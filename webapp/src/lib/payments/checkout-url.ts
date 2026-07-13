// Build the Payme / Click checkout URLs for direct pay-per-listing. Pure so it
// unit-tests without a network. Only the merchant/service ids are needed here —
// they are PUBLIC (the private webhook secret keys live server-side in the edge
// functions, never in a checkout URL). Payme amounts are in tiyin (so'm × 100);
// Click in so'm. The order is addressed by our `order_id`.

export interface PaymeCheckout {
  merchantId: string;
  orderId: string;
  amountUzs: number;
  returnUrl: string;
}

/** Payme checkout: a base64 of `m=…;ac.order_id=…;a=<tiyin>;c=<return>`. */
export function paymeCheckoutUrl(o: PaymeCheckout): string {
  const parts = [
    `m=${o.merchantId}`,
    `ac.order_id=${o.orderId}`,
    `a=${Math.round(o.amountUzs * 100)}`,
    `c=${o.returnUrl}`,
  ].join(";");
  return `https://checkout.paycom.uz/${btoa(parts)}`;
}

export interface ClickCheckout {
  serviceId: string;
  merchantId: string;
  orderId: string;
  amountUzs: number;
  returnUrl: string;
}

/** Click checkout: a query string carrying our order id as transaction_param. */
export function clickCheckoutUrl(o: ClickCheckout): string {
  const q = new URLSearchParams({
    service_id: o.serviceId,
    merchant_id: o.merchantId,
    amount: String(o.amountUzs),
    transaction_param: o.orderId,
    return_url: o.returnUrl,
  });
  return `https://my.click.uz/services/pay?${q.toString()}`;
}
