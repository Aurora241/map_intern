import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/utils/geo_calculator.dart';

class RulerState {
  final List<LatLng> points;
  final List<double> segmentDistances;
  final double totalDistance;

  const RulerState({
    this.points = const [],
    this.segmentDistances = const [],
    this.totalDistance = 0,
  });

  bool get hasPoints => points.isNotEmpty;
  bool get canUndo => points.isNotEmpty;

  RulerState copyWith({
    List<LatLng>? points,
    List<double>? segmentDistances,
    double? totalDistance,
  }) {
    return RulerState(
      points: points ?? this.points,
      segmentDistances: segmentDistances ?? this.segmentDistances,
      totalDistance: totalDistance ?? this.totalDistance,
    );
  }
}

class RulerNotifier extends StateNotifier<RulerState> {
  RulerNotifier() : super(const RulerState());

  void addPoint(LatLng point) {
    final newPoints = [...state.points, point];
    final segments = GeoCalculator.segmentDistances(newPoints);
    final total = GeoCalculator.totalDistanceMeters(newPoints);
    state = state.copyWith(
      points: newPoints,
      segmentDistances: segments,
      totalDistance: total,
    );
  }

  void removeLastPoint() {
    if (state.points.isEmpty) return;
    final newPoints = state.points.sublist(0, state.points.length - 1);
    final segments = GeoCalculator.segmentDistances(newPoints);
    final total = GeoCalculator.totalDistanceMeters(newPoints);
    state = state.copyWith(
      points: newPoints,
      segmentDistances: segments,
      totalDistance: total,
    );
  }

  void clear() {
    state = const RulerState();
  }
}

final rulerProvider =
    StateNotifierProvider<RulerNotifier, RulerState>((ref) => RulerNotifier());
