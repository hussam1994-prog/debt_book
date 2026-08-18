import 'package:flutter/widgets.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/l10n/app_localizations_en.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n {
    return AppLocalizations.of(this) ?? AppLocalizationsEn();
  }
}