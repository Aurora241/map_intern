import 'package:latlong2/latlong.dart';
import '../../../../core/errors/failures.dart';
import '../entities/route_entity.dart';

abstract interface class MapRepository {
  Future<(RouteEntity?, Failure?)> getRoute(LatLng origin, LatLng destination);
}
