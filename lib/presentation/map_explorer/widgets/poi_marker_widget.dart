import 'package:flutter/material.dart';
import 'package:flutter_map_app/data/models/poi_category.dart';
import '../../../data/models/poi_model.dart';

class PoiMarkerWidget extends StatelessWidget {
  final PoiModel poi;
  final VoidCallback? onTap;

  const PoiMarkerWidget({
    super.key,
    required this.poi,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = PoiCategory.getCategoryById(poi.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: category.color, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 3),
          ],
        ),
        child: Icon(
          category.icon,
          color: category.color,
          size: 18,
        ),
      ),
    );
  }
}