#!/bin/sh
# Probes from reaudit 2 of the overdue-events front, part 1 (repair 2: a
# relative file_path whose first folder name starts with "~" resolves
# against the cwd in the log guard). Behavior only, pinned by content.
# Run by hand: sh tests/audit/pm-cos-vencido-p1-reaudit-2.sh < /dev/null
# Every case works in folders under one mktemp -d, removed at the end, with
# HOME pointed inside it. CDPATH and CLAUDE_PROJECT_DIR are dropped. The
# guard runs under sh and, when present, /bin/dash.
# Claude Code 2.1.309, measured by this reaudit: "~user/..", "~root/.." and
# "~+/x" are written relative to the cwd, never expanded; ".." after them is
# resolved by text. The guard must follow the same reading.
# Cases:
# T1 "~cos/memory/<log>" over an existing log in a Chief of Staff at
#    <cwd>/~cos is refused, with the payload cwd and, without it, with the
#    hook's cwd.
# T2 other spellings with "~" that Claude Code writes relative to the cwd
#    land on the existing log and are refused: "~root/../memory/<log>",
#    "~+/memory/<log>", "~cos/../~cos/memory/<log>".
# T3 no refusal by mistake: "~cos/..." to a new log, to a non-log file, to
#    a log in a "~cos" folder that is not a Chief of Staff, a bare "~", and
#    "~cos/memory/<log>" while the log that exists is under HOME/cos (the
#    guard never reads "~cos" as "~/cos").
# T4 the neighbors of the removed branch keep their reading: a plain
#    relative path, a "~/" path against an absolute HOME and an absolute
#    path over the existing log are refused.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

unset CDPATH
unset CLAUDE_PROJECT_DIR
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
GUARD="$ROOT/hooks/log-guard.sh"
MSG="Log guard (pm-chief-of-staff): this Write would replace a day's log (memory/YYYY-MM-DD.md) that already exists and is not empty. The log only grows: add the new entry with Edit, keeping the entries already in it."
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

# payload CWD PATH: a Write payload; with an empty CWD, no cwd key at all.
payload() {
  if [ -n "$1" ]; then
    printf '{"session_id":"s","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"%s","content":"new"}}' "$1" "$2" > "$work/in"
  else
    printf '{"session_id":"s","hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"%s","content":"new"}}' "$2" > "$work/in"
  fi
}

# guard SHELL HOOK_CWD: runs the guard on $work/in with HOME=$work/home.
guard() {
  (cd "$2" && HOME="$work/home" "$1" "$GUARD" < "$work/in" > "$work/out" 2> "$work/err")
  rc=$?
}
refused() { [ "$rc" -eq 2 ] && [ ! -s "$work/out" ] && cmp -s "$work/err" "$work/msg"; }
passed() { [ "$rc" -eq 0 ] && [ ! -s "$work/out" ] && [ ! -s "$work/err" ]; }

# Layout: HOME is $work/home and holds a Chief of Staff at cos/; the cwd is
# $work/cwd, itself a Chief of Staff, with a Chief of Staff at ~cos/ and at
# ~+/, and a plain folder ~plain/memory/ that is not one.
H="$work/home"
W="$work/cwd"
cos "$H/cos"
cos "$W"
cos "$W/~cos"
cos "$W/~+"
mkdir -p "$W/~plain/memory" "$W/~cos/notes" "$W/new/~cos/memory"
printf '## [08:00] not a cos\n' > "$W/~plain/memory/$LOG"
printf 'note\n' > "$W/~cos/notes/$LOG"
echo manual > "$W/new/~cos/CLAUDE.md"
echo facts > "$W/new/~cos/CRITICAL_FACTS.md"

# T1
t1=""
for s in $SHELLS; do
  payload "$W" "~cos/memory/$LOG"
  guard "$s" /
  refused || t1="${t1}$s payload cwd exit $rc; "
  payload "" "~cos/memory/$LOG"
  guard "$s" "$W"
  refused || t1="${t1}$s hook cwd exit $rc; "
done
if [ -z "$t1" ]; then ok "T1 ~cos/memory/<log> over an existing log resolves against the cwd and is refused ($SHELLS)"
else fail "T1 relative ~cos path" "$t1"
fi

# T2
t2=""
for s in $SHELLS; do
  for p in "~root/../memory/$LOG" "~+/memory/$LOG" "~cos/../~cos/memory/$LOG" "~nobody-here/./../~cos/memory//$LOG"; do
    payload "$W" "$p"
    guard "$s" /
    refused || t2="${t2}$s $p exit $rc; "
  done
done
if [ -z "$t2" ]; then ok "T2 ~user/.., ~+/ and ~cos/.. spellings land on the existing log under the cwd and are refused ($SHELLS)"
else fail "T2 other ~ spellings" "$t2"
fi

# T3
t3=""
for s in $SHELLS; do
  for p in "~cos/memory/2031-05-18.md" "~cos/notes/$LOG" "~cos/memory/notes.md" "~plain/memory/$LOG" "~"; do
    payload "$W" "$p"
    guard "$s" /
    passed || t3="${t3}$s $p exit $rc; "
  done
  # The log that exists is $H/cos/memory/<log>; "~cos/..." from a cwd with
  # no log under ~cos must not be read as "~/cos/...".
  payload "$W/new" "~cos/memory/$LOG"
  guard "$s" /
  passed || t3="${t3}$s ~cos read as ~/cos exit $rc; "
done
if [ -z "$t3" ]; then ok "T3 ~ paths that are not the existing log pass, and ~cos is never read as ~/cos ($SHELLS)"
else fail "T3 no refusal by mistake" "$t3"
fi

# T4
t4=""
for s in $SHELLS; do
  for p in "memory/$LOG" "~/cos/memory/$LOG" "~//cos/./memory/$LOG" "$W/~cos/memory/$LOG"; do
    payload "$W" "$p"
    guard "$s" /
    refused || t4="${t4}$s $p exit $rc; "
  done
done
if [ -z "$t4" ]; then ok "T4 plain relative, ~/ against HOME and absolute paths over a log are still refused ($SHELLS)"
else fail "T4 neighbors of the removed branch" "$t4"
fi

rm -rf "$work"
[ "$failures" -eq 0 ] || exit 1
exit 0
