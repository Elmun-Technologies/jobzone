import { describe, expect, it } from "vitest";

import { suggestCategorySlug, suggestProfessions } from "@/lib/professions";

describe("suggestCategorySlug", () => {
  it("maps a known profession to its category slug", () => {
    expect(suggestCategorySlug("Sotuvchi")).toBe("retail");
    expect(suggestCategorySlug("Ofitsiant")).toBe("horeca");
    expect(suggestCategorySlug("Haydovchi")).toBe("driver");
    expect(suggestCategorySlug("Farrosh")).toBe("cleaning");
    expect(suggestCategorySlug("Payvandchi")).toBe("construction");
  });

  it("matches when the profession is a word inside a longer title", () => {
    expect(suggestCategorySlug("Tajribali Sotuvchi kerak")).toBe("retail");
  });

  it("ignores apostrophes/case (Bog'bon)", () => {
    expect(suggestCategorySlug("bog'bon")).toBe("agriculture");
  });

  it("returns null for short or unknown titles", () => {
    expect(suggestCategorySlug("ab")).toBeNull();
    expect(suggestCategorySlug("Kosmonavt")).toBeNull();
  });
});

describe("suggestProfessions", () => {
  it("stays quiet until the second character", () => {
    expect(suggestProfessions("s")).toEqual([]);
    expect(suggestProfessions("")).toEqual([]);
    expect(suggestProfessions("so").length).toBeGreaterThan(0);
  });

  it("ranks prefix matches above mid-word ones", () => {
    const hits = suggestProfessions("kassir");
    expect(hits[0]).toBe("Kassir");
  });

  it("ignores case and apostrophe glyphs", () => {
    expect(suggestProfessions("bogbon")).toContain("Bog'bon");
    expect(suggestProfessions("BOGʻBON")).toContain("Bog'bon");
  });

  it("respects the limit and returns nothing for unknown trades", () => {
    expect(suggestProfessions("a", 5).length).toBeLessThanOrEqual(5);
    expect(suggestProfessions("chi").length).toBeLessThanOrEqual(8);
    expect(suggestProfessions("kosmonavt")).toEqual([]);
  });
});
