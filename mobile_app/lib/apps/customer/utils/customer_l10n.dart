import 'package:flutter/widgets.dart';

import '../../../core/utils/app_localizations.dart';

extension CustomerL10nContext on BuildContext {
  String tr({required String vi, required String en}) {
    final localizations =
        AppLocalizations.of(this) ?? AppLocalizations(Localizations.localeOf(this));
    return localizations.byLocale(vi: vi, en: en);
  }
}
