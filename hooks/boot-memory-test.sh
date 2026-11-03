#!/bin/sh
# Test suite for boot-memory.sh.
# Gate: G1 to G6 (agents-md spec, part 1), G7 and G8 (audit fix 1: silent
# folders without CRITICAL_FACTS.md or without a manual), and G2n, G3n, G5n,
# G8n and G9 (english spec: navigation.md, and the legacy name navegacao.md
# next to it). G2, G3, G5 and G8 keep the legacy name navegacao.md.
# Handoff to the memoria-agente engine: C1 to C7 (agents-md spec, part 2),
# C8, C9 and H1 to H8 (audit fix 1: 2-day window and host name rule), K1 and
# K2 (audit fix 2: only a regular file counts as proof of life).
# Runtime: R1 to R5 (codex-compat-funcional spec: Codex runtime and a path
# with spaces). Time line: T1 (english spec, format only, never the clock;
# line 3 since the boot-budget spec). Pack with a byte budget: B1 to B10, R6
# to R8 (boot-budget spec: 8000 bytes, cut at whole lines, footer,
# CLAUDE_PROJECT_DIR, the compact matcher). B11 (audit round 1, D1), and
# from fix round 1: B10w (a failing or garbage wc), B12 (a failing date) and
# U1 (the UTF-8 check itself). From fix round 2 (Codex review): B13 (the
# failure line with backslashes in the root), B14 (CDPATH) and B15 (only a
# regular memory/YYYY-MM-DD.md is the latest log). Overdue events: D0 (the
# test date generator) and O1 to O9 (overdue-events spec, I1 and I2: the
# mark, the fixed line, the date boundary, the budget, and the differential
# oracle against the hook of dd1520d).
# Run by hand: sh hooks/boot-memory-test.sh
# Each case builds a folder with mktemp -d, runs the hook inside it in a
# subshell (the hook reads paths relative to the cwd, as in a real session)
# and removes the folder.
# A boot is detected by the fixed boot header and by the CRITICAL_FACTS.md
# fixture in the load, never by the whole text.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

# The hook reads CLAUDE_PROJECT_DIR first; one inherited from the caller
# would point every case away from its folder.
unset CLAUDE_PROJECT_DIR
# An exported CDPATH makes cd print the folder inside $(...), which would
# double every path built from DIR.
unset CDPATH
DIR=$(cd "$(dirname "$0")" && pwd) || exit 1
HOOK="$DIR/boot-memory.sh"
MARCA="=== MEMORY BOOT (pm-chief-of-staff) ==="
FIXTURE="fixture-critical-facts-g"
failures=0

if [ -x "$HOOK" ]; then
  echo "ok    execution bit of the hook"
else
  echo "FAIL  execution bit of the hook missing: $HOOK"
  failures=$((failures + 1))
fi

# run_in NAME FILE...: builds a temporary folder with the files, runs the
# hook in it and leaves the result in $out and $rc. Returns 1 when mktemp
# fails (the failure is already counted). CLAUDE.md is born as the one-line
# bridge.
run_in() {
  label="$1"
  shift
  tmp=$(mktemp -d 2>/dev/null)
  if [ -z "$tmp" ] || [ ! -d "$tmp" ]; then
    echo "FAIL  $label: mktemp -d returned no folder"
    failures=$((failures + 1))
    return 1
  fi
  for f in "$@"; do
    case "$f" in
      CLAUDE.md) echo "@AGENTS.md" > "$tmp/$f" ;;
      CRITICAL_FACTS.md) echo "$FIXTURE" > "$tmp/$f" ;;
      *) echo "content of $f" > "$tmp/$f" ;;
    esac
  done
  out=$(cd "$tmp" && "$HOOK" 2>/dev/null)
  rc=$?
  rm -rf "$tmp"
  return 0
}

# boots: exit 0, the header on the first line and the fixture in the load.
boots() {
  [ "$rc" -eq 0 ] && [ "$(printf '%s\n' "$out" | sed -n 1p)" = "$MARCA" ] \
    && printf '%s\n' "$out" | grep -qx "$FIXTURE"
}

# case_g NAME EXPECTED FILE...
# EXPECTED: boots or silent.
case_g() {
  name="$1"
  expected="$2"
  shift 2
  run_in "$name" "$@" || return
  first=$(printf '%s\n' "$out" | sed -n 1p)
  if [ "$expected" = boots ]; then
    if boots; then
      echo "ok    $name"
    else
      echo "FAIL  $name: expected a boot (exit $rc, first line: $first)"
      failures=$((failures + 1))
    fi
  else
    if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
      echo "ok    $name"
    else
      echo "FAIL  $name: expected exit 0 and empty stdout (exit $rc, stdout: $first)"
      failures=$((failures + 1))
    fi
  fi
}

case_g "G1 old folder" boots CLAUDE.md CRITICAL_FACTS.md
case_g "G2 legacy navegacao.md with bridge" boots AGENTS.md CLAUDE.md CRITICAL_FACTS.md navegacao.md
case_g "G3 legacy navegacao.md without bridge" boots AGENTS.md CRITICAL_FACTS.md navegacao.md
case_g "G4 vault template" silent AGENTS.md CRITICAL_FACTS.md
case_g "G5 repo with AGENTS.md and legacy navegacao.md" silent AGENTS.md navegacao.md
case_g "G6 empty" silent
case_g "G7 only CLAUDE.md" silent CLAUDE.md
case_g "G8 CF and legacy navegacao.md without manual" silent CRITICAL_FACTS.md navegacao.md
case_g "G2n navigation.md with bridge" boots AGENTS.md CLAUDE.md CRITICAL_FACTS.md navigation.md
case_g "G3n navigation.md without bridge" boots AGENTS.md CRITICAL_FACTS.md navigation.md
case_g "G5n repo with AGENTS.md and navigation.md" silent AGENTS.md navigation.md
case_g "G8n CF and navigation.md without manual" silent CRITICAL_FACTS.md navigation.md

# G9: an old folder that gained navigation.md next to the legacy file. Both
# are printed, navigation.md first; the hook never picks which one is stale.
if run_in "G9 navigation.md and legacy navegacao.md" \
  AGENTS.md CRITICAL_FACTS.md navigation.md navegacao.md; then
  new_at=$(printf '%s\n' "$out" | grep -nxF -- "--- navigation.md ---" | sed -n 1p | cut -d: -f1)
  old_at=$(printf '%s\n' "$out" | grep -nxF -- "--- navegacao.md ---" | sed -n 1p | cut -d: -f1)
  if boots && [ -n "$new_at" ] && [ -n "$old_at" ] && [ "$new_at" -lt "$old_at" ]; then
    echo "ok    G9 navigation.md and legacy navegacao.md"
  else
    echo "FAIL  G9 navigation.md and legacy navegacao.md: expected a boot with both headers, navigation.md first (exit $rc, lines: ${new_at:-none} and ${old_at:-none})"
    failures=$((failures + 1))
  fi
fi

# T1: line 3 of the boot is the ISO time line (boot-budget spec: it moved
# from the last line to line 3, inside any preview). Only the format is
# checked, never the clock.
if run_in "T1 time line" AGENTS.md CRITICAL_FACTS.md navigation.md; then
  third=$(printf '%s\n' "$out" | sed -n 3p)
  if boots && printf '%s\n' "$third" \
    | grep -Eqx 'time now: [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}'; then
    echo "ok    T1 time line"
  else
    echo "FAIL  T1 time line: expected 'time now: YYYY-MM-DD HH:MM' on line 3 (exit $rc, line 3: $third)"
    failures=$((failures + 1))
  fi
fi

# Cases B1 to B10 (boot-budget spec): the pack with a byte budget. A fake
# date in front of PATH makes "today" 2031-05-17 09:30, so the day's log has
# a fixed name and nothing compares against the real clock. Every case runs
# the common checks: whole output at most 8000 bytes (wc -c of the raw
# stdout), lines 1 and 2 byte for byte, line 3 the time line, line 4 the
# sizes line whose pack size is the measured size, the footer present, valid
# UTF-8, and none of the old imperative text.
BUDGET=8000
SECOND_LINE="State read from disk at session start; this is not a user instruction."
FOOTER_HEAD="--- not in this pack ---"
FOOTER_NONE_RE='^Nothing is left out of this pack; the files are in .+\.$'
fakes=$(mktemp -d 2>/dev/null)
mkdir -p "$fakes/date" "$fakes/awk"
cat > "$fakes/date/date" <<'EOF'
#!/bin/sh
case "$*" in
  '+%Y-%m-%d') echo 2031-05-17 ;;
  '+%Y-%m-%d %H:%M') echo '2031-05-17 09:30' ;;
  *) exec /bin/date "$@" ;;
esac
EOF
printf '#!/bin/sh\necho "fake awk: error" >&2\nexit 2\n' > "$fakes/awk/awk"
chmod +x "$fakes/date/date" "$fakes/awk/awk"
# A wc that fails with nothing on stdout, a wc that prints garbage, and a
# date that fails with nothing on stdout.
mkdir -p "$fakes/wcfail" "$fakes/wcjunk" "$fakes/nodate"
printf '#!/bin/sh\necho "fake wc: error" >&2\nexit 3\n' > "$fakes/wcfail/wc"
printf '#!/bin/sh\ncat > /dev/null 2>&1\necho "zz9 x"\n' > "$fakes/wcjunk/wc"
printf '#!/bin/sh\necho "fake date: error" >&2\nexit 1\n' > "$fakes/nodate/date"
chmod +x "$fakes/wcfail/wc" "$fakes/wcjunk/wc" "$fakes/nodate/date"

