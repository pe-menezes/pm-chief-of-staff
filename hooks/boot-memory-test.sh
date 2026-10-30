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
# with spaces). Time line: T1 (english spec, format only, never the clock).
# Run by hand: sh hooks/boot-memory-test.sh
# Each case builds a folder with mktemp -d, runs the hook inside it in a
# subshell (the hook reads paths relative to the cwd, as in a real session)
# and removes the folder.
# A boot is detected by the fixed boot header and by the CRITICAL_FACTS.md
# fixture in the load, never by the whole text.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

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

# T1: the last line of the boot is the ISO time line. Only the format is
# checked, never the clock.
if run_in "T1 time line" AGENTS.md CRITICAL_FACTS.md navigation.md; then
  last=$(printf '%s\n' "$out" | tail -n 1)
  if boots && printf '%s\n' "$last" \
    | grep -Eqx 'time now: [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}'; then
    echo "ok    T1 time line"
  else
    echo "FAIL  T1 time line: expected 'time now: YYYY-MM-DD HH:MM' (exit $rc, last line: $last)"
    failures=$((failures + 1))
  fi
fi

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

[ "$failures" -eq 0 ] || exit 1
exit 0
