/** True when Supabase credentials are configured. Mirrors the Flutter app's
 * `Env.hasSupabase` gate — when false the data layer serves mock content. */
export function hasSupabase(): boolean {
  return (
    !!process.env.NEXT_PUBLIC_SUPABASE_URL &&
    !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
  );
}
