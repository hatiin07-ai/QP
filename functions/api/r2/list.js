const PUBLIC_URL = "https://pub-abd3a298d51549de9932c08e65482f0b.r2.dev";
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, X-Key"
};

export async function onRequestGet({ request, env }) {
  const url = new URL(request.url);
  const prefix = url.searchParams.get("prefix") || "";
  try {
    const list = await env.DRESS.list({ prefix });
    const objects = (list.objects || []).map(o => ({
      key: o.key,
      url: `${PUBLIC_URL}/${o.key}`,
      size: o.size
    }));
    return new Response(JSON.stringify({ objects }), {
      headers: { ...CORS, "Content-Type": "application/json" }
    });
  } catch(e) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: { ...CORS, "Content-Type": "application/json" }
    });
  }
}

export async function onRequestOptions() {
  return new Response(null, { headers: CORS });
}
