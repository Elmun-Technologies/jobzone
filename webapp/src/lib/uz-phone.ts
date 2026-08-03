/**
 * Uzbek mobile numbers, the one shape this market uses: +998 followed by nine
 * digits (a two-digit operator code and seven subscriber digits).
 *
 * The résumé's phone is the field employers actually dial, and a free-text box
 * collected it every way a person can write one — "+998 90 123 45 67",
 * "998901234567", "90-123-45-67", "8 90 123 45 67". Pinning the +998 in the UI
 * and normalising here means one stored shape, and a number that can be dialled
 * from a Telegram notification without a human first repairing it.
 */

/** The nine national digits, from anything a person might have typed. */
export function nationalDigits(raw: string): string {
  const digits = (raw ?? "").replace(/\D/g, "");
  // Country code typed (with or without +), or a leading 8 out of old habit.
  const withoutCc = digits.startsWith("998") ? digits.slice(3) : digits;
  const trimmed =
    withoutCc.length > 9 && withoutCc.startsWith("8")
      ? withoutCc.slice(1)
      : withoutCc;
  // Keep the LAST nine: a stray prefix is far likelier than a stray suffix.
  return trimmed.length > 9 ? trimmed.slice(-9) : trimmed;
}

/** Display grouping as typed: "901234567" -> "90 123 45 67". */
export function formatNational(digits: string): string {
  const d = nationalDigits(digits);
  const parts = [d.slice(0, 2), d.slice(2, 5), d.slice(5, 7), d.slice(7, 9)];
  return parts.filter(Boolean).join(" ");
}

/** Storage shape: "+998901234567", or "" until all nine digits are there. */
export function toE164(raw: string): string {
  const d = nationalDigits(raw);
  return d.length === 9 ? `+998${d}` : "";
}

/** Nine digits present — what the wizard's "next" button checks. */
export function isCompleteUzPhone(raw: string): boolean {
  return nationalDigits(raw).length === 9;
}
