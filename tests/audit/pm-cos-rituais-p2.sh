#!/bin/sh
# Probes from the audit of the optional-routines front, part 2 (the pains
# review as an active event in CRITICAL_FACTS.md). Behavior only, pinned by
# content. setup, the seeds and the PROMPTs are instructions, so the probes
# check what the agent writes and follows at run time against the hook that
# reads it, and the contracts between files.
# Run by hand: sh tests/audit/pm-cos-rituais-p2.sh < /dev/null
# Every boot case works in folders under one mktemp -d, removed at the end.
# CDPATH and CLAUDE_PROJECT_DIR are dropped. "Today" comes from a fake date
# in front of PATH; no case reads the clock.
# Cases:
#   PB1 (risk code: date boundary, fixed labels) the pains review example
#       that setup, PROMPT.md and PROMPT.pt-BR.md teach for the initial
#       CRITICAL_FACTS.md points at the vocabulary's pains file of its
#       column, carries that column's label pair, has its checked date (the
#       setup day) before its event date, and, written into CRITICAL_FACTS.md
#       next to the roadmap example of the same file, is shown unmarked on
#       the setup day and on its own event date and marked
#       " . OVERDUE <date>" once the date has passed, while the roadmap line
#       keeps its own mark; the English example with its text in a third
#       language (labels untouched, as setup says) is marked the same way.
#   PB2 (risk code: the overdue exception) every line of setup, the PROMPTs,
#       the seeds and the modules that teaches removing an overdue active
#       event line (it names the OVERDUE mark and says to remove the line)
#       also keeps the general removal and carries the pains review
#       exception: replace the line with the next review, remove it only
#       when no pain is left open. The judge is checked against a copy of
#       setup's session routine with the exception cut, so it is never
#       vacuous.
#   PB3 (risk code: the line after the review) every line that tells what a
#       done review does to the pains review line (it names the vocabulary's
#       pains file of its language and CRITICAL_FACTS.md, and says to remove
#       the line) swaps it for the next review and removes it only when no
#       pain is left open: setup items 3 and 6, close-week step 5, the two
#       PROMPTs and the two READMEs.
#   PB4 every line that states the cap of 5 active events (setup, PROMPTs,
#       READMEs, seeds, modules) has one sentence that names the cap and the
#       pains review together, so the line counts among the 5; there are at
#       least the three places setup and the two PROMPTs.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

unset CDPATH
unset CLAUDE_PROJECT_DIR
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
BOOT="$ROOT/hooks/boot-memory.sh"
VOC="$ROOT/modules/vocabulary.md"
MID=$(printf '\302\267')
ARROW=$(printf '\342\206\222')
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi
work=$(cd "$work" && pwd -P)
trap 'rm -rf "$work"' EXIT

# vocab ROWSTART COL: the backticked cell of a vocabulary row (3 en, 4 pt-BR).
vocab() {
  grep -F "| $1" "$VOC" | head -n 1 | awk -F'|' -v c="$2" '{ print $c }' | sed 's/^ *`//; s/` *$//'
}
PAINS_EN=$(vocab 'pains |' 3)
PAINS_PT=$(vocab 'pains |' 4)
EV_EN=$(vocab 'active event in `CRITICAL_FACTS.md`: event date' 3 | sed 's/^(//; s/ .*//')
EV_PT=$(vocab 'active event in `CRITICAL_FACTS.md`: event date' 4 | sed 's/^(//; s/ .*//')
CK_EN=$(vocab 'active event in `CRITICAL_FACTS.md`: checked date' 3 | sed 's/ .*//')
CK_PT=$(vocab 'active event in `CRITICAL_FACTS.md`: checked date' 4 | sed 's/ .*//')
for v in "$PAINS_EN" "$PAINS_PT" "$EV_EN" "$EV_PT" "$CK_EN" "$CK_PT"; do
  if [ -z "$v" ]; then
    echo "FAIL  vocabulary rows not found (pains, event date, checked date)"
    exit 1
  fi
done

# fake_date DIR DAY: a date command in DIR that answers DAY for the boot.
fake_date() {
  mkdir -p "$1"
  printf '#!/bin/sh\ncase "$*" in\n  "+%%Y-%%m-%%d") echo %s ;;\n  "+%%Y-%%m-%%d %%H:%%M") echo "%s 09:30" ;;\n  *) exec /bin/date "$@" ;;\nesac\n' "$2" "$2" > "$1/date"
  chmod +x "$1/date"
}

B="$work/boot"
mkdir -p "$B/memory"
echo manual > "$B/AGENTS.md"
echo nav > "$B/navigation.md"

