#!/bin/sh
# Probes from reaudit 1 of part 2 of the overdue-events front (repair 2: the
# active event labels stay untranslated). Behavior only, pinned by content.
# Run by hand: sh tests/audit/pm-cos-vencido-p2-reaudit-1.sh < /dev/null
# Every case works in folders under one mktemp -d, removed at the end.
# CDPATH and CLAUDE_PROJECT_DIR are dropped. "Today" comes from a fake date
# in front of PATH; no case reads the clock.
# Cases:
# R1 the plant and setup adaptation replaces each label of the vocabulary
#    piece by piece (the fixed text before "YYYY" of the event date row and
#    of the checked date row), not the whole-line row. This case takes the
#    active event format the seeds write (process-meeting and close-week, in
#    English), adapts it the same way to each target column of the event
#    rows (pt-BR for a Portuguese folder; en for an English folder and for
#    any other language, which keeps the en column), fills the placeholders
#    with an event date before today and feeds the line to the session-start
#    hook: the line must be marked OVERDUE, and the adapted format must be
#    the whole-line row of the same column, so the pieces and the whole row
#    never drift apart.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

unset CDPATH
unset CLAUDE_PROJECT_DIR
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
BOOT="$ROOT/hooks/boot-memory.sh"
VOC="$ROOT/modules/vocabulary.md"
MID=$(printf '\302\267')
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

for f in "$BOOT" "$VOC"; do
  [ -f "$f" ] || { echo "FAIL  missing $f"; exit 1; }
done

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi
work=$(cd "$work" && pwd -P)

mkdir -p "$work/may17"
printf '#!/bin/sh\ncase "$*" in\n  "+%%Y-%%m-%%d") echo 2031-05-17 ;;\n  "+%%Y-%%m-%%d %%H:%%M") echo "2031-05-17 09:30" ;;\n  *) exec /bin/date "$@" ;;\nesac\n' > "$work/may17/date"
chmod +x "$work/may17/date"

B="$work/boot"
mkdir -p "$B/memory"
echo manual > "$B/AGENTS.md"
echo nav > "$B/navigation.md"

# cell PREFIX COL: column COL of the vocabulary row whose role starts with
# PREFIX, without the surrounding spaces and backticks.
cell() {
  grep -F -- "$1" "$VOC" | head -n 1 | awk -F'|' -v c="$2" '{ print $c }' | sed 's/^ *`//; s/` *$//'
}

# piece CELL: the fixed text before the first YYYY.
piece() {
  printf '%s\n' "$1" | awk '{ i = index($0, "YYYY"); if (i > 0) print substr($0, 1, i - 1) }'
}

# swap TEXT FROM TO: TEXT with the first FROM replaced by TO, as fixed text.
swap() {
  printf '%s\n' "$1" | awk -v f="$2" -v t="$3" '{ i = index($0, f); if (i > 0) $0 = substr($0, 1, i - 1) t substr($0, i + length(f)); print }'
}

fill() {
  printf '%s\n' "$1" | sed 's/^{[^}]*}/Quarterly review/; s/{[^}]*}$/projects\/a.md/; s/YYYY-MM-DD/2031-05-16/g'
}

ROW_DATE='| active event in `CRITICAL_FACTS.md`: event date'
ROW_CHK='| active event in `CRITICAL_FACTS.md`: checked date'
ROW_WHOLE='| active event line, whole'

r1=""
n1=0
en_date=$(piece "$(cell "$ROW_DATE" 3)")
en_chk=$(piece "$(cell "$ROW_CHK" 3)")
if [ -z "$en_date" ] || [ -z "$en_chk" ]; then
  r1=" [en event rows not found or without YYYY]"
fi
for src in seeds/process-meeting/SKILL.md seeds/close-week/SKILL.md; do
  [ -n "$r1" ] && break
  fmt=$(grep -o '`{[^}]*} ([^`]*`' "$ROOT/$src" | head -n 1 | sed 's/^`//; s/`$//')
  if [ -z "$fmt" ]; then
    r1="$r1 [$src: no active event format found]"
    continue
  fi
  for col in 3 4; do
    to_date=$(piece "$(cell "$ROW_DATE" "$col")")
    to_chk=$(piece "$(cell "$ROW_CHK" "$col")")
    whole=$(cell "$ROW_WHOLE" "$col")
    if [ -z "$to_date" ] || [ -z "$to_chk" ] || [ -z "$whole" ]; then
      r1="$r1 [column $col: event rows not found or without YYYY]"
      continue
    fi
    adapted=$(swap "$(swap "$fmt" "$en_date" "$to_date")" "$en_chk" "$to_chk")
    # The placeholders {event} and {source path} are the person's own words
    # and adapt with the rest of the column; compare from the first "(" to
    # the last "{".
    a_tail=${adapted#*\(}
    a_tail=${a_tail%\{*}
    w_tail=${whole#*\(}
    w_tail=${w_tail%\{*}
    [ "$a_tail" = "$w_tail" ] || r1="$r1 [$src column $col: adapted '$adapted' is not the whole-line row '$whole']"
    line="* $(fill "$adapted")"
    printf '# Facts\n\n%s\n' "$line" > "$B/CRITICAL_FACTS.md"
    (cd "$B" && PATH="$work/may17:$PATH" sh "$BOOT" > "$work/pack" 2>/dev/null)
    grep -qxF -- "$line $MID OVERDUE 2031-05-16" "$work/pack" || r1="$r1 [$src column $col: not marked: $line]"
    n1=$((n1 + 1))
  done
done
if [ -z "$r1" ] && [ "$n1" -eq 4 ]; then
  ok "R1 the seed format adapted piece by piece by the event rows (en, also for any other language, and pt-BR) is the whole-line row and is marked when overdue"
else
  fail "R1 piecewise adaptation vs whole row and hook" "$r1"
fi

rm -rf "$work"
[ "$failures" -eq 0 ]