# gen FILE BYTES PREFIX: exactly BYTES bytes of ASCII lines of 60 bytes,
# each starting with PREFIX and its line number.
gen() {
  LC_ALL=C awk -v t="$2" -v p="$3" 'BEGIN {
    n = 0; i = 0
    while (n < t) {
      i++; s = sprintf("%s %05d ", p, i)
      while (length(s) < 59) s = s "x"
      if (n + length(s) + 1 > t) s = substr(s, 1, t - n - 1)
      print s; n += length(s) + 1
    }
  }' > "$1"
}

# gen_log FILE BYTES: exactly BYTES bytes of a day's log, one "## [HH:MM]"
# heading every six lines and body lines in between.
gen_log() {
  LC_ALL=C awk -v t="$2" 'BEGIN {
    n = 0; i = 0; h = 0
    while (n < t) {
      i++
      if (i % 6 == 1) { h++; s = sprintf("## [%02d:%02d] LOG_HEAD_%03d decision taken", (h / 60) % 24, h % 60, h) }
      else { s = sprintf("LOG_BODY_%05d ", i); while (length(s) < 59) s = s "y" }
      if (n + length(s) + 1 > t) s = substr(s, 1, t - n - 1)
      print s; n += length(s) + 1
    }
  }' > "$1"
}

# new_cos: a new-layout Chief of Staff in $tmp (AGENTS.md, CRITICAL_FACTS.md
# with the fixture, navigation.md). Returns 1 when mktemp fails.
new_cos() {
  tmp=$(mktemp -d 2>/dev/null)
  if [ -z "$tmp" ] || [ ! -d "$tmp" ]; then
    echo "FAIL  $1: mktemp -d returned no folder"
    failures=$((failures + 1))
    return 1
  fi
  echo "manual" > "$tmp/AGENTS.md"
  echo "$FIXTURE" > "$tmp/CRITICAL_FACTS.md"
  echo "NAV_SMALL" > "$tmp/navigation.md"
  mkdir -p "$tmp/memory"
}

# run_pack [DIR [PATH_FRONT]]: runs the hook in DIR ($tmp by default) with the
# fake date, raw stdout in a file; $out, $rc and $size (bytes) are set.
run_pack() {
  where="${1:-$tmp}"
  front="${2:-$fakes/date}"
  (cd "$where" && PATH="$front:$PATH" "$HOOK" > "$fakes/stdout" 2>/dev/null)
  rc=$?
  size=$(wc -c < "$fakes/stdout" | tr -d ' ')
  out=$(cat "$fakes/stdout")
}

# section NAME: the lines of the section headed "--- NAME ---", up to the
# next line starting with "--- ", the blank separator included.
section() {
  printf '%s\n' "$out" | awk -v h="--- $1 ---" '
    $0 == h { on = 1; print; next }
    on && /^--- / { exit }
    on { print }'
}

# utf8_ok FILE: FILE is valid UTF-8. The conversion goes to a regular file:
# on macOS, iconv writing to /dev/null fails on valid UTF-8 at some byte
# offsets ("Inappropriate ioctl for device"), measured in audit round 1.
utf8_ok() {
  iconv -f UTF-8 -t UTF-8 < "$1" > "$fakes/iconv.out" 2>/dev/null
}

# common: the checks every pack case runs; prints the first broken one in
# $why and returns 1.
common() {
  why=""
  l3=$(printf '%s\n' "$out" | sed -n 3p)
  l4=$(printf '%s\n' "$out" | sed -n 4p)
  said=$(printf '%s\n' "$l4" | sed -n 's/.*this pack \([0-9]*\) bytes (limit 8000)\.$/\1/p')
  if [ "$rc" -ne 0 ]; then why="exit $rc"
  elif [ "$size" -gt "$BUDGET" ]; then why="output of $size bytes, above $BUDGET"
  elif [ "$(printf '%s\n' "$out" | sed -n 1p)" != "$MARCA" ]; then why="line 1"
  elif [ "$(printf '%s\n' "$out" | sed -n 2p)" != "$SECOND_LINE" ]; then why="line 2"
  elif ! printf '%s\n' "$l3" | grep -Eqx 'time now: [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}'; then why="line 3: $l3"
  elif ! printf '%s\n' "$l4" | grep -Eqx 'Sizes: CRITICAL_FACTS\.md [0-9]+ bytes \(target about 3000\), (AGENTS|CLAUDE)\.md [0-9]+ bytes \(target about 10000\), this pack [0-9]+ bytes \(limit 8000\)\.'; then why="line 4: $l4"
  elif [ "$said" != "$size" ]; then why="line 4 says $said bytes, measured $size"
  elif ! printf '%s\n' "$out" | grep -qxF -- "$FOOTER_HEAD" \
    && ! printf '%s\n' "$out" | grep -Eq "$FOOTER_NONE_RE"; then why="footer missing"
  elif ! utf8_ok "$fakes/stdout"; then why="output is not valid UTF-8"
  elif printf '%s\n' "$out" | grep -qi 'read it from disk'; then why="old imperative text"
  fi
  [ -z "$why" ]
}

# verdict NAME CONDITION_RESULT DETAIL: one ok or FAIL line.
verdict() {
  if [ "$2" -eq 0 ]; then
    echo "ok    $1"
  else
    echo "FAIL  $1: $3"
    failures=$((failures + 1))
  fi
}

# B1 small log: every heading is shown, in file order, and no body line.
if new_cos "B1 small log"; then
  printf '## [08:10] B1_FIRST\nbody line B1_BODY\n## [09:20] B1_SECOND\n' > "$tmp/memory/2031-05-17.md"
  run_pack
  r=1
  if common; then
    a=$(printf '%s\n' "$out" | grep -nxF '## [08:10] B1_FIRST' | cut -d: -f1)
    b=$(printf '%s\n' "$out" | grep -nxF '## [09:20] B1_SECOND' | cut -d: -f1)
    if [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ] \
      && printf '%s\n' "$out" | grep -qxF -- "--- memory/2031-05-17.md ---" \
      && ! printf '%s\n' "$out" | grep -qF B1_BODY \
      && printf '%s\n' "$out" | grep -qxF NAV_SMALL; then r=0
    else why="headings ${a:-none} and ${b:-none}, or a body line in the pack"
    fi
  fi
  rm -rf "$tmp"
  verdict "B1 small log: headings in file order, bodies on disk" "$r" "$why"
fi

# B2 the real case: CRITICAL_FACTS.md of 3608 bytes, navigation.md of 5543
# and a day's log of 28122 (the 28/10 log). The old hook gave 37491.
if new_cos "B2 log of 28122"; then
  { echo "$FIXTURE"; gen /dev/stdout 3583 CF_LINE; } > "$tmp/CRITICAL_FACTS.md"
  gen "$tmp/navigation.md" 5543 NAV_LINE
  gen_log "$tmp/memory/2031-05-17.md" 28122
  cfs=$(wc -c < "$tmp/CRITICAL_FACTS.md" | tr -d ' ')
  logs=$(wc -c < "$tmp/memory/2031-05-17.md" | tr -d ' ')
  run_pack
  r=1
  if [ "$cfs" -ne 3608 ] || [ "$logs" -ne 28122 ]; then why="fixture sizes $cfs and $logs"
  elif common; then
    logsec=$(section memory/2031-05-17.md)
    if printf '%s\n' "$out" | grep -qxF "$FIXTURE" \
      && printf '%s\n' "$logsec" | grep -q 'LOG_HEAD_' \
      && [ "$(printf '%s\n' "$logsec" | wc -c | tr -d ' ')" -le 1500 ] \
      && ! printf '%s\n' "$out" | grep -qF LOG_BODY_ \
      && ! printf '%s\n' "$out" | grep -qF 'LOG_HEAD_001 ' \
      && printf '%s\n' "$out" | grep -qF 'NAV_LINE 00001' \
      && printf '%s\n' "$out" | grep -Eq '^memory/2031-05-17\.md: .*headings.*not shown.*entry bodies.*on disk'; then r=0
    else why="log section or footer"
    fi
  fi
  rm -rf "$tmp"
  verdict "B2 log of 28122 bytes, the real case, fits the budget" "$r" "$why"
fi

# B3 CRITICAL_FACTS.md above 4000 bytes: whole lines up to the section cap,
# the first line kept, the last left out and named in the footer.
if new_cos "B3 big CRITICAL_FACTS.md"; then
  { echo "$FIXTURE"; gen /dev/stdout 6000 CF_LINE; } > "$tmp/CRITICAL_FACTS.md"
  last_cf=$(tail -n 1 "$tmp/CRITICAL_FACTS.md")
  run_pack
  r=1
  if common; then
    cfsec=$(section CRITICAL_FACTS.md)
    if printf '%s\n' "$cfsec" | grep -qxF "$FIXTURE" \
      && [ "$(printf '%s\n' "$cfsec" | wc -c | tr -d ' ')" -le 4000 ] \
      && ! printf '%s\n' "$out" | grep -qxF "$last_cf" \
      && printf '%s\n' "$cfsec" | grep -Eq '^[0-9]+ of [0-9]+ lines shown\.$' \
      && ! printf '%s\n' "$cfsec" | grep -Eq '^CF_LINE [0-9]{5} x{0,40}$' \
      && printf '%s\n' "$out" | grep -Eq '^CRITICAL_FACTS\.md: lines [0-9]+ to [0-9]+ of [0-9]+ are not shown\.$'; then r=0
    else why="CRITICAL_FACTS.md section of $(printf '%s\n' "$cfsec" | wc -c | tr -d ' ') bytes, or footer line"
    fi
  fi
  rm -rf "$tmp"
  verdict "B3 CRITICAL_FACTS.md above 4000 bytes cut at a whole line" "$r" "$why"
fi

