import { describe, expect, it } from "vitest";

import { suggestCategorySlug } from "@/lib/professions";

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
