#!/bin/sh
# Probes from the audit of the overdue-events front, part 1 (the overdue mark
# in hooks/boot-memory.sh and the log guard hooks/log-guard.sh). Behavior
# only, pinned by content.
# Run by hand: sh tests/audit/pm-cos-vencido-p1.sh < /dev/null
# Every case works in folders under one mktemp -d, removed at the end.
# CDPATH and CLAUDE_PROJECT_DIR are dropped. "Today" comes from a fake date
# in front of PATH; no case reads the clock.
# Cases:
# V1 the log guard over path shapes the executor suite does not build: a
#    Chief of Staff folder named with accented letters (raw UTF-8 in the
#    payload), a path with a ".." segment, a relative "../memory/..." from a
#    payload cwd one folder down, the folder reached through a symbolic link,
#    and memory/ itself a symbolic link: each Write over the non-empty log
#    is refused with exit 2 and the fixed message.
# V2 the guard decides by the folder that holds memory/: a project folder
#    that is not a Chief of Staff, nested inside one and with its own
#    memory/YYYY-MM-DD.md, passes in silence even with the cwd at the Chief
#    of Staff root.
# V3 a Write payload of real size (2 MB of content), with file_path after
#    the content, and a payload pretty-printed over several lines, both
#    over the non-empty log, are refused.
# V4 a CRITICAL_FACTS.md with CRLF line ends: the overdue mark goes before
#    the carriage return, so the line still ends in "OVERDUE <date>\r".
# V5 the fixed OVERDUE line is the line right under the "N of M lines
#    shown." count line of the section.
# V6 the CRITICAL_FACTS.md section, measured the way the hook counts it
#    (leading newline included), stays within 4000 bytes while one marked
#    line, padded byte by byte, crosses the cap with the fixed line.
# V7 the century rule of leap years on a past date: 1900-02-29 is never
#    marked, 2000-02-29 is.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

unset CDPATH
unset CLAUDE_PROJECT_DIR
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
GUARD="$ROOT/hooks/log-guard.sh"
BOOT="$ROOT/hooks/boot-memory.sh"
MSG="Log guard (pm-chief-of-staff): this Write would replace a day's log (memory/YYYY-MM-DD.md) that already exists and is not empty. The log only grows: add the new entry with Edit, keeping the entries already in it."
NOTE="Lines marked OVERDUE: the event date has passed, and the outcome is in the log or the source."
LOG=2031-05-17.md
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

# cos DIR: a new-layout Chief of Staff in DIR with a non-empty day's log.
cos() {
  mkdir -p "$1/memory"
  echo manual > "$1/AGENTS.md"
  echo nav > "$1/navigation.md"
  echo facts > "$1/CRITICAL_FACTS.md"
  printf '## [08:00] First entry\nbody\n' > "$1/memory/$LOG"
}

# write_payload PATH CWD: a compact PreToolUse payload of a Write in $work/in.
write_payload() {
  printf '{"session_id":"s-1","transcript_path":"/x/t.jsonl","cwd":"%s","permission_mode":"default","hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"%s","content":"## [10:00] New\\nbody\\n"}}' \
    "$2" "$1" > "$work/in"
}

# guard HOOK_CWD: runs the guard on $work/in; sets rc, stdout and stderr in
# $work/out and $work/err.
guard() {
  (cd "$1" && sh "$GUARD" < "$work/in" > "$work/out" 2> "$work/err")
  rc=$?
}
refused() { [ "$rc" -eq 2 ] && [ ! -s "$work/out" ] && cmp -s "$work/err" "$work/msg"; }
passed() { [ "$rc" -eq 0 ] && [ ! -s "$work/out" ] && [ ! -s "$work/err" ]; }

