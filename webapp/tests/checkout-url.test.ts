import { describe, expect, it } from "vitest";

import { clickCheckoutUrl, paymeCheckoutUrl } from "@/lib/payments/checkout-url";

describe("paymeCheckoutUrl", () => {
  it("base64-encodes the merchant params with the amount in tiyin", () => {
    const url = paymeCheckoutUrl({
      merchantId: "M1",
      orderId: "ord-1",
      amountUzs: 79900,
      returnUrl: "https://x/paid",
    });
    expect(url.startsWith("https://checkout.paycom.uz/")).toBe(true);
    const decoded = atob(url.split("/").pop()!);
    expect(decoded).toBe("m=M1;ac.order_id=ord-1;a=7990000;c=https://x/paid");
  });
});

describe("clickCheckoutUrl", () => {
  it("carries the order id as transaction_param, amount in so'm", () => {
    const url = clickCheckoutUrl({
      serviceId: "S1",
      merchantId: "M2",
      orderId: "ord-1",
      amountUzs: 79900,
      returnUrl: "https://x/paid",
    });
    const u = new URL(url);
    expect(u.origin + u.pathname).toBe("https://my.click.uz/services/pay");
    expect(u.searchParams.get("service_id")).toBe("S1");
    expect(u.searchParams.get("merchant_id")).toBe("M2");
    expect(u.searchParams.get("transaction_param")).toBe("ord-1");
    expect(u.searchParams.get("amount")).toBe("79900");
    expect(u.searchParams.get("return_url")).toBe("https://x/paid");
  });
});
