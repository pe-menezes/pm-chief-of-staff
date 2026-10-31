#!/bin/sh
# Size gate for pm-chief-of-staff: at the end of a turn, hands the turn back
# to the agent once when it made the manual (AGENTS.md plus CLAUDE.md) or
# CRITICAL_FACTS.md grow and end above its cap, with the curation to do.
# A turn that does not make a measured file grow passes in silence.
# Events: the first argument is the event, prompt on UserPromptSubmit and
# stop on Stop; the second is the runtime marker, codex in the Codex
# registration (.codex-plugin/plugin.json), absent in the Claude one
# (hooks/hooks.json), as in boot-memory.sh.
# prompt: records the sizes at the start of the turn, in one file per
# session (session_id of the input JSON) under the hook's own folder in
# CLAUDE_PLUGIN_DATA, with the project root. Its stdout is always empty and
# its exit always 0: both runtimes put the stdout of this event into the
# context, and exit 2 on this event drops the person's prompt.
# stop: compares the end of the turn with that record, decides, then
# records the end, which is the start of the next turn when it is born
# without a prompt (a background task notification, for example). Its
# stdout is always one JSON object, {} on a pass and on any internal
# failure, and its exit always 0, never 2.
# Block shape: Claude Code takes hookSpecificOutput.additionalContext on
# Stop, shown as hook feedback; Codex takes decision block with a reason.
# Both go through stop_hook_active, so a turn is handed back at most once.
# Semantics: a measured file blocks when it grew in the turn (end above
# start) and ended above its cap, whether it crossed the cap in this turn or
# was already above it. Not growing, or ending at or below the cap, passes.
# Measure in bytes (wc -c), a missing file being 0. The manual is AGENTS.md
# plus CLAUDE.md against 13000; CRITICAL_FACTS.md against 3900. With the
# memoria-agente engine alive in the folder (same proof as boot-memory.sh,
# only without the codex marker), CRITICAL_FACTS.md belongs to the engine
# and is not measured; the manual still is.
# Root and gate are the ones of boot-memory.sh, duplicated on purpose
# because that hook writes nothing and does not change here;
# hooks/size-gate-test.sh proves both decide the same over generated folder
# shapes.
# State: only inside $CLAUDE_PLUGIN_DATA/size-gate, never created above it.
# Records are written atomically (temporary file in the same folder, then
# mv), and records older than 30 days leave on the prompt: only regular
# files with the hook's name pattern, in its own folder, links not followed.
# The message is fixed English text with numbers only: no path, no file
# content, so the JSON never depends on escaping outside text.
event="${1:-}"
runtime="${2:-claude}"

MANUAL_CAP=13000
CF_CAP=3900
MANUAL_TARGET=10000
CF_TARGET=3000
NL='
'
# A space and a tab.
BLANKS=' 	'

# Pattern matching: bracket expressions list their characters one by one,
# never as a range, because the /bin/sh of macOS (bash 3.2) matches a range
# by the locale's collation, where letters like e acute fall inside A-Z.

# is_num VALUE: digits only, no leading zero, at most 9 digits, so it is safe
# in $((...)), where a bad operand ends the whole shell.
is_num() {
  case "$1" in ''|*[!0123456789]*|0?*|??????????*) return 1 ;; esac
  return 0
}

# size_of FILE: sets sz to the size of FILE in bytes, 0 when it is not a
# regular file. Returns 1 when wc fails, even after printing a number, or
# gives no number. The blanks around the count leave by parameter
# expansion, so no second process can hide the status of wc.
size_of() {
  sz=0
  [ -f "$1" ] || return 0
  sz=$(LC_ALL=C wc -c < "$1" 2>/dev/null) || return 1
  sz=${sz#"${sz%%[!"$BLANKS"]*}"}
  sz=${sz%"${sz##*[!"$BLANKS"]}"}
  is_num "$sz"
}

# measure: sets manual and cf (cf is - when the engine owns it). Returns 1
# on an internal failure.
measure() {
  size_of AGENTS.md || return 1
  a=$sz
  size_of CLAUDE.md || return 1
  manual=$((a + sz))
  cf=-
  if [ "$engine" = no ]; then
    size_of CRITICAL_FACTS.md || return 1
    cf=$sz
  fi
  return 0
}

# json_field KEY TYPE: the value of the first "KEY" : value pair of the
# payload, with any whitespace around the colon. A key inside a string value
# never matches, because JSON escapes its quotes. TYPE string: prints the
# content of a quoted string, and nothing when the value is not a string
# (null, a number, true, an object). TYPE bool: prints true or false only
# when the value is that literal followed by a comma or the closing brace,
# and nothing for any other value or a truncated payload. Prints nothing
# when the key is missing.
json_field() {
  printf '%s' "$payload" | LC_ALL=C tr '\n\r\t' '   ' 2>/dev/null \
    | LC_ALL=C awk -v k="$1" -v t="$2" '
      { s = s $0 }
      END {
        if (!match(s, "\"" k "\"[ ]*:[ ]*")) exit 0
        r = substr(s, RSTART + RLENGTH)
        if (t == "string") {
          if (substr(r, 1, 1) != "\"") exit 0
          r = substr(r, 2)
          i = index(r, "\"")
          if (i == 0) exit 0
          print substr(r, 1, i - 1)
        } else if (t == "bool") {
          if (match(r, /^true[ ]*[,}]/)) print "true"
          else if (match(r, /^false[ ]*[,}]/)) print "false"
        }
      }' 2>/dev/null
}

