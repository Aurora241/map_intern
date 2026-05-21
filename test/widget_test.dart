import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_intern/features/map/presentation/providers/map_tool_provider.dart';
import 'package:map_intern/features/map/presentation/providers/ruler_provider.dart';
import 'package:map_intern/features/map/presentation/providers/polygon_provider.dart';
import 'package:map_intern/features/map/presentation/widgets/tool_panel.dart';
import 'package:map_intern/features/map/presentation/widgets/measurement_card.dart';

ProviderContainer makeContainer() => ProviderContainer();

Widget wrap(Widget child, {ProviderContainer? container}) {
  return UncontrolledProviderScope(
    container: container ?? ProviderContainer(),
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('ToolPanel', () {
    testWidgets('renders all 4 buttons', (tester) async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(bottomNavigationBar: ToolPanel()),
        ),
      ));

      expect(find.text('Ruler'), findsOneWidget);
      expect(find.text('Polygon'), findsOneWidget);
      expect(find.text('Direction'), findsOneWidget);
      expect(find.text('Xóa'), findsOneWidget);
    });

    testWidgets('tapping Ruler activates ruler tool', (tester) async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(bottomNavigationBar: ToolPanel()),
        ),
      ));

      expect(container.read(activeToolProvider), MapTool.none);
      await tester.tap(find.text('Ruler'));
      await tester.pump();
      expect(container.read(activeToolProvider), MapTool.ruler);
    });

    testWidgets('tapping active tool again deactivates it', (tester) async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(bottomNavigationBar: ToolPanel()),
        ),
      ));

      await tester.tap(find.text('Ruler'));
      await tester.pump();
      expect(container.read(activeToolProvider), MapTool.ruler);

      await tester.tap(find.text('Ruler'));
      await tester.pump();
      expect(container.read(activeToolProvider), MapTool.none);
    });

    testWidgets('tapping Polygon activates polygon tool', (tester) async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(bottomNavigationBar: ToolPanel()),
        ),
      ));

      await tester.tap(find.text('Polygon'));
      await tester.pump();
      expect(container.read(activeToolProvider), MapTool.polygon);
    });

    testWidgets('switching tools clears previous tool state', (tester) async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(activeToolProvider.notifier).state = MapTool.ruler;
      container.read(rulerProvider.notifier).addPoint(LatLng(21.0, 106.0));
      expect(container.read(rulerProvider).points.length, 1);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(bottomNavigationBar: ToolPanel()),
        ),
      ));

      await tester.tap(find.text('Polygon'));
      await tester.pump();

      // Ruler state was cleared when switching to Polygon
      expect(container.read(rulerProvider).points, isEmpty);
    });
  });

  group('MeasurementCard', () {
    testWidgets('hidden when no tool is active', (tester) async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(wrap(const MeasurementCard(), container: container));

      // SizedBox.shrink — no measurement icons or text rendered
      expect(find.byIcon(Icons.straighten), findsNothing);
      expect(find.byIcon(Icons.pentagon_outlined), findsNothing);
      expect(find.textContaining('km'), findsNothing);
      expect(find.textContaining('m²'), findsNothing);
    });

    testWidgets('shows distance after ruler adds two points', (tester) async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(activeToolProvider.notifier).state = MapTool.ruler;
      container.read(rulerProvider.notifier).addPoint(LatLng(21.028, 105.854)); // Hanoi
      container.read(rulerProvider.notifier).addPoint(LatLng(10.823, 106.630)); // HCM

      await tester.pumpWidget(wrap(const MeasurementCard(), container: container));

      // Distance HN→HCM ≈ 1149 km — should show "km"
      expect(find.textContaining('km'), findsOneWidget);
    });

    testWidgets('shows point count when polygon is open', (tester) async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(activeToolProvider.notifier).state = MapTool.polygon;
      container.read(polygonProvider.notifier).addVertex(LatLng(21.0, 105.0));
      container.read(polygonProvider.notifier).addVertex(LatLng(21.1, 105.0));

      await tester.pumpWidget(wrap(const MeasurementCard(), container: container));

      expect(find.text('2 điểm'), findsOneWidget);
    });

    testWidgets('shows area after polygon is closed', (tester) async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(activeToolProvider.notifier).state = MapTool.polygon;
      container.read(polygonProvider.notifier).addVertex(LatLng(21.0, 105.0));
      container.read(polygonProvider.notifier).addVertex(LatLng(22.0, 105.0));
      container.read(polygonProvider.notifier).addVertex(LatLng(21.5, 106.0));
      container.read(polygonProvider.notifier).closePolygon();

      await tester.pumpWidget(wrap(const MeasurementCard(), container: container));

      // Closed polygon shows area — either m² or km²
      final hasArea = find.textContaining('km²').evaluate().isNotEmpty ||
          find.textContaining('m²').evaluate().isNotEmpty;
      expect(hasArea, isTrue);
    });
  });
}
