import 'dart:convert';

/// Build the Payme / Click checkout URLs for direct pay-per-listing. Pure (no
/// I/O) so it unit-tests without a device. Mirrors the web builder
/// `webapp/src/lib/payments/checkout-url.ts` exactly — same URL shapes so both
/// clients hit the same merchant. Only the PUBLIC merchant/service ids are used
/// here; the private webhook keys live server-side in the edge functions, never
/// in a checkout URL. Payme amounts are in tiyin (so'm × 100); Click in so'm.
/// The order is addressed by our `order_id`.

/// Payme checkout: a base64 of `m=…;ac.order_id=…;a=<tiyin>;c=<return>`.
String paymeCheckoutUrl({
  required String merchantId,
  required String orderId,
  required int amountUzs,
  required String returnUrl,
}) {
  final parts = [
    'm=$merchantId',
    'ac.order_id=$orderId',
    'a=${amountUzs * 100}',
    'c=$returnUrl',
  ].join(';');
  final encoded = base64.encode(utf8.encode(parts));
  return 'https://checkout.paycom.uz/$encoded';
}

/// Click checkout: a query string carrying our order id as transaction_param.
String clickCheckoutUrl({
  required String serviceId,
  required String merchantId,
  required String orderId,
  required int amountUzs,
  required String returnUrl,
}) {
  final q = Uri(
    scheme: 'https',
    host: 'my.click.uz',
    path: '/services/pay',
    queryParameters: {
      'service_id': serviceId,
      'merchant_id': merchantId,
      'amount': '$amountUzs',
      'transaction_param': orderId,
      'return_url': returnUrl,
    },
  );
  return q.toString();
}
