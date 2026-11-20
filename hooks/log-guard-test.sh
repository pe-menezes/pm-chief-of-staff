#!/bin/sh
# Test suite for log-guard.sh (overdue-events spec, I3): a PreToolUse hook on
# Write that refuses, with exit 2 and a fixed English message on stderr, a
# Write over a day's log (memory/YYYY-MM-DD.md) that exists and is not empty,
# in a Chief of Staff folder. Everything else passes with exit 0 and nothing
# on stdout or stderr: Edit, a new log, an empty log, a folder that is not a
# Chief of Staff, a file outside memory/, a name that is not a date, and any
# internal failure (fail-open).
# Cases:
#   X1 the execution bit of the hook
#   L1 to L12 behavior, one case per acceptance line of I3 and per way out
#   L13 differential oracle: over every shape of the five names that the
#       Chief of Staff gate reads, the guard refuses exactly where
#       boot-memory.sh boots
#   L14 the registration in hooks/hooks.json, run as Claude Code runs it
#   L15 equivalent spellings of the log's path (repeated "/", ".", "..",
#       "~/") are refused; spellings of another file pass; a relative path
#       whose first folder starts with "~" resolves against the cwd
#   L16 a command that fails after printing output makes the guard pass
#   L17 a payload of about 2.4 MB over the log is refused; cut, it passes
#   L18 a printf that fails after printing output makes the guard pass
#   L19 JSON whitespace outside the strings does not change the verdict
#   L20 a bracket of the wrong kind, or a string left open after the
#       object, is not one whole object and passes
#   L21 a string glued before or after the object is text outside it and
#       passes
#   L22 the structure decides, not the JSON grammar: a whole structure with
#       an invalid escape or a missing comma over the log is refused
# L10h covers a payload that is not one whole JSON object.
# Run by hand: sh hooks/log-guard-test.sh < /dev/null
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

# A CLAUDE_PROJECT_DIR or CDPATH from the caller would move the folders.
unset CLAUDE_PROJECT_DIR
unset CDPATH
DIR=$(cd "$(dirname "$0")" && pwd) || exit 1
ROOT=$(cd "$DIR/.." && pwd) || exit 1
GUARD="$DIR/log-guard.sh"
BOOT="$DIR/boot-memory.sh"
MSG="Log guard (pm-chief-of-staff): this Write would replace a day's log (memory/YYYY-MM-DD.md) that already exists and is not empty. The log only grows: add the new entry with Edit, keeping the entries already in it."
LOG=2031-05-17.md
failures=0

ok() { echo "ok    $1"; }
fail() { echo "FAIL  $1"; failures=$((failures + 1)); }

