/** Next's searchParams type accounts for repeated query keys (string[]); every
 * admin page only ever wants the first value. Shared so the same one-liner
 * isn't redefined per page. */
export function pickParam(v: string | string[] | undefined): string | undefined {
  return Array.isArray(v) ? v[0] : v;
}
