class MapConstants {
  static const double defaultLat = 16.0;
  static const double defaultLng = 106.0;
  static const double defaultZoom = 5.5;
  static const double minZoom = 3.0;
  static const double maxZoom = 18.0;

  static const String tileStyleUrl =
      'https://tiles.openfreemap.org/styles/bright';

  static const String provincesSourceId = 'provinces-source';
  static const String provincesFillLayerId = 'provinces-fill';
  static const String provincesLineLayerId = 'provinces-line';
  static const String provinceSelectedFillLayerId = 'province-selected-fill';

  static const String rulerPointsSourceId = 'ruler-points-source';
  static const String rulerLinesSourceId = 'ruler-lines-source';
  static const String rulerPointsLayerId = 'ruler-points-layer';
  static const String rulerLinesLayerId = 'ruler-lines-layer';

  static const String polygonSourceId = 'polygon-source';
  static const String polygonFillLayerId = 'polygon-fill-layer';
  static const String polygonLineLayerId = 'polygon-line-layer';
  static const String polygonPointsSourceId = 'polygon-points-source';
  static const String polygonPointsLayerId = 'polygon-points-layer';

  static const String routeSourceId = 'route-source';
  static const String routeLineLayerId = 'route-line-layer';
  static const String routeCasingLayerId = 'route-casing-layer';
  static const String waypointSourceId = 'waypoint-source';
  static const String waypointLayerId = 'waypoint-layer';
}

class ApiConstants {
  static const String osrmBaseUrl =
      'https://router.project-osrm.org/route/v1/driving';
  static const int connectTimeoutMs = 10000;
  static const int receiveTimeoutMs = 15000;
}