# B4 navigation bigger than what is left: the start is shown, the end is not,
# and the footer names it.
if new_cos "B4 big navigation"; then
  gen "$tmp/navigation.md" 20000 NAV_LINE
  last_nav=$(tail -n 1 "$tmp/navigation.md")
  run_pack
  r=1
  if common; then
    if printf '%s\n' "$out" | grep -qF 'NAV_LINE 00001' \
      && ! printf '%s\n' "$out" | grep -qxF "$last_nav" \
      && printf '%s\n' "$out" | grep -Eq '^navigation\.md: lines [0-9]+ to [0-9]+ of [0-9]+ are not shown\.$'; then r=0
    else why="navigation start, end or footer line"
    fi
  fi
  rm -rf "$tmp"
  verdict "B4 navigation bigger than the rest of the budget" "$r" "$why"
fi

# B5 the three big together, plus the legacy navegacao.md: sections in the
# order facts, log, navigation.md, navegacao.md, then the footer.
if new_cos "B5 all big"; then
  { echo "$FIXTURE"; gen /dev/stdout 9000 CF_LINE; } > "$tmp/CRITICAL_FACTS.md"
  gen "$tmp/navigation.md" 20000 NAV_LINE
  gen "$tmp/navegacao.md" 20000 OLDNAV_LINE
  gen_log "$tmp/memory/2031-05-17.md" 28122
  run_pack
  r=1
  if common; then
    p1=$(printf '%s\n' "$out" | grep -nxF -- "--- CRITICAL_FACTS.md ---" | cut -d: -f1)
    p2=$(printf '%s\n' "$out" | grep -nxF -- "--- memory/2031-05-17.md ---" | cut -d: -f1)
    p3=$(printf '%s\n' "$out" | grep -nxF -- "--- navigation.md ---" | cut -d: -f1)
    p4=$(printf '%s\n' "$out" | grep -nxF -- "--- navegacao.md ---" | cut -d: -f1)
    p5=$(printf '%s\n' "$out" | grep -nxF -- "$FOOTER_HEAD" | cut -d: -f1)
    if [ -n "$p1" ] && [ -n "$p2" ] && [ -n "$p3" ] && [ -n "$p4" ] && [ -n "$p5" ] \
      && [ "$p1" -lt "$p2" ] && [ "$p2" -lt "$p3" ] && [ "$p3" -lt "$p4" ] && [ "$p4" -lt "$p5" ] \
      && printf '%s\n' "$out" | grep -q '^CRITICAL_FACTS\.md: lines' \
      && printf '%s\n' "$out" | grep -q '^memory/2031-05-17\.md: ' \
      && printf '%s\n' "$out" | grep -q '^navigation\.md: lines' \
      && printf '%s\n' "$out" | grep -q '^navegacao\.md: lines'; then r=0
    else why="order ${p1:-none} ${p2:-none} ${p3:-none} ${p4:-none} ${p5:-none}, or footer lines"
    fi
  fi
  rm -rf "$tmp"
  verdict "B5 the three big together, with both navigation files" "$r" "$why"
fi

# B6 without today's log, the latest dated log gives the headings.
if new_cos "B6 old log"; then
  printf '## [08:00] B6_OLD\n' > "$tmp/memory/2026-01-02.md"
  printf '## [18:40] B6_LATEST\nbody B6_BODY\n' > "$tmp/memory/2026-10-28.md"
  echo "## B6_NOTES" > "$tmp/memory/notes.md"
  run_pack
  r=1
  if common; then
    if printf '%s\n' "$out" | grep -qxF -- "--- memory/2026-10-28.md ---" \
      && printf '%s\n' "$out" | grep -qxF '## [18:40] B6_LATEST' \
      && ! printf '%s\n' "$out" | grep -qF B6_OLD \
      && ! printf '%s\n' "$out" | grep -qF B6_NOTES \
      && ! printf '%s\n' "$out" | grep -qF B6_BODY; then r=0
    else why="log fallback"
    fi
  fi
  rm -rf "$tmp"
  verdict "B6 today's log missing, the latest dated one is used" "$r" "$why"
fi

# B7 CLAUDE_PROJECT_DIR points to the folder while the cwd is a subfolder
# without any memory file: the gate and the files come from the project dir.
# B7b: a CLAUDE_PROJECT_DIR that is not a directory falls back to the cwd.
if new_cos "B7 project dir"; then
  mkdir -p "$tmp/sub folder"
  printf '## [07:00] B7_HEAD\n' > "$tmp/memory/2031-05-17.md"
  (cd "$tmp/sub folder" && CLAUDE_PROJECT_DIR="$tmp" PATH="$fakes/date:$PATH" "$HOOK" > "$fakes/stdout" 2>/dev/null)
  rc=$?
  size=$(wc -c < "$fakes/stdout" | tr -d ' ')
  out=$(cat "$fakes/stdout")
  r=1
  if common; then
    if printf '%s\n' "$out" | grep -qxF "$FIXTURE" \
      && printf '%s\n' "$out" | grep -qxF '## [07:00] B7_HEAD'; then r=0
    else why="files not read from CLAUDE_PROJECT_DIR"
    fi
  fi
  verdict "B7 CLAUDE_PROJECT_DIR with the cwd in a subfolder" "$r" "$why"
  (cd "$tmp" && CLAUDE_PROJECT_DIR="$tmp/missing" PATH="$fakes/date:$PATH" "$HOOK" > "$fakes/stdout" 2>/dev/null)
  rc=$?
  size=$(wc -c < "$fakes/stdout" | tr -d ' ')
  out=$(cat "$fakes/stdout")
  r=1
  if common && printf '%s\n' "$out" | grep -qxF "$FIXTURE"; then r=0; fi
  verdict "B7b CLAUDE_PROJECT_DIR that is not a directory falls back to the cwd" "$r" "$why"
  rm -rf "$tmp"
fi

# B8 accented text: the facts, the log headings and the navigation in
# Portuguese, big enough to be cut; the output stays valid UTF-8.
if new_cos "B8 accents"; then
  awk -v f="$FIXTURE" 'BEGIN { print f; for (i = 1; i <= 120; i++) printf "Decisão %03d: ação já útil, revisão é coração da operação\n", i }' > "$tmp/CRITICAL_FACTS.md"
  awk 'BEGIN { for (i = 1; i <= 200; i++) printf "## [%02d:%02d] Reunião %03d: atenção à decisão\ncorpo com acentuação\n", (i / 60) % 24, i % 60, i }' > "$tmp/memory/2031-05-17.md"
  awk 'BEGIN { for (i = 1; i <= 300; i++) printf "* `pastas/ção-%03d/`: navegação, histórico e índice\n", i }' > "$tmp/navigation.md"
  run_pack
  r=1
  if common; then
    if printf '%s\n' "$out" | grep -qF 'Decisão 001: ação' \
      && printf '%s\n' "$out" | grep -qF 'Reunião 200: atenção' \
      && printf '%s\n' "$out" | grep -qF 'pastas/ção-001'; then r=0
    else why="accented lines missing"
    fi
  fi
  rm -rf "$tmp"
  verdict "B8 accented text cut at whole lines stays valid UTF-8" "$r" "$why"
fi

# B9 nothing left out: small files and a log with headings only give the
# one-line footer.
if new_cos "B9 nothing out"; then
  printf '## [08:00] B9_HEAD\n' > "$tmp/memory/2031-05-17.md"
  run_pack
  r=1
  if common; then
    if printf '%s\n' "$out" | grep -Eq "$FOOTER_NONE_RE" \
      && ! printf '%s\n' "$out" | grep -qxF -- "$FOOTER_HEAD" \
      && [ "$(printf '%s\n' "$out" | grep -Ec "$FOOTER_NONE_RE")" -eq 1 ]; then r=0
    else why="one-line footer"
    fi
  fi
  rm -rf "$tmp"
  verdict "B9 nothing left out says so in one line" "$r" "$why"
fi

# B10 internal failure while assembling (an awk that fails): one statement
# line saying the pack was not assembled and where the files are, exit 0.
if new_cos "B10 failure"; then
  run_pack "$tmp" "$fakes/awk:$fakes/date"
  lines=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
  r=1
  if [ "$rc" -eq 0 ] && [ "$lines" -eq 1 ] \
    && printf '%s\n' "$out" | grep -Eqx 'Memory boot pack not assembled; the files are on disk in .+\.'; then r=0
  else why="exit $rc, $lines lines: $(printf '%s\n' "$out" | sed -n 1p)"
  fi
  rm -rf "$tmp"
  verdict "B10 failure while assembling gives one statement line and exit 0" "$r" "$why"
fi

# B10w (audit round 1, finding A-D1): a wc that fails or prints garbage
# gives the same one statement line and exit 0, never an empty stdout.
for mode in wcfail wcjunk; do
  if new_cos "B10w $mode"; then
    run_pack "$tmp" "$fakes/$mode:$fakes/date"
    lines=$(printf '%s\n' "$out" | awk 'END { print NR + 0 }')
    [ -s "$fakes/stdout" ] || lines=0
    r=1
    if [ "$rc" -eq 0 ] && [ "$lines" -eq 1 ] \
      && printf '%s\n' "$out" | grep -Eqx 'Memory boot pack not assembled; the files are on disk in .+\.'; then r=0
    else why="exit $rc, $lines lines: $(printf '%s\n' "$out" | sed -n 1p)"
    fi
    rm -rf "$tmp"
    verdict "B10w a $mode wc gives one statement line and exit 0" "$r" "$why"
  fi
done