T=$(mktemp -d 2>/dev/null)
if [ -z "$T" ] || [ ! -d "$T" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi
printf '%s\n' "$MSG" > "$T/msg"

# cos DIR [old]: a Chief of Staff in DIR, new layout (AGENTS.md,
# CRITICAL_FACTS.md, navigation.md) or old (CLAUDE.md, CRITICAL_FACTS.md),
# with a non-empty day's log.
cos() {
  mkdir -p "$1/memory"
  if [ "${2:-}" = old ]; then
    echo "@AGENTS.md" > "$1/CLAUDE.md"
  else
    echo "manual" > "$1/AGENTS.md"
    echo "nav" > "$1/navigation.md"
  fi
  echo "facts" > "$1/CRITICAL_FACTS.md"
  printf '## [08:00] First entry\nbody\n' > "$1/memory/$LOG"
}

# payload TOOL PATH [CWD]: the PreToolUse input of Claude Code in $T/in, in
# the shape measured in a real transcript (file_path first in tool_input).
# With CWD "-" the cwd field is left out.
payload() {
  cwd_field=""
  [ "${3:--}" = - ] || cwd_field="\"cwd\":\"$3\","
  if [ "$1" = Edit ]; then
    input="{\"file_path\":\"$2\",\"old_string\":\"body\",\"new_string\":\"body 2\"}"
  else
    input="{\"file_path\":\"$2\",\"content\":\"## [10:00] New entry\\nbody\\n\"}"
  fi
  printf '{"session_id":"s-1","transcript_path":"/x/t.jsonl",%s"permission_mode":"default","hook_event_name":"PreToolUse","tool_name":"%s","tool_input":%s}' \
    "$cwd_field" "$1" "$input" > "$T/in"
}

# run_guard DIR: runs the guard in DIR with $T/in as stdin; sets rc and
# leaves stdout and stderr in $T/out and $T/err.
run_guard() {
  (cd "$1" && sh "$GUARD" < "$T/in" > "$T/out" 2> "$T/err")
  rc=$?
}

# refused: exit 2, the fixed message alone on stderr, nothing on stdout.
refused() {
  [ "$rc" -eq 2 ] && [ ! -s "$T/out" ] && cmp -s "$T/err" "$T/msg"
}

# passed: exit 0, nothing on stdout or stderr.
passed() {
  [ "$rc" -eq 0 ] && [ ! -s "$T/out" ] && [ ! -s "$T/err" ]
}

# expect NAME refused|passed
expect() {
  if "$2"; then ok "$1"
  else fail "$1: expected $2 (exit $rc, stdout $(wc -c < "$T/out" | tr -d ' ') bytes, stderr: $(head -c 200 "$T/err"))"
  fi
}

if [ -x "$GUARD" ]; then ok "X1 execution bit of the guard"
else fail "X1 execution bit of the guard missing: $GUARD"
fi

# L1: a Write over an existing, non-empty log, by absolute path, is refused,
# in both layouts, and the log stays as it was.
C="$T/cos"
cos "$C"
cp "$C/memory/$LOG" "$T/log-before"
payload Write "$C/memory/$LOG" "$C"
run_guard "$C"
if refused && cmp -s "$C/memory/$LOG" "$T/log-before"; then ok "L1 Write over an existing log, absolute path, is refused"
else fail "L1 Write over an existing log, absolute path: exit $rc, stderr: $(head -c 200 "$T/err")"
fi
O="$T/old"
cos "$O" old
payload Write "$O/memory/$LOG" "$O"
run_guard "$O"
expect "L1o same in the old layout (CLAUDE.md and CRITICAL_FACTS.md)" refused

# L2: relative paths resolve against the cwd of the payload, else the cwd of
# the hook.
payload Write "memory/$LOG" "$C"
run_guard "$C"
expect "L2 relative path with the payload cwd is refused" refused
payload Write "./memory/$LOG" "$C"
run_guard "$C"
expect "L2b ./ relative path is refused" refused
payload Write "memory/$LOG" -
run_guard "$C"
expect "L2c relative path with no cwd in the payload uses the hook cwd" refused
payload Write "memory/$LOG" "$C"
run_guard /
expect "L2d relative path follows the payload cwd, not the hook cwd" refused
payload Write "memory/$LOG" "$T"
run_guard "$C"
expect "L2e relative path from a payload cwd that is not a Chief of Staff passes" passed

# L3: a new log passes; L4: an empty log passes.
payload Write "$C/memory/2031-05-18.md" "$C"
run_guard "$C"
expect "L3 Write of a new log passes" passed
: > "$C/memory/2031-05-19.md"
payload Write "$C/memory/2031-05-19.md" "$C"
run_guard "$C"
expect "L4 Write over an empty log passes" passed

# L5: Edit passes, and so does any tool that is not Write.
payload Edit "$C/memory/$LOG" "$C"
run_guard "$C"
expect "L5 Edit of an existing log passes" passed
payload MultiEdit "$C/memory/$LOG" "$C"
run_guard "$C"
expect "L5b another tool name passes" passed

# L6: a folder with spaces in its name, absolute and relative.
S="$T/my chief of staff"
cos "$S"
payload Write "$S/memory/$LOG" "$S"
run_guard "$S"
expect "L6 path with spaces, absolute, is refused" refused
payload Write "memory/$LOG" "$S"
run_guard "$S"
expect "L6b path with spaces, relative, is refused" refused

# L7: a folder that is not a Chief of Staff (AGENTS.md and CRITICAL_FACTS.md
# with no navigation file, the vault template of the boot gate).
V="$T/vault"
mkdir -p "$V/memory"
echo manual > "$V/AGENTS.md"
echo facts > "$V/CRITICAL_FACTS.md"
echo "## [08:00] x" > "$V/memory/$LOG"
payload Write "$V/memory/$LOG" "$V"
run_guard "$V"
expect "L7 a folder that is not a Chief of Staff passes" passed
# L7b: the log of a Chief of Staff is guarded whatever the hook cwd is.
payload Write "$C/memory/$LOG" "$V"
run_guard "$V"
expect "L7b the log of a Chief of Staff from another cwd is refused" refused

# L8: outside memory/.
echo x > "$C/$LOG"
mkdir -p "$C/notes" "$C/memory/archive"
echo x > "$C/notes/$LOG"
echo x > "$C/memory/archive/$LOG"
for p in "$C/$LOG" "$C/notes/$LOG" "$C/memory/archive/$LOG"; do
  payload Write "$p" "$C"
  run_guard "$C"
  expect "L8 a dated file outside memory/ passes (${p#"$C"/})" passed
done

# L9: a name in memory/ that is not a date.
for n in today.md 2031-05-17.md.bak 2031-05-17-notes.md 2031-5-17.md 2031-05-17.txt x2031-05-17.md; do
  echo x > "$C/memory/$n"
  payload Write "$C/memory/$n" "$C"
  run_guard "$C"
  expect "L9 a name that is not a date passes (memory/$n)" passed
done

# L10: fail-open. No input, input that is not JSON, a truncated payload, no
# tool_name, a tool_name that is not a string, and a path with a JSON escape
# all pass in silence.
: > "$T/in"
run_guard "$C"
expect "L10 empty input passes" passed
printf 'not json at all' > "$T/in"
run_guard "$C"
expect "L10b input that is not JSON passes" passed
printf '{"tool_name":"Write","tool_input":{"file_path":"%s/memory/%s' "$C" "$LOG" > "$T/in"
run_guard "$C"
expect "L10c truncated payload passes" passed
printf '{"tool_input":{"file_path":"%s/memory/%s","content":"x"}}' "$C" "$LOG" > "$T/in"
run_guard "$C"
expect "L10d payload with no tool_name passes" passed
printf '{"tool_name":null,"tool_input":{"file_path":"%s/memory/%s","content":"x"}}' "$C" "$LOG" > "$T/in"
run_guard "$C"
expect "L10e tool_name that is not a string passes" passed
printf '{"tool_name":"Write","tool_input":{"file_path":"%s\\/memory\\/%s","content":"x"}}' "$C" "$LOG" > "$T/in"
run_guard "$C"
expect "L10f path with a JSON escape passes (fail-open)" passed
# L10g: the raw JSON text of a path is never read as the path. The JSON
# value x\\y names a folder x\y, which does not exist, so the Write makes a
# new file; a Chief of Staff in a folder named with the raw text x\\y must
# not refuse it.
B="$T/x\\\\y"
cos "$B"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s/memory/%s","content":"x"}}' "$B" "$LOG" > "$T/in"
run_guard "$T"
expect "L10g the raw text of an escaped path is not read as the path" passed
# L10h: a payload that is not one whole JSON object passes, even when the
# tool_name and the file_path of the existing log are whole in it: cut after
# the file_path, a string or a key left open, a bracket missing or of the
# wrong kind, text after the object, or a value that is not an object.
l10h=""
h1='{"tool_name":"Write","tool_input":{"file_path":"'"$C/memory/$LOG"'"'
for cut in "$h1,\"content\":\"abc" "$h1," "$h1" "$h1}" "$h1,\"content\":\"abc\"}" \
  "$h1,\"cont" "$h1,\"content\":\"abc\\" "$h1,\"content\":[\"abc\"}}" \
  "$h1,\"content\":\"abc\"}} x" "$h1,\"content\":\"abc\"}}{}" "[$h1,\"content\":\"abc\"}}]" \
  "$h1,\"content\":\"abc\"}}}" "$h1,\"content\":\"a\\\\\\\"}}" "$h1,\"content\":\"a\\\\\\\\\\\"}}"; do
  printf '%s' "$cut" > "$T/in"
  run_guard "$C"
  passed || l10h="${l10h}[$cut] exit $rc; "
done
# The same payload closed is a whole object and is refused, also when its
# content ends in an escaped backslash or holds an escaped quote and braces.
for whole in "$h1,\"content\":\"abc\"}}" "$h1,\"content\":\"a\\\\\\\\\"}}" \
  "$h1,\"content\":\"a \\\"}}]{ b\"}}"; do
  printf '%s' "$whole" > "$T/in"
  run_guard "$C"
  refused || l10h="${l10h}whole [$whole] exit $rc; "
done
if [ -z "$l10h" ]; then ok "L10h a payload that is not one whole JSON object passes, the whole one is refused"
else fail "L10h $l10h"
fi

# L11: a folder with a log's name passes.
mkdir -p "$C/memory/2031-05-20.md"
echo x > "$C/memory/2031-05-20.md/inside"
payload Write "$C/memory/2031-05-20.md" "$C"
run_guard "$C"
expect "L11 a folder named like a log passes" passed

# L12: the key file_path inside the content is escaped JSON and never read as
# the path, in either order.
printf '{"tool_name":"Write","tool_input":{"content":"{\\"file_path\\":\\"%s/memory/%s\\"}","file_path":"%s/memory/2031-05-21.md"}}' "$C" "$LOG" "$C" > "$T/in"
run_guard "$C"
expect "L12 a log path inside the content does not refuse a new file" passed
printf '{"tool_name":"Write","tool_input":{"content":"{\\"file_path\\":\\"%s/memory/2031-05-21.md\\"}","file_path":"%s/memory/%s"}}' "$C" "$C" "$LOG" > "$T/in"
run_guard "$C"
expect "L12b a new path inside the content does not let the log through" refused

# L13: differential oracle against boot-memory.sh. For each of the 32 shapes
# of CLAUDE.md, AGENTS.md, CRITICAL_FACTS.md, navigation.md and navegacao.md,
# with a non-empty log, the guard refuses exactly when the boot prints a
# pack. The folders carry no memoria-agente config, so the boot never hands
# off.
l13_n=0
l13_bad=""
mask=0
while [ "$mask" -lt 32 ]; do
  W="$T/shape-$mask"
  mkdir -p "$W/memory"
  i=0
  for name in CLAUDE.md AGENTS.md CRITICAL_FACTS.md navigation.md navegacao.md; do
    [ $(((mask >> i) & 1)) -eq 1 ] && echo "x" > "$W/$name"
    i=$((i + 1))
  done
  echo "## [08:00] x" > "$W/memory/$LOG"
  boot_out=$(cd "$W" && sh "$BOOT" 2>/dev/null)
  payload Write "$W/memory/$LOG" "$W"
  run_guard "$W"
  l13_n=$((l13_n + 1))
  if [ -n "$boot_out" ]; then
    refused || { [ -n "$l13_bad" ] || l13_bad="shape $mask: the boot boots, the guard exits $rc"; }
  else
    passed || { [ -n "$l13_bad" ] || l13_bad="shape $mask: the boot is silent, the guard exits $rc"; }
  fi
  mask=$((mask + 1))
done
if [ -z "$l13_bad" ] && [ "$l13_n" -eq 32 ]; then ok "L13 differential oracle: the guard and the boot agree on all $l13_n shapes"
else fail "L13 differential oracle: $l13_bad ($l13_n shapes)"
fi

# L14: the registration in hooks/hooks.json, a PreToolUse on Write, run
# through sh -c as Claude Code runs a hook command, with the plugin root in
# a folder with spaces.
json_get() {
  if command -v plutil >/dev/null 2>&1; then
    plutil -extract "$2" raw -o - "$1" 2>/dev/null
  elif command -v node >/dev/null 2>&1; then
    node -e 'let v=require(process.argv[1]);for(const k of process.argv[2].split("."))v=v==null?v:v[k];if(typeof v!=="string")process.exit(1);process.stdout.write(v)' "$1" "$2" 2>/dev/null
  else
    return 1
  fi
}
matcher=$(json_get "$ROOT/hooks/hooks.json" hooks.PreToolUse.0.matcher)
cmd=$(json_get "$ROOT/hooks/hooks.json" hooks.PreToolUse.0.hooks.0.command)
P="$T/plugin root"
ln -s "$ROOT" "$P"
if [ "$matcher" != Write ] || [ -z "$cmd" ]; then
  fail "L14 registration: PreToolUse matcher [$matcher], command [$cmd] in hooks/hooks.json"
else
  payload Write "$C/memory/$LOG" "$C"
  (cd "$C" && env CLAUDE_PLUGIN_ROOT="$P" sh -c "$cmd" < "$T/in" > "$T/out" 2> "$T/err")
  rc=$?
  r1=$rc
  refused
  s1=$?
  payload Write "$C/memory/2031-05-22.md" "$C"
  (cd "$C" && env CLAUDE_PLUGIN_ROOT="$P" sh -c "$cmd" < "$T/in" > "$T/out" 2> "$T/err")
  rc=$?
  passed
  s2=$?
  if [ "$s1" -eq 0 ] && [ "$s2" -eq 0 ]; then ok "L14 the hooks.json registration on Write refuses the overwrite and passes a new log"
  else fail "L14 registration run: overwrite exit $r1, new log exit $rc"
  fi
fi

# L15: a path that names the log through repeated slashes, "." or ".."
# components, or a leading "~/" (the home folder) is the same file, and it
# is refused like the plain path; a path that names another file still
# passes.
for p in "memory/./$LOG" "memory//$LOG" ".//memory/././$LOG" "$C//memory/./$LOG" \
  "$C/memory//$LOG" "$C/memory/archive/../$LOG" "$C/notes/../memory/$LOG" \
  "memory/archive/../$LOG" "$C/memory/no-such-folder/../$LOG"; do
  payload Write "$p" "$C"
  run_guard "$C"
  expect "L15 an equivalent path is refused ($p)" refused
done
for p in "memory/./2031-05-18.md" "$C/memory//2031-05-18.md" "$C/memory/archive/./$LOG/" \
  "$C/memory/archive/../../notes/$LOG" "memory/$LOG/" "memory/$LOG/." "$C/memory/../$LOG"; do
  payload Write "$p" "$C"
  run_guard "$C"
  expect "L15b a path that names another file passes ($p)" passed
done
payload Write "~/cos/memory/$LOG" /
(cd / && HOME="$T" sh "$GUARD" < "$T/in" > "$T/out" 2> "$T/err")
rc=$?
expect "L15c a path under ~/ resolves against the home folder and is refused" refused
(cd / && HOME=relative sh "$GUARD" < "$T/in" > "$T/out" 2> "$T/err")
rc=$?
expect "L15d a path under ~/ with a home that is not absolute passes" passed
# L15e: a relative path whose first folder name starts with "~" but not "~/"
# (here ~cos) is relative, so it resolves against the cwd: over the existing
# log it is refused, and a new log by the same spelling passes. HOME is a
# folder with no cos/ in it: a guard that read ~cos/ as $HOME/cos/ would
# find no log there and let the first Write through, so the misreading fails
# here instead of landing on the Chief of Staff the suite keeps in $T/cos.
mkdir -p "$T/tilde" "$T/empty home"
cos "$T/tilde/~cos"
payload Write "~cos/memory/$LOG" "$T/tilde"
(cd / && HOME="$T/empty home" sh "$GUARD" < "$T/in" > "$T/out" 2> "$T/err")
rc=$?
expect "L15e a relative ~cos/ path over the existing log is refused" refused
payload Write "~cos/memory/2031-05-18.md" "$T/tilde"
(cd / && HOME="$T/empty home" sh "$GUARD" < "$T/in" > "$T/out" 2> "$T/err")
rc=$?
expect "L15e a relative ~cos/ path to a new log passes" passed

# L16: fail-open when a command fails after printing usable output. Each
# command below is replaced, in front of PATH, by one that runs the real
# command and, on its K-th call only, exits 1 after the real output, leaving
# a mark. The payload has a relative path, so the guard reads tool_name,
# file_path and cwd. A guard whose K-th call failed must pass in silence; a
# guard that never made a K-th call refuses as usual. The production script
# is not changed.
l16=""
for c in cat awk tr sed head grep dirname basename; do
  real=$(command -v "$c" 2>/dev/null)
  case "$real" in /*) ;; *) continue ;; esac
  for k in 1 2 3 4; do
    F="$T/failing-$c-$k"
    mkdir -p "$F"
    printf '#!/bin/sh\nn=0\n[ -f "%s/count" ] && read n < "%s/count"\nn=$((n + 1))\necho "$n" > "%s/count"\n"%s" "$@"\ns=$?\n[ "$n" -eq %s ] || exit "$s"\n: > "%s/ran"\nexit 1\n' \
      "$F" "$F" "$F" "$real" "$k" "$F" > "$F/$c"
    chmod +x "$F/$c"
    payload Write "memory/$LOG" "$C"
    (cd "$C" && PATH="$F:$PATH" sh "$GUARD" < "$T/in" > "$T/out" 2> "$T/err")
    rc=$?
    if [ -f "$F/ran" ]; then
      passed || l16="${l16}$c failed on call $k after its output and the guard exited $rc; "
    else
      refused || l16="${l16}$c made no call $k and the guard exited $rc; "
    fi
  done
done
if [ -z "$l16" ]; then ok "L16 a command that fails after printing output makes the guard pass in silence"
else fail "L16 $l16"
fi

# L17: a large Write (about 2.4 MB of content, with escaped quotes,
# backslashes and line breaks) over the existing log is refused, so the
# payload never travels through the environment or the arguments, whose
# limit sits near 1 MB on macOS; the same payload cut before its end passes.
LC_ALL=C awk -v f="$C/memory/$LOG" 'BEGIN {
  printf "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"%s\",\"content\":\"", f
  for (i = 0; i < 48000; i++) printf "## [10:00] entry %05d with a \\\"quote\\\", a \\\\ and a break\\n", i % 100000
  printf "\"}}"
}' > "$T/big"
big_size=$(wc -c < "$T/big" | tr -d ' ')
cp "$T/big" "$T/in"
run_guard "$C"
r1=$rc
refused
s1=$?
head -c $((big_size - 2)) "$T/big" > "$T/in"
run_guard "$C"
passed
s2=$?
if [ "$big_size" -gt 2400000 ] && [ "$s1" -eq 0 ] && [ "$s2" -eq 0 ]; then ok "L17 a payload of $big_size bytes over the log is refused, and cut before its end it passes"
else fail "L17 large payload of $big_size bytes: whole exit $r1, cut exit $rc"
fi

# L18: a printf that prints its output and then returns a non-zero status
# makes the guard pass. A copy of the guard gets, right under its first line,
# a printf function that runs the real one and, on its K-th call only,
# returns 1 after the output, leaving a mark. The fixed message on stderr is
# what the guard does once it has decided, not an input to the decision, so
# the function leaves that one call alone. A guard whose K-th call failed
# must pass in silence; one that never made a K-th call refuses as usual.
l18=""
for k in 1 2 3 4; do
  F="$T/failing-printf-$k"
  mkdir -p "$F"
  {
    echo '#!/bin/sh'
    printf 'printf() {\n  case "$*" in *"Log guard (pm-chief-of-staff)"*) command printf "$@"; return ;; esac\n  __n=0\n  [ -f "%s/count" ] && read __n < "%s/count"\n  __n=$((__n + 1))\n  echo "$__n" > "%s/count"\n  command printf "$@"\n  __s=$?\n  [ "$__n" -eq %s ] || return "$__s"\n  : > "%s/ran"\n  return 1\n}\n' \
      "$F" "$F" "$F" "$k" "$F"
    sed '1d' "$GUARD"
  } > "$F/guard.sh"
  payload Write "memory/$LOG" "$C"
  (cd "$C" && sh "$F/guard.sh" < "$T/in" > "$T/out" 2> "$T/err")
  rc=$?
  if [ -f "$F/ran" ]; then
    passed || l18="${l18}printf failed on call $k after its output and the guard exited $rc; "
  else
    refused || l18="${l18}printf made no call $k and the guard exited $rc; "
  fi
done
if [ -z "$l18" ]; then ok "L18 a printf that fails after printing output makes the guard pass in silence"
else fail "L18 $l18"
fi

# L19: JSON whitespace outside the strings (space, tab, line feed, carriage
# return) never changes the verdict: a whole object over the existing log is
# refused when it is indented over several lines, with LF or with CRLF line
# ends, with a line break after its last brace, and with a space and a tab
# before its first brace. Each shape is a printf format with %s for the path:
# \t, \r and \n in the format are the real bytes, \\n is a JSON escape.
l19=""
for fmt in \
  '{\n  "tool_name": "Write",\n  "tool_input": {\n    "file_path": "%s",\n    "content": "## [10:00] x\\n"\n  }\n}' \
  '{\r\n\t"tool_name" :\t"Write",\r\n\t"tool_input": {\r\n\t\t"file_path": "%s",\r\n\t\t"content": "x"\r\n\t}\r\n}\r\n' \
  '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}\n' \
  '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}\r\n' \
  ' \t{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}' \
  '{ "tool_name" : "Write" , "tool_input" : { "file_path" : "%s" , "content" : "x" } } \t\r\n'; do
  printf "$fmt" "$C/memory/$LOG" > "$T/in"
  run_guard "$C"
  refused || l19="${l19}[hex $(od -An -tx1 < "$T/in" | tr -s ' \n' ' ' | cut -c1-90)...] exit $rc; "
done
if [ -z "$l19" ]; then ok "L19 a whole object with JSON whitespace outside its strings is refused"
else fail "L19 $l19"
fi

# L20: the kind of a bracket decides alone. Each payload opens and closes the
# same number of brackets, but one closes with the wrong kind, so it is not
# one whole object and passes; a string left open after the object closed
# passes too.
l20=""
h20='{"tool_name":"Write","tool_input":{"file_path":"'"$C/memory/$LOG"'","content":'
for bad in "$h20\"abc\"]}" "$h20[\"abc\"}]}" "$h20{\"a\":1]}}" "$h20\"abc\"}}\"tail" \
  "$h20\"abc\"}} \"tail"; do
  printf '%s' "$bad" > "$T/in"
  run_guard "$C"
  passed || l20="${l20}[$bad] exit $rc; "
done
if [ -z "$l20" ]; then ok "L20 a bracket of the wrong kind or a string left open after the object passes"
else fail "L20 $l20"
fi

# L21: a string glued to the object, before its first brace or after its
# last one, with or without a space between them, is text outside the
# object, so the payload is not one whole object and passes in silence.
l21=""
w21="$h20\"abc\"}}"
for glued in "\"head\"$w21" "\"head\" $w21" "$w21\"tail\"" "$w21 \"tail\""; do
  printf '%s' "$glued" > "$T/in"
  run_guard "$C"
  passed || l21="${l21}[$glued] exit $rc; "
done
if [ -z "$l21" ]; then ok "L21 a string glued before or after the object passes in silence"
else fail "L21 $l21"
fi

# L22: the guard checks the structure of the payload, not the whole JSON
# grammar, because it reads only three string fields. A payload whose
# structure is whole (strings closed, brackets nested by kind, one object
# with nothing around it) over the existing log is refused even when its
# content holds an invalid escape, or a comma is missing between two pairs.
l22=""
for gram in "$h20\"\\q\"}}" "$h20\"a\\u12zz\"}}" "$h20\"x\" \"more\":\"y\"}}"; do
  printf '%s' "$gram" > "$T/in"
  run_guard "$C"
  refused || l22="${l22}[$gram] exit $rc; "
done
if [ -z "$l22" ]; then ok "L22 a whole structure with an invalid escape or a missing comma is refused"
else fail "L22 $l22"
fi

rm -rf "$T"
[ "$failures" -eq 0 ] || exit 1
exit 0
