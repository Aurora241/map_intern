import 'dart:math';
import 'package:latlong2/latlong.dart';

class GeoCalculator {
  static const Distance _distance = Distance();

  /// Haversine distance in meters between two points
  static double distanceMeters(LatLng a, LatLng b) {
    return _distance.as(LengthUnit.Meter, a, b);
  }

  /// Total distance of a polyline in meters
  static double totalDistanceMeters(List<LatLng> points) {
    if (points.length < 2) return 0;
    double total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      total += distanceMeters(points[i], points[i + 1]);
    }
    return total;
  }

  /// Segment distances for a polyline in meters
  static List<double> segmentDistances(List<LatLng> points) {
    if (points.length < 2) return [];
    return List.generate(
      points.length - 1,
      (i) => distanceMeters(points[i], points[i + 1]),
    );
  }

  /// Spherical polygon area in square meters using the spherical excess formula.
  /// Accurate for typical use cases (city/province scale).
  static double polygonAreaSqMeters(List<LatLng> points) {
    if (points.length < 3) return 0;

    const double earthRadius = 6371008.8; // meters
    final int n = points.length;
    double area = 0.0;

    for (int i = 0; i < n; i++) {
      final LatLng p1 = points[i];
      final LatLng p2 = points[(i + 1) % n];

      final double lat1 = p1.latitudeInRad;
      final double lat2 = p2.latitudeInRad;
      final double dLng =
          (p2.longitude - p1.longitude) * (pi / 180.0);

      area += dLng * (2 + sin(lat1) + sin(lat2));
    }

    area = (area * earthRadius * earthRadius / 2).abs();
    return area;
  }

  /// Format distance for display
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  /// Format area for display
  static String formatArea(double sqMeters) {
    if (sqMeters < 1000000) {
      return '${sqMeters.toStringAsFixed(0)} m²';
    }
    return '${(sqMeters / 1000000).toStringAsFixed(2)} km²';
  }
}
