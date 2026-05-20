import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/utils/geo_calculator.dart';

class PolygonState {
  final List<LatLng> vertices;
  final bool isClosed;
  final double? areaSqMeters;

  const PolygonState({
    this.vertices = const [],
    this.isClosed = false,
    this.areaSqMeters,
  });

  bool get canClose => vertices.length >= 3 && !isClosed;
  bool get canUndo => vertices.isNotEmpty && !isClosed;
  bool get hasVertices => vertices.isNotEmpty;

  PolygonState copyWith({
    List<LatLng>? vertices,
    bool? isClosed,
    double? areaSqMeters,
  }) {
    return PolygonState(
      vertices: vertices ?? this.vertices,
      isClosed: isClosed ?? this.isClosed,
      areaSqMeters: areaSqMeters ?? this.areaSqMeters,
    );
  }
}

class PolygonNotifier extends StateNotifier<PolygonState> {
  PolygonNotifier() : super(const PolygonState());

  void addVertex(LatLng point) {
    if (state.isClosed) return;
    state = state.copyWith(vertices: [...state.vertices, point]);
  }

  void closePolygon() {
    if (!state.canClose) return;
    final area = GeoCalculator.polygonAreaSqMeters(state.vertices);
    state = state.copyWith(isClosed: true, areaSqMeters: area);
  }

  void removeLastVertex() {
    if (!state.canUndo) return;
    state = state.copyWith(
      vertices: state.vertices.sublist(0, state.vertices.length - 1),
    );
  }

  void clear() {
    state = const PolygonState();
  }
}

final polygonProvider = StateNotifierProvider<PolygonNotifier, PolygonState>(
    (ref) => PolygonNotifier());
