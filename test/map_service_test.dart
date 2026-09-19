import 'package:flutter_test/flutter_test.dart';
import 'package:rental_subscription_platform/services/maps/map_service.dart';
import 'package:rental_subscription_platform/services/maps/mock_map_service.dart';

void main() {
  group('MockMapService & Distance Calculator Unit Tests', () {
    late MockMapService mapService;

    setUp(() {
      mapService = MockMapService();
    });

    test('getCurrentLocation returns default Hyderabad coordinates', () async {
      final loc = await mapService.getCurrentLocation();
      expect(loc.latitude, closeTo(17.4646, 0.001));
      expect(loc.longitude, closeTo(78.3667, 0.001));
      expect(loc.address, contains('Hyderabad'));
    });

    test('calculateDistanceKm computes accurate Haversine distance between Kondapur and Miyapur', () async {
      const kondapur = GeoLocation(latitude: 17.4646, longitude: 78.3667);
      const miyapur = GeoLocation(latitude: 17.4968, longitude: 78.3582);

      final distance = await mapService.calculateDistanceKm(kondapur, miyapur);
      // Realistic aerial distance ~3.69 km
      expect(distance, greaterThan(3.0));
      expect(distance, lessThan(4.5));
    });

    test('calculateDistanceKm returns 0 for same location', () async {
      const point = GeoLocation(latitude: 17.4646, longitude: 78.3667);
      final distance = await mapService.calculateDistanceKm(point, point);
      expect(distance, equals(0.0));
    });

    test('reverseGeocode identifies Hyderabad hubs', () async {
      final address = await mapService.reverseGeocode(17.4968, 78.3582);
      expect(address, contains('Miyapur'));
    });

    test('searchPlaces finds matching stations', () async {
      final results = await mapService.searchPlaces('Miyapur');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.address, contains('Miyapur'));
    });
  });
}
