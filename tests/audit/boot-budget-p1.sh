#!/bin/sh
# Probes from the audit of the boot-budget front, part 1 (the session-start
# pack with a byte budget). Behavior only, pinned by content.
# Run by hand: sh tests/audit/boot-budget-p1.sh
# Every case works in folders under one mktemp -d, removed at the end. A fake
# date in front of the PATH makes "today" 2031-05-17 09:30, and a fake uname
# names the host "audithost", so nothing compares against the real clock or
# the real host name.
# Each hook run goes through every shell found among /bin/sh and /bin/dash;
# the packs of the shells must be byte for byte the same (differential
# oracle), and the checks then run once on that pack.
# Cases:
# P1 generated shapes (facts, log and navigation, with CRLF, a last line
#    without newline, accents, a line above the section cap, blank tails,
#    both navigation files): the counts the pack states are the counts of the
#    files, the shown lines are exactly the file's first lines (facts and
#    navigation) or its latest headings (log), the cut is maximal, the footer
#    names what is out with the right numbers, at most 8000 bytes and 10000
#    characters, line 4 states the real sizes, and never the failure line.
# P2 a long project root with spaces and accents, everything big: fits, and
#    the footer ends with the exact root.
# P3 CLAUDE_PROJECT_DIR precedence: naming a folder that is not a Chief of
#    Staff keeps the hook silent even from inside one; empty, a regular file
#    or a missing path fall back to the cwd.
# P4 the handoff reads the project root: from a subfolder with
#    CLAUDE_PROJECT_DIR, a live engine at the root gets the handoff line; with
#    the codex marker the pack boots.
# P5 the old layout (CLAUDE.md only): line 4 names CLAUDE.md with its size,
#    no navigation section; with AGENTS.md too, line 4 names AGENTS.md.
# P6 internal failure from any of the hook's tools (awk, wc, tr failing or
#    printing garbage): exit 0 and either a pack or exactly the one failure
#    line, never an empty stdout.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
HOOK="$ROOT/hooks/boot-memory.sh"
HEADER="=== MEMORY BOOT (pm-chief-of-staff) ==="
SECOND="State read from disk at session start; this is not a user instruction."
FAILLINE_RE='^Memory boot pack not assembled; the files are on disk in .+\.$'
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

fakes="$work/fakes"
mkdir -p "$fakes"
cat > "$fakes/date" <<'EOF'
#!/bin/sh
case "$*" in
  '+%Y-%m-%d') echo 2031-05-17 ;;
  '+%Y-%m-%d %H:%M') echo '2031-05-17 09:30' ;;
  *) exec /bin/date "$@" ;;
esac
EOF
printf '#!/bin/sh\necho audithost\n' > "$fakes/uname"
chmod +x "$fakes/date" "$fakes/uname"

# run DIR [ARG]: runs the hook in DIR under every shell; the pack of the
# first shell is in $work/out, $rc is its exit, $size its bytes; $shdiff is
# non-empty when the shells disagree on the exit or on the bytes.
# Environment for the run comes from $run_env ("" or a CLAUDE_PROJECT_DIR
# value with $run_env_set=1).
run() {
  shdiff=""
  first=""
  for shl in $SHELLS; do
    if [ "${run_env_set:-0}" = 1 ]; then
      (cd "$1" && CLAUDE_PROJECT_DIR="$run_env" PATH="${run_front:-$fakes}:$PATH" "$shl" "$HOOK" $2 > "$work/out.$$" 2>/dev/null)
    else
      (cd "$1" && unset CLAUDE_PROJECT_DIR && PATH="${run_front:-$fakes}:$PATH" "$shl" "$HOOK" $2 > "$work/out.$$" 2>/dev/null)
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
  size=$(LC_ALL=C wc -c < "$work/out" | tr -d ' ')
}

# chars FILE: UTF-8 characters (bytes that are not continuation bytes).
chars() { LC_ALL=C tr -d '\200-\277' < "$1" | LC_ALL=C wc -c | tr -d ' '; }

