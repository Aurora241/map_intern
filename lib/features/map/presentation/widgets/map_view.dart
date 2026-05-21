import 'dart:math' show Point;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../../../core/constants/map_constants.dart';
import '../../../../core/utils/geo_calculator.dart';
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
  bool _provinceLayerReady = false;

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
    ref.listen(activeToolProvider, (prev, next) {
      if (next != MapTool.none && _provinceLayerReady && _controller != null) {
        _controller!
            .setGeoJsonSource(
              MapConstants.provinceSelectedSourceId,
              {'type': 'FeatureCollection', 'features': []},
            )
            .catchError((_) {});
        ref.read(selectedProvinceProvider.notifier).clear();
      }
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
    try {
      await _initLayers();
    } catch (e) {
      debugPrint('Layer init error: $e');
    } finally {
      if (mounted) setState(() => _mapReady = true);
    }
  }

  Future<void> _initLayers() async {
    // Each group is independent — one failure must not block the others
    try {
      await _initRulerLayers();
    } catch (e) {
      debugPrint('Ruler init error: $e');
    }
    try {
      await _initPolygonLayers();
    } catch (e) {
      debugPrint('Polygon init error: $e');
    }
    try {
      await _initDirectionLayers();
    } catch (e) {
      debugPrint('Direction init error: $e');
    }
    try {
      await _loadProvinces();
      await _initProvinceHighlightLayer();
      _provinceLayerReady = true;
    } catch (e) {
      debugPrint('Province init error: $e');
    }
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
    await _controller!.addSource(
      MapConstants.rulerLabelsSourceId,
      const GeojsonSourceProperties(data: '{"type":"FeatureCollection","features":[]}'),
    );
    await _controller!.addSymbolLayer(
      MapConstants.rulerLabelsSourceId,
      MapConstants.rulerLabelsLayerId,
      const SymbolLayerProperties(
        textField: '{label}',
        textSize: 11,
        textColor: '#FF7043',
        textHaloColor: '#FFFFFF',
        textHaloWidth: 1.5,
        textAllowOverlap: true,
        textIgnorePlacement: true,
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

    // Segment distance labels at midpoint of each segment
    final labelFeatures = <Map<String, dynamic>>[];
    for (int i = 0; i < state.points.length - 1; i++) {
      final p1 = state.points[i];
      final p2 = state.points[i + 1];
      labelFeatures.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [
            (p1.longitude + p2.longitude) / 2,
            (p1.latitude + p2.latitude) / 2,
          ],
        },
        'properties': {
          'label': GeoCalculator.formatDistance(state.segmentDistances[i]),
        },
      });
    }
    _controller!.setGeoJsonSource(
        MapConstants.rulerLabelsSourceId,
        {'type': 'FeatureCollection', 'features': labelFeatures});
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
    await _controller!.addSource(
      MapConstants.polygonLabelsSourceId,
      const GeojsonSourceProperties(data: '{"type":"FeatureCollection","features":[]}'),
    );
    await _controller!.addSymbolLayer(
      MapConstants.polygonLabelsSourceId,
      MapConstants.polygonLabelsLayerId,
      const SymbolLayerProperties(
        textField: '{label}',
        textSize: 11,
        textColor: '#7B1FA2',
        textHaloColor: '#FFFFFF',
        textHaloWidth: 1.5,
        textAllowOverlap: true,
        textIgnorePlacement: true,
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

    // Labels: segment distances at midpoints + area at centroid
    final labelFeatures = <Map<String, dynamic>>[];
    final verts = state.vertices;

    // Segment labels
    final edgeCount = state.isClosed ? verts.length : verts.length - 1;
    for (int i = 0; i < edgeCount; i++) {
      final p1 = verts[i];
      final p2 = verts[(i + 1) % verts.length];
      final dist = GeoCalculator.distanceMeters(p1, p2);
      labelFeatures.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [
            (p1.longitude + p2.longitude) / 2,
            (p1.latitude + p2.latitude) / 2,
          ],
        },
        'properties': {'label': GeoCalculator.formatDistance(dist)},
      });
    }

    // Area label at centroid (only when closed)
    if (state.isClosed && state.areaSqMeters != null && verts.isNotEmpty) {
      final centLat = verts.map((p) => p.latitude).reduce((a, b) => a + b) / verts.length;
      final centLng = verts.map((p) => p.longitude).reduce((a, b) => a + b) / verts.length;
      labelFeatures.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [centLng, centLat],
        },
        'properties': {'label': GeoCalculator.formatArea(state.areaSqMeters!)},
      });
    }

    _controller!.setGeoJsonSource(
        MapConstants.polygonLabelsSourceId,
        {'type': 'FeatureCollection', 'features': labelFeatures});
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
    // Two separate layers avoid match-expression compatibility issues
    await _controller!.addCircleLayer(
      MapConstants.waypointSourceId,
      '${MapConstants.waypointLayerId}-origin',
      const CircleLayerProperties(
        circleRadius: 8,
        circleColor: '#4CAF50',
        circleStrokeWidth: 2.5,
        circleStrokeColor: '#FFFFFF',
      ),
      filter: ['==', 'type', 'origin'],
    );
    await _controller!.addCircleLayer(
      MapConstants.waypointSourceId,
      '${MapConstants.waypointLayerId}-dest',
      const CircleLayerProperties(
        circleRadius: 8,
        circleColor: '#F44336',
        circleStrokeWidth: 2.5,
        circleStrokeColor: '#FFFFFF',
      ),
      filter: ['==', 'type', 'destination'],
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
      final rawProps = feature['properties'];
      final props = rawProps is Map
          ? rawProps.map((k, v) => MapEntry(k.toString(), v))
          : <String, dynamic>{};
      final name = props['NAME_1']?.toString() ??
          props['name']?.toString() ??
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
