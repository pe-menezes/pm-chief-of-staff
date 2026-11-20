#!/bin/sh
# Reaudit probe of the audit backlog front, part 2, fix round 1 (step 5 of
# start-day run again the same day). Behavior only, pinned by content: the
# seed is an instruction, so the probe checks what it tells the agent to do.
#
# Run: sh tests/audit/pm-cos-backlog-p2-reaudit-1.sh < /dev/null
#
# Cases:
#   RR1 (risk code: what deletes the person's lines) step 5 of start-day,
#       read whole and not only its same-day clause, keeps the reflection,
#       balance and seed lines a close-day already wrote in today's block:
#       the three labels sit together in the object of the keep, no label is
#       named anywhere else in the step, no sentence of the step removes,
#       replaces, clears or rebuilds the block or its lines (apart from
#       redoing the 3 and "never delete them"), and the keep carries no
#       condition. So "the Balance line going away since the 3 changed",
#       "replace them with a fresh line each", a block "written from scratch"
#       before the same-day clause or a "clear the block" after the new-day
#       one fails.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

# An exported CDPATH makes cd print the folder inside $(...), which would
# double every path built from ROOT.
unset CDPATH
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
VOC="$ROOT/modules/vocabulary.md"
START="$ROOT/seeds/start-day/SKILL.md"
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

for f in "$VOC" "$START"; do
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

# step N FILE: the line of step N of the "## Flow" section of FILE.
step() {
  awk -v n="$1" '
    /^## Flow/ { on = 1; next }
    /^## / { on = 0 }
    on && index($0, n ". ") == 1 { print; exit }' "$2"
}

# ---------------------------------------------------------------------------
# RR1 start-day step 5 keeps the close-day lines, read as a whole step.

rr1_bad=""
refl_lbl=$(cell "reflection" 3)
bal_lbl=$(cell "balance" 3)
bal_lbl=${bal_lbl%% *}
seed_lbl=$(cell "seed for tomorrow" 3)
s5=$(step 5 "$START")
if [ -z "$refl_lbl" ] || [ -z "$bal_lbl" ] || [ -z "$seed_lbl" ]; then
  rr1_bad="$rr1_bad [vocabulary: a label cell this case reads is missing]"
elif [ -z "$s5" ]; then
  rr1_bad="$rr1_bad [start-day has no step 5]"
else
  # The object of the keep: from the first "keep" of the step to the first
  # "lines" after it. All three labels sit there, together.
  obj=$(printf '%s\n' "$s5" | awk '{
    i = match($0, /(^|[^a-z])keeps?[^a-z]/)
    if (!i) exit
    t = substr($0, i)
    j = index(t, "lines")
    if (j) print substr(t, 1, j + 4)
  }')
  if [ -z "$obj" ]; then
    rr1_bad="$rr1_bad [step 5 keeps no lines]"
  else
    for l in "$refl_lbl" "$bal_lbl" "$seed_lbl"; do
      printf '%s\n' "$obj" | grep -q -F -- "\`$l\`" || rr1_bad="$rr1_bad [the $l line is not among the kept lines]"
    done
    # Outside the kept list, the step names no label: a label named
    # elsewhere is a label the step does something else with.
    rest=$(printf '%s\n' "$s5" | awk -v o="$obj" '{ i = index($0, o); if (i) $0 = substr($0, 1, i - 1) " " substr($0, i + length(o)); print }')
    for l in "$refl_lbl" "$bal_lbl" "$seed_lbl"; do
      printf '%s\n' "$rest" | grep -q -F -- "$l" && rr1_bad="$rr1_bad [the step names the $l line outside the kept lines]"
    done
    # The keep carries no condition: the same-day clause, from the keep to
    # the new-day clause, holds none of these words (BP4 reads its own list
    # over the same clause; these are wordings it misses).
    k=$(printf '%s\n' "$s5" | awk '{
      i = match($0, /(^|[^a-z])keeps?[^a-z]/)
      if (!i) exit
      t = substr($0, i)
      j = index(t, "New day")
      if (j) t = substr(t, 1, j - 1)
      print t
    }')
    w=$(printf '%s\n' "$k" | grep -o -i -E '(^|[^a-z])(only|if|when|unless|except|where|wherever|relevant|needed|necessary|usually|normally|generally|typically|possible|appropriate|sometimes|often|default|choice|decide[sd]?|request(ed)?|upon|person)([^a-z]|$)' | head -n 1)
    [ -z "$w" ] || rr1_bad="$rr1_bad [keeping the lines carries a condition:$w]"
  fi
  # No sentence of the step removes, replaces, clears or rebuilds the block
  # or its lines; "never delete them" is the one allowed mention.
  n=$(printf '%s\n' "$s5" | awk '{ gsub(/never delete them/, " "); print }')
  w=$(printf '%s\n' "$n" | grep -o -i -E '(delet|remov|drop|clear|eras|wip|replac|overwrit|rewrit|discard|purg|scratch|away|fresh|anew|rebuild|recreat|regenerat|reset)[a-z]*' | head -n 1)
  [ -z "$w" ] || rr1_bad="$rr1_bad [step 5 removes or rebuilds what the block holds:$w]"
fi
if [ -z "$rr1_bad" ]; then
  ok "RR1 start-day step 5, read whole, keeps the $refl_lbl, $bal_lbl and $seed_lbl lines of today's block together and unconditionally, and no sentence of it removes, replaces or rebuilds them"
else
  fail "RR1 start-day step 5 keeps the close-day lines" "$rr1_bad"
fi

[ "$failures" -eq 0 ]