# B12 (audit round 1, finding B-3): a date that fails gives "time now:
# unknown" on line 3; the rest of the pack stays whole, and with no today's
# log the latest dated log gives the headings.
if new_cos "B12 date fails"; then
  printf '## [08:10] B12_HEAD\n' > "$tmp/memory/2031-05-16.md"
  run_pack "$tmp" "$fakes/nodate"
  l3=$(printf '%s\n' "$out" | sed -n 3p)
  r=1
  if [ "$rc" -ne 0 ]; then why="exit $rc"
  elif [ "$(printf '%s\n' "$out" | sed -n 1p)" != "$MARCA" ]; then why="line 1: $(printf '%s\n' "$out" | sed -n 1p)"
  elif [ "$l3" != "time now: unknown" ]; then why="line 3: $l3"
  elif [ "$size" -gt "$BUDGET" ]; then why="output of $size bytes"
  elif ! printf '%s\n' "$out" | grep -qxF -- "--- memory/2031-05-16.md ---"; then why="no log section"
  elif ! printf '%s\n' "$out" | grep -qxF -- "## [08:10] B12_HEAD"; then why="no log heading"
  elif ! printf '%s\n' "$out" | grep -Eq "$FOOTER_NONE_RE"; then why="footer missing"
  else r=0
  fi
  rm -rf "$tmp"
  verdict "B12 a failing date gives 'time now: unknown' and a whole pack" "$r" "$why"
fi

# U1 (audit round 1, finding B-2): the UTF-8 check of the common checks
# accepts valid UTF-8 whatever its byte offset (iconv to /dev/null fails on
# macOS for some offsets of valid text) and rejects an invalid byte.
LC_ALL=C awk 'BEGIN { printf "xxx"; for (i = 0; i < 100; i++) printf "linha %d com acentua\303\247\303\243o: decis\303\243o\n", i }' > "$fakes/u1-valid"
printf 'abc\377def\n' > "$fakes/u1-invalid"
r=1
if ! utf8_ok "$fakes/u1-valid"; then why="valid UTF-8 rejected"
elif utf8_ok "$fakes/u1-invalid"; then why="invalid byte accepted"
else r=0
fi
verdict "U1 the UTF-8 check accepts valid text and rejects an invalid byte" "$r" "$why"

# Fix round 2 cases run the hook under every shell found among /bin/sh and
# /bin/dash, named on the command line, not through the shebang.
SHELLS2=""
for s in /bin/sh /bin/dash; do [ -x "$s" ] && SHELLS2="$SHELLS2 $s"; done

# run_shell SHELL DIR FRONT: runs the hook with SHELL in DIR, FRONT in front
# of PATH and no CLAUDE_PROJECT_DIR; $out, $rc and $size are set.
run_shell() {
  (cd "$2" && unset CLAUDE_PROJECT_DIR && PATH="$3:$PATH" "$1" "$HOOK" > "$fakes/stdout" 2>/dev/null)
  rc=$?
  size=$(wc -c < "$fakes/stdout" | tr -d ' ')
  out=$(cat "$fakes/stdout")
}

# B13 (Codex review, CX1): the failure line carries the root byte for byte.
# A root whose name holds a literal backslash-c and backslash-0303 (which
# echo reads as "stop here" and as an octal byte) gives the whole line,
# valid UTF-8 and exit 0, under every shell.
b13=""
if new_cos "B13 root with backslashes"; then
  d="$tmp/"'raiz \c meio \0303 fim'
  mkdir -p "$d/memory"
  cp "$tmp/AGENTS.md" "$tmp/CRITICAL_FACTS.md" "$tmp/navigation.md" "$d/"
  want="Memory boot pack not assembled; the files are on disk in $(cd "$d" && pwd)."
  for shl in $SHELLS2; do
    run_shell "$shl" "$d" "$fakes/awk:$fakes/date"
    lines=$(awk 'END { print NR + 0 }' "$fakes/stdout")
    if [ "$rc" -ne 0 ] || [ "$lines" -ne 1 ] || [ "$out" != "$want" ] || ! utf8_ok "$fakes/stdout"; then
      b13="$b13 [$(basename "$shl"): exit $rc, $lines lines, $size bytes]"
    fi
  done
  rm -rf "$tmp"
  r=0
  [ -n "$b13" ] && r=1
  verdict "B13 the failure line keeps a root with backslashes whole, valid UTF-8, exit 0 (shells:$SHELLS2)" "$r" "$b13"
fi

# B14 (Codex review, CX2): with CDPATH set and a relative
# CLAUDE_PROJECT_DIR, the cd prints nothing: a folder that is not a Chief of
# Staff stays silent, and in a Chief of Staff line 1 is the header and the
# pack keeps its budget and the size it states.
b14=""
if new_cos "B14 CDPATH"; then
  mkdir -p "$tmp/not cos"
  echo "CF only" > "$tmp/not cos/CRITICAL_FACTS.md"
  mkdir -p "$tmp/the cos/memory"
  cp "$tmp/AGENTS.md" "$tmp/CRITICAL_FACTS.md" "$tmp/navigation.md" "$tmp/the cos/"
  for shl in $SHELLS2; do
    (cd "$tmp" && CDPATH=. CLAUDE_PROJECT_DIR="not cos" PATH="$fakes/date:$PATH" "$shl" "$HOOK" > "$fakes/stdout" 2>/dev/null)
    rc=$?
    size=$(wc -c < "$fakes/stdout" | tr -d ' ')
    if [ "$rc" -ne 0 ] || [ "$size" -ne 0 ]; then
      b14="$b14 [$(basename "$shl") not a CoS: exit $rc, $size bytes]"
    fi
    (cd "$tmp" && CDPATH=. CLAUDE_PROJECT_DIR="the cos" PATH="$fakes/date:$PATH" "$shl" "$HOOK" > "$fakes/stdout" 2>/dev/null)
    rc=$?
    size=$(wc -c < "$fakes/stdout" | tr -d ' ')
    out=$(cat "$fakes/stdout")
    if ! common || ! printf '%s\n' "$out" | grep -qx "$FIXTURE"; then
      b14="$b14 [$(basename "$shl") CoS: ${why:-no fixture}; line 1: $(printf '%s\n' "$out" | sed -n 1p)]"
    fi
  done
  rm -rf "$tmp"
  r=0
  [ -n "$b14" ] && r=1
  verdict "B14 CDPATH with a relative CLAUDE_PROJECT_DIR prints nothing from the cd (shells:$SHELLS2)" "$r" "$b14"
fi

# B15 (Codex review, CX3): with no log for today, the log is the latest
# regular file named memory/YYYY-MM-DD.md. An undated name that sorts later,
# a folder with a dated name and names with a newline are never the log,
# also with ls and sort failing.
b15=""
mkdir -p "$fakes/nolssort"
printf '#!/bin/sh\necho "fake: error" >&2\nexit 3\n' > "$fakes/nolssort/ls"
printf '#!/bin/sh\necho "fake: error" >&2\nexit 3\n' > "$fakes/nolssort/sort"
chmod +x "$fakes/nolssort/ls" "$fakes/nolssort/sort"
if new_cos "B15 latest dated log"; then
  printf '## [08:00] B15_NOTES\n' > "$tmp/memory/9-notes.md"
  mkdir -p "$tmp/memory/2026-10-29.md"
  printf '## [08:00] B15_INSIDE\n' > "$tmp/memory/2026-10-29.md/2026-10-30.md"
  printf '## [08:00] B15_NEWLINE\n' > "$tmp/memory/2026-10-30
x.md"
  printf '## [08:00] B15_NEWLINE2\n' > "$tmp/memory/2026-10-31.md
"
  printf '## [08:00] B15_RIGHT\n' > "$tmp/memory/2026-10-28.md"
  for front in "$fakes/date" "$fakes/nolssort:$fakes/date"; do
    tag2=""
    [ "$front" = "$fakes/date" ] || tag2=" without ls and sort"
    for shl in $SHELLS2; do
      run_shell "$shl" "$tmp" "$front"
      tag="$(basename "$shl")$tag2"
      if ! common; then b15="$b15 [$tag: $why]"
      elif ! printf '%s\n' "$out" | grep -qxF -- "--- memory/2026-10-28.md ---"; then b15="$b15 [$tag: no section memory/2026-10-28.md]"
      elif ! printf '%s\n' "$out" | grep -qxF -- "## [08:00] B15_RIGHT"; then b15="$b15 [$tag: no B15_RIGHT heading]"
      elif [ "$(printf '%s\n' "$out" | grep -c -- '^--- memory/')" -ne 1 ]; then b15="$b15 [$tag: more than one log section]"
      elif printf '%s\n' "$out" | grep -q 'B15_NOTES\|B15_INSIDE\|B15_NEWLINE'; then b15="$b15 [$tag: a decoy taken as the log]"
      fi
    done
  done
  rm -rf "$tmp"
  r=0
  [ -n "$b15" ] && r=1
  verdict "B15 the latest log is the latest regular memory/YYYY-MM-DD.md, never a decoy (shells:$SHELLS2)" "$r" "$b15"
fi

# B11 (audit round 1, finding D1: the footer reserve was smaller than the
# real footer, so a full pack overflowed into the failure line). The cases
# are generated by shape, never picked by hand: CRITICAL_FACTS.md below and
# above its section cap, with line counts at the digit turns (9/10, 99/100,
# 999/1000); navigation.md of 5 content lines followed by a tail of blank
# lines or of short lines, with totals at the same turns and one far above;
# with and without navegacao.md; no day's log, a log of headings only and a
# log with bodies. Every case runs the common checks and must not give the
# failure line.
b11_n=0
b11_bad=0
b11_first=""
for cf in "9 40" "10 40" "99 40" "100 39" "100 52" "999 8" "1000 8"; do
  cf_lines=${cf% *}
  cf_width=${cf#* }
  for tail_kind in blank short; do
    for nav_total in 9 10 99 100 999 1000 4005; do
      for legacy in no yes; do
        for log_kind in none heads bodies; do
          new_cos "B11" || continue
          awk -v f="$FIXTURE" -v n="$cf_lines" -v w="$cf_width" 'BEGIN {
            print f
            for (i = 2; i <= n; i++) { s = sprintf("CF%04d ", i); while (length(s) < w - 1) s = s "c"; print s }
          }' > "$tmp/CRITICAL_FACTS.md"
          awk -v n="$nav_total" -v k="$tail_kind" 'BEGIN {
            for (i = 1; i <= 5; i++) printf "* NAV%d: a navigation line of some length\n", i
            for (i = 6; i <= n; i++) { if (k == "blank") print ""; else print "x" }
          }' > "$tmp/navigation.md"
          if [ "$legacy" = yes ]; then cp "$tmp/navigation.md" "$tmp/navegacao.md"; fi
          case "$log_kind" in
            heads) printf '## [08:00] B11_HEAD\n' > "$tmp/memory/2031-05-17.md" ;;
            bodies) printf '## [08:00] B11_HEAD\nbody\n' > "$tmp/memory/2031-05-17.md" ;;
          esac
          run_pack
          b11_n=$((b11_n + 1))
          if ! common || printf '%s\n' "$out" | grep -q '^Memory boot pack not assembled'; then
            [ -n "$why" ] || why="failure line"
            b11_bad=$((b11_bad + 1))
            [ -n "$b11_first" ] || b11_first="cf $cf_lines x $cf_width, $tail_kind tail of $nav_total, navegacao.md $legacy, log $log_kind: $why"
          fi
          rm -rf "$tmp"
        done
      done
    done
  done
