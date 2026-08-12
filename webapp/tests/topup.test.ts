import { describe, expect, it } from "vitest";

import {
  isValidTopUpAmount,
  MAX_TOPUP_UZS,
  MIN_TOPUP_UZS,
  parseTopUpAmount,
} from "@/lib/payments/topup";

// The form uses these to enable the pay buttons and the server action uses them
// to refuse a submission; if they ever disagree, an employer gets sent to a
// gateway for a charge `create_topup_order` (0085) will reject.
describe("parseTopUpAmount", () => {
  it("reads what the amount field actually contains", () => {
    expect(parseTopUpAmount("50000")).toBe(50000);
    // The input renders grouped ("50 000") and posts what's rendered.
    expect(parseTopUpAmount("50 000")).toBe(50000);
    // …including a non-breaking space, which is what some keyboards insert.
    expect(parseTopUpAmount("1 000 000")).toBe(1000000);
  });

  it("rejects anything that isn't a plain amount", () => {
    expect(parseTopUpAmount("")).toBeNaN();
    expect(parseTopUpAmount("50,000")).toBeNaN();
    expect(parseTopUpAmount("-50000")).toBeNaN();
    expect(parseTopUpAmount("5e5")).toBeNaN();
    expect(parseTopUpAmount("abc")).toBeNaN();
    expect(parseTopUpAmount(null)).toBeNaN();
  });
});

describe("isValidTopUpAmount", () => {
  it("accepts the range the RPC accepts", () => {
    expect(isValidTopUpAmount(MIN_TOPUP_UZS)).toBe(true);
    expect(isValidTopUpAmount(100000)).toBe(true);
    expect(isValidTopUpAmount(MAX_TOPUP_UZS)).toBe(true);
  });

  it("refuses amounts outside it", () => {
    expect(isValidTopUpAmount(MIN_TOPUP_UZS - 1)).toBe(false);
    expect(isValidTopUpAmount(MAX_TOPUP_UZS + 1)).toBe(false);
    expect(isValidTopUpAmount(0)).toBe(false);
    expect(isValidTopUpAmount(-100000)).toBe(false);
  });

  it("refuses non-numbers and fractions of a so'm", () => {
    // Click charges in so'm and Payme in tiyin derived from it; a fractional
    // so'm makes the two amounts disagree and the callback fail validation.
    expect(isValidTopUpAmount(50000.5)).toBe(false);
    expect(isValidTopUpAmount(Number.NaN)).toBe(false);
    expect(isValidTopUpAmount(Number.POSITIVE_INFINITY)).toBe(false);
  });
});
