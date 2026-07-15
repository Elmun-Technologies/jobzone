/** True when Supabase credentials are configured. Mirrors the Flutter app's
 * `Env.hasSupabase` gate — when false the data layer returns empty results
 * (the product is online-only; there is no demo/mock content). */
export function hasSupabase(): boolean {
  return (
    !!process.env.NEXT_PUBLIC_SUPABASE_URL &&
    !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
  );
}
