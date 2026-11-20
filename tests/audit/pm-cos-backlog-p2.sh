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
#       Since the fix round of this part, the whole step is read: no other
#       clause makes an item expire on its own, automatically or by a
#       deadline ("an item more than 7 days late expires on its own" fails).
#   BP4 (risk code: what deletes the person's lines) when start-day runs
#       again the same day, step 5 redoes the 3 in today's block and keeps,
#       as they are, the reflection, balance and seed lines already in it
#       (a close-day run alone earlier the same day writes them); it never
#       deletes them and never overwrites the whole block, with no condition.
#   BP5 (risk code: the close-day second run writes the block's lines) the
#       mixed path of one day (close-day alone, then start-day writes the 3,
#       then close-day again) leaves a block with the 3 numbered, the
#       reflection and the seed, and no balance line. The second-run rule
#       says what that run does: it writes the missing balance line once, in
#       the format of step 5, in 1 line, before the seed line, with no
#       condition, and the format of step 5 still holds the balance line.
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
  # The whole step, clause by clause (A3 of the audit of this part): the only
  # clauses that may speak of expiring are the proposal the person settles
  # and the item that never expires; any other expiry, or a second one inside
  # those two clauses, makes an item expire without the person deciding.
  awk -v mark="$expired" '
    function cut(s, n,   i) {
      while ((i = index(s, n)) > 0) s = substr(s, 1, i - 1) " " substr(s, i + length(n))
      return s
    }
    {
      s = $0
      if (index(s, "propose expiring") && index(s, "the person settles it")) {
        s = cut(s, "propose expiring"); s = cut(s, mark)
      }
      s = cut(s, "never expires")
      if (tolower(s) ~ /expir/) print
    }' "$work/scan-s" > "$work/auto"
  [ -s "$work/auto" ] && bp2_bad="$bp2_bad [a clause of step 3 expires an item without the person settling it: $(head -n 1 "$work/auto")]"
  # Nor does any wording of an expiry on its own, automatic or by a time
  # span, or a removal of the item under another verb.
  w=$(grep -o -i -E '(on its own|by itself|automatic[a-z]*|without (asking|the person)|(^|[^a-z])(a|an|one|two|three|[0-9]+) (days?|weeks?|months?)([^a-z]|$)|deadline|lapses?|(dropped|removed|deleted|discarded|archived|purged)([^a-z]|$))' "$work/scan" | head -n 1)
  [ -z "$w" ] || bp2_bad="$bp2_bad [step 3 lets an item expire on its own:$w]"
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

# ---------------------------------------------------------------------------
# BP4 start-day run again the same day keeps the close-day lines of the block.

# The condition words of BP1, plus those of a choice, a default and a request
# and the person themselves (the same widening as RC2 in the fix round of
# this part, without "they", which the kept lines' "as they are" carries).
COND4='(^|[^a-z])(only|if|when|whenever|unless|except|provided|once|after|until|ask|asks|asked|confirm|confirms|confirmed|propose|proposes|may|might|can|could|should|optional|optionally|depending|approve|approves|approved|agree|agrees|agreed|choice|choose|chooses|chosen|decide|decides|decided|decision|default|defaults|request|requests|requested|upon|wish|wishes|want|wants|prefer|prefers|preference|permission|consent|consents|person)([^a-z]|$)'

bp4_bad=""
refl_lbl=$(cell "reflection" 3)
bal_lbl=$(cell "balance" 3)
bal_lbl=${bal_lbl%% *}
seed_lbl=$(cell "seed for tomorrow" 3)
if [ -z "$refl_lbl" ] || [ -z "$bal_lbl" ] || [ -z "$seed_lbl" ]; then
  bp4_bad="$bp4_bad [vocabulary: a label cell this case reads is missing]"
else
  step 5 "$START" > "$work/rec"
  if [ ! -s "$work/rec" ]; then
    bp4_bad="$bp4_bad [start-day has no step 5]"
  else
    r=$(after "$(cat "$work/rec")" "Same day runs again")
    # The same-day clause: up to the new-day one.
    r=$(printf '%s\n' "$r" | awk '{ i = index($0, "New day"); if (i) $0 = substr($0, 1, i - 1); print }')
    if [ -z "$r" ]; then
      bp4_bad="$bp4_bad [step 5 says nothing of a run again the same day]"
    else
      printf '%s\n' "$r" | grep -q 'the 3' || bp4_bad="$bp4_bad [the run again does not redo the 3]"
      for l in "$refl_lbl" "$bal_lbl" "$seed_lbl"; do
        printf '%s\n' "$r" | grep -q -F -- "\`$l\`" || bp4_bad="$bp4_bad [the $l line is not kept]"
      done
      printf '%s\n' "$r" | grep -q -E '(^|[^a-z])keeps?([^a-z]|$)' || bp4_bad="$bp4_bad [the labeled lines are not kept]"
      printf '%s\n' "$r" | grep -q 'as they are' || bp4_bad="$bp4_bad [the kept lines may change]"
      printf '%s\n' "$r" | grep -q -i 'never delete' || bp4_bad="$bp4_bad [the labeled lines may be deleted]"
      w=$(printf '%s\n' "$r" | grep -o -i -E '(overwrit|replac|rewrit|delet|remov|clear|eras)[a-z]* (the|today.s) (whole |entire )?block' | head -n 1)
      [ -z "$w" ] || bp4_bad="$bp4_bad [the run again wipes the block:$w]"
      w=$(printf '%s\n' "$r" | grep -o -i -E "$COND4" | head -n 1)
      [ -z "$w" ] || bp4_bad="$bp4_bad [keeping the lines carries a condition:$w]"
    fi
  fi
