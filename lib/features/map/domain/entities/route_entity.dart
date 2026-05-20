import 'package:latlong2/latlong.dart';

class RouteEntity {
  final List<LatLng> geometry;
  final double distanceMeters;
  final double durationSeconds;

  const RouteEntity({
    required this.geometry,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get formattedDuration {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) return '$minutes phút';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '$hours giờ $mins phút';
  }
}