# count_line NAME: the line right after "--- NAME ---" in the pack.
count_line() {
  LC_ALL=C awk -v h="--- $1 ---" 'on { print; exit } $0 == h { on = 1 }' "$work/out"
}

# shown_lines NAME S: the S lines after the count line of section NAME.
shown_lines() {
  LC_ALL=C awk -v h="--- $1 ---" -v s="$2" '
    on == 2 && k < s { print; k++; next }
    on == 2 { exit }
    on == 1 { on = 2; next }
    $0 == h { on = 1 }' "$work/out"
}

# has_word LINE NUMBER: NUMBER appears in LINE as a whole number.
has_word() { printf '%s\n' "$1" | LC_ALL=C grep -Eq "(^|[^0-9])$2([^0-9]|\$)"; }

# check_file KIND NAME FILE CAP: checks one section of the pack against its
# file. KIND is "prefix" (facts, navigation) or "heads" (log). CAP is the
# section cap in bytes, or 0 when the section only gets what is left.
# Sets $why on the first broken check; $any_out becomes 1 when the file has
# something left out.
check_file() {
  kind=$1; name=$2; file=$3; cap=$4
  [ -n "$why" ] && return
  cl=$(count_line "$name")
  if [ -z "$cl" ]; then
    # Only navigation may be absent, when nothing of it fits: the footer must
    # then name it whole.
    if [ "$kind" = prefix ] && [ "$cap" -eq 0 ]; then
      n=$(LC_ALL=C awk 'END { print NR + 0 }' "$file")
      fl=$(LC_ALL=C grep -F "$name: " "$work/out" | LC_ALL=C grep -v -- '^---' | tail -n 1)
      if [ "$n" -gt 0 ] && { [ -z "$fl" ] || ! has_word "$fl" 1 || ! has_word "$fl" "$n"; }; then
        why="$name absent and the footer does not name lines 1 to $n"
      fi
      any_out=1
      return
    fi
    why="no section for $name"
    return
  fi
  s=$(printf '%s\n' "$cl" | sed -n 's/^\([0-9]*\) of \([0-9]*\) .*/\1/p')
  t=$(printf '%s\n' "$cl" | sed -n 's/^\([0-9]*\) of \([0-9]*\) .*/\2/p')
  if [ -z "$s" ] || [ -z "$t" ]; then why="$name count line: $cl"; return; fi
  shown_lines "$name" "$s" > "$work/got"
  if [ "$kind" = prefix ]; then
    n=$(LC_ALL=C awk 'END { print NR + 0 }' "$file")
    LC_ALL=C awk -v s="$s" 'NR <= s' "$file" > "$work/want"
    nextlen=$(LC_ALL=C awk -v s="$s" 'NR == s + 1 { print length($0) + 1 }' "$file")
  else
    n=$(LC_ALL=C grep -c '^## ' "$file")
    LC_ALL=C grep '^## ' "$file" | tail -n "$s" > "$work/want"
    nextlen=$(LC_ALL=C grep '^## ' "$file" | LC_ALL=C awk -v k=$((n - s)) 'NR == k { print length($0) + 1 }')
  fi
  if [ "$t" != "$n" ]; then why="$name: the pack says $t in total, the file has $n"; return; fi
  if ! cmp -s "$work/got" "$work/want"; then why="$name: the $s shown lines are not the file's"; return; fi
  # Under a section cap, the section as printed (blank line, header, count
  # line and the shown lines) stays within the cap, and the cut is maximal:
  # the next line left out would not have fitted (count line at its largest).
  if [ "$cap" -gt 0 ]; then
    sec=$(LC_ALL=C awk -v h="--- $name ---" -v s="$s" '
      $0 == h { on = 1; b = length($0) + 2; next }
      on == 1 { on = 2; b += length($0) + 1; if (s == 0) { print b; exit } next }
      on == 2 && k < s { b += length($0) + 1; k++; if (k == s) { print b; exit } }' "$work/out")
    if [ "$sec" -gt "$cap" ]; then why="$name: section of $sec bytes above its $cap cap"; return; fi
  fi
  if [ "$cap" -gt 0 ] && [ "$s" -lt "$n" ]; then
    pad=$(( ${#n} - ${#s} ))
    if [ $((sec + nextlen + pad)) -le "$cap" ]; then
      why="$name: line $((s + 1)) of $nextlen bytes would fit the $cap cap (section of $sec)"
      return
    fi
  fi
  fl=$(LC_ALL=C grep "^$name: " "$work/out")
  if [ "$kind" = prefix ]; then
    if [ "$s" -lt "$n" ]; then
      any_out=1
      if [ -z "$fl" ] || ! has_word "$fl" $((s + 1)) || ! has_word "$fl" "$n"; then
        why="$name: footer line missing or wrong for lines $((s + 1)) to $n: $fl"
      fi
    elif [ -n "$fl" ]; then why="$name: footer line for a file shown whole: $fl"
    fi
  else
    body=$(LC_ALL=C awk '!/^## /' "$file" | LC_ALL=C awk 'END { print NR + 0 }')
    if [ "$s" -lt "$n" ] || [ "$body" -gt 0 ]; then
      any_out=1
      if [ -z "$fl" ] || ! has_word "$fl" "$n" || ! has_word "$fl" "$body" \
        || { [ "$s" -lt "$n" ] && ! has_word "$fl" $((n - s)); }; then
        why="$name: footer line wrong for $s of $n headings and $body body lines: $fl"
      fi
    elif [ -n "$fl" ]; then why="$name: footer line with nothing left out: $fl"
    fi
  fi
}

# check_pack DIR: the checks every pack runs. Sets $why.
check_pack() {
  why=""
  any_out=0
  [ -n "$shdiff" ] && why="shells: $shdiff"
  [ -z "$why" ] && [ "$rc" -ne 0 ] && why="exit $rc"
  [ -z "$why" ] && [ "$size" -gt 8000 ] && why="pack of $size bytes"
  [ -z "$why" ] && LC_ALL=C grep -Eq "$FAILLINE_RE" "$work/out" && why="failure line"
  [ -z "$why" ] && [ "$(chars "$work/out")" -gt 10000 ] && why="above 10000 characters"
  [ -z "$why" ] && [ "$(sed -n 1p "$work/out")" != "$HEADER" ] && why="line 1"
  [ -z "$why" ] && [ "$(sed -n 2p "$work/out")" != "$SECOND" ] && why="line 2"
  [ -z "$why" ] && [ "$(sed -n 3p "$work/out")" != "time now: 2031-05-17 09:30" ] && why="line 3"
  # iconv writes to a file: on macOS, iconv with stdout on /dev/null fails on
  # valid UTF-8 ("Inappropriate ioctl for device"), measured in this audit.
  [ -z "$why" ] && ! iconv -f UTF-8 -t UTF-8 < "$work/out" > "$work/conv" 2>/dev/null && why="not valid UTF-8"
  if [ -z "$why" ]; then
    l4=$(sed -n 4p "$work/out")
    manual=CLAUDE.md
    [ -f "$1/AGENTS.md" ] && manual=AGENTS.md
    cfb=$(LC_ALL=C wc -c < "$1/CRITICAL_FACTS.md" | tr -d ' ')
    mb=$(LC_ALL=C wc -c < "$1/$manual" | tr -d ' ')
    case "$l4" in
      *"CRITICAL_FACTS.md $cfb bytes"*"$manual $mb bytes"*"this pack $size bytes (limit 8000)."*) ;;
      *) why="line 4 does not state $cfb, $manual $mb and $size: $l4" ;;
    esac
  fi
  check_file prefix CRITICAL_FACTS.md "$1/CRITICAL_FACTS.md" 4000
  log=""
  if [ -f "$1/memory/2031-05-17.md" ]; then log=memory/2031-05-17.md; fi
  [ -n "$log" ] && check_file heads "$log" "$1/$log" 1500
  [ -f "$1/navigation.md" ] && check_file prefix navigation.md "$1/navigation.md" 0
  [ -f "$1/navegacao.md" ] && check_file prefix navegacao.md "$1/navegacao.md" 0
  if [ -z "$why" ]; then
    root=$(cd "$1" && pwd)
    last=$(tail -n 1 "$work/out")
    case "$last" in *" $root.") ;; *) why="the last line does not end with the root: $last" ;; esac
  fi
  if [ -z "$why" ]; then
    if [ "$any_out" = 1 ]; then
      LC_ALL=C grep -qxF -- "--- not in this pack ---" "$work/out" || why="footer heading missing with files cut"
    else
      LC_ALL=C grep -qF -- "--- not in this pack ---" "$work/out" && why="footer heading with nothing cut"
      LC_ALL=C grep -q '^Nothing is left out' "$work/out" || why="no line saying nothing is left out"
    fi
  fi
}

