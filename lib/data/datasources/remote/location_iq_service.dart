import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/location_suggestion.dart';

class LocationIqService {
  final Dio _dio = Dio();

  static String get _apiKey => dotenv.env['LOCATIONIQ_API_KEY'] ?? '';

  Future<List<LocationSuggestion>> searchAddress(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await _dio.get(
        'https://us1.locationiq.com/v1/autocomplete.php',
        queryParameters: {
          'key': _apiKey,
          'q': query,
          'countrycodes': 'vn', 
          'format': 'json',
          'accept-language': 'vi', 
          'limit': 5, 
        },
      );

      if (response.statusCode == 200) {
        final List data = response.data;
        return data
            .map((json) => LocationSuggestion.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}