/// The "first vacancy free, then pay per listing" rule, as a pure function.
///
/// The database is what actually enforces it — `guard_job_publish()` (0066)
/// raises `payment_required` on a 2nd+ market entry that carries no paid tier
/// order. This mirrors that rule client-side so the employer is sent to the
/// checkout *before* they hit the guard; when the two disagree the employer
/// either sees a bare error (client too permissive) or pays twice (client too
/// strict), so the logic lives here where it can be read and tested rather
/// than inline in a form's submit handler.
library;

/// Whether this save puts the vacancy on the market for the first time — the
/// transition the paywall gates. False means no payment can be due, so the
/// caller can skip asking the backend whether the company has published
/// before.
///
/// [wantsToGoLive] — the employer pressed "E'lon qilish" (not "save draft").
/// This is about INTENT, not the row's resulting status: a scheduled post is
/// written as a draft but is still a market entry, and skipping the gate for
/// it left the vacancy parked, unpublished, at its scheduled time.
///
/// [isEdit] — editing an existing vacancy rather than creating one. Editing is
/// not exempt: publishing a draft from the edit screen is a market entry like
/// any other.
///
/// [firstPublishedAt] / [currentStatus] — of the vacancy being edited. One
/// that has already been on the market re-opens for free (the guard exempts it
/// via `first_published_at`), so it must never be sent to the checkout again.
/// `status` covers the same ground on a database that predates 0066, where
/// `first_published_at` simply reads as null.
bool isChargeableMarketEntry({
  required bool wantsToGoLive,
  required bool isEdit,
  DateTime? firstPublishedAt,
  String? currentStatus,
}) {
  if (!wantsToGoLive) return false;
  if (isEdit && (firstPublishedAt != null || currentStatus == 'open')) {
    return false;
  }
  return true;
}
