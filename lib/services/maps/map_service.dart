class GeoLocation {
  final double latitude;
  final double longitude;
  final String? address;

  const GeoLocation({
    required this.latitude,
    required this.longitude,
    this.address,
  });
}

abstract class MapService {
  Future<GeoLocation> getCurrentLocation();
  Future<double> calculateDistanceKm(GeoLocation from, GeoLocation to);
  Future<String> reverseGeocode(double latitude, double longitude);
  Future<List<GeoLocation>> searchPlaces(String query);
}