# V1: path shapes.
v1=""
A="$work/Chief of Staff Café Zoë"
cos "$A"
write_payload "$A/memory/$LOG" "$A"
guard /
refused || v1="${v1}accented folder (exit $rc); "
C="$work/cos"
cos "$C"
mkdir -p "$C/notes"
write_payload "$C/memory/../memory/$LOG" "$C"
guard /
refused || v1="${v1}.. segment (exit $rc); "
write_payload "../memory/$LOG" "$C/notes"
guard /
refused || v1="${v1}relative ../memory from a sub-folder cwd (exit $rc); "
ln -s "$C" "$work/link-to-cos"
write_payload "$work/link-to-cos/memory/$LOG" "$work"
guard /
refused || v1="${v1}folder through a symbolic link (exit $rc); "
M="$work/cos-linked-memory"
mkdir -p "$M" "$work/memory-elsewhere"
echo manual > "$M/AGENTS.md"
echo nav > "$M/navigation.md"
echo facts > "$M/CRITICAL_FACTS.md"
printf '## [08:00] x\n' > "$work/memory-elsewhere/$LOG"
ln -s "$work/memory-elsewhere" "$M/memory"
write_payload "$M/memory/$LOG" "$M"
guard /
refused || v1="${v1}memory/ as a symbolic link (exit $rc); "
if [ -z "$v1" ]; then ok "V1 the guard refuses over accented, .., relative-up and linked path shapes"
else fail "V1 path shapes" "$v1"
fi

# V2: a nested project that is not a Chief of Staff.
mkdir -p "$C/projects/app/memory"
printf '## [08:00] app note\n' > "$C/projects/app/memory/$LOG"
write_payload "$C/projects/app/memory/$LOG" "$C"
guard "$C"
if passed; then ok "V2 a non-Chief of Staff project nested in one passes, whatever the cwd"
else fail "V2 nested project" "exit $rc, stderr $(head -c 120 "$work/err")"
fi

# V3: payload size and layout.
v3=""
{
  printf '{"session_id":"s-1","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"content":"' "$C"
  LC_ALL=C awk 'BEGIN { for (i = 0; i < 60000; i++) printf "## line %05d padding padding padding\\n", i }'
  printf '","file_path":"%s"}}' "$C/memory/$LOG"
} > "$work/in"
big=$(wc -c < "$work/in" | tr -d ' ')
guard /
if [ "$big" -lt 2000000 ]; then v3="${v3}payload of only $big bytes; "
elif ! refused; then v3="${v3}2 MB payload with file_path last (exit $rc); "
fi
printf '{\n  "tool_name": "Write",\n  "tool_input": {\n    "file_path": "%s",\n    "content": "x"\n  }\n}\n' "$C/memory/$LOG" > "$work/in"
guard /
refused || v3="${v3}pretty-printed payload (exit $rc); "
if [ -z "$v3" ]; then ok "V3 a 2 MB Write with file_path last and a multi-line payload are refused"
else fail "V3 payload shapes" "$v3"
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
CR=$(printf '\r')

# V4: CRLF.
printf '* crlf review (event 2031-05-16, checked 2031-05-16) -> source/a.md\r\n* future (event 2031-05-18, checked 2031-05-16)\r\n' > "$B/CRITICAL_FACTS.md"
(cd "$B" && PATH="$FD:$PATH" sh "$BOOT" > "$work/pack" 2>/dev/null)
want="* crlf review (event 2031-05-16, checked 2031-05-16) -> source/a.md $MID OVERDUE 2031-05-16$CR"
fut="* future (event 2031-05-18, checked 2031-05-16)$CR"
if grep -qxF -- "$want" "$work/pack" && grep -qxF -- "$fut" "$work/pack"; then
  ok "V4 with CRLF the mark goes before the carriage return, the future line is intact"
else
  fail "V4 CRLF" "$(grep -F crlf "$work/pack" | od -c | tail -n 3 | tr '\n' ' ')"
fi

# V5: position of the fixed line.
printf '* plain fact\n* review (event 2031-05-10, checked 2031-05-10) -> source/b.md\n' > "$B/CRITICAL_FACTS.md"
(cd "$B" && PATH="$FD:$PATH" sh "$BOOT" > "$work/pack" 2>/dev/null)
under=$(awk '/^--- CRITICAL_FACTS.md ---$/ { getline; getline; print; exit }' "$work/pack")
count=$(awk '/^--- CRITICAL_FACTS.md ---$/ { getline; print; exit }' "$work/pack")
if [ "$count" = "2 of 2 lines shown." ] && [ "$under" = "$NOTE" ] \
  && [ "$(grep -cxF -- "$NOTE" "$work/pack")" -eq 1 ]; then
  ok "V5 the fixed OVERDUE line sits right under the count line, once"
