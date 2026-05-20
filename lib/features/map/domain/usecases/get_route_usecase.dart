import 'package:latlong2/latlong.dart';
import '../../../../core/errors/failures.dart';
import '../entities/route_entity.dart';
import '../repositories/map_repository.dart';

class GetRouteUseCase {
  final MapRepository _repository;

  const GetRouteUseCase(this._repository);

  Future<(RouteEntity?, Failure?)> call(
      LatLng origin, LatLng destination) async {
    return _repository.getRoute(origin, destination);
  }
}
