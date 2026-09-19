import 'dart:math';
import 'map_service.dart';

class MockMapService implements MapService {
  // Default user location: Kondapur / HITEC City, Hyderabad
  static const GeoLocation defaultHyderabadUserLocation = GeoLocation(
    latitude: 17.4646,
    longitude: 78.3667,
    address: 'Botanical Garden Rd, Kondapur, Hyderabad, Telangana 500084',
  );

  final GeoLocation _currentLocation;

  MockMapService({GeoLocation? initialLocation})
      : _currentLocation = initialLocation ?? defaultHyderabadUserLocation;

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
    if ((latitude - 17.4968).abs() < 0.01) {
      return 'Miyapur Metro Station Hub, Hyderabad';
    } else if ((latitude - 17.4646).abs() < 0.01) {
      return 'Kondapur HITEC City Hub, Hyderabad';
    }
    return 'Hyderabad Urban, Telangana, India';
  }

  @override
  Future<List<GeoLocation>> searchPlaces(String query) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final q = query.toLowerCase();
    final allKnown = [
      const GeoLocation(latitude: 17.4968, longitude: 78.3582, address: 'Miyapur Metro Station Hub, Hyderabad'),
      const GeoLocation(latitude: 17.4646, longitude: 78.3667, address: 'Kondapur HITEC City Hub, Hyderabad'),
      const GeoLocation(latitude: 17.4483, longitude: 78.3915, address: 'Cyber Towers, HITEC City, Hyderabad'),
      const GeoLocation(latitude: 17.4401, longitude: 78.3489, address: 'Gachibowli Financial District, Hyderabad'),
      const GeoLocation(latitude: 17.4933, longitude: 78.3914, address: 'KPHB Colony Metro Station, Hyderabad'),
    ];

    return allKnown
        .where((loc) => (loc.address ?? '').toLowerCase().contains(q))
        .toList();
  }

  double _toRadians(double degree) => degree * (pi / 180.0);
}
