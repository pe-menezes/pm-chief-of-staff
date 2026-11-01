#!/bin/sh
# Probes from reaudit 2 of part 2 of the destination yardstick front (the
# yardstick in the size gate message, fix round 2). Behavior only, pinned by
# content.
# Run by hand: sh tests/audit/yardstick-p2-reaudit-2.sh < /dev/null
# Every case works in folders under one mktemp -d, removed at the end.
# Nothing inherited from the caller decides where the hook looks or writes:
# CDPATH, CLAUDE_PROJECT_DIR and CLAUDE_PLUGIN_DATA are dropped. Each hook run
# goes through every shell found among /bin/sh and /bin/dash, in both
# runtimes (no marker, and the codex marker).
# Cases:
# YQ3 when the manual grows above its cap, the move bucket of the block
#     message keeps a line a script can fail in the manual until the person
#     accepts the check that replaces it: the script clause (from "propose to
#     the person" up to the first destination, the skill that owns it) ties
#     the line to the person's acceptance ("accept" with until, only once,
#     only when or only after, so a rewording that keeps the rule passes).
#     Without it the agent may take the line out now and only propose the
#     check, and a refused proposal leaves a rule deleted without the
#     person's decision, against bucket (3) of the same message (Y3 in
#     size-gate-p2.sh pins that bucket).
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

[ -f "$HOOK" ] || { echo "FAIL  missing $HOOK"; exit 1; }

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi
work=$(cd "$work" && pwd -P)

SHELLS=""
for s in /bin/sh /bin/dash; do [ -x "$s" ] && SHELLS="$SHELLS $s"; done

# json_str FILE KEY: the string at the dotted KEY, empty with exit 1 when
# missing or not a string.
if command -v node >/dev/null 2>&1; then
  json_str() {
    node -e 'let v=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));for(const k of process.argv[2].split("."))v=v==null?v:v[k];if(typeof v!=="string")process.exit(1);process.stdout.write(v)' "$1" "$2" < /dev/null 2>/dev/null
  }
elif command -v plutil >/dev/null 2>&1; then
  json_str() {
    plutil -extract "$2" raw -o - "$1" < /dev/null 2>/dev/null
  }
else
  echo "FAIL  neither node nor plutil to read JSON"
  exit 1
fi

# fill FILE BYTES: FILE with exactly BYTES bytes.
fill() {
  LC_ALL=C awk -v n="$2" 'BEGIN { while (n >= 100) { printf "%099d\n", 0; n -= 100 } while (n-- > 0) printf "x" }' > "$1"
}

# has TEXT A B C ...: prints the anchors missing from TEXT.
has() {
  t=$1
  shift
  for a in "$@"; do
    case "$t" in
      *"$a"*) ;;
      *) printf ' [missing: %s]' "$a" ;;
    esac
  done
}

PROPOSE="propose to the person"
FIRST_DEST="skill that owns"
ACCEPT="accept"

n_case=0
for sh in $SHELLS; do
  for rt in claude codex; do
    mk=""
    [ "$rt" = codex ] && mk=codex
    n_case=$((n_case + 1))
    W="$work/c$n_case/work"
    D="$work/c$n_case/data"
    mkdir -p "$W" "$D"
    printf '@AGENTS.md\n' > "$W/CLAUDE.md"
    fill "$W/AGENTS.md" 1989
    echo "navigation" > "$W/navigation.md"
    fill "$W/CRITICAL_FACTS.md" 1000
    why=""
    printf '{"session_id":"%s","hook_event_name":"UserPromptSubmit","prompt":"x"}' "$SID" > "$work/in"
    ( cd "$W" && CLAUDE_PLUGIN_DATA="$D" && export CLAUDE_PLUGIN_DATA && exec "$sh" "$HOOK" prompt ${mk:+"$mk"} ) < "$work/in" > "$work/out" 2>/dev/null
    fill "$W/AGENTS.md" 13989
    printf '{"session_id":"%s","hook_event_name":"Stop","stop_hook_active":false,"last_assistant_message":"done"}' "$SID" > "$work/in"
    ( cd "$W" && CLAUDE_PLUGIN_DATA="$D" && export CLAUDE_PLUGIN_DATA && exec "$sh" "$HOOK" stop ${mk:+"$mk"} ) < "$work/in" > "$work/out" 2>/dev/null
    if [ "$rt" = codex ]; then
      m=$(json_str "$work/out" reason)
    else
      m=$(json_str "$work/out" hookSpecificOutput.additionalContext)
    fi
    if [ -z "$m" ]; then
      why="$why [no block: $(cat "$work/out")]"
    else
      # The manual's buckets: from "Manual: (1) consolidate" on.
      man=${m#*"Manual: (1) consolidate"}
      # Bucket 2: from "(2) move" to "(3) deleting a rule".
      b2=${man#*"(2) move"}
      b2=${b2%%"(3) deleting a rule"*}
      if [ "$man" = "$m" ] || [ "$b2" = "$man" ] || [ -z "$b2" ]; then
        why="$why [move bucket of the manual not found: $m]"
      else
        # The script clause: from the proposal to the first destination.
        cl=${b2#*"$PROPOSE"}
        cl=${cl%%"$FIRST_DEST"*}
        if [ "$cl" = "$b2" ]; then
          why="$why [script clause not found: no $PROPOSE in the move bucket: $b2]"
        elif [ "${b2%%"$FIRST_DEST"*}" = "$b2" ]; then
          why="$why [no $FIRST_DEST in the move bucket: $b2]"
        else
          # The clause ties the line to the person's acceptance: "accept",
          # with a word that makes it a condition (until, only once, only
          # when, only after), so a rewording that keeps the rule passes.
          r=$(has "$cl" "$ACCEPT")
          case "$cl" in
            *"until "*|*"only once "*|*"only when "*|*"only after "*) ;;
            *) r="$r [no condition on the line (until, only once, only when, only after)]" ;;
          esac
          [ -z "$r" ] || why="$why [script clause:$r: $cl]"
        fi
      fi
    fi
    if [ -z "$why" ]; then ok "YQ3 a line a script can fail stays in the manual until the person accepts its check ($sh, $rt)"
    else fail "YQ3 a line a script can fail stays in the manual until the person accepts its check ($sh, $rt)" "$why"; fi
  done
done

chmod -R u+w "$work" 2>/dev/null
rm -rf "$work"
[ "$failures" -eq 0 ] || exit 1
exit 0