# pack_of TEXT DAY: the boot pack of a CRITICAL_FACTS.md holding TEXT.
pack_of() {
  printf '# Facts\n\n## Active events\n%s\n' "$1" > "$B/CRITICAL_FACTS.md"
  fake_date "$work/d$2" "$2"
  (cd "$B" && PATH="$work/d$2:$PATH" sh "$BOOT" > "$work/pack" 2>/dev/null)
}

# examples FILE: the example list items of FILE that hold "(event" or
# "(evento", backticked or quoted, without their delimiters.
examples() {
  { grep -o '`\* [^`]*(evento* [^`]*`' "$1"; grep -o '"\* [^"]*(evento* [^"]*"' "$1"; } 2>/dev/null | sed 's/^[`"]//; s/[`"]$//'
}

# PB1
e1=""
n1=0
for spec in "skills/setup/SKILL.md en" "PROMPT.md en" "PROMPT.pt-BR.md pt"; do
  src=${spec% *}
  col=${spec#* }
  if [ "$col" = en ]; then path=$PAINS_EN; ev=$EV_EN; ck=$CK_EN; else path=$PAINS_PT; ev=$EV_PT; ck=$CK_PT; fi
  f="$ROOT/$src"
  ex=$(examples "$f" | grep -F -- "$ARROW $path" | head -n 1)
  other=$(examples "$f" | grep -vF -- "$ARROW $path" | head -n 1)
  if [ -z "$ex" ]; then
    e1="$e1 [$src: no example line pointing at $path]"
    continue
  fi
  shape=$(printf '%s\n' "$ex" | sed -n "s/^\* .* ($ev \([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\), $ck \([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\)) $ARROW \(.*\)\$/\1 \2 \3/p")
  if [ -z "$shape" ]; then
    e1="$e1 [$src: not the $col label pair or shape: $ex]"
    continue
  fi
  d=$(printf '%s' "$shape" | awk '{ print $1 }')
  c=$(printf '%s' "$shape" | awk '{ print $2 }')
  p=$(printf '%s' "$shape" | awk '{ print $3 }')
  [ "$p" = "$path" ] || e1="$e1 [$src: source $p is not $path]"
  if [ "$(printf '%s\n%s\n' "$c" "$d" | sort | head -n 1)" != "$c" ] || [ "$c" = "$d" ]; then
    e1="$e1 [$src: checked $c is not before event $d]"
  fi
  # the setup day and the event date itself: nothing marked
  for day in "$c" "$d"; do
    pack_of "$ex" "$day"
    { grep -qxF -- "$ex" "$work/pack" && ! grep -qF -- "OVERDUE" "$work/pack"; } || e1="$e1 [$src: marked or missing on $day]"
  done
  # past its date, next to the file's other example (its own date kept)
  if [ -n "$other" ]; then
    pack_of "$other
$ex" 2099-12-31
    od=$(printf '%s\n' "$other" | grep -o '(evento* [0-9-]*' | head -n 1 | sed 's/.* //')
    grep -qxF -- "$ex $MID OVERDUE $d" "$work/pack" || e1="$e1 [$src: pains line not marked after $d]"
    grep -qxF -- "$other $MID OVERDUE $od" "$work/pack" || e1="$e1 [$src: the other example lost its own mark]"
  else
    e1="$e1 [$src: no second example to sit next to]"
  fi
  # third language, labels untouched
  if [ "$col" = en ]; then
    fr=$(printf '%s\n' "$ex" | sed "s/^\* [^(]*(/* Revue des irritants (/")
    pack_of "$fr" 2099-12-31
    grep -qxF -- "$fr $MID OVERDUE $d" "$work/pack" || e1="$e1 [$src: third-language line not marked: $fr]"
  fi
  n1=$((n1 + 1))
done
if [ -z "$e1" ] && [ "$n1" -eq 3 ]; then
  ok "PB1 the pains review example of setup and both PROMPTs points at the pains file, keeps its labels and is marked only after its date"
else
  fail "PB1 pains review example vs vocabulary and hook" "$e1"
fi

# judge_exception LINE: empty when a line that teaches removing an overdue
# event line keeps the general removal and carries the pains exception.
judge_exception() {
  j=""
  printf '%s\n' "$1" | grep -qiE 'remove the line|removes the line|tire a linha' || j="$j no general removal;"
  printf '%s\n' "$1" | grep -qiE 'pains review|revis(ão|ao) das dores' || j="$j no pains review exception;"
  printf '%s\n' "$1" | grep -qiE 'replace|swap|troque|troca' || j="$j no swap for the next review;"
  printf '%s\n' "$1" | grep -qiE 'no pain is left open|n(ã|a)o sobrar dor aberta|n(ã|a)o sobra dor aberta' || j="$j removal not bound to no open pain;"
  printf '%s' "$j"
}

# PB2
e2=""
n2=0
for f in "$ROOT/skills/setup/SKILL.md" "$ROOT/PROMPT.md" "$ROOT/PROMPT.pt-BR.md" "$ROOT"/seeds/*/SKILL.md "$ROOT"/modules/*.md; do
  [ -f "$f" ] || continue
  grep -n 'OVERDUE' "$f" 2>/dev/null | grep -iE 'remove the line|removes the line|tire a linha|tira a linha' > "$work/hits"
  # the session routine of setup, both PROMPTs and close-day step 7 must
  # each still teach the general removal
  case "$f" in
    */skills/setup/SKILL.md|*/PROMPT.md|*/PROMPT.pt-BR.md|*/seeds/close-day/SKILL.md)
      [ -s "$work/hits" ] || e2="$e2 [${f#"$ROOT"/}: no longer teaches removing an overdue line with its outcome found]" ;;
  esac
  while IFS= read -r hit; do
    num=${hit%%:*}
    body=${hit#*:}
    j=$(judge_exception "$body")
    [ -z "$j" ] || e2="$e2 [${f#"$ROOT"/}:$num:$j]"
    n2=$((n2 + 1))
  done < "$work/hits"
done
# the judge on a copy of setup's session routine with the exception cut
routine=$(grep -F 'Session routine the generated AGENTS.md carries' "$ROOT/skills/setup/SKILL.md" | head -n 1)
cut=$(printf '%s\n' "$routine" | sed 's/ The pains review line is the one exception[^.]*\.[^.]*\.//')
if [ "$cut" = "$routine" ] || [ -z "$(judge_exception "$cut")" ]; then
  e2="$e2 [judge: the routine with the exception cut was not caught]"
fi
if [ -z "$e2" ] && [ "$n2" -ge 4 ]; then
  ok "PB2 every routine that removes an overdue event line keeps the pains review exception ($n2 places)"
else
  fail "PB2 overdue removal without the pains exception" "$e2 (places read: $n2)"
fi

# PB3
e3=""
n3=0
for spec in "skills/setup/SKILL.md en" "seeds/close-week/SKILL.md en" "PROMPT.md en" "README.md en" "PROMPT.pt-BR.md pt" "README.pt-BR.md pt"; do
  src=${spec% *}
  col=${spec#* }
  if [ "$col" = en ]; then path=$PAINS_EN; else path=$PAINS_PT; fi
  grep -nF -- "$path" "$ROOT/$src" | grep -F 'CRITICAL_FACTS' | grep -iE 'remove[s]? (the line|it)|drops? it|tir(e|a) a linha|a tira ' > "$work/hits"
  found=0
  while IFS= read -r hit; do
    num=${hit%%:*}
    body=${hit#*:}
    printf '%s\n' "$body" | grep -qiE 'replace|swaps|troque|troca' || e3="$e3 [$src:$num: no swap for the next review]"
    printf '%s\n' "$body" | grep -qiE 'no pain is left open|n(ã|a)o sobra(r)? dor aberta' || e3="$e3 [$src:$num: removal not bound to no open pain]"
    found=1
    n3=$((n3 + 1))
  done < "$work/hits"
  [ "$found" -eq 1 ] || e3="$e3 [$src: no line tells what the done review does to the line]"
done
if [ -z "$e3" ]; then
  ok "PB3 a done pains review swaps the line for the next one and drops it only with no open pain ($n3 places)"
else
  fail "PB3 the line after the review" "$e3"
fi

# PB4
e4=""
n4=0
for f in "$ROOT/skills/setup/SKILL.md" "$ROOT/PROMPT.md" "$ROOT/PROMPT.pt-BR.md" "$ROOT/README.md" "$ROOT/README.pt-BR.md" "$ROOT"/seeds/*/SKILL.md "$ROOT"/modules/*.md; do
  [ -f "$f" ] || continue
  grep -nE 'at most 5 active events|no m(á|a)ximo 5 eventos ativos' "$f" > "$work/hits"
  while IFS= read -r hit; do
    num=${hit%%:*}
    body=${hit#*:}
    # one sentence names both the cap and the pains review
    printf '%s\n' "$body" | awk '{ gsub(/\. /, ".\n"); print }' | grep -iE 'pains review|revis(ã|a)o das dores' | grep -qE '(at most|no m(á|a)ximo) 5' || e4="$e4 [${f#"$ROOT"/}:$num: no sentence counts the pains review in the cap]"
    n4=$((n4 + 1))
  done < "$work/hits"
done
if [ -z "$e4" ] && [ "$n4" -ge 3 ]; then
  ok "PB4 every statement of the 5-event cap counts the pains review among them ($n4 places)"
else
  fail "PB4 the cap of 5 active events" "$e4 (places read: $n4)"
fi

[ "$failures" -eq 0 ]
