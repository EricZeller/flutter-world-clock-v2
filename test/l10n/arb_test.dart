import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';

// gen-l10n falls back to English for a message a translation lacks and
// only warns about it, so a forgotten string would show up in the app.
void main() {
  final languages = {
    for (final locale in AppLocalizations.supportedLocales) locale.languageCode,
  };
  final template = _readArb('en');
  final messages = _messages(template);

  test('an ARB file exists for every supported language and vice versa', () {
    final files = {
      for (final file in Directory('lib/l10n').listSync())
        if (RegExp(r'app_(\w+)\.arb$').firstMatch(file.path) case final match?)
          match.group(1)!,
    };
    expect(files, languages);
  });

  for (final language in languages.where((language) => language != 'en')) {
    test('$language translates every message of app_en.arb', () {
      final arb = _readArb(language);
      expect(arb['@@locale'], language);
      expect(_messages(arb), messages, reason: 'the same messages, no extras');
      for (final key in messages) {
        final message = arb[key] as String;
        expect(message.trim(), isNotEmpty, reason: key);
        // Every placeholder of the template is used, also in plurals
        // ({count, plural, ...}), hence no closing brace.
        if (template['@$key'] case {'placeholders': final Map placeholders}) {
          for (final placeholder in placeholders.keys) {
            expect(message, contains('{$placeholder'), reason: key);
          }
        }
      }
    });
  }
}

Map<String, dynamic> _readArb(String language) =>
    jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _messages(Map<String, dynamic> arb) => {
  for (final key in arb.keys)
    if (!key.startsWith('@')) key,
};
