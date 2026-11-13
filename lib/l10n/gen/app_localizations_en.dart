// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get brandName => 'THIRTY';

  @override
  String get youAboutSectionTitle => 'About';

  @override
  String youAboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get youPageTitle => 'You';

  @override
  String get youPageSubtitle => 'Your space in THIRTY.';

  @override
  String get youPersonalSectionTitle => 'Personal';

  @override
  String get youPreferencesSectionTitle => 'Preferences';

  @override
  String get youDataPrivacySectionTitle => 'Data & privacy';

  @override
  String get youPersonalMemoryTitle => 'What THIRTY remembers';

  @override
  String get youPersonalMemoryDetail => 'What you’ve told it, need by need';

  @override
  String get youPersonalHistoryTitle => 'Your Circles';

  @override
  String get youPersonalHistoryDetail => 'Every Circle, as it happened';

  @override
  String get youAppearanceTitle => 'Appearance';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';
}
