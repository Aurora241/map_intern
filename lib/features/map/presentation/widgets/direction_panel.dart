import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/direction_provider.dart';
import '../providers/map_tool_provider.dart';

class DirectionPanel extends ConsumerWidget {
  const DirectionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTool = ref.watch(activeToolProvider);
    if (activeTool != MapTool.direction) return const SizedBox.shrink();

    final direction = ref.watch(directionProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.directions,
                        color: Color(0xFF1565C0), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWaypointRow(
                          context,
                          icon: Icons.trip_origin,
                          color: Colors.green,
                          label: direction.origin != null
                              ? _formatCoord(direction.origin!.latitude,
                                  direction.origin!.longitude)
                              : 'Điểm xuất phát',
                          hasValue: direction.origin != null,
                        ),
                        const SizedBox(height: 4),
                        _buildWaypointRow(
                          context,
                          icon: Icons.location_on,
                          color: Colors.red,
                          label: direction.destination != null
                              ? _formatCoord(
                                  direction.destination!.latitude,
                                  direction.destination!.longitude)
                              : 'Điểm đến',
                          hasValue: direction.destination != null,
                        ),
                      ],
                    ),
                  ),
                  if (direction.origin != null && direction.destination != null)
                    IconButton(
                      icon: const Icon(Icons.swap_vert),
                      onPressed: () =>
                          ref.read(directionProvider.notifier).swapWaypoints(),
                      tooltip: 'Đảo chiều',
                    ),
                ],
              ),
              if (direction.status == DirectionStatus.loading)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(),
                ),
              if (direction.status == DirectionStatus.loaded &&
                  direction.route != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        direction.route!.formattedDuration,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.route, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        direction.route!.formattedDistance,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              if (direction.status == DirectionStatus.error)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 14, color: Colors.red),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          direction.hint,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              if (direction.status == DirectionStatus.selectingOrigin ||
                  direction.status == DirectionStatus.selectingDest)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.touch_app, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        direction.hint,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaypointRow(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required bool hasValue,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: hasValue ? Colors.black87 : Colors.grey,
            fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
          ),
        ),
      ],
    );
  }

  String _formatCoord(double lat, double lng) {
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }
}
