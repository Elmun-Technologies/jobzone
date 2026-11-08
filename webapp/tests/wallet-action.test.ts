import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { payTopUp } from "@/lib/actions/wallet";

const mocks = vi.hoisted(() => ({
  createClient: vi.fn(),
  getUser: vi.fn(),
  rpc: vi.fn(),
  invoke: vi.fn(),
  headers: vi.fn(),
  redirect: vi.fn((url: string): never => {
    throw new Error(`redirect:${url}`);
  }),
  revalidatePath: vi.fn(),
}));

vi.mock("@/lib/supabase/server", () => ({ createClient: mocks.createClient }));
vi.mock("next/headers", () => ({ headers: mocks.headers }));
vi.mock("next/navigation", () => ({ redirect: mocks.redirect }));
vi.mock("next/cache", () => ({ revalidatePath: mocks.revalidatePath }));

function topUp(overrides: Record<string, string> = {}) {
  const form = new FormData();
  for (const [key, value] of Object.entries({
    companyId: "company-1",
    amount: "50 000",
    provider: "click",
    locale: "ru",
    ...overrides,
  })) {
    form.set(key, value);
  }
  return payTopUp({}, form);
}

beforeEach(() => {
  vi.clearAllMocks();
  for (const name of [
    "NEXT_PUBLIC_CLICK_SERVICE_ID",
    "NEXT_PUBLIC_CLICK_MERCHANT_ID",
    "NEXT_PUBLIC_PAYME_MERCHANT_ID",
    "NEXT_PUBLIC_RAHMAT_ENABLED",
  ]) {
    vi.stubEnv(name, "");
  }
  mocks.createClient.mockResolvedValue({
    auth: { getUser: mocks.getUser },
    rpc: mocks.rpc,
    functions: { invoke: mocks.invoke },
  });
  mocks.getUser.mockResolvedValue({ data: { user: { id: "employer-1" } } });
  mocks.rpc.mockResolvedValue({
    data: [{ order_id: "pending-order", amount_uzs: 50000 }],
    error: null,
  });
  mocks.headers.mockResolvedValue(new Headers({ host: "jobs.example" }));
  mocks.invoke.mockResolvedValue({ data: null, error: null });
});

afterEach(() => vi.unstubAllEnvs());

