import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';

class MockBookingRepository implements BookingRepository {
  final List<Booking> _bookings = [
    Booking(
      id: 'bk_demo_active_01',
      bookingNumber: 'VR-BLR-8921',
      customerId: 'usr_demo_customer_01',
      bikeId: 'bike_001',
      pickupStationId: 'st_indiranagar',
      returnStationId: 'st_indiranagar',
      startTime: DateTime.now().subtract(const Duration(hours: 1)),
      endTime: DateTime.now().add(const Duration(hours: 3)),
      pricing: const PricingBreakdown(
        rentalFare: 276.00,
        gstAmount: 49.68,
        securityDeposit: 999.00,
        totalPayable: 1324.68,
      ),
      status: BookingStatus.confirmed,
      depositStatus: SecurityDepositStatus.held,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  @override
  Future<List<Booking>> getUserBookings(String customerId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _bookings.where((b) => b.customerId == customerId).toList();
  }

  @override
  Future<Booking?> getBookingById(String bookingId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _bookings.firstWhere((b) => b.id == bookingId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Booking> createBooking({
    required String customerId,
    required String bikeId,
    required String pickupStationId,
    required String returnStationId,
    required DateTime startTime,
    required DateTime endTime,
    required PricingBreakdown pricing,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final id = 'bk_${DateTime.now().millisecondsSinceEpoch}';
    final bookingNumber = 'VR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final booking = Booking(
      id: id,
      bookingNumber: bookingNumber,
      customerId: customerId,
      bikeId: bikeId,
      pickupStationId: pickupStationId,
      returnStationId: returnStationId,
      startTime: startTime,
      endTime: endTime,
      pricing: pricing,
      createdAt: DateTime.now(),
      status: BookingStatus.confirmed,
    );

    _bookings.insert(0, booking);
    return booking;
  }

  @override
  Future<Booking> cancelBooking(String bookingId, String reason) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) throw Exception('Booking not found');

    final old = _bookings[index];
    final updated = Booking(
      id: old.id,
      bookingNumber: old.bookingNumber,
      customerId: old.customerId,
      bikeId: old.bikeId,
      pickupStationId: old.pickupStationId,
      returnStationId: old.returnStationId,
      startTime: old.startTime,
      endTime: old.endTime,
      actualPickupTime: old.actualPickupTime,
      actualReturnTime: old.actualReturnTime,
      status: BookingStatus.cancelled,
      pricing: old.pricing,
      depositStatus: SecurityDepositStatus.refundInitiated,
      cancellationReason: reason,
      createdAt: old.createdAt,
    );

    _bookings[index] = updated;
    return updated;
  }

  @override
  Future<Booking> recordPickup(String bookingId, int startingOdometer) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) throw Exception('Booking not found');

    final old = _bookings[index];
    final updated = Booking(
      id: old.id,
      bookingNumber: old.bookingNumber,
      customerId: old.customerId,
      bikeId: old.bikeId,
      pickupStationId: old.pickupStationId,
      returnStationId: old.returnStationId,
      startTime: old.startTime,
      endTime: old.endTime,
      actualPickupTime: DateTime.now(),
      status: BookingStatus.active,
      pricing: old.pricing,
      depositStatus: old.depositStatus,
      startingOdometer: startingOdometer,
      createdAt: old.createdAt,
    );

    _bookings[index] = updated;
    return updated;
  }

  @override
  Future<Booking> recordReturn(String bookingId, int endingOdometer, String returnStationId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) throw Exception('Booking not found');

    final old = _bookings[index];
    final updated = Booking(
      id: old.id,
      bookingNumber: old.bookingNumber,
      customerId: old.customerId,
      bikeId: old.bikeId,
      pickupStationId: old.pickupStationId,
      returnStationId: returnStationId,
      startTime: old.startTime,
      endTime: old.endTime,
      actualPickupTime: old.actualPickupTime,
      actualReturnTime: DateTime.now(),
      status: BookingStatus.completed,
      pricing: old.pricing,
      depositStatus: SecurityDepositStatus.refundInitiated,
      startingOdometer: old.startingOdometer,
      endingOdometer: endingOdometer,
      createdAt: old.createdAt,
    );

    _bookings[index] = updated;
    return updated;
  }
}
