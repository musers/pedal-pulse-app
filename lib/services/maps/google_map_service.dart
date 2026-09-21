import 'dart:math';
import 'package:dio/dio.dart';
import 'map_service.dart';

class GoogleMapService implements MapService {
  final String? apiKey;
  final Dio _dio;

  GoogleMapService({
    this.apiKey,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  @override
  Future<GeoLocation> getCurrentLocation() async {
    // Default center for Hyderabad IT corridor / Kondapur
    return const GeoLocation(
      latitude: 17.4646,
      longitude: 78.3667,
      address: 'Kondapur, Hyderabad, Telangana',
    );
  }

  @override
  Future<double> calculateDistanceKm(GeoLocation from, GeoLocation to) async {
    if (isConfigured) {
      try {
        final origins = '${from.latitude},${from.longitude}';
        final destinations = '${to.latitude},${to.longitude}';
        
        final response = await _dio.get(
          'https://maps.googleapis.com/maps/api/distancematrix/json',
          queryParameters: {
            'origins': origins,
            'destinations': destinations,
            'mode': 'driving',
            'key': apiKey,
          },
        );

        if (response.statusCode == 200 && response.data['status'] == 'OK') {
          final rows = response.data['rows'] as List;
          if (rows.isNotEmpty) {
            final elements = rows[0]['elements'] as List;
            if (elements.isNotEmpty && elements[0]['status'] == 'OK') {
              final distanceMeters = elements[0]['distance']['value'] as int;
              return double.parse((distanceMeters / 1000.0).toStringAsFixed(2));
            }
          }
        }
      } catch (_) {
        // Fallback to high-precision Haversine on network error
      }
    }

    // High precision Haversine formula calculation
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
    if (isConfigured) {
      try {
        final response = await _dio.get(
          'https://maps.googleapis.com/maps/api/geocode/json',
          queryParameters: {
            'latlng': '$latitude,$longitude',
            'key': apiKey,
          },
        );

        if (response.statusCode == 200 && response.data['status'] == 'OK') {
          final results = response.data['results'] as List;
          if (results.isNotEmpty) {
            return results[0]['formatted_address'] as String;
          }
        }
      } catch (_) {}
    }

    return 'Hyderabad, Telangana, India';
  }

  @override
  Future<List<GeoLocation>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    if (isConfigured) {
      try {
        // 1. Query Google Places Autocomplete API with Hyderabad location bias
        final response = await _dio.get(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json',
          queryParameters: {
            'input': query,
            'location': '17.4646,78.3667', // Hyderabad center
            'radius': '35000', // 35 km radius
            'components': 'country:in',
            'key': apiKey,
          },
        );

        if (response.statusCode == 200 && response.data['status'] == 'OK') {
          final predictions = response.data['predictions'] as List;
          final results = <GeoLocation>[];

          for (final p in predictions.take(5)) {
            final description = p['description'] as String;
            final placeId = p['place_id'] as String;

            // Fetch lat/lng details
            final detailResponse = await _dio.get(
              'https://maps.googleapis.com/maps/api/place/details/json',
              queryParameters: {
                'place_id': placeId,
                'fields': 'geometry,formatted_address',
                'key': apiKey,
              },
            );

            if (detailResponse.statusCode == 200 && detailResponse.data['status'] == 'OK') {
              final loc = detailResponse.data['result']['geometry']['location'];
              results.add(GeoLocation(
                latitude: (loc['lat'] as num).toDouble(),
                longitude: (loc['lng'] as num).toDouble(),
                address: description,
              ));
            }
          }

          if (results.isNotEmpty) return results;
        }
      } catch (_) {
        // Fallback to localized search
      }
    }

    // Localized Hyderabad smart search fallback
    final hyderabadLocations = [
      const GeoLocation(latitude: 17.4968, longitude: 78.3582, address: 'Miyapur Metro Station, Hyderabad'),
      const GeoLocation(latitude: 17.4646, longitude: 78.3667, address: 'Botanical Garden, Kondapur, Hyderabad'),
      const GeoLocation(latitude: 17.4435, longitude: 78.3772, address: 'Cyber Towers, HITEC City, Hyderabad'),
      const GeoLocation(latitude: 17.4399, longitude: 78.3489, address: 'Gachibowli Stadium, Hyderabad'),
      const GeoLocation(latitude: 17.4483, longitude: 78.3915, address: 'Madhapur Metro Station, Hyderabad'),
      const GeoLocation(latitude: 17.4156, longitude: 78.3427, address: 'Financial District, Nanakramguda, Hyderabad'),
      const GeoLocation(latitude: 17.4947, longitude: 78.3996, address: 'Kukatpally Housing Board (KPHB), Hyderabad'),
      const GeoLocation(latitude: 17.4319, longitude: 78.4073, address: 'Jubilee Hills Check Post, Hyderabad'),
    ];

    final q = query.toLowerCase();
    return hyderabadLocations.where((loc) => loc.address?.toLowerCase().contains(q) ?? false).toList();
  }
}
