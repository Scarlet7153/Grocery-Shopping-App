import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ShipperThemePreference {
  system,
  light,
  dark,
}

class ShipperThemeState {
  final ShipperThemePreference preference;

  const ShipperThemeState({required this.preference});

  ThemeMode get themeMode {
    switch (preference) {
      case ShipperThemePreference.light:
        return ThemeMode.light;
      case ShipperThemePreference.dark:
        return ThemeMode.dark;
      case ShipperThemePreference.system:
        return ThemeMode.system;
    }
  }
}

class ShipperThemeCubit extends Cubit<ShipperThemeState> {
  static const String _prefKey = 'shipper_theme_preference';

  ShipperThemeCubit()
      : super(const ShipperThemeState(preference: ShipperThemePreference.system)) {
    _loadSavedPreference();
  }

  Future<void> setThemePreference(ShipperThemePreference preference) async {
    emit(ShipperThemeState(preference: preference));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, preference.name);
  }

  Future<void> _loadSavedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final rawValue = prefs.getString(_prefKey);

    if (rawValue == null || rawValue.isEmpty) {
      return;
    }

    for (final item in ShipperThemePreference.values) {
      if (item.name == rawValue) {
        emit(ShipperThemeState(preference: item));
        return;
      }
    }
  }
}