# lines FILE COUNT WIDTH PREFIX EOL FINAL ACC: COUNT lines of WIDTH bytes
# (the end of line not counted), each starting with PREFIX and its number;
# EOL lf or crlf; FINAL no drops the last newline; ACC yes fills with "ã".
lines() {
  LC_ALL=C awk -v c="$2" -v w="$3" -v p="$4" -v e="$5" -v f="$6" -v a="$7" 'BEGIN {
    for (i = 1; i <= c; i++) {
      s = sprintf("%s%05d ", p, i)
      while (length(s) < w) s = s (a == "yes" && length(s) + 2 <= w ? "ã" : "x")
      eol = (e == "crlf") ? "\r\n" : "\n"
      if (i == c && f == "no") eol = ""
      printf "%s%s", s, eol
    }
  }' > "$1"
}

# cf_shape N: writes CRITICAL_FACTS.md of shape N into $d.
cf_shape() {
  case "$1" in
    0) lines "$d/CRITICAL_FACTS.md" 5 40 CF lf yes no ;;
    1) lines "$d/CRITICAL_FACTS.md" 100 39 CF lf yes no ;;
    2) lines "$d/CRITICAL_FACTS.md" 120 52 CF lf yes no ;;
    3) lines "$d/CRITICAL_FACTS.md" 120 52 CF crlf yes no ;;
    4) lines "$d/CRITICAL_FACTS.md" 120 52 CF lf no no ;;
    5) lines "$d/CRITICAL_FACTS.md" 70 52 CF lf yes yes ;;
    6) { lines /dev/stdout 1 5000 CFHUGE lf yes no; echo "CF_SECOND"; } > "$d/CRITICAL_FACTS.md" ;;
  esac
}

