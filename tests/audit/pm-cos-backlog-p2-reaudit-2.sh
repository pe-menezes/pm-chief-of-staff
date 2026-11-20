#!/bin/sh
# Reaudit probe of the audit backlog front, part 2, fix round 2 (close-day
# second run writing the balance line a block with the 3 lacks). Behavior
# only, pinned by content: the seed is an instruction, so the probe checks
# what it tells the agent to do.
#
# Run: sh tests/audit/pm-cos-backlog-p2-reaudit-2.sh < /dev/null
#
# Cases:
#   RR2 (risk code: what overwrites the person's lines) the second-run rule
#       of close-day, read as a whole paragraph, never overwrites, clears or
#       rebuilds a line of the block: apart from replacing the balance line
#       with the new balance and the seed line with the new seed, no clause
#       replaces, overwrites, removes, clears or rebuilds anything, nothing
#       is written "over" or "in place of" a line, no label gets more than 1
#       line, and the sentence that writes the missing balance line names no
#       reflection line. So "right before its seed line, which it replaces",
#       "written over its reflection line", "in place of its seed line",
#       "rewriting the block from scratch", a neighbor sentence that drops
#       the reflection or clears the seed, or "in 1 line or more" fails.
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

for f in "$VOC" "$DAY"; do
  [ -f "$f" ] || { echo "FAIL  missing $f"; exit 1; }
done

# cell ROLE COLUMN: the backticked value of a row of the person-facing table
# (COLUMN 3 is en), by its role name.
cell() {
  awk -F'|' -v role="$1" -v col="$2" '
    /^## Person-facing vocabulary/ { on = 1; next }
    /^## / { on = 0 }
    on {
      r = $2; gsub(/^ +| +$/, "", r)
      if (r == role) { v = $col; sub(/^ *`/, "", v); sub(/` *$/, "", v); print v; exit }
    }' "$VOC"
}

# take_out TEXT NEEDLE: TEXT with every literal NEEDLE taken out.
take_out() {
  awk -v t="$1" -v n="$2" 'BEGIN {
    out = ""
    while ((i = index(t, n)) > 0) { out = out substr(t, 1, i - 1); t = substr(t, i + length(n)) }
    print out t
  }'
}

# ---------------------------------------------------------------------------
# RR2 the second-run rule overwrites no line of the block.

rr2_bad=""
refl_lbl=$(cell "reflection" 3)
bal_lbl=$(cell "balance" 3)
bal_lbl=${bal_lbl%% *}
seed_lbl=$(cell "seed for tomorrow" 3)
rule=$(grep -m1 '^The second-run rule' "$DAY")
if [ -z "$refl_lbl" ] || [ -z "$bal_lbl" ] || [ -z "$seed_lbl" ]; then
  rr2_bad="$rr2_bad [vocabulary: a label cell this case reads is missing]"
elif [ -z "$rule" ]; then
  rr2_bad="$rr2_bad [close-day has no second-run rule paragraph]"
else
  # The two replacements the rule makes on purpose: the balance by the new
  # balance and the seed by the new seed. Nothing else may replace anything.
  rest=$(take_out "$rule" "replace its \`$bal_lbl\` line with the new balance")
  rest=$(take_out "$rest" "replace its \`$seed_lbl\` line with the new seed")
  w=$(printf '%s\n' "$rest" | grep -o -i -E '(^|[^a-z])(replace|replaces|replaced|replacing|overwrite|overwrites|overwritten|overwriting|rewrite|rewrites|rewritten|rewriting|rebuild|rebuilds|rebuilt|rebuilding|delete|deletes|deleted|deleting|remove|removes|removed|removing|drop|drops|dropped|dropping|clear|clears|cleared|clearing|erase|erases|erased|erasing|wipe|wipes|wiped|wiping|discard|discards|discarded|strike|strikes|struck|reset|resets|empty|empties|emptied|over|instead|scratch|fresh|anew)([^a-z]|$)' | head -n 1)
  [ -z "$w" ] || rr2_bad="$rr2_bad [the rule overwrites or removes a line of the block:$w]"
  printf '%s\n' "$rest" | grep -q -i 'in place of' && rr2_bad="$rr2_bad [the rule writes a line in place of another]"
  # 1 line per label: no clause lets a label run to more lines.
  w=$(printf '%s\n' "$rule" | grep -o -i -E '(^|[^a-z])(or more|and more|more than|at least|several|multiple|two lines|[2-9] lines)([^a-z]|$)' | head -n 1)
  [ -z "$w" ] || rr2_bad="$rr2_bad [a label may run to more than 1 line:$w]"
  # The sentence of the missing balance line writes that line only: it names
  # no reflection line (the seed line is named only as its place).
  m=$(printf '%s\n' "$rule" | awk '{ gsub(/\. /, ".\n"); print }' | grep -F -- "no \`$bal_lbl\` line")
  if [ -n "$m" ]; then
    printf '%s\n' "$m" | grep -q -F -- "$refl_lbl" && rr2_bad="$rr2_bad [the sentence of the missing $bal_lbl line touches the $refl_lbl line]"
  fi
fi
if [ -z "$rr2_bad" ]; then
  ok "RR2 the close-day second-run rule replaces only the $bal_lbl and $seed_lbl lines with the new ones and overwrites, clears or rebuilds no other line, 1 line per label"
else
  fail "RR2 close-day second-run rule overwrites no line" "$rr2_bad"
fi

[ "$failures" -eq 0 ]
