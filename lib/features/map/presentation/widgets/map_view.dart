import 'dart:math' show Point;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../../../core/constants/map_constants.dart';
import '../providers/map_controller_provider.dart';
import '../providers/map_tool_provider.dart';
import '../providers/ruler_provider.dart';
import '../providers/polygon_provider.dart';
import '../providers/direction_provider.dart';
import '../providers/province_provider.dart';

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  MapLibreMapController? _controller;
  bool _mapReady = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(rulerProvider, (prev, next) {
      if (_mapReady) _updateRulerLayer(next);
    });
    ref.listen(polygonProvider, (prev, next) {
      if (_mapReady) _updatePolygonLayer(next);
    });
    ref.listen(directionProvider, (prev, next) {
      if (_mapReady) _updateDirectionLayer(next);
    });

    return MapLibreMap(
      styleString: MapConstants.tileStyleUrl,
      initialCameraPosition: const CameraPosition(
        target: LatLng(MapConstants.defaultLat, MapConstants.defaultLng), // maplibre LatLng
        zoom: MapConstants.defaultZoom,
      ),
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: _onStyleLoaded,
      onMapClick: _onMapTap,
      myLocationEnabled: false,
      compassEnabled: true,
      rotateGesturesEnabled: true,
    );
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    // Expose controller so external widgets (zoom buttons) can use it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(mapControllerProvider.notifier).state = controller;
      }
    });
  }

  Future<void> _onStyleLoaded() async {
    if (_controller == null) return;
    await _initLayers();
    setState(() => _mapReady = true);
  }

  Future<void> _initLayers() async {
    await _loadProvinces();
    await _initProvinceHighlightLayer();
    await _initRulerLayers();
    await _initPolygonLayers();
    await _initDirectionLayers();
  }

  // ─── Ruler layers ───────────────────────────────────────────

  Future<void> _initRulerLayers() async {
    await _controller!.addSource(
      MapConstants.rulerLinesSourceId,
      const GeojsonSourceProperties(data: '{"type":"FeatureCollection","features":[]}'),
    );
    await _controller!.addSource(
      MapConstants.rulerPointsSourceId,
      const GeojsonSourceProperties(data: '{"type":"FeatureCollection","features":[]}'),
    );
    await _controller!.addLineLayer(
      MapConstants.rulerLinesSourceId,
      MapConstants.rulerLinesLayerId,
      const LineLayerProperties(
        lineColor: '#FF7043',
        lineWidth: 2.5,
        lineDasharray: [6, 3],
      ),
    );
    await _controller!.addCircleLayer(
      MapConstants.rulerPointsSourceId,
      MapConstants.rulerPointsLayerId,
      const CircleLayerProperties(
        circleRadius: 6,
        circleColor: '#FF7043',
        circleStrokeWidth: 2,
        circleStrokeColor: '#FFFFFF',
      ),
    );
  }

  void _updateRulerLayer(RulerState state) {
    if (_controller == null) return;

    final pointsGeoJson = {
      'type': 'FeatureCollection',
      'features': state.points
          .map((p) => {
                'type': 'Feature',
                'geometry': {
                  'type': 'Point',
                  'coordinates': [p.longitude, p.latitude],
                },
                'properties': {},
              })
          .toList(),
    };

    final linesGeoJson = {
      'type': 'FeatureCollection',
      'features': state.points.length >= 2
          ? [
              {
                'type': 'Feature',
                'geometry': {
                  'type': 'LineString',
                  'coordinates': state.points
                      .map((p) => [p.longitude, p.latitude])
                      .toList(),
                },
                'properties': {},
              }
            ]
          : [],
    };

    _controller!.setGeoJsonSource(
        MapConstants.rulerPointsSourceId, pointsGeoJson);
    _controller!.setGeoJsonSource(
        MapConstants.rulerLinesSourceId, linesGeoJson);
  }

  // ─── Polygon layers ─────────────────────────────────────────

  Future<void> _initPolygonLayers() async {
    await _controller!.addSource(
      MapConstants.polygonSourceId,
      const GeojsonSourceProperties(data: '{"type":"FeatureCollection","features":[]}'),
    );
    await _controller!.addSource(
      MapConstants.polygonPointsSourceId,
      const GeojsonSourceProperties(data: '{"type":"FeatureCollection","features":[]}'),
    );
    await _controller!.addFillLayer(
      MapConstants.polygonSourceId,
      MapConstants.polygonFillLayerId,
      const FillLayerProperties(
        fillColor: '#7B1FA2',
        fillOpacity: 0.2,
      ),
    );
    await _controller!.addLineLayer(
      MapConstants.polygonSourceId,
      MapConstants.polygonLineLayerId,
      const LineLayerProperties(
        lineColor: '#7B1FA2',
        lineWidth: 2,
      ),
    );
    await _controller!.addCircleLayer(
      MapConstants.polygonPointsSourceId,
      MapConstants.polygonPointsLayerId,
      const CircleLayerProperties(
        circleRadius: 6,
        circleColor: '#7B1FA2',
        circleStrokeWidth: 2,
        circleStrokeColor: '#FFFFFF',
      ),
    );
  }

  void _updatePolygonLayer(PolygonState state) {
    if (_controller == null) return;

    final coords = state.vertices
        .map((p) => [p.longitude, p.latitude])
        .toList();

    // Polygon fill (only when closed)
    final polygonGeoJson = {
      'type': 'FeatureCollection',
      'features': state.isClosed && coords.length >= 3
          ? [
              {
                'type': 'Feature',
                'geometry': {
                  'type': 'Polygon',
                  'coordinates': [
                    [...coords, coords.first], // close the ring
                  ],
                },
                'properties': {},
              }
            ]
          : state.vertices.length >= 2
              ? [
                  {
                    'type': 'Feature',
                    'geometry': {
                      'type': 'LineString',
                      'coordinates': coords,
                    },
                    'properties': {},
                  }
                ]
              : [],
    };

    final pointsGeoJson = {
      'type': 'FeatureCollection',
      'features': state.vertices.indexed
          .map((entry) {
            final (i, p) = entry;
            return {
              'type': 'Feature',
              'geometry': {
                'type': 'Point',
                'coordinates': [p.longitude, p.latitude],
              },
              'properties': {'isFirst': i == 0},
            };
          })
          .toList(),
    };

    _controller!.setGeoJsonSource(
        MapConstants.polygonSourceId, polygonGeoJson);
    _controller!.setGeoJsonSource(
        MapConstants.polygonPointsSourceId, pointsGeoJson);
  }

  // ─── Direction layers ────────────────────────────────────────

  Future<void> _initDirectionLayers() async {
    await _controller!.addSource(
      MapConstants.routeSourceId,
      const GeojsonSourceProperties(data: '{"type":"FeatureCollection","features":[]}'),
    );
    await _controller!.addSource(
      MapConstants.waypointSourceId,
      const GeojsonSourceProperties(data: '{"type":"FeatureCollection","features":[]}'),
    );
    await _controller!.addLineLayer(
      MapConstants.routeSourceId,
      MapConstants.routeCasingLayerId,
      const LineLayerProperties(
        lineColor: '#FFFFFF',
        lineWidth: 9,
        lineCap: 'round',
        lineJoin: 'round',
      ),
    );
    await _controller!.addLineLayer(
      MapConstants.routeSourceId,
      MapConstants.routeLineLayerId,
      const LineLayerProperties(
        lineColor: '#1565C0',
        lineWidth: 5,
        lineCap: 'round',
        lineJoin: 'round',
      ),
    );
    await _controller!.addCircleLayer(
      MapConstants.waypointSourceId,
      MapConstants.waypointLayerId,
      const CircleLayerProperties(
        circleRadius: 8,
        circleColor: [
          'match',
          ['get', 'type'],
          'origin', '#4CAF50',
          '#F44336',
        ],
        circleStrokeWidth: 2.5,
        circleStrokeColor: '#FFFFFF',
      ),
    );
  }

  void _updateDirectionLayer(DirectionState state) {
    if (_controller == null) return;

    // Waypoints
    final waypointFeatures = <Map<String, dynamic>>[];
    if (state.origin != null) {
      waypointFeatures.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [state.origin!.longitude, state.origin!.latitude],
        },
        'properties': {'type': 'origin'},
      });
    }
    if (state.destination != null) {
      waypointFeatures.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [
            state.destination!.longitude,
            state.destination!.latitude
          ],
        },
        'properties': {'type': 'destination'},
      });
    }
    _controller!.setGeoJsonSource(MapConstants.waypointSourceId,
        {'type': 'FeatureCollection', 'features': waypointFeatures});

    // Route line
    if (state.route != null) {
      final routeGeoJson = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'geometry': {
              'type': 'LineString',
              'coordinates': state.route!.geometry
                  .map((p) => [p.longitude, p.latitude])
                  .toList(),
            },
            'properties': {},
          }
        ],
      };
      _controller!.setGeoJsonSource(MapConstants.routeSourceId, routeGeoJson);
      _fitBoundsToRoute(state);
    } else {
      _controller!.setGeoJsonSource(MapConstants.routeSourceId,
          {'type': 'FeatureCollection', 'features': []});
    }
  }

  void _fitBoundsToRoute(DirectionState state) {
    if (state.origin == null || state.destination == null) return;
    final minLat = [state.origin!.latitude, state.destination!.latitude]
        .reduce((a, b) => a < b ? a : b);
    final maxLat = [state.origin!.latitude, state.destination!.latitude]
        .reduce((a, b) => a > b ? a : b);
    final minLng = [state.origin!.longitude, state.destination!.longitude]
        .reduce((a, b) => a < b ? a : b);
    final maxLng = [state.origin!.longitude, state.destination!.longitude]
        .reduce((a, b) => a > b ? a : b);

    _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        left: 80,
        top: 80,
        right: 80,
        bottom: 200,
      ),
    );
  }

  // ─── Province highlight layer ────────────────────────────────

  Future<void> _initProvinceHighlightLayer() async {
    await _controller!.addSource(
      MapConstants.provinceSelectedSourceId,
      const GeojsonSourceProperties(
          data: '{"type":"FeatureCollection","features":[]}'),
    );
    await _controller!.addFillLayer(
      MapConstants.provinceSelectedSourceId,
      MapConstants.provinceSelectedFillLayerId,
      const FillLayerProperties(
        fillColor: '#FF5722',
        fillOpacity: 0.3,
      ),
    );
    await _controller!.addLineLayer(
      MapConstants.provinceSelectedSourceId,
      MapConstants.provinceSelectedLineLayerId,
      const LineLayerProperties(
        lineColor: '#BF360C',
        lineWidth: 2,
        lineOpacity: 0.9,
      ),
    );
  }

  // ─── Province boundary layer ─────────────────────────────────

  Future<void> _loadProvinces() async {
    try {
      final String data =
          await rootBundle.loadString('assets/geo/vietnam_provinces.geojson');
      await _controller!.addSource(
        MapConstants.provincesSourceId,
        GeojsonSourceProperties(data: data),
      );
      await _controller!.addFillLayer(
        MapConstants.provincesSourceId,
        MapConstants.provincesFillLayerId,
        const FillLayerProperties(
          fillColor: '#4CAF50',
          fillOpacity: 0.08,
        ),
      );
      await _controller!.addLineLayer(
        MapConstants.provincesSourceId,
        MapConstants.provincesLineLayerId,
        const LineLayerProperties(
          lineColor: '#2E7D32',
          lineWidth: 1.2,
          lineOpacity: 0.7,
        ),
      );
    } catch (e) {
      // GeoJSON not yet added to assets — silently skip
      debugPrint('Province GeoJSON not found: $e');
    }
  }

  // ─── Map tap handler ─────────────────────────────────────────

  void _onMapTap(Point<double> point, LatLng coordinates) {
    final activeTool = ref.read(activeToolProvider);
    final latLng = ll.LatLng(coordinates.latitude, coordinates.longitude);

    switch (activeTool) {
      case MapTool.ruler:
        ref.read(rulerProvider.notifier).addPoint(latLng);
      case MapTool.polygon:
        ref.read(polygonProvider.notifier).addVertex(latLng);
      case MapTool.direction:
        ref.read(directionProvider.notifier).onMapTap(latLng);
      case MapTool.none:
        _queryProvince(point);
    }
  }

  Future<void> _queryProvince(Point<double> point) async {
    if (_controller == null) return;
    try {
      final features = await _controller!.queryRenderedFeatures(
        point,
        [MapConstants.provincesFillLayerId],
        null,
      );

      if (features.isEmpty) {
        ref.read(selectedProvinceProvider.notifier).clear();
        await _controller!.setGeoJsonSource(
          MapConstants.provinceSelectedSourceId,
          {'type': 'FeatureCollection', 'features': []},
        );
        return;
      }

      final feature = features.first;
      final props = feature['properties'] as Map<String, dynamic>?;
      final name = props?['NAME_1'] as String? ??
          props?['name'] as String? ??
          'Tỉnh không xác định';

      ref.read(selectedProvinceProvider.notifier).select(name);
      await _controller!.setGeoJsonSource(
        MapConstants.provinceSelectedSourceId,
        {'type': 'FeatureCollection', 'features': [feature]},
      );
    } catch (e) {
      debugPrint('Province query error: $e');
    }
  }
}
