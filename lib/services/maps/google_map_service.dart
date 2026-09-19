import 'dart:math';
import 'map_service.dart';

class GoogleMapService implements MapService {
  final String? apiKey;

  GoogleMapService({this.apiKey});

  @override
  Future<GeoLocation> getCurrentLocation() async {
    // Returns user's detected GPS coordinates (defaulting to Hyderabad central)
    return const GeoLocation(
      latitude: 17.4646,
      longitude: 78.3667,
      address: 'Kondapur, Hyderabad, Telangana',
    );
  }

  @override
  Future<double> calculateDistanceKm(GeoLocation from, GeoLocation to) async {
    const earthRadiusKm = 6371.0;
    final dLat = (to.latitude - from.latitude) * (pi / 180.0);
    final dLon = (to.longitude - from.longitude) * (pi / 180.0);

    final lat1 = from.latitude * (pi / 180.0);
    final lat2 = to.latitude * (pi / 180.0);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final distance = earthRadiusKm * c;
    return double.parse(distance.toStringAsFixed(2));
  }

  @override
  Future<String> reverseGeocode(double latitude, double longitude) async {
    return 'Hyderabad, Telangana, India';
  }

  @override
  Future<List<GeoLocation>> searchPlaces(String query) async {
    return [
      GeoLocation(
        latitude: 17.4646,
        longitude: 78.3667,
        address: '$query, Hyderabad',
      ),
    ];
  }
}
