import 'dart:convert';
import 'dart:io';

/// ADR-025 §6 G-KEYS: THIRTY's own check of its ARB catalogue.
///
/// `flutter gen-l10n` alone is not enough: for a message missing from a
/// non-English catalogue it silently falls back to English and exits 0. So
/// every rule below fails the test suite instead, whatever the generator
/// does:
///
/// - every catalogue parses, names its locale, and is one of the six launch
///   languages; every enabled locale has a catalogue;
/// - the English template describes every key and declares exactly the
///   placeholders its message uses, with types the generator accepts;
/// - every message is valid ICU for gen-l10n (`{name}`, `plural`, `select`),
///   every plural has `other` and only the categories its language has,
///   every select has `other`;
/// - every other catalogue has exactly the template's keys (none missing,
///   none unsupported), the same placeholders per message, and no metadata
///   of its own for keys.

/// The six launch languages (Amendment 3). A catalogue for any other
/// language is an unsupported resource.
const launchLanguages = {'en', 'fr', 'nl', 'es', 'de', 'it'};

/// CLDR cardinal plural categories per launch language (CLDR 46). `=N`
/// exact matches are always allowed; `other` is always required.
const pluralCategories = {
  'en': {'one', 'other'},
  'nl': {'one', 'other'},
  'de': {'one', 'other'},
  'fr': {'one', 'many', 'other'},
  'es': {'one', 'many', 'other'},
  'it': {'one', 'many', 'other'},
};

const _placeholderTypes = {
  'String',
  'int',
  'double',
  'num',
  'DateTime',
  'Object',
};

/// One ICU argument found in a message.
class IcuArgument {
  IcuArgument(this.name, this.kind, this.cases);

  final String name;

  /// `simple`, `plural` or `select`.
  final String kind;
  final List<String> cases;
}

class IcuSyntaxError implements Exception {
  IcuSyntaxError(this.message, this.offset);
  final String message;
  final int offset;
  @override
  String toString() => '$message at $offset';
}

/// The ICU arguments of [message], outermost and nested, or throws
/// [IcuSyntaxError]. gen-l10n's grammar without `use-escaping`: text is
/// anything but braces; an argument is `{name}`, `{name, plural, cases}` or
/// `{name, select, cases}`; a case is `key{message}`.
List<IcuArgument> parseIcu(String message) {
  final out = <IcuArgument>[];
  var i = 0;
  final ident = RegExp(r'[A-Za-z_][A-Za-z0-9_]*');

  void ws() {
    while (i < message.length && ' \t\n\r'.contains(message[i])) {
      i++;
    }
  }

  String word() {
    final m = ident.matchAsPrefix(message, i);
    if (m == null) throw IcuSyntaxError('expected a name', i);
    i = m.end;
    return m.group(0)!;
  }

  late void Function({required bool nested}) body;

  void argument() {
    // At '{'.
    i++;
    ws();
    final name = word();
    ws();
    if (i < message.length && message[i] == '}') {
      i++;
      out.add(IcuArgument(name, 'simple', const []));
      return;
    }
    if (i >= message.length || message[i] != ',') {
      throw IcuSyntaxError('expected "}" or "," after {$name', i);
    }
    i++;
    ws();
    final kind = word();
    if (kind != 'plural' && kind != 'select') {
      throw IcuSyntaxError('unsupported argument type "$kind"', i);
    }
    ws();
    if (i >= message.length || message[i] != ',') {
      throw IcuSyntaxError('expected "," after $kind', i);
    }
    i++;
    final cases = <String>[];
    while (true) {
      ws();
      if (i >= message.length) throw IcuSyntaxError('unclosed $kind', i);
      if (message[i] == '}') {
        i++;
        break;
      }
      final m = RegExp(
        r'=\d+|[A-Za-z_][A-Za-z0-9_]*',
      ).matchAsPrefix(message, i);
      if (m == null) throw IcuSyntaxError('expected a case key', i);
      final key = m.group(0)!;
      if (cases.contains(key)) throw IcuSyntaxError('duplicate case $key', i);
      cases.add(key);
      i = m.end;
      ws();
      if (i >= message.length || message[i] != '{') {
        throw IcuSyntaxError('expected "{" after case $key', i);
      }
      i++;
      body(nested: true);
      if (i >= message.length || message[i] != '}') {
        throw IcuSyntaxError('unclosed case $key', i);
      }
      i++;
    }
    if (cases.isEmpty) throw IcuSyntaxError('$kind without cases', i);
    out.add(IcuArgument(name, kind, cases));
  }

  body = ({required bool nested}) {
    while (i < message.length) {
      final ch = message[i];
      if (ch == '{') {
        argument();
      } else if (ch == '}') {
        if (nested) return;
        throw IcuSyntaxError('unmatched "}"', i);
      } else {
        i++;
      }
    }
    if (nested) throw IcuSyntaxError('unclosed "{"', i);
  };

  body(nested: false);
  return out;
}

/// A catalogue file's contents.
class Catalogue {
  Catalogue(this.file, this.locale, this.raw);

  final String file;
  final String locale;
  final Map<String, Object?> raw;

  String get language => locale.split(RegExp('[_-]')).first;

  Map<String, String> get messages => {
    for (final e in raw.entries)
      if (!e.key.startsWith('@')) e.key: '${e.value}',
  };

  Map<String, Object?>? meta(String key) =>
      (raw['@$key'] as Map?)?.cast<String, Object?>();
}

