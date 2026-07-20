// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KnoQ';

  @override
  String get homeTab => 'Home';

  @override
  String get analyticsTab => 'Analytics';

  @override
  String get settingsTab => 'Settings';

  @override
  String get recentSessions => 'Recent Sessions';

  @override
  String get activeDrills => 'Active Drills';

  @override
  String get totalHits => 'Total Hits';

  @override
  String get avgPower => 'Avg Power';

  @override
  String get sweetSpot => 'Sweet Spot';

  @override
  String get language => 'Language';

  @override
  String get exportData => 'Export My Data';

  @override
  String get exportSuccess => 'Data exported successfully';

  @override
  String get exportError => 'Failed to export data';

  @override
  String get noData => 'No data available';
}
