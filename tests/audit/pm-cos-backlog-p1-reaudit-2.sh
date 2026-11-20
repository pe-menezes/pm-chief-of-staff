#!/bin/sh
# Probes from reaudit 2 of the backlog front, part 1 (the log guard walks the
# text outside the strings piece by piece, each bracket kind found on its
# own). Behavior only, pinned by content.
# Run by hand: sh tests/audit/pm-cos-backlog-p1-reaudit-2.sh < /dev/null
# Every case works in folders under one mktemp -d, removed at the end.
# CDPATH and CLAUDE_PROJECT_DIR are dropped. No case reads the clock.
# Cases:
# S1 a whole Write over the existing log whose structure holds arrays outside
#    the strings (one with strings, an empty one right before the closing
#    braces, nested arrays and objects before tool_name, an array after
#    tool_input, and an indented one with tabs and line feeds) is refused
#    with exit 2 and the fixed message. Under sh and, when present,
#    /bin/dash.
# S2 text other than whitespace right before the first "{" (a letter, a
#    digit, a comma, a colon, a backslash, with or without a space between
#    it and the brace) is text outside the object, so the Write passes with
#    exit 0 and nothing on stdout or stderr. Same shells.
# S0 the existing log is unchanged by every run.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

unset CDPATH
unset CLAUDE_PROJECT_DIR
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
GUARD="$ROOT/hooks/log-guard.sh"
MSG="Log guard (pm-chief-of-staff): this Write would replace a day's log (memory/YYYY-MM-DD.md) that already exists and is not empty. The log only grows: add the new entry with Edit, keeping the entries already in it."
LOG=2031-05-14.md
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
passed() { [ "$rc" -eq 0 ] && [ ! -s "$work/out" ] && [ ! -s "$work/err" ]; }

# S1: payload N writes the N-th whole object to $work/in; the path is the
# only %s, so every other byte is the format's own.
s1_payload() {
  case "$1" in
    1) printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x","tags":["a","b"]}}' "$F" ;;
    2) printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x","e":[]}}' "$F" ;;
    3) printf '{"a":[[],[{}],{"b":[1,[2]]}],"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}' "$F" ;;
    4) printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"},"l":[{"k":"v"}]}' "$F" ;;
    5) printf '{\n\t"tool_name": "Write",\n\t"list": [\n\t\t"a",\n\t\t[]\n\t],\n\t"tool_input": {\n\t\t"file_path": "%s",\n\t\t"content": "x"\n\t}\n}\n' "$F" ;;
  esac > "$work/in"
}
s1=""
n1=0
for s in $SHELLS; do
  for i in 1 2 3 4 5; do
    s1_payload "$i"
    guard "$s"
    n1=$((n1 + 1))
    refused || s1="${s1}$s payload $i [$(cut -c1-90 < "$work/in" | head -1)] exit $rc; "
  done
done
if [ -z "$s1" ]; then ok "S1 a whole Write with arrays outside the strings is refused ($n1 runs, $SHELLS)"
else fail "S1 whole object with arrays" "$s1"
fi

# S2: the text before the brace is the %s of the format; the object after it
# is the canonical Write over the existing log.
s2=""
n2=0
for s in $SHELLS; do
  for pre in 'x' '1' ',' ':' '\' 'x ' '1	'; do
    printf '%s{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}' "$pre" "$F" > "$work/in"
    guard "$s"
    n2=$((n2 + 1))
    passed || s2="${s2}$s text [$pre] exit $rc; "
  done
done
if [ -z "$s2" ]; then ok "S2 text right before the first brace passes in silence ($n2 runs, $SHELLS)"
else fail "S2 text before the object" "$s2"
fi

if [ "$(cat "$F")" = "$(printf '## [08:00] First entry\nbody')" ]; then ok "S0 the existing log is unchanged"
else fail "S0 existing log" "changed"
fi

rm -rf "$work"
[ "$failures" -eq 0 ] || exit 1
exit 0
