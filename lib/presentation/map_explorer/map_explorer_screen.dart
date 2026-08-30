import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_app/presentation/map_explorer/widgets/poi_filter_bar.dart';
import 'package:flutter_map_app/presentation/map_explorer/widgets/poi_symbol_dialog.dart';
import 'package:flutter_map_app/viewmodels/map_explorer_viewmodel.dart';
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
  late final MapExplorerViewModel _viewModel;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = MapExplorerViewModel();

    _viewModel.onShowSnackBar = (message, isError) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.orange[800] : null,
          duration: const Duration(seconds: 3),
        ),
      );
    };

    _viewModel.onMoveMapCamera = (location, zoom) {
      _mapController.move(location, zoom);
    };

    _viewModel.moveToUserLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;

    final horizontalMargin = screenWidth * 0.035;
    final bottomPanelOffset = screenHeight * 0.025;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _viewModel.currentLocation,
                  initialZoom: 14.5,
                  onTap: (_, _) => FocusScope.of(context).unfocus(),
                  onLongPress: (_, point) {
                    _viewModel.updateLocationOnLongPress(point);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.flutter_map_app',
                  ),
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _viewModel.currentLocation,
                        radius: _viewModel.radiusInMeters,
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
                        point: _viewModel.currentLocation,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                      ..._viewModel.visiblePoiList.map(
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
                  if (_viewModel.routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _viewModel.routePoints,
                          strokeWidth: 4.5,
                          color: Colors.blueAccent,
                        ),
                      ],
                    ),
                ],
              ),

              Positioned(
                top: topPadding + 8,
                left: horizontalMargin,
                right: horizontalMargin,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MapSearchBar(
                      controller: _searchController,
                      suggestions: _viewModel.isScanning
                          ? []
                          : _viewModel.suggestions,
                      onChanged: _viewModel.isScanning
                          ? (_) {}
                          : _viewModel.onSearchChanged,
                      onClear: _viewModel.isScanning
                          ? () {}
                          : () {
                              _searchController.clear();
                              _viewModel.clearSuggestions();
                            },
                      onSelectSuggestion: _viewModel.isScanning
                          ? (_) {}
                          : (suggestion) {
                              FocusScope.of(context).unfocus();
                              _searchController.text = suggestion.displayName;
                              _viewModel.selectSuggestion(suggestion);
                            },
                    ),
                    PoiFilterBar(
                      selectedCategoryIds: _viewModel.selectedCategoryIds,
                      onCategoryToggled: _viewModel.toggleCategory,
                      onOpenSymbol: () {
                        PoiSymbolDialog.show(
                          context: context,
                          poiList: _viewModel.allPoiList,
                          selectedCategoryIds: _viewModel.selectedCategoryIds,
                          onCategoryToggled: _viewModel.toggleCategory,
                          currentLocation: _viewModel.currentLocation,
                          onPoiSelected: _viewModel.drawRouteToPoi,
                        );
                      },
                    ),
                  ],
                ),
              ),

              Positioned(
                left: horizontalMargin,
                right: horizontalMargin,
                bottom: bottomPanelOffset,
                child: RadiusControlPanel(
                  radiusInMeters: _viewModel.radiusInMeters,
                  isScanning: _viewModel.isScanning,
                  onRadiusChanged: _viewModel.updateRadius,
                  onScanPressed: _viewModel.scanNearbyPois,
                ),
              ),

              Positioned(
                right: horizontalMargin + 4,
                bottom: bottomPanelOffset + (screenHeight * 0.165),
                child: FloatingActionButton.small(
                  heroTag: 'btnMyLocation',
                  onPressed: _viewModel.isScanning
                      ? null
                      : () {
                          _searchController.clear();
                          _viewModel.moveToUserLocation();
                        },
                  backgroundColor: _viewModel.isScanning
                      ? Colors.grey
                      : Colors.blueAccent,
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              ),

              if (_viewModel.isLoading)
                Container(
                  color: Colors.black12,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}
