#!/bin/sh
# Probes from the audit of the stop-size-gate front, part 2 (the docs of
# hooks/size-gate.sh). Behavior only, pinned by content: each case holds the
# hook to a sentence the README, its Portuguese mirror and the repository
# guide state about it.
# Run by hand: sh tests/audit/size-gate-p2.sh < /dev/null
# Every case works in folders under one mktemp -d, removed at the end.
# Nothing inherited from the caller decides where the hook looks or writes:
# CDPATH, CLAUDE_PROJECT_DIR and CLAUDE_PLUGIN_DATA are dropped. Each hook
# run goes through every shell found among /bin/sh and /bin/dash, in both
# runtimes (no marker, and the codex marker).
# Cases:
# Y1 an edit made between turns is not judged: after a turn closes, the
#    manual and CRITICAL_FACTS.md grow above their caps outside any turn;
#    the next turn, with a prompt and no change, passes; a turn that then
#    grows the manual blocks from the size the prompt recorded.
# Y2 the person's folder is left as it was (paths and contents) through a
#    prompt, a blocking stop and the continuation stop; the plugin data
#    folder holds only the hook's folder with one record for the session,
#    whose two lines are the sizes and the folder path, and nothing of the
#    prompt text.
# Y3 the block message carries the curation in three buckets for each file
#    that grew (consolidate, move, and deletion as the person's decision,
#    with none deleted by the agent) and the one-line exit for intentional
#    growth; a bucket list appears only for a file that grew.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

unset CDPATH
unset CLAUDE_PROJECT_DIR
unset CLAUDE_PLUGIN_DATA
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
HOOK="$ROOT/hooks/size-gate.sh"
SID=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee
MANUAL_LABEL="the manual (AGENTS.md plus CLAUDE.md)"
CF_LABEL="CRITICAL_FACTS.md"
MARKER="PROMPT-TEXT-MARKER-Y2"
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

n_case=0
# new_case: C (case folder), W (the person's folder, new layout with the
# 11-byte bridge, manual 2000 and CRITICAL_FACTS.md 1000), D (plugin data
# folder, created empty) and SD (the hook's own folder).
new_case() {
  n_case=$((n_case + 1))
  C="$work/c$n_case"
  W="$C/work"
  D="$C/data"
  SD="$D/size-gate"
  mkdir -p "$W" "$D"
  printf '@AGENTS.md\n' > "$W/CLAUDE.md"
  fill "$W/AGENTS.md" 1989
  echo "navigation" > "$W/navigation.md"
  fill "$W/CRITICAL_FACTS.md" 1000
}
set_manual() { fill "$W/AGENTS.md" $(($1 - 11)); }
set_cf() { fill "$W/CRITICAL_FACTS.md" "$1"; }

prompt_in() {
  printf '{"session_id":"%s","hook_event_name":"UserPromptSubmit","prompt":"%s"}' "$SID" "${1:-x}" > "$work/in"
}
stop_in() {
  printf '{"session_id":"%s","hook_event_name":"Stop","stop_hook_active":%s,"last_assistant_message":"done"}' "$SID" "$1" > "$work/in"
}

# run SHELL EVENT [MARKER]: the hook in W with $work/in on stdin; rc and
# $work/out.
run() {
  (
    cd "$W" || exit 97
    CLAUDE_PLUGIN_DATA="$D"
    export CLAUDE_PLUGIN_DATA
    exec "$1" "$HOOK" "$2" ${3:+"$3"}
  ) < "$work/in" > "$work/out" 2>/dev/null
  rc=$?
}
silent() { [ "$rc" -eq 0 ] && [ ! -s "$work/out" ]; }
passes() { [ "$rc" -eq 0 ] && [ "$(cat "$work/out")" = "{}" ]; }

# msg_of RUNTIME: the block message of the last stop, empty when none.
msg_of() {
  if [ "$1" = codex ]; then
    [ "$(json_str "$work/out" decision)" = block ] && json_str "$work/out" reason
  else
    [ "$(json_str "$work/out" hookSpecificOutput.hookEventName)" = Stop ] \
      && json_str "$work/out" hookSpecificOutput.additionalContext
  fi
}

# listing DIR...: every path under DIR, sorted, with the type of each and
# the checksum of each regular file.
listing() {
  for d in "$@"; do
    find "$d" -print 2>/dev/null | LC_ALL=C sort | while IFS= read -r p; do
      if [ -L "$p" ]; then echo "L $p"; elif [ -d "$p" ]; then echo "d $p"; else echo "f $p $(cksum < "$p")"; fi
    done
  done
}

# ---------------------------------------------------------------- Y1
# README "an edit made outside a session is not judged": the start of a turn
# is what its prompt measured, not the end of the previous turn.
for sh in $SHELLS; do
  for rt in claude codex; do
    mk=""
    [ "$rt" = codex ] && mk=codex
    new_case
    why=""
    prompt_in; run "$sh" prompt $mk
    silent || why="first prompt not silent (exit $rc)"
    if [ -z "$why" ]; then
      stop_in false; run "$sh" stop $mk
      passes || why="first stop without change did not pass: $(cat "$work/out")"
    fi
    if [ -z "$why" ]; then
      # Outside any turn: both files grow above their caps.
      set_manual 14000
      set_cf 4500
      prompt_in; run "$sh" prompt $mk
      silent || why="second prompt not silent (exit $rc)"
    fi
    if [ -z "$why" ]; then
      stop_in false; run "$sh" stop $mk
      passes || why="the turn after an edit made between turns was judged: $(cat "$work/out")"
    fi
    if [ -z "$why" ]; then
      # Control: growth inside the next turn blocks from the prompt's size.
      prompt_in; run "$sh" prompt $mk
      set_manual 14100
      stop_in false; run "$sh" stop $mk
      m=$(msg_of "$rt")
      case "$m" in
        *"$MANUAL_LABEL grew from 14000 to 14100 bytes"*) ;;
        *) why="growth inside the turn did not block from 14000: $(cat "$work/out")" ;;
      esac
      case "$m" in
        *"$CF_LABEL grew"*) why="CRITICAL_FACTS.md did not grow in the turn and was named: $m" ;;
      esac
    fi
    if [ -z "$why" ]; then ok "Y1 an edit between turns is not judged ($sh, $rt)"
    else fail "Y1 an edit between turns is not judged ($sh, $rt)" "$why"; fi
  done
