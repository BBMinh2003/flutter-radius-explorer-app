class PoiModel {
  final String id;
  final String name;
  final String type;
  final double lat;
  final double lon;

  double? roadDistanceMeters;
  double? roadDurationSeconds;

  PoiModel({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lon,
    this.roadDistanceMeters,
    this.roadDurationSeconds,
  });

  String get formattedDistance {
    if (roadDistanceMeters == null) return 'N/A';
    if (roadDistanceMeters! >= 1000) {
      return '${(roadDistanceMeters! / 1000).toStringAsFixed(1)} km';
    }
    return '${roadDistanceMeters!.round()} m';
  }

  String get formattedDuration {
    if (roadDurationSeconds == null) return '';
    final mins = (roadDurationSeconds! / 60).round();
    if (mins < 1) return '< 1 phút';
    if (mins >= 60) {
      final hours = mins ~/ 60;
      final remainingMins = mins % 60;
      return '$hours giờ $remainingMins phút';
    }
    return '$mins phút';
  }

  factory PoiModel.fromJson(Map<String, dynamic> json) {
    final tags = json['tags'] as Map<String, dynamic>? ?? {};

    double lat = 0.0;
    double lon = 0.0;

    if (json.containsKey('lat') && json.containsKey('lon')) {
      lat = (json['lat'] as num).toDouble();
      lon = (json['lon'] as num).toDouble();
    } else if (json.containsKey('center')) {
      lat = (json['center']['lat'] as num).toDouble();
      lon = (json['center']['lon'] as num).toDouble();
    }

    String detectedType = tags['amenity'] ??
        tags['healthcare'] ??
        tags['shop'] ??
        'other';

    if (detectedType == 'clinic' || detectedType == 'doctor') {
      detectedType = 'hospital';
    }

    return PoiModel(
      id: json['id'].toString(),
      name: tags['name'] ?? tags['brand'] ?? 'Địa điểm không tên',
      type: detectedType,
      lat: lat,
      lon: lon,
    );
  }
}