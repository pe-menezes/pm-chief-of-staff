#!/bin/sh
# Audit probe of the optional-rituals front, fix round 2 (parts 1 and 2).
#
# Run: sh tests/audit/pm-cos-rituais-conserto2.sh < /dev/null
#
# Cases:
#   RC2 (risk code: the close-day second run overwrites the block's lines) a
#       second close-day run the same day, alone or in the pair with
#       start-day (today's block with the numbered 3), updates the labeled
#       lines of the block that already exists instead of adding to it: the
#       reflection is joined into the one reflection line, the balance and the
#       seed for tomorrow replace the one line of each, and no label gets a
#       second line, so the block keeps the ceiling of 1 line per label and
#       one seed for the next opening. The rule is unconditional: a condition
#       grafted onto it ("only when the person confirms it", "at the
#       person's choice", "By default", "upon request") fails the case, and
#       so does one grafted onto the day block clause of the ceiling.
#       The standalone paragraph sends its second run to the same rule.
#       Rewritten in the audit backlog front, part 2, when the rule left the
#       standalone paragraph for its own paragraph covering both modes.
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

# after TEXT NEEDLE: what follows the first NEEDLE in TEXT (empty if absent).
after() {
  awk -v t="$1" -v n="$2" 'BEGIN { i = index(t, n); if (i) print substr(t, i + length(n)) }'
}

seed_lbl=$(cell "seed for tomorrow" 3)
refl_lbl=$(cell "reflection" 3)
bal_lbl=$(cell "balance" 3)
bal_lbl=${bal_lbl%% *}
if [ -z "$seed_lbl" ] || [ -z "$refl_lbl" ] || [ -z "$bal_lbl" ]; then
  echo "FAIL  vocabulary: a person-facing cell this probe reads is missing"
  rm -rf "$work"
  exit 1
fi

# ---------------------------------------------------------------------------
# RC2 a second run the same day, alone or in the pair, updates the block's
# lines in place, never adds lines, with no condition on the rule.

# Words that make the rule conditional or turn it into a question. The rule
# paragraph, the standalone pointer to it and the day block clause of the
# ceiling carry none of them. Besides the words of a condition, the list holds
# the words of a choice, a default and a request (A1 of the audit backlog
# front, part 2: "at the person's choice", "the person decides", "By
# default", "upon request"), and the person themselves ("person", "they",
# "their"): the rule is about what the agent writes, so any mention of the
# person there makes them a gate on it.
COND='(^|[^a-z])(only|if|when|whenever|unless|except|provided|once|after|until|ask|asks|asked|confirm|confirms|confirmed|propose|proposes|may|might|can|could|should|optional|optionally|depending|approve|approves|approved|agree|agrees|agreed|choice|choose|chooses|chosen|decide|decides|decided|decision|default|defaults|request|requests|requested|upon|wish|wishes|want|wants|prefer|prefers|preference|permission|consent|consents|person|they|their)([^a-z]|$)'

rc2_bad=""
# The rule: its own paragraph, outside the standalone paragraph and the steps.
grep -v '^It also works alone' "$DAY" | grep -v -E '^ *[0-9]+\. ' \
  | grep 'second run the same day' > "$work/rule"
if [ ! -s "$work/rule" ]; then
  rc2_bad="$rc2_bad [no paragraph says what a second run the same day does in both modes]"
elif [ "$(wc -l < "$work/rule")" -ne 1 ]; then
  rc2_bad="$rc2_bad [more than one paragraph states the second run rule]"