done
if [ "$b11_bad" -eq 0 ] && [ "$b11_n" -eq 588 ]; then
  echo "ok    B11 generated shapes fit the budget without the failure line ($b11_n cases)"
else
  echo "FAIL  B11 generated shapes: $b11_bad of $b11_n cases broken; first: $b11_first"
  failures=$((failures + 1))
fi

# Cases D0 and O1 to O9 (overdue-events spec, I1 and I2). An active event in
# CRITICAL_FACTS.md carries "(event YYYY-MM-DD" or, in a Portuguese folder,
# "(evento YYYY-MM-DD"; the pack marks the line " · OVERDUE YYYY-MM-DD" when
# that date is strictly before today, and the section then carries one fixed
# line. "Today" comes from a fake date in front of PATH, and every other date
# is generated from it by day_shift, never read from the real clock.
OVERDUE_LINE="Lines marked OVERDUE: the event date has passed, and the outcome is in the log or the source."
MID=$(printf '\302\267')
ARROW=$(printf '\342\206\222')
REPO=$(cd "$DIR/.." && pwd)

# day_shift DATE N: the date N days after DATE (N may be negative), from day
# numbers of the Gregorian calendar, computed here and never by the hook.
day_shift() {
  awk -v d="$1" -v n="$2" '
    function dfc(y, m, dd,   era, yoe, doy, doe) {
      if (m <= 2) y--
      era = int((y >= 0 ? y : y - 399) / 400); yoe = y - era * 400
      doy = int((153 * (m > 2 ? m - 3 : m + 9) + 2) / 5) + dd - 1
      doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
      return era * 146097 + doe - 719468
    }
    function cfd(z,   era, doe, yoe, y, doy, mp, dd, m) {
      z += 719468
      era = int((z >= 0 ? z : z - 146096) / 146097); doe = z - era * 146097
      yoe = int((doe - int(doe / 1460) + int(doe / 36524) - int(doe / 146096)) / 365)
      y = yoe + era * 400; doy = doe - (365 * yoe + int(yoe / 4) - int(yoe / 100))
      mp = int((5 * doy + 2) / 153); dd = doy - int((153 * mp + 2) / 5) + 1
      m = mp < 10 ? mp + 3 : mp - 9
      if (m <= 2) y++
      return sprintf("%04d-%02d-%02d", y, m, dd)
    }
    BEGIN { split(d, a, "-"); print cfd(dfc(a[1] + 0, a[2] + 0, a[3] + 0) + n) }'
}

# fake_today DATE: a folder whose date answers DATE (and DATE 09:30); sets td.
fake_today() {
  td="$fakes/today-$1"
  if [ ! -d "$td" ]; then
    mkdir -p "$td"
    printf '#!/bin/sh\ncase "$*" in\n  %s) echo %s ;;\n  %s) echo %s ;;\n  *) exec /bin/date "$@" ;;\nesac\n' \
      "'+%Y-%m-%d'" "$1" "'+%Y-%m-%d %H:%M'" "'$1 09:30'" > "$td/date"
    chmod +x "$td/date"
  fi
}

# ev LANG DATE TEXT: an active event line in the format of I1.
ev() {
  if [ "$1" = pt ]; then
    printf '* %s (evento %s, conferido %s) %s fonte/%s.md\n' "$3" "$2" "$2" "$ARROW" "$3"
  else
    printf '* %s (event %s, checked %s) %s source/%s.md\n' "$3" "$2" "$2" "$ARROW" "$3"
  fi
}

# in_out LINE: LINE is a whole line of the pack.
in_out() {
  printf '%s\n' "$out" | grep -qxF -- "$1"
}

# D0: the date generator itself, at the turns the O cases cross.
d0=""
for t in "2032-01-01 -1 2031-12-31" "2031-12-31 1 2032-01-01" "2032-03-01 -1 2032-02-29" \
  "2031-03-01 -1 2031-02-28" "2100-03-01 -1 2100-02-28" "2000-03-01 -1 2000-02-29" \
  "2031-05-17 -366 2030-05-16" "2031-05-01 -1 2031-04-30"; do
  set -- $t
  got=$(day_shift "$1" "$2")
  [ "$got" = "$3" ] || { [ -n "$d0" ] || d0="$1 $2 gave $got, expected $3"; }
done
r=0
[ -n "$d0" ] && r=1
verdict "D0 the test date generator crosses month, leap day and year turns" "$r" "$d0"

# O1: yesterday marks, in English and in Portuguese; a legacy line passes
# intact; the fixed line comes once, inside the CRITICAL_FACTS.md section;
# the file on disk does not change.
fake_today 2031-05-17
y=$(day_shift 2031-05-17 -1)
if new_cos "O1 yesterday"; then
  en=$(ev en "$y" launch-review)
  pt=$(ev pt "$y" revisão-do-lançamento)
  legacy="* Legacy fact with no date, as every installed folder has"
  printf '%s\n' "$FIXTURE" "$en" "$pt" "$legacy" > "$tmp/CRITICAL_FACTS.md"
  cp "$tmp/CRITICAL_FACTS.md" "$fakes/o1-before"
  run_pack "$tmp" "$td"
  r=1
  if common; then
    cfsec=$(section CRITICAL_FACTS.md)
    if ! printf '%s\n' "$cfsec" | grep -qxF -- "$en $MID OVERDUE $y"; then why="English event not marked"
    elif ! printf '%s\n' "$cfsec" | grep -qxF -- "$pt $MID OVERDUE $y"; then why="Portuguese event not marked"
    elif ! printf '%s\n' "$cfsec" | grep -qxF -- "$legacy"; then why="legacy line changed"
    elif [ "$(printf '%s\n' "$out" | grep -cxF -- "$OVERDUE_LINE")" -ne 1 ] \
      || ! printf '%s\n' "$cfsec" | grep -qxF -- "$OVERDUE_LINE"; then why="fixed line not once in the section"
    elif [ "$(printf '%s\n' "$out" | grep -c OVERDUE)" -ne 3 ]; then why="OVERDUE on other lines"
    elif ! cmp -s "$tmp/CRITICAL_FACTS.md" "$fakes/o1-before"; then why="CRITICAL_FACTS.md on disk changed"
    else r=0
    fi
  fi
  rm -rf "$tmp"
  verdict "O1 yesterday's event is marked OVERDUE in both languages, legacy line intact, file unchanged" "$r" "$why"
fi

# O2: today's and tomorrow's events are not marked, and with no mark there is
# no fixed line.
fake_today 2031-05-17
if new_cos "O2 today and tomorrow"; then
  e1=$(ev en 2031-05-17 today-review)
  e2=$(ev pt "$(day_shift 2031-05-17 1)" amanhã)
  printf '%s\n' "$FIXTURE" "$e1" "$e2" > "$tmp/CRITICAL_FACTS.md"
  run_pack "$tmp" "$td"
  r=1
  if common; then
    if ! in_out "$e1" || ! in_out "$e2"; then why="event lines changed"
    elif printf '%s\n' "$out" | grep -q OVERDUE; then why="OVERDUE in the pack"
    else r=0
    fi
  fi
  rm -rf "$tmp"
  verdict "O2 today's and tomorrow's events are not marked, no fixed line" "$r" "$why"
fi

# O3: the boundary over generated todays (a month turn, the leap day, the
# year turn): the day before and the year before mark, today and the day
# after do not, in both languages.
o3=""
o3_n=0
for t in 2031-05-17 2031-05-01 2031-12-31 2032-01-01 2032-02-29 2032-03-01 2031-03-01; do
  fake_today "$t"
  new_cos "O3" || continue
  p1=$(day_shift "$t" -1)
  p2=$(day_shift "$t" -366)
  f1=$(day_shift "$t" 1)
  a=$(ev en "$p1" before-en)
  b=$(ev pt "$p1" before-pt)
  c=$(ev en "$p2" year-before)
  d=$(ev pt "$t" today-pt)
  e=$(ev en "$t" today-en)
  f=$(ev pt "$f1" after-pt)
  printf '%s\n' "$FIXTURE" "$a" "$b" "$c" "$d" "$e" "$f" > "$tmp/CRITICAL_FACTS.md"
  run_pack "$tmp" "$td"
  o3_n=$((o3_n + 1))
  w=""
  if ! common; then w="$why"
  elif ! in_out "$a $MID OVERDUE $p1" || ! in_out "$b $MID OVERDUE $p1" \
    || ! in_out "$c $MID OVERDUE $p2"; then w="a past event not marked"
  elif ! in_out "$d" || ! in_out "$e" || ! in_out "$f"; then w="today's or tomorrow's event changed"
  elif [ "$(printf '%s\n' "$out" | grep -cxF -- "$OVERDUE_LINE")" -ne 1 ]; then w="fixed line not once"
  fi
  [ -n "$w" ] && [ -z "$o3" ] && o3="today $t: $w"
  rm -rf "$tmp"
