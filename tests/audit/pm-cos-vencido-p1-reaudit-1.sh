#!/bin/sh
# Probes from reaudit 1 of the overdue-events front, part 1 (repair of the
# three defects of the Codex review: equivalent paths through the log guard,
# CommonMark fences in the overdue mark, fail-open on a command that fails
# after printing output). Behavior only, pinned by content.
# Run by hand: sh tests/audit/pm-cos-vencido-p1-reaudit-1.sh < /dev/null
# Every case works in folders under one mktemp -d, removed at the end.
# CDPATH and CLAUDE_PROJECT_DIR are dropped. "Today" comes from a fake date
# in front of PATH; no case reads the clock.
# Cases:
# R1 the review's exact C1 payloads (memory/./ and memory// over an existing
#    log, with only cwd, tool_name and tool_input) are refused with exit 2
#    and the fixed message, under sh and, when present, /bin/dash.
# R2 a Chief of Staff in a real-looking folder (spaces, "~" inside a folder
#    name, as in an iCloud vault): an equivalent spelling of the log is
#    refused; equivalent spellings of a new log, of a file of a sibling
#    folder that is not a Chief of Staff, and of a non-log file pass.
# R3 a relative file_path whose first folder name starts with "~" (not
#    "~/") resolves against the payload cwd, as Claude Code 2.1.309 writes
#    it, so the existing log under it is refused.
# R4 the review's exact C3 injections: cat or awk redefined as a shell
#    function that runs the real command and returns 1 (and awk returning
#    141, as a broken pipe does) make the guard pass in silence; under sh
#    and, when present, /bin/dash.
# R8 a "~/" path with a HOME that is not absolute passes: the HOME is never
#    read from the root.
# R5 the review's exact C2 input through the boot: the line inside the
#    4-backtick fence is not marked, the line after it is.
# R6 a CRITICAL_FACTS.md whose only past-dated event lines sit inside fences
#    (long fence with a short run inside, a fence with an info string inside
#    another, tildes, a fence left open to the end) carries no mark and no
#    fixed line, every line as on disk.
# R7 a closing run may sit up to 3 spaces in, and a run 4 spaces in does not
#    close.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

unset CDPATH
unset CLAUDE_PROJECT_DIR
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
GUARD="$ROOT/hooks/log-guard.sh"
BOOT="$ROOT/hooks/boot-memory.sh"
MSG="Log guard (pm-chief-of-staff): this Write would replace a day's log (memory/YYYY-MM-DD.md) that already exists and is not empty. The log only grows: add the new entry with Edit, keeping the entries already in it."
NOTE="Lines marked OVERDUE: the event date has passed, and the outcome is in the log or the source."
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

# cos DIR: a Chief of Staff (CLAUDE.md layout) in DIR with a non-empty log.
cos() {
  mkdir -p "$1/memory"
  echo manual > "$1/CLAUDE.md"
  echo facts > "$1/CRITICAL_FACTS.md"
  printf '## [08:00] First entry\nbody\n' > "$1/memory/$LOG"
}

# review_payload CWD PATH: the Codex review's payload shape.
review_payload() {
  printf '{"cwd":"%s","tool_name":"Write","tool_input":{"file_path":"%s","content":"new"}}' "$1" "$2" > "$work/in"
}

# guard SHELL HOOK_CWD [PREFIX]: runs the guard on $work/in; with PREFIX,
# the guard is sourced by SHELL after that shell code. Sets rc.
guard() {
  if [ -n "$3" ]; then
    (cd "$2" && "$1" -c "$3 . \"$GUARD\"" < "$work/in" > "$work/out" 2> "$work/err")
  else
    (cd "$2" && "$1" "$GUARD" < "$work/in" > "$work/out" 2> "$work/err")
  fi
  rc=$?
}
refused() { [ "$rc" -eq 2 ] && [ ! -s "$work/out" ] && cmp -s "$work/err" "$work/msg"; }
passed() { [ "$rc" -eq 0 ] && [ ! -s "$work/out" ] && [ ! -s "$work/err" ]; }

# R1: the review's C1 inputs.
C="$work/cos"
cos "$C"
r1=""
for s in $SHELLS; do
  for p in "memory/./$LOG" "memory//$LOG" "memory/$LOG"; do
    review_payload "$C" "$p"
    guard "$s" /
    refused || r1="${r1}$s $p exit $rc; "
  done
done
if [ -z "$r1" ]; then ok "R1 the review's memory/./ and memory// payloads are refused like the plain path ($SHELLS)"
else fail "R1 review C1 inputs" "$r1"
fi

# R2: a real-looking folder.
V="$work/Library/Mobile Documents/iCloud~md~obsidian/Documents/Vault Pessoal"
cos "$V"
mkdir -p "$V/notes" "$work/Library/Mobile Documents/iCloud~md~obsidian/Documents/plain/memory"
P="$work/Library/Mobile Documents/iCloud~md~obsidian/Documents/plain"
printf '## [08:00] not a cos\n' > "$P/memory/$LOG"
printf 'note\n' > "$V/notes/$LOG"
r2=""
for p in "memory/./$LOG" "./notes/../memory//$LOG" "$V/./memory/$LOG"; do
  review_payload "$V" "$p"
  guard sh /
  refused || r2="${r2}log $p exit $rc; "
done
for p in "memory/./2031-05-18.md" "notes/../memory/2031-05-18.md" "../plain/memory/$LOG" \
  "$V/../plain/./memory/$LOG" "notes//$LOG" "memory/../notes/$LOG" "$V/memory/./notes.md"; do
  review_payload "$V" "$p"
  guard sh /
  passed || r2="${r2}not the log $p exit $rc; "
