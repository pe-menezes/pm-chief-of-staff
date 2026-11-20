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
# Fail-open: anything the guard cannot read for sure (no input, input whose
# structure is not one whole JSON object, no tool_name, a path holding a
# JSON escape, a command that fails, even after printing output) passes,
# with exit 0 and nothing on stdout or stderr. The decision runs in a
# subshell whose only possible output is the word refuse, and it counts only
# when the subshell ends with status 0; any other end, a crash included,
# passes.
# What it checks: the structure of the payload (every string closed, read
# by the parity of the backslashes before each quote; brackets nested by
# kind; one object, with nothing before or after it but whitespace), not
# the whole JSON grammar (escapes, commas, colons, literals, a control
# character inside a string), because it reads only three string fields.
# A payload whose structure is whole is read even when its grammar is not:
# an invalid escape in the content of a Write over the log is refused
# (case L22 of hooks/log-guard-test.sh).
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
# The payload must be one whole JSON object by its structure (the grammar
# inside is not checked): no string is left open, and in the text outside
# the strings the first character is "{", the brackets nest by kind, and
# the object closes at the end of the input; JSON whitespace there never
# counts, and each string counts as text, so a string before the first "{"
# or after the object is text outside it. Any other input (cut short, a
# string or a key left open, text or a string after the object) exits 1,
# and the guard passes. The time is linear in the payload, up to a log
# factor where it joins pieces.
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
      # tailrun: the length of the run of backslashes at the end of x. The
      # awk of macOS reads the whole of x on every substr call, so a call
      # per backslash would take time in the square of the run; here a chunk
      # before the part already counted doubles while it holds only
      # backslashes and halves when it does not, so a run of any length
      # costs a few dozen calls.
      function tailrun(x,   L, k, c) {
        L = length(x)
        k = 0
        c = 1
        while (k < L) {
          if (c > L - k) c = L - k
          if (substr(x, L - k - c + 1, c) !~ /[^\\]/) { k += c; c += c }
          else if (c == 1) break
          else c = int(c / 2)
        }
        return k
      }
      # Cost: the awk of macOS reads the whole string on every substr call,
      # and a split or gsub by a regular expression takes time in the
      # square of its matches, while a split on one literal character is
      # linear. So the text is never walked by substr per character, never
      # cut by a regular expression with many matches, and never grown by
      # one concatenation per piece.
      # join: a[1..n] joined by one space, pair by pair, so each byte is
      # copied about log2(n) times, never once per element.
      function join(a, n,   m, i, v) {
        if (n < 1) return ""
        for (; n > 1; n = m) {
          m = 0
          for (i = 1; i <= n; i += 2) {
            v = (i < n) ? a[i] " " a[i + 1] : a[i]
            a[++m] = v
          }
        }
        return a[1]
      }
      # blank: x with every ch made a space, by a split on ch and a join.
      function blank(x, ch,   y, m) {
        if (!index(x, ch)) return x
        m = split(x, y, ch)
        return join(y, m)
      }
      # at: puts in P[1..] the positions of ch in p, in order, by one split
      # on the character itself, and returns how many there are.
      function at(p, ch, P,   x, m, k, pos) {
        m = split(p, x, ch)
        pos = 0
        for (k = 1; k < m; k++) {
          pos += length(x[k]) + 1
          P[k] = pos
        }
        return m - 1
      }
      # walk: reads one piece of the text outside the strings, in order,
      # against the brackets open so far (st, d) and closed, set once the
      # object has closed. It returns 0 when the piece breaks the shape of
      # one whole object: a character other than a space before the first
      # "{" or after the object, or a bracket that closes with the wrong
      # kind. The brackets come in order from a merge of the positions of
      # each kind; text between them counts only before the first "{" and
      # after the object, so it is read there alone.
      function walk(p,   A, B, C, E, na, nb, nc, ne, ia, ib, ic, ie, L, pa, pb, pc, pe, pos, c) {
        if (p !~ /[^ ]/) return 1
        if (closed) return 0
        if (p !~ /[][{}]/) return (d > 0)
        na = at(p, "{", A)
        nb = at(p, "[", B)
        nc = at(p, "}", C)
        ne = at(p, "]", E)
        L = length(p) + 1
        ia = 1; ib = 1; ic = 1; ie = 1
        while (1) {
          pa = (ia <= na) ? A[ia] : L
          pb = (ib <= nb) ? B[ib] : L
          pc = (ic <= nc) ? C[ic] : L
          pe = (ie <= ne) ? E[ie] : L
          pos = pa; c = "{"
          if (pb < pos) { pos = pb; c = "[" }
          if (pc < pos) { pos = pc; c = "}" }
          if (pe < pos) { pos = pe; c = "]" }
          if (pos == L) return 1
          if (c == "{") ia++
          else if (c == "[") ib++
          else if (c == "}") ic++
          else ie++
          if (d == 0) {
            if (c != "{") return 0
            if (substr(p, 1, pos - 1) ~ /[^ ]/) return 0
          }
          if (c == "{" || c == "[") st[++d] = c
          else {
            if ((c == "}") != (st[d] == "{")) return 0
            if (--d == 0) {
              closed = 1
              return (substr(p, pos + 1) !~ /[^ ]/)
            }
          }
        }
      }
      { a[NR] = blank(blank($0, "\r"), "\t") }
      END {
        # s: the lines joined by one space.
        s = join(a, NR)
        # The text outside every string is read piece by piece, in order;
        # each string counts as one character of that text where it closes,
        # so a string before the first brace or after the object is text
        # outside the object. A quote preceded by an odd run of backslashes
        # is escaped and stays inside the string.
        n = split(s, q, "\"")
        d = 0; closed = 0
        if (!walk(q[1])) exit 1
        ins = 0
        for (i = 1; i < n; i++) {
          if (ins) {
            if (tailrun(q[i]) % 2) continue
            ins = 0
            if (closed || d == 0) exit 1
            if (!walk(q[i + 1])) exit 1
          } else ins = 1
        }
        if (ins) exit 1
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
