import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/osrm_datasource.dart';
import '../../data/repositories/map_repository_impl.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/usecases/get_route_usecase.dart';

enum DirectionStatus { idle, selectingOrigin, selectingDest, loading, loaded, error }

class DirectionState {
  final DirectionStatus status;
  final LatLng? origin;
  final LatLng? destination;
  final RouteEntity? route;
  final Failure? failure;

  const DirectionState({
    this.status = DirectionStatus.idle,
    this.origin,
    this.destination,
    this.route,
    this.failure,
  });

  String get hint {
    switch (status) {
      case DirectionStatus.idle:
        return 'Chọn điểm xuất phát';
      case DirectionStatus.selectingOrigin:
        return 'Tap để chọn điểm xuất phát';
      case DirectionStatus.selectingDest:
        return 'Tap để chọn điểm đến';
      case DirectionStatus.loading:
        return 'Đang tìm đường...';
      case DirectionStatus.loaded:
        return '${route?.formattedDuration} • ${route?.formattedDistance}';
      case DirectionStatus.error:
        return failure?.message ?? 'Có lỗi xảy ra';
    }
  }

  DirectionState copyWith({
    DirectionStatus? status,
    LatLng? origin,
    LatLng? destination,
    RouteEntity? route,
    Failure? failure,
  }) {
    return DirectionState(
      status: status ?? this.status,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      route: route ?? this.route,
      failure: failure ?? this.failure,
    );
  }
}

class DirectionNotifier extends StateNotifier<DirectionState> {
  final GetRouteUseCase _getRoute;

  DirectionNotifier(this._getRoute) : super(const DirectionState());

  void startSelecting() {
    state = const DirectionState(status: DirectionStatus.selectingOrigin);
  }

  void onMapTap(LatLng point) {
    if (state.status == DirectionStatus.selectingOrigin) {
      state = state.copyWith(
        origin: point,
        status: DirectionStatus.selectingDest,
      );
    } else if (state.status == DirectionStatus.selectingDest) {
      state = state.copyWith(
        destination: point,
        status: DirectionStatus.loading,
      );
      _fetchRoute(state.origin!, point);
    }
  }

  Future<void> _fetchRoute(LatLng origin, LatLng dest) async {
    state = state.copyWith(status: DirectionStatus.loading);
    final (route, failure) = await _getRoute(origin, dest);

    if (failure != null) {
      state = state.copyWith(status: DirectionStatus.error, failure: failure);
      return;
    }
    if (route == null) return;
    state = state.copyWith(status: DirectionStatus.loaded, route: route);
  }

  void swapWaypoints() {
    if (state.origin == null || state.destination == null) return;
    final tmp = state.origin;
    state = DirectionState(
      status: DirectionStatus.loading,
      origin: state.destination,
      destination: tmp,
    );
    _fetchRoute(state.origin!, state.destination!);
  }

  void clear() {
    state = const DirectionState();
  }
}

final directionProvider =
    StateNotifierProvider<DirectionNotifier, DirectionState>((ref) {
  final repo = MapRepositoryImpl(OsrmDataSource());
  final useCase = GetRouteUseCase(repo);
  return DirectionNotifier(useCase);
});