done
r=0
{ [ -n "$o3" ] || [ "$o3_n" -ne 7 ]; } && r=1
verdict "O3 day before and year before mark, today and after do not, across month, leap and year turns ($o3_n todays)" "$r" "$o3"

# O4: an impossible date is never marked, a real leap day is.
fake_today 2031-05-17
if new_cos "O4 impossible dates"; then
  : > "$tmp/CRITICAL_FACTS.md"
  echo "$FIXTURE" >> "$tmp/CRITICAL_FACTS.md"
  i=0
  for bad in 2026-02-30 2026-13-01 2026-00-10 2026-04-31 2026-05-00 2027-02-29 2026-04-32 2100-02-29 2026-02-29; do
    i=$((i + 1))
    if [ $((i % 2)) -eq 0 ]; then ev pt "$bad" "bad-$i"; else ev en "$bad" "bad-$i"; fi >> "$tmp/CRITICAL_FACTS.md"
  done
  g1=$(ev en 2028-02-29 leap-en)
  g2=$(ev pt 2000-02-29 leap-pt)
  printf '%s\n' "$g1" "$g2" >> "$tmp/CRITICAL_FACTS.md"
  run_pack "$tmp" "$td"
  r=1
  if common; then
    if [ "$(printf '%s\n' "$out" | grep -c "$MID OVERDUE")" -ne 2 ]; then why="$(printf '%s\n' "$out" | grep -c "$MID OVERDUE") marks, expected 2"
    elif ! in_out "$g1 $MID OVERDUE 2028-02-29" || ! in_out "$g2 $MID OVERDUE 2000-02-29"; then why="a real leap day not marked"
    else r=0
    fi
  fi
  rm -rf "$tmp"
  verdict "O4 impossible dates (2026-02-30, 2026-13-01 and others) are not marked, real leap days are" "$r" "$why"
fi

# O5: a line inside a code fence is never marked, a fence that opens and
# never closes holds the rest, and near misses of the pattern pass intact.
fake_today 2031-05-17
y=$(day_shift 2031-05-17 -1)
if new_cos "O5 fences"; then
  in1=$(ev en "$y" in-backtick-fence)
  in2=$(ev pt "$y" in-tilde-fence)
  after=$(ev en "$y" after-fences)
  n1="* Capitalized (Event $y, checked $y)"
  n2="* No parenthesis event $y"
  n3="* Short date (event 2031-5-16, checked 2031-5-16)"
  n4="* Another word (eventual $y)"
  tail=$(ev pt "$y" in-open-fence)
  printf '%s\n' "$FIXTURE" '```text' "$in1" '```' '~~~' "$in2" '~~~' "$after" "$n1" "$n2" "$n3" "$n4" '```' "$tail" > "$tmp/CRITICAL_FACTS.md"
  run_pack "$tmp" "$td"
  r=1
  if common; then
    if [ "$(printf '%s\n' "$out" | grep -c "$MID OVERDUE")" -ne 1 ]; then why="$(printf '%s\n' "$out" | grep -c "$MID OVERDUE") marks, expected 1"
    elif ! in_out "$after $MID OVERDUE $y"; then why="the line after the fences not marked"
    elif ! in_out "$in1" || ! in_out "$in2" || ! in_out "$tail"; then why="a fenced line changed"
    elif ! in_out "$n1" || ! in_out "$n2" || ! in_out "$n3" || ! in_out "$n4"; then why="a near miss changed"
    else r=0
    fi
  fi
  rm -rf "$tmp"
  verdict "O5 fenced lines and near misses of the pattern are not marked" "$r" "$why"
fi

# O6: with no date from date, nothing is marked.
if new_cos "O6 date fails"; then
  e1=$(ev en 2001-01-01 long-past)
  printf '%s\n' "$FIXTURE" "$e1" > "$tmp/CRITICAL_FACTS.md"
  run_pack "$tmp" "$fakes/nodate"
  r=1
  if [ "$rc" -ne 0 ]; then why="exit $rc"
  elif ! in_out "$e1"; then why="event line changed"
  elif printf '%s\n' "$out" | grep -q OVERDUE; then why="OVERDUE in the pack"
  else r=0
  fi
  rm -rf "$tmp"
  verdict "O6 a failing date marks nothing" "$r" "$why"
fi

# o_section_ok: the CRITICAL_FACTS.md section of $out is at most 4000 bytes,
# every shown line with a past event ends in its mark, every other line has
# none, the fixed line is there exactly when a mark is, and the footer names
# the lines after the shown ones. PAST and FUT are the yesterday and the
# tomorrow of the case. Sets why.
o_section_ok() {
  why=""
  cfsec=$(section CRITICAL_FACTS.md)
  secb=$(printf '%s\n' "$cfsec" | wc -c | tr -d ' ')
  marks=$(printf '%s\n' "$cfsec" | grep -c "$MID OVERDUE")
  unmarked_past=$(printf '%s\n' "$cfsec" | grep -F "(event $PAST" | grep -vc "$MID OVERDUE $PAST\$")
  marked_future=$(printf '%s\n' "$cfsec" | grep -F "(event $FUT" | grep -c "OVERDUE")
  loose=$(printf '%s\n' "$out" | grep "OVERDUE" | grep -vF "(event $PAST" | grep -vcxF -- "$OVERDUE_LINE")
  fixed=$(printf '%s\n' "$out" | grep -cxF -- "$OVERDUE_LINE")
  shown=$(printf '%s\n' "$cfsec" | sed -n 's/^\([0-9]*\) of \([0-9]*\) lines shown\.$/\1/p')
  total=$(printf '%s\n' "$cfsec" | sed -n 's/^\([0-9]*\) of \([0-9]*\) lines shown\.$/\2/p')
  if [ "$secb" -gt 4000 ]; then why="section of $secb bytes"
  elif [ "$unmarked_past" -ne 0 ]; then why="$unmarked_past past events shown without the mark"
  elif [ "$marked_future" -ne 0 ]; then why="$marked_future future events marked"
  elif [ "$loose" -ne 0 ]; then why="$loose loose OVERDUE lines"
  elif [ "$marks" -gt 0 ] && [ "$fixed" -ne 1 ]; then why="$marks marks and $fixed fixed lines"
  elif [ "$marks" -eq 0 ] && [ "$fixed" -ne 0 ]; then why="a fixed line with no mark"
  elif [ -z "$shown" ] || [ -z "$total" ]; then why="no shown line"
  elif [ "$shown" -lt "$total" ] \
    && ! in_out "CRITICAL_FACTS.md: lines $((shown + 1)) to $total of $total are not shown."; then why="footer for $shown of $total"
  fi
  [ -z "$why" ]
}

# O7: the pack at its limit with marks. A big log and a big navigation fill
# the pack; CRITICAL_FACTS.md holds N event lines, odd ones past and even
# ones future, swept so the marks push the section over its cap at every
# place. Every case runs the common checks and o_section_ok.
fake_today 2031-05-17
PAST=$(day_shift 2031-05-17 -1)
FUT=$(day_shift 2031-05-17 1)
o7=""
o7_n=0
o7_cut=0
n=30
while [ "$n" -le 66 ]; do
  new_cos "O7" || break
  gen "$tmp/navigation.md" 9000 NAV_LINE
  gen_log "$tmp/memory/2031-05-17.md" 20000
  {
    echo "$FIXTURE"
    i=1
    while [ "$i" -le "$n" ]; do
      if [ $((i % 2)) -eq 1 ]; then ev en "$PAST" "e$i-padding-padding"; else ev en "$FUT" "e$i-padding-padding"; fi
      i=$((i + 1))
    done
  } > "$tmp/CRITICAL_FACTS.md"
  run_pack "$tmp" "$td"
  o7_n=$((o7_n + 1))
  w=""
  if ! common; then w="$why"
  elif ! o_section_ok; then w="$why"
  fi
  [ -n "$shown" ] && [ -n "$total" ] && [ "$shown" -lt "$total" ] && o7_cut=$((o7_cut + 1))
  [ -n "$w" ] && [ -z "$o7" ] && o7="$n events: $w"
  rm -rf "$tmp"
  n=$((n + 1))
done
r=0
{ [ -n "$o7" ] || [ "$o7_n" -ne 37 ] || [ "$o7_cut" -eq 0 ] || [ "$o7_cut" -eq "$o7_n" ]; } && r=1
verdict "O7 pack at its limit with marks: section within 4000, pack within 8000 ($o7_n cases, $o7_cut cut)" "$r" "${o7:-cut in $o7_cut of $o7_n}"

# O8: a line cut by the budget leaves no loose mark. Filler of every size in
# a window puts the cap before, inside and after the one past event, which
# is the last line; the fixed line rides only with a shown mark.
o8=""
o8_n=0
o8_shown=0
o8_cut=0
last=$(ev en "$PAST" the-last-line-of-the-file)
b=3700
while [ "$b" -le 3960 ]; do
  new_cos "O8" || break
  { gen /dev/stdout "$b" CF_FILL; echo "$last"; } > "$tmp/CRITICAL_FACTS.md"
  run_pack "$tmp" "$td"
  o8_n=$((o8_n + 1))
  w=""
  if ! common; then w="$why"
  elif ! o_section_ok; then w="$why"
  elif in_out "$last $MID OVERDUE $PAST"; then o8_shown=$((o8_shown + 1))
  elif printf '%s\n' "$out" | grep -qF -- "$last"; then w="the event shown without its mark"
  elif printf '%s\n' "$out" | grep -q OVERDUE; then w="OVERDUE with the event cut"
  else o8_cut=$((o8_cut + 1))
  fi
  [ -n "$w" ] && [ -z "$o8" ] && o8="filler of $b bytes: $w"
  rm -rf "$tmp"
  b=$((b + 1))
