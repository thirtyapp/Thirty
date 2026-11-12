/// THIRTY's localization access layer (ADR-025; L-INF).
///
/// **English only, by design.** ADR-026 gate G-5C: until a persisted
/// language identity for saved Circles is decided and built (ADR-026 Part B,
/// founder decision D-L-5c), THIRTY runs in English on every device,
/// whatever its language — it starts normally, nothing is refused. There is
/// no define, setting or control that widens [thirtyReleaseLocales]; a guard
/// test pins it (`test/l10n/l_inf_runtime_locale_test.dart`).
///
/// Resolution is a pure function of its inputs ([resolveThirtyLocale]), so
/// domain code can obtain strings without a `BuildContext`
/// ([thirtyLocalizationsFor]) and tests can pass other release sets.
library;

import 'package:flutter/widgets.dart';

import '../../l10n/gen/app_localizations.dart';

/// The languages this build runs in, English first. English only until
/// ADR-026 Part B (see the library comment).
const thirtyReleaseLocales = <Locale>[Locale('en')];

/// The delegates THIRTY's app uses: its own catalogue and the SDK's
/// Material, Cupertino and Widgets localizations. For English these give
/// exactly the words Flutter's defaults gave before L-INF
/// (`test/l10n/l_inf_material_equivalence_test.dart`).
const thirtyLocalizationsDelegates = AppLocalizations.localizationsDelegates;

/// The language THIRTY uses, given the device's ordered locales and an
/// explicit [override] (none exists yet): the override when it is in
/// [releaseLocales]; else the first device locale whose language is; else
/// the first release locale (English). Matched by language only, so a
/// regional variant (fr-BE, es-MX) resolves to its language.
Locale resolveThirtyLocale(
  List<Locale>? deviceLocales, {
  Locale? override,
  List<Locale> releaseLocales = thirtyReleaseLocales,
}) {
  assert(
    releaseLocales.isNotEmpty && releaseLocales.first.languageCode == 'en',
  );
  Locale? supported(Locale? locale) {
    if (locale == null) return null;
    for (final release in releaseLocales) {
      if (release.languageCode == locale.languageCode) return release;
    }
    return null;
  }

  final chosen = supported(override);
  if (chosen != null) return chosen;
  for (final locale in deviceLocales ?? const <Locale>[]) {
    final match = supported(locale);
    if (match != null) return match;
  }
  return releaseLocales.first;
}

/// [MaterialApp.localeListResolutionCallback]: always [resolveThirtyLocale]
/// over [thirtyReleaseLocales].
Locale thirtyLocaleListResolution(
  List<Locale>? deviceLocales,
  Iterable<Locale> supportedLocales,
) => resolveThirtyLocale(deviceLocales);

/// THIRTY's words for [locale], without a `BuildContext` — resolved like the
/// app, so it is English for every locale today.
AppLocalizations thirtyLocalizationsFor(Locale locale) =>
    lookupAppLocalizations(resolveThirtyLocale([locale]));

/// `context.l10n.brandName`.
extension ThirtyLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
