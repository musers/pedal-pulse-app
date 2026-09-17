enum BookingStatus {
  pendingPayment,
  confirmed,
  active,
  completed,
  cancelled,
}

enum SecurityDepositStatus {
  pending,
  held,
  refundInitiated,
  refunded,
  deducted,
}

class PricingBreakdown {
  final double rentalFare;
  final double gstAmount; // 18% GST standard in India for vehicle rentals
  final double securityDeposit;
  final double discountAmount;
  final double totalPayable;

  const PricingBreakdown({
    required this.rentalFare,
    required this.gstAmount,
    required this.securityDeposit,
    this.discountAmount = 0.0,
    required this.totalPayable,
  });
}

class Booking {
  final String id;
  final String bookingNumber;
  final String customerId;
  final String bikeId;
  final String pickupStationId;
  final String returnStationId;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? actualPickupTime;
  final DateTime? actualReturnTime;
  final BookingStatus status;
  final PricingBreakdown pricing;
  final SecurityDepositStatus depositStatus;
  final int? startingOdometer;
  final int? endingOdometer;
  final String? cancellationReason;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.bookingNumber,
    required this.customerId,
    required this.bikeId,
    required this.pickupStationId,
    required this.returnStationId,
    required this.startTime,
    required this.endTime,
    this.actualPickupTime,
    this.actualReturnTime,
    this.status = BookingStatus.confirmed,
    required this.pricing,
    this.depositStatus = SecurityDepositStatus.held,
    this.startingOdometer,
    this.endingOdometer,
    this.cancellationReason,
    required this.createdAt,
  });
}
