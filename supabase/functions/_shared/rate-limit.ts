// Simple in-memory sliding-window or token-bucket rate limiter for Edge Functions.
// For true distributed high-scale across multi-region edge nodes, a Redis (Upstash)
// store is recommended; this acts as a robust lightweight perimeter guard.

const rateMap = new Map<string, { count: number; resetAt: number }>();

export function checkRateLimit(
  identifier: string,
  maxRequests: number = 60,
  windowSeconds: number = 60,
): { allowed: boolean; retryAfter: number } {
  const now = Date.now();
  const windowMs = windowSeconds * 1000;
  
  let record = rateMap.get(identifier);
  if (!record || now > record.resetAt) {
    record = { count: 1, resetAt: now + windowMs };
    rateMap.set(identifier, record);
    return { allowed: true, retryAfter: 0 };
  }

  if (record.count >= maxRequests) {
    const retryAfter = Math.ceil((record.resetAt - now) / 1000);
    return { allowed: false, retryAfter };
  }

  record.count++;
  return { allowed: true, retryAfter: 0 };
}
