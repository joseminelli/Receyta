// Ativa a assinatura na hora: o app chama esta função logo depois da compra, e
// ela pergunta direto ao RevenueCat (API REST) até quando o entitlement `cloud`
// vale e grava em `entitlements`. Sem isso, o acesso só liga quando o webhook
// (revenuecat-webhook) chega, o que pode levar um bom tempo.
//
// Só mexe na conta de quem chama (o id vem do token de login). Publicar COM
// verificação de JWT (padrão). Precisa do segredo REVENUECAT_SECRET_API_KEY: a
// "Secret API key" (sk_...) do projeto, em RevenueCat → API keys.

import { createClient } from "npm:@supabase/supabase-js@2";

const ENTITLEMENT = "cloud";

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);

  const auth = req.headers.get("Authorization") ?? "";
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: auth } } },
  );
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return json({ error: "unauthorized" }, 401);

  const key = Deno.env.get("REVENUECAT_SECRET_API_KEY");
  if (!key) return json({ error: "not configured" }, 500);

  const res = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(user.id)}`,
    { headers: { Authorization: `Bearer ${key}` } },
  );
  if (!res.ok) return json({ error: "revenuecat", status: res.status }, 502);

  const body = await res.json();
  const ent = body?.subscriber?.entitlements?.[ENTITLEMENT];
  const until = ent?.expires_date ? Date.parse(ent.expires_date) : NaN;
  if (!ent || Number.isNaN(until)) return json({ active: false });

  const db = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { error } = await db.from("entitlements").upsert({
    user_id: user.id,
    plan_until: new Date(until).toISOString(),
    product_id: ent.product_identifier ?? null,
    last_event_ms: Date.now(),
    updated_at: new Date().toISOString(),
  }, { onConflict: "user_id" });
  if (error) return json({ error: error.message }, 500);

  return json({ active: until > Date.now() });
});
