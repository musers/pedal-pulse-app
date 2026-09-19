import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rental_subscription_platform/services/payment/payment_service.dart';
import 'package:rental_subscription_platform/services/payment/razorpay_payment_service.dart';

void main() {
  group('RazorpayPaymentService & Server Verification Unit Tests', () {
    const testKeySecret = 'test_secret_key_veloride_9988';
    late RazorpayPaymentService paymentService;

    setUp(() {
      paymentService = RazorpayPaymentService(
        razorpayKeyId: 'rzp_test_sample',
        razorpayKeySecret: testKeySecret,
      );
    });

    test('createOrder creates valid INR payment order', () async {
      final order = await paymentService.createOrder(
        bookingId: 'bk_sample_01',
        amount: 1324.68,
        customerPhone: '+919876500000',
        customerEmail: 'customer@veloride.in',
      );

      expect(order.orderId.isNotEmpty, isTrue);
      expect(order.amount, 1324.68);
      expect(order.currency, 'INR');
    });

    test('verifyPayment succeeds with valid HMAC-SHA256 cryptographic signature', () async {
      const orderId = 'order_test_8811';
      const paymentId = 'pay_test_9922';

      // Compute valid signature
      final payload = '$orderId|$paymentId';
      final hmac = Hmac(sha256, utf8.encode(testKeySecret));
      final validSignature = hmac.convert(utf8.encode(payload)).toString();

      final verification = PaymentVerification(
        orderId: orderId,
        paymentId: paymentId,
        signature: validSignature,
      );

      final isValid = await paymentService.verifyPayment(verification);
      expect(isValid, isTrue);
    });

    test('verifyPayment fails with tampered signature (client untrusted)', () async {
      const orderId = 'order_test_8811';
      const paymentId = 'pay_test_9922';

      const tamperedVerification = PaymentVerification(
        orderId: orderId,
        paymentId: paymentId,
        signature: 'fake_tampered_signature_1234567890abcdef',
      );

      final isValid = await paymentService.verifyPayment(tamperedVerification);
      expect(isValid, isFalse);
    });

    test('processRefund succeeds for deposit return', () async {
      final refundResult = await paymentService.processRefund(
        paymentId: 'pay_test_9922',
        amount: 999.00,
        reason: 'Security deposit released after hub intake',
      );

      expect(refundResult, isTrue);
    });
  });
}