# valid_sid VALUE: only the letters A to Z and a to z, the digits, dot,
# underscore and hyphen, not starting with a dot, 1 to 128 characters.
valid_sid() {
  case "$1" in
    ''|.*|*[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-]*) return 1 ;;
  esac
  [ "${#1}" -le 128 ]
}

# drop_record: removes the record of this session, best effort; rm removes
# a link itself, never its target, and leaves a folder in place. Called on
# any failure after the record path is known, so no later turn compares
# with an old start.
drop_record() {
  rm -f -- "$rec" 2>/dev/null
  return 0
}

# write_record: the record of this session, atomically. Line 1 holds the
# sizes, the rest is the root. Returns 1 on any failure, leaving no
# temporary file behind.
write_record() {
  tmp="$sd/turn-$sid.state.tmp.$$"
  rm -f -- "$tmp" 2>/dev/null
  [ -e "$tmp" ] && return 1
  if ! (set -C; printf 'size-gate 1 %s %s\n%s\n' "$manual" "$cf" "$root" > "$tmp") 2>/dev/null; then
    rm -f -- "$tmp" 2>/dev/null
    return 1
  fi
  if [ -d "$rec" ] || ! mv -f -- "$tmp" "$rec" 2>/dev/null; then
    rm -f -- "$tmp" 2>/dev/null
    return 1
  fi
  return 0
}

# message: the curation request for the files in grew_manual and grew_cf.
message() {
  msg="Size gate (pm-chief-of-staff): a file loaded in almost every turn grew in this turn and ended above its cap."
  if [ "$grew_manual" = yes ]; then
    msg="$msg In this turn the manual (AGENTS.md plus CLAUDE.md) grew from $start_manual to $manual bytes; its cap is $MANUAL_CAP bytes and the close-week curation aims at about $MANUAL_TARGET."
  fi
  if [ "$grew_cf" = yes ]; then
    msg="$msg In this turn CRITICAL_FACTS.md grew from $start_cf to $cf bytes; its cap is $CF_CAP bytes and the close-week curation aims at about $CF_TARGET."
  fi
  msg="$msg Before ending the turn, curate in three buckets."
  if [ "$grew_manual" = yes ]; then
    msg="$msg Manual: (1) consolidate: remove a line that repeats another, or that CRITICAL_FACTS.md, the navigation file, a rule or another repository already carries; (2) move: what does not apply in almost every turn goes to the skill that owns it, a module in .claude/skills/_shared/, a rule with paths: or the navigation file, leaving at most a one-line pointer; (3) deleting a rule is the person's decision: show them the list with the reason for each item, and delete none on your own."
  fi
  if [ "$grew_cf" = yes ]; then
    msg="$msg CRITICAL_FACTS.md: (1) consolidate: remove a fact that repeats another, or that the manual, the navigation file or a rule already carries; (2) move: an event that no longer holds goes to the log or to its hub, and a resolved priority leaves; (3) deleting a priority is the person's decision: show them the list with the reason for each item, and delete none on your own."
  fi
  msg="$msg If the growth was intentional, say why in one line and end the turn."
}

