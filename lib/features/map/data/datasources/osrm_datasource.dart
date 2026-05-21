import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/map_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../models/route_model.dart';

class OsrmDataSource {
  final Dio _dio;

  OsrmDataSource() : _dio = DioClient.instance;

  // ─── Vietnam geographic constraints ─────────────────────────
  static const double _vnMinLat = 8.18;
  static const double _vnMaxLat = 23.37;
  static const double _vnMaxLng = 109.46;

  /// Approximate western border longitude of Vietnam at a given latitude,
  /// calibrated to the actual Vietnam–Laos–Cambodia border.
  /// Used for POST-ROUTE VALIDATION — must not reject points that are
  /// genuinely inside Vietnam (false positives cause valid routes to fail).
  ///
  ///  Border reference (approximate):
  ///    lat 22–23 → ~102.5 (Hà Giang/China)
  ///    lat 20–22 → ~103.0 (Điện Biên/Sơn La)
  ///    lat 18–20 → ~103.7 (Thanh Hoá/Nghệ An, border far west)
  ///    lat 17–18 → ~105.0 (Hà Tĩnh, border closes in)
  ///    lat 16–17 → ~106.1 (Quảng Bình — narrowest waist)
  ///    lat 15–16 → ~106.6 (Quảng Trị/Huế)
  ///    lat 13–15 → ~107.0 (Kon Tum/Gia Lai)
  ///    lat 10–13 → ~107.0 (Đắk Lắk/Bình Phước/Cambodia)
  ///    lat  < 10 → ~104.0 (Mekong delta)
  static double _minVietnamLng(double lat) {
    if (lat >= 22.0) return 102.5;
    if (lat >= 20.0) return 103.0;
    if (lat >= 18.0) return 103.7; // Nghệ An — border far west
    if (lat >= 17.0) return 105.0; // Hà Tĩnh
    if (lat >= 16.0) return 106.0; // Quảng Bình (~106.1)
    if (lat >= 15.0) return 106.5; // Quảng Trị/Huế
    if (lat >= 13.0) return 107.0; // Kon Tum/Gia Lai — border ~107.0
    if (lat >= 11.5) return 106.5; // Đắk Lắk/Đắk Nông
    if (lat >= 10.0) return 104.8; // Bình Phước/HCMC — Cambodia border ~104.5
    return 104.0;                  // Mekong delta
  }

  /// Safe minimum longitude for OSRM VIA POINTS — more conservative than
  /// _minVietnamLng so via points land clearly on Vietnam's road network,
  /// not right on the border where roads may not exist.
  static double _safeViaLng(double lat) {
    if (lat >= 22.0) return 103.5;
    if (lat >= 20.0) return 104.0;
    if (lat >= 18.0) return 105.0; // QL1A corridor (Nghệ An)
    if (lat >= 17.0) return 105.8; // Hà Tĩnh coast
    if (lat >= 16.0) return 106.5; // Đồng Hới coast
    if (lat >= 15.0) return 107.2; // Huế area
    if (lat >= 13.0) return 107.5; // Kon Tum/Gia Lai (QL19/QL14)
    if (lat >= 11.5) return 107.5; // Đắk Lắk/Đắk Nông
    if (lat >= 10.0) return 105.5; // Bình Phước / north HCMC
    return 105.0;                  // Mekong delta
  }

  static bool _isInVietnam(double lat, double lng) =>
      lat >= _vnMinLat &&
      lat <= _vnMaxLat &&
      lng >= _minVietnamLng(lat) &&
      lng <= _vnMaxLng;

  /// Build OSRM URL with 2 intermediate via points.
  /// Via latitudes are linearly interpolated (33 / 67 %).
  /// Via longitudes are clamped with _safeViaLng so they land on
  /// Vietnam's road network even through the narrow central waist.
  static String _buildUrl(LatLng origin, LatLng destination) {
    final vias = <LatLng>[];
    for (final t in [0.33, 0.67]) {
      final lat = origin.latitude + (destination.latitude - origin.latitude) * t;
      final lngLinear = origin.longitude + (destination.longitude - origin.longitude) * t;
      final lng = lngLinear < _safeViaLng(lat) ? _safeViaLng(lat) : lngLinear;
      vias.add(LatLng(lat, lng));
    }

    final allPoints = [origin, ...vias, destination];
    final coords = allPoints.map((p) => '${p.longitude},${p.latitude}').join(';');

    // ignore: avoid_print
    print('[OSRM] via1=${vias[0].latitude.toStringAsFixed(2)},${vias[0].longitude.toStringAsFixed(2)}'
        ' via2=${vias[1].latitude.toStringAsFixed(2)},${vias[1].longitude.toStringAsFixed(2)}');

    return '${ApiConstants.osrmBaseUrl}/$coords?overview=full&geometries=geojson';
  }

  Future<(RouteModel?, Failure?)> fetchRoute(
    LatLng origin,
    LatLng destination, {
    CancelToken? cancelToken,
  }) async {
    // 1. Validate both endpoints are within Vietnam
    if (!_isInVietnam(origin.latitude, origin.longitude) ||
        !_isInVietnam(destination.latitude, destination.longitude)) {
      return (null, const PointOutsideVietnamFailure());
    }

    try {
      final url = _buildUrl(origin, destination);
      // ignore: avoid_print
      print('[OSRM] GET $url');
      final response = await _dio.get(url, cancelToken: cancelToken);

      if (response.data['code'] != 'Ok') {
        // ignore: avoid_print
        print('[OSRM] code=${response.data['code']} → RouteNotFound');
        return (null, const RouteNotFoundFailure());
      }

      final model = RouteModel.fromOsrmJson(response.data);

      // 2. Post-validate: check no route point escapes Vietnam's bounding box
      final badPoints = model.geometry
          .where((p) => !_isInVietnam(p.latitude, p.longitude))
          .toList();
      if (badPoints.isNotEmpty) {
        // ignore: avoid_print
        print('[OSRM] Route outside VN: first bad point = ${badPoints.first}');
        return (null, const RouteOutsideVietnamFailure());
      }

      // ignore: avoid_print
      print('[OSRM] OK — ${model.geometry.length} pts, '
          '${(model.distanceMeters / 1000).toStringAsFixed(1)} km');
      return (model, null);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return (null, null);
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return (null, const TimeoutFailure());
      }
      if (e.type == DioExceptionType.connectionError) {
        return (null, const NetworkFailure());
      }
      return (null, const ServerFailure());
    } catch (_) {
      return (null, const ParseFailure());
    }
  }
}
