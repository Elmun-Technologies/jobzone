import { ConfirmSubmit } from "@/components/admin/confirm-submit";
import { adminStrings } from "@/lib/admin/strings";

/**
 * One-row moderation form: hidden fields + optional reason input + a two-step
 * confirm button wired to a server action. Lives in table action cells.
 */
export function ModerationForm({
  action,
  fields,
  label,
  withReason = false,
}: {
  action: (formData: FormData) => Promise<void>;
  fields: Record<string, string>;
  label: string;
  withReason?: boolean;
}) {
  return (
    <form action={action} className="flex items-center gap-2">
      {Object.entries(fields).map(([name, value]) => (
        <input key={name} type="hidden" name={name} value={value} />
      ))}
      {withReason ? (
        <input
          type="text"
          name="reason"
          placeholder={adminStrings.mod.reasonPlaceholder}
          className="border-border bg-background text-foreground placeholder:text-muted-foreground h-9 w-36 rounded-lg border px-2.5 text-xs focus-visible:outline-none"
        />
      ) : null}
      <ConfirmSubmit size="sm" variant="outline">
        {label}
      </ConfirmSubmit>
    </form>
  );
}
