# Map Intern

Flutter map application built as a 6-day assessment project. Runs on Android (tested on CPH2481, Android 15).

## Features

### Ruler
Tap multiple points on the map to measure distance along a path. Each segment shows its distance inline; the card at the bottom displays the running total.

- Haversine formula for accurate geodesic distances
- Undo last point / clear all
- Format: `m` under 1 km, `km` above

### Polygon
Draw a polygon by tapping vertices. Close it by tapping near the first point (< 30 px). The map shows edge lengths on each side and the total area at the centroid.

- Spherical excess formula for area on a curved Earth
- Undo vertex / clear
- Format: `m²` under 1 km², `km²` above

### Direction
Tap origin then destination — the app fetches a driving route from OSRM and draws it on the map.

- Via-point routing: 2 intermediate waypoints are inserted at 33 % and 67 % of the straight line, with longitudes clamped to keep the route inside Vietnam's road network through the narrow central waist (Quảng Bình, lat ≈ 16–17°)
- Post-validation: every point in the returned geometry is checked against the Vietnamese border; routes that escape (e.g. through Laos or Cambodia) are rejected
- Error states: no network, no route found, timeout, point outside Vietnam — each shown with a retry button
- Swap origin ↔ destination in one tap

### Province Highlight
Tap anywhere on the map (no tool active) to highlight the province under the finger and display its name.

## Setup

```bash
flutter pub get
flutter run
```

Requires Android device or emulator with internet access. No API keys needed — map tiles are served by [OpenFreeMap](https://openfreemap.org) and routing by the public [OSRM](https://project-osrm.org) server.

## Architecture

```
lib/
  core/
    constants/   # MapConstants, ApiConstants
    errors/      # Failure sealed class hierarchy
    network/     # Dio client with timeouts
    utils/       # GeoCalculator (haversine, spherical excess)
  features/map/
    data/
      datasources/  # OsrmDataSource — HTTP + Vietnam boundary logic
      models/       # RouteModel (DTO)
      repositories/ # MapRepositoryImpl
    domain/
      entities/     # RouteEntity
      repositories/ # MapRepository interface
      usecases/     # GetRouteUseCase
    presentation/
      pages/        # MapPage — scaffold, stack layout
      providers/    # Riverpod state: ruler, polygon, direction, province, tool
      widgets/      # MapView, tool panels, measurement cards, zoom controls
```

State management: **Riverpod** (`StateNotifierProvider`).  
Map rendering: **MapLibre GL** — GeoJSON sources updated in place; no layer teardown on state change.

## Technical decisions

**MapLibre GL** over Google Maps / Mapbox — open source, no billing, works offline with custom tiles. The Flutter plugin wraps the native Android/iOS SDK via a platform view.

**OpenFreeMap** for tiles — free, no key, global coverage, vector tiles served over HTTPS. Bright style chosen for readability.

**OSRM public server** for routing — zero setup, adequate for demo. Limitation: shared infrastructure, no SLA. Production would use a self-hosted OSRM instance or a commercial routing API with a Vietnamese road profile.

**Haversine** for ruler/polygon distances — accurate to < 0.3 % for distances under 1000 km, sufficient for this use case. Vincenty would be more accurate at transcontinental scale.

**Listener instead of `onMapClick`** — MapLibre's `onMapClick` callback does not fire reliably on some Android devices using the Vulkan renderer (confirmed on CPH2481, Android 15). Raw pointer events via Flutter's `Listener` widget work on all devices; tap is detected when movement < 15 px and duration < 400 ms.

**`localPosition × devicePixelRatio`** — Flutter's pointer events report logical pixels; MapLibre's `toLatLng()` expects physical pixels. Devices with high DPI (CPH2481: dpr = 3.0) placed dots at the wrong location without this conversion.

## Limitations

- Routing uses the OSRM `driving` profile — travel time reflects car speeds, not motorcycle speeds. A motorcycle factor (~×1.3 duration) could be applied client-side.
- No offline support — tiles and routing both require internet.
- Self-intersecting polygons are accepted without warning; area calculation becomes unreliable in that case.
- Province boundaries are simplified (≈ 5 %) for performance; boundary precision is ± a few hundred metres.

## If I had more time

- Self-hosted OSRM with a Vietnamese road profile tuned for motorcycle speeds
- Geocoding search bar to set origin/destination by name
- Offline tile cache for the Vietnam bounding box
- GPX export for ruler paths and polygon areas
- Unit test coverage for DirectionNotifier state machine