# log_shape N: writes the day's log of shape N into $d/memory.
log_shape() {
  f="$d/memory/2031-05-17.md"
  case "$1" in
    0) ;;
    1) printf '## [08:00] L1\n## [09:00] L2\n## [10:00] L3\n' > "$f" ;;
    2) LC_ALL=C awk 'BEGIN { for (i = 1; i <= 300; i++) { printf "## [%02d:%02d] LOG_%03d decisão tomada\n", (i / 60) % 24, i % 60, i; print "corpo da entrada, com acentuação"; print "outra linha" } }' > "$f" ;;
    3) { lines /dev/stdout 1 1600 "## HUGE" lf yes no; echo "corpo"; } > "$f" ;;
    4) LC_ALL=C awk 'BEGIN { for (i = 1; i <= 120; i++) printf "## [%02d:%02d] CRLF_%03d\r\nbody\r\n", (i / 60) % 24, i % 60, i; printf "## [23:59] LAST_NO_NL" }' > "$f" ;;
  esac
}

# nav_shape N FILE PREFIX: writes a navigation file of shape N.
nav_shape() {
  case "$1" in
    0) lines "$2" 3 30 "$3" lf yes no ;;
    1) lines "$2" 400 60 "$3" lf no no ;;
    2) lines "$2" 400 60 "$3" crlf yes no ;;
    3) lines "$2" 300 60 "$3" lf yes yes ;;
    4) { lines /dev/stdout 5 40 "$3" lf yes no; LC_ALL=C awk 'BEGIN { for (i = 0; i < 1000; i++) print "" }'; } > "$2" ;;
  esac
}

