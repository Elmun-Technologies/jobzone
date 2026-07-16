import { adminStrings } from "@/lib/admin/strings";
import { creditWallet } from "@/lib/actions/admin/finance";

const s = adminStrings.finance;

const inputClass =
  "border-border bg-background text-foreground h-9 rounded-lg border px-2.5 text-sm focus-visible:outline-none";

/**
 * Manual wallet adjustment — the last-resort tool that admin_credit_wallet
 * (0069) authorises. Enter a UUID from any wallet row above, sign the amount
 * (positive credit, negative debit), pick a kind for reporting, and record
 * a reason. Every submission is audit-logged with the actor, kind, amount,
 * and reason — reconciliation depends on the reason being useful, so the
 * server RPC RAISEs when it's blank.
 */
export function ManualCreditForm({ locale }: { locale: string }) {
  return (
    <section className="border-border bg-card mb-5 rounded-2xl border p-4">
      <h2 className="text-foreground text-sm font-semibold">
        {s.manualCreditTitle}
      </h2>
      <p className="text-muted-foreground mt-1 text-xs">{s.manualCreditHint}</p>
      <form
        action={creditWallet}
        className="mt-3 grid grid-cols-1 gap-2 sm:grid-cols-[minmax(0,1fr)_140px_140px_minmax(0,1fr)_auto]"
      >
        <input type="hidden" name="locale" value={locale} />
        <label className="flex flex-col gap-1">
          <span className="text-muted-foreground text-xs">{s.companyId}</span>
          <input
            name="companyId"
            type="text"
            required
            placeholder="00000000-0000-0000-0000-000000000000"
            pattern="[0-9a-fA-F-]{36}"
            title={s.companyIdHint}
            className={inputClass}
          />
        </label>
        <label className="flex flex-col gap-1">
          <span className="text-muted-foreground text-xs">{s.amount}</span>
          <input
            name="amountUzs"
            type="number"
            step="1"
            required
            placeholder="±100000"
            className={inputClass}
          />
        </label>
        <label className="flex flex-col gap-1">
          <span className="text-muted-foreground text-xs">{s.kind}</span>
          <select name="kind" defaultValue="bonus" className={inputClass}>
            <option value="bonus">{s.kindBonus}</option>
            <option value="refund">{s.kindRefund}</option>
            <option value="topup">{s.kindTopup}</option>
            <option value="spend">{s.kindSpend}</option>
          </select>
        </label>
        <label className="flex flex-col gap-1">
          <span className="text-muted-foreground text-xs">{s.reason}</span>
          <input
            name="reason"
            type="text"
            required
            maxLength={200}
            className={inputClass}
          />
        </label>
        <div className="flex items-end">
          <button
            type="submit"
            className="bg-primary text-primary-foreground h-9 rounded-full px-4 text-xs font-semibold"
          >
            {s.submit}
          </button>
        </div>
      </form>
    </section>
  );
}
