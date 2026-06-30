const inputClass =
  "h-11 w-full rounded-lg border border-border bg-background px-3 text-foreground outline-none focus-visible:ring-2 focus-visible:ring-ring";

/** Shared email + password inputs for the sign-in / sign-up forms. */
export function EmailPasswordFields({
  emailLabel,
  passwordLabel,
}: {
  emailLabel: string;
  passwordLabel: string;
}) {
  return (
    <>
      <label className="block">
        <span className="text-foreground mb-1 block text-sm font-medium">
          {emailLabel}
        </span>
        <input
          name="email"
          type="email"
          autoComplete="email"
          required
          className={inputClass}
        />
      </label>
      <label className="block">
        <span className="text-foreground mb-1 block text-sm font-medium">
          {passwordLabel}
        </span>
        <input
          name="password"
          type="password"
          autoComplete="current-password"
          required
          className={inputClass}
        />
      </label>
    </>
  );
}

export function FormError({ message }: { message?: string }) {
  if (!message) return null;
  return <p className="text-destructive text-sm font-medium">{message}</p>;
}