# gate: the whole hook. Sets result (the stop's JSON). Returns 1 on any
# internal failure; the caller then prints the safe default.
gate() {
  result='{}'
  case "$event" in prompt|stop) ;; *) return 0 ;; esac
  # No pathname expansion anywhere: record fields are split with set --.
  set -f

  # Project root, as in boot-memory.sh: CLAUDE_PROJECT_DIR when it is a
  # directory, else the cwd; CDPATH dropped and the cd writes nothing.
  unset CDPATH
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR" ]; then
    cd -- "$CLAUDE_PROJECT_DIR" >/dev/null 2>&1 || return 0
  fi
  root=$(pwd 2>/dev/null)
  [ -n "$root" ] || return 0

  # Chief of Staff gate, as in boot-memory.sh.
  [ -f CRITICAL_FACTS.md ] || return 0
  [ -f CLAUDE.md ] || { [ -f AGENTS.md ] && { [ -f navigation.md ] || [ -f navegacao.md ]; }; } || return 0

  # Session and state folder. Nothing is written unless all of these hold.
  payload=$(cat 2>/dev/null)
  # session_id counts only as a JSON string.
  sid=$(json_field session_id string)
  valid_sid "$sid" || return 0
  data="${CLAUDE_PLUGIN_DATA:-}"
  case "$data" in /*) ;; *) return 0 ;; esac
  [ -d "$data" ] && [ ! -L "$data/size-gate" ] || return 0
  sd="$data/size-gate"
  if [ ! -d "$sd" ]; then
    # A failed mkdir may have lost a race with another session that created
    # the folder: the check below decides, not the status of mkdir.
    mkdir -- "$sd" 2>/dev/null
  fi
  [ -d "$sd" ] && [ ! -L "$sd" ] && [ -w "$sd" ] || return 0
  rec="$sd/turn-$sid.state"

  # Live memoria-agente engine, as in boot-memory.sh (only without codex).
  engine=no
  host_dir=$(uname -n 2>/dev/null | LC_ALL=C cut -c1-64 2>/dev/null \
    | LC_ALL=C tr -c 'A-Za-z0-9._\n-' '-' 2>/dev/null \
    | LC_ALL=C sed 's/^\.*//' 2>/dev/null | LC_ALL=C cut -c1-64 2>/dev/null)
  [ -n "$host_dir" ] || host_dir=sem-host
  if [ "$runtime" != codex ] && [ -f .claude/memoria-config.json ] \
    && find ".claude/data/sensor-efeito/$host_dir" -mindepth 1 -maxdepth 1 -type f -name '*.jsonl' -mtime -2 2>/dev/null | grep -q .; then
    engine=yes
  fi

  measure || { drop_record; return 1; }

  if [ "$event" = prompt ]; then
    # Old records leave: regular files with the hook's names, in its own
    # folder only; find does not follow links by default.
    LC_ALL=C find "$sd" -mindepth 1 -maxdepth 1 -type f \
      \( -name 'turn-*.state' -o -name 'turn-*.state.tmp.*' \) -mtime +30 \
      -exec rm -f -- {} + 2>/dev/null
    write_record || { drop_record; return 1; }
    return 0
  fi

  # stop: read the start of the turn before overwriting it.
  start_manual=""
  start_cf=""
  if [ -f "$rec" ] && [ ! -L "$rec" ]; then
    saved=$(cat -- "$rec" 2>/dev/null; printf .)
    saved=${saved%.}
    head=${saved%%"$NL"*}
    rest=${saved#*"$NL"}
    if [ "$rest" = "$root$NL" ]; then
      set -- $head
      # The record holds whole or not at all: one field out of form and
      # there is no start.
      if [ "$#" -eq 4 ] && [ "$1" = size-gate ] && [ "$2" = 1 ] \
        && is_num "$3" && { is_num "$4" || [ "$4" = - ]; }; then
        start_manual=$3
        start_cf=$4
      fi
    fi
  fi

  # stop_hook_active counts only as true or false; any other form (missing,
  # truncated, another value) never blocks.
  active=$(json_field stop_hook_active bool)
  grew_manual=no
  grew_cf=no
  if [ "$active" = false ] && [ -n "$start_manual" ]; then
    if [ "$manual" -gt "$start_manual" ] && [ "$manual" -gt "$MANUAL_CAP" ]; then
      grew_manual=yes
    fi
    if [ "$cf" != - ] && [ -n "$start_cf" ] && [ "$start_cf" != - ] \
      && [ "$cf" -gt "$start_cf" ] && [ "$cf" -gt "$CF_CAP" ]; then
      grew_cf=yes
    fi
  fi

  # The end of this turn is the start of the next one.
  write_record || { drop_record; return 1; }

  if [ "$grew_manual" = yes ] || [ "$grew_cf" = yes ]; then
    message
    if [ "$runtime" = codex ]; then
      result="{\"decision\":\"block\",\"reason\":\"$msg\"}"
    else
      result="{\"hookSpecificOutput\":{\"hookEventName\":\"Stop\",\"additionalContext\":\"$msg\"}}"
    fi
  fi
  return 0
}

# The whole hook runs with its stdout and stderr away from the agent; only
# the result built from fixed text reaches stdout.
result='{}'
if ! gate >/dev/null 2>&1; then
  result='{}'
fi
if [ "$event" = stop ]; then
  printf '%s' "$result"
fi
exit 0
