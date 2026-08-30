import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_app/core/services/location_services.dart';
import 'package:flutter_map_app/data/datasources/remote/location_iq_service.dart';
import 'package:flutter_map_app/data/datasources/remote/open_route_service.dart';
import 'package:flutter_map_app/data/datasources/remote/overpass_service.dart';
import 'package:flutter_map_app/data/models/location_suggestion.dart';
import 'package:flutter_map_app/data/models/poi_category.dart';
import 'package:flutter_map_app/data/models/poi_model.dart';
import 'package:latlong2/latlong.dart';

class MapExplorerViewModel extends ChangeNotifier {
  final LocationIqService _locationIqService;
  final OverpassService _overpassService;
  final OpenRouteService _orsService;

  MapExplorerViewModel({
    LocationIqService? locationIqService,
    OverpassService? overpassService,
    OpenRouteService? orsService,
  }) : _locationIqService = locationIqService ?? LocationIqService(),
       _overpassService = overpassService ?? OverpassService(),
       _orsService = orsService ?? OpenRouteService() {
    _selectedCategoryIds = PoiCategory.categories.map((c) => c.id).toSet();
  }

  LatLng _currentLocation = const LatLng(21.02851, 105.8542);
  LatLng get currentLocation => _currentLocation;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  double _radiusInMeters = 1000.0;
  double get radiusInMeters => _radiusInMeters;

  Set<String> _selectedCategoryIds = {};
  Set<String> get selectedCategoryIds => _selectedCategoryIds;

  List<LocationSuggestion> _suggestions = [];
  List<LocationSuggestion> get suggestions => _suggestions;

  List<PoiModel> _allPoiList = [];
  List<PoiModel> get allPoiList => _allPoiList;

  List<LatLng> _routePoints = [];
  List<LatLng> get routePoints => _routePoints;

  CancelToken? _scanCancelToken;
  Timer? _debounceTimer;

  List<PoiModel> get visiblePoiList {
    if (_selectedCategoryIds.isEmpty) return [];
    return _allPoiList.where((poi) {
      final category = PoiCategory.getCategoryById(poi.type);
      return _selectedCategoryIds.contains(category.id);
    }).toList();
  }

  Function(String message, bool isError)? onShowSnackBar;
  Function(LatLng location, double zoom)? onMoveMapCamera;

  Future<void> moveToUserLocation() async {
    if (_isScanning) return;

    _isLoading = true;
    _suggestions = [];
    notifyListeners();

    final location = await LocationService.getCurrentLocation();

    if (location != null) {
      _currentLocation = location;
      _allPoiList.clear();
      _routePoints.clear();
      onMoveMapCamera?.call(_currentLocation, 14.5);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> scanNearbyPois() async {
    if (_isScanning) {
      cancelScan();
      return;
    }

    _scanCancelToken = CancelToken();
    _isScanning = true;
    _routePoints.clear();
    notifyListeners();

    final allCategoryIds = PoiCategory.categories.map((c) => c.id).toSet();

    try {
      final pois = await _overpassService.fetchNearbyPois(
        center: _currentLocation,
        radiusInMeters: _radiusInMeters,
        selectedCategoryIds: allCategoryIds,
        cancelToken: _scanCancelToken,
      );

      _allPoiList = pois;
      _isScanning = false;
      notifyListeners();

      final message = pois.isNotEmpty
          ? 'Tìm thấy ${_allPoiList.length} tiện ích xung quanh (Đang hiển thị ${visiblePoiList.length})'
          : 'Không thể tải dữ liệu hoặc máy chủ quá tải. Vui lòng thử lại!';

      onShowSnackBar?.call(message, pois.isEmpty);
    } on DioException catch (e) {
      _isScanning = false;
      notifyListeners();

      if (CancelToken.isCancel(e)) {
        onShowSnackBar?.call('Đã dừng quét tiện ích.', false);
      }
    } catch (_) {
      _isScanning = false;
      notifyListeners();
    }
  }

  void cancelScan() {
    _scanCancelToken?.cancel('User cancelled');
  }

  Future<void> drawRouteToPoi(PoiModel poi) async {
    final destination = LatLng(poi.lat, poi.lon);

    final points = await _orsService.getRouteCoordinates(
      start: _currentLocation,
      end: destination,
    );

    if (points != null && points.isNotEmpty) {
      _routePoints = points;
      notifyListeners();
      onMoveMapCamera?.call(destination, 15.0);
    }
  }

  void toggleCategory(String catId) {
    if (_selectedCategoryIds.contains(catId)) {
      _selectedCategoryIds.remove(catId);
    } else {
      _selectedCategoryIds.add(catId);
    }
    notifyListeners();
  }

  void onSearchChanged(String query) {
    if (_isScanning) return;

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().length >= 2) {
        _suggestions = await _locationIqService.searchAddress(query);
      } else {
        _suggestions = [];
      }
      notifyListeners();
    });
  }

  void selectSuggestion(LocationSuggestion suggestion) {
    if (_isScanning) return;

    _currentLocation = LatLng(suggestion.lat, suggestion.lon);
    _suggestions = [];
    _allPoiList.clear();
    _routePoints.clear();
    notifyListeners();

    onMoveMapCamera?.call(_currentLocation, 14.5);
  }

  void updateLocationOnLongPress(LatLng point) {
    if (_isScanning) return;

    _currentLocation = point;
    _allPoiList.clear();
    _routePoints.clear();
    notifyListeners();
  }

  void updateRadius(double value) {
    if (_isScanning) return;

    _radiusInMeters = value;
    _allPoiList.clear();
    _routePoints.clear();
    notifyListeners();
  }

  void clearSuggestions() {
    _suggestions = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _scanCancelToken?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
