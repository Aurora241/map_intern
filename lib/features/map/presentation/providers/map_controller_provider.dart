import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

final mapControllerProvider =
    StateProvider<MapLibreMapController?>((ref) => null);

// True after onStyleLoaded + layer init completes
final mapReadyProvider = StateProvider<bool>((ref) => false);

// Current map zoom level — updated on every camera idle
final zoomLevelProvider = StateProvider<double>((ref) => 5.5);
