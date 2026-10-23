import "jsr:@supabase/functions-js/edge-runtime.d.ts";

/**
 * Picks up the payments whose success callback never made it home.
 *
 * Razorpay captures the money the moment the customer authorises it, but the
 * Checkout SDK only *tells* the app over its own activity callback, and that
 * callback is not bulletproof. On some devices the UPI-intent handoff dies at
 * the exact moment of return (razorpay-flutter issue #408: "Payment
 * Successful — you will be redirected… you get a Something went wrong
 * dialog, and neither the success nor the failure callback fires"), and even
 * the OS killing the gateway's helper process between the coming home of the
 * payment app and the checkout's own confirm round trip can do it. What
 * happened: Razorpay captured, the app heard nothing of the kind, an error
 * dialog appeared instead, and `place_order` never even ran — no
 * verified_payments row, and a customer with no order.
 *
 * The cure that belongs here: when the app hears the failure event, then
 * before giving up it asks this endpoint whether the gateway actually kept
 * the money. This function answers by asking Razorpay itself (server to
 * server, with the key secret no phone ever sees), and only answers "yes"
 * when Razorpay has the payment *captured*. It then writes the same row
 * verify-razorpay-payment would have written, which is the credential
 * place_order demands, so the order can be placed after the fact.
 *
 * The lookup replaces the signature check rather than duplicating it: there
 * is no callback signature to check when no callback arrived, and a row can
 * exist only because the gateway itself said the payment was captured.
 *
 * WHO MAY CLAIM
 *
 * A signed-in caller, and — for every order minted since
 * create-razorpay-order started stamping a user_id note on Razorpay orders —
 * the account that had the order minted for it. An order-id is not much of a
 * secret, so without this binding a user who knew someone else's razorpay
 * order id of a captured-but-unclaimed payment could attach it to their own
 * cart; the note makes that impossible, because the caller must be the same
 * account the order was created for. Older orders get the row written under
 * the caller's uid, which matches how they were paid anyway.
 *
 * The insert is ignore-duplicates, so repeated claims (retry taps, retries of
 * this very endpoint) leave the first record standing, exactly as verify
 * does.
 */

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const KEY_ID = Deno.env.get("RAZORPAY_KEY_ID") ?? "";
const KEY_SECRET = Deno.env.get("RAZORPAY_KEY_SECRET") ?? "";

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/** Same check the sibling payment functions do: the caller must be signed in. */
async function currentUserId(authHeader: string | null): Promise<string | null> {
  if (!authHeader) return null;
  const response = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    headers: { apikey: ANON_KEY, Authorization: authHeader },
  });
  if (!response.ok) return null;
  const user = await response.json().catch(() => null);
  return user?.id ?? null;
}

type RazorpayPayment = { id?: string; amount?: number; status?: string; captured?: boolean };

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "POST only" }, 405);

  if (!KEY_ID || !KEY_SECRET) {
    return json({ paid: false, error: "Online payment is not configured yet" }, 503);
  }
  if (!SERVICE_KEY) {
    return json({ paid: false, error: "Payments cannot be confirmed yet" }, 503);
  }

  const authHeader = req.headers.get("Authorization");
  const userId = await currentUserId(authHeader);
  if (!userId || !authHeader) {
    return json({ paid: false, error: "Sign in to pay online" }, 401);
  }

  let orderId = "";
  try {
    const body = await req.json();
    orderId = String(body?.order_id ?? "").trim();
  } catch {
    return json({ paid: false, error: "Bad request" }, 400);
  }
  if (!/^order_[A-Za-z0-9]{8,}$/.test(orderId)) {
    return json({ paid: false, error: "Bad request" }, 400);
  }

  // 1. The order itself — what it was for, and who it was minted for.
  const orderResponse = await fetch(
    `https://api.razorpay.com/v1/orders/${encodeURIComponent(orderId)}`,
    { headers: { Authorization: `Basic ${btoa(`${KEY_ID}:${KEY_SECRET}`)}` } },
  );
  const order = await orderResponse.json().catch(() => null);
  if (!orderResponse.ok || !order?.id) {
    console.error("razorpay order lookup failed", orderId, orderResponse.status);
    return json({ paid: false, error: "Razorpay is not answering" }, 502);
  }

  // Only the account the order was minted for may claim it ( stamped onto
  // the order as a note by create-razorpay-order; orders minted before that
  // carry no note and stay claimable by whoever paid them ).
  const boundUser = String(order.notes?.user_id ?? "");
  if (boundUser && boundUser !== userId) {
    return json({ paid: false, error: "This payment belongs to a different account" }, 403);
  }

  const amountPaise = Number(order.amount);
  if (!Number.isFinite(amountPaise) || amountPaise <= 0) {
    return json({ paid: false, error: "Could not confirm the payment amount" }, 502);
  }

  // 2. What Razorpay actually took on this order. A list, because a customer
  // can attempt more than once; any captured one is the money we hold.
  const paymentsResponse = await fetch(
    `https://api.razorpay.com/v1/orders/${encodeURIComponent(orderId)}/payments`,
    { headers: { Authorization: `Basic ${btoa(`${KEY_ID}:${KEY_SECRET}`)}` } },
  );
  const paymentsData = await paymentsResponse.json().catch(() => null);
  if (!paymentsResponse.ok) {
    console.error("razorpay payments lookup failed", orderId, paymentsResponse.status);
    return json({ paid: false, error: "Razorpay is not answering" }, 502);
  }
  const captures = ((paymentsData?.payments ?? []) as RazorpayPayment[])
    .filter((p) => (p.status === "captured" || p.captured === true) && !!p.id);
  if (captures.length === 0) {
    // Nothing was taken: the failure event was the truth. Let the app fail.
    return json({ paid: false }, 200);
  }
  const paymentId = captures[0].id!;

  // 3. The same record verify-razorpay-payment writes: the credential
  // place_order checks before an online order goes through.
  const saved = await fetch(`${SUPABASE_URL}/rest/v1/verified_payments`, {
    method: "POST",
    headers: {
      apikey: SERVICE_KEY,
      Authorization: `Bearer ${SERVICE_KEY}`,
      "Content-Type": "application/json",
      // Recorded once; repeats leave the first record alone.
      Prefer: "resolution=ignore-duplicates,return=representation",
    },
    body: JSON.stringify({
      payment_id: paymentId,
      razorpay_order_id: orderId,
      user_id: userId,
      amount_paise: Math.round(amountPaise),
    }),
  });
  if (!saved.ok) {
    console.error("could not record the payment", saved.status, await saved.text().catch(() => ""));
    return json({ paid: false, error: "Could not record the payment" }, 500);
  }

  return json({ paid: true, payment_id: paymentId }, 200);
});
