const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, X-Key"
};

export async function onRequestDelete({ request, env }) {
  const key = request.headers.get("X-Key");
  if (!key) return new Response(JSON.stringify({ error: "X-Key required" }), {
    status: 400, headers: { ...CORS, "Content-Type": "application/json" }
  });
  try {
    await env.DRESS.delete(key);
    return new Response(JSON.stringify({ ok: true, key }), {
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
