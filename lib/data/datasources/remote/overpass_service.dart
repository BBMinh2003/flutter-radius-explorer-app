import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_app/data/models/poi_model.dart';
import '../../../data/models/poi_category.dart';

class OverpassService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 25), // Tăng timeout đồng bộ
      headers: {
        'User-Agent': 'FlutterMapApp/1.0 (com.example.flutter_map_app)',
      },
    ),
  );

  final List<String> _endpoints = [
    'https://overpass.nchc.org.tw/api/interpreter', 
    'https://overpass-api.de/api/interpreter',     
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];

  Future<List<PoiModel>> fetchNearbyPois({
    required LatLng center,
    required double radiusInMeters,
    required Set<String> selectedCategoryIds,
    CancelToken? cancelToken,
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

    final query = '[out:json][timeout:25];(${queryParts.join()});out center qt;';

    for (final endpoint in _endpoints) {
      if (cancelToken?.isCancelled ?? false) break; 

      try {
        final response = await _dio.post(
          endpoint,
          data: 'data=${Uri.encodeComponent(query)}',
          cancelToken: cancelToken, 
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            responseType: ResponseType.json,
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          final List elements = response.data['elements'] ?? [];
          return elements.map((e) => PoiModel.fromJson(e)).toList();
        }
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) {
          rethrow; 
        }
        await Future.delayed(const Duration(milliseconds: 300));
        continue;
      } catch (e) {
        await Future.delayed(const Duration(milliseconds: 300));
        continue;
      }
    }
    return [];
  }
}