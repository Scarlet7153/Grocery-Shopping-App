import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StoreThemePreference {
  system,
  light,
  dark,
}

class StoreThemeState {
  final StoreThemePreference preference;

  const StoreThemeState({required this.preference});

  ThemeMode get themeMode {
    switch (preference) {
      case StoreThemePreference.light:
        return ThemeMode.light;
      case StoreThemePreference.dark:
        return ThemeMode.dark;
      case StoreThemePreference.system:
        return ThemeMode.system;
    }
  }
}

class StoreThemeCubit extends Cubit<StoreThemeState> {
  static const String _prefKey = 'store_theme_preference';

  StoreThemeCubit()
      : super(const StoreThemeState(preference: StoreThemePreference.system)) {
    _loadSavedPreference();
  }

  Future<void> setThemePreference(StoreThemePreference preference) async {
    emit(StoreThemeState(preference: preference));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, preference.name);
  }

  Future<void> _loadSavedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final rawValue = prefs.getString(_prefKey);

    if (rawValue == null || rawValue.isEmpty) {
      return;
    }

    for (final item in StoreThemePreference.values) {
      if (item.name == rawValue) {
        emit(StoreThemeState(preference: item));
        return;
      }
    }
  }
}
