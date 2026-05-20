import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/map_tool_provider.dart';
import '../providers/ruler_provider.dart';
import '../providers/polygon_provider.dart';
import '../providers/direction_provider.dart';

class ToolPanel extends ConsumerWidget {
  const ToolPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTool = ref.watch(activeToolProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ToolButton(
              icon: Icons.straighten,
              label: 'Ruler',
              color: const Color(0xFFFF7043),
              isActive: activeTool == MapTool.ruler,
              onTap: () => _toggleTool(ref, MapTool.ruler),
            ),
            _ToolButton(
              icon: Icons.pentagon_outlined,
              label: 'Polygon',
              color: const Color(0xFF7B1FA2),
              isActive: activeTool == MapTool.polygon,
              onTap: () => _toggleTool(ref, MapTool.polygon),
            ),
            _ToolButton(
              icon: Icons.directions,
              label: 'Direction',
              color: const Color(0xFF1565C0),
              isActive: activeTool == MapTool.direction,
              onTap: () => _toggleTool(ref, MapTool.direction),
            ),
            _ToolButton(
              icon: Icons.clear_all,
              label: 'Xóa',
              color: Colors.grey[600]!,
              isActive: false,
              onTap: () => _clearAll(ref),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleTool(WidgetRef ref, MapTool tool) {
    final current = ref.read(activeToolProvider);
    if (current == tool) {
      ref.read(activeToolProvider.notifier).state = MapTool.none;
    } else {
      _clearToolState(ref, current);
      ref.read(activeToolProvider.notifier).state = tool;
      if (tool == MapTool.direction) {
        ref.read(directionProvider.notifier).startSelecting();
      }
    }
  }

  void _clearToolState(WidgetRef ref, MapTool tool) {
    switch (tool) {
      case MapTool.ruler:
        ref.read(rulerProvider.notifier).clear();
      case MapTool.polygon:
        ref.read(polygonProvider.notifier).clear();
      case MapTool.direction:
        ref.read(directionProvider.notifier).clear();
      case MapTool.none:
        break;
    }
  }

  void _clearAll(WidgetRef ref) {
    final current = ref.read(activeToolProvider);
    _clearToolState(ref, current);
    ref.read(activeToolProvider.notifier).state = MapTool.none;
    ref.read(rulerProvider.notifier).clear();
    ref.read(polygonProvider.notifier).clear();
    ref.read(directionProvider.notifier).clear();
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? color : Colors.grey[600], size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
