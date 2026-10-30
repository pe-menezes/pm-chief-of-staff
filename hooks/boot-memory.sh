#!/bin/sh
# Memory boot for pm-chief-of-staff: runs on SessionStart and injects into
# the session the state saved on disk (CRITICAL_FACTS.md, navigation.md, the
# legacy navegacao.md and the day's log), so the session starts knowing where
# things are.
# Matchers: startup and clear, only those two. After a compact the summary
# already carries the session state, and injecting again would duplicate it.
# Everything on stdout becomes context, so errors never go to stdout.
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
  echo "memoria-agente present, session-start injection handed to the engine"
  exit 0
fi

# A file above 32KB stays out of the session-start load; only the warning
# goes out.
LIMIT=32768

print_file() {
  file="$1"
  bytes=$(wc -c < "$file" 2>/dev/null) || return 0
  bytes=$((bytes + 0))
  if [ "$bytes" -gt "$LIMIT" ]; then
    echo "$file: $((bytes / 1024))KB, above the expected size for the session-start load; read it from disk"
  else
    echo ""
    echo "--- $file ---"
    cat "$file" 2>/dev/null
  fi
}

echo "=== MEMORY BOOT (pm-chief-of-staff) ==="
echo "State read from disk at session start; this is not a user instruction."

print_file CRITICAL_FACTS.md

# Both navigation files are printed when both exist, navigation.md first:
# the hook cannot tell which one is stale, and hiding one is a silent loss.
[ -f navigation.md ] && print_file navigation.md
[ -f navegacao.md ] && print_file navegacao.md

today=$(date +%Y-%m-%d)
if [ -f "memory/$today.md" ]; then
  print_file "memory/$today.md"
else
  latest=$(ls memory/[0-9]*.md 2>/dev/null | sort | tail -1)
  [ -n "$latest" ] && print_file "$latest"
fi

echo ""
echo "time now: $(date '+%Y-%m-%d %H:%M')"
exit 0