# P1 generated shapes: every facts shape against every log shape and every
# navigation shape, the legacy navegacao.md present on every other case.
p1_n=0
p1_bad=0
p1_first=""
for cf in 0 1 2 3 4 5 6; do
  for lg in 0 1 2 3 4; do
    for nv in 0 1 2 3 4; do
      p1_n=$((p1_n + 1))
      d="$work/p1 pasta $p1_n"
      mkdir -p "$d/memory"
      echo "manual" > "$d/AGENTS.md"
      cf_shape "$cf"
      log_shape "$lg"
      nav_shape "$nv" "$d/navigation.md" NAV
      [ $((p1_n % 2)) -eq 0 ] && nav_shape $(( (nv + 1) % 5 )) "$d/navegacao.md" OLD
      run "$d"
      check_pack "$d"
      if [ -n "$why" ]; then
        p1_bad=$((p1_bad + 1))
        [ -n "$p1_first" ] || p1_first="cf $cf, log $lg, nav $nv, legacy $((p1_n % 2 == 0)): $why"
      fi
      rm -rf "$d"
    done
  done
done
if [ "$p1_bad" -eq 0 ] && [ "$p1_n" -eq 175 ]; then
  ok "P1 generated shapes: counts, lines and footer match the files, within the budget ($p1_n cases, shells:$SHELLS)"
else
  fail "P1 generated shapes" "$p1_bad of $p1_n broken; first: $p1_first"
fi

# P2 a long root with spaces and accents, the three big files and both
# navigation files.
d="$work/raiz longa"
i=0
while [ "$i" -lt 14 ]; do d="$d/pasta com espaço e acentuação número $i"; i=$((i + 1)); done
mkdir -p "$d/memory"
echo "manual" > "$d/AGENTS.md"
cf_shape 2
log_shape 2
nav_shape 1 "$d/navigation.md" NAV
nav_shape 3 "$d/navegacao.md" OLD
run "$d"
check_pack "$d"
if [ -z "$why" ] && [ "${#d}" -gt 600 ]; then
  ok "P2 long root with spaces and accents fits, footer ends with the root"
else
  fail "P2 long root" "${why:-root of ${#d} bytes}"
fi
rm -rf "$work/raiz longa"

# A small Chief of Staff for P3 to P5.
small() {
  d="$1"
  mkdir -p "$d/memory"
  echo "manual" > "$d/AGENTS.md"
  echo "CF_SMALL" > "$d/CRITICAL_FACTS.md"
  echo "NAV_SMALL" > "$d/navigation.md"
  printf '## [08:00] HEAD_SMALL\n' > "$d/memory/2031-05-17.md"
}

# P3 CLAUDE_PROJECT_DIR precedence.
small "$work/p3 cos"
mkdir -p "$work/p3 other"
echo "CF_OTHER" > "$work/p3 other/CRITICAL_FACTS.md"
run_env_set=1
run_env="$work/p3 other"
run "$work/p3 cos"
silent_rc=$rc
silent_size=$size
silent_diff=$shdiff
r=0
for v in "" "$work/p3 cos/CRITICAL_FACTS.md" "$work/p3 missing"; do
  run_env="$v"
  run "$work/p3 cos"
  check_pack "$work/p3 cos"
  if [ -n "$why" ] || ! LC_ALL=C grep -qxF CF_SMALL "$work/out"; then r=1; p3why="CLAUDE_PROJECT_DIR '$v': ${why:-no CF_SMALL}"; break; fi
