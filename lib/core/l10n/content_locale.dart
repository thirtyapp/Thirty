/// THIRTY's content language (ADR-025 §7) — the language of an element's
/// words and of the recordings that say them. It is not the UI locale.
///
/// The two answer different questions:
/// - **UI locale** (`thirty_locales.dart`): which language the screens use.
///   An unsupported device language resolves to English, and the app
///   carries on.
/// - **Content locale**: which approved words and recordings exist. A
///   content language with no approved words or no approved recordings has
///   none — it never borrows English ones. No content means no voice.
library;

import 'package:flutter/foundation.dart';

/// A content language, by its language code. Any code can be asked for;
/// whether THIRTY has approved words in it is [hasApprovedContent].
@immutable
class ContentLocale {
  const ContentLocale(this.languageCode);

  /// English: the canonical source of THIRTY's content (Amendment 3), and
  /// the language of the frozen English recordings.
  static const english = ContentLocale('en');

  final String languageCode;

  /// Whether THIRTY has founder-approved words in this language.
  bool get hasApprovedContent => approvedContentLocales.contains(this);

  @override
  bool operator ==(Object other) =>
      other is ContentLocale && other.languageCode == languageCode;

  @override
  int get hashCode => languageCode.hashCode;

  @override
  String toString() => 'ContentLocale($languageCode)';
}

/// The content languages with founder-approved words: English only. A
/// language joins this set only with its complete, natively reviewed
/// content (Amendment 3, ADR-025).
final approvedContentLocales = Set<ContentLocale>.unmodifiable({
  ContentLocale.english,
});

/// The content language of every Circle in this build: English.
///
/// The release-locale set is English only (ADR-026 gate G-5C), so every
/// session, before and after a restart, uses English words and English
/// recordings.
///
/// Not built here, because it needs a new persisted session field: taking
/// a Circle's content language from the UI locale at Start, and keeping it
/// until Close across a restart (ADR-025 §7.4). That field is D-L-8, still
/// OPEN.
const currentContentLocale = ContentLocale.english;
