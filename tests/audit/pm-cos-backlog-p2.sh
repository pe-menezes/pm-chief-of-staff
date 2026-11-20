#!/bin/sh
# Audit probe of the audit backlog front, part 2 (the rituals' leftovers and
# the Codex discovery in the pastable prompt). Behavior only, pinned by
# content: the seeds and the PROMPTs are instructions, so the probe checks
# what they tell the agent to do.
#
# Run: sh tests/audit/pm-cos-backlog-p2.sh < /dev/null
#
# Cases:
#   BP1 (risk code: the close-day second run overwrites the block's lines)
#       steps 3 and 5 of close-day, the ones that write the reflection, the
#       balance and the seed, send a second run the same day to the
#       second-run rule, with no condition, so neither step read to the
#       letter adds a second line of a label in the pair with start-day.
#   BP2 the backlog scan of start-day (step 3) sets apart a dated
#       prospective item whose date has passed: it proposes expiring it with
#       the folder's expired mark or re-anchoring it with a new date, the
#       person settles it, and an item with no written date never expires.
#   BP3 (risk code: what writes through a link) the discovery rule of
#       PROMPT.md and PROMPT.pt-BR.md checks .agents itself before any
#       write: as a link (even a broken one) or as a file, nothing is written
#       in it or through it and the conflict goes to the person; then
#       .agents/skills, in the order of modules/codex-bridge.sh, all before
#       the first creation step (a).
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

# An exported CDPATH makes cd print the folder inside $(...), which would
# double every path built from ROOT.
unset CDPATH
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
VOC="$ROOT/modules/vocabulary.md"
DAY="$ROOT/seeds/close-day/SKILL.md"
START="$ROOT/seeds/start-day/SKILL.md"
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi
trap 'rm -rf "$work"' EXIT

for f in "$VOC" "$DAY" "$START" "$ROOT/PROMPT.md" "$ROOT/PROMPT.pt-BR.md"; do
  [ -f "$f" ] || { echo "FAIL  missing $f"; exit 1; }
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

# before TEXT NEEDLE: what comes before the first NEEDLE in TEXT (empty if
# NEEDLE is absent).
before() {
  awk -v t="$1" -v n="$2" 'BEGIN { i = index(t, n); if (i) print substr(t, 1, i - 1) }'
}

# step N FILE: the line of step N of the "## Flow" section of FILE.
step() {
  awk -v n="$1" '
    /^## Flow/ { on = 1; next }
    /^## / { on = 0 }
    on && index($0, n ". ") == 1 { print; exit }' "$2"
}

# pos TEXT NEEDLE: the position of the first NEEDLE in TEXT, 0 if absent.
pos() {
  awk -v t="$1" -v n="$2" 'BEGIN { print index(t, n) }'
}

# Words that make a rule conditional or turn it into a question.
COND='(^|[^a-z])(only|if|when|whenever|unless|except|provided|once|after|until|ask|asks|asked|confirm|confirms|confirmed|propose|proposes|may|might|can|could|should|optional|optionally|depending|approve|approves|approved|agree|agrees)([^a-z]|$)'

expired=$(cell "expired mark" 3)
if [ -z "$expired" ]; then
  echo "FAIL  vocabulary: a person-facing cell this probe reads is missing"
  exit 1
fi

# ---------------------------------------------------------------------------
# BP1 close-day steps 3 and 5 send a second run to the second-run rule.

bp1_bad=""
for n in 3 5; do
  step "$n" "$DAY" > "$work/step"
  if [ ! -s "$work/step" ]; then
    bp1_bad="$bp1_bad [close-day has no step $n]"
    continue
  fi
  s=$(after "$(cat "$work/step")" "second run the same day")
  if [ -z "$s" ]; then
    bp1_bad="$bp1_bad [step $n says nothing of a second run the same day]"
    continue
  fi
  # The pointer: the clause from the second run to the closing parenthesis.
  c=$(printf '%s\n' "$s" | awk '{ sub(/\).*/, ""); print }')
  printf '%s\n' "$c" | grep -q 'second-run rule' || bp1_bad="$bp1_bad [step $n does not follow the second-run rule]"
  printf '%s\n' "$c" | grep -q -i -E '(^|[^a-z])(add|adds|append|appends)([^a-z]|$)' \
    && bp1_bad="$bp1_bad [step $n adds on a second run]"
  w=$(printf '%s\n' "$c" | grep -o -i -E "$COND" | head -n 1)
  [ -z "$w" ] || bp1_bad="$bp1_bad [step $n sends to the rule with a condition:$w]"
done
if [ -z "$bp1_bad" ]; then
  ok "BP1 close-day steps 3 and 5 send a second run the same day to the second-run rule, with no condition"
