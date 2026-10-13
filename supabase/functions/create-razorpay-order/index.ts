import "jsr:@supabase/functions-js/edge-runtime.d.ts";

/**
 * Mints a Razorpay order for an amount the server works out for itself.
 *
 * Earlier this trusted the app's own `amount_paise` — a tampered client
 * could ask for an order of ₹1 while the cart it walked away with was worth
 * ₹5,000. Razorpay's own guidance is explicit about this: the amount has to
 * come from the merchant's server, never from the Checkout callback or the
 * client that opened it. So this function re-derives the payable amount
 * itself, the same way the place_order database function does when the order
 * is placed: read the caller's own cart (RLS already scopes `cart_items` to
 * `customer_id = auth.uid()`, so forwarding their own bearer token is enough —
 * no service role needed), price it from `products` (or the chosen
 * `product_variants` row), apply a coupon only if `coupons` itself still backs
 * it, and cap wallet use at the ledger's real balance. Whatever the client
 * claims about the total is read only as a hint for which coupon or how much
 * wallet to try — never as the number that gets charged.
 *
 * The rider's tip is the one thing the customer chooses outright: it is
 * checked against the same 0–500 range place_order enforces, added on top of
 * the bill, and never paid for out of the wallet (place_order caps wallet
 * use at the bill without the tip, and so must this).
 *
 * The two must agree to the paisa: place_order refuses a payment that does not
 * cover what it works out is due.
 *
 * The key secret never leaves this function: the app is handed only an
 * order id and the public key id, which is all the Checkout SDK needs.
 *
 * A signed-in caller is required. Not because the order is tied to an
 * account here, but because an open endpoint that mints payment orders is
 * an open endpoint for running up someone else's Razorpay account.
 */

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const KEY_ID = Deno.env.get("RAZORPAY_KEY_ID") ?? "";
const KEY_SECRET = Deno.env.get("RAZORPAY_KEY_SECRET") ?? "";

const FREE_DELIVERY_THRESHOLD = 299;
const BASE_DELIVERY_FEE = 29;
const MAX_TIP = 500; // same limit as place_order

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/** A GET against PostgREST, scoped by whatever RLS lets this caller's own token see. */
async function restGet(path: string, authHeader: string): Promise<unknown[] | null> {
  const response = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    headers: { apikey: ANON_KEY, Authorization: authHeader },
  });
  if (!response.ok) return null;
  return await response.json().catch(() => null);
}

async function currentUserId(authHeader: string | null): Promise<string | null> {
  if (!authHeader) return null;
  const response = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    headers: { apikey: ANON_KEY, Authorization: authHeader },
  });
  if (!response.ok) return null;
  const user = await response.json().catch(() => null);
  return user?.id ?? null;
}

type CartRow = {
  quantity: number;
  variant: { price: number } | null;
  product: { price: number; discount_price: number | null; seller_id: string } | null;
};

