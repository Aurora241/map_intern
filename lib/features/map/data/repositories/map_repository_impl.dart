import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/repositories/map_repository.dart';
import '../datasources/osrm_datasource.dart';

class MapRepositoryImpl implements MapRepository {
  final OsrmDataSource _dataSource;
  CancelToken? _cancelToken;

  MapRepositoryImpl(this._dataSource);

  @override
  Future<(RouteEntity?, Failure?)> getRoute(
      LatLng origin, LatLng destination) async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    final (model, failure) = await _dataSource.fetchRoute(
      origin,
      destination,
      cancelToken: _cancelToken,
    );

    if (failure != null) return (null, failure);
    if (model == null) return (null, null);
    return (model.toEntity(), null);
  }

  void dispose() {
    _cancelToken?.cancel();
  }
}
