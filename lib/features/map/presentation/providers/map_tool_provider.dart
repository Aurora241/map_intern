import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MapTool { none, ruler, polygon, direction }

final activeToolProvider = StateProvider<MapTool>((ref) => MapTool.none);
