const ALLOWED_ORIGINS = [
  "https://yollla.uz",
  "https://www.yollla.uz",
  "http://localhost:3000",
  "http://127.0.0.1:3000",
];

export const corsHeaders = {
  "Access-Control-Allow-Origin": "https://www.yollla.uz",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-edge-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  Vary: "Origin",
};

/** Prefer the request Origin when it is a known first-party host. */
export function corsFor(req: Request): Record<string, string> {
  const origin = req.headers.get("origin") ?? "";
  const allow = ALLOWED_ORIGINS.includes(origin)
    ? origin
    : "https://www.yollla.uz";
  return { ...corsHeaders, "Access-Control-Allow-Origin": allow };
}

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
