import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/geo_calculator.dart';
import '../providers/map_tool_provider.dart';
import '../providers/ruler_provider.dart';
import '../providers/polygon_provider.dart';

class MeasurementCard extends ConsumerWidget {
  const MeasurementCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTool = ref.watch(activeToolProvider);

    return switch (activeTool) {
      MapTool.ruler => _RulerCard(),
      MapTool.polygon => _PolygonCard(),
      _ => const SizedBox.shrink(),
    };
  }
}

class _RulerCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ruler = ref.watch(rulerProvider);
    if (!ruler.hasPoints) return const SizedBox.shrink();

    return _CardContainer(
      icon: Icons.straighten,
      color: const Color(0xFFFF7043),
      actions: [
        if (ruler.canUndo)
          _CardAction(
            icon: Icons.undo,
            label: 'Hoàn tác',
            onTap: () => ref.read(rulerProvider.notifier).removeLastPoint(),
          ),
        _CardAction(
          icon: Icons.clear,
          label: 'Xóa',
          onTap: () => ref.read(rulerProvider.notifier).clear(),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            GeoCalculator.formatDistance(ruler.totalDistance),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (ruler.segmentDistances.length > 1)
            Text(
              '${ruler.points.length} điểm • ${ruler.segmentDistances.length} đoạn',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }
}

class _PolygonCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final polygon = ref.watch(polygonProvider);
    if (!polygon.hasVertices) return const SizedBox.shrink();

    return _CardContainer(
      icon: Icons.pentagon_outlined,
      color: const Color(0xFF7B1FA2),
      actions: [
        if (polygon.canClose)
          _CardAction(
            icon: Icons.check,
            label: 'Đóng',
            onTap: () => ref.read(polygonProvider.notifier).closePolygon(),
          ),
        if (polygon.canUndo)
          _CardAction(
            icon: Icons.undo,
            label: 'Hoàn tác',
            onTap: () => ref.read(polygonProvider.notifier).removeLastVertex(),
          ),
        _CardAction(
          icon: Icons.clear,
          label: 'Xóa',
          onTap: () => ref.read(polygonProvider.notifier).clear(),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (polygon.isClosed && polygon.areaSqMeters != null)
            Text(
              GeoCalculator.formatArea(polygon.areaSqMeters!),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Text(
              '${polygon.vertices.length} điểm',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          Text(
            polygon.isClosed ? 'Diện tích' : 'Tap điểm đầu hoặc nhấn Đóng',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Widget child;
  final List<_CardAction> actions;

  const _CardContainer({
    required this.icon,
    required this.color,
    required this.child,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
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
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: child),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CardAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
