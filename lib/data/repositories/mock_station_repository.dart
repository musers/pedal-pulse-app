import '../../domain/entities/station.dart';
import '../../domain/repositories/station_repository.dart';
import '../datasources/mock_data_source.dart';

class MockStationRepository implements StationRepository {
  @override
  Future<List<Station>> getStations({String? city}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return MockDataSource.stations.where((station) {
      if (city != null && station.city.toLowerCase() != city.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<Station?> getStationById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return MockDataSource.stations.firstWhere((station) => station.id == id);
    } catch (_) {
      return null;
    }
  }
}
