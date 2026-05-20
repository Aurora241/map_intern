import 'package:latlong2/latlong.dart';
import '../../domain/entities/route_entity.dart';

class RouteModel {
  final List<LatLng> geometry;
  final double distanceMeters;
  final double durationSeconds;

  const RouteModel({
    required this.geometry,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  factory RouteModel.fromOsrmJson(Map<String, dynamic> json) {
    final route = json['routes'][0] as Map<String, dynamic>;
    final coords =
        (route['geometry']['coordinates'] as List).map((c) {
      final pair = c as List;
      // OSRM returns [lng, lat]
      return LatLng(
        (pair[1] as num).toDouble(),
        (pair[0] as num).toDouble(),
      );
    }).toList();

    return RouteModel(
      geometry: coords,
      distanceMeters: (route['distance'] as num).toDouble(),
      durationSeconds: (route['duration'] as num).toDouble(),
    );
  }

  RouteEntity toEntity() => RouteEntity(
        geometry: geometry,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
      );
}
