import 'package:flutter_test/flutter_test.dart';
import 'package:world_clock_v2/utils/search.dart';

void main() {
  group('foldForSearch', () {
    test('drops case and diacritics', () {
      expect(foldForSearch('São Tomé'), 'sao tome');
      expect(foldForSearch('ZÜRICH'), 'zurich');
      expect(foldForSearch('Asunción'), 'asuncion');
      expect(foldForSearch('Kraków Łódź'), 'krakow lodz');
      expect(foldForSearch('Chișinău'), 'chisinau');
      expect(foldForSearch('İstanbul'), 'istanbul');
    });

    test('spells out ligatures and ß', () {
      expect(foldForSearch('Straße'), 'strasse');
      expect(foldForSearch('Œuvre Æther'), 'oeuvre aether');
    });

    test('drops combining marks of decomposed letters', () {
      expect(foldForSearch('São Tomé'), 'sao tome');
    });

    test('ignores apostrophes and soft hyphens, reads _ as space', () {
      expect(foldForSearch("N'Djamena"), 'ndjamena');
      expect(foldForSearch('N’Djaména'), 'ndjamena');
      expect(foldForSearch('Nukuʻalofa'), 'nukualofa');
      expect(foldForSearch('Reyk­ja­vík'), 'reykjavik');
      expect(foldForSearch('America/New_York'), 'america/new york');
    });

    test('keeps offsets as they are', () {
      expect(foldForSearch('-04:00 +05:30'), '-04:00 +05:30');
    });

    test('spells out umlauts the German way if asked', () {
      expect(foldForSearch('München', german: true), 'muenchen');
      expect(foldForSearch('Österreich', german: true), 'oesterreich');
      expect(foldForSearch('Zürich São', german: true), 'zuerich sao');
    });
  });

  group('matchesSearch', () {
    test('ignores case and diacritics of the text and the query', () {
      final text = searchTextOf(['São Tomé', 'Sao Tome and Principe']);
      expect(matchesSearch(text, 'sao tome'), isTrue);
      expect(matchesSearch(text, 'SÃO'), isTrue);
      expect(matchesSearch(text, 'tomé'), isTrue);
      expect(matchesSearch(text, 'lisbon'), isFalse);
    });

    test('finds umlauts typed without dots or spelled out', () {
      final text = searchTextOf(['Munich', 'München']);
      expect(matchesSearch(text, 'münchen'), isTrue);
      expect(matchesSearch(text, 'munchen'), isTrue);
      expect(matchesSearch(text, 'Muenchen'), isTrue);
      expect(matchesSearch(text, 'munich'), isTrue);
    });

    test('needs every word, in any order', () {
      final text = searchTextOf(['Port-au-Prince', 'Haiti']);
      expect(matchesSearch(text, 'port au prince'), isTrue);
      expect(matchesSearch(text, 'haiti port'), isTrue);
      expect(matchesSearch(text, 'port spain'), isFalse);
    });

    test('an empty query matches everything', () {
      expect(matchesSearch(searchTextOf(['Berlin']), '  '), isTrue);
    });
  });

  test('compareNames sorts letters with diacritics with their base', () {
    final names = ['Zypern', 'Polen', 'Österreich', 'Ägypten', 'Deutschland']
      ..sort(compareNames);
    expect(names, ['Ägypten', 'Deutschland', 'Österreich', 'Polen', 'Zypern']);
    expect(compareNames('berlin', 'Berlin'), isNot(0),
        reason: 'names that fold alike still have a fixed order');
  });
}
