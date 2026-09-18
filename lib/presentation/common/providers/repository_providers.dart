import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../data/datasources/supabase_data_source.dart';
import '../../../data/repositories/mock_bike_repository.dart';
import '../../../data/repositories/mock_booking_repository.dart';
import '../../../data/repositories/mock_station_repository.dart';
import '../../../data/repositories/supabase_bike_repository.dart';
import '../../../data/repositories/supabase_booking_repository.dart';
import '../../../data/repositories/supabase_station_repository.dart';
import '../../../domain/repositories/bike_repository.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../../domain/repositories/station_repository.dart';

final supabaseDataSourceProvider = Provider<SupabaseDataSource?>((ref) {
  final client = SupabaseConfig.client;
  if (client == null) return null;
  return SupabaseDataSource(client);
});

final bikeRepositoryProvider = Provider<BikeRepository>((ref) {
  final supabaseDs = ref.watch(supabaseDataSourceProvider);
  if (supabaseDs != null) {
    return SupabaseBikeRepository(supabaseDs);
  }
  return MockBikeRepository();
});

final stationRepositoryProvider = Provider<StationRepository>((ref) {
  final supabaseDs = ref.watch(supabaseDataSourceProvider);
  if (supabaseDs != null) {
    return SupabaseStationRepository(supabaseDs);
  }
  return MockStationRepository();
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final supabaseDs = ref.watch(supabaseDataSourceProvider);
  if (supabaseDs != null) {
    return SupabaseBookingRepository(supabaseDs);
  }
  return MockBookingRepository();
});
