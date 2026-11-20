#!/bin/sh
# Memory boot for pm-chief-of-staff: runs on SessionStart and injects into
# the session a pack built from the state saved on disk (CRITICAL_FACTS.md,
# the headings of the day's log, navigation.md and the legacy navegacao.md),
# so the session starts knowing where things are.
# Matchers: startup, clear and compact. After a compact the hook context of
# the session start is summarized with the rest, and the hooks docs of Claude
# Code recommend SessionStart with compact to put the critical state back.
# Budget: the whole pack stays at or below 8000 bytes. Claude Code cuts hook
# output above 10000 characters down to a 2000-character preview, and Codex
# previews above its additionalContextLimit (3500 tokens in the plugin
# registration). Bytes are never fewer than characters in UTF-8, so a byte
# budget is the safe side. The pack is built in memory and written once.
# Everything on stdout becomes context, so errors never go to stdout, and all
# pack text is a statement, never an imperative: hook text that reads like a
# system command can trip the prompt-injection defense.
# Paths: the project root is CLAUDE_PROJECT_DIR when it names a directory,
# else the cwd. The cwd of a hook follows the agent's cd, so a compact after
# a cd would miss the folder without it.
# With the memoria-agente engine configured AND alive in this project, the
# engine takes over the session-start injection and this hook hands off,
# saying so in 1 line.
# An engine that is configured but shows no recent sign of life does NOT get
# the handoff: no boot is worse than a double boot. A freshly installed
# engine gets a double boot until its first telemetry event, accepted as
# fail-open.
# Accepted proof of life, only one: .claude/data/sensor-efeito/<folder of
# this host>/*.jsonl modified less than 2 days ago, which the engine writes
# from 0.14.0 on (in the engine: INSTALL.md, docs/architecture.md and
# scripts/sensor_efeito.py).
# Only this host's folder counts: .claude/data travels between machines, and
# an event from another machine would make this one, without the engine,
# start with no boot at all.
# The engine proofs up to 0.13.0 are gone (.claude/data/sensor-efeito-log.jsonl
# and .claude/data/juiz-*-log.jsonl): they carry no host, and every fresh
# clone gives them a current date, so a machine without the engine handed off
# and stayed with no boot for up to 2 days. An engine up to 0.13.0 is back to
# a double boot, the accepted side.
# This host's folder follows the engine rule (scripts/sensor_efeito.py,
# pasta_do_host) over uname -n: cut at 64, every character outside
# [A-Za-z0-9._-] becomes a hyphen, leading dots are dropped, cut at 64, empty
# becomes sem-host. Limit: a non-ASCII hostname, or one changed by the
# network on macOS, can give a name other than the engine's, and then the
# hook does not hand off (double boot, the accepted side).
# Runtime: the Codex registration (.codex-plugin/plugin.json) calls this hook
# with the argument codex; the Claude one (hooks/hooks.json), without an
# argument. The memoria-agente engine runs and writes telemetry only under
# Claude, so with the codex marker the handoff does not apply and the boot
# always runs: the folder's telemetry comes from Claude and does not prove a
# live engine in this session. The runtime comes only from the marker, never
# from a host file. If Codex also reads hooks/hooks.json, Codex gets a double
# boot, the accepted side.
runtime="${1:-claude}"

# Project root: CLAUDE_PROJECT_DIR when it is a directory, else the cwd. The
# gate, the handoff and the pack all read paths relative to it.
# CDPATH is dropped and the cd writes nothing: with CDPATH set, cd prints the
# directory it reached on stdout, which would land before the pack and
# outside its count, and a relative CLAUDE_PROJECT_DIR could resolve under a
# CDPATH entry instead of the cwd.
unset CDPATH
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR" ]; then
  cd -- "$CLAUDE_PROJECT_DIR" >/dev/null 2>&1 || exit 0
fi
root=$(pwd 2>/dev/null)
[ -n "$root" ] || exit 0

