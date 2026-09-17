import '../entities/booking.dart';

abstract class BookingRepository {
  Future<List<Booking>> getUserBookings(String customerId);
  Future<Booking?> getBookingById(String bookingId);
  Future<Booking> createBooking({
    required String customerId,
    required String bikeId,
    required String pickupStationId,
    required String returnStationId,
    required DateTime startTime,
    required DateTime endTime,
    required PricingBreakdown pricing,
  });
  Future<Booking> cancelBooking(String bookingId, String reason);
  Future<Booking> recordPickup(String bookingId, int startingOdometer);
  Future<Booking> recordReturn(String bookingId, int endingOdometer, String returnStationId);
}
