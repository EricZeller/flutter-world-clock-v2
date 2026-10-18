// Search and sorting that ignore case and diacritics, shared by all search
// fields of the app. Pure Dart, so tool/generate_place_names.dart can use it
// too.

/// Latin letters with diacritics and the letters they are found by.
const _foldings = {
  'a': 'àáâãäåāăą',
  'c': 'çćĉċč',
  'd': 'ďđð',
  'e': 'èéêëēĕėęě',
  'g': 'ĝğġģ',
  'h': 'ĥħ',
  'i': 'ìíîïĩīĭįı',
  'j': 'ĵ',
  'k': 'ķ',
  'l': 'ĺļľŀł',
  'n': 'ñńņňŉ',
  'o': 'òóôõöøōŏő',
  'r': 'ŕŗř',
  's': 'śŝşšș',
  't': 'ţťŧț',
  'u': 'ùúûüũūŭůűų',
  'w': 'ŵ',
  'y': 'ýÿŷ',
  'z': 'źżž',
  'ae': 'æ',
  'oe': 'œ',
  'ss': 'ß',
  'th': 'þ',
  // `America/New_York` is found as `new york`; `N'Djamena` as `ndjamena`.
  ' ': '_',
  '': '\'’ʻ­',
};

final _folding = {
  for (final MapEntry(key: base, value: letters) in _foldings.entries)
    for (final letter in letters.split('')) letter: base,
};

/// German umlauts as they are written without them: `Muenchen`.
const _germanFolding = {'ä': 'ae', 'ö': 'oe', 'ü': 'ue'};

/// [text] in lower case without diacritics, as it is searched and sorted:
/// `São Tomé` becomes `sao tome`, `Zürich` `zurich`. With [german], umlauts
/// are spelled out instead: `zuerich`.
String foldForSearch(String text, {bool german = false}) {
  final buffer = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    // Combining marks, such as those of decomposed letters.
    if (rune >= 0x300 && rune <= 0x36f) continue;
    final letter = String.fromCharCode(rune);
    buffer.write(
      (german ? _germanFolding[letter] : null) ?? _folding[letter] ?? letter,
    );
  }
  return buffer.toString();
}

/// Everything in [parts] in the form [matchesSearch] expects. Words with
/// umlauts are added a second time spelled out, so `Muenchen` finds
/// `München` just like `Munchen` and `münchen` do.
String searchTextOf(Iterable<String> parts) {
  final text = parts.where((part) => part.isNotEmpty).join(' ');
  final folded = foldForSearch(text);
  final german = foldForSearch(text, german: true);
  return german == folded ? folded : '$folded $german';
}

/// Whether [searchText] of [searchTextOf] contains every word of [query],
/// ignoring case and diacritics. An empty query matches everything.
bool matchesSearch(String searchText, String query) => foldForSearch(query)
    .split(' ')
    .where((word) => word.isNotEmpty)
    .every(searchText.contains);

/// Orders names alphabetically, ignoring case and diacritics, so that
/// `Österreich` comes before `Polen` rather than after `Zypern`.
int compareNames(String a, String b) {
  final result = foldForSearch(a).compareTo(foldForSearch(b));
  return result != 0 ? result : a.compareTo(b);
}
