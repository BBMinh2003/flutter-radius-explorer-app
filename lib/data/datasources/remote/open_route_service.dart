import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';

class OpenRouteService {
  final Dio _dio = Dio();

  static String get _apiKey => dotenv.env['OPENROUTESERVICE_API_KEY'] ?? '';

  Future<List<Map<String, double>>?> getMatrixDistances({
    required LatLng origin,
    required List<LatLng> destinations,
    String profile = 'driving-car',
  }) async {
    if (destinations.isEmpty) return [];

    final limitedDestinations = destinations.take(100).toList();
    final url = 'https://api.openrouteservice.org/v2/matrix/$profile';

    final List<List<double>> locations = [
      [origin.longitude, origin.latitude],
      ...limitedDestinations.map((d) => [d.longitude, d.latitude]),
    ];

    final List<int> destinationIndices = List.generate(
      limitedDestinations.length,
      (index) => index + 1,
    );

     try {
      final response = await _dio.post(
        url,
        options: Options(
          headers: {
            'Authorization': _apiKey,
            'Content-Type': 'application/json; charset=utf-8',
          },
        ),
        data: {
          'locations': locations,
          'sources': [0],
          'destinations': destinationIndices,
          'metrics': ['distance', 'duration'],
          'units': 'm',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final distances = List<num>.from(data['distances'][0]);
        final durations = List<num>.from(data['durations'][0]);

        List<Map<String, double>> results = [];
        for (int i = 0; i < distances.length; i++) {
          results.add({
            'distance': distances[i].toDouble(),
            'duration': durations[i].toDouble(),
          });
        }
        return results;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  Future<List<LatLng>?> getRouteCoordinates({
      required LatLng start,
      required LatLng end,
      String profile = 'driving-car',
    }) async {
      final url =
          'https://api.openrouteservice.org/v2/directions/$profile/geojson';

      try {
        final response = await _dio.post(
          url,
          options: Options(
            headers: {
              'Authorization': _apiKey,
              'Content-Type': 'application/json; charset=utf-8',
            },
          ),
          data: {
            'coordinates': [
              [start.longitude, start.latitude],
              [end.longitude, end.latitude],
            ],
          },
        );

        if (response.statusCode == 200) {
          final List coordinates =
              response.data['features'][0]['geometry']['coordinates'];

          return coordinates
              .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
              .toList();
        }
        return null;
      } catch (e) {
        return null;
      }
    }

   
}