done
r=0
{ [ -n "$o8" ] || [ "$o8_shown" -eq 0 ] || [ "$o8_cut" -eq 0 ]; } && r=1
verdict "O8 a line cut by the budget leaves no loose mark ($o8_n cases: $o8_shown shown marked, $o8_cut cut)" "$r" "${o8:-shown $o8_shown, cut $o8_cut}"

# O9: differential oracle. With no line in the new format that is overdue
# (legacy lines, future and today's events, impossible dates, fenced events,
# near misses, or past events with a failing date), the pack is byte for
# byte the pack of the hook at the base dd1520d, over generated shapes.
base_hook="$fakes/base-boot-memory.sh"
o9=""
o9_n=0
if ! git -C "$REPO" show dd1520d:hooks/boot-memory.sh > "$base_hook" 2>/dev/null || [ ! -s "$base_hook" ]; then
  o9="base copy dd1520d:hooks/boot-memory.sh not readable from git"
else
  y=$(day_shift 2031-05-17 -1)
  for variant in legacy future impossible fenced pastnodate; do
    for cf_size in 300 3990 5000; do
      for nav_size in 40 5543 9000; do
        for log_kind in none big; do
          for legacy_nav in no yes; do
            new_cos "O9" || continue
            front="$fakes/today-2031-05-17"
            {
              echo "$FIXTURE"
              case "$variant" in
                legacy) echo "* A legacy fact (with a parenthesis 2031-05-01)" ;;
                future) ev en 2031-05-17 today-en; ev pt "$(day_shift 2031-05-17 1)" amanhã; ev en 2099-12-31 far ;;
                impossible) ev en 2026-02-30 feb-30; ev pt 2026-13-01 mes-13; ev en 2027-02-29 not-leap ;;
                fenced) printf '%s\n' '```' "$(ev en "$y" fenced)" '```' "* (Event $y)" "* event $y" "* (eventual $y)" ;;
                pastnodate) ev en "$y" past-en; ev pt 2001-01-01 passado; front="$fakes/nodate" ;;
              esac
              gen /dev/stdout "$cf_size" CF_ORACLE
            } > "$tmp/CRITICAL_FACTS.md"
            gen "$tmp/navigation.md" "$nav_size" NAV_LINE
            [ "$legacy_nav" = yes ] && cp "$tmp/navigation.md" "$tmp/navegacao.md"
            [ "$log_kind" = big ] && gen_log "$tmp/memory/2031-05-17.md" 6000
            (cd "$tmp" && PATH="$front:$PATH" sh "$base_hook" > "$fakes/o9-base" 2>/dev/null)
            (cd "$tmp" && PATH="$front:$PATH" sh "$HOOK" > "$fakes/o9-new" 2>/dev/null)
            o9_n=$((o9_n + 1))
            if ! cmp -s "$fakes/o9-base" "$fakes/o9-new" || [ ! -s "$fakes/o9-new" ]; then
              [ -n "$o9" ] || o9="$variant, facts $cf_size, navigation $nav_size, log $log_kind, navegacao.md $legacy_nav: packs differ"
            fi
            rm -rf "$tmp"
          done
        done
      done
    done
  done
fi
r=0
{ [ -n "$o9" ] || [ "$o9_n" -ne 180 ]; } && r=1
verdict "O9 differential oracle: with nothing overdue the pack is byte for byte the one of dd1520d ($o9_n shapes)" "$r" "$o9"

rm -rf "$fakes"

# Cases C1 to C7 (agents-md spec, part 2): the handoff to the memoria-agente
# engine. Every folder starts from the old layout (CLAUDE.md +
# CRITICAL_FACTS.md) so the gate passes. The proof is a file under
# .claude/data with a fresh mtime (touch without a date) or one forced by
# touch -t.
CEDE="memoria-agente present, session-start injection handed to the engine"

# Folder of this host under sensor-efeito. When uname -n has only
# [A-Za-z0-9._-], no leading dot and at most 64 characters, the engine rule
# is the identity and the test uses the name itself. Otherwise the test
# derives the name on its own (without copying the hook) and says so.
HOST_RAW=$(uname -n 2>/dev/null)
case "$HOST_RAW" in
  ''|.*|*[!A-Za-z0-9._-]*) identity=no ;;
  *) identity=yes ;;
esac
[ "${#HOST_RAW}" -le 64 ] || identity=no
if [ "$identity" = yes ]; then
  HOST_DIR="$HOST_RAW"
else
  HOST_DIR=$(printf '%s' "$HOST_RAW" | LC_ALL=C cut -c1-64 | LC_ALL=C sed 's/[^A-Za-z0-9._-]/-/g; s/^\.\{1,\}//' | LC_ALL=C cut -c1-64)
  [ -n "$HOST_DIR" ] || HOST_DIR=sem-host
  echo "info  hostname outside the identity, C1/C5/C6/C8/C9 run with a derived name: $HOST_DIR"
fi

# case_c NAME EXPECTED CONFIG PROOF DATE [PATH_DIR]
# EXPECTED: hands-off or boots. CONFIG: yes or no. PROOF: path under
# .claude/data; ending in / becomes an empty folder, not a file. DATE: fresh,
# or the touch -t stamp (in UTC, no daylight saving). PATH_DIR: folder put in
# front of PATH only while the hook runs (the fake uname of the H and K
# cases).
case_c() {
  name="$1"
  expected="$2"
  config="$3"
  proof="$4"
  stamp="$5"
  in_front="$6"
  if [ -z "$stamp" ]; then
    echo "FAIL  $name: empty date stamp"
    failures=$((failures + 1))
    return
  fi
  tmp=$(mktemp -d 2>/dev/null)
  if [ -z "$tmp" ] || [ ! -d "$tmp" ]; then
    echo "FAIL  $name: mktemp -d returned no folder"
    failures=$((failures + 1))
    return
  fi
  echo "@AGENTS.md" > "$tmp/CLAUDE.md"
  echo "$FIXTURE" > "$tmp/CRITICAL_FACTS.md"
  mkdir -p "$tmp/.claude/data/$(dirname "$proof")"
  [ "$config" = yes ] && echo "{}" > "$tmp/.claude/memoria-config.json"
  case "$proof" in
    */) mkdir -p "$tmp/.claude/data/$proof" ;;
    *) echo "{}" > "$tmp/.claude/data/$proof" ;;
  esac
  if [ "$stamp" != fresh ]; then
    TZ=UTC0 touch -t "$stamp" "$tmp/.claude/data/$proof"
  fi
  if [ -n "$in_front" ]; then
    out=$(cd "$tmp" && PATH="$in_front:$PATH" "$HOOK" 2>/dev/null)
  else
    out=$(cd "$tmp" && "$HOOK" 2>/dev/null)
  fi
  rc=$?
  rm -rf "$tmp"
  first=$(printf '%s\n' "$out" | sed -n 1p)
  if [ "$expected" = hands-off ]; then
    if [ "$rc" -eq 0 ] && [ "$out" = "$CEDE" ]; then
      echo "ok    $name"
    else
      echo "FAIL  $name: expected only the handoff line (exit $rc, first line: $first)"
      failures=$((failures + 1))
    fi
  else
    if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -qxF "$MARCA"; then
      echo "ok    $name"
    else
      echo "FAIL  $name: expected a full boot (exit $rc, first line: $first)"
      failures=$((failures + 1))
    fi
  fi
}

case_c "C1 fresh sensor of this host" hands-off yes "sensor-efeito/$HOST_DIR/2026-10.jsonl" fresh
case_c "C2 fresh sensor of another host" boots yes "sensor-efeito/outra-maquina-de-teste/2026-10.jsonl" fresh
# C3 and C7 rewritten in audit fix 1 (finding B1): the logs without a host
# get a fresh date on every clone, so they stopped being proof and boot.
case_c "C3 fresh judge log" boots yes "juiz-escrita-log.jsonl" fresh
case_c "C4 judge log from 2026-10-12" boots yes "juiz-escrita-log.jsonl" 202610120000
case_c "C5 without config" boots no "sensor-efeito/$HOST_DIR/2026-10.jsonl" fresh
case_c "C6 old sensor of this host" boots yes "sensor-efeito/$HOST_DIR/2000-01.jsonl" 200001010000
case_c "C7 fresh sensor-efeito-log" boots yes "sensor-efeito-log.jsonl" fresh

# Cases C8 and C9 from audit fix 1 (finding A1): the edge of the 2-day
# window. -mtime -2 is an age below 48 h; 47 h hands off and 49 h boots, with
# 1 h of slack on each side. The stamp is "now minus N hours", by the macOS
# date (-v) or the Linux one (-d). date and touch -t run in UTC (TZ=UTC0): in
# the local zone, one hour a year the 47 h stamp falls in the hour that
# daylight saving repeats, and touch -t writes the first of the two.
hours_ago() {
  TZ=UTC0 date -v-"$1"H +%Y%m%d%H%M 2>/dev/null || TZ=UTC0 date -d "$1 hours ago" +%Y%m%d%H%M 2>/dev/null
}
case_c "C8 sensor of this host at 47 h" hands-off yes "sensor-efeito/$HOST_DIR/2026-10.jsonl" "$(hours_ago 47)"
case_c "C9 sensor of this host at 49 h" boots yes "sensor-efeito/$HOST_DIR/2026-10.jsonl" "$(hours_ago 49)"

