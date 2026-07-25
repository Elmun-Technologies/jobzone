import { describe, expect, it } from "vitest";

import { notificationHref, toNotificationKind } from "@/lib/notifications";

// The account list and the realtime toast both route through this, so a
// regression here silently breaks deep-links in two places at once.
describe("notificationHref", () => {
  it("deep-links a job match to its vacancy", () => {
    expect(notificationHref("job_match", { job_id: "abc" })).toBe("/jobs/abc");
  });

  it("falls back to the inbox when a message has no conversation", () => {
    expect(notificationHref("message", { conversation_id: "c1" })).toBe(
      "/account/messages/c1",
    );
    expect(notificationHref("message", {})).toBe("/account/messages");
  });

  it("sends application updates to the applications list", () => {
    expect(notificationHref("application_update", {})).toBe(
      "/account/applications",
    );
  });

  it("returns null for rows with nowhere to go", () => {
    expect(notificationHref("system", {})).toBeNull();
    expect(notificationHref("review", {})).toBeNull();
    // A malformed payload must not produce "/jobs/undefined".
    expect(notificationHref("job_match", { job_id: 42 })).toBeNull();
    expect(notificationHref("job_match", {})).toBeNull();
  });
});

describe("toNotificationKind", () => {
  it("passes known kinds through", () => {
    expect(toNotificationKind("job_match")).toBe("job_match");
  });

  it("narrows anything unknown to system", () => {
    expect(toNotificationKind("wat")).toBe("system");
    expect(toNotificationKind(null)).toBe("system");
    expect(toNotificationKind(undefined)).toBe("system");
  });
});