done
run_env_set=0
if [ -z "$silent_diff" ] && [ "$silent_rc" -eq 0 ] && [ "$silent_size" -eq 0 ] && [ "$r" -eq 0 ]; then
  ok "P3 CLAUDE_PROJECT_DIR wins when it is a folder; empty, a file or missing fall back to the cwd"
else
  fail "P3 CLAUDE_PROJECT_DIR precedence" "silent run: exit $silent_rc, $silent_size bytes $silent_diff; ${p3why:-}"
fi

# P4 the handoff reads the project root from a subfolder.
small "$work/p4 cos"
mkdir -p "$work/p4 cos/sub pasta" "$work/p4 cos/.claude/data/sensor-efeito/audithost"
echo '{}' > "$work/p4 cos/.claude/memoria-config.json"
echo '{}' > "$work/p4 cos/.claude/data/sensor-efeito/audithost/2031-05.jsonl"
run_env_set=1
run_env="$work/p4 cos"
run "$work/p4 cos/sub pasta"
handoff=$(cat "$work/out")
handoff_rc=$rc
handoff_diff=$shdiff
run "$work/p4 cos/sub pasta" codex
check_pack "$work/p4 cos"
run_env_set=0
if [ -z "$handoff_diff" ] && [ "$handoff_rc" -eq 0 ] \
  && [ "$handoff" = "memoria-agente present, session-start injection handed to the engine" ] \
  && [ -z "$why" ] && LC_ALL=C grep -qxF CF_SMALL "$work/out"; then
  ok "P4 the handoff and the codex boot read the project root from a subfolder"
else
  fail "P4 handoff from a subfolder" "claude run: exit $handoff_rc '$handoff' $handoff_diff; codex run: ${why:-no CF_SMALL}"
fi

# P5 the old layout, and AGENTS.md winning over CLAUDE.md on line 4.
d="$work/p5 old"
mkdir -p "$d"
printf 'old manual\nsecond line\n' > "$d/CLAUDE.md"
echo "CF_OLD" > "$d/CRITICAL_FACTS.md"
run "$d"
check_pack "$d"
# The verdict of the first check lives in its own variable: run sets $r, so
# a second run must never wash out a failure of the first.
p5old=""
if [ -n "$why" ]; then p5old="old layout: $why"
elif LC_ALL=C grep -q -- '^--- navigation.md ---$' "$work/out"; then p5old="old layout: a navigation section"
elif ! LC_ALL=C grep -qxF CF_OLD "$work/out"; then p5old="old layout: no CF_OLD"
fi
echo "the new manual, longer" > "$d/AGENTS.md"
echo "NAV_P5" > "$d/navigation.md"
run "$d"
check_pack "$d"
p5new=""
if [ -n "$why" ]; then p5new="with AGENTS.md: $why"
elif ! LC_ALL=C grep -qxF NAV_P5 "$work/out"; then p5new="with AGENTS.md: no NAV_P5"
fi
if [ -z "$p5old" ] && [ -z "$p5new" ]; then
  ok "P5 old CLAUDE.md layout boots and line 4 names the manual it has"
else
  fail "P5 old layout" "$p5old${p5new:+ ${p5new}}"
fi

