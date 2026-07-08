import { describe, expect, it } from "vitest";

import { safeNext } from "@/lib/auth/safe-next";

describe("safeNext", () => {
  const fb = "/uz/account";

  it("allows same-origin absolute paths", () => {
    expect(safeNext("/uz/account", fb)).toBe("/uz/account");
    expect(safeNext("/employer/jobs/new", fb)).toBe("/employer/jobs/new");
    expect(safeNext("/", fb)).toBe("/");
  });

  it("falls back for missing / relative targets", () => {
    expect(safeNext(null, fb)).toBe(fb);
    expect(safeNext(undefined, fb)).toBe(fb);
    expect(safeNext("", fb)).toBe(fb);
    expect(safeNext("account", fb)).toBe(fb);
  });

  it("blocks off-site and open-redirect vectors", () => {
    expect(safeNext("//evil.tld", fb)).toBe(fb);
    expect(safeNext("/\\evil.tld", fb)).toBe(fb);
    expect(safeNext("https://evil.tld", fb)).toBe(fb);
    expect(safeNext("@evil.tld", fb)).toBe(fb);
    expect(safeNext("/uz\\@evil.tld", fb)).toBe(fb);
    expect(safeNext("javascript:alert(1)", fb)).toBe(fb);
  });
});
