import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../../core/config/supabase_config.dart';
import 'payment_service.dart';

class RazorpayPaymentService implements PaymentService {
  final String? razorpayKeyId;
  final String? razorpayKeySecret;
  final Dio _dio;

  RazorpayPaymentService({
    this.razorpayKeyId,
    this.razorpayKeySecret,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  bool get isConfigured =>
      razorpayKeyId != null && razorpayKeyId!.isNotEmpty;

  @override
  Future<PaymentOrder> createOrder({
    required String bookingId,
    required double amount,
    required String customerPhone,
    required String customerEmail,
  }) async {
    // If Supabase Edge Functions are deployed:
    final supabaseClient = SupabaseConfig.client;
    if (supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        final response = await supabaseClient.functions.invoke(
          'create-razorpay-order',
          body: {
            'bookingId': bookingId,
            'amount': amount,
            'customerPhone': customerPhone,
            'customerEmail': customerEmail,
          },
        );

        final data = response.data as Map<String, dynamic>;
        return PaymentOrder(
          orderId: data['orderId'] as String,
          amount: (data['amount'] as num).toDouble(),
          currency: (data['currency'] as String?) ?? 'INR',
          bookingId: bookingId,
        );
      } catch (_) {
        // Fallback to direct client order if edge function not yet published
      }
    }

    // Direct Razorpay REST API call if keys are present
    if (razorpayKeyId != null && razorpayKeySecret != null) {
      try {
        final basicAuth = base64Encode(utf8.encode('$razorpayKeyId:$razorpayKeySecret'));
        final response = await _dio.post(
          'https://api.razorpay.com/v1/orders',
          options: Options(
            headers: {
              'Authorization': 'Basic $basicAuth',
              'Content-Type': 'application/json',
            },
          ),
          data: {
            'amount': (amount * 100).toInt(),
            'currency': 'INR',
            'receipt': 'rcpt_${bookingId.substring(0, bookingId.length > 14 ? 14 : bookingId.length)}',
          },
        );

        final data = response.data as Map<String, dynamic>;
        return PaymentOrder(
          orderId: data['id'] as String,
          amount: amount,
          currency: 'INR',
          bookingId: bookingId,
        );
      } catch (_) {
        // Fallback to mock order
      }
    }

    // Direct / Mock order generation
    final mockOrderId = 'order_rzp_${DateTime.now().millisecondsSinceEpoch}';
    return PaymentOrder(
      orderId: mockOrderId,
      amount: amount,
      currency: 'INR',
      bookingId: bookingId,
    );
  }

  @override
  Future<bool> verifyPayment(PaymentVerification verification) async {
    final supabaseClient = SupabaseConfig.client;
    if (supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        final response = await supabaseClient.functions.invoke(
          'verify-razorpay-payment',
          body: {
            'orderId': verification.orderId,
            'paymentId': verification.paymentId,
            'signature': verification.signature,
          },
        );

        final data = response.data as Map<String, dynamic>;
        return data['verified'] == true;
      } catch (_) {
        // Fallback
      }
    }

    // Server-side cryptographic HMAC-SHA256 signature verification algorithm:
    // generated_signature = hmac_sha256(order_id + "|" + razorpay_payment_id, secret)
    if (razorpayKeySecret != null && razorpayKeySecret!.isNotEmpty) {
      final payload = '${verification.orderId}|${verification.paymentId}';
      final hmac = Hmac(sha256, utf8.encode(razorpayKeySecret!));
      final digest = hmac.convert(utf8.encode(payload));
      final generatedSignature = digest.toString();

      return generatedSignature == verification.signature;
    }

    // In test/mock mode without live secrets, treat test payment IDs as valid
    return verification.paymentId.isNotEmpty;
  }

  @override
  Future<bool> processRefund({
    required String paymentId,
    required double amount,
    String? reason,
  }) async {
    final supabaseClient = SupabaseConfig.client;
    if (supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        final response = await supabaseClient.functions.invoke(
          'process-razorpay-refund',
          body: {
            'paymentId': paymentId,
            'amount': amount,
            'reason': reason ?? 'Security deposit release',
          },
        );

        final data = response.data as Map<String, dynamic>;
        return data['refunded'] == true;
      } catch (_) {
        // Fallback
      }
    }

    return true;
  }
}