describe("payTopUp", () => {
  it.each(["", "4999", "50000001", "5000.5", "-5000", "5e4"])(
    "rejects invalid amount %j before creating a client",
    async (amount) => {
      expect(await topUp({ amount })).toEqual({ error: "amount" });
      expect(mocks.createClient).not.toHaveBeenCalled();
    },
  );

  it("rejects a missing company before accessing the backend", async () => {
    expect(await topUp({ companyId: " " })).toEqual({ error: "amount" });
    expect(mocks.createClient).not.toHaveBeenCalled();
  });

  it("does not create an order for a signed-out caller", async () => {
    mocks.getUser.mockResolvedValue({ data: { user: null } });
    expect(await topUp()).toEqual({ error: "signedOut" });
    expect(mocks.rpc).not.toHaveBeenCalled();
    expect(mocks.invoke).not.toHaveBeenCalled();
    expect(mocks.redirect).not.toHaveBeenCalled();
  });

  it.each([
    {
      data: null,
      error: { message: "amount_out_of_range" },
      expected: "amount",
    },
    {
      data: null,
      error: { message: "not_company_owner" },
      expected: "unknown",
    },
    { data: [], error: null, expected: "unknown" },
    { data: null, error: null, expected: "unknown" },
    {
      data: { order_id: "unexpected-shape" },
      error: null,
      expected: "unknown",
    },
  ])(
    "stops checkout for an unsuccessful order: $expected",
    async ({ data, error, expected }) => {
      mocks.rpc.mockResolvedValue({ data, error });
      expect(await topUp()).toEqual({ error: expected });
      expect(mocks.headers).not.toHaveBeenCalled();
      expect(mocks.invoke).not.toHaveBeenCalled();
      expect(mocks.redirect).not.toHaveBeenCalled();
      expect(mocks.revalidatePath).not.toHaveBeenCalled();
    },
  );

  it("records only a pending RPC order when no gateway is configured", async () => {
    expect(await topUp({ companyId: " company-1 ", locale: "" })).toEqual({
      ok: true,
    });
    expect(mocks.rpc).toHaveBeenCalledExactlyOnceWith("create_topup_order", {
      p_amount_uzs: 50000,
      p_company_id: "company-1",
    });
    expect(mocks.revalidatePath).toHaveBeenCalledExactlyOnceWith(
      "/uz/employer/wallet",
    );
    expect(mocks.redirect).not.toHaveBeenCalled();
    expect(mocks.invoke).not.toHaveBeenCalled();
  });

  it("uses the server order ID and amount for Click, not submitted payment fields", async () => {
    vi.stubEnv("NEXT_PUBLIC_CLICK_SERVICE_ID", "click-service");
    vi.stubEnv("NEXT_PUBLIC_CLICK_MERCHANT_ID", "click-merchant");
    mocks.rpc.mockResolvedValue({
      data: [{ order_id: "server-order", amount_uzs: "75000" }],
      error: null,
    });
    mocks.headers.mockResolvedValue(
      new Headers({ host: "jobs.example", "x-forwarded-proto": "http" }),
    );
    await expect(
      topUp({ order_id: "forged-order", amount_uzs: "1" }),
    ).rejects.toThrow("redirect:");
    const url = new URL(mocks.redirect.mock.calls[0][0]);
    expect(url.origin + url.pathname).toBe("https://my.click.uz/services/pay");
    expect(Object.fromEntries(url.searchParams)).toEqual({
      service_id: "click-service",
      merchant_id: "click-merchant",
      transaction_param: "server-order",
      amount: "75000",
      return_url: "http://jobs.example/ru/employer/wallet",
    });
    expect(mocks.revalidatePath).not.toHaveBeenCalled();
  });

  it("uses the server order and tiyin amount for Payme", async () => {
    vi.stubEnv("NEXT_PUBLIC_PAYME_MERCHANT_ID", "payme-merchant");
    await expect(topUp({ provider: "payme" })).rejects.toThrow("redirect:");
    const url = mocks.redirect.mock.calls[0][0];
    expect(url).toMatch(/^https:\/\/checkout\.paycom\.uz\//);
    const encoded = url.slice("https://checkout.paycom.uz/".length);
    expect(Buffer.from(encoded, "base64").toString()).toBe(
      "m=payme-merchant;ac.order_id=pending-order;a=5000000;c=https://jobs.example/ru/employer/wallet",
    );
    expect(mocks.revalidatePath).not.toHaveBeenCalled();
  });

  it("requests a Rahmat invoice for the server-created order", async () => {
    vi.stubEnv("NEXT_PUBLIC_RAHMAT_ENABLED", "1");
    mocks.invoke.mockResolvedValue({
      data: { ok: true, checkout_url: "https://pay.example/invoice" },
      error: null,
    });
    await expect(topUp({ provider: "rahmat" })).rejects.toThrow(
      "redirect:https://pay.example/invoice",
    );
    expect(mocks.invoke).toHaveBeenCalledExactlyOnceWith("rahmat-invoice", {
      body: {
        order_id: "pending-order",
        return_url: "https://jobs.example/ru/employer/wallet",
      },
    });
    expect(mocks.revalidatePath).not.toHaveBeenCalled();
  });

  it.each([
    { data: null, error: { message: "gateway unavailable" } },
    {
      data: { ok: false, checkout_url: "https://pay.example/rejected" },
      error: null,
    },
    { data: { ok: true }, error: null },
  ])(
    "keeps the order pending when Rahmat cannot return checkout: %j",
    async (result) => {
      vi.stubEnv("NEXT_PUBLIC_RAHMAT_ENABLED", "1");
      mocks.invoke.mockResolvedValue(result);
      expect(await topUp({ provider: "rahmat" })).toEqual({ ok: true });
      expect(mocks.redirect).not.toHaveBeenCalled();
      expect(mocks.revalidatePath).toHaveBeenCalledWith("/ru/employer/wallet");
      expect(mocks.rpc).toHaveBeenCalledTimes(1);
    },
  );
});
