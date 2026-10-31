#!/bin/sh
# Probes from the re-audit of fix round 2 of the boot-budget front, part 1
# (the Codex review findings CX1 to CX3). Behavior only, pinned by content.
# Run by hand: sh tests/audit/boot-budget-p1-reaudit-2.sh
# Every case works in folders under one mktemp -d, removed at the end. Each
# hook run goes through every shell found among /bin/sh and /bin/dash; the
# shells must agree byte for byte and on the exit, and the checks then run
# once on that output. A fake date makes "today" 2031-05-17 09:30 (or fails,
# when a case says so) and a fake uname names the host "audithost", so
# nothing compares against the real clock or the real host name.
# Cases:
# V1 a root whose name holds a literal backslash-c, backslash-0303, %s and
#    %d: the pack boots and its footer ends with that root byte for byte;
#    with the assembly forced to fail (awk failing), the output is exactly
#    the one failure line with that root. Exit 0, valid UTF-8.
# V2 CDPATH naming another folder that holds a Chief of Staff under the same
#    relative name as CLAUDE_PROJECT_DIR: the pack is the one of the folder
#    under the cwd, never the CDPATH one, and nothing but the pack is on
#    stdout; when the folder under the cwd is not a Chief of Staff, the hook
#    is silent even though the CDPATH one is.
# V3 no log for today (and also no date at all, and also ls and sort
#    failing): the log is the latest regular memory/YYYY-MM-DD.md across a
#    year turn (2026-01-01 over 2025-12-31), never a near-miss name, a
#    folder or a link to a folder with a later dated-looking name.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

unset CLAUDE_PROJECT_DIR CDPATH
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
HOOK="$ROOT/hooks/boot-memory.sh"
HEADER="=== MEMORY BOOT (pm-chief-of-staff) ==="
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi
work=$(cd "$work" && pwd)

SHELLS=""
for s in /bin/sh /bin/dash; do [ -x "$s" ] && SHELLS="$SHELLS $s"; done

# Fakes. The date answers 2031-05-17 09:30, or exits 1 with nothing on
# stdout when AUD_DATE=fail. awk, ls and sort that fail live in their own
# folders, put in front of the PATH only by the cases that want them.
fakes="$work/fakes"
mkdir -p "$fakes" "$work/noawk" "$work/nolssort"
cat > "$fakes/date" <<'EOF'
#!/bin/sh
[ "$AUD_DATE" = fail ] && exit 1
case "$*" in
  '+%Y-%m-%d') echo 2031-05-17 ;;
  '+%Y-%m-%d %H:%M') echo '2031-05-17 09:30' ;;
  *) exec /bin/date "$@" ;;
esac
EOF
printf '#!/bin/sh\necho audithost\n' > "$fakes/uname"
printf '#!/bin/sh\nexit 3\n' > "$work/noawk/awk"
printf '#!/bin/sh\necho "fake: error" >&2\nexit 3\n' > "$work/nolssort/ls"
printf '#!/bin/sh\necho "fake: error" >&2\nexit 3\n' > "$work/nolssort/sort"
chmod +x "$fakes/date" "$fakes/uname" "$work/noawk/awk" "$work/nolssort/ls" "$work/nolssort/sort"
AUD_DATE=ok
export AUD_DATE

# run DIR FRONT [CDPATH]: runs the hook in DIR under every shell, FRONT and
# the fakes in front of the PATH, CLAUDE_PROJECT_DIR from $run_cpd (unset
# when empty) and CDPATH from the third argument (unset when absent). The
# output of the first shell is in $work/out, $rc is its exit, $nl its lines,
# $size its bytes; $shdiff is non-empty when the shells disagree.
run() {
  shdiff=""
  first=""
  for shl in $SHELLS; do
    if [ -n "${run_cpd:-}" ]; then
      (cd "$1" && CDPATH="$3" CLAUDE_PROJECT_DIR="$run_cpd" PATH="$2$fakes:$PATH" "$shl" "$HOOK" > "$work/out.$$" 2>/dev/null)
    else
      (cd "$1" && unset CLAUDE_PROJECT_DIR CDPATH && PATH="$2$fakes:$PATH" "$shl" "$HOOK" > "$work/out.$$" 2>/dev/null)
    fi
    r=$?
    if [ -z "$first" ]; then
      first=$shl
      rc=$r
      mv "$work/out.$$" "$work/out"
    else
      if [ "$r" -ne "$rc" ] || ! cmp -s "$work/out" "$work/out.$$"; then
        shdiff="$first and $shl differ (exit $rc and $r)"
      fi
      rm -f "$work/out.$$"
    fi
  done
  nl=$(LC_ALL=C awk 'END { print NR + 0 }' "$work/out")
  size=$(LC_ALL=C wc -c < "$work/out" | tr -d ' ')
}