else
  fail "BP1 close-day steps 3 and 5 on a second run" "$bp1_bad"
fi

# ---------------------------------------------------------------------------
# BP2 start-day step 3 proposes expiring or re-anchoring a lapsed item.

bp2_bad=""
step 3 "$START" > "$work/scan"
if [ ! -s "$work/scan" ]; then
  bp2_bad="$bp2_bad [start-day has no step 3]"
else
  awk '{ gsub(/\. /, ".\n"); gsub(/; /, ";\n"); print }' "$work/scan" > "$work/scan-s"
  grep -i 'prospective' "$work/scan-s" > "$work/pro"
  if [ ! -s "$work/pro" ]; then
    bp2_bad="$bp2_bad [step 3 does not set apart a dated prospective item]"
  else
    grep -q -E 'dated|with a date' "$work/pro" || bp2_bad="$bp2_bad [the prospective item is not the dated one]"
    grep -q -E 'date (has )?passed' "$work/pro" || bp2_bad="$bp2_bad [the rule is not for a date that passed]"
    grep -q -F -- "$expired" "$work/pro" || bp2_bad="$bp2_bad [no $expired mark]"
    grep -q -E 'expir[a-z]* .* or re-anchor[a-z]* it with a new date' "$work/pro" \
      || bp2_bad="$bp2_bad [expiring and re-anchoring with a new date are not the two options]"
    grep -q 'the person settles it' "$work/pro" || bp2_bad="$bp2_bad [the person does not settle it]"
  fi
  grep -q 'no written date never expires' "$work/scan-s" || bp2_bad="$bp2_bad [an item with no written date may expire]"
fi
if [ -z "$bp2_bad" ]; then
  ok "BP2 start-day step 3 proposes expiring ($expired) or re-anchoring a lapsed dated prospective item, the person settles it, and no written date never expires"
else
  fail "BP2 start-day lapsed prospective item" "$bp2_bad"
fi

# ---------------------------------------------------------------------------
# BP3 the PROMPTs check .agents, then .agents/skills, before any write.

bp3_bad=""
for spec in "PROMPT.md en" "PROMPT.pt-BR.md pt"; do
  src=${spec% *}
  lang=${spec#* }
  if [ "$lang" = en ]; then
    first='Before any write'
    top='.agents already exists as a link (even a broken one) or as a file'
    none='write nothing in it or through it'
    sub='.agents/skills already exists as a link'
    confl='conflict'
  else
    first='Antes de qualquer escrita'
    top='.agents já existe como link (mesmo quebrado) ou como arquivo'
    none='não escreva nada nele nem através dele'
    sub='.agents/skills já existe como link'
    confl='conflito'
  fi
  grep -m1 -F '(a)' "$ROOT/$src" | grep -F '.agents/skills' > "$work/disc"
  if [ ! -s "$work/disc" ]; then
    bp3_bad="$bp3_bad [$src: no discovery rule with step (a)]"
    continue
  fi
  pre=$(before "$(cat "$work/disc")" "(a)")
  pf=$(pos "$pre" "$first")
  pt=$(pos "$pre" "$top")
  pn=$(pos "$pre" "$none")
  ps=$(pos "$pre" "$sub")
  [ "$pf" -gt 0 ] || bp3_bad="$bp3_bad [$src: the checks do not come before any write]"
  [ "$pt" -gt 0 ] || bp3_bad="$bp3_bad [$src: .agents as a link, even broken, or a file is not checked before (a)]"
  [ "$pn" -gt 0 ] || bp3_bad="$bp3_bad [$src: something may be written in or through .agents]"
  [ "$ps" -gt 0 ] || bp3_bad="$bp3_bad [$src: .agents/skills as a link is not checked before (a)]"
  printf '%s\n' "$pre" | grep -q -i -F -- "$confl" || bp3_bad="$bp3_bad [$src: the conflict does not go to the person]"
  # The bridge's order: .agents first, then .agents/skills.
  if [ "$pf" -gt 0 ] && [ "$pt" -gt 0 ] && [ "$ps" -gt 0 ]; then
    { [ "$pf" -lt "$pt" ] && [ "$pt" -lt "$ps" ]; } || bp3_bad="$bp3_bad [$src: the checks are not in the bridge's order]"
  fi
done
if [ -z "$bp3_bad" ]; then
  ok "BP3 both PROMPTs check .agents (link, even broken, or file) and then .agents/skills before any write, nothing through them, conflict to the person"
else
  fail "BP3 .agents before the discovery writes" "$bp3_bad"
fi

[ "$failures" -eq 0 ]
