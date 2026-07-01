import type { User } from "@supabase/supabase-js";
import { describe, expect, it } from "vitest";

import { isAdminUser } from "@/lib/auth/admin-role";

function fakeUser(overrides: Partial<User>): User {
  return {
    id: "u1",
    aud: "authenticated",
    created_at: "2026-01-01T00:00:00Z",
    app_metadata: {},
    user_metadata: {},
    ...overrides,
  } as User;
}

describe("isAdminUser", () => {
  it("is false for null/undefined", () => {
    expect(isAdminUser(null)).toBe(false);
    expect(isAdminUser(undefined)).toBe(false);
  });

  it("is false without an app_metadata role", () => {
    expect(isAdminUser(fakeUser({}))).toBe(false);
  });

  it("is true only for app_metadata.role === 'admin'", () => {
    expect(isAdminUser(fakeUser({ app_metadata: { role: "admin" } }))).toBe(true);
    expect(isAdminUser(fakeUser({ app_metadata: { role: "employer" } }))).toBe(false);
    expect(isAdminUser(fakeUser({ app_metadata: { role: "Admin" } }))).toBe(false);
  });

  it("never trusts user_metadata (client-writable)", () => {
    // profiles.role / user_metadata are settable by the user; only the
    // server-only app_metadata claim may grant admin (matches DB is_admin()).
    expect(isAdminUser(fakeUser({ user_metadata: { role: "admin" } }))).toBe(false);
  });
});
