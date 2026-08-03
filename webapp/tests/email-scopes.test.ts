import { describe, expect, it } from "vitest";

import {
  DEFAULT_EMAIL_PREFS,
  EMAIL_PREF_COLUMNS,
  EMAIL_SCOPES,
  isUnsubscribeToken,
  parseScope,
  toEmailPrefs,
} from "@/lib/email-scopes";

// Both the one-click endpoint (which mail clients POST to, unattended) and the
// landing page hand their `scope`/`token` straight to a SECURITY DEFINER RPC,
// so what this module lets through is the whole client-side validation story.
describe("parseScope", () => {
  it("passes every scope the RPC accepts", () => {
    for (const scope of EMAIL_SCOPES) expect(parseScope(scope)).toBe(scope);
  });

  it("falls back to 'all' for anything unknown", () => {
    // "unsubscribe" with a scope we can't honor must silence everything
    // rather than silently doing nothing.
    expect(parseScope("push")).toBe("all");
    expect(parseScope("")).toBe("all");
    expect(parseScope(undefined)).toBe("all");
    expect(parseScope(42)).toBe("all");
    expect(parseScope(["job_match"])).toBe("all");
  });

  it("trims a scope that arrived with whitespace", () => {
    expect(parseScope(" marketing ")).toBe("marketing");
  });
});

describe("isUnsubscribeToken", () => {
  it("accepts a uuid, case-insensitively and with padding", () => {
    expect(isUnsubscribeToken("3f2504e0-4f89-11d3-9a0c-0305e82c3301")).toBe(
      true,
    );
    expect(isUnsubscribeToken("3F2504E0-4F89-11D3-9A0C-0305E82C3301")).toBe(
      true,
    );
    expect(isUnsubscribeToken(" 3f2504e0-4f89-11d3-9a0c-0305e82c3301 ")).toBe(
      true,
    );
  });

  it("rejects anything that isn't a uuid", () => {
    expect(isUnsubscribeToken("")).toBe(false);
    expect(isUnsubscribeToken("not-a-token")).toBe(false);
    expect(isUnsubscribeToken("3f2504e0-4f89-11d3-9a0c")).toBe(false);
    expect(isUnsubscribeToken(null)).toBe(false);
    expect(isUnsubscribeToken(123)).toBe(false);
    // A SQL fragment must never reach the RPC as a "token".
    expect(isUnsubscribeToken("' or 1=1 --")).toBe(false);
  });
});

describe("scope → column map", () => {
  it("covers every scope except the catch-all", () => {
    const mapped = Object.keys(EMAIL_PREF_COLUMNS).sort();
    const expected = EMAIL_SCOPES.filter((s) => s !== "all")
      .slice()
      .sort();
    expect(mapped).toEqual(expected);
  });

  it("names a real preference column for each scope", () => {
    for (const column of Object.values(EMAIL_PREF_COLUMNS)) {
      expect(Object.keys(DEFAULT_EMAIL_PREFS)).toContain(column);
    }
  });
});

describe("toEmailPrefs", () => {
  it("keeps the values the backend returned", () => {
    expect(
      toEmailPrefs({
        email_job_match: false,
        email_marketing: false,
        email_messages: true,
        email_application: false,
        email_reviews: true,
      }),
    ).toEqual({
      email_job_match: false,
      email_marketing: false,
      email_messages: true,
      email_application: false,
      email_reviews: true,
    });
  });

  it("fills in the column defaults for a partial or missing row", () => {
    // A row created before 0084 has no email_marketing; showing it as "off"
    // would misreport what the backend will actually do.
    expect(toEmailPrefs({ email_job_match: false })).toEqual({
      ...DEFAULT_EMAIL_PREFS,
      email_job_match: false,
    });
    expect(toEmailPrefs(null)).toEqual(DEFAULT_EMAIL_PREFS);
    expect(toEmailPrefs(undefined)).toEqual(DEFAULT_EMAIL_PREFS);
  });
});
