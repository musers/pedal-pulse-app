import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/mock_bike_repository.dart';
import '../../../data/repositories/mock_booking_repository.dart';
import '../../../data/repositories/mock_station_repository.dart';
import '../../../domain/repositories/bike_repository.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../../domain/repositories/station_repository.dart';

final bikeRepositoryProvider = Provider<BikeRepository>((ref) {
  return MockBikeRepository();
});

final stationRepositoryProvider = Provider<StationRepository>((ref) {
  return MockStationRepository();
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return MockBookingRepository();
});
