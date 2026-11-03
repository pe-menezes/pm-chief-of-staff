#!/bin/sh
# Probes from the re-audit of the optional-routines front, part 2, fix 1
# (the pains review exception in close-day and the dates of the next pains
# review line). Behavior only, pinned by content: setup, the seeds and the
# PROMPTs are instructions, so the probes check what they tell the agent to
# write in CRITICAL_FACTS.md after a done review.
# Run by hand: sh tests/audit/pm-cos-rituais-p2-reaudit-1.sh < /dev/null
# Cases:
#   RA1 (risk code: date boundary) every line of setup, the two PROMPTs and
#       close-day that tells the agent to replace the pains review line
#       after a done review gives the dates of the new line: the event date
#       is the nearest of the pains file's review dates, the checked date is
#       the day of the review, and the next review is 3 months after the one
#       done unless the person gives another date; none keeps the old
#       "that day" / "today" wording for the checked date. Setup must carry
#       it twice (item 6 and the session routine), the others once.
#   RA2 (risk code: what removes the line) every line that tells what a
#       done review does to the pains review line (setup, close-week,
#       close-day, both PROMPTs, both READMEs) binds the "no pain left open"
#       condition to the removal ("remove it when no pain is left open"),
#       never to the replacement, so a swap of the two branches, which keeps
#       every keyword, is caught. Setup and each README carry it twice, the
#       others once.
#   RA3 the sentence of the 5-event cap that names the pains review counts
#       it only while a pain is left open and does not say "always"
#       (setup, PROMPT.md, PROMPT.pt-BR.md).
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

unset CDPATH
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi
trap 'rm -rf "$work"' EXIT

SWAP_LINE='(pains review line|linha da revis(ã|a)o das dores)'
SWAP_VERB='(replace|troque|troca)'

# RA1
e1=""
n1=0
for spec in "skills/setup/SKILL.md 2" "PROMPT.md 1" "PROMPT.pt-BR.md 1" "seeds/close-day/SKILL.md 1"; do
  src=${spec% *}
  want=${spec#* }
  grep -niE "$SWAP_LINE" "$ROOT/$src" | grep -iE "$SWAP_VERB" > "$work/hits"
  found=0
  while IFS= read -r hit; do
    num=${hit%%:*}
    body=${hit#*:}
    printf '%s\n' "$body" | grep -qiE 'the nearest of the|a mais pr(ó|o)xima das datas' || e1="$e1 [$src:$num: event date not the nearest review date]"
    printf '%s\n' "$body" | grep -qiE 'the day of the review as the checked date|o dia da revis(ã|a)o como data de conferido' || e1="$e1 [$src:$num: checked date not the day of the review]"
    printf '%s\n' "$body" | grep -qiE '(the next review 3 months after the one done, unless (the person gives|I give) another date)|(a pr(ó|o)xima revis(ã|a)o 3 meses depois da feita, salvo outra data)' || e1="$e1 [$src:$num: no 3-month cadence with the person's date]"
    printf '%s\n' "$body" | grep -qiE 'that day as the checked date|today as the (checked date|last confirmation)|o dia como data de conferido' && e1="$e1 [$src:$num: old checked-date wording]"
    found=$((found + 1))
    n1=$((n1 + 1))
  done < "$work/hits"
  [ "$found" -ge "$want" ] || e1="$e1 [$src: $found line(s) replace the pains review line, want $want]"
done
if [ -z "$e1" ]; then
  ok "RA1 the next pains review line gets the nearest review date, the review day as checked, and a 3-month cadence ($n1 places)"
else
  fail "RA1 the dates of the next pains review line" "$e1"
fi

# RA2
e2=""
n2=0
for spec in "skills/setup/SKILL.md 2" "seeds/close-week/SKILL.md 1" "seeds/close-day/SKILL.md 1" "PROMPT.md 1" "PROMPT.pt-BR.md 1" "README.md 2" "README.pt-BR.md 2"; do
  src=${spec% *}
  want=${spec#* }
  grep -niE 'no pain is left open|n(ã|a)o sobra(r)? dor aberta' "$ROOT/$src" > "$work/hits"
  found=0
  while IFS= read -r hit; do
    num=${hit%%:*}
    body=${hit#*:}
    # the condition sits right after the removal verb, and a replacement
    # comes before it in the same clause, joined by "or"/"and" ("ou"/"e")
    printf '%s\n' "$body" | grep -qiE '(removes? (it|the line)|drops? it)( only)? when no pain is left open|(tire a linha|a tira) quando n(ã|a)o sobra(r)? dor aberta' || e2="$e2 [$src:$num: the no-open-pain condition is not on the removal]"
    printf '%s\n' "$body" | grep -qiE '(replace|swap)[^;]*(, or| and) (removes?|drops?) (it|the line)|(troque|troca)[^;]*(, ou| e)( s(ó|o))? (tire a linha|a tira)' || e2="$e2 [$src:$num: no replacement before the conditioned removal]"
    found=$((found + 1))
    n2=$((n2 + 1))
  done < "$work/hits"
  [ "$found" -ge "$want" ] || e2="$e2 [$src: $found line(s) bind the removal to no open pain, want $want]"
done
if [ -z "$e2" ]; then
  ok "RA2 a done review removes the pains review line only when no pain is left open, and otherwise replaces it ($n2 places)"
else
  fail "RA2 the removal branch of the pains review line" "$e2 (places read: $n2)"
fi

# RA3
e3=""
n3=0
for src in skills/setup/SKILL.md PROMPT.md PROMPT.pt-BR.md; do
  grep -nE 'at most 5 active events|no m(á|a)ximo 5 eventos ativos' "$ROOT/$src" > "$work/hits"
  found=0
  while IFS= read -r hit; do
    num=${hit%%:*}
    body=${hit#*:}
    sent=$(printf '%s\n' "$body" | awk '{ gsub(/\. /, ".\n"); print }' | grep -iE 'pains review|revis(ã|a)o das dores' | grep -E '(at most|no m(á|a)ximo) 5' | head -n 1)
    if [ -z "$sent" ]; then
      e3="$e3 [$src:$num: no sentence counts the pains review in the cap]"
    else
      printf '%s\n' "$sent" | grep -qiE 'while a pain is left open|enquanto houver dor aberta' || e3="$e3 [$src:$num: the pains review counts in the cap without the open pain condition]"
      printf '%s\n' "$sent" | grep -qiE '(^|[^a-z])(always|sempre)([^a-z]|$)' && e3="$e3 [$src:$num: the cap sentence says always]"
    fi
    found=1
    n3=$((n3 + 1))
  done < "$work/hits"
  [ "$found" -eq 1 ] || e3="$e3 [$src: no statement of the cap]"
done
if [ -z "$e3" ]; then
  ok "RA3 the pains review counts among the 5 events only while a pain is left open ($n3 places)"
else
  fail "RA3 the pains review in the cap" "$e3"
fi

[ "$failures" -eq 0 ]
