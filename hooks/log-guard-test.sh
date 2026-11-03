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
#       "~/") are refused; spellings of another file pass
#   L16 a command that fails after printing output makes the guard pass
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

rm -rf "$T"
[ "$failures" -eq 0 ] || exit 1
exit 0
