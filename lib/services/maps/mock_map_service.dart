import 'dart:math';
import 'map_service.dart';

class MockMapService implements MapService {
  // Default user location: Koramangala, Bengaluru
  static const GeoLocation defaultBengaluruUserLocation = GeoLocation(
    latitude: 12.9345,
    longitude: 77.6101,
    address: 'Koramangala 4th Block, Bengaluru, Karnataka 560034',
  );

  final GeoLocation _currentLocation;

  MockMapService({GeoLocation? initialLocation})
      : _currentLocation = initialLocation ?? defaultBengaluruUserLocation;

  @override
  Future<GeoLocation> getCurrentLocation() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _currentLocation;
  }

  @override
  Future<double> calculateDistanceKm(GeoLocation from, GeoLocation to) async {
    // Haversine formula
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(to.latitude - from.latitude);
    final dLon = _toRadians(to.longitude - from.longitude);

    final lat1 = _toRadians(from.latitude);
    final lat2 = _toRadians(to.latitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final distance = earthRadiusKm * c;
    return double.parse(distance.toStringAsFixed(2));
  }

  @override
  Future<String> reverseGeocode(double latitude, double longitude) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if ((latitude - 12.9352).abs() < 0.01) {
      return 'Koramangala 5th Block, Bengaluru';
    } else if ((latitude - 12.9784).abs() < 0.01) {
      return 'Indiranagar 100ft Road, Bengaluru';
    } else if ((latitude - 12.9116).abs() < 0.01) {
      return 'HSR Layout Sector 1, Bengaluru';
    } else if ((latitude - 12.9863).abs() < 0.01) {
      return 'Whitefield ITPL Main Rd, Bengaluru';
    }
    return 'Bengaluru Urban, Karnataka, India';
  }

  @override
  Future<List<GeoLocation>> searchPlaces(String query) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final q = query.toLowerCase();
    final allKnown = [
      const GeoLocation(latitude: 12.9352, longitude: 77.6245, address: 'Koramangala 5th Block Hub'),
      const GeoLocation(latitude: 12.9784, longitude: 77.6408, address: 'Indiranagar 100ft Road Hub'),
      const GeoLocation(latitude: 12.9116, longitude: 77.6389, address: 'HSR Layout Sector 1 Hub'),
      const GeoLocation(latitude: 12.9863, longitude: 77.7314, address: 'Whitefield ITPL Hub'),
      const GeoLocation(latitude: 12.9716, longitude: 77.5946, address: 'MG Road Metro Station'),
    ];

    return allKnown
        .where((loc) => (loc.address ?? '').toLowerCase().contains(q))
        .toList();
  }

  double _toRadians(double degree) => degree * (pi / 180.0);
}
