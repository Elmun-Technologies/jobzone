/**
 * Uzbekistan's 14 administrative regions (viloyatlar), canonical names —
 * mirrors `lib/core/utils/uzbekistan_regions.dart` on the mobile side (the
 * source of truth for `jobs.region` values written by the employer post-job
 * form on both clients).
 *
 * Derived from `UZ_DISTRICTS` rather than written out again: two hand-kept
 * copies of the same 14 strings is how a region ends up spelled one way in the
 * admin filter and another in the résumé picker — and a region that differs by
 * one apostrophe matches nothing.
 */
export { UZ_REGION_NAMES as UZ_REGIONS } from "./uz-districts";
