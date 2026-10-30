#!/bin/sh
# Language meter for the E2E runs: sh tests/e2e/lang-check.sh <file> <en|pt>
# Counts function words of each language (whole words, case-insensitive) and
# prints "<lang> ok" or "<lang> FALHA" with both counts. Exit 0 on ok, 1 on
# FALHA, 2 on a usage error. Thresholds come from the common spec:
#   en: at least 15 English words and zero Portuguese words
#   pt: at least 15 Portuguese words and at most 2 English words
# The Portuguese list is literal Portuguese on purpose: it is what is measured.

EN_WORDS='the|and|you|with|for|is'
PT_WORDS='não|você|para|uma|com|está|pessoa'

usage() {
  printf 'usage: sh tests/e2e/lang-check.sh <file> <en|pt>\n' >&2
  exit 2
}

[ "$#" -eq 2 ] || usage
file=$1
lang=$2
case "$lang" in
  en|pt) ;;
  *) usage ;;
esac
if [ ! -f "$file" ] || [ ! -r "$file" ]; then
  printf 'lang-check: cannot read %s\n' "$file" >&2
  exit 2
fi

# Whole-word matching needs a UTF-8 locale: under C, an accented letter is not
# a word character, so "for" matches inside a word that goes on with a
# c-cedilla, and an uppercase accented word does not fold to lowercase.
utf8=
for loc in C.UTF-8 C.utf8 en_US.UTF-8 en_US.utf8; do
  if locale -a 2>/dev/null | grep -q -x -F "$loc"; then
    utf8=$loc
    break
  fi
done
if [ -z "$utf8" ]; then
  printf 'lang-check: no UTF-8 locale available, cannot count words reliably\n' >&2
  exit 2
fi
LC_ALL=$utf8
export LC_ALL

# Split the text into words first, one per line (a word is a run of letters,
# digits and underscores, the same word characters as grep -w), then match
# each line whole. Matching with grep -o -w on the raw text is not used: the
# macOS grep stops counting the rest of a line after a listed word that sits
# inside a longer one ("is" inside "list").
words() {
  grep -o -E '[[:alnum:]_]+' "$file"
}

count() {
  n=$(words | grep -i -x -E "$1" | wc -l)
  printf '%s' $((n + 0))
}

en=$(count "$EN_WORDS")
pt=$(count "$PT_WORDS")

if [ "$lang" = en ]; then
  [ "$en" -ge 15 ] && [ "$pt" -eq 0 ] && verdict=ok || verdict=FALHA
else
  [ "$pt" -ge 15 ] && [ "$en" -le 2 ] && verdict=ok || verdict=FALHA
fi

printf '%s %s en=%s pt=%s\n' "$lang" "$verdict" "$en" "$pt"
[ "$verdict" = ok ]
