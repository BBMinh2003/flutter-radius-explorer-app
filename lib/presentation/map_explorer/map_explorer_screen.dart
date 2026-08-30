import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_app/core/services/location_services.dart';
import 'package:flutter_map_app/data/datasources/remote/location_iq_service.dart';
import 'package:flutter_map_app/data/datasources/remote/open_route_service.dart';
import 'package:flutter_map_app/data/datasources/remote/overpass_service.dart';
import 'package:flutter_map_app/data/models/location_suggestion.dart';
import 'package:flutter_map_app/data/models/poi_category.dart';
import 'package:flutter_map_app/data/models/poi_model.dart';
import 'package:flutter_map_app/presentation/map_explorer/widgets/poi_filter_bar.dart';
import 'package:flutter_map_app/presentation/map_explorer/widgets/poi_symbol_dialog.dart';
import 'package:latlong2/latlong.dart';

import 'widgets/map_search_bar.dart';
import 'widgets/poi_marker_widget.dart';
import 'widgets/radius_control_panel.dart';

class MapExplorerScreen extends StatefulWidget {
  const MapExplorerScreen({super.key});

  @override
  State<MapExplorerScreen> createState() => _MapExplorerScreenState();
}

class _MapExplorerScreenState extends State<MapExplorerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final LocationIqService _locationIqService = LocationIqService();
  final OverpassService _overpassService = OverpassService();

  LatLng _currentLocation = const LatLng(21.02851, 105.8542);
  bool _isLoading = false;
  bool _isScanning = false;
  double _radiusInMeters = 1000.0;

  final Set<String> _selectedCategoryIds = PoiCategory.categories
      .map((c) => c.id)
      .toSet();

  List<LocationSuggestion> _suggestions = [];

  List<PoiModel> _allPoiList = [];

  Timer? _debounceTimer;

  List<PoiModel> get _visiblePoiList {
    if (_selectedCategoryIds.isEmpty) return [];
    return _allPoiList.where((poi) {
      final category = PoiCategory.getCategoryById(poi.type);
      return _selectedCategoryIds.contains(category.id);
    }).toList();
  }

  List<LatLng> _routePoints = [];
  final OpenRouteService _orsService = OpenRouteService();

  @override
  void initState() {
    super.initState();
    _moveToUserLocation();
  }

  Future<void> _moveToUserLocation() async {
    setState(() => _isLoading = true);
    final location = await LocationService.getCurrentLocation();

    if (location != null && mounted) {
      setState(() {
        _currentLocation = location;
        _isLoading = false;
        _allPoiList.clear();
        _routePoints.clear();
      });
      _mapController.move(_currentLocation, 14.5);
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _scanNearbyPois() async {
    setState(() {
      _isScanning = true;
      _routePoints.clear(); 
    });

    final allCategoryIds = PoiCategory.categories.map((c) => c.id).toSet();

    final pois = await _overpassService.fetchNearbyPois(
      center: _currentLocation,
      radiusInMeters: _radiusInMeters,
      selectedCategoryIds: allCategoryIds,
    );

    if (mounted) {
      setState(() {
        _allPoiList = pois;
        _isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tìm thấy ${_allPoiList.length} tiện ích xung quanh (Đang hiển thị ${_visiblePoiList.length})',
          ),
        ),
      );
    }
  }

  Future<void> _drawRouteToPoi(PoiModel poi) async {
    final destination = LatLng(poi.lat, poi.lon);

    final points = await _orsService.getRouteCoordinates(
      start: _currentLocation,
      end: destination,
    );

    if (points != null && points.isNotEmpty) {
      setState(() {
        _routePoints = points;
      });

      _mapController.move(destination, 15.0);
    }
  }

  void _toggleCategory(String catId) {
    setState(() {
      if (_selectedCategoryIds.contains(catId)) {
        _selectedCategoryIds.remove(catId);
      } else {
        _selectedCategoryIds.add(catId);
      }
    });
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().length >= 2) {
        final results = await _locationIqService.searchAddress(query);
        if (mounted) setState(() => _suggestions = results);
      } else if (mounted) {
        setState(() => _suggestions = []);
      }
    });
  }

  void _selectSuggestion(LocationSuggestion suggestion) {
    FocusScope.of(context).unfocus();
    final newLocation = LatLng(suggestion.lat, suggestion.lon);
    setState(() {
      _currentLocation = newLocation;
      _suggestions = [];
      _allPoiList.clear();
      _routePoints.clear();
      _searchController.text = suggestion.displayName;
    });
    _mapController.move(newLocation, 14.5);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 14.5,
              onTap: (_, _) {
                FocusScope.of(context).unfocus();
              },
              onLongPress: (tapPosition, point) {
                setState(() {
                  _currentLocation = point;
                  _allPoiList.clear();
                  _routePoints.clear();
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_map_app',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _currentLocation,
                    radius: _radiusInMeters,
                    useRadiusInMeter: true,
                    color: Colors.blueAccent.withValues(alpha: 0.15),
                    borderColor: Colors.blueAccent,
                    borderStrokeWidth: 2.0,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                  ..._visiblePoiList.map(
                    (poi) => Marker(
                      point: LatLng(poi.lat, poi.lon),
                      width: 32,
                      height: 32,
                      child: PoiMarkerWidget(
                        poi: poi,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${poi.name} (${poi.type})'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.5,
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
            ],
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MapSearchBar(
                controller: _searchController,
                suggestions: _suggestions,
                onChanged: _onSearchChanged,
                onClear: () {
                  _searchController.clear();
                  setState(() => _suggestions = []);
                },
                onSelectSuggestion: _selectSuggestion,
              ),
              PoiFilterBar(
                selectedCategoryIds: _selectedCategoryIds,
                onCategoryToggled: _toggleCategory,
                onOpenSymbol: () {
                  PoiSymbolDialog.show(
                    context: context,
                    poiList: _allPoiList,
                    selectedCategoryIds: _selectedCategoryIds,
                    onCategoryToggled: _toggleCategory,
                    currentLocation: _currentLocation,
                    onPoiSelected: _drawRouteToPoi,
                  );
                },
              ),
            ],
          ),

          Positioned(
            left: 12,
            right: 12,
            bottom: 24,
            child: RadiusControlPanel(
              radiusInMeters: _radiusInMeters,
              isScanning: _isScanning,
              onRadiusChanged: (value) {
                setState(() {
                  _radiusInMeters = value;
                  _allPoiList.clear();
                  _routePoints.clear();
                });
              },
              onScanPressed: _scanNearbyPois,
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 140.0),
        child: FloatingActionButton(
          onPressed: _moveToUserLocation,
          backgroundColor: Colors.blueAccent,
          child: const Icon(Icons.my_location, color: Colors.white),
        ),
      ),
    );
  }
}