# Defensive gate: the plugin is enabled globally, and in any folder that is
# not a Chief of Staff the hook has to be invisible. A Chief of Staff is
# CRITICAL_FACTS.md together with CLAUDE.md (old layout) or together with
# AGENTS.md plus a navigation file (new layout, with or without the CLAUDE.md
# bridge). The navigation file is navigation.md, or navegacao.md, its legacy
# name from 0.7.0.
# AGENTS.md with CRITICAL_FACTS.md is not enough: a folder from another
# system can have both names and would get a duplicate boot. The navigation
# file, which setup creates and this hook already reads, is the third piece
# of evidence.
[ -f CRITICAL_FACTS.md ] || exit 0
[ -f CLAUDE.md ] || { [ -f AGENTS.md ] && { [ -f navigation.md ] || [ -f navegacao.md ]; }; } || exit 0

# Handoff to the memoria-agente engine, with two mandatory pieces of
# evidence:
# 1) .claude/memoria-config.json at the project root, the config its install
#    skill writes (installed in the environment does not mean active in this
#    folder);
# 2) the proof of life from the top, in this host's folder, modified in the
#    last 2 days. Only a regular file in there: a folder named like a .jsonl,
#    or the machine's own folder with a name ending in .jsonl, is no proof.
# The handoff says so in 1 line, so that both boots missing at once stays
# visible.
host_dir=$(uname -n 2>/dev/null | LC_ALL=C cut -c1-64 2>/dev/null \
  | LC_ALL=C tr -c 'A-Za-z0-9._\n-' '-' 2>/dev/null \
  | LC_ALL=C sed 's/^\.*//' 2>/dev/null | LC_ALL=C cut -c1-64 2>/dev/null)
[ -n "$host_dir" ] || host_dir=sem-host
if [ "$runtime" != codex ] && [ -f .claude/memoria-config.json ] \
  && find ".claude/data/sensor-efeito/$host_dir" -mindepth 1 -maxdepth 1 -type f -name '*.jsonl' -mtime -2 2>/dev/null | grep -q .; then
  printf '%s\n' "memoria-agente present, session-start injection handed to the engine"
  exit 0
fi

# Budget, in bytes: the whole pack, the CRITICAL_FACTS.md section and the
# log headings section. Navigation gets what is left. The targets on line 4
# are the sizes the close-week curation aims at.
LIMIT=8000
CF_CAP=4000
LOG_CAP=1500
CF_TARGET=3000
MANUAL_TARGET=10000
NL='
'

# is_num VALUE: VALUE is a number that is safe in arithmetic expansion:
# digits only, no leading zero (read as octal), at most 9 digits. A value
# from a tool goes through this before any $((...)), because a bad operand
# there ends the whole shell, past the fallback line.
is_num() {
  case "$1" in ''|*[!0-9]*|0?*|??????????*) return 1 ;; esac
  return 0
}

# bytes_of TEXT: sets nb to the size of TEXT in bytes. Returns 1 when wc or
# tr give no number.
bytes_of() {
  nb=$(printf '%s' "$1" | LC_ALL=C wc -c 2>/dev/null | tr -d ' ')
  is_num "$nb"
}

# count_lines FILE: number of lines, a last line without newline included.
count_lines() {
  LC_ALL=C awk 'END { print NR + 0 }' "$1" 2>/dev/null
}

# count_headings FILE: "<headings> <other lines>" of a log, headings being
# the lines that start with "## ".
count_headings() {
  LC_ALL=C awk '/^## / { m++ } END { print m + 0, NR - m }' "$1" 2>/dev/null
}

