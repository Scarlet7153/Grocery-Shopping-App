import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class SettingsEvent {}

class ThemeChanged extends SettingsEvent {
  final bool isDarkMode;
  ThemeChanged(this.isDarkMode);
}

class LanguageChanged extends SettingsEvent {
  final String languageCode;
  LanguageChanged(this.languageCode);
}

// State
class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;

  SettingsState({
    required this.themeMode,
    required this.locale,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

// Bloc
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SharedPreferences prefs;

  SettingsBloc({required this.prefs})
      : super(SettingsState(
          themeMode: _loadTheme(prefs),
          locale: _loadLocale(prefs),
        )) {
    on<ThemeChanged>((event, emit) async {
      final themeMode = event.isDarkMode ? ThemeMode.dark : ThemeMode.light;
      await prefs.setBool('is_dark_mode', event.isDarkMode);
      emit(state.copyWith(themeMode: themeMode));
    });

    on<LanguageChanged>((event, emit) async {
      final locale = Locale(event.languageCode);
      await prefs.setString('language_code', event.languageCode);
      emit(state.copyWith(locale: locale));
    });
  }

  static ThemeMode _loadTheme(SharedPreferences prefs) {
    final isDark = prefs.getBool('is_dark_mode') ?? false;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static Locale _loadLocale(SharedPreferences prefs) {
    final code = prefs.getString('language_code') ?? 'vi';
    return Locale(code);
  }
}
