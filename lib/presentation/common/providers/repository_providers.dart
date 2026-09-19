import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../data/datasources/supabase_data_source.dart';
import '../../../data/repositories/mock_bike_repository.dart';
import '../../../data/repositories/mock_booking_repository.dart';
import '../../../data/repositories/mock_promo_repository.dart';
import '../../../data/repositories/mock_station_repository.dart';
import '../../../data/repositories/mock_subscription_repository.dart';
import '../../../data/repositories/supabase_bike_repository.dart';
import '../../../data/repositories/supabase_booking_repository.dart';
import '../../../data/repositories/supabase_promo_repository.dart';
import '../../../data/repositories/supabase_station_repository.dart';
import '../../../data/repositories/supabase_subscription_repository.dart';
import '../../../domain/repositories/bike_repository.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../../domain/repositories/promo_repository.dart';
import '../../../domain/repositories/station_repository.dart';
import '../../../domain/repositories/subscription_repository.dart';
import '../../../services/maps/map_service.dart';
import '../../../services/maps/mock_map_service.dart';

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

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final client = SupabaseConfig.client;
  if (client != null) {
    return SupabaseSubscriptionRepository(client);
  }
  return MockSubscriptionRepository();
});

final promoRepositoryProvider = Provider<PromoRepository>((ref) {
  final client = SupabaseConfig.client;
  if (client != null) {
    return SupabasePromoRepository(client);
  }
  return MockPromoRepository();
});

final mapServiceProvider = Provider<MapService>((ref) {
  return MockMapService();
});
