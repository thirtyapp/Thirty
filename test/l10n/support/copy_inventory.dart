import 'dart:io';

import '../../features/b8/support/live_copy.dart';

/// ADR-025 §6 G-HC / G-A11Y: the inventory of hard-coded user-facing text.
///
/// Dart: every string literal the B8 extractor reads from production source
/// (developer-only and generated code excluded; adjacent literals joined;
/// single and double quotes), kept when it reads as words — the rule of the
/// 2026-11-03 inventory tool (`hardcoded_inventory.py`): at least two
/// letters in a row, not an identifier, key, route, asset or URL, and either
/// a space or a capital first letter. Diagnostics (assertions, thrown
/// errors, logs) are technical, not user-facing. A literal on an
/// accessibility site (labels, hints, tooltips, announcements, live
/// regions) is classed `a11y`.
///
/// Android: Kotlin notification-channel and notification text constants
/// (the inventory tool's rule), and `android:label` in the manifest.
class CopyCandidate {
  const CopyCandidate(this.kind, this.file, this.text);

  /// `copy`, `a11y` or `android`.
  final String kind;
  final String file;
  final String text;

  String get id => '$kind\t$file\t$text';
}

final _letters = RegExp('[A-Za-z]{2,}');
final _identifier = RegExp(r'^[a-z_][A-Za-z0-9_.:/-]*$');
final _technical = RegExp(
  r'throw |assert\(|StateError|ArgumentError|FormatException|debugPrint|'
  r'FlutterError|UnsupportedError|developer\.log|toString\(\)|Error\(|'
  r'Exception\(',
);
final _a11y = RegExp(
  r'semanticsLabel|semanticLabel|Semantics\(|label:|hint:|tooltip|'
  r'liveRegion|announce|onTapHint|onLongPressHint',
);

/// Whether [t] reads as words rather than a key or path.
bool readsAsWords(String t) {
  if (!_letters.hasMatch(t)) return false;
  if (_identifier.hasMatch(t)) return false;
  for (final p in [
    'package:',
    'dart:',
    'assets',
    'http',
    'android.',
    'com.',
    'io.',
  ]) {
    if (t.startsWith(p)) return false;
  }
  return t.contains(' ') || t[0] != t[0].toLowerCase();
}

/// The candidates in the Dart [files].
List<CopyCandidate> dartCandidates(List<String> files) => [
  for (final f in files)
    for (final s in literalsIn(f))
      if (readsAsWords(s.text) &&
          !_technical.hasMatch(s.context) &&
          !_technical.hasMatch(s.statement))
        CopyCandidate(
          _a11y.hasMatch(s.context) ? 'a11y' : 'copy',
          s.file,
          s.text,
        ),
];

final _kotlinLiteral = RegExp(r'"((?:[^"\\\n]|\\.)*)"');
final _kotlinSite = RegExp(
  r'setContent|NotificationChannel\(|CHANNEL_NAME|CHANNEL_DESC|Toast|'
  r'setTicker|const val [A-Z_]*(NAME|DESCRIPTION|TITLE|TEXT)\b',
);

/// The candidates in Android's Kotlin sources and manifest under [root].
List<CopyCandidate> androidCandidates([String root = 'android/app/src/main']) {
  final out = <CopyCandidate>[];
  final dir = Directory('$root/kotlin');
  if (dir.existsSync()) {
    final files = [
      for (final f in dir.listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.kt')) f.path.replaceAll(r'\', '/'),
    ]..sort();
    for (final f in files) {
      for (final line in File(f).readAsLinesSync()) {
        final t = line.trim();
        if (t.startsWith('//') || t.startsWith('*')) continue;
        if (!_kotlinSite.hasMatch(line)) continue;
        for (final m in _kotlinLiteral.allMatches(line)) {
          if (readsAsWords(m.group(1)!)) {
            out.add(CopyCandidate('android', f, m.group(1)!));
          }
        }
      }
    }
  }
  final manifest = File('$root/AndroidManifest.xml');
  if (manifest.existsSync()) {
    for (final m in RegExp(
      r'android:label="([^"@]*)"',
    ).allMatches(manifest.readAsStringSync())) {
      out.add(
        CopyCandidate(
          'android',
          manifest.path.replaceAll(r'\', '/'),
          m.group(1)!,
        ),
      );
    }
  }
  return out;
}

/// The whole inventory of this checkout.
List<CopyCandidate> inventory() => [
  ...dartCandidates(productionFiles()),
  ...androidCandidates(),
];

/// Candidates as a multiset: how many times each (kind, file, text) occurs.
Map<String, int> counts(Iterable<CopyCandidate> cs) {
  final out = <String, int>{};
  for (final c in cs) {
    out[c.id] = (out[c.id] ?? 0) + 1;
  }
  return out;
}

String escapeField(String s) =>
    s.replaceAll(r'\', r'\\').replaceAll('\t', r'\t').replaceAll('\n', r'\n');

String unescapeField(String s) => s.replaceAllMapped(
  RegExp(r'\\(.)'),
  (m) => switch (m.group(1)) {
    't' => '\t',
    'n' => '\n',
    final other => other!,
  },
);

/// The baseline file: `kind \t file \t count \t text` per line.
Map<String, int> readBaseline(String path) {
  final out = <String, int>{};
  for (final line in File(path).readAsLinesSync()) {
    if (line.isEmpty || line.startsWith('#')) continue;
    final parts = line.split('\t');
    if (parts.length != 4) throw StateError('bad baseline line: $line');
    final [kind, file, count, text] = parts;
    out['$kind\t$file\t${unescapeField(text)}'] = int.parse(count);
  }
  return out;
}

/// What [current] has beyond [baseline] (new, unapproved text), and what
/// [baseline] still lists that is gone (stale entries the baseline must
/// drop: it only ever shrinks).
({List<String> added, List<String> stale}) compareToBaseline(
  Map<String, int> current,
  Map<String, int> baseline,
) {
  final added = <String>[];
  final stale = <String>[];
  for (final MapEntry(:key, :value) in current.entries) {
    final allowed = baseline[key] ?? 0;
    if (value > allowed) added.add('$key  (×${value - allowed})');
  }
  for (final MapEntry(:key, :value) in baseline.entries) {
    final now = current[key] ?? 0;
    if (now < value) stale.add('$key  (×${value - now})');
  }
  return (added: added..sort(), stale: stale..sort());
}
