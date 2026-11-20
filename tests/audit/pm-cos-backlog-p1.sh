#!/bin/sh
# Probes from the audit of the backlog front, part 1 (the log guard reads
# one whole JSON object). Behavior only, pinned by content.
# Run by hand: sh tests/audit/pm-cos-backlog-p1.sh < /dev/null
# Every case works in folders under one mktemp -d, removed at the end.
# CDPATH and CLAUDE_PROJECT_DIR are dropped. No case reads the clock.
# Cases:
# A1 JSON whitespace around and between the tokens (space, tab, line feed,
#    carriage return) does not make a whole object stop being one: a Write
#    over the existing log with a trailing line feed, a trailing CRLF,
#    leading whitespace, or pretty-printed with tabs and CRLF line ends
#    (tab around the colon included) is refused with exit 2 and the fixed
#    message, under sh and, when present, /bin/dash.
# A2 brackets that do not nest by kind, or a string left open after an
#    object that already closed, are not one whole JSON object: such a
#    payload holding the existing log's file_path passes in silence, under
#    sh and, when present, /bin/dash.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

unset CDPATH
unset CLAUDE_PROJECT_DIR
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
GUARD="$ROOT/hooks/log-guard.sh"
MSG="Log guard (pm-chief-of-staff): this Write would replace a day's log (memory/YYYY-MM-DD.md) that already exists and is not empty. The log only grows: add the new entry with Edit, keeping the entries already in it."
LOG=2031-05-16.md
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

# guard SHELL: runs the guard on $work/in from /. Sets rc.
guard() {
  (cd / && "$1" "$GUARD" < "$work/in" > "$work/out" 2> "$work/err")
  rc=$?
}
refused() { [ "$rc" -eq 2 ] && [ ! -s "$work/out" ] && cmp -s "$work/err" "$work/msg"; }
passed() { [ "$rc" -eq 0 ] && [ ! -s "$work/out" ] && [ ! -s "$work/err" ]; }

# A1: whole objects with JSON whitespace outside the strings. Each shape is
# written by printf with %s for the path; \t, \r and \n in the format are the
# real bytes, and the content's \\n and \\" are JSON escapes.
a1=""
n1=0
for s in $SHELLS; do
  for fmt in \
    '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"## [09:00] x\\n"}}\n' \
    '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"## [09:00] x\\n"}}\r\n' \
    ' \t\r\n{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}' \
    '{\r\n\t"tool_name":\t"Write",\r\n\t"tool_input": {\r\n\t\t"file_path" :\t"%s",\r\n\t\t"content": "a \\"}\\" ]"\r\n\t}\r\n}\r\n' \
    '{ "tool_name" : "Write" , "tool_input" : { "file_path" : "%s" , "content" : "x" } }\t\n'; do
    printf "$fmt" "$F" > "$work/in"
    guard "$s"
    n1=$((n1 + 1))
    refused || a1="${a1}$s [$(od -An -c < "$work/in" | tr -s ' \n' ' ' | cut -c1-80)...] exit $rc; "
  done
done
if [ -z "$a1" ]; then ok "A1 a whole Write payload with JSON whitespace outside its strings is refused ($n1 runs, $SHELLS)"
else fail "A1 whitespace around a whole object" "$a1"
fi

# A2: not one whole object, with the log's file_path whole in it.
a2=""
n2=0
for s in $SHELLS; do
  for fmt in \
    '{"tool_name":"Write","tool_input":{"file_path":"%s","content":["x"}]}' \
    '{"tool_name":"Write","tool_input":{"file_path":"%s","content":{"x":1]}}' \
    '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}"' \
    '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}} "tail'; do
    printf "$fmt" "$F" > "$work/in"
    guard "$s"
    n2=$((n2 + 1))
    passed || a2="${a2}$s [$(cat "$work/in")] exit $rc; "
  done
done
if [ -z "$a2" ]; then ok "A2 brackets of the wrong kind or a string left open after the object pass in silence ($n2 runs, $SHELLS)"
else fail "A2 payload that is not one whole object" "$a2"
fi

# The log on disk is untouched by every run above.
if [ "$(cat "$F")" = "$(printf '## [08:00] First entry\nbody')" ]; then ok "A0 the existing log is unchanged"
else fail "A0 existing log" "changed"
fi

rm -rf "$work"
[ "$failures" -eq 0 ] || exit 1
exit 0
