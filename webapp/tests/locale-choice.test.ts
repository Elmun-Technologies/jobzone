import { describe, expect, it } from "vitest";

import { preferredFromHeader, shouldAskLanguage } from "@/lib/locale-choice";

describe("preferredFromHeader", () => {
  it("picks the highest-quality supported language", () => {
    expect(preferredFromHeader("ru-RU,ru;q=0.9,en;q=0.8")).toBe("ru");
    expect(preferredFromHeader("uz-Latn-UZ,uz;q=0.9")).toBe("uz");
    expect(preferredFromHeader("en-GB,en;q=0.5")).toBe("en");
  });

  it("skips languages we don't serve", () => {
    expect(preferredFromHeader("kk-KZ,tr;q=0.9,ru;q=0.8")).toBe("ru");
    expect(preferredFromHeader("kk-KZ,tr;q=0.9")).toBeNull();
  });

  it("honours quality order over header order", () => {
    expect(preferredFromHeader("en;q=0.4,ru;q=0.9")).toBe("ru");
  });

  it("returns null without a usable header", () => {
    expect(preferredFromHeader(null)).toBeNull();
    expect(preferredFromHeader("")).toBeNull();
    expect(preferredFromHeader("ru;q=0")).toBeNull();
  });
});

describe("shouldAskLanguage", () => {
  const ru = "ru-RU,ru;q=0.9";

  it("asks a Russian browser that landed on an Uzbek page", () => {
    expect(
      shouldAskLanguage({
        current: "uz",
        chosen: undefined,
        acceptLanguage: ru,
        userAgent: "Mozilla/5.0 (iPhone)",
      }),
    ).toBe(true);
  });

  it("stays out of the way when the page already matches", () => {
    expect(
      shouldAskLanguage({
        current: "ru",
        chosen: undefined,
        acceptLanguage: ru,
        userAgent: "Mozilla/5.0 (iPhone)",
      }),
    ).toBe(false);
  });

  it("never asks twice", () => {
    expect(
      shouldAskLanguage({
        current: "uz",
        chosen: "uz",
        acceptLanguage: ru,
        userAgent: "Mozilla/5.0 (iPhone)",
      }),
    ).toBe(false);
  });

  it("never covers the page for a crawler", () => {
    for (const ua of [
      "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
      "Mozilla/5.0 (compatible; YandexBot/3.0)",
      "facebookexternalhit/1.1",
    ]) {
      expect(
        shouldAskLanguage({
          current: "uz",
          chosen: undefined,
          acceptLanguage: ru,
          userAgent: ua,
        }),
      ).toBe(false);
    }
  });

  it("says nothing without a language signal", () => {
    expect(
      shouldAskLanguage({
        current: "uz",
        chosen: undefined,
        acceptLanguage: null,
        userAgent: "Mozilla/5.0 (iPhone)",
      }),
    ).toBe(false);
  });
});
