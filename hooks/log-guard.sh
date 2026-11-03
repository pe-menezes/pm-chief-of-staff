#!/bin/sh
# Log guard for pm-chief-of-staff (overdue-events spec, I3): a PreToolUse
# hook on Write. The day's log, memory/YYYY-MM-DD.md, only grows; a Write
# over one that already exists and is not empty would replace every entry
# in it, so the guard refuses it with exit 2 and a fixed English message on
# stderr, which Claude Code hands back to the agent. Edit passes, a new log
# passes, an empty log passes.
# Where: the folder that holds memory/ must be a Chief of Staff, by the same
# gate as boot-memory.sh (CRITICAL_FACTS.md together with CLAUDE.md, or
# with AGENTS.md plus navigation.md or the legacy navegacao.md), duplicated
# on purpose as size-gate.sh does; hooks/log-guard-test.sh proves both
# decide the same over every shape of those names. The gate looks at the
# folder of the file being written, so a log is guarded whatever the cwd.
# Paths: an absolute file_path is taken as it is; a relative one resolves
# against the cwd of the payload when it is an absolute folder, else the cwd
# of the hook.
# Fail-open: anything the guard cannot read for sure (no input, input that
# is not JSON, no tool_name, a path holding a JSON escape, a failing tool)
# passes, with exit 0 and nothing on stdout or stderr. The decision runs in
# a subshell whose only possible output is the word refuse; any other end,
# a crash included, passes.
# Runtime: registered only in hooks/hooks.json. Codex writes files through
# apply_patch, with no Write tool and no file_path, so the Codex manifest
# does not register it (measured on codex-cli 0.163.0-alpha.10.2).
MSG="Log guard (pm-chief-of-staff): this Write would replace a day's log (memory/YYYY-MM-DD.md) that already exists and is not empty. The log only grows: add the new entry with Edit, keeping the entries already in it."

# Pattern matching: bracket expressions list their characters one by one,
# never as a range, because the /bin/sh of macOS (bash 3.2) matches a range
# by the locale's collation.
D='[0123456789]'

# json_field KEY: the content of the first "KEY" : "string" pair of the
# payload, with any whitespace around the colon; nothing when the key is
# missing or its value is not a string. A key inside a string value never
# matches, because JSON escapes its quotes. A value holding a backslash
# comes back whole up to the next quote, and the caller refuses to read it.
json_field() {
  printf '%s' "$payload" | LC_ALL=C tr '\n\r\t' '   ' 2>/dev/null \
    | LC_ALL=C awk -v k="$1" '
      { s = s $0 }
      END {
        if (!match(s, "\"" k "\"[ ]*:[ ]*")) exit 0
        r = substr(s, RSTART + RLENGTH)
        if (substr(r, 1, 1) != "\"") exit 0
        r = substr(r, 2)
        i = index(r, "\"")
        if (i == 0) exit 0
        print substr(r, 1, i - 1)
      }' 2>/dev/null
}

# decide: prints refuse when the Write must be refused, and nothing else.
decide() {
  set -f
  unset CDPATH
  payload=$(cat 2>/dev/null)
  [ -n "$payload" ] || return 0
  tool=$(json_field tool_name)
  [ "$tool" = Write ] || return 0
  path=$(json_field file_path)
  [ -n "$path" ] || return 0
  case "$path" in *\\*) return 0 ;; esac
  case "$path" in
    /*) ;;
    *)
      base=$(json_field cwd)
      case "$base" in *\\*) base="" ;; esac
      case "$base" in /*) [ -d "$base" ] || base="" ;; *) base="" ;; esac
      [ -n "$base" ] || base=$(pwd 2>/dev/null)
      [ -n "$base" ] || return 0
      path="$base/$path"
      ;;
  esac

  # The file: memory/YYYY-MM-DD.md, a regular file that is not empty.
  name=${path##*/}
  case "$name" in $D$D$D$D-$D$D-$D$D.md) ;; *) return 0 ;; esac
  dir=${path%/*}
  [ "${dir##*/}" = memory ] || return 0
  [ -f "$path" ] && [ -s "$path" ] || return 0

  # The Chief of Staff gate of boot-memory.sh, in the folder holding memory/.
  cd -- "${dir%/*}/" >/dev/null 2>&1 || return 0
  [ -f CRITICAL_FACTS.md ] || return 0
  [ -f CLAUDE.md ] || { [ -f AGENTS.md ] && { [ -f navigation.md ] || [ -f navegacao.md ]; }; } || return 0
  printf 'refuse'
}

verdict=$(decide 2>/dev/null)
if [ "$verdict" = refuse ]; then
  printf '%s\n' "$MSG" >&2
  exit 2
fi
exit 0
