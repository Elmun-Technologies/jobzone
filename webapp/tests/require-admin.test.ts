import type { User } from "@supabase/supabase-js";
import { beforeEach, describe, expect, it, vi } from "vitest";

import { requireAdmin } from "@/lib/auth/require-admin";

const mocks = vi.hoisted(() => ({
  hasSupabase: vi.fn(),
  getCurrentUser: vi.fn(),
  redirect: vi.fn((destination: string): never => {
    throw new Error(`NEXT_REDIRECT:${destination}`);
  }),
  notFound: vi.fn((): never => {
    throw new Error("NEXT_NOT_FOUND");
  }),
}));

vi.mock("server-only", () => ({}));
vi.mock("@/lib/data/supabase-env", () => ({
  hasSupabase: mocks.hasSupabase,
}));
vi.mock("@/lib/auth/user", () => ({
  getCurrentUser: mocks.getCurrentUser,
}));
vi.mock("next/navigation", () => ({
  redirect: mocks.redirect,
  notFound: mocks.notFound,
}));

function fakeUser(overrides: Partial<User>): User {
  return {
    id: "user-1",
    aud: "authenticated",
    created_at: "2026-01-01T00:00:00Z",
    app_metadata: {},
    user_metadata: {},
    ...overrides,
  } as User;
}

beforeEach(() => {
  vi.clearAllMocks();
  mocks.hasSupabase.mockReturnValue(true);
  mocks.getCurrentUser.mockResolvedValue(null);
});

describe("requireAdmin", () => {
  it("returns not found without looking up a user when Supabase is unavailable", async () => {
    mocks.hasSupabase.mockReturnValue(false);

    await expect(requireAdmin("uz")).rejects.toThrow("NEXT_NOT_FOUND");

    expect(mocks.getCurrentUser).not.toHaveBeenCalled();
    expect(mocks.notFound).toHaveBeenCalledOnce();
  });

  it("redirects signed-out users to the locale-specific sign-in page", async () => {
    await expect(requireAdmin("ru")).rejects.toThrow(
      "NEXT_REDIRECT:/ru/sign-in?next=/ru/admin",
    );

    expect(mocks.getCurrentUser).toHaveBeenCalledOnce();
    expect(mocks.redirect).toHaveBeenCalledExactlyOnceWith(
      "/ru/sign-in?next=/ru/admin",
    );
  });

  it.each([
    ["a regular user", fakeUser({ app_metadata: { role: "employer" } })],
    ["a forged user_metadata admin claim", fakeUser({ user_metadata: { role: "admin" } })],
  ])("returns not found for %s", async (_description, user) => {
    mocks.getCurrentUser.mockResolvedValue(user);

    await expect(requireAdmin("en")).rejects.toThrow("NEXT_NOT_FOUND");

    expect(mocks.notFound).toHaveBeenCalledOnce();
    expect(mocks.redirect).not.toHaveBeenCalled();
  });

  it("returns the user id for an admin app_metadata claim", async () => {
    mocks.getCurrentUser.mockResolvedValue(
      fakeUser({ id: "admin-1", app_metadata: { role: "admin" } }),
    );

    await expect(requireAdmin("uz")).resolves.toEqual({ userId: "admin-1" });

    expect(mocks.notFound).not.toHaveBeenCalled();
    expect(mocks.redirect).not.toHaveBeenCalled();
  });
});