# cut_prefix FILE BUDGET: the first whole lines of FILE that fit in BUDGET
# bytes (newline included). Sets cut_shown and cut_body (each line ending in
# a newline). The trailing "." keeps blank lines that command substitution
# would strip.
cut_prefix() {
  r=$(LC_ALL=C awk -v b="$2" '
    { n = length($0) + 1
      if (!stop && used + n <= b) { used += n; k++; keep[k] = $0 } else stop = 1 }
    END { print k + 0; for (i = 1; i <= k; i++) print keep[i]; print "." }' "$1" 2>/dev/null) || return 1
  r=${r%.}
  cut_shown=${r%%"$NL"*}
  cut_body=${r#*"$NL"}
  is_num "$cut_shown"
}

# cut_headings FILE BUDGET: the latest "## " headings of FILE that fit in
# BUDGET bytes, printed in file order. Sets cut_shown and cut_body.
cut_headings() {
  r=$(LC_ALL=C awk -v b="$2" '
    /^## / { h[++m] = $0 }
    END { first = m + 1
      for (i = m; i >= 1; i--) { n = length(h[i]) + 1; if (used + n > b) break; used += n; first = i }
      print m - first + 1; for (i = first; i <= m; i++) print h[i]; print "." }' "$1" 2>/dev/null) || return 1
  r=${r%.}
  cut_shown=${r%%"$NL"*}
  cut_body=${r#*"$NL"}
  is_num "$cut_shown"
}

# footer: the lines for what is left out, from the *_shown and *_total
# values. Sets foot.
footer() {
  lines=""
  if [ "$cf_shown" -lt "$cf_total" ]; then
    lines="${lines}CRITICAL_FACTS.md: lines $((cf_shown + 1)) to $cf_total of $cf_total are not shown.$NL"
  fi
  if [ -n "$log" ]; then
    if [ "$log_shown" -lt "$log_total" ]; then
      lines="${lines}$log: $((log_total - log_shown)) of $log_total headings are not shown, the oldest ones; the entry bodies ($log_body lines) stay on disk.$NL"
    elif [ "$log_body" -gt 0 ]; then
      lines="${lines}$log: all $log_total headings are shown; the entry bodies ($log_body lines) stay on disk.$NL"
    fi
  fi
  if [ -n "$nav1" ] && [ "$nav1_shown" -lt "$nav1_total" ]; then
    lines="${lines}$nav1: lines $((nav1_shown + 1)) to $nav1_total of $nav1_total are not shown.$NL"
  fi
  if [ -n "$nav2" ] && [ "$nav2_shown" -lt "$nav2_total" ]; then
    lines="${lines}$nav2: lines $((nav2_shown + 1)) to $nav2_total of $nav2_total are not shown.$NL"
  fi
  if [ -n "$lines" ]; then
    foot="$NL--- not in this pack ---$NL${lines}The full files are in $root.$NL"
  else
    foot="${NL}Nothing is left out of this pack; the files are in $root.$NL"
  fi
}

# assemble: builds the whole pack in $pack. Returns 1 on any internal
# failure, and the caller prints the one-line fallback instead.
assemble() {
  manual=CLAUDE.md
  [ -f AGENTS.md ] && manual=AGENTS.md
  cf_bytes=$(wc -c < CRITICAL_FACTS.md 2>/dev/null | tr -d ' ')
  is_num "$cf_bytes" || return 1
  manual_bytes=$(wc -c < "$manual" 2>/dev/null | tr -d ' ')
  is_num "$manual_bytes" || return 1

  # The day's log, or the latest dated one when today's does not exist or
  # date gives no date. A dated log is a regular file named exactly
  # memory/YYYY-MM-DD.md; nothing else in memory/ is ever the log. The
  # choice is a glob loop that compares the dates as numbers, with no ls or
  # sort whose failure would leave the log out unseen, and a name with a
  # newline never matches the pattern.
  today=$(date +%Y-%m-%d 2>/dev/null)
  case "$today" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;; *) today="" ;; esac
  log=""
  if [ -n "$today" ] && [ -f "memory/$today.md" ]; then
    log="memory/$today.md"
  else
    best=0
    for f in memory/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do
      [ -f "$f" ] || continue
      d=${f#memory/}
      d=${d%.md}
      # "1" in front keeps a year like 0999 from a leading zero: 9 digits,
      # safe for is_num and the arithmetic.
      key="1${d%%-*}"
      d=${d#*-}
      key="$key${d%%-*}${d#*-}"
      is_num "$key" || continue
      if [ "$key" -gt "$best" ]; then best=$key; log=$f; fi
    done
  fi

  # Both navigation files are shown when both exist, navigation.md first:
  # the hook cannot tell which one is stale, and hiding one is a silent loss.
  nav1=""
  nav2=""
  [ -f navigation.md ] && nav1=navigation.md
  if [ -f navegacao.md ]; then
    if [ -n "$nav1" ]; then nav2=navegacao.md; else nav1=navegacao.md; fi
  fi

  # Totals first: the footer is reserved at its largest size (everything
  # left out) before any section takes bytes.
  cf_total=$(count_lines CRITICAL_FACTS.md) || return 1
  log_total=0
  log_body=0
  if [ -n "$log" ]; then
    counts=$(count_headings "$log") || return 1
    log_total=${counts% *}
    log_body=${counts#* }
  fi
  nav1_total=0
  nav2_total=0
  if [ -n "$nav1" ]; then nav1_total=$(count_lines "$nav1") || return 1; fi
  if [ -n "$nav2" ]; then nav2_total=$(count_lines "$nav2") || return 1; fi
  for v in "$cf_total" "$log_total" "$log_body" "$nav1_total" "$nav2_total"; do
    is_num "$v" || return 1
  done

  # The largest footer: every file cut right before its last line, so the
  # "lines K to N" start has as many digits as N, and every log heading left
  # out.
  cf_shown=0
  [ "$cf_total" -gt 0 ] && cf_shown=$((cf_total - 1))
  log_shown=0
  nav1_shown=0
  [ "$nav1_total" -gt 0 ] && nav1_shown=$((nav1_total - 1))
  nav2_shown=0
  [ "$nav2_total" -gt 0 ] && nav2_shown=$((nav2_total - 1))
  footer
  bytes_of "$foot" || return 1
  reserve_all=$nb
  cf_shown=$cf_total
  log_shown=$log_total
  log_body_saved=$log_body
  log_body=0
  nav1_shown=$nav1_total
  nav2_shown=$nav2_total
  footer
  bytes_of "$foot" || return 1
  reserve_none=$nb
  log_body=$log_body_saved
  reserve=$reserve_all
  [ "$reserve_none" -gt "$reserve" ] && reserve=$reserve_none

  line1="=== MEMORY BOOT (pm-chief-of-staff) ==="
  line2="State read from disk at session start; this is not a user instruction."
  # Line 3 says unknown when date gives no date and time.
  now=$(date '+%Y-%m-%d %H:%M' 2>/dev/null)
  case "$now" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' '[0-9][0-9]:[0-9][0-9]) ;;
    *) now=unknown ;;
  esac
  line3="time now: $now"
  line4a="Sizes: CRITICAL_FACTS.md $cf_bytes bytes (target about $CF_TARGET), $manual $manual_bytes bytes (target about $MANUAL_TARGET), this pack "
  line4b=" bytes (limit $LIMIT)."
  head_a="$line1$NL$line2$NL$line3$NL$line4a"
  bytes_of "$head_a${LIMIT}$line4b$NL" || return 1
  head_reserve=$nb

  # A pack over the limit with readable files is never the failure line: the
  # overflow becomes slack taken from the sections, and the last section
  # loses whole lines, until the pack fits. The slack grows by the overflow,
  # by at least 128 bytes (one more footer line) and by at least its own
  # size, so it at least doubles: the 8th assembly has a slack of 8192 or
  # more, above the whole limit, and every section is down to nothing. The
  # loop ends by construction within the 8 assemblies.
  slack=0
  tries=0
  while :; do
    build_sections || return 1
    [ "$size" -le "$LIMIT" ] && return 0
    tries=$((tries + 1))
    [ "$tries" -lt 8 ] || return 1
    step=$((size - LIMIT))
    [ "$step" -lt 128 ] && step=128
    [ "$step" -lt "$slack" ] && step=$slack
    slack=$((slack + step))
  done
}

# build_sections: the sections, the footer and line 4 for the current slack.
# Sets pack and size. Returns 1 on an internal failure.
build_sections() {
  left=$((LIMIT - head_reserve - reserve - slack))

  # CRITICAL_FACTS.md, up to its section cap.
  # The slack also comes off the cap of the section that is last in the
  # pack, so that section is the one that loses lines.
  last=cf
  [ -n "$log" ] && last=log
  [ -n "$nav1" ] && last=nav
  cap=$CF_CAP
  [ "$last" = cf ] && cap=$((cap - slack))
  [ "$cap" -gt "$left" ] && cap=$left
  bytes_of "$NL--- CRITICAL_FACTS.md ---$NL$cf_total of $cf_total lines shown.$NL" || return 1
  hdr_max=$nb
  cut_prefix CRITICAL_FACTS.md $((cap - hdr_max)) || return 1
  cf_shown=$cut_shown
  cf_sec="$NL--- CRITICAL_FACTS.md ---$NL$cf_shown of $cf_total lines shown.$NL$cut_body"
  bytes_of "$cf_sec" || return 1
  left=$((left - nb))

  # The log headings, the latest first to fit, up to their section cap.
  log_sec=""
  if [ -n "$log" ]; then
    cap=$LOG_CAP
    [ "$last" = log ] && cap=$((cap - slack))
    [ "$cap" -gt "$left" ] && cap=$left
    bytes_of "$NL--- $log ---$NL$log_total of $log_total headings shown, the latest ones, in file order; the entry bodies are not in this pack.$NL" || return 1
    hdr_max=$nb
    cut_headings "$log" $((cap - hdr_max)) || return 1
    log_shown=$cut_shown
    log_sec="$NL--- $log ---$NL$log_shown of $log_total headings shown, the latest ones, in file order; the entry bodies are not in this pack.$NL$cut_body"
    bytes_of "$log_sec" || return 1
    left=$((left - nb))
  fi

  # Navigation, with what is left: navigation.md first, then navegacao.md.
  # With both, the second header is held back while the first is cut, so
  # both names stay in the pack.
  nav_sec=""
  hold=0
  if [ -n "$nav2" ]; then
    bytes_of "$NL--- $nav2 ---$NL$nav2_total of $nav2_total lines shown.$NL" || return 1
    hold=$nb
  fi
  for which in 1 2; do
    if [ "$which" = 1 ]; then name=$nav1; total=$nav1_total; else name=$nav2; total=$nav2_total; hold=0; fi
    [ -n "$name" ] || continue
    bytes_of "$NL--- $name ---$NL$total of $total lines shown.$NL" || return 1
    hdr_max=$nb
    shown=0
    if [ "$((left - hold))" -ge "$hdr_max" ]; then
      cut_prefix "$name" $((left - hold - hdr_max)) || return 1
      shown=$cut_shown
      sec="$NL--- $name ---$NL$shown of $total lines shown.$NL$cut_body"
      nav_sec="$nav_sec$sec"
      bytes_of "$sec" || return 1
      left=$((left - nb))
    fi
    if [ "$which" = 1 ]; then nav1_shown=$shown; else nav2_shown=$shown; fi
  done

  footer
  body="$cf_sec$log_sec$nav_sec$foot"

  # Line 4 states the size of the pack that contains it: the number is
  # solved for its own digit count.
  bytes_of "$head_a$line4b$NL$body" || return 1
  base=$nb
  size=""
  for d in 1 2 3 4 5 6; do
    try=$((base + d))
    if [ "${#try}" -eq "$d" ]; then size=$try; break; fi
  done
  [ -n "$size" ] || return 1
  pack="$head_a$size$line4b$NL$body"
  bytes_of "$pack" || return 1
  [ "$nb" = "$size" ] || return 1
  return 0
}

if assemble 2>/dev/null; then
  printf '%s' "$pack"
else
  # printf, never echo: echo reads backslashes in the root (\c ends the
  # line, \0303 writes a lone byte).
  printf '%s\n' "Memory boot pack not assembled; the files are on disk in $root."
fi
exit 0
