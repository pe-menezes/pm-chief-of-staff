#!/bin/sh
# Probes from reaudit 1 of the backlog front, part 1 (the log guard reads
# one whole JSON object; the parity of the backslashes before each quote).
# Behavior only, pinned by content.
# Run by hand: sh tests/audit/pm-cos-backlog-p1-reaudit-1.sh < /dev/null
# Every case works in folders under one mktemp -d, removed at the end.
# CDPATH and CLAUDE_PROJECT_DIR are dropped. No case reads the clock.
# Cases:
# R1 a whole Write over the existing log whose content is only backslashes
#    (1 to 4 of them, so the string segment between the quotes is an even
#    run of 2 to 8 backslashes with nothing before it) is refused with exit
#    2 and the fixed message; so is one whose content is a backslash and a
#    quote (an odd run alone before an escaped quote, then an empty
#    segment). Under sh and, when present, /bin/dash.
# R0 the existing log is unchanged by every run.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

unset CDPATH
unset CLAUDE_PROJECT_DIR
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
GUARD="$ROOT/hooks/log-guard.sh"
MSG="Log guard (pm-chief-of-staff): this Write would replace a day's log (memory/YYYY-MM-DD.md) that already exists and is not empty. The log only grows: add the new entry with Edit, keeping the entries already in it."
LOG=2031-05-15.md
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi
work=$(cd "$work" && pwd -P)
printf '%s\n' "$MSG" > "$work/msg"

SHELLS="sh"
[ -x /bin/dash ] && SHELLS="sh /bin/dash"

C="$work/cos"
mkdir -p "$C/memory"
echo manual > "$C/CLAUDE.md"
echo facts > "$C/CRITICAL_FACTS.md"
printf '## [08:00] First entry\nbody\n' > "$C/memory/$LOG"
F="$C/memory/$LOG"

guard() {
  (cd / && "$1" "$GUARD" < "$work/in" > "$work/out" 2> "$work/err")
  rc=$?
}
refused() { [ "$rc" -eq 2 ] && [ ! -s "$work/out" ] && cmp -s "$work/err" "$work/msg"; }

# R1: each content below is the raw JSON text between the quotes of the
# content value, written with printf %s, so every backslash is a real byte.
r1=""
n1=0
for s in $SHELLS; do
  for content in '\\' '\\\\' '\\\\\\' '\\\\\\\\' '\\\"'; do
    printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"%s"}}' "$F" "$content" > "$work/in"
    guard "$s"
    n1=$((n1 + 1))
    refused || r1="${r1}$s content [$content] exit $rc; "
  done
done
if [ -z "$r1" ]; then ok "R1 a whole Write whose content is only a run of backslashes is refused ($n1 runs, $SHELLS)"
else fail "R1 content made of backslashes" "$r1"
fi

if [ "$(cat "$F")" = "$(printf '## [08:00] First entry\nbody')" ]; then ok "R0 the existing log is unchanged"
else fail "R0 existing log" "changed"
fi

rm -rf "$work"
[ "$failures" -eq 0 ] || exit 1
exit 0
