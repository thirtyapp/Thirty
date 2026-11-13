import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The product name: the app title (MaterialApp.onGenerateTitle) and the name shown in the You tab's About card. A brand: never translated in any language.
  ///
  /// In en, this message translates to:
  /// **'THIRTY'**
  String get brandName;

  /// You tab: the heading of the About section, above the informational card that shows the product name and the running version. A short section heading; the section has no links or actions.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get youAboutSectionTitle;

  /// You tab, About card: the line under the product name that shows which build is running. {version} is the app's version string exactly as the build reports it (digits, dots and a plus sign, e.g. major.minor.patch+build): inserted verbatim, never translated, reformatted or padded.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String youAboutVersion(String version);

  /// You tab: the page's main heading, shown in the editorial serif under the THIRTY wordmark at the top of the page and announced as a heading. It names the tab (the same word as the tab's name in the bottom navigation): the person's own space in the app, not an account or profile.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youPageTitle;

  /// You tab: the one-line subtitle directly under the page heading. A calm description of the page as the person's own space in the app (their experience, preferences and data), not an account. THIRTY is the product name (see brandName) and is never translated. Ends with a full stop.
  ///
  /// In en, this message translates to:
  /// **'Your space in THIRTY.'**
  String get youPageSubtitle;

  /// You tab: the heading of the Personal section, above the card with what is the person's own and stays on this device: their optional first name, what THIRTY remembers, the Circles they kept and their Circle history. A short section heading, announced as a heading.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get youPersonalSectionTitle;

  /// You tab: the heading of the Preferences section, above the card with the app's settings: the daily reminder, appearance (theme) and, in builds that include it, spoken guidance. A short section heading, announced as a heading.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get youPreferencesSectionTitle;

  /// You tab: the heading of the Data & privacy section, above the card with the privacy and data controls: the usage-data choice, copying the Circle history as text, and deleting the Circle history. A short section heading, announced as a heading; the ampersand is part of the heading.
  ///
  /// In en, this message translates to:
  /// **'Data & privacy'**
  String get youDataPrivacySectionTitle;

  /// You tab, Personal section: the title of the row that opens the What THIRTY remembers page, where the person sees what they have told THIRTY after their Circles, need by need. The row is one button: a screen reader reads this title, a comma and the line under it (youPersonalMemoryDetail) together as one label. The same words also name that page and appear elsewhere in the app; this key is only the row on You. THIRTY is the product name (see brandName) and is never translated.
  ///
  /// In en, this message translates to:
  /// **'What THIRTY remembers'**
  String get youPersonalMemoryTitle;

  /// You tab, Personal section: the supporting line under youPersonalMemoryTitle, saying what that page holds: what the person has told THIRTY ("it"), grouped need by need. Shown in smaller secondary text under youPersonalMemoryTitle; a screen reader reads it after the title and a comma, as part of the row's one label. It describes the row and is not a separate instruction or hint. Uses a typographic apostrophe (’).
  ///
  /// In en, this message translates to:
  /// **'What you’ve told it, need by need'**
  String get youPersonalMemoryDetail;

  /// You tab, Personal section: the title of the row that opens the person's Circle history, the dated record of their Circles kept on this device. The row is one button: a screen reader reads this title, a comma and the line under it (youPersonalHistoryDetail) together as one label. It is not the Yours row (the Circles the person chose to keep) and not the Insights heading that uses the same words; this key is only the row on You.
  ///
  /// In en, this message translates to:
  /// **'Your Circles'**
  String get youPersonalHistoryTitle;

  /// You tab, Personal section: the supporting line under youPersonalHistoryTitle, saying what the Circle history holds: each of the person's Circles, recorded as it happened. Shown in smaller secondary text under youPersonalHistoryTitle; a screen reader reads it after the title and a comma, as part of the row's one label. It describes the row and is not a separate instruction or hint.
  ///
  /// In en, this message translates to:
  /// **'Every Circle, as it happened'**
  String get youPersonalHistoryDetail;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
