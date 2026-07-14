import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/monetization/domain/checkout_url.dart';

void main() {
  group('paymeCheckoutUrl', () {
    test('base64-encodes the merchant params with the amount in tiyin', () {
      final url = paymeCheckoutUrl(
        merchantId: 'M1',
        orderId: 'ord-1',
        amountUzs: 79900,
        returnUrl: 'https://x/paid',
      );
      expect(url.startsWith('https://checkout.paycom.uz/'), isTrue);
      final decoded = utf8.decode(base64.decode(url.split('/').last));
      expect(decoded, 'm=M1;ac.order_id=ord-1;a=7990000;c=https://x/paid');
    });
  });

  group('clickCheckoutUrl', () {
    test('carries the order id as transaction_param, amount in so\'m', () {
      final url = clickCheckoutUrl(
        serviceId: 'S1',
        merchantId: 'M2',
        orderId: 'ord-1',
        amountUzs: 79900,
        returnUrl: 'https://x/paid',
      );
      final u = Uri.parse(url);
      expect(
        '${u.scheme}://${u.host}${u.path}',
        'https://my.click.uz/services/pay',
      );
      expect(u.queryParameters['service_id'], 'S1');
      expect(u.queryParameters['merchant_id'], 'M2');
      expect(u.queryParameters['transaction_param'], 'ord-1');
      expect(u.queryParameters['amount'], '79900');
      expect(u.queryParameters['return_url'], 'https://x/paid');
    });
  });
}
