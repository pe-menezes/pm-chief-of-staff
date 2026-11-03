#!/bin/sh
# Probes from the audit of the overdue-events front, part 2 (the text that
# teaches the active event line and how a session resolves an overdue one).
# Behavior only, pinned by content: each case takes the active event line the
# plugin teaches or writes, as it stands in the text, and feeds it to the
# session-start hook, which must mark it once its date has passed.
# Run by hand: sh tests/audit/pm-cos-vencido-p2.sh < /dev/null
# Every case works in folders under one mktemp -d, removed at the end.
# CDPATH and CLAUDE_PROJECT_DIR are dropped. "Today" comes from a fake date
# in front of PATH; no case reads the clock.
# Cases:
# E1 the example line that setup and the two PROMPTs give to the person
#    (a backticked or quoted list item holding "(event " or "(evento "),
#    written as is into CRITICAL_FACTS.md: with today after its event date
#    the pack shows it with " · OVERDUE <its date>"; with today before it,
#    the line is shown unmarked.
# E2 the active event line the planted seeds write (process-meeting and
#    close-week, the backticked "{event} (...) → {...}" format) and the
#    whole-line row of modules/vocabulary.md in both columns (en, and pt-BR,
#    the one the plant adaptation uses in a Portuguese folder), with the
#    placeholders filled and an event date before today: each is marked.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

unset CDPATH
unset CLAUDE_PROJECT_DIR
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
BOOT="$ROOT/hooks/boot-memory.sh"
MID=$(printf '\302\267')
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi
work=$(cd "$work" && pwd -P)

# fake_date DIR DAY: a date command in DIR that answers DAY for the boot.
fake_date() {
  mkdir -p "$1"
  printf '#!/bin/sh\ncase "$*" in\n  "+%%Y-%%m-%%d") echo %s ;;\n  "+%%Y-%%m-%%d %%H:%%M") echo "%s 09:30" ;;\n  *) exec /bin/date "$@" ;;\nesac\n' "$2" "$2" > "$1/date"
  chmod +x "$1/date"
}
fake_date "$work/after" 2099-12-31
fake_date "$work/before" 2000-01-01
fake_date "$work/may17" 2031-05-17

B="$work/boot"
mkdir -p "$B/memory"
echo manual > "$B/AGENTS.md"
echo nav > "$B/navigation.md"

# pack_of LINE FAKEDIR: the boot pack of a CRITICAL_FACTS.md holding LINE.
pack_of() {
  printf '# Facts\n\n%s\n' "$1" > "$B/CRITICAL_FACTS.md"
  (cd "$B" && PATH="$2:$PATH" sh "$BOOT" > "$work/pack" 2>/dev/null)
}

# event_date LINE: the date right after the first "(event " or "(evento ".
event_date() {
  printf '%s\n' "$1" | grep -o '(evento* [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' | head -n 1 | sed 's/.* //'
}

# E1: the example taught by setup and the two PROMPTs.
e1=""
n1=0
for src in skills/setup/SKILL.md PROMPT.md PROMPT.pt-BR.md; do
  f="$ROOT/$src"
  ex=$( { grep -o '`\* [^`]*(evento* [^`]*`' "$f"; grep -o '"\* [^"]*(evento* [^"]*"' "$f"; } 2>/dev/null | head -n 1)
  ex=$(printf '%s' "$ex" | sed 's/^[`"]//; s/[`"]$//')
  if [ -z "$ex" ]; then
    e1="$e1 [$src: no example active event line found]"
    continue
  fi
  d=$(event_date "$ex")
  if [ -z "$d" ]; then
    e1="$e1 [$src: example has no ISO event date: $ex]"
    continue
  fi
  pack_of "$ex" "$work/after"
  grep -qxF -- "$ex $MID OVERDUE $d" "$work/pack" || e1="$e1 [$src: not marked after its date: $ex]"
  pack_of "$ex" "$work/before"
  { grep -qxF -- "$ex" "$work/pack" && ! grep -qF -- "OVERDUE" "$work/pack"; } || e1="$e1 [$src: wrong before its date]"
  n1=$((n1 + 1))
done
if [ -z "$e1" ] && [ "$n1" -eq 3 ]; then
  ok "E1 the example line of setup, PROMPT.md and PROMPT.pt-BR.md is marked once its date passes, and only then"
else
  fail "E1 taught example vs hook" "$e1"
fi

# fill FORMAT: the format with its placeholders filled and dates 2031-05-16.
fill() {
  printf '%s\n' "$1" | sed 's/^{[^}]*}/Quarterly review/; s/{[^}]*}$/projects\/a.md/; s/YYYY-MM-DD/2031-05-16/g'
}

# E2: the line the seeds write and the vocabulary row, both columns.
e2=""
n2=0
for src in seeds/process-meeting/SKILL.md seeds/close-week/SKILL.md; do
  fmt=$(grep -o '`{[^}]*} ([^`]*`' "$ROOT/$src" | head -n 1 | sed 's/^`//; s/`$//')
  if [ -z "$fmt" ]; then
    e2="$e2 [$src: no active event format found]"
    continue
  fi
  line="* $(fill "$fmt")"
  pack_of "$line" "$work/may17"
  grep -qxF -- "$line $MID OVERDUE 2031-05-16" "$work/pack" || e2="$e2 [$src: not marked: $line]"
  n2=$((n2 + 1))
done
row=$(grep -F '| active event line, whole' "$ROOT/modules/vocabulary.md" | head -n 1)
for col in 3 4; do
  fmt=$(printf '%s\n' "$row" | awk -F'|' -v c="$col" '{ print $c }' | sed 's/^ *`//; s/` *$//')
  if [ -z "$fmt" ]; then
    e2="$e2 [vocabulary column $col: empty]"
    continue
  fi
  line="* $(fill "$fmt")"
  pack_of "$line" "$work/may17"
  grep -qxF -- "$line $MID OVERDUE 2031-05-16" "$work/pack" || e2="$e2 [vocabulary column $col: not marked: $line]"
  n2=$((n2 + 1))
done
if [ -z "$e2" ] && [ "$n2" -eq 4 ]; then
  ok "E2 the line process-meeting and close-week write, and the vocabulary row in en and pt-BR, are marked when overdue"
else
  fail "E2 written format vs hook" "$e2"
fi

rm -rf "$work"
[ "$failures" -eq 0 ]
