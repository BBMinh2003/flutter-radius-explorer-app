import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../../models/poi_category.dart';
import '../../models/poi_model.dart';

class OverpassService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': 'FlutterMapApp/1.0 (com.example.flutter_map_app)',
      },
    ),
  );

  final List<String> _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];

  Future<List<PoiModel>> fetchNearbyPois({
    required LatLng center,
    required double radiusInMeters,
    required Set<String> selectedCategoryIds,
  }) async {
    if (selectedCategoryIds.isEmpty) return [];

    final radiusInt = radiusInMeters.toInt();
    final lat = center.latitude;
    final lon = center.longitude;

    final List<String> queryParts = [];
    for (final catId in selectedCategoryIds) {
      final cat = PoiCategory.categories.firstWhere(
        (c) => c.id == catId,
        orElse: () => PoiCategory.categories.first,
      );
      queryParts.add(
        cat.queryFilter
            .replaceAll('{radius}', '$radiusInt')
            .replaceAll('{lat}', '$lat')
            .replaceAll('{lon}', '$lon'),
      );
    }

    final query = '[out:json][timeout:15];(${queryParts.join()});out center;';

    for (final endpoint in _endpoints) {
      try {
        final response = await _dio.post(
          endpoint,
          data: 'data=${Uri.encodeQueryComponent(query)}',
          options: Options(contentType: Headers.formUrlEncodedContentType),
        );

        if (response.statusCode == 200) {
          final List elements = response.data['elements'] ?? [];
          return elements.map((e) => PoiModel.fromJson(e)).toList();
        }
      } catch (e) {
        continue;
      }
    }
    return [];
  }
}