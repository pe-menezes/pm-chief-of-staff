#!/bin/sh
# Probes from reaudit 1 of the stop-size-gate front, part 1 (hooks/size-gate.sh,
# fix round 1). Behavior only, pinned by content.
# Run by hand: sh tests/audit/size-gate-p1-reaudit-1.sh < /dev/null
# Every case works in folders under one mktemp -d, removed at the end.
# CDPATH, CLAUDE_PROJECT_DIR and CLAUDE_PLUGIN_DATA are dropped. Each hook run
# goes through every shell found among /bin/sh and /bin/dash. Fake tools
# never read stdin. No case reads the clock.
# Cases:
# Y1 a failure that drops the session's record (wc or mv failing, at the
#    prompt and at the stop) when the record path is a link to a file
#    outside the hook's folder: the target keeps its bytes, nothing else
#    appears next to it, the prompt stays silent and the stop prints {}.
# Y2 the same failures when the record path is a folder holding a file:
#    the folder and the file stay.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

unset CDPATH
unset CLAUDE_PROJECT_DIR
unset CLAUDE_PLUGIN_DATA
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
HOOK="$ROOT/hooks/size-gate.sh"
SID=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi
work=$(cd "$work" && pwd -P)

SHELLS=""
for s in /bin/sh /bin/dash; do [ -x "$s" ] && SHELLS="$SHELLS $s"; done

# Fakes: wc and mv that fail with no stdout.
FK="$work/fakes"
mkdir -p "$FK/wc" "$FK/mv"
printf '#!/bin/sh\necho "fake wc: error" >&2\nexit 1\n' > "$FK/wc/wc"
printf '#!/bin/sh\necho "fake mv: error" >&2\nexit 1\n' > "$FK/mv/mv"
chmod +x "$FK/wc/wc" "$FK/mv/mv"

# fill FILE BYTES: FILE with exactly BYTES bytes.
fill() {
  LC_ALL=C awk -v n="$2" 'BEGIN { while (n >= 100) { printf "%099d\n", 0; n -= 100 } while (n-- > 0) printf "x" }' > "$1"
}

n_case=0
# new_case: C (case folder), W (the person's folder: bridge, manual,
# navigation, CRITICAL_FACTS.md), D (plugin data folder), SD (the hook's own
# folder, created), REC (this session's record path), OUT (a folder outside
# the plugin data folder).
new_case() {
  n_case=$((n_case + 1))
  C="$work/c$n_case"
  W="$C/work"
  D="$C/data"
  SD="$D/size-gate"
  REC="$SD/turn-$SID.state"
  OUT="$C/outside"
  mkdir -p "$W" "$SD" "$OUT"
  printf '@AGENTS.md\n' > "$W/CLAUDE.md"
  fill "$W/AGENTS.md" 1989
  echo "navigation" > "$W/navigation.md"
  fill "$W/CRITICAL_FACTS.md" 1000
}

# run SHELL EVENT FAKE: the hook in W, with the fake tool first on the PATH.
run() {
  if [ "$2" = prompt ]; then
    printf '{"session_id":"%s","hook_event_name":"UserPromptSubmit","prompt":"x"}' "$SID" > "$work/in"
  else
    printf '{"session_id":"%s","hook_event_name":"Stop","stop_hook_active":false,"last_assistant_message":"done"}' "$SID" > "$work/in"
  fi
  (
    cd "$W" || exit 97
    CLAUDE_PLUGIN_DATA="$D"
    export CLAUDE_PLUGIN_DATA
    PATH="$FK/$3:$PATH"
    exec "$1" "$HOOK" "$2"
  ) < "$work/in" > "$work/out" 2>/dev/null
  rc=$?
}
# output_ok EVENT: prompt silent with exit 0; stop {} with exit 0.
output_ok() {
  [ "$rc" -eq 0 ] || return 1
  if [ "$1" = prompt ]; then [ ! -s "$work/out" ]; else [ "$(cat "$work/out")" = "{}" ]; fi
}

# Y1: the record path is a link to a file outside.
for sh in $SHELLS; do
  for ev in prompt stop; do
    for tool in wc mv; do
      name="Y1 $tool failing at the $ev, record a link outside ($sh)"
      new_case
      printf 'size-gate 1 12000 1000\n%s\n' "$W" > "$OUT/target.state"
      ln -s "$OUT/target.state" "$REC"
      want=$(od -An -tx1 "$OUT/target.state")
      run "$sh" "$ev" "$tool"
      why=""
      output_ok "$ev" || why="$why output (exit $rc, stdout: $(cat "$work/out"));"
      [ -f "$OUT/target.state" ] && [ ! -L "$OUT/target.state" ] || why="$why the target left;"
      [ "$(od -An -tx1 "$OUT/target.state" 2>/dev/null)" = "$want" ] || why="$why the target changed;"
      [ "$(ls -A "$OUT")" = "target.state" ] || why="$why outside now holds: $(ls -A "$OUT" | tr '\n' ' ');"
      if [ -z "$why" ]; then ok "$name"; else fail "$name" "$why"; fi
    done
  done
done

# Y2: the record path is a folder holding a file.
for sh in $SHELLS; do
  for ev in prompt stop; do
    for tool in wc mv; do
      name="Y2 $tool failing at the $ev, record path a folder ($sh)"
      new_case
      mkdir "$REC"
      echo keep > "$REC/keep"
      run "$sh" "$ev" "$tool"
      why=""
      output_ok "$ev" || why="$why output (exit $rc, stdout: $(cat "$work/out"));"
      [ -d "$REC" ] && [ ! -L "$REC" ] || why="$why the folder left;"
      [ "$(cat "$REC/keep" 2>/dev/null)" = keep ] || why="$why the file inside left or changed;"
      if [ -z "$why" ]; then ok "$name"; else fail "$name" "$why"; fi
    done
  done
done

rm -rf "$work"
[ "$failures" -eq 0 ] || exit 1
exit 0
