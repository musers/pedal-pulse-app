import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/supabase_data_source.dart';

class SupabaseBookingRepository implements BookingRepository {
  final SupabaseDataSource dataSource;

  SupabaseBookingRepository(this.dataSource);

  @override
  Future<List<Booking>> getUserBookings(String customerId) =>
      dataSource.getUserBookings(customerId);

  @override
  Future<Booking?> getBookingById(String bookingId) async {
    // Queries can be filtered by ID if needed, or by customer
    throw UnimplementedError('Direct single booking lookup via ID');
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
  }) =>
      dataSource.createBooking(
        customerId: customerId,
        bikeId: bikeId,
        pickupStationId: pickupStationId,
        returnStationId: returnStationId,
        startTime: startTime,
        endTime: endTime,
        pricing: pricing,
      );

  @override
  Future<Booking> cancelBooking(String bookingId, String reason) =>
      dataSource.cancelBooking(bookingId, reason);

  @override
  Future<Booking> recordPickup(String bookingId, int startingOdometer) =>
      dataSource.recordPickup(bookingId, startingOdometer);

  @override
  Future<Booking> recordReturn(
    String bookingId,
    int endingOdometer,
    String returnStationId,
  ) =>
      dataSource.recordReturn(bookingId, endingOdometer, returnStationId);
}
