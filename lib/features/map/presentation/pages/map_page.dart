import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../providers/map_controller_provider.dart';
import '../widgets/map_view.dart';
import '../widgets/tool_panel.dart';
import '../widgets/measurement_card.dart';
import '../widgets/direction_panel.dart';
import '../widgets/zoom_controls.dart';
import '../widgets/province_card.dart';
import '../widgets/map_loading_overlay.dart';

class MapPage extends ConsumerWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          const MapView(),
          const MapLoadingOverlay(),

          // Zoom controls
          Positioned(
            right: 16,
            bottom: 160,
            child: ZoomControls(
              onZoomIn: () => _zoom(ref, 1),
              onZoomOut: () => _zoom(ref, -1),
            ),
          ),

          // Info cards float above tool panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 90,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                DirectionPanel(),
                MeasurementCard(),
                ProvinceCard(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ToolPanel(),
    );
  }

  void _zoom(WidgetRef ref, int direction) {
    final controller = ref.read(mapControllerProvider);
    if (controller == null) return;
    if (direction > 0) {
      controller.animateCamera(CameraUpdate.zoomIn());
    } else {
      controller.animateCamera(CameraUpdate.zoomOut());
    }
  }
}
