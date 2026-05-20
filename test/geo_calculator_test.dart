import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_intern/core/utils/geo_calculator.dart';

void main() {
  group('GeoCalculator', () {
    group('distanceMeters', () {
      test('same point returns 0', () {
        final p = LatLng(21.028, 105.854);
        expect(GeoCalculator.distanceMeters(p, p), 0);
      });

      test('Hanoi to HCM is approximately 1150 km', () {
        final hanoi = LatLng(21.028, 105.854);
        final hcm = LatLng(10.823, 106.630);
        final dist = GeoCalculator.distanceMeters(hanoi, hcm);
        // Allow ±50km tolerance
        expect(dist, greaterThan(1_100_000));
        expect(dist, lessThan(1_200_000));
      });
    });

    group('totalDistanceMeters', () {
      test('empty list returns 0', () {
        expect(GeoCalculator.totalDistanceMeters([]), 0);
      });

      test('single point returns 0', () {
        expect(GeoCalculator.totalDistanceMeters([LatLng(10, 106)]), 0);
      });

      test('two identical points return 0', () {
        final p = LatLng(10.0, 106.0);
        expect(GeoCalculator.totalDistanceMeters([p, p]), 0);
      });
    });

    group('polygonAreaSqMeters', () {
      test('less than 3 points returns 0', () {
        expect(
          GeoCalculator.polygonAreaSqMeters([
            LatLng(10, 106),
            LatLng(11, 106),
          ]),
          0,
        );
      });

      test('small square ~1km x 1km returns ~1_000_000 m²', () {
        // ~0.009 degrees ≈ 1 km at equator
        const d = 0.009;
        final lat = 10.0;
        final lng = 106.0;
        final square = [
          LatLng(lat, lng),
          LatLng(lat + d, lng),
          LatLng(lat + d, lng + d),
          LatLng(lat, lng + d),
        ];
        final area = GeoCalculator.polygonAreaSqMeters(square);
        // Allow 10% tolerance
        expect(area, greaterThan(900_000));
        expect(area, lessThan(1_100_000));
      });
    });

    group('formatDistance', () {
      test('under 1000m shows meters', () {
        expect(GeoCalculator.formatDistance(850), '850 m');
      });

      test('over 1000m shows km', () {
        expect(GeoCalculator.formatDistance(12500), '12.50 km');
      });
    });

    group('formatArea', () {
      test('under 1km² shows m²', () {
        expect(GeoCalculator.formatArea(500000), '500000 m²');
      });

      test('over 1km² shows km²', () {
        expect(GeoCalculator.formatArea(2500000), '2.50 km²');
      });
    });
  });
}
