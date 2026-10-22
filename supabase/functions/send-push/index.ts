import "jsr:@supabase/functions-js/edge-runtime.d.ts";

// Fired by a Postgres trigger on `notifications` INSERT (see
// notify_push_on_insert() in supabase/notifications_push.sql). Not a
// user-facing endpoint — authenticated by a shared secret header instead of
// a Supabase JWT, since a Postgres trigger has no user session to attach
// one from.
//
// This is the version actually deployed and wired to that trigger. An
// earlier draft here diverged from it (different secret names, a payload
// shape the trigger never sent) — if the Supabase project were ever lost,
// restoring from that draft would have deployed something the app didn't
// use. This file is now the same code that is live.
const WEBHOOK_SECRET = Deno.env.get("WEBHOOK_SHARED_SECRET");
const SERVICE_ACCOUNT_JSON = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

// Must match push_service.dart's _loudChannelId — an order landing, or a run
// getting assigned, is the one alert either side is actively waiting on, so
// it gets routed to the phone's louder channel instead of the default one.
const LOUD_CHANNEL_ID = "duggu_order_alert";

interface ServiceAccount {
  project_id: string;
  private_key: string;
  client_email: string;
  token_uri: string;
}

interface NotifyPayload {
  user_id: string;
  title: string;
  body: string;
  type?: string;
  order_id: string | null;
  loud?: boolean;
}

function base64url(input: ArrayBuffer | string): string {
  const bytes = typeof input === "string"
    ? new TextEncoder().encode(input)
    : new Uint8Array(input);
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToPkcs8(pem: string): ArrayBuffer {
  const stripped = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const binary = atob(stripped);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

async function fetchAccessToken(account: ServiceAccount): Promise<string> {
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToPkcs8(account.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const nowSeconds = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: account.token_uri,
    iat: nowSeconds,
    exp: nowSeconds + 3600,
  };
  const unsigned = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(claims))}`;
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const assertion = `${unsigned}.${base64url(signature)}`;

  const response = await fetch(account.token_uri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!response.ok) {
    throw new Error(`Token exchange failed: ${response.status} ${await response.text()}`);
  }
  const json = await response.json();
  return json.access_token as string;
}

async function fetchDeviceTokens(userId: string): Promise<{ token: string }[]> {
  const url = `${SUPABASE_URL}/rest/v1/device_tokens?user_id=eq.${userId}&select=token`;
  const response = await fetch(url, {
    headers: {
      apikey: SUPABASE_SERVICE_ROLE_KEY!,
      Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
    },
  });
  if (!response.ok) return [];
  return await response.json();
}

async function deleteDeviceToken(token: string): Promise<void> {
  const url = `${SUPABASE_URL}/rest/v1/device_tokens?token=eq.${encodeURIComponent(token)}`;
  await fetch(url, {
    method: "DELETE",
    headers: {
      apikey: SUPABASE_SERVICE_ROLE_KEY!,
      Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
    },
  });
}

Deno.serve(async (req: Request) => {
  if (req.headers.get("x-webhook-secret") !== WEBHOOK_SECRET) {
    return new Response("Forbidden", { status: 403 });
  }
  if (!SERVICE_ACCOUNT_JSON || !SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return new Response("Missing server configuration", { status: 500 });
  }

  const payload: NotifyPayload = await req.json();
  const account: ServiceAccount = JSON.parse(SERVICE_ACCOUNT_JSON);

  const tokens = await fetchDeviceTokens(payload.user_id);
  if (tokens.length === 0) {
    return new Response(JSON.stringify({ sent: 0 }), { status: 200 });
  }

  const accessToken = await fetchAccessToken(account);
  const sendUrl = `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`;
  const loud = payload.loud === true;

  let sent = 0;
  for (const { token } of tokens) {
    const response = await fetch(sendUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          // The heads-up itself. Without this block the message carries
          // only `data`, which Android never turns into a tray notification
          // on its own — and the app's own local-notification code
          // (push_service.dart's _show()) reads message.notification, not
          // message.data, so a data-only push used to arrive and show
          // nothing at all, in the foreground or the background.
          notification: {
            title: payload.title,
            body: payload.body,
          },
          data: {
            // Who this was addressed to. A device keeps its FCM token across
            // a sign-out, so a message already in flight can arrive after
            // someone else has signed in on it; the app drops anything whose
            // recipient is not the account currently open.
            user_id: payload.user_id,
            title: payload.title,
            body: payload.body,
            ...(payload.type ? { type: payload.type } : {}),
            loud: loud ? "true" : "false",
            ...(payload.order_id ? { order_id: payload.order_id } : {}),
          },
          android: {
            priority: "high",
            ...(loud
              ? { notification: { channel_id: LOUD_CHANNEL_ID, sound: "order_alert" } }
              : {}),
          },
          apns: {
            headers: { "apns-priority": "10" },
            payload: { aps: { sound: "default" } },
          },
        },
      }),
    });

    if (response.ok) {
      sent++;
      continue;
    }

    const errorText = await response.text();
    if (/UNREGISTERED|NOT_FOUND|INVALID_ARGUMENT/.test(errorText)) {
      await deleteDeviceToken(token);
    }
  }

  return new Response(JSON.stringify({ sent, total: tokens.length }), { status: 200 });
});
