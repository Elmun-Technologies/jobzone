/**
 * Sanitize a post-auth `next` redirect target. Only a same-origin absolute
 * path ("/uz/account", "/employer/jobs/new") is allowed — never a full URL,
 * protocol-relative ("//evil"), backslash ("/\\evil"), or userinfo ("@evil")
 * target, all of which turn `next` into an open-redirect / phishing vector.
 */
export function safeNext(
  next: string | null | undefined,
  fallback: string,
): string {
  if (!next || next[0] !== "/") return fallback; // must be an absolute local path
  if (next[1] === "/" || next[1] === "\\") return fallback; // block //host, /\host
  if (next.includes("\\")) return fallback; // block backslash tricks
  return next;
}