else
  fail "V5 fixed line position" "count [$count], next [$under]"
fi

# V6: the section cap counted the way the hook counts it. The section is
# the text the hook builds, from its leading newline through the last shown
# line; the blank line before the next "--- " heading is that leading
# newline. A filler of 3720 bytes and one past event as the last line,
# padded one byte at a time over 80 lengths, put the 4000-byte cap before,
# on and after the marked line plus the fixed line.
v6=""
v6_shown=0
v6_cut=0
k=0
while [ "$k" -le 80 ]; do
  LC_ALL=C awk 'BEGIN { for (i = 1; i <= 62; i++) { s = sprintf("FILL %05d ", i); while (length(s) < 59) s = s "x"; print s } }' > "$B/CRITICAL_FACTS.md"
  pad=$(LC_ALL=C awk -v k="$k" 'BEGIN { s = ""; while (length(s) < k) s = s "p"; print s }')
  printf '* review%s (event 2031-05-10, checked 2031-05-10) -> source/c.md\n' "$pad" >> "$B/CRITICAL_FACTS.md"
  (cd "$B" && PATH="$FD:$PATH" sh "$BOOT" > "$work/pack" 2>/dev/null)
  sec=$(LC_ALL=C awk '
    /^--- CRITICAL_FACTS.md ---$/ { on = 1 }
    on && /^--- / && !/^--- CRITICAL_FACTS.md ---$/ { done = 1 }
    on && !done && /^Nothing is left out of this pack/ { done = 1 }
    on && !done { n[++m] = length($0) + 1 }
    END { t = 1; for (i = 1; i < m; i++) t += n[i]; print t + 0 }' "$work/pack")
  if grep -q "OVERDUE 2031-05-10\$" "$work/pack"; then v6_shown=$((v6_shown + 1)); else v6_cut=$((v6_cut + 1)); fi
  if [ "$sec" -gt 4000 ]; then [ -n "$v6" ] || v6="padding $k: section of $sec bytes"; fi
  k=$((k + 1))
done
if [ -z "$v6" ] && [ "$v6_shown" -gt 0 ] && [ "$v6_cut" -gt 0 ]; then
  ok "V6 the CRITICAL_FACTS.md section, leading newline included, stays within 4000 bytes with the mark and the fixed line ($v6_shown shown, $v6_cut cut)"
else
  fail "V6 section cap" "${v6:-shown $v6_shown, cut $v6_cut}"
fi

# V7: the century rule of the calendar on past dates. 1900 and 2100 are not
# leap years, 2000 is; with today at 2031-05-17, only a past date tells the
# rule apart, so 1900-02-29 is the past impossible leap day.
printf '* not leap (event 1900-02-29, checked 1900-02-28) -> source/d.md\n* leap (evento 2000-02-29, conferido 2000-02-29) -> fonte/e.md\n* also not (event 2031-02-29, checked 2031-02-28) -> source/f.md\n' > "$B/CRITICAL_FACTS.md"
(cd "$B" && PATH="$FD:$PATH" sh "$BOOT" > "$work/pack" 2>/dev/null)
if grep -qxF -- "* not leap (event 1900-02-29, checked 1900-02-28) -> source/d.md" "$work/pack" \
  && grep -qxF -- "* also not (event 2031-02-29, checked 2031-02-28) -> source/f.md" "$work/pack" \
  && grep -qxF -- "* leap (evento 2000-02-29, conferido 2000-02-29) -> fonte/e.md $MID OVERDUE 2000-02-29" "$work/pack"; then
  ok "V7 a past 1900-02-29 and 2031-02-29 are not marked, a past 2000-02-29 is"
else
  fail "V7 century rule" "$(grep -E 'leap|also not' "$work/pack" | tr '\n' '|')"
fi

rm -rf "$work"
[ "$failures" -eq 0 ] || exit 1
exit 0
