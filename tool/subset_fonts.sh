#!/usr/bin/env sh
# Subsets Pacifico, the accent font of the app, to the Latin script and
# writes it to the two places it is bundled from: the Flutter assets and
# the Android resources of the home screen widget. The original font is in
# tool/data/fonts; it also covers Cyrillic, Greek and Vietnamese, which the
# app never shows in Pacifico: its UI languages and the bundled city names
# are Latin, and a custom city in another script falls back to the system
# font. Hinting instructions are dropped too, Flutter does not use them.
# The subset is a third of the original, which the arm64 APK (limited to
# 10 MiB by CI) contains twice.
#
# Needs fonttools: pip install fonttools
#
#   sh tool/subset_fonts.sh
#
# Red Hat Display is left as it is: it only covers Latin already.
set -eu
cd "$(dirname "$0")/.."

# Basic Latin to Latin Extended-B, modifier letters (ʻ), combining marks,
# Latin Extended Additional (Vietnamese), general punctuation (’ …), € and ™.
unicodes='U+0000-024F,U+02BB-02BC,U+0300-036F,U+1E00-1EFF,U+2000-206F,U+20AC,U+2122'

for output in fonts/Pacifico/Pacifico-Regular.ttf \
    android/app/src/main/res/font/pacifico.ttf; do
  pyftsubset tool/data/fonts/Pacifico-Regular.ttf \
    --unicodes="$unicodes" --layout-features='*' --no-hinting \
    --output-file="$output"
  echo "Wrote $output ($(wc -c < "$output" | tr -d ' ') bytes)"
done