# whole_pack: the output is a whole pack (exit 0, shells agree, line 1 the
# header, line 4 stating the measured size, a footer, valid UTF-8). Sets why.
whole_pack() {
  why=""
  [ -n "$shdiff" ] && why="shells: $shdiff"
  [ -z "$why" ] && [ "$rc" -ne 0 ] && why="exit $rc"
  [ -z "$why" ] && [ "$size" -gt 8000 ] && why="pack of $size bytes"
  [ -z "$why" ] && [ "$(sed -n 1p "$work/out")" != "$HEADER" ] && why="line 1: $(sed -n 1p "$work/out" | cut -c1-80)"
  if [ -z "$why" ]; then
    case "$(sed -n 4p "$work/out")" in
      "Sizes: "*", this pack $size bytes (limit 8000).") ;;
      *) why="line 4 does not state $size bytes" ;;
    esac
  fi
  if [ -z "$why" ] && ! LC_ALL=C grep -qxF -- "--- not in this pack ---" "$work/out" \
    && ! LC_ALL=C grep -Eq '^Nothing is left out of this pack; the files are in .+\.$' "$work/out"; then
    why="no footer"
  fi
  [ -z "$why" ] && ! iconv -f UTF-8 -t UTF-8 < "$work/out" > "$work/conv" 2>/dev/null && why="not valid UTF-8"
  [ -z "$why" ]
}

# cos DIR CF: a small Chief of Staff whose CRITICAL_FACTS.md is the line CF.
cos() {
  mkdir -p "$1/memory"
  printf 'manual\n' > "$1/AGENTS.md"
  printf '%s\n' "$2" > "$1/CRITICAL_FACTS.md"
  printf 'NAV_R2\n' > "$1/navigation.md"
}

# V1 the root byte for byte, in the pack and in the failure line.
v1=""
d="$work/"'v1 raiz \c meio \0303 %s %d fim'
cos "$d" CF_V1
printf '## [08:00] V1_HEAD\n' > "$d/memory/2031-05-17.md"
rootv1=$(cd "$d" && pwd)
run_cpd=""
run "$d" ""
if ! whole_pack; then v1="$v1 [pack: $why]"
elif [ "$(tail -n 1 "$work/out")" != "Nothing is left out of this pack; the files are in $rootv1." ]; then
  v1="$v1 [pack: last line is not the root byte for byte: $(tail -n 1 "$work/out" | cut -c1-200)]"
fi
run "$d" "$work/noawk:"
if [ -n "$shdiff" ] || [ "$rc" -ne 0 ] || [ "$nl" -ne 1 ] \
  || [ "$(cat "$work/out")" != "Memory boot pack not assembled; the files are on disk in $rootv1." ] \
  || ! iconv -f UTF-8 -t UTF-8 < "$work/out" > "$work/conv" 2>/dev/null; then
  v1="$v1 [failure line: exit $rc, $nl lines, $size bytes $shdiff]"
fi
if [ -z "$v1" ]; then
  ok "V1 a root with backslashes and percent signs reaches the footer and the failure line byte for byte"
else
  fail "V1 root with backslashes and percent signs" "$v1"
fi

# V2 CDPATH never picks the folder.
v2=""
cos "$work/v2 cwd/proj" CF_V2_REAL
cos "$work/v2 elsewhere/proj" CF_V2_DECOY
cos "$work/v2 elsewhere/half" CF_V2_HALF_DECOY
mkdir -p "$work/v2 cwd/half"
printf 'CF only\n' > "$work/v2 cwd/half/CRITICAL_FACTS.md"
rootv2=$(cd "$work/v2 cwd/proj" && pwd)
for cdp in "$work/v2 elsewhere" "$work/v2 elsewhere:" ".:$work/v2 elsewhere"; do
  run_cpd=proj
  run "$work/v2 cwd" "" "$cdp"
  if ! whole_pack; then v2="$v2 [CDPATH '$cdp', proj: $why]"
  elif ! LC_ALL=C grep -qxF CF_V2_REAL "$work/out" || LC_ALL=C grep -qF CF_V2_DECOY "$work/out"; then
    v2="$v2 [CDPATH '$cdp', proj: the pack is not the cwd's folder]"
  elif [ "$(tail -n 1 "$work/out")" != "Nothing is left out of this pack; the files are in $rootv2." ]; then
    v2="$v2 [CDPATH '$cdp', proj: footer root: $(tail -n 1 "$work/out" | cut -c1-200)]"
  fi
  run_cpd=half
  run "$work/v2 cwd" "" "$cdp"
  if [ -n "$shdiff" ] || [ "$rc" -ne 0 ] || [ "$size" -ne 0 ]; then
    v2="$v2 [CDPATH '$cdp', half: exit $rc, $size bytes, line 1: $(sed -n 1p "$work/out" | cut -c1-80) $shdiff]"
  fi
