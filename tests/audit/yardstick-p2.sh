#!/bin/sh
# Probes from the audit of part 2 of the destination yardstick front (the
# yardstick in the size gate message). Behavior only, pinned by content.
# Run by hand: sh tests/audit/yardstick-p2.sh < /dev/null
# Every case works in folders under one mktemp -d, removed at the end.
# Nothing inherited from the caller decides where the hook looks or writes:
# CDPATH, CLAUDE_PROJECT_DIR and CLAUDE_PLUGIN_DATA are dropped. Each hook run
# goes through every shell found among /bin/sh and /bin/dash, in both
# runtimes (no marker, and the codex marker).
# Cases:
# YQ1 when the manual grows above its cap, the move bucket of the block
#     message sends what leaves the manual to the destinations of the setup
#     yardstick, in the setup's order (the skill that owns it, a module in
#     .claude/skills/_shared/, a rule with paths: plus its rules index line,
#     a skill with user-invocable: false for a rule fired by a subject, the
#     navigation file for a source address), and never tells the agent to
#     leave a pointer in the manual, which the yardstick no longer does. The
#     setup yardstick is read for the same anchors in the same order, so a
#     change on either side without the other fails here.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

unset CDPATH
unset CLAUDE_PROJECT_DIR
unset CLAUDE_PLUGIN_DATA
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
HOOK="$ROOT/hooks/size-gate.sh"
SETUP="$ROOT/skills/setup/SKILL.md"
SID=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

for f in "$HOOK" "$SETUP"; do
  [ -f "$f" ] || { echo "FAIL  missing $f"; exit 1; }
done

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

# inorder TEXT A B C ...: prints the anchors missing from TEXT or whose first
# occurrence does not come after the first occurrence of the one before.
inorder() {
  t=$1
  shift
  prev=0
  for a in "$@"; do
    rest=${t%%"$a"*}
    if [ "$rest" = "$t" ]; then printf ' [missing: %s]' "$a"; continue; fi
    p=$((${#rest} + 1))
    [ "$p" -le "$prev" ] && printf ' [out of order: %s]' "$a"
    prev=$p
  done
}

# The setup yardstick section, joined into one line.
setup_y=$(awk '/^### The 4-destination yardstick/ { on = 1; next } on && (/^#/ || /^Format of a rule file/) { exit } on' "$SETUP" | tr '\n' ' ')

# ---------------------------------------------------------------- YQ1
yq1_setup=""
[ -n "$setup_y" ] || yq1_setup=" [setup yardstick section not found]"
if [ -z "$yq1_setup" ]; then
  r=$(inorder "$setup_y" "skill that owns" ".claude/skills/_shared/" "paths:" "rules index" "user-invocable: false" "navigation")
  [ -z "$r" ] || yq1_setup=" [setup yardstick:$r]"
fi

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
    why="$yq1_setup"
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
      # The manual's move bucket: from "(2) move" to "(3) deleting a rule".
      b2=${m#*"Manual: (1) consolidate"}
      b2=${b2#*"(2) move"}
      b2=${b2%%"(3) deleting a rule"*}
      if [ "$b2" = "$m" ] || [ -z "$b2" ]; then
        why="$why [move bucket of the manual not found: $m]"
      else
        r=$(inorder "$b2" "skill that owns" ".claude/skills/_shared/" "paths:" "rules index" "user-invocable: false" "navigation")
        [ -z "$r" ] || why="$why [move bucket:$r]"
      fi
      case "$m" in
        *[Pp]ointer*) why="$why [the message still sends a pointer to the manual]" ;;
      esac
    fi
    if [ -z "$why" ]; then ok "YQ1 the manual's move bucket follows the setup yardstick, no pointer ($sh, $rt)"
    else fail "YQ1 the manual's move bucket follows the setup yardstick, no pointer ($sh, $rt)" "$why"; fi
  done
done

chmod -R u+w "$work" 2>/dev/null
rm -rf "$work"
[ "$failures" -eq 0 ] || exit 1
exit 0
