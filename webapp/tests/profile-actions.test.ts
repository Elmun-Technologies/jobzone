import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { saveAvatarUrl, updateProfile } from "@/lib/actions/profile";

const mocks = vi.hoisted(() => ({
  createClient: vi.fn(),
  getUser: vi.fn(),
  from: vi.fn(),
  update: vi.fn(),
  eq: vi.fn(),
  redirect: vi.fn((url: string): never => {
    throw new Error(`redirect:${url}`);
  }),
  revalidatePath: vi.fn(),
}));

vi.mock("@/lib/supabase/server", () => ({ createClient: mocks.createClient }));
vi.mock("next/navigation", () => ({ redirect: mocks.redirect }));
vi.mock("next/cache", () => ({ revalidatePath: mocks.revalidatePath }));

const storageBase = "https://project.supabase.co";
const avatarUrl = `${storageBase}/storage/v1/object/public/avatars/user-1/photo.jpg`;

beforeEach(() => {
  vi.clearAllMocks();
  vi.stubEnv("NEXT_PUBLIC_SUPABASE_URL", storageBase);
  mocks.createClient.mockResolvedValue({
    auth: { getUser: mocks.getUser },
    from: mocks.from,
  });
  mocks.getUser.mockResolvedValue({ data: { user: { id: "user-1" } } });
  mocks.from.mockReturnValue({ update: mocks.update });
  mocks.update.mockReturnValue({ eq: mocks.eq });
  mocks.eq.mockResolvedValue({ error: null });
});

afterEach(() => vi.unstubAllEnvs());

describe("saveAvatarUrl", () => {
  it.each([
    "https://attacker.example/photo.jpg",
    "https://project.supabase.co.attacker.example/storage/v1/object/public/avatars/photo.jpg",
    `${storageBase}/storage/v1/object/public/resumes/cv.pdf`,
    `${storageBase}/storage/v1/object/public/avatars-evil/photo.jpg`,
    "javascript:alert(1)",
  ])("rejects untrusted avatar URL %j before backend access", async (url) => {
    expect(await saveAvatarUrl(url)).toEqual({ ok: false });
    expect(mocks.createClient).not.toHaveBeenCalled();
  });

  it("fails closed when the storage origin is not configured", async () => {
    vi.stubEnv("NEXT_PUBLIC_SUPABASE_URL", "");
    expect(await saveAvatarUrl(avatarUrl)).toEqual({ ok: false });
    expect(mocks.createClient).not.toHaveBeenCalled();
  });

  it("does not write for a signed-out caller", async () => {
    mocks.getUser.mockResolvedValue({ data: { user: null } });
    expect(await saveAvatarUrl(avatarUrl)).toEqual({ ok: false });
    expect(mocks.from).not.toHaveBeenCalled();
    expect(mocks.revalidatePath).not.toHaveBeenCalled();
  });

  it("updates only the authenticated profile and refreshes it after success", async () => {
    expect(await saveAvatarUrl(avatarUrl)).toEqual({ ok: true });
    expect(mocks.from).toHaveBeenCalledExactlyOnceWith("profiles");
    expect(mocks.update).toHaveBeenCalledExactlyOnceWith({
      avatar_url: avatarUrl,
    });
    expect(mocks.eq).toHaveBeenCalledExactlyOnceWith("id", "user-1");
    expect(mocks.revalidatePath).toHaveBeenCalledExactlyOnceWith("/account");
  });

  it("does not report success or refresh when the database refuses the write", async () => {
    mocks.eq.mockResolvedValue({ error: { message: "RLS denied" } });
    expect(await saveAvatarUrl(avatarUrl)).toEqual({ ok: false });
    expect(mocks.revalidatePath).not.toHaveBeenCalled();
  });

  it("fails closed on a session lookup exception without writing", async () => {
    mocks.getUser.mockRejectedValue(new Error("auth unavailable"));
    expect(await saveAvatarUrl(avatarUrl)).toEqual({ ok: false });
    expect(mocks.from).not.toHaveBeenCalled();
    expect(mocks.revalidatePath).not.toHaveBeenCalled();
  });
});

function profileForm() {
  const form = new FormData();
  form.set("locale", "ru");
  form.set("fullName", "  Test Person  ");
  form.set("headline", "  Electrician  ");
  form.set("bio", "   ");
  form.set("city", "  Toshkent ");
  form.set("id", "someone-else");
  form.set("role", "admin");
  form.set("is_admin", "true");
  return form;
}

describe("updateProfile", () => {
  it("redirects guests before attempting a profile write", async () => {
    mocks.getUser.mockResolvedValue({ data: { user: null } });
    await expect(updateProfile({}, profileForm())).rejects.toThrow(
      "redirect:/ru/sign-in",
    );
    expect(mocks.from).not.toHaveBeenCalled();
  });

  it("whitelists editable fields and uses session identity, not submitted privileges or ID", async () => {
    await expect(updateProfile({}, profileForm())).rejects.toThrow(
      "redirect:/ru/account",
    );
    expect(mocks.from).toHaveBeenCalledExactlyOnceWith("profiles");
    expect(mocks.update).toHaveBeenCalledExactlyOnceWith({
      full_name: "Test Person",
      headline: "Electrician",
      bio: null,
      phone: null,
      city: "Toshkent",
      country: null,
    });
    expect(mocks.eq).toHaveBeenCalledExactlyOnceWith("id", "user-1");
  });

  it("returns a database failure without a success redirect", async () => {
    mocks.eq.mockResolvedValue({ error: { message: "write rejected" } });
    expect(await updateProfile({}, profileForm())).toEqual({
      error: "unknown",
    });
    expect(mocks.redirect).not.toHaveBeenCalled();
  });
});
