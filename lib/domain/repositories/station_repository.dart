import '../entities/station.dart';

abstract class StationRepository {
  Future<List<Station>> getStations({String? city});
  Future<Station?> getStationById(String id);
}