done

# ---------------------------------------------------------------- Y2
# README: one small file per session, with the sizes and the path of the
# folder, in the plugin's data folder, outside the person's folder; none of
# the scripts deletes, renames or replaces a file of the person. Guide: the
# state lives only in ${CLAUDE_PLUGIN_DATA}/size-gate.
for sh in $SHELLS; do
  for rt in claude codex; do
    mk=""
    [ "$rt" = codex ] && mk=codex
    new_case
    why=""
    before=$(listing "$W")
    prompt_in "$MARKER"; run "$sh" prompt $mk
    silent || why="prompt not silent (exit $rc)"
    [ -z "$why" ] && [ "$before" != "$(listing "$W")" ] && why="the prompt changed the person's folder"
    if [ -z "$why" ]; then
      set_manual 14000
      set_cf 4500
      before=$(listing "$W")
      stop_in false; run "$sh" stop $mk
      [ -n "$(msg_of "$rt")" ] || why="the stop did not block: $(cat "$work/out")"
    fi
    if [ -z "$why" ]; then
      stop_in true; run "$sh" stop $mk
      passes || why="the continuation stop did not pass: $(cat "$work/out")"
    fi
    [ -z "$why" ] && [ "$before" != "$(listing "$W")" ] && why="the stops changed the person's folder"
    if [ -z "$why" ]; then
      expect=$(printf 'd %s\nd %s\nf %s/turn-%s.state' "$D" "$SD" "$SD" "$SID")
      got=$(listing "$D" | sed 's/ [0-9][0-9]* [0-9][0-9]*$//')
      [ "$got" = "$expect" ] || why="the data folder holds more than the session's record:$(echo "$got" | tr '\n' ' ')"
    fi
    if [ -z "$why" ]; then
      rec="$SD/turn-$SID.state"
      lines=$(LC_ALL=C awk 'END { print NR }' "$rec")
      line2=$(sed -n 2p "$rec")
      line1=$(sed -n 1p "$rec")
      [ "$lines" = 2 ] || why="the record has $lines lines"
      [ -z "$why" ] && [ "$line2" != "$W" ] && why="line 2 of the record is not the folder path: $line2"
      if [ -z "$why" ]; then
        case " $line1 " in
          *" 14000 4500 "*) ;;
          *) why="line 1 of the record does not carry the sizes 14000 and 4500: $line1" ;;
        esac
      fi
      [ -z "$why" ] && grep -r -q "$MARKER" "$D" 2>/dev/null && why="the prompt text reached the data folder"
    fi
    if [ -z "$why" ]; then ok "Y2 the person's folder is untouched and the record holds sizes and path ($sh, $rt)"
    else fail "Y2 the person's folder is untouched and the record holds sizes and path ($sh, $rt)" "$why"; fi
  done
done

# ---------------------------------------------------------------- Y3
# README: the turn goes back with the curation in three buckets
# (consolidate, move, and deletions, which are the person's to decide), and
# the agent can answer in one line why the growth was intentional.
# y3_has MSG LABEL TEXT: appends to why when MSG lacks TEXT.
y3_has() {
  case "$1" in *"$3"*) ;; *) why="${why}missing [$2: $3]; " ;; esac
}
y3_lacks() {
  case "$1" in *"$3"*) why="${why}unexpected [$2: $3]; " ;; esac
}
for sh in $SHELLS; do
  for rt in claude codex; do
    mk=""
    [ "$rt" = codex ] && mk=codex
    for which in manual cf both; do
      new_case
      why=""
      prompt_in; run "$sh" prompt $mk
      case "$which" in
        manual) set_manual 14000 ;;
        cf) set_cf 4500 ;;
        both) set_manual 14000; set_cf 4500 ;;
      esac
      stop_in false; run "$sh" stop $mk
      m=$(msg_of "$rt")
      if [ -z "$m" ]; then
        why="no block: $(cat "$work/out")"
      else
        y3_has "$m" all "curate in three buckets"
        y3_has "$m" all "If the growth was intentional, say why in one line"
        if [ "$which" != cf ]; then
          y3_has "$m" manual "Manual: (1) consolidate"
          y3_has "$m" manual "(2) move"
          y3_has "$m" manual "(3) deleting a rule is the person's decision"
        else
          y3_lacks "$m" cf "Manual: (1)"
        fi
        if [ "$which" != manual ]; then
          y3_has "$m" cf "CRITICAL_FACTS.md: (1) consolidate"
          y3_has "$m" cf "(3) deleting a priority is the person's decision"
        else
          y3_lacks "$m" manual "CRITICAL_FACTS.md: (1)"
        fi
        y3_has "$m" all "delete none on your own"
      fi
      if [ -z "$why" ]; then ok "Y3 three buckets and the one-line exit, $which ($sh, $rt)"
      else fail "Y3 three buckets and the one-line exit, $which ($sh, $rt)" "$why"; fi
    done
  done
done

chmod -R u+w "$work" 2>/dev/null
rm -rf "$work"
[ "$failures" -eq 0 ] || exit 1
exit 0
