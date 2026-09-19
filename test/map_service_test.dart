import 'package:flutter_test/flutter_test.dart';
import 'package:rental_subscription_platform/services/maps/map_service.dart';
import 'package:rental_subscription_platform/services/maps/mock_map_service.dart';

void main() {
  group('MockMapService & Distance Calculator Unit Tests', () {
    late MockMapService mapService;

    setUp(() {
      mapService = MockMapService();
    });

    test('getCurrentLocation returns default Bengaluru coordinates', () async {
      final loc = await mapService.getCurrentLocation();
      expect(loc.latitude, closeTo(12.9345, 0.001));
      expect(loc.longitude, closeTo(77.6101, 0.001));
      expect(loc.address, contains('Bengaluru'));
    });

    test('calculateDistanceKm computes accurate Haversine distance between Koramangala and Indiranagar', () async {
      const koramangala = GeoLocation(latitude: 12.9352, longitude: 77.6245);
      const indiranagar = GeoLocation(latitude: 12.9784, longitude: 77.6408);

      final distance = await mapService.calculateDistanceKm(koramangala, indiranagar);
      // Realistic road/aerial distance ~5.08 km
      expect(distance, greaterThan(4.5));
      expect(distance, lessThan(6.0));
    });

    test('calculateDistanceKm returns 0 for same location', () async {
      const point = GeoLocation(latitude: 12.9352, longitude: 77.6245);
      final distance = await mapService.calculateDistanceKm(point, point);
      expect(distance, equals(0.0));
    });

    test('reverseGeocode identifies Bengaluru hubs', () async {
      final address = await mapService.reverseGeocode(12.9352, 77.6245);
      expect(address, contains('Koramangala'));
    });

    test('searchPlaces finds matching stations', () async {
      final results = await mapService.searchPlaces('Indiranagar');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.address, contains('Indiranagar'));
    });
  });
}
