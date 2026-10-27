import "jsr:@supabase/functions-js/edge-runtime.d.ts";

/**
 * Records a captured payment the moment Razorpay announces it, no app
 * involved.
 *
 * The claim-razorpay-payment endpoint depends on the app hearing *something*
 * — the failure event — before it goes looking. There are ways to miss even
 * that: the gateway's helper never reschedules, or the app is backgrounded
 * so far that Android kills it between the payment app returning and the
 * checkout's callback. Razorpay's webhook covers both: the gateway POSTs
 * `payment.captured` straight here, and the row `place_order` demands (the
 * same row verify-razorpay-payment writes) is recorded while the customer is
 * still staring at any "Something went wrong" dialog. When the app finally
 * does get round to asking, the claim endpoint finds the row already there
 * and repeats are absorbed by ignore-duplicates.
 *
 * AUTHENTICITY: the request is accepted only when the HMAC-SHA256 of the raw
 * body, keyed with the webhook secret set in the Razorpay dashboard, matches
 * the X-Razorpay-Signature header. Razorpay documents this check and sends
 * nothing else worth trusting; a forged POST gets a 400.
 *
 * WHO THE PAYMENT BELONGS TO: create-razorpay-order stamps {user_id} onto
 * the order notes, and the payment entity carries those notes forward. If
 * the notes are missing (an order minted before stamping began), the row is
 * still written but without a user — razorpay_order_id remains the key by
 * which the money is traceable. place_order still requires a signed-in
 * caller, so an unowned row can be consumed only by whoever paid and talks
 * to us with a valid session.
 */

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const WEBHOOK_SECRET = Deno.env.get("RAZORPAY_WEBHOOK_SECRET") ?? "";

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/** Constant-time-ish hex comparison; lengths differ → reject outright. */
function signaturesMatch(expected: string, received: string): boolean {
  if (received.length !== expected.length) return false;
  let diff = 0;
  for (let i = 0; i < expected.length; i++) {
    diff |= expected.charCodeAt(i) ^ received.charCodeAt(i);
  }
  return diff === 0;
}

async function verifySignature(raw: string, header: string | null): Promise<boolean> {
  if (!WEBHOOK_SECRET || !header) return false;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(WEBHOOK_SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(raw));
  const expected = Array.from(new Uint8Array(mac))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  return signaturesMatch(expected, header.trim());
}

type WebhookPayment = {
  id?: string;
  order_id?: string;
  amount?: number;
  status?: string;
  captured?: boolean;
  notes?: Record<string, unknown>;
};

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "POST only" }, 405);
  if (!SERVICE_KEY) return json({ error: "Payments cannot be recorded yet" }, 503);
  if (!WEBHOOK_SECRET) return json({ error: "Webhook is not configured yet" }, 503);

  const raw = await req.text();
  const ok = await verifySignature(raw, req.headers.get("X-Razorpay-Signature"));
  if (!ok) return json({ error: "Bad signature" }, 400);

  let event: {
    event?: string;
    payload?: { payment?: { entity?: WebhookPayment } };
  };
  try {
    event = JSON.parse(raw);
  } catch {
    return json({ error: "Bad request" }, 400);
  }

  // Events worth nothing to us are acknowledged and dropped — Razorpay
  // retries anything that isn't a 2xx otherwise.
  if (event.event !== "payment.captured") return json({ ok: true }, 200);

  const payment = event.payload?.payment?.entity;
  const paymentId = String(payment?.id ?? "");
  const orderId = String(payment?.order_id ?? "");
  const amountPaise = Number(payment?.amount);
  const captured = payment?.status === "captured" || payment?.captured === true;
  if (!paymentId || !orderId || !Number.isFinite(amountPaise) || amountPaise <= 0 || !captured) {
    return json({ ok: true }, 200);
  }

  const userId = String((payment?.notes?.user_id as string | undefined) ?? "");

  const saved = await fetch(`${SUPABASE_URL}/rest/v1/verified_payments`, {
    method: "POST",
    headers: {
      apikey: SERVICE_KEY,
      Authorization: `Bearer ${SERVICE_KEY}`,
      "Content-Type": "application/json",
      // Recorded once; webhook retries and the claim endpoint repeating
      // leave the first record standing.
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
    // 500 makes Razorpay retry the delivery; the row goes in eventually.
    console.error("webhook insert failed", saved.status, await saved.text().catch(() => ""));
    return json({ ok: false }, 500);
  }

  return json({ ok: true, payment_id: paymentId }, 200);
});