/** What one unit costs: the chosen variant's price, else the product's selling price. */
function unitPriceOf(row: CartRow): number {
  const product = row.product;
  if (!product) return 0;
  return row.variant?.price ?? product.discount_price ?? product.price;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "POST only" }, 405);

  if (!KEY_ID || !KEY_SECRET) {
    // Said plainly, because the app shows this straight to the shopper and
    // "something went wrong" would send them hunting in the wrong place.
    return json({ error: "Online payment is not configured yet" }, 503);
  }

  const authHeader = req.headers.get("Authorization");
  const userId = await currentUserId(authHeader);
  if (!userId || !authHeader) {
    return json({ error: "Sign in to pay online" }, 401);
  }

  let receipt = "";
  let requestedWalletAmount = 0;
  let couponCode = "";
  let tip = 0;
  try {
    const body = await req.json();
    receipt = String(body?.receipt ?? "").slice(0, 40);
    requestedWalletAmount = Math.max(0, Math.trunc(Number(body?.wallet_amount ?? 0)) || 0);
    couponCode = String(body?.coupon_code ?? "").trim();
    tip = Math.trunc(Number(body?.tip ?? 0)) || 0;
  } catch {
    return json({ error: "Bad request" }, 400);
  }
  if (tip < 0 || tip > MAX_TIP) {
    return json({ error: `A tip must be between 0 and ${MAX_TIP}` }, 400);
  }

  // The caller's own cart, priced from the caller's own products — nothing
  // here comes from the request body.
  const cartRows = await restGet(
    "cart_items?select=quantity,variant:product_variants(price),product:products(price,discount_price,seller_id)",
    authHeader,
  ) as CartRow[] | null;
  if (!cartRows || cartRows.length === 0) {
    return json({ error: "Your cart is empty" }, 400);
  }

  const subtotal = cartRows.reduce((sum, row) => sum + unitPriceOf(row) * row.quantity, 0);
  if (subtotal <= 0) {
    return json({ error: "Your cart is empty" }, 400);
  }

  // A cart can span several sellers — this is a multi-vendor marketplace, not
  // a single shop's app — and each seller's slice ships (and is charged
  // delivery for) on its own. So the free-delivery threshold is checked per
  // seller's own subtotal, not the cart's combined total.
  const subtotalBySeller = new Map<string, number>();
  for (const row of cartRows) {
    if (!row.product) continue;
    const key = row.product.seller_id || "";
    subtotalBySeller.set(key, (subtotalBySeller.get(key) ?? 0) + unitPriceOf(row) * row.quantity);
  }
  let deliveryFee = 0;
  for (const sellerSubtotal of subtotalBySeller.values()) {
    if (sellerSubtotal > 0 && sellerSubtotal < FREE_DELIVERY_THRESHOLD) deliveryFee += BASE_DELIVERY_FEE;
  }

  // A coupon is only honoured here if `coupons` itself still backs it —
  // the code alone proves nothing. Anything that fails this (unknown,
  // inactive, or the cart no longer clears its minimum) is silently worth
  // ₹0 rather than trusted from the client.
  let couponDiscount = 0;
  if (couponCode) {
    const coupons = await restGet(
      `coupons?select=discount_percent,max_discount,min_order_value&is_active=eq.true&code=ilike.${encodeURIComponent(couponCode)}`,
      authHeader,
    ) as Array<{ discount_percent: number; max_discount: number; min_order_value: number }> | null;
    const coupon = coupons?.[0];
    if (coupon && subtotal >= coupon.min_order_value) {
      couponDiscount = Math.min((subtotal * coupon.discount_percent) / 100, coupon.max_discount);
    }
  }

  // The bill for goods and delivery; the tip sits on top of it.
  const total = Math.max(0, subtotal + deliveryFee - couponDiscount);

  // Same ledger-sum the place_order function trusts, read straight from the
  // caller's own transactions rather than taken on their word.
  let walletBalance = 0;
  if (requestedWalletAmount > 0) {
    const txns = await restGet(
      `wallet_transactions?select=amount,type&user_id=eq.${userId}`,
      authHeader,
    ) as Array<{ amount: number; type: string }> | null;
    walletBalance = (txns ?? []).reduce(
      (sum, t) => sum + (t.type === "CREDIT" ? t.amount : -t.amount),
      0,
    );
  }
  const walletUsed = Math.min(requestedWalletAmount, Math.max(0, walletBalance), Math.trunc(total));

  const payable = Math.max(0, total - walletUsed) + tip;
  const amountPaise = Math.round(payable * 100);

  // Whole paise, at least ₹1, and a ceiling so a cart gone wrong cannot ask
  // a shopper to authorise a fortune. Razorpay would reject some of these
  // itself; catching them here keeps the failure readable.
  if (amountPaise < 100) {
    return json({ error: "Nothing left to pay online for this order" }, 400);
  }
  if (amountPaise > 50_000_000) {
    return json({ error: "That amount cannot be charged" }, 400);
  }

  const auth = btoa(`${KEY_ID}:${KEY_SECRET}`);
  const response = await fetch("https://api.razorpay.com/v1/orders", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Basic ${auth}`,
    },
    body: JSON.stringify({
      amount: amountPaise,
      currency: "INR",
      receipt,
      payment_capture: 1,
    }),
  });

  const order = await response.json().catch(() => null);
  if (!response.ok || !order?.id) {
    console.error("razorpay order failed", response.status, order);
    return json({ error: order?.error?.description ?? "Could not start the payment" }, 502);
  }

  // key_id goes back with the order so the app does not need it built in: a
  // build made before the key existed can still take a payment.
  return json({ order_id: order.id, amount: order.amount, key_id: KEY_ID }, 200);
});
