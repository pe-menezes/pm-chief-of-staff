#!/bin/sh
# Audit probe of the optional-rituals front, fix round 2 (parts 1 and 2).
#
# Run: sh tests/audit/pm-cos-rituais-conserto2.sh < /dev/null
#
# Cases:
#   RC2 (risk code: the standalone close-day second run) a second close-day
#       run the same day updates the labeled lines of the block that already
#       exists instead of adding to it: the reflection is joined into the one
#       reflection line, the seed for tomorrow replaces the one seed line, and
#       no label gets a second line, so the block keeps the ceiling of 1 line
#       per label and one seed for the next opening.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

# An exported CDPATH makes cd print the folder inside $(...), which would
# double every path built from ROOT.
unset CDPATH
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
VOC="$ROOT/modules/vocabulary.md"
DAY="$ROOT/seeds/close-day/SKILL.md"
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi

for f in "$VOC" "$DAY"; do
  [ -f "$f" ] || { echo "FAIL  missing $f"; rm -rf "$work"; exit 1; }
done

# cell ROLE COLUMN: the backticked value of a row of the person-facing table
# (COLUMN 3 is en, 4 is pt-BR), by its role name.
cell() {
  awk -F'|' -v role="$1" -v col="$2" '
    /^## Person-facing vocabulary/ { on = 1; next }
    /^## / { on = 0 }
    on {
      r = $2; gsub(/^ +| +$/, "", r)
      if (r == role) { v = $col; sub(/^ *`/, "", v); sub(/` *$/, "", v); print v; exit }
    }' "$VOC"
}

# sentences FILE: the text of FILE, one sentence per line.
sentences() {
  awk '{ gsub(/\. /, ".\n"); print }' "$1"
}

# after TEXT NEEDLE: what follows the first NEEDLE in TEXT (empty if absent).
after() {
  awk -v t="$1" -v n="$2" 'BEGIN { i = index(t, n); if (i) print substr(t, i + length(n)) }'
}

seed_lbl=$(cell "seed for tomorrow" 3)
refl_lbl=$(cell "reflection" 3)
if [ -z "$seed_lbl" ] || [ -z "$refl_lbl" ]; then
  echo "FAIL  vocabulary: a person-facing cell this probe reads is missing"
  rm -rf "$work"
  exit 1
fi

# ---------------------------------------------------------------------------
# RC2 a second standalone run updates the block's lines, never adds lines.

grep -m1 '^It also works alone' "$DAY" > "$work/alone"
rc2_bad=""
if [ ! -s "$work/alone" ]; then
  rc2_bad="$rc2_bad [close-day has no standalone paragraph]"
else
  sentences "$work/alone" | grep 'second run the same day' > "$work/second"
  if [ ! -s "$work/second" ]; then
    rc2_bad="$rc2_bad [nothing says what a second run the same day does]"
  else
    # Only the clause of the second run: the sentence opens by naming both
    # labels for the first run.
    s=$(after "$(cat "$work/second")" "second run the same day")
    # The second run never adds or appends to the block: adding a second
    # reflection and a second seed breaks the 1 line per label ceiling.
    printf '%s\n' "$s" | grep -q -i -E '(^|[^a-z])(add|adds|append|appends)([^a-z]|$)' \
      && rc2_bad="$rc2_bad [the second run adds to the block]"
    # The reflection is joined into the reflection line already there, in 1 line.
    r=$(after "$s" "$refl_lbl")
    if [ -z "$r" ]; then
      rc2_bad="$rc2_bad [the second run does not name the $refl_lbl line]"
    else
      printf '%s\n' "$r" | grep -q -E '^`? line' || rc2_bad="$rc2_bad [the second run does not update the existing $refl_lbl line]"
      printf '%s\n' "$s" | grep -q -E "join[a-z]* the new reflection" || rc2_bad="$rc2_bad [the new reflection is not joined to what is there]"
      printf '%s\n' "$r" | grep -q '1 line' || rc2_bad="$rc2_bad [the joined $refl_lbl line is not kept to 1 line]"
    fi
    # The seed for tomorrow is replaced by the new one, so one seed is left.
    p=$(after "$s" "replace")
    if [ -z "$p" ]; then
      rc2_bad="$rc2_bad [the second run does not replace the seed]"
    else
      q=$(after "$p" "$seed_lbl")
      [ -n "$q" ] || rc2_bad="$rc2_bad [what is replaced is not the $seed_lbl line]"
      printf '%s\n' "$q" | grep -q 'with the new seed' || rc2_bad="$rc2_bad [the $seed_lbl line is not replaced with the new seed]"
    fi
    printf '%s\n' "$s" | grep -q 'never a second line of either label' || rc2_bad="$rc2_bad [a label may get a second line]"
    printf '%s\n' "$s" | grep -q 'never a second block' || rc2_bad="$rc2_bad [a second run may write a second block]"
  fi
fi
# The ceiling the second run must keep is still stated for the day block.
grep '^Ceiling' "$DAY" | grep -F -- "$refl_lbl" | grep -F -- "$seed_lbl" | grep -q 'in 1 line each' \
  || rc2_bad="$rc2_bad [the day block ceiling no longer holds each label to 1 line]"
if [ -z "$rc2_bad" ]; then
  ok "RC2 a second close-day alone the same day joins the reflection into its one line and replaces the seed, never a second line of a label"
else
  fail "RC2 second standalone close-day" "$rc2_bad"
fi

rm -rf "$work"
[ "$failures" -eq 0 ]
