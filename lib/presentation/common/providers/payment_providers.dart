import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/payment/payment_service.dart';
import '../../../services/payment/razorpay_payment_service.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  const keyId = String.fromEnvironment('RAZORPAY_KEY_ID', defaultValue: '');
  const keySecret = String.fromEnvironment('RAZORPAY_KEY_SECRET', defaultValue: '');

  return RazorpayPaymentService(
    razorpayKeyId: keyId.isNotEmpty ? keyId : null,
    razorpayKeySecret: keySecret.isNotEmpty ? keySecret : null,
  );
});