done
if [ -z "$r2" ]; then ok "R2 in a folder with spaces and ~ inside names, only spellings of the existing log are refused"
else fail "R2 real-looking folder" "$r2"
fi

# R3: a folder whose name starts with "~", reached by a relative path.
T="$work/tilde"
cos "$T/~cos"
review_payload "$T" "~cos/memory/$LOG"
guard sh /
if refused; then ok "R3 a relative path through a folder named ~cos resolves against the cwd and is refused"
else fail "R3 relative ~cos path" "exit $rc on an existing log at $T/~cos/memory/$LOG"
fi

# R4: the review's C3 injections, the canonical overwrite otherwise refused.
r4=""
for s in $SHELLS; do
  review_payload "$C" "memory/$LOG"
  guard "$s" /
  refused || r4="${r4}$s no injection exit $rc; "
  for inj in 'cat() { command cat; return 1; };' \
    'awk() { command awk "$@"; return 1; };' \
    'awk() { command awk "$@"; return 141; };'; do
    guard "$s" / "$inj"
    passed || r4="${r4}$s [$inj] exit $rc; "
  done
done
if [ -z "$r4" ]; then ok "R4 cat or awk failing after their output make the guard pass in silence ($SHELLS)"
else fail "R4 review C3 injections" "$r4"
fi

# R8: "~/" resolves only against an absolute HOME. A HOME that names the
# Chief of Staff's parent without its leading "/" is not absolute, so the
# Write passes; read from the root, it would land on the existing log.
E="$work/elsewhere"
mkdir -p "$E"
review_payload "$E" "~/cos/memory/$LOG"
(cd "$E" && HOME="${work#/}" sh "$GUARD" < "$work/in" > "$work/out" 2> "$work/err")
rc=$?
if passed; then ok "R8 a ~/ path with a HOME that is not absolute passes, never read from the root"
else fail "R8 relative HOME" "exit $rc with HOME=${work#/}"
fi

# The boot cases: a fake date answering 2031-05-17.
FD="$work/fake-date"
mkdir -p "$FD"
printf '#!/bin/sh\ncase "$*" in\n  "+%%Y-%%m-%%d") echo 2031-05-17 ;;\n  "+%%Y-%%m-%%d %%H:%%M") echo "2031-05-17 09:30" ;;\n  *) exec /bin/date "$@" ;;\nesac\n' > "$FD/date"
chmod +x "$FD/date"
B="$work/boot"
mkdir -p "$B/memory"
echo manual > "$B/AGENTS.md"
echo nav > "$B/navigation.md"
MID=$(printf '\302\267')
boot() { (cd "$B" && PATH="$FD:$PATH" sh "$BOOT" > "$work/pack" 2>/dev/null); }
has() { grep -qxF -- "$1" "$work/pack"; }

# R5: the review's C2 input.
printf '%s\n' '````markdown' '```' '* Example (event 2031-05-16)' '````' '* Actual (event 2031-05-16)' > "$B/CRITICAL_FACTS.md"
boot
if has '* Example (event 2031-05-16)' && has "* Actual (event 2031-05-16) $MID OVERDUE 2031-05-16" \
  && [ "$(grep -c OVERDUE "$work/pack")" -eq 2 ]; then
  ok "R5 the review's fence: the example inside is not marked, the line after is"
else
  fail "R5 review C2 input" "$(grep -E 'Example|Actual' "$work/pack" | tr '\n' '|')"
fi

# R6: only fenced past events.
cat > "$B/CRITICAL_FACTS.md" <<'EOF'
* plain fact
````md
```
* ex1 (event 2031-05-01, checked 2031-05-01) -> source/a.md
```
* ex2 (evento 2031-05-02, conferido 2031-05-02) -> fonte/b.md
````
~~~~
~~~ trailing
* ex3 (event 2031-05-03)
~~~
* ex4 (event 2031-05-04)
~~~~~
   ```text
* ex5 (event 2031-05-05)
```text
* ex6 (event 2031-05-06)
EOF
boot
r6=""
grep -q OVERDUE "$work/pack" && r6="${r6}a mark or the fixed line in the pack; "
while IFS= read -r l; do
  has "$l" || r6="${r6}line changed or missing: $l; "
done < "$B/CRITICAL_FACTS.md"
if [ -z "$r6" ]; then ok "R6 a file whose past events are all fenced carries no mark and no fixed line"
else fail "R6 fenced-only file" "$r6"
fi

# R7: indentation of the closing run.
printf '%s\n' '```' '* in1 (event 2031-05-10)' '   ```' '* out1 (event 2031-05-10)' \
  '~~~' '* in2 (event 2031-05-11)' '    ~~~' '* in3 (event 2031-05-12)' '~~~' '* out2 (event 2031-05-11)' > "$B/CRITICAL_FACTS.md"
boot
if has '* in1 (event 2031-05-10)' && has '* in2 (event 2031-05-11)' && has '* in3 (event 2031-05-12)' \
  && has "* out1 (event 2031-05-10) $MID OVERDUE 2031-05-10" && has "* out2 (event 2031-05-11) $MID OVERDUE 2031-05-11" \
  && has "$NOTE"; then
  ok "R7 a closing run 3 spaces in closes, 4 spaces in does not"
else
  fail "R7 closing indentation" "$(grep -E '\* (in|out)[0-9]' "$work/pack" | tr '\n' '|')"
fi

rm -rf "$work"
[ "$failures" -eq 0 ] || exit 1
exit 0