fi
if [ -z "$bp4_bad" ]; then
  ok "BP4 start-day run again the same day redoes the 3 and keeps the $refl_lbl, $bal_lbl and $seed_lbl lines already in the block as they are, never deleting them"
else
  fail "BP4 start-day run again the same day" "$bp4_bad"
fi

# ---------------------------------------------------------------------------
# BP5 the second-run rule writes the balance line a block with the 3 lacks.

bp5_bad=""
if [ -z "$refl_lbl" ] || [ -z "$bal_lbl" ] || [ -z "$seed_lbl" ]; then
  bp5_bad="$bp5_bad [vocabulary: a label cell this case reads is missing]"
else
  grep -m1 '^The second-run rule' "$DAY" > "$work/rule5"
  if [ ! -s "$work/rule5" ]; then
    bp5_bad="$bp5_bad [close-day has no second-run rule paragraph]"
  else
    # The rule, sentence by sentence; the sentence of the block with no
    # balance line is the one naming that line as missing.
    awk '{ gsub(/\. /, ".\n"); print }' "$work/rule5" | grep -F -- "no \`$bal_lbl\` line" > "$work/mix"
    if [ ! -s "$work/mix" ]; then
      bp5_bad="$bp5_bad [the rule says nothing of a block with no $bal_lbl line]"
    elif [ "$(wc -l < "$work/mix")" -ne 1 ]; then
      bp5_bad="$bp5_bad [more than one sentence of the rule speaks of the missing $bal_lbl line]"
    else
      m=$(cat "$work/mix")
      # The block of the mixed path: it holds the 3 numbered.
      printf '%s\n' "$m" | grep -q 'with the 3 numbered' || bp5_bad="$bp5_bad [the missing $bal_lbl line is not tied to a block with the 3]"
      # The line is written, in the format of step 5, in 1 line.
      printf '%s\n' "$m" | grep -q -E '(^|[^a-z])(write|writes|written)([^a-z]|$)' \
        || bp5_bad="$bp5_bad [the missing $bal_lbl line is not written]"
      printf '%s\n' "$m" | grep -q 'format of step 5' || bp5_bad="$bp5_bad [the $bal_lbl line does not follow the format of step 5]"
      printf '%s\n' "$m" | grep -q 'in 1 line' || bp5_bad="$bp5_bad [the $bal_lbl line is not held to 1 line]"
      # Its place: before the seed line, never at the end of the block.
      b=$(after "$m" "before")
      printf '%s\n' "$b" | grep -q -F -- "\`$seed_lbl\` line" \
        || bp5_bad="$bp5_bad [the $bal_lbl line is not placed before the $seed_lbl line]"
      printf '%s\n' "$m" | grep -q -i -E 'end of (the|today.s) block|at the end' \
        && bp5_bad="$bp5_bad [the $bal_lbl line goes at the end of the block]"
      printf '%s\n' "$m" | grep -q -i -E '(^|[^a-z])(add|adds|append|appends)([^a-z]|$)' \
        && bp5_bad="$bp5_bad [the $bal_lbl line is appended]"
      w=$(printf '%s\n' "$m" | grep -o -i -E "$COND4" | head -n 1)
      [ -z "$w" ] || bp5_bad="$bp5_bad [writing the missing $bal_lbl line carries a condition:$w]"
    fi
    # The rule still forbids a second line of any label and a second block.
    grep -q -i 'never a second line of any label' "$work/rule5" || bp5_bad="$bp5_bad [a label may get a second line]"
    grep -q -i 'never a second block' "$work/rule5" || bp5_bad="$bp5_bad [a second run may write a second block]"
  fi
  # The format the rule points at still holds the balance line.
  awk '/^## Flow/ { on = 1; next } /^## / { on = 0 } on' "$DAY" | grep -q -F -- "$bal_lbl {N}/3" \
    || bp5_bad="$bp5_bad [the format of step 5 has no $bal_lbl line]"
fi
if [ -z "$bp5_bad" ]; then
  ok "BP5 a second close-day over a block with the 3 and no $bal_lbl line writes that line once, in the format of step 5, in 1 line, before the $seed_lbl line"
else
  fail "BP5 close-day second run over a block with no $bal_lbl line" "$bp5_bad"
fi

[ "$failures" -eq 0 ]