else
  p=$(after "$(cat "$work/rule")" "second run the same day")
  # Both modes: alone and in the pair with start-day.
  printf '%s\n' "$p" | grep -q 'alone' || rc2_bad="$rc2_bad [the rule does not cover the standalone run]"
  printf '%s\n' "$p" | grep -q -F 'pair with `start-day`' || rc2_bad="$rc2_bad [the rule does not cover the pair with start-day]"
  # The second run never adds or appends to the block.
  printf '%s\n' "$p" | grep -q -i -E '(^|[^a-z])(add|adds|append|appends)([^a-z]|$)' \
    && rc2_bad="$rc2_bad [the second run adds to the block]"
  # Each label: the reflection joined in 1 line, balance and seed replaced.
  printf '%s\n' "$p" | grep -q -F -- "join the new reflection to its \`$refl_lbl\` line, kept in 1 line" \
    || rc2_bad="$rc2_bad [the new reflection is not joined to the $refl_lbl line in 1 line]"
  printf '%s\n' "$p" | grep -q -F -- "replace its \`$bal_lbl\` line with the new balance" \
    || rc2_bad="$rc2_bad [the $bal_lbl line is not replaced with the new balance]"
  printf '%s\n' "$p" | grep -q -F -- "replace its \`$seed_lbl\` line with the new seed" \
    || rc2_bad="$rc2_bad [the $seed_lbl line is not replaced with the new seed]"
  printf '%s\n' "$p" | grep -q -i 'never a second line of any label' || rc2_bad="$rc2_bad [a label may get a second line]"
  printf '%s\n' "$p" | grep -q -i 'never a second block' || rc2_bad="$rc2_bad [a second run may write a second block]"
  # R2-B1: a condition grafted onto the rule ("only when the person
  # confirms it") makes it optional; the rule is unconditional.
  w=$(printf '%s\n' "$p" | grep -o -i -E "$COND" | head -n 1)
  [ -z "$w" ] || rc2_bad="$rc2_bad [the rule carries a condition:$w]"
fi
# The standalone paragraph sends its second run to the same rule.
grep -m1 '^It also works alone' "$DAY" > "$work/alone"
if [ ! -s "$work/alone" ]; then
  rc2_bad="$rc2_bad [close-day has no standalone paragraph]"
else
  a=$(after "$(cat "$work/alone")" "second run the same day")
  a=$(printf '%s\n' "$a" | awk '{ sub(/\. .*/, "."); print }')
  if [ -z "$a" ]; then
    rc2_bad="$rc2_bad [the standalone paragraph says nothing of a second run]"
  else
    printf '%s\n' "$a" | grep -q 'second-run rule' || rc2_bad="$rc2_bad [the standalone second run does not follow the second-run rule]"
    printf '%s\n' "$a" | grep -q 'never a second block' || rc2_bad="$rc2_bad [the standalone second run may write a second block]"
    printf '%s\n' "$a" | grep -q -i -E '(^|[^a-z])(add|adds|append|appends)([^a-z]|$)' \
      && rc2_bad="$rc2_bad [the standalone second run adds to the block]"
    w=$(printf '%s\n' "$a" | grep -o -i -E "$COND" | head -n 1)
    [ -z "$w" ] || rc2_bad="$rc2_bad [the standalone second run carries a condition:$w]"
  fi
fi
# The ceiling the second run must keep is still stated for the day block.
grep '^Ceiling' "$DAY" | grep -F -- "$refl_lbl" | grep -F -- "$bal_lbl" | grep -F -- "$seed_lbl" | grep -q 'in 1 line each' \
  || rc2_bad="$rc2_bad [the day block ceiling no longer holds each label to 1 line]"
# The day block clause of the ceiling (its first sentence; the rest is about
# other destinations) passes the same guard as the rule.
c=$(grep -m1 '^Ceiling' "$DAY" | awk '{ sub(/\. .*/, "."); print }')
w=$(printf '%s\n' "$c" | grep -o -i -E "$COND" | head -n 1)
[ -z "$w" ] || rc2_bad="$rc2_bad [the day block ceiling carries a condition:$w]"
if [ -z "$rc2_bad" ]; then
  ok "RC2 a second close-day the same day, alone or in the pair, joins the reflection into its one line and replaces the balance and the seed, never a second line of a label, with no condition"
else
  fail "RC2 second close-day the same day" "$rc2_bad"
fi

rm -rf "$work"
[ "$failures" -eq 0 ]
