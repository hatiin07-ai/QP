const PUBLIC_URL = "https://pub-abd3a298d51549de9932c08e65482f0b.r2.dev";
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "PUT, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, X-Key"
};

export async function onRequestPut({ request, env }) {
  const key = request.headers.get("X-Key");
  if (!key) return new Response(JSON.stringify({ error: "X-Key required" }), {
    status: 400, headers: { ...CORS, "Content-Type": "application/json" }
  });
  try {
    const body = await request.arrayBuffer();
    const ct = request.headers.get("Content-Type") || "image/png";
    await env.DRESS.put(key, body, { httpMetadata: { contentType: ct } });
    return new Response(JSON.stringify({ ok: true, key, url: `${PUBLIC_URL}/${key}` }), {
      headers: { ...CORS, "Content-Type": "application/json" }
    });
  } catch(e) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500, headers: { ...CORS, "Content-Type": "application/json" }
    });
  }
}

export async function onRequestOptions() {
  return new Response(null, { headers: CORS });
}
