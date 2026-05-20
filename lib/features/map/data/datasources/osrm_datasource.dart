import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/map_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../models/route_model.dart';

class OsrmDataSource {
  final Dio _dio;

  OsrmDataSource() : _dio = DioClient.instance;

  Future<(RouteModel?, Failure?)> fetchRoute(
    LatLng origin,
    LatLng destination, {
    CancelToken? cancelToken,
  }) async {
    try {
      final url =
          '${ApiConstants.osrmBaseUrl}/${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson';

      final response = await _dio.get(url, cancelToken: cancelToken);

      if (response.data['code'] != 'Ok') {
        return (null, const RouteNotFoundFailure());
      }

      final model = RouteModel.fromOsrmJson(response.data);
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