# P6 internal failure from the hook's tools: a tool that fails silently or
# prints garbage gives exit 0 and either a pack or the one failure line.
p6_bad=""
small "$work/p6 cos"
for tool in awk wc tr; do
  for mode in fail garbage; do
    fb="$work/p6 bin $tool $mode"
    mkdir -p "$fb"
    cp "$fakes/date" "$fakes/uname" "$fb/"
    if [ "$mode" = fail ]; then printf '#!/bin/sh\nexit 3\n' > "$fb/$tool"
    else printf '#!/bin/sh\ncat > /dev/null 2>&1\necho "zz9 x"\n' > "$fb/$tool"; fi
    chmod +x "$fb/$tool"
    for shl in $SHELLS; do
      (cd "$work/p6 cos" && unset CLAUDE_PROJECT_DIR && PATH="$fb:$PATH" "$shl" "$HOOK" > "$work/out" 2>/dev/null)
      r=$?
      l1=$(sed -n 1p "$work/out")
      nl=$(LC_ALL=C awk 'END { print NR + 0 }' "$work/out")
      good=0
      # A pack counts only whole: line 1 the header, line 4 stating the
      # measured size, a footer, valid UTF-8. A header alone is no pack.
      if [ "$l1" = "$HEADER" ]; then
        p6size=$(LC_ALL=C wc -c < "$work/out" | tr -d ' ')
        case "$(sed -n 4p "$work/out")" in
          "Sizes: "*", this pack $p6size bytes (limit 8000).") good=1 ;;
        esac
        LC_ALL=C grep -qxF -- "--- not in this pack ---" "$work/out" \
          || LC_ALL=C grep -Eq '^Nothing is left out of this pack; the files are in .+\.$' "$work/out" \
          || good=0
      fi
      printf '%s\n' "$l1" | LC_ALL=C grep -Eq "$FAILLINE_RE" && [ "$nl" -eq 1 ] && good=1
      iconv -f UTF-8 -t UTF-8 < "$work/out" > "$work/conv" 2>/dev/null || good=0
      if [ "$r" -ne 0 ] || [ "$good" -ne 1 ]; then
        p6_bad="$p6_bad [$tool $mode $(basename "$shl"): exit $r, $nl lines]"
      fi
    done
  done
done
if [ -z "$p6_bad" ]; then
  ok "P6 a failing tool gives exit 0 and a pack or the one failure line"
else
  fail "P6 failing tools" "$p6_bad"
fi

# P7 the sizes of the real folder: CRITICAL_FACTS.md of 3608 bytes,
# navigation.md of 5543 and a day's log of 28122 and of 71680 bytes (one
# "## [HH:MM]" heading every six lines), in ASCII and with accents.
p7=""
for logbytes in 28122 71680; do
  for acc in no yes; do
    d="$work/p7 real $logbytes $acc"
    mkdir -p "$d/memory"
    echo "manual" > "$d/AGENTS.md"
    lines "$d/CRITICAL_FACTS.md" 88 40 CF lf yes "$acc"
    lines "$d/navigation.md" 241 22 NAV lf yes "$acc"
    LC_ALL=C awk -v t="$logbytes" -v a="$acc" 'BEGIN {
      n = 0; i = 0; h = 0
      while (n < t) {
        i++
        if (i % 6 == 1) { h++; s = sprintf("## [%02d:%02d] LOG_%03d %s", (h / 60) % 24, h % 60, h, a == "yes" ? "decisão de reunião" : "decision taken") }
        else { s = sprintf("BODY_%05d ", i); while (length(s) < 59) s = s "y" }
        if (n + length(s) + 1 > t) s = substr(s, 1, t - n - 1)
        print s; n += length(s) + 1
      }
    }' > "$d/memory/2031-05-17.md"
    sizes=$(LC_ALL=C wc -c < "$d/CRITICAL_FACTS.md" | tr -d ' ')/$(LC_ALL=C wc -c < "$d/navigation.md" | tr -d ' ')/$(LC_ALL=C wc -c < "$d/memory/2031-05-17.md" | tr -d ' ')
    run "$d"
    check_pack "$d"
    if [ "$acc" = no ] && [ "$sizes" != "3608/5543/$logbytes" ]; then why="fixture sizes $sizes"; fi
    if [ -n "$why" ]; then p7="$p7 [$logbytes $acc: $why]"
    else p7_info="${p7_info:-} $logbytes/$acc: $size bytes, $(chars "$work/out") chars;"
    fi
    rm -rf "$d"
  done
done
if [ -z "$p7" ]; then
  ok "P7 the real folder sizes fit:$p7_info"
else
  fail "P7 real folder sizes" "$p7"
fi

rm -rf "$work"
[ "$failures" -eq 0 ] || exit 1
exit 0
