import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  hasSupabase: vi.fn(),
  requireAdmin: vi.fn(),
  createAdminClient: vi.fn(),
  createClient: vi.fn(),
  getUserById: vi.fn(),
  updateUserById: vi.fn(),
  rpc: vi.fn(),
  redirect: vi.fn((path: string): never => {
    throw new Error(`redirect:${path}`);
  }),
  revalidatePath: vi.fn(),
}));

vi.mock("@/lib/data/supabase-env", () => ({
  hasSupabase: mocks.hasSupabase,
}));
vi.mock("@/lib/auth/require-admin", () => ({
  requireAdmin: mocks.requireAdmin,
}));
vi.mock("@/lib/supabase/admin", () => ({
  createAdminClient: mocks.createAdminClient,
}));
vi.mock("@/lib/supabase/server", () => ({ createClient: mocks.createClient }));
vi.mock("next/navigation", () => ({ redirect: mocks.redirect }));
vi.mock("next/cache", () => ({ revalidatePath: mocks.revalidatePath }));

import { setProfileAdmin } from "@/lib/actions/admin/users";

function adminForm(isAdmin: boolean) {
  const form = new FormData();
  form.set("locale", "ru");
  form.set("id", "target-user");
  form.set("isAdmin", isAdmin ? "1" : "0");
  return form;
}

beforeEach(() => {
  vi.clearAllMocks();
  mocks.hasSupabase.mockReturnValue(true);
  mocks.requireAdmin.mockResolvedValue({ userId: "caller-admin" });
  mocks.createAdminClient.mockReturnValue({
    auth: {
      admin: {
        getUserById: mocks.getUserById,
        updateUserById: mocks.updateUserById,
      },
    },
  });
  mocks.createClient.mockResolvedValue({ rpc: mocks.rpc });
  mocks.getUserById.mockResolvedValue({
    data: {
      user: {
        id: "target-user",
        app_metadata: { theme: "dark", role: "member" },
      },
    },
    error: null,
  });
  mocks.updateUserById.mockResolvedValue({ data: { user: {} }, error: null });
  mocks.rpc.mockResolvedValue({ error: null });
});

afterEach(() => vi.restoreAllMocks());

describe("setProfileAdmin", () => {
  it("denies unauthorized callers before creating or using the service-role client", async () => {
    mocks.requireAdmin.mockRejectedValue(new Error("unauthorized"));

    await expect(setProfileAdmin(adminForm(true))).rejects.toThrow("unauthorized");

    expect(mocks.requireAdmin).toHaveBeenCalledExactlyOnceWith("ru");
    expect(mocks.createAdminClient).not.toHaveBeenCalled();
    expect(mocks.getUserById).not.toHaveBeenCalled();
    expect(mocks.updateUserById).not.toHaveBeenCalled();
    expect(mocks.createClient).not.toHaveBeenCalled();
    expect(mocks.rpc).not.toHaveBeenCalled();
  });

  it.each([
    {
      action: "grants",
      isAdmin: true,
      metadata: { theme: "dark", role: "member" },
      expected: { theme: "dark", role: "admin" },
    },
    {
      action: "revokes",
      isAdmin: false,
      metadata: { theme: "dark", role: "admin", locale: "uz" },
      expected: { theme: "dark", locale: "uz" },
    },
  ])("$action admin while preserving other app metadata", async ({
    isAdmin,
    metadata,
    expected,
  }) => {
    mocks.getUserById.mockResolvedValue({
      data: { user: { id: "target-user", app_metadata: metadata } },
      error: null,
    });

    await setProfileAdmin(adminForm(isAdmin));

    expect(mocks.requireAdmin).toHaveBeenCalledExactlyOnceWith("ru");
    expect(mocks.updateUserById).toHaveBeenCalledExactlyOnceWith("target-user", {
      app_metadata: expected,
    });
    expect(mocks.rpc).toHaveBeenCalledExactlyOnceWith("admin_set_profile_admin", {
      p_profile: "target-user",
      p_is_admin: isAdmin,
    });
  });

  it("treats a resolved Auth update error as failure and skips the mirror RPC", async () => {
    mocks.updateUserById.mockResolvedValue({
      data: { user: null },
      error: { message: "Auth update rejected" },
    });

    await expect(setProfileAdmin(adminForm(true))).rejects.toThrow(
      "redirect:/ru/admin/users?notice=authkey",
    );

    expect(mocks.rpc).not.toHaveBeenCalled();
  });

  it("reports a user lookup error and does not update the claim or mirror", async () => {
    mocks.getUserById.mockResolvedValue({
      data: { user: null },
      error: { message: "lookup failed" },
    });

    await expect(setProfileAdmin(adminForm(true))).rejects.toThrow(
      "redirect:/ru/admin/users?notice=authkey",
    );

    expect(mocks.updateUserById).not.toHaveBeenCalled();
    expect(mocks.rpc).not.toHaveBeenCalled();
  });

  it("redirects when the service-role client is unavailable", async () => {
    mocks.createAdminClient.mockReturnValue(null);

    await expect(setProfileAdmin(adminForm(true))).rejects.toThrow(
      "redirect:/ru/admin/users?notice=authkey",
    );

    expect(mocks.getUserById).not.toHaveBeenCalled();
    expect(mocks.updateUserById).not.toHaveBeenCalled();
    expect(mocks.rpc).not.toHaveBeenCalled();
  });

  it("updates the Auth claim before mirroring it through the audited RPC", async () => {
    await setProfileAdmin(adminForm(true));

    expect(mocks.updateUserById.mock.invocationCallOrder[0]).toBeLessThan(
      mocks.rpc.mock.invocationCallOrder[0],
    );
    expect(mocks.revalidatePath).toHaveBeenCalledExactlyOnceWith(
      "/ru/admin/users",
    );
  });

  it("reports a mirror RPC error after the Auth claim update", async () => {
    mocks.rpc.mockResolvedValue({ error: { message: "RPC rejected" } });

    await expect(setProfileAdmin(adminForm(true))).rejects.toThrow(
      "redirect:/ru/admin/users?notice=err",
    );

    expect(mocks.updateUserById).toHaveBeenCalledOnce();
  });
});
