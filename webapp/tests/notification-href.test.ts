import { describe, expect, it } from "vitest";

import {
  notificationHref,
  notificationStatus,
  notificationTitleKey,
  toNotificationKind,
} from "@/lib/notifications";

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

// The list page and the toast both localize through these, so a regression
// puts English back in front of an Uzbek-speaking seeker in two places.
describe("notificationTitleKey", () => {
  it("localizes the types whose title the DB stores in English", () => {
    // 0005 writes the literal 'Application update' / 'New message'.
    expect(notificationTitleKey("application_update")).toBe(
      "typeApplicationUpdate",
    );
    expect(notificationTitleKey("message")).toBe("typeMessage");
  });

  it("keeps the stored title where it is content, not copy", () => {
    // job_match's title is the vacancy's own name (0036); review/system are
    // admin-authored broadcast text already written in its final language.
    expect(notificationTitleKey("job_match")).toBeNull();
    expect(notificationTitleKey("review")).toBeNull();
    expect(notificationTitleKey("system")).toBeNull();
  });
});

describe("notificationStatus", () => {
  it("reads the status a application update carries", () => {
    expect(
      notificationStatus("application_update", { status: "shortlisted" }),
    ).toBe("shortlisted");
  });

  it("keeps the stored body for every other type", () => {
    // A chat message's body is the message preview — never overwrite it.
    expect(notificationStatus("message", { status: "hired" })).toBeNull();
    expect(notificationStatus("job_match", { status: "hired" })).toBeNull();
  });

  it("falls back to the stored body for a status it has no label for", () => {
    // A status added to the DB after this build shipped must not render as a
    // missing-translation error.
    expect(
      notificationStatus("application_update", { status: "teleported" }),
    ).toBeNull();
    expect(notificationStatus("application_update", {})).toBeNull();
    expect(notificationStatus("application_update", { status: 7 })).toBeNull();
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
