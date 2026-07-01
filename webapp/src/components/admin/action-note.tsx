/**
 * Inline result line for admin server actions (the repo's typed-state
 * `useActionState` convention — see src/lib/actions/wallet.ts). Presentational
 * only, usable from both server and client components.
 */
export function ActionNote({
  ok,
  error,
}: {
  ok?: string | null;
  error?: string | null;
}) {
  if (error) {
    return <p className="text-destructive mt-2 text-sm">{error}</p>;
  }
  if (ok) {
    return <p className="text-foreground mt-2 text-sm font-medium">{ok}</p>;
  }
  return null;
}
