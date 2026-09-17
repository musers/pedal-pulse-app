import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';

class MockBookingRepository implements BookingRepository {
  final List<Booking> _bookings = [];

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
