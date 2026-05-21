import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProvinceNotifier extends StateNotifier<String?> {
  ProvinceNotifier() : super(null);

  void select(String name) => state = name;
  void clear() => state = null;
}

final selectedProvinceProvider =
    StateNotifierProvider<ProvinceNotifier, String?>(
  (ref) => ProvinceNotifier(),
);
