import '../../domain/entities/station.dart';
import '../../domain/repositories/station_repository.dart';
import '../datasources/supabase_data_source.dart';

class SupabaseStationRepository implements StationRepository {
  final SupabaseDataSource dataSource;

  SupabaseStationRepository(this.dataSource);

  @override
  Future<List<Station>> getStations({String? city}) =>
      dataSource.getStations(city: city);

  @override
  Future<Station?> getStationById(String id) async {
    final list = await dataSource.getStations();
    try {
      return list.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
