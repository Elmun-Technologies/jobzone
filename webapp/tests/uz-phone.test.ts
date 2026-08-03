import { describe, expect, it } from "vitest";

import {
  formatNational,
  isCompleteUzPhone,
  nationalDigits,
  toE164,
} from "@/lib/uz-phone";

describe("nationalDigits", () => {
  it("accepts every shape a person types a UZ number in", () => {
    for (const raw of [
      "+998 90 123 45 67",
      "998901234567",
      "+998901234567",
      "90 123 45 67",
      "90-123-45-67",
      "901234567",
    ]) {
      expect(nationalDigits(raw), raw).toBe("901234567");
    }
  });

  it("drops a leading 8 typed out of old habit", () => {
    expect(nationalDigits("8 90 123 45 67")).toBe("901234567");
  });

  it("keeps partial input as typed, so the field stays editable", () => {
    expect(nationalDigits("90 12")).toBe("9012");
    expect(nationalDigits("")).toBe("");
  });
});

describe("formatNational", () => {
  it("groups as you type", () => {
    expect(formatNational("9")).toBe("9");
    expect(formatNational("901")).toBe("90 1");
    expect(formatNational("901234567")).toBe("90 123 45 67");
  });
});

describe("toE164 / isCompleteUzPhone", () => {
  it("only yields a number once all nine digits are there", () => {
    expect(toE164("90 123 45 6")).toBe("");
    expect(isCompleteUzPhone("90 123 45 6")).toBe(false);
    expect(toE164("90 123 45 67")).toBe("+998901234567");
    expect(isCompleteUzPhone("+998 90 123 45 67")).toBe(true);
  });

  it("round-trips its own output", () => {
    expect(toE164(toE164("901234567"))).toBe("+998901234567");
  });
});
