import 'dart:io';

/// ADR-024 B8 — the live product's words, read from production source.
///
/// Every string literal under `lib/` outside developer-only code (the QA
/// harness, dev previews, the design-system showcase), with comments and
/// import lines removed and Dart's implicit concatenation of adjacent
/// literals joined, so a phrase split over lines is one string. Used by the
/// live-copy guards and the review pack, so both read exactly what ships.
class LiveString {
  const LiveString(
    this.file,
    this.line,
    this.text,
    this.context, {
    this.statement = '',
  });

  final String file;
  final int line;
  final String text;

  /// The source line the literal starts on and the one before, trimmed —
  /// to tell copy from keys, routes and diagnostics.
  final String context;

  /// Up to six lines before the literal: whether it is the message of an
  /// `assert(…)` or a thrown error whose condition spans lines.
  final String statement;

  String get where => '$file:$line';
}

const developerOnly = [
  'lib/core/qa/',
  'lib/core/dev_preview/',
  'lib/core/showcase/',
];

final _literal = RegExp(
  r"r?'(?:[^'\\\n]|\\.)*'"
  '|'
  r'r?"(?:[^"\\\n]|\\.)*"',
);

/// [file]'s literals, adjacent ones joined.
List<LiveString> literalsIn(String file) {
  final lines = File(file).readAsLinesSync();
  final kept = [
    for (final line in lines)
      switch (line.trim()) {
        final t
            when t.startsWith('//') ||
                t.startsWith('import ') ||
                t.startsWith('export ') ||
                t.startsWith('part ') =>
          '',
        _ => line,
      },
  ];
  final text = kept.join('\n');
  final out = <LiveString>[];
  int? startLine;
  String? context;
  String? statement;
  final buffer = StringBuffer();
  var end = -1;
  void flush() {
    if (startLine != null) {
      out.add(
        LiveString(
          file,
          startLine!,
          buffer.toString(),
          context!,
          statement: statement!,
        ),
      );
    }
    startLine = null;
    buffer.clear();
  }

  for (final m in _literal.allMatches(text)) {
    final between = end < 0 ? null : text.substring(end, m.start);
    final adjacent = between != null && between.trim().isEmpty;
    if (!adjacent) flush();
    final raw = m.group(0)!;
    final body = raw.startsWith('r')
        ? raw.substring(2, raw.length - 1)
        : raw.substring(1, raw.length - 1);
    if (startLine == null) {
      startLine = text.substring(0, m.start).split('\n').length;
      // The line it starts on and the one before: a diagnostic's message
      // often starts on the line after `throw StateError(`.
      context = [
        if (startLine! > 1) kept[startLine! - 2].trim(),
        kept[startLine! - 1].trim(),
      ].join(' ');
      final from = startLine! > 6 ? startLine! - 7 : 0;
      final before = kept.sublist(from, startLine! - 1);
      // Only the statement this literal belongs to: stop at the last `;`.
      final last = before.lastIndexWhere((l) => l.trimRight().endsWith(';'));
      statement = before.sublist(last + 1).join(' ');
    }
    buffer.write(body.replaceAll(r"\'", "'").replaceAll(r'\n', ' '));
    end = m.end;
  }
  flush();
  return out;
}

/// Every production Dart file outside developer-only code, sorted.
List<String> productionFiles() {
  final files = [
    for (final f in Directory('lib').listSync(recursive: true))
      if (f is File && f.path.endsWith('.dart')) f.path.replaceAll(r'\', '/'),
  ]..removeWhere((p) => developerOnly.any(p.startsWith));
  return files..sort();
}

/// Whether [s] reads as words a person sees — not a key, route, asset,
/// wire value or diagnostic.
bool looksLikeCopy(LiveString s) {
  final t = s.text.trim();
  if (t.length < 2 || !t.contains(RegExp('[A-Za-z]'))) return false;
  if (t.startsWith('/') ||
      t.startsWith('assets/') ||
      t.startsWith('package:')) {
    return false;
  }
  if (!t.contains(' ') && !RegExp(r'^[A-Z][a-z’]+[.!?]?$').hasMatch(t)) {
    return false;
  }
  // Mostly interpolation (a debug trace's `${c.id.name}(b…`): not copy.
  final words = t
      .replaceAll(RegExp(r'\$\{[^}]*\}?'), ' ')
      .replaceAll(RegExp(r'\$\w+'), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => RegExp('[A-Za-z]{2,}').hasMatch(w))
      .length;
  if (t.contains(r'$') && words < 2) return false;
  final st = s.statement;
  for (final marker in ['assert(', 'throw ', 'Error(', 'Exception(']) {
    if (st.contains(marker)) return false;
  }
  final c = s.context;
  for (final marker in [
    'assert(',
    'ArgumentError',
    'StateError',
    'UnsupportedError',
    'FormatException',
    'debugPrint',
    'developer.log',
    'throw ',
    'Key(',
    'RegExp(',
  ]) {
    if (c.contains(marker)) return false;
  }
  return true;
}