done
run_cpd=""
if [ -z "$v2" ]; then
  ok "V2 a relative CLAUDE_PROJECT_DIR resolves under the cwd, never under CDPATH"
else
  fail "V2 CDPATH resolution" "$v2"
fi

# V3 the latest dated log across a year turn, decoys with later names.
v3=""
d="$work/v3 cos"
cos "$d" CF_V3
printf '## [08:00] V3_OLD_YEAR\nbody\n' > "$d/memory/2025-12-31.md"
printf '## [08:00] V3_OLDER\n' > "$d/memory/2025-06-30.md"
printf '## [08:00] V3_RIGHT\nbody\n' > "$d/memory/2026-01-01.md"
printf '## [08:00] V3_DECOY_BAK\n' > "$d/memory/2026-01-01.md.bak"
printf '## [08:00] V3_DECOY_PREFIX\n' > "$d/memory/x2026-01-02.md"
printf '## [08:00] V3_DECOY_EXT\n' > "$d/memory/2026-01-02.markdown"
printf '## [08:00] V3_DECOY_SHORT\n' > "$d/memory/2026-1-03.md"
printf '## [08:00] V3_DECOY_NODASH\n' > "$d/memory/20260104.md"
printf '## [08:00] V3_DECOY_COPY\n' > "$d/memory/2026-01-05 (1).md"
mkdir -p "$d/memory/2026-01-06.md" "$d/somedir"
printf '## [08:00] V3_DECOY_INSIDE\n' > "$d/memory/2026-01-06.md/2026-01-06.md"
printf '## [08:00] V3_DECOY_LINKDIR\n' > "$d/somedir/2026-01-07.md"
ln -s ../somedir "$d/memory/2026-01-07.md"
# No FIFO among the decoys: a regression that reads one would hang the run
# instead of failing it.
for mode in nolog nodate nolssort; do
  front=""
  AUD_DATE=ok
  [ "$mode" = nodate ] && AUD_DATE=fail
  [ "$mode" = nolssort ] && front="$work/nolssort:"
  run_cpd=""
  run "$d" "$front"
  if [ "$mode" = nodate ]; then
    [ "$(sed -n 3p "$work/out")" = "time now: unknown" ] || v3="$v3 [$mode: line 3 $(sed -n 3p "$work/out")]"
  fi
  if ! whole_pack; then v3="$v3 [$mode: $why]"
  elif [ "$(LC_ALL=C grep -c -- '^--- memory/' "$work/out")" -ne 1 ]; then v3="$v3 [$mode: not exactly one log section]"
  elif ! LC_ALL=C grep -qxF -- "--- memory/2026-01-01.md ---" "$work/out"; then
    v3="$v3 [$mode: section $(LC_ALL=C grep -- '^--- memory/' "$work/out")]"
  elif ! LC_ALL=C grep -qxF "## [08:00] V3_RIGHT" "$work/out"; then v3="$v3 [$mode: no V3_RIGHT heading]"
  elif LC_ALL=C grep -q 'V3_OLD\|V3_DECOY' "$work/out"; then v3="$v3 [$mode: a decoy or an older log in the pack]"
  elif ! LC_ALL=C grep -qxF "memory/2026-01-01.md: all 1 headings are shown; the entry bodies (1 lines) stay on disk." "$work/out"; then
    v3="$v3 [$mode: the footer does not name the log]"
  fi
done
AUD_DATE=ok
if [ -z "$v3" ]; then
  ok "V3 the latest regular memory/YYYY-MM-DD.md wins across a year turn, never a near-miss, folder or link to a folder"
else
  fail "V3 latest dated log" "$v3"
fi

rm -rf "$work"
[ "$failures" -eq 0 ]
