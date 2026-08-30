import 'package:flutter/material.dart';
import 'package:flutter_map_app/data/datasources/remote/open_route_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_app/data/models/poi_model.dart';
import '../../../data/models/poi_category.dart';

class PoiSymbolDialog extends StatelessWidget {
  final List<PoiModel> poiList;
  final Set<String> selectedCategoryIds;
  final ValueChanged<String> onCategoryToggled;
  final LatLng currentLocation;
  final ValueChanged<PoiModel>? onPoiSelected;

  const PoiSymbolDialog({
    super.key,
    required this.poiList,
    required this.selectedCategoryIds,
    required this.onCategoryToggled,
    required this.currentLocation,
    this.onPoiSelected,
  });

  static void show({
    required BuildContext context,
    required List<PoiModel> poiList,
    required Set<String> selectedCategoryIds,
    required ValueChanged<String> onCategoryToggled,
    required LatLng currentLocation,
    ValueChanged<PoiModel>? onPoiSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return PoiSymbolDialog(
            poiList: poiList,
            selectedCategoryIds: selectedCategoryIds,
            currentLocation: currentLocation,
            onPoiSelected: onPoiSelected,
            onCategoryToggled: (id) {
              onCategoryToggled(id);
              setModalState(() {});
            },
          );
        },
      ),
    );
  }

  int _countPoisByCategory(PoiCategory category) {
    return poiList.where((poi) {
      final poiCat = PoiCategory.getCategoryById(poi.type);
      return poiCat.id == category.id;
    }).length;
  }

  void _openCategoryPoiList(BuildContext context, PoiCategory category) {
    final categoryPois = poiList.where((poi) {
      final poiCat = PoiCategory.getCategoryById(poi.type);
      return poiCat.id == category.id;
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CategoryPoiListSheet(
        category: category,
        categoryPois: categoryPois,
        currentLocation: currentLocation,
        onPoiSelected: onPoiSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = poiList.length;

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chú thích & Thống kê',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Tổng số tìm thấy: $totalCount địa điểm',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 24),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: PoiCategory.categories.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 56),
              itemBuilder: (context, index) {
                final cat = PoiCategory.categories[index];
                final count = _countPoisByCategory(cat);
                final isSelected = selectedCategoryIds.contains(cat.id);

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openCategoryPoiList(context, cat),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 4.0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: cat.color, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    cat.label,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: count > 0
                                          ? cat.color.withValues(alpha: 0.15)
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: count > 0
                                            ? cat.color
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cat.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                          onPressed: () => _openCategoryPoiList(context, cat),
                        ),
                        Checkbox(
                          value: isSelected,
                          activeColor: cat.color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: (_) => onCategoryToggled(cat.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPoiListSheet extends StatefulWidget {
  final PoiCategory category;
  final List<PoiModel> categoryPois;
  final LatLng currentLocation;
  final ValueChanged<PoiModel>? onPoiSelected;

  const _CategoryPoiListSheet({
    required this.category,
    required this.categoryPois,
    required this.currentLocation,
    this.onPoiSelected,
  });

  @override
  State<_CategoryPoiListSheet> createState() => _CategoryPoiListSheetState();
}

class _CategoryPoiListSheetState extends State<_CategoryPoiListSheet> {
  final OpenRouteService _orsService = OpenRouteService();
  bool _isLoading = true;
  List<PoiModel> _sortedPois = [];

  @override
  void initState() {
    super.initState();
    _fetchAndSortRoadDistances();
  }

  Future<void> _fetchAndSortRoadDistances() async {
    if (widget.categoryPois.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final destinations = widget.categoryPois
        .map((p) => LatLng(p.lat, p.lon))
        .toList();

    final matrixResults = await _orsService.getMatrixDistances(
      origin: widget.currentLocation,
      destinations: destinations,
    );

    if (matrixResults != null && matrixResults.length == widget.categoryPois.length) {
      for (int i = 0; i < widget.categoryPois.length; i++) {
        widget.categoryPois[i].roadDistanceMeters = matrixResults[i]['distance'];
        widget.categoryPois[i].roadDurationSeconds = matrixResults[i]['duration'];
      }

      widget.categoryPois.sort((a, b) =>
          (a.roadDistanceMeters ?? double.infinity)
              .compareTo(b.roadDistanceMeters ?? double.infinity));
    }

    if (mounted) {
      setState(() {
        _sortedPois = widget.categoryPois;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.category.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.category.icon,
                  color: widget.category.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.category.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Sắp xếp theo khoảng cách đường bộ tăng dần',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 20),
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: widget.category.color,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Đang tính toán khoảng cách đường bộ...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _sortedPois.isEmpty
                    ? const Center(
                        child: Text(
                          'Không tìm thấy địa điểm nào thuộc nhóm này',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _sortedPois.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 48),
                        itemBuilder: (context, index) {
                          final poi = _sortedPois[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            onTap: () {
                              Navigator.pop(context); 
                              Navigator.pop(context); 
                              
                              widget.onPoiSelected?.call(poi);
                            },
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  widget.category.color.withValues(alpha: 0.15),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: widget.category.color,
                                ),
                              ),
                            ),
                            title: Text(
                              poi.name.isNotEmpty
                                  ? poi.name
                                  : widget.category.label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${poi.lat.toStringAsFixed(4)}, ${poi.lon.toStringAsFixed(4)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  poi.formattedDistance,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                if (poi.formattedDuration.isNotEmpty)
                                  Text(
                                    poi.formattedDuration,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}