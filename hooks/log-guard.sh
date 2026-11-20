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
# Paths: an absolute file_path is taken as it is; one starting with "~/"
# resolves against an absolute HOME; any other relative one resolves against
# the cwd of the payload when it is an absolute folder, else the cwd of the
# hook. The result is then put in its plain form by text (repeated "/" and
# "." dropped, ".." taking out the component before it), so an equivalent
# spelling of the log is the log.
# Fail-open: anything the guard cannot read for sure (no input, input that
# is not one whole JSON object, no tool_name, a path holding a JSON escape,
# a command that fails, even after printing output) passes, with exit 0 and
# nothing on stdout or stderr. The decision runs in a subshell whose only
# possible output is the word refuse, and it counts only when the subshell
# ends with status 0; any other end, a crash included, passes.
# Runtime: registered only in hooks/hooks.json. Codex writes files through
# apply_patch, with no Write tool and no file_path, so the Codex manifest
# does not register it (measured on codex-cli 0.163.0-alpha.10.2).
MSG="Log guard (pm-chief-of-staff): this Write would replace a day's log (memory/YYYY-MM-DD.md) that already exists and is not empty. The log only grows: add the new entry with Edit, keeping the entries already in it."

# Pattern matching: bracket expressions list their characters one by one,
# never as a range, because the /bin/sh of macOS (bash 3.2) matches a range
# by the locale's collation.
D='[0123456789]'

# json_fields: reads the payload from stdin, in one command, so its exit
# status is the status of the whole read; nothing pipes the payload in, so
# no status is lost in a pipeline, and the payload never travels through
# the environment or the arguments, whose limit (near 1 MB on macOS) a large
# Write passes. Line breaks, carriage returns and tabs become spaces.
# The payload must be one whole JSON object: no string is left open, and in
# the text outside the strings the first character is "{", the brackets
# nest by kind, and the object closes at the end of the input. Any
# other input (cut short, a string or a key left open, text after the
# object) exits 1, and the guard passes.
# For a whole object it prints three lines, T, P and C followed by the
# content of the first "KEY" : "string" pair of tool_name, file_path and
# cwd, with any whitespace around the colon; nothing after the letter when
# the key is missing or its value is not a string. A key inside a string
# value never matches, because JSON escapes its quotes. A value holding a
# backslash comes back whole up to the next quote, and the caller refuses
# to read it.
json_fields() {
  LC_ALL=C awk '
      function field(k,   r, i) {
        if (!match(s, "\"" k "\"[ ]*:[ ]*")) return ""
        r = substr(s, RSTART + RLENGTH)
        if (substr(r, 1, 1) != "\"") return ""
        r = substr(r, 2)
        i = index(r, "\"")
        if (i == 0) return ""
        return substr(r, 1, i - 1)
      }
      { gsub(/[\r\t]/, " "); s = s (NR > 1 ? " " : "") $0 }
      END {
        # t: the text outside every string. A quote preceded by an odd run
        # of backslashes is escaped and stays inside the string.
        n = split(s, q, "\"")
        t = q[1]
        ins = 0
        for (i = 1; i < n; i++) {
          if (ins) {
            L = length(q[i])
            k = 0
            while (k < L && substr(q[i], L - k, 1) == "\\") k++
            if (k % 2) continue
            ins = 0
            t = t q[i + 1]
          } else ins = 1
        }
        if (ins) exit 1
        d = 0; closed = 0
        n = length(t)
        for (i = 1; i <= n; i++) {
          c = substr(t, i, 1)
          if (c == " ") continue
          if (closed) exit 1
          if (d == 0 && c != "{") exit 1
          if (c == "{" || c == "[") st[++d] = c
          else if (c == "}" || c == "]") {
            if ((c == "}") != (st[d] == "{")) exit 1
            if (--d == 0) closed = 1
          }
        }
        if (!closed) exit 1
        print "T" field("tool_name")
        print "P" field("file_path")
        print "C" field("cwd")
      }' 2>/dev/null
}

# decide: prints refuse when the Write must be refused, and nothing else.
decide() {
  set -f
  unset CDPATH
  # Every step that feeds the decision checks its exit status: a command
  # that fails, even after printing output, passes.
  fields=$(json_fields) || return 0
  nl='
'
  case "$fields" in T*"$nl"P*"$nl"C*) ;; *) return 0 ;; esac
  tool=${fields%%"$nl"*}
  rest=${fields#*"$nl"}
  path=${rest%%"$nl"*}
  cwd_field=${rest#*"$nl"}
  tool=${tool#T}
  path=${path#P}
  cwd_field=${cwd_field#C}
  [ "$tool" = Write ] || return 0
  [ -n "$path" ] || return 0
  case "$path" in *\\*) return 0 ;; esac
  # A path ending in a folder separator, "." or ".." names a folder.
  case "$path" in */ | */. | */.. | . | ..) return 0 ;; esac
  case "$path" in
    /*) ;;
    '~/'*)
      case "$HOME" in /*) ;; *) return 0 ;; esac
      path="$HOME/${path#??}"
      ;;
    *)
      base=$cwd_field
      case "$base" in *\\*) base="" ;; esac
      case "$base" in /*) [ -d "$base" ] || base="" ;; *) base="" ;; esac
      [ -n "$base" ] || base=$(pwd 2>/dev/null) || return 0
      [ -n "$base" ] || return 0
      path="$base/$path"
      ;;
  esac

  # The path in its plain form, as Claude Code resolves it before writing:
  # repeated separators and "." components dropped, each ".." taking out the
  # component before it, by text, in the shell, so that memory//x.md and
  # memory/./x.md are the log they name. Links are followed afterwards by
  # the file tests and by cd, as before.
  old_ifs=$IFS
  IFS=/
  set -- $path
  IFS=$old_ifs
  path=""
  for c in "$@"; do
    case "$c" in
      '' | .) ;;
      ..) path=${path%/*} ;;
      *) path="$path/$c" ;;
    esac
  done
  [ -n "$path" ] || return 0

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

# The verdict counts only when decide itself ends with status 0: a printf
# of the word that fails after printing it passes, like any other step.
if verdict=$(decide 2>/dev/null) && [ "$verdict" = refuse ]; then
  printf '%s\n' "$MSG" >&2
  exit 2
fi
exit 0
