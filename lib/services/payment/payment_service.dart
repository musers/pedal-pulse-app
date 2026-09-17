enum PaymentStatus {
  initiated,
  success,
  failed,
  refunded,
}

class PaymentOrder {
  final String orderId;
  final double amount;
  final String currency;
  final String bookingId;

  const PaymentOrder({
    required this.orderId,
    required this.amount,
    this.currency = 'INR',
    required this.bookingId,
  });
}

class PaymentVerification {
  final String orderId;
  final String paymentId;
  final String signature;

  const PaymentVerification({
    required this.orderId,
    required this.paymentId,
    required this.signature,
  });
}

abstract class PaymentService {
  Future<PaymentOrder> createOrder({
    required String bookingId,
    required double amount,
    required String customerPhone,
    required String customerEmail,
  });

  Future<bool> verifyPayment(PaymentVerification verification);

  Future<bool> processRefund({
    required String paymentId,
    required double amount,
    String? reason,
  });
}
