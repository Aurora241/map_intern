import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/map_controller_provider.dart';

class MapLoadingOverlay extends ConsumerWidget {
  const MapLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReady = ref.watch(mapReadyProvider);
    if (isReady) return const SizedBox.shrink();

    return const ColoredBox(
      color: Color(0xFFEEEEEE),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải bản đồ...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