/// Every violation of the G-KEYS rules in [arbDir], with [templateFile] as
/// the English template and [enabledLocales] the locales the build offers.
List<String> catalogueViolations(
  String arbDir, {
  String templateFile = 'app_en.arb',
  Set<String> enabledLocales = const {'en'},
}) {
  final v = <String>[];
  final catalogues = <Catalogue>[];
  final files =
      Directory(arbDir)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.arb'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final f in files) {
    final name = f.uri.pathSegments.last;
    Object? decoded;
    try {
      decoded = jsonDecode(f.readAsStringSync());
    } on FormatException catch (e) {
      v.add('$name: not valid JSON (${e.message})');
      continue;
    }
    if (decoded is! Map) {
      v.add('$name: not a JSON object');
      continue;
    }
    final raw = decoded.cast<String, Object?>();
    final locale = raw['@@locale'];
    final expected = RegExp(r'^app_(.+)\.arb$').firstMatch(name)?.group(1);
    if (locale is! String || locale != expected) {
      v.add('$name: "@@locale" must be "$expected"');
      continue;
    }
    final c = Catalogue(name, locale, raw);
    if (!launchLanguages.contains(c.language)) {
      v.add('$name: unsupported language "${c.language}"');
    }
    catalogues.add(c);
  }
  for (final locale in enabledLocales) {
    if (!catalogues.any((c) => c.locale == locale)) {
      v.add('missing catalogue for enabled locale "$locale"');
    }
  }
  final template = catalogues.where((c) => c.file == templateFile).firstOrNull;
  if (template == null) {
    v.add('missing template $templateFile');
    return v;
  }

  // Template: descriptions, declared vs used placeholders, ICU, plurals.
  final templatePlaceholders = <String, Set<String>>{};
  for (final MapEntry(key: key, value: message) in template.messages.entries) {
    final meta = template.meta(key);
    final description = meta?['description'];
    if (description is! String || description.trim().isEmpty) {
      v.add('${template.file}: "$key" has no @$key.description');
    }
    final declared = (meta?['placeholders'] as Map?)?.cast<String, Object?>();
    for (final MapEntry(key: name, value: spec) in (declared ?? {}).entries) {
      final type = (spec as Map?)?['type'];
      if (type != null && !_placeholderTypes.contains(type)) {
        v.add('${template.file}: "$key" placeholder $name has type $type');
      }
      if (type == 'DateTime' && (spec as Map)['format'] == null) {
        v.add(
          '${template.file}: "$key" DateTime placeholder $name needs a format',
        );
      }
    }
    final args = _checkMessage(template, key, message, v);
    if (args == null) continue;
    final used = {for (final a in args) a.name};
    final declaredNames = {...?declared?.keys};
    for (final name in used.difference(declaredNames)) {
      v.add('${template.file}: "$key" uses {$name} without declaring it');
    }
    for (final name in declaredNames.difference(used)) {
      v.add('${template.file}: "$key" declares {$name} but never uses it');
    }
    for (final a in args.where((a) => a.kind == 'plural')) {
      final type = ((declared?[a.name] as Map?)?['type']) ?? 'num';
      if (type != 'int' && type != 'num') {
        v.add('${template.file}: "$key" plural {${a.name}} must be int or num');
      }
    }
    templatePlaceholders[key] = used;
  }
  for (final key in template.raw.keys.where(
    (k) => k.startsWith('@') && !k.startsWith('@@'),
  )) {
    if (!template.messages.containsKey(key.substring(1))) {
      v.add('${template.file}: metadata $key has no message');
    }
  }

  // Every other catalogue: the template's keys exactly, same placeholders.
  for (final c in catalogues.where((c) => c != template)) {
    final keys = c.messages.keys.toSet();
    final expected = template.messages.keys.toSet();
    for (final k in expected.difference(keys)) {
      v.add('${c.file}: missing translation "$k"');
    }
    for (final k in keys.difference(expected)) {
      v.add('${c.file}: unsupported key "$k" (not in the template)');
    }
    for (final k in c.raw.keys.where(
      (k) => k.startsWith('@') && !k.startsWith('@@'),
    )) {
      v.add('${c.file}: metadata $k belongs in the template only');
    }
    for (final MapEntry(key: key, value: message) in c.messages.entries) {
      final args = _checkMessage(c, key, message, v);
      if (args == null || !templatePlaceholders.containsKey(key)) continue;
      final used = {for (final a in args) a.name};
      if (used.length != templatePlaceholders[key]!.length ||
          !used.containsAll(templatePlaceholders[key]!)) {
        v.add(
          '${c.file}: "$key" placeholders $used differ from the '
          'template\'s ${templatePlaceholders[key]}',
        );
      }
    }
  }
  return v;
}

List<IcuArgument>? _checkMessage(
  Catalogue c,
  String key,
  String message,
  List<String> v,
) {
  if (message.trim().isEmpty) {
    v.add('${c.file}: "$key" is empty');
    return null;
  }
  final List<IcuArgument> args;
  try {
    args = parseIcu(message);
  } on IcuSyntaxError catch (e) {
    v.add('${c.file}: "$key" malformed ICU: $e');
    return null;
  }
  for (final a in args) {
    if (a.kind == 'simple') continue;
    if (!a.cases.contains('other')) {
      v.add('${c.file}: "$key" ${a.kind} {${a.name}} has no "other" case');
    }
    if (a.kind == 'plural') {
      final allowed = pluralCategories[c.language] ?? const {'other'};
      for (final k in a.cases.where((k) => !k.startsWith('='))) {
        if (!allowed.contains(k)) {
          v.add(
            '${c.file}: "$key" plural case "$k" is not a ${c.language} '
            'plural category',
          );
        }
      }
    }
  }
  return args;
}
