// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MyBudget';

  @override
  String get settingsSignOut => 'Sign Out';

  @override
  String get settingsSectionRegion => 'Region';

  @override
  String get settingsLocaleTileTitle => 'Language & region';

  @override
  String get settingsLocaleDialogTitle => 'Language & region';
}
