import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StoreLanguagePreference {
  system,
  vietnamese,
  english,
}

class StoreLanguageState {
  final StoreLanguagePreference preference;

  const StoreLanguageState({required this.preference});

  Locale? get locale {
    switch (preference) {
      case StoreLanguagePreference.vietnamese:
        return const Locale('vi');
      case StoreLanguagePreference.english:
        return const Locale('en');
      case StoreLanguagePreference.system:
        return null;
    }
  }
}

class StoreLanguageCubit extends Cubit<StoreLanguageState> {
  static const String _prefKey = 'store_language_preference';

  StoreLanguageCubit()
      : super(
          const StoreLanguageState(
            preference: StoreLanguagePreference.system,
          ),
        ) {
    _loadSavedPreference();
  }

  Future<void> setLanguagePreference(StoreLanguagePreference preference) async {
    emit(StoreLanguageState(preference: preference));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, preference.name);
  }

  Future<void> _loadSavedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final rawValue = prefs.getString(_prefKey);

    if (rawValue == null || rawValue.isEmpty) {
      return;
    }

    for (final item in StoreLanguagePreference.values) {
      if (item.name == rawValue) {
        emit(StoreLanguageState(preference: item));
        return;
      }
    }
  }
}
