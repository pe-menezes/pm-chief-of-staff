#!/bin/sh
# Probes from the audit of the audit backlog front, part 2. Behavior only,
# pinned by content: the seeds and the PROMPTs are instructions, so the
# probes check what they tell the agent to do.
#
# Run: sh tests/audit/pm-cos-backlog-p2-audit.sh < /dev/null
#
# Cases:
#   AP1 (risk code: the close-day lines the person reads in the morning) the
#       first close-day run of the day still writes the three labeled lines:
#       step 3 makes a relevant account a reflection line in the day block,
#       step 5 writes the balance and the seed at the end of the day block
#       with both labels in its format, and every "in place" / "line already
#       there" / "never a new line" instruction is scoped, on its own line,
#       after "second run the same day", so the second-run rule never reaches
#       the first run.
#   AP2 (risk code: date boundary) every line that replaces the pains review
#       line after a done review (setup twice, both PROMPTs, close-day step 7,
#       close-week step 5) updates the pains file's review dates before it
#       replaces the line, so "the nearest of the pains file's review dates"
#       is read after the next review was written, not the date just done.
#   AP3 (risk code: what deletes data, and the person's decision) start-day
#       step 3 proposes the expiry of a lapsed dated prospective item before
#       anything is written, and an expired line stays where it is, with the
#       mark: nothing is deleted, removed, dropped or moved.
#   AP4 (risk code: what writes through a link) the discovery rule of both
#       PROMPTs accepts as "already in place" only the .agents/skills link
#       target that modules/codex-bridge.sh accepts, read from the bridge
#       (differential oracle), and shows the .agents conflict to the person.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

# An exported CDPATH makes cd print the folder inside $(...), which would
# double every path built from ROOT.
unset CDPATH
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
VOC="$ROOT/modules/vocabulary.md"
DAY="$ROOT/seeds/close-day/SKILL.md"
WEEK="$ROOT/seeds/close-week/SKILL.md"
START="$ROOT/seeds/start-day/SKILL.md"
SETUP="$ROOT/skills/setup/SKILL.md"
BRIDGE="$ROOT/modules/codex-bridge.sh"
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi
trap 'rm -rf "$work"' EXIT

for f in "$VOC" "$DAY" "$WEEK" "$START" "$SETUP" "$BRIDGE" "$ROOT/PROMPT.md" "$ROOT/PROMPT.pt-BR.md"; do
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

# before TEXT NEEDLE: what comes before the first NEEDLE in TEXT (empty if
# NEEDLE is absent).
before() {
  awk -v t="$1" -v n="$2" 'BEGIN { i = index(t, n); if (i) print substr(t, 1, i - 1) }'
}

# pos TEXT NEEDLE: the position of the first NEEDLE in TEXT, 0 if absent.
pos() {
  awk -v t="$1" -v n="$2" 'BEGIN { print index(t, n) }'
}

# step N FILE: the line of step N of the "## Flow" section of FILE.
step() {
  awk -v n="$1" '
    /^## Flow/ { on = 1; next }
    /^## / { on = 0 }
    on && index($0, n ". ") == 1 { print; exit }' "$2"
}

# rpos TEXT ERE: the position of the first match of ERE in TEXT, lowercased,
# 0 if none.
rpos() {
  awk -v t="$1" -v re="$2" 'BEGIN { t = tolower(t); print (match(t, re) ? RSTART : 0) }'
}

seed_lbl=$(cell "seed for tomorrow" 3)
refl_lbl=$(cell "reflection" 3)
bal_lbl=$(cell "balance" 3)
bal_lbl=${bal_lbl%% *}
expired=$(cell "expired mark" 3)
if [ -z "$seed_lbl" ] || [ -z "$refl_lbl" ] || [ -z "$bal_lbl" ] || [ -z "$expired" ]; then
  echo "FAIL  vocabulary: a person-facing cell this probe reads is missing"
  exit 1
fi
SECOND='second run the same day'

# ---------------------------------------------------------------------------
# AP1 the first close-day run still writes the three labeled lines.