# Cases H1 to H8 from audit fix 1 (finding A2): the host name rule. A fake
# uname, in a folder put in front of PATH only while the hook runs, serves
# the name; the fresh proof sits in the folder the engine writes. The
# expected folders are literals from the REGRA table of the "sensor 7n-t"
# case in the engine's tests/smoke.sh (origin/main 3558597), except H7,
# which is the engine's pasta_do_host run on the name cut at 64 (the cut in
# host_maquina). Nothing here creates an environment variable or changes the
# hook.
# case_h NAME RAW DIR [EXPECTED]; RAW "-fail-" makes uname exit with an
# error. EXPECTED is hands-off when omitted; DIR ending in / is the fresh,
# empty host folder, with no proof inside.
case_h() {
  fake=$(mktemp -d 2>/dev/null)
  if [ -z "$fake" ] || [ ! -d "$fake" ]; then
    echo "FAIL  $1: mktemp -d returned no folder"
    failures=$((failures + 1))
    return
  fi
  if [ "$2" = "-fail-" ]; then
    printf '#!/bin/sh\necho "fake uname: error" >&2\nexit 1\n' > "$fake/uname"
  else
    printf '%s\n' "$2" > "$fake/name"
    printf '#!/bin/sh\ncat "%s/name"\n' "$fake" > "$fake/uname"
  fi
  chmod +x "$fake/uname"
  case "$3" in
    */) case_c "$1" "${4:-hands-off}" yes "sensor-efeito/$3" fresh "$fake" ;;
    *) case_c "$1" "${4:-hands-off}" yes "sensor-efeito/$3/2026-10.jsonl" fresh "$fake" ;;
  esac
  rm -rf "$fake"
}
case_h "H1 leading dot is dropped" ".oculto" "oculto"
case_h "H2 slash becomes hyphen" "a/b" "a-b"
case_h "H3 spaces become hyphens" "  " "--"
case_h "H4 only dots becomes sem-host" "..." "sem-host"
case_h "H5 empty becomes sem-host" "" "sem-host"
case_h "H6 80 characters cut at 64" \
  "hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh" \
  "hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh"
case_h "H7 cut at 64 before dropping the dots" \
  "..........aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" \
  "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
case_h "H8 failing uname becomes sem-host" "-fail-" "sem-host"

# Cases K1 and K2 from audit fix 2 (finding K1 of the Codex review): only a
# regular file inside this host's folder is proof of life. A folder named
# like a .jsonl does not count, nor the host folder itself when the machine
# name ends in .jsonl (find would test the starting point).
case_c "K1 folder 2026-10.jsonl in this host's folder" boots yes "sensor-efeito/$HOST_DIR/2026-10.jsonl/" fresh
case_h "K2 host ending in .jsonl with an empty folder" "maquina.jsonl" "maquina.jsonl/" boots

# Cases R1 to R5 (codex-compat-funcional spec): the Codex runtime and the
# path with spaces. The memoria-agente engine writes telemetry only from
# Claude, so Codex never hands off to it: the Codex registration passes the
# codex marker to the hook, and without the marker the hook follows the
# usual handoff. R1 runs the hook directly; R2 to R5 read the command of each
# registration (hooks/hooks.json for Claude and the inline hook in
# .codex-plugin/plugin.json) and run it through sh -c, as both agents run a
# hook command, with the plugin root in a folder with spaces.
# case_r NAME EXPECTED FILE KEY VAR
# EXPECTED: hands-off or boots. FILE: registration relative to the repo
# root. KEY: dotted path of the command in the JSON. VAR: variable holding
# the plugin root. Every folder has the config and fresh proof of life for
# this host, the handoff condition under Claude.
json_command() {
  if command -v plutil >/dev/null 2>&1; then
    plutil -extract "$2" raw -o - "$1" 2>/dev/null
  elif command -v node >/dev/null 2>&1; then
    node -e 'let v=require(process.argv[1]);for(const k of process.argv[2].split("."))v=v==null?v:v[k];if(typeof v!=="string")process.exit(1);process.stdout.write(v)' "$1" "$2" 2>/dev/null
  else
    return 1
  fi
}
ROOT=$(cd "$DIR/.." && pwd)
case_r() {
  name="$1"
  expected="$2"
  cmd=$(json_command "$ROOT/$3" "$4")
  if [ -z "$cmd" ]; then
    echo "FAIL  $name: command missing in $3 ($4), or neither plutil nor node to read it"
    failures=$((failures + 1))
    return
  fi
  tmp=$(mktemp -d 2>/dev/null)
  if [ -z "$tmp" ] || [ ! -d "$tmp" ]; then
    echo "FAIL  $name: mktemp -d returned no folder"
    failures=$((failures + 1))
    return
  fi
  package="$tmp/pacote do plugin"
  work="$tmp/user work folder"
  mkdir -p "$package/hooks" "$work/.claude/data/sensor-efeito/$HOST_DIR"
  cp -p "$HOOK" "$package/hooks/boot-memory.sh"
  echo "@AGENTS.md" > "$work/CLAUDE.md"
  echo "$FIXTURE" > "$work/CRITICAL_FACTS.md"
  echo "{}" > "$work/.claude/memoria-config.json"
  echo "{}" > "$work/.claude/data/sensor-efeito/$HOST_DIR/2026-10.jsonl"
  out=$(cd "$work" && env "$5=$package" sh -c "$cmd" 2>/dev/null)
  rc=$?
  rm -rf "$tmp"
  first=$(printf '%s\n' "$out" | sed -n 1p)
  if [ "$expected" = hands-off ]; then
    if [ "$rc" -eq 0 ] && [ "$out" = "$CEDE" ]; then
      echo "ok    $name"
    else
      echo "FAIL  $name: expected only the handoff line (exit $rc, first line: $first)"
      failures=$((failures + 1))
    fi
  else
    if boots; then
      echo "ok    $name"
    else
      echo "FAIL  $name: expected a full boot (exit $rc, first line: $first)"
      failures=$((failures + 1))
    fi
  fi
}

# R1: the hook run directly with the codex marker while the engine is alive
# under Claude.
tmp=$(mktemp -d 2>/dev/null)
echo "@AGENTS.md" > "$tmp/CLAUDE.md"
echo "$FIXTURE" > "$tmp/CRITICAL_FACTS.md"
mkdir -p "$tmp/.claude/data/sensor-efeito/$HOST_DIR"
echo "{}" > "$tmp/.claude/memoria-config.json"
echo "{}" > "$tmp/.claude/data/sensor-efeito/$HOST_DIR/2026-10.jsonl"
out=$(cd "$tmp" && "$HOOK" codex 2>/dev/null)
rc=$?
rm -rf "$tmp"
if boots; then
  echo "ok    R1 codex marker does not hand off to the Claude engine"
else
  echo "FAIL  R1 codex marker: expected a full boot (exit $rc)"
  failures=$((failures + 1))
fi

case_r "R2 Claude startup registration with spaces hands off" hands-off \
  hooks/hooks.json hooks.SessionStart.0.hooks.0.command CLAUDE_PLUGIN_ROOT
case_r "R3 Claude clear registration with spaces hands off" hands-off \
  hooks/hooks.json hooks.SessionStart.1.hooks.0.command CLAUDE_PLUGIN_ROOT
case_r "R4 Codex startup registration with spaces boots" boots \
  .codex-plugin/plugin.json hooks.hooks.SessionStart.0.hooks.0.command CLAUDE_PLUGIN_ROOT
case_r "R5 Codex clear registration with spaces boots" boots \
  .codex-plugin/plugin.json hooks.hooks.SessionStart.1.hooks.0.command CLAUDE_PLUGIN_ROOT
# R6 and R7 (boot-budget spec): the compact registration, added after the
# two existing ones, runs the same command.
case_r "R6 Claude compact registration with spaces hands off" hands-off \
  hooks/hooks.json hooks.SessionStart.2.hooks.0.command CLAUDE_PLUGIN_ROOT
case_r "R7 Codex compact registration with spaces boots" boots \
  .codex-plugin/plugin.json hooks.hooks.SessionStart.2.hooks.0.command CLAUDE_PLUGIN_ROOT

# R8 (boot-budget spec, scoped to SessionStart by the stop-size-gate spec):
# only the SessionStart handlers count, since both registries also carry
# the UserPromptSubmit and Stop handlers of size-gate.sh. Matchers in order
# startup, clear, compact in both registries, and in Codex three
# SessionStart commands, each raising its context limit to 3500.
# session_start FILE: the lines of the SessionStart array, from its key to
# the closing bracket at the same indentation.
session_start() {
  awk '
    !on && /"SessionStart": *\[/ { on = 1; match($0, /^ */); ind = RLENGTH; print; next }
    on { print; if (match($0, /^ *\]/) && RLENGTH - 1 == ind) exit }
  ' "$1"
}
ss_claude=$(session_start "$ROOT/hooks/hooks.json")
ss_codex=$(session_start "$ROOT/.codex-plugin/plugin.json")
m_claude=$(printf '%s\n' "$ss_claude" | grep -o '"matcher": *"[a-z]*"' | sed 's/.*"\([a-z]*\)"$/\1/' | tr '\n' ' ')
m_codex=$(printf '%s\n' "$ss_codex" | grep -o '"matcher": *"[a-z]*"' | sed 's/.*"\([a-z]*\)"$/\1/' | tr '\n' ' ')
n_cmd=$(printf '%s\n' "$ss_codex" | grep -c '"command": ')
n_lim=$(printf '%s\n' "$ss_codex" | grep -c '"additionalContextLimit": 3500')
if [ "$m_claude" = "startup clear compact " ] && [ "$m_codex" = "startup clear compact " ] \
  && [ "$n_cmd" -eq 3 ] && [ "$n_lim" -eq 3 ]; then
  echo "ok    R8 compact matcher in both registries and the Codex context limit"
else
  echo "FAIL  R8 registries: Claude [$m_claude], Codex [$m_codex], $n_cmd commands, $n_lim limits"
  failures=$((failures + 1))
fi

[ "$failures" -eq 0 ] || exit 1
exit 0