ap1_bad=""
s3=$(step 3 "$DAY")
s5=$(step 5 "$DAY")
if [ -z "$s3" ] || [ -z "$s5" ]; then
  ap1_bad="$ap1_bad [close-day has no step 3 or no step 5]"
else
  # What a run writes before any second-run clause: the first run's part.
  h3=$(before "$s3" "$SECOND")
  [ -n "$h3" ] || h3=$s3
  printf '%s\n' "$h3" | grep -q -F -- "becomes a \`$refl_lbl\` line in the day block" \
    || ap1_bad="$ap1_bad [step 3 no longer makes a relevant account a $refl_lbl line in the day block]"
  h5=$(before "$s5" "$SECOND")
  [ -n "$h5" ] || h5=$s5
  printf '%s\n' "$h5" | grep -q 'At the end of the day block' \
    || ap1_bad="$ap1_bad [step 5 no longer writes at the end of the day block on the first run]"
  # The format of step 5: the fenced block right under it holds both labels.
  awk '
    /^5\. \*\*/ { on = 1; next }
    on && /^[0-9]+\. / { exit }
    on && /^ *```/ { f = !f; next }
    on && f { sub(/^ +/, ""); print }' "$DAY" > "$work/fmt"
  grep -q -F -- "$bal_lbl " "$work/fmt" || ap1_bad="$ap1_bad [step 5 format has no $bal_lbl line]"
  grep -q -F -- "$seed_lbl " "$work/fmt" || ap1_bad="$ap1_bad [step 5 format has no $seed_lbl line]"
fi
# Every in-place instruction is scoped to the second run on its own line.
# "line(s) already there" is the block's line; step 6's "what is already
# there" is the write gate, not the day block.
INPLACE='in place|lines? already there|never a new line'
grep -n -i -E "$INPLACE" "$DAY" > "$work/inplace"
while IFS= read -r hit; do
  num=${hit%%:*}
  body=${hit#*:}
  sp=$(pos "$body" "$SECOND")
  ip=$(rpos "$body" "$INPLACE")
  if [ "$sp" -eq 0 ] || [ "$ip" -lt "$sp" ]; then
    ap1_bad="$ap1_bad [close-day:$num: an in-place instruction is not scoped to the second run]"
  fi
done < "$work/inplace"
[ -s "$work/inplace" ] || ap1_bad="$ap1_bad [close-day says nothing of updating in place]"
if [ -z "$ap1_bad" ]; then
  ok "AP1 the first close-day run still writes the $refl_lbl, $bal_lbl and $seed_lbl lines; in-place updates are scoped to the second run"
else
  fail "AP1 first close-day run" "$ap1_bad"
fi

# ---------------------------------------------------------------------------
# AP2 the pains file's review dates are updated before the line is replaced.

SWAP_LINE='(pains review line|linha da revis(ã|a)o das dores)'
SWAP_VERB='(replace|troque|troca)'
UPD='(updates?|atualiz[ae]) (the review dates|as datas de revis)'
REP='(replaces?|troque|troca) (the (pains review )?line|a linha)'
ap2_bad=""
n2=0
for spec in "skills/setup/SKILL.md 2" "PROMPT.md 1" "PROMPT.pt-BR.md 1" "seeds/close-day/SKILL.md 1" "seeds/close-week/SKILL.md 1"; do
  src=${spec% *}
  want=${spec#* }
  grep -n -i -E "$SWAP_LINE" "$ROOT/$src" | grep -i -E "$SWAP_VERB" > "$work/hits"
  found=0
  while IFS= read -r hit; do
    num=${hit%%:*}
    body=${hit#*:}
    pu=$(rpos "$body" "$UPD")
    pr=$(rpos "$body" "$REP")
    if [ "$pu" -eq 0 ] || [ "$pr" -eq 0 ]; then
      ap2_bad="$ap2_bad [$src:$num: no update of the review dates and replacement of the line]"
    elif [ "$pr" -lt "$pu" ]; then
      ap2_bad="$ap2_bad [$src:$num: the line is replaced before the review dates are updated]"
    fi
    found=$((found + 1))
    n2=$((n2 + 1))
  done < "$work/hits"
  [ "$found" -ge "$want" ] || ap2_bad="$ap2_bad [$src: $found line(s) replace the pains review line, want $want]"
done
if [ -z "$ap2_bad" ]; then
  ok "AP2 the pains file's review dates are updated before the pains review line is replaced ($n2 places)"
else
  fail "AP2 order of the pains review update" "$ap2_bad"
fi

# ---------------------------------------------------------------------------
# AP3 start-day proposes the expiry, and the expired line stays in place.

ap3_bad=""
step 3 "$START" | awk '{ gsub(/\. /, ".\n"); gsub(/; /, ";\n"); print }' | grep -i 'prospective' > "$work/pro"
if [ ! -s "$work/pro" ]; then
  ap3_bad="$ap3_bad [start-day step 3 has no dated prospective item]"
else
  p=$(cat "$work/pro")
  pp=$(rpos "$p" "propos[a-z]*")
  pe=$(rpos "$p" "expir[a-z]*")
  { [ "$pp" -gt 0 ] && [ "$pp" -lt "$pe" ]; } || ap3_bad="$ap3_bad [the expiry is not proposed before it is written]"
  printf '%s\n' "$p" | grep -q -F -- "$expired" || ap3_bad="$ap3_bad [no $expired mark]"
  printf '%s\n' "$p" | grep -q -i -E 'where it is|stays' || ap3_bad="$ap3_bad [the expired line does not stay where it is]"
  w=$(printf '%s\n' "$p" | grep -o -i -E '(^|[^a-z])(delete[sd]?|deleting|remove[sd]?|removing|drop(s|ped|ping)?|erase[sd]?|move[sd]?|moving)([^a-z]|$)' | head -n 1)
  [ -z "$w" ] || ap3_bad="$ap3_bad [the expired line is taken away:$w]"
fi
if [ -z "$ap3_bad" ]; then
  ok "AP3 start-day proposes the expiry of a lapsed dated item and the line stays where it is with $expired"
else
  fail "AP3 start-day expiry" "$ap3_bad"
fi

# ---------------------------------------------------------------------------
# AP4 the PROMPTs accept only the bridge's own link target as in place.

ap4_bad=""
target=$(sed -n 's/.*\[ "\$target" = "\([^"]*\)" \] && \[ -d \.agents\/skills \].*/\1/p' "$BRIDGE" | head -n 1)
if [ -z "$target" ]; then
  ap4_bad="$ap4_bad [the bridge accepts no .agents/skills link target]"
else
  for spec in "PROMPT.md en" "PROMPT.pt-BR.md pt"; do
    src=${spec% *}
    lang=${spec#* }
    if [ "$lang" = en ]; then
      other="as a link to anything other than $target,"
      inplace="(a link to $target is the discovery already in place)"
      show='show me the conflict'
    else
      other="como link pra qualquer lugar que não seja $target,"
      inplace="(link pra $target é a descoberta já feita)"
      show='me mostre o conflito'
    fi
    grep -m1 -F '(a)' "$ROOT/$src" | grep -F '.agents/skills' > "$work/disc"
    if [ ! -s "$work/disc" ]; then
      ap4_bad="$ap4_bad [$src: no discovery rule with step (a)]"
      continue
    fi
    pre=$(before "$(cat "$work/disc")" "(a)")
    [ "$(pos "$pre" "$other")" -gt 0 ] || ap4_bad="$ap4_bad [$src: a .agents/skills link to another target than the bridge's is not a conflict]"
    [ "$(pos "$pre" "$inplace")" -gt 0 ] || ap4_bad="$ap4_bad [$src: the link in place is not the bridge's target]"
    [ "$(pos "$pre" "$show")" -gt 0 ] || ap4_bad="$ap4_bad [$src: the .agents conflict is not shown to the person]"
  done
fi
if [ -z "$ap4_bad" ]; then
  ok "AP4 both PROMPTs take as in place only the bridge's .agents/skills target ($target) and show the .agents conflict to the person"
else
  fail "AP4 .agents/skills target against the bridge" "$ap4_bad"
fi

[ "$failures" -eq 0 ]
