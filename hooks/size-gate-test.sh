#!/bin/sh
# Test suite for size-gate.sh, the end-of-turn size gate on the manual
# (AGENTS.md plus CLAUDE.md, cap 13000 bytes) and on CRITICAL_FACTS.md (cap
# 3900 bytes).
# Cases, by letter of the stop-size-gate spec (part 1):
#   A  a folder that is not a Chief of Staff: nothing written anywhere;
#   B  old layout (CLAUDE.md alone) and new layout (AGENTS.md with and
#      without the bridge), the manual being the sum of both files;
#   C  the manual crossing the cap blocks; D  growing while already above
#      blocks; E  above and not growing passes; F  shrinking passes;
#   G  growing and ending at or below the cap passes;
#   H  the same for CRITICAL_FACTS.md at 3900;
#   I  stop_hook_active true passes and records the end, which the next
#      turn compares against;
#   J  each no-record case: no record, record of another root, empty or
#      unset CLAUDE_PLUGIN_DATA, folder without write, no session_id, bad
#      session_id;
#   K  live memoria-agente engine: CRITICAL_FACTS.md is not measured under
#      Claude, and is measured with the codex marker;
#   L  the block shape in both runtimes, read by a JSON parser, message of
#      at most 2000 bytes with the file name and the numbers;
#   M  hostile session_id: nothing written anywhere;
#   N  payload with spaces around the colon, on several lines, and with
#      decoy keys inside string values;
#   O  failing wc, tr, mkdir and mv: prompt silent, stop {};
#   P  records older than 30 days leave, other names and links stay;
#   Q  the four new registrations run through sh -c with the plugin root in
#      a folder with spaces;
#   R  differential oracle: boot-memory.sh and size-gate.sh agree on which
#      folders are a Chief of Staff, over generated folder shapes;
#   S  project root: CLAUDE_PROJECT_DIR, a relative one under CDPATH=.;
#   T  fix round 1: session_id filter under UTF-8 locales, a failing
#      measure or write drops the old record, mkdir losing a race, a record
#      with any field out of form, session_id only as a string and
#      stop_hook_active only as true or false.
# Run by hand: sh hooks/size-gate-test.sh < /dev/null
# Each case builds its own folder with mktemp -d (work folder and plugin
# data folder inside it) and removes it. Fake tools never read stdin.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

# Nothing inherited from the caller decides where the hook looks or writes.
unset CLAUDE_PROJECT_DIR
unset CLAUDE_PLUGIN_DATA
# An exported CDPATH makes cd print the folder inside $(...).
unset CDPATH
DIR=$(cd "$(dirname "$0")" && pwd) || exit 1
ROOT=$(cd "$DIR/.." && pwd) || exit 1
HOOK="$DIR/size-gate.sh"
BOOT="$DIR/boot-memory.sh"
SID=11111111-2222-3333-4444-555555555555
MANUAL_LABEL="the manual (AGENTS.md plus CLAUDE.md)"
CF_LABEL="CRITICAL_FACTS.md"
failures=0

ok() { echo "ok    $1"; }
fail() {
  echo "FAIL  $1"
  failures=$((failures + 1))
}

if [ -x "$HOOK" ]; then
  ok "execution bit of the hook"
else
  fail "execution bit of the hook missing: $HOOK"
fi

# json_command FILE KEY: the string at the dotted KEY of the JSON in FILE,
# read by plutil or node (node parses the file content, so a file without
# the .json extension is still read as JSON).
# Empty, with exit 1, when the key is missing, is not a string or the file
# is not JSON.
json_command() {
  if command -v plutil >/dev/null 2>&1; then
    plutil -extract "$2" raw -o - "$1" 2>/dev/null
  elif command -v node >/dev/null 2>&1; then
    node -e 'let v=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));for(const k of process.argv[2].split("."))v=v==null?v:v[k];if(typeof v!=="string")process.exit(1);process.stdout.write(v)' "$1" "$2" 2>/dev/null
  else
    return 1
  fi
}
if ! command -v plutil >/dev/null 2>&1 && ! command -v node >/dev/null 2>&1; then
  fail "neither plutil nor node to read JSON: the L checks cannot run"
fi

# fill FILE BYTES: FILE with exactly BYTES bytes, in 100-byte lines.
fill() {
  LC_ALL=C awk -v n="$2" 'BEGIN { while (n >= 100) { printf "%099d\n", 0; n -= 100 } while (n-- > 0) printf "x" }' > "$1"
}

# bytes FILE: size in bytes.
bytes() {
  wc -c < "$1" | tr -d ' '
}

# new_case: T (case folder), W (work folder, the person's folder) and D
# (plugin data folder, created empty as Claude Code does). Returns 1 when
# mktemp fails. Resets the runner knobs.
new_case() {
  T=$(mktemp -d 2>/dev/null)
  if [ -z "$T" ] || [ ! -d "$T" ]; then
    fail "$1: mktemp -d returned no folder"
    return 1
  fi
  T=$(cd "$T" && pwd -P)
  W="$T/work"
  D="$T/data"
  mkdir -p "$W" "$D"
  data_val="$D"
  path_front=""
  project_dir=""
  loc_var=""
  loc_val=""
  return 0
}

end_case() {
  chmod -R u+w "$T" 2>/dev/null
  rm -rf "$T"
}

# layout KIND: the Chief of Staff files in W.
# The manual starts at 2000 bytes and CRITICAL_FACTS.md at 1000 in all three.
# old: CLAUDE.md and CRITICAL_FACTS.md. new: AGENTS.md, the one-line
# CLAUDE.md bridge, CRITICAL_FACTS.md and navigation.md. agents: AGENTS.md,
# CRITICAL_FACTS.md and navigation.md, without the bridge.
layout() {
  case "$1" in
    old) fill "$W/CLAUDE.md" 2000 ;;
    new)
      # 1989 + the 11-byte bridge: the manual starts at 2000, as in old.
      fill "$W/AGENTS.md" 1989
      echo "@AGENTS.md" > "$W/CLAUDE.md"
      echo "navigation" > "$W/navigation.md"
      ;;
    agents)
      fill "$W/AGENTS.md" 2000
      echo "navigation" > "$W/navigation.md"
      ;;
  esac
  fill "$W/CRITICAL_FACTS.md" 1000
}

# set_size WHICH BYTES: manual (sum of AGENTS.md and CLAUDE.md) or cf.
# With AGENTS.md present, AGENTS.md takes what the bridge leaves.
set_size() {
  if [ "$1" = cf ]; then
    fill "$W/CRITICAL_FACTS.md" "$2"
  elif [ -f "$W/AGENTS.md" ]; then
    bridge=0
    [ -f "$W/CLAUDE.md" ] && bridge=$(bytes "$W/CLAUDE.md")
    fill "$W/AGENTS.md" $(($2 - bridge))
  else
    fill "$W/CLAUDE.md" "$2"
  fi
}

prompt_payload() {
  printf '{"session_id":"%s","hook_event_name":"UserPromptSubmit","prompt":"hello"}' "${1:-$SID}"
}
stop_payload() {
  printf '{"session_id":"%s","hook_event_name":"Stop","stop_hook_active":%s,"last_assistant_message":"done"}' "$SID" "$1"
}

# run_hook EVENT PAYLOAD [MARKER]: runs the hook in W (or in run_dir when
# set) with the payload on stdin; sets rc and out, raw stdout in $T/out.
# Knobs: data_val ("-unset-" unsets CLAUDE_PLUGIN_DATA), path_front,
# project_dir, loc_var and loc_val (LANG or LC_ALL set to loc_val, every
# other locale variable unset). The hook runs by its #! line, /bin/sh.
run_hook() {
  printf '%s' "$2" > "$T/in"
  (
    cd "${run_dir:-$W}" || exit 97
    if [ -n "$loc_var" ]; then
      unset LC_ALL LC_CTYPE LC_COLLATE LANG
      case "$loc_var" in
        LANG) LANG="$loc_val"; export LANG ;;
        LC_ALL) LC_ALL="$loc_val"; export LC_ALL ;;
      esac
    fi
    if [ "$data_val" = "-unset-" ]; then
      unset CLAUDE_PLUGIN_DATA
    else
      CLAUDE_PLUGIN_DATA="$data_val"
      export CLAUDE_PLUGIN_DATA
    fi
    if [ -n "$project_dir" ]; then
      CLAUDE_PROJECT_DIR="$project_dir"
      export CLAUDE_PROJECT_DIR
    fi
    [ -n "$path_front" ] && PATH="$path_front:$PATH"
    if [ -n "$3" ]; then exec "$HOOK" "$1" "$3"; else exec "$HOOK" "$1"; fi
  ) < "$T/in" > "$T/out" 2>/dev/null
  rc=$?
  out=$(cat "$T/out")
}

# prompt_silent NAME: the last run was a prompt with exit 0 and no stdout.
prompt_silent() {
  if [ "$rc" -eq 0 ] && [ ! -s "$T/out" ]; then
    return 0
  fi
  fail "$1: prompt must exit 0 with empty stdout (exit $rc, stdout: $out)"
  return 1
}

# is_pass: the last stop printed exactly {} with exit 0.
is_pass() {
  [ "$rc" -eq 0 ] && [ "$out" = "{}" ]
}

# block_ok RUNTIME LABEL FROM TO CAP TARGET: the last stop is a block in the
# shape of RUNTIME (claude or codex), read by a JSON parser, with a message
# of at most 2000 bytes naming the file and the numbers. Sets why on
# failure.
block_ok() {
  why=""
  if [ "$rc" -ne 0 ]; then why="exit $rc"; return 1; fi
  if [ "$1" = codex ]; then
    dec=$(json_command "$T/out" decision)
    msg=$(json_command "$T/out" reason)
    if [ "$dec" != block ]; then why="decision is not block: $out"; return 1; fi
    if json_command "$T/out" hookSpecificOutput.hookEventName >/dev/null; then
      why="Codex block carries hookSpecificOutput"; return 1
    fi
  else
    ev=$(json_command "$T/out" hookSpecificOutput.hookEventName)
    msg=$(json_command "$T/out" hookSpecificOutput.additionalContext)
    if [ "$ev" != Stop ]; then why="hookEventName is not Stop: $out"; return 1; fi
    if json_command "$T/out" decision >/dev/null; then
      why="Claude block carries a decision"; return 1
    fi
  fi
  if [ -z "$msg" ]; then why="empty message: $out"; return 1; fi
  printf '%s' "$msg" > "$T/msg"
  n=$(bytes "$T/msg")
  if [ "$n" -gt 2000 ]; then why="message of $n bytes"; return 1; fi
  if ! grep -qF "$2 grew from $3 to $4 bytes" "$T/msg"; then
    why="message lacks '$2 grew from $3 to $4 bytes': $msg"; return 1
  fi
  if ! grep -qF "$5" "$T/msg" || ! grep -qF "$6" "$T/msg"; then
    why="message lacks the cap $5 or the target $6"; return 1
  fi
  return 0
}

label_of() {
  if [ "$1" = cf ]; then echo "$CF_LABEL"; else echo "$MANUAL_LABEL"; fi
}
cap_of() {
  if [ "$1" = cf ]; then echo 3900; else echo 13000; fi
}
target_of() {
  if [ "$1" = cf ]; then echo 3000; else echo 10000; fi
}

# gate_case NAME LAYOUT WHICH START END EXPECTED [MARKER]
# A prompt with WHICH at START bytes, then WHICH at END bytes and a stop.
# EXPECTED: pass or block. The runtime of the block shape is codex with the
# codex marker, else claude.
gate_case() {
  name="$1"
  new_case "$name" || return
  layout "$2"
  set_size "$3" "$4"
  run_hook prompt "$(prompt_payload)" "$7"
  if prompt_silent "$name"; then
    set_size "$3" "$5"
    run_hook stop "$(stop_payload false)" "$7"
    if [ "$6" = pass ]; then
      if is_pass; then ok "$name"; else fail "$name: expected {} (exit $rc, stdout: $out)"; fi
    else
      runtime=claude
      [ "$7" = codex ] && runtime=codex
      if block_ok "$runtime" "$(label_of "$3")" "$4" "$5" "$(cap_of "$3")" "$(target_of "$3")"; then
        ok "$name"
      else
        fail "$name: expected a $runtime block ($why)"
      fi
    fi
  fi
  end_case
}

# listing PATH...: every path under the given folders, sorted.
listing() {
  find "$@" -print 2>/dev/null | LC_ALL=C sort
}

# snapshot: every path under T except the runner's own files (in, out, msg)
# and the manual files the case resizes.
snapshot() {
  listing "$T" | grep -v -e "^$T/in\$" -e "^$T/out\$" -e "^$T/msg\$" \
    -e '/AGENTS\.md$' -e '/CLAUDE\.md$' -e '/CRITICAL_FACTS\.md$'
}

# ---------------------------------------------------------------- A
# A folder that is not a Chief of Staff: prompt silent, stop {}, and
# nothing created in the data folder or in the work folder.
a_case() {
  name="$1"
  shift
  new_case "$name" || return
  for f in "$@"; do fill "$W/$f" 20000; done
  before=$(listing "$W" "$D")
  run_hook prompt "$(prompt_payload)"
  if prompt_silent "$name"; then
    for f in "$@"; do fill "$W/$f" 25000; done
    run_hook stop "$(stop_payload false)"
    after=$(listing "$W" "$D")
    if is_pass && [ "$before" = "$after" ] && [ -z "$(find "$D" -mindepth 1 -print)" ]; then
      ok "$name"
    else
      fail "$name: expected {} and nothing written (exit $rc, stdout: $out)"
    fi
  fi
  end_case
}
a_case "A1 empty folder"
a_case "A2 AGENTS.md and CRITICAL_FACTS.md without navigation" AGENTS.md CRITICAL_FACTS.md
a_case "A3 CLAUDE.md without CRITICAL_FACTS.md" CLAUDE.md
a_case "A4 CRITICAL_FACTS.md and navigation.md without manual" CRITICAL_FACTS.md navigation.md

# ---------------------------------------------------------------- B
gate_case "B1 old layout, CLAUDE.md alone grows past the cap" old manual 12000 14000 block
gate_case "B2 new layout with bridge grows past the cap" new manual 12000 14000 block
gate_case "B3 new layout without bridge grows past the cap" agents manual 12000 14000 block
# B4: AGENTS.md alone ends at 12994 bytes, under the cap; with the 11-byte
# bridge the manual is 13005, above it.
gate_case "B4 the manual is AGENTS.md plus CLAUDE.md" new manual 12900 13005 block

# ---------------------------------------------------------------- C to G
gate_case "C1 manual crosses the cap" old manual 12900 13100 block
gate_case "C2 manual crosses the cap by one byte" new manual 12000 13001 block
gate_case "D1 manual grows while already above the cap" new manual 13500 13600 block
gate_case "D2 manual grows by one byte above the cap" old manual 14000 14001 block
gate_case "E1 manual above the cap does not grow" new manual 13500 13500 pass
gate_case "F1 manual above the cap shrinks" new manual 14000 13800 pass
gate_case "F2 manual shrinks to under the cap" old manual 14000 12000 pass
gate_case "G1 manual grows and ends below the cap" new manual 11000 12000 pass
gate_case "G2 manual grows and ends at the cap" old manual 12000 13000 pass

# ---------------------------------------------------------------- H
gate_case "H1 CRITICAL_FACTS.md crosses the cap" new cf 3800 3950 block
gate_case "H2 CRITICAL_FACTS.md grows while already above the cap" old cf 4000 4100 block
gate_case "H3 CRITICAL_FACTS.md above the cap does not grow" new cf 4000 4000 pass
gate_case "H4 CRITICAL_FACTS.md above the cap shrinks" new cf 4200 4000 pass
gate_case "H5 CRITICAL_FACTS.md grows and ends below the cap" old cf 3000 3500 pass
gate_case "H6 CRITICAL_FACTS.md grows and ends at the cap" new cf 3000 3900 pass
gate_case "H7 CRITICAL_FACTS.md crosses the cap by one byte" new cf 3000 3901 block

# H8: CRITICAL_FACTS.md removed during the turn. Without it the folder is
# no longer a Chief of Staff, so the stop is silent. (A missing manual file
# counting as 0 is covered by B1, without AGENTS.md, and B3, without
# CLAUDE.md.)
new_case "H8" && {
  layout old
  run_hook prompt "$(prompt_payload)"
  if prompt_silent "H8 CRITICAL_FACTS.md removed during the turn"; then
    rm -f "$W/CRITICAL_FACTS.md"
    run_hook stop "$(stop_payload false)"
    if is_pass; then ok "H8 CRITICAL_FACTS.md removed during the turn"
    else fail "H8 CRITICAL_FACTS.md removed during the turn: expected {} (exit $rc, stdout: $out)"; fi
  fi
  end_case
}

# H9: both files grow above their caps in the same turn: one block naming
# both, still within 2000 bytes.
new_case "H9" && {
  layout new
  run_hook prompt "$(prompt_payload)"
  if prompt_silent "H9 both files grow"; then
    set_size manual 14000
    set_size cf 4500
    run_hook stop "$(stop_payload false)"
    if block_ok claude "$MANUAL_LABEL" 2000 14000 13000 10000 \
      && grep -qF "$CF_LABEL grew from 1000 to 4500 bytes" "$T/msg" \
      && grep -qF 3900 "$T/msg" && grep -qF 3000 "$T/msg"; then
      ok "H9 both files grow"
    else
      fail "H9 both files grow: expected one block naming both (${why:-CRITICAL_FACTS.md part missing}): $out"
    fi
  fi
  end_case
}

# ---------------------------------------------------------------- I
# stop_hook_active true passes and records the end; a stop with no prompt
# in between compares against that record.
new_case "I1" && {
  layout new
  run_hook prompt "$(prompt_payload)"
  prompt_silent "I1 prompt" && {
    set_size manual 14000
    run_hook stop "$(stop_payload true)"
    if is_pass; then ok "I1 stop_hook_active true passes"
    else fail "I1 stop_hook_active true passes: expected {} (exit $rc, stdout: $out)"; fi
    run_hook stop "$(stop_payload false)"
    if is_pass; then ok "I2 next turn without growth compares with the recorded end"
    else fail "I2 next turn without growth: expected {} (exit $rc, stdout: $out)"; fi
    set_size manual 14100
    run_hook stop "$(stop_payload false)"
    if block_ok claude "$MANUAL_LABEL" 14000 14100 13000 10000; then
      ok "I3 next turn with growth blocks from the recorded end"
    else
      fail "I3 next turn with growth: expected a block from 14000 to 14100 ($why)"
    fi
    # The block recorded its own end too: the continuation stop and a stop
    # after it without growth pass.
    run_hook stop "$(stop_payload false)"
    if is_pass; then ok "I4 the block records the end of its turn"
    else fail "I4 the block records the end of its turn: expected {} (exit $rc, stdout: $out)"; fi
  }
  end_case
}

# ---------------------------------------------------------------- J
# Each case with no usable record: the stop passes with {}.
j_pass() {
  if is_pass; then ok "$1"; else fail "$1: expected {} (exit $rc, stdout: $out)"; fi
}

new_case "J1" && {
  layout new
  set_size manual 14000
  run_hook stop "$(stop_payload false)"
  j_pass "J1 no record"
  # J1 recorded the end of that turn: the next one compares with it.
  set_size manual 14500
  run_hook stop "$(stop_payload false)"
  if block_ok claude "$MANUAL_LABEL" 14000 14500 13000 10000; then
    ok "J1b the stop without a record records its end"
  else
    fail "J1b the stop without a record records its end ($why)"
  fi
  end_case
}

# J2: the record was written from another root with the same session.
new_case "J2" && {
  layout new
  mkdir -p "$T/other"
  W_A="$W"
  W="$T/other"
  layout new
  run_hook prompt "$(prompt_payload)"
  prompt_silent "J2 prompt" && {
    W="$W_A"
    set_size manual 14000
    run_hook stop "$(stop_payload false)"
    j_pass "J2 record of another root"
  }
  end_case
}

for mode in empty unset relative missing; do
  new_case "J3" || continue
  layout new
  case "$mode" in
    empty) data_val="" ;;
    unset) data_val="-unset-" ;;
    relative) data_val="data" ;;
    missing) data_val="$T/no-such-data" ;;
  esac
  before=$(snapshot)
  run_hook prompt "$(prompt_payload)"
  if prompt_silent "J3 CLAUDE_PLUGIN_DATA $mode"; then
    set_size manual 14000
    run_hook stop "$(stop_payload false)"
    after=$(snapshot)
    if is_pass && [ "$before" = "$after" ]; then
      ok "J3 CLAUDE_PLUGIN_DATA $mode: {} and nothing written"
    else
      fail "J3 CLAUDE_PLUGIN_DATA $mode: expected {} and nothing written (exit $rc, stdout: $out)"
    fi
  fi
  end_case
done

# J4: the data folder, or the hook's own folder inside it, without write.
for where in data own; do
  new_case "J4" || continue
  layout new
  if [ "$where" = own ]; then mkdir "$D/size-gate"; chmod 555 "$D/size-gate"; else chmod 555 "$D"; fi
  run_hook prompt "$(prompt_payload)"
  if prompt_silent "J4 folder without write ($where)"; then
    set_size manual 14000
    run_hook stop "$(stop_payload false)"
    if is_pass && [ -z "$(find "$D" -type f -print)" ]; then
      ok "J4 folder without write ($where)"
    else
      fail "J4 folder without write ($where): expected {} and no file (exit $rc, stdout: $out)"
    fi
  fi
  end_case
done

# J5: session_id missing from the stop payload, after a good prompt.
new_case "J5" && {
  layout new
  run_hook prompt "$(prompt_payload)"
  prompt_silent "J5 prompt" && {
    set_size manual 14000
    run_hook stop '{"hook_event_name":"Stop","stop_hook_active":false}'
    j_pass "J5 session_id missing"
    run_hook stop '{"session_id":null,"hook_event_name":"Stop","stop_hook_active":false}'
    # J5b also checks that no record was born: only the prompt's own.
    if [ "$(listing "$D/size-gate")" = "$(printf '%s\n%s' "$D/size-gate" "$D/size-gate/turn-$SID.state")" ]; then
      j_pass "J5b session_id null"
    else
      fail "J5b session_id null: a record was born: $(listing "$D/size-gate" | tr '\n' ' ')"
    fi
  }
  end_case
}

# J6: a bad session_id in the stop payload, after a good prompt.
new_case "J6" && {
  layout new
  run_hook prompt "$(prompt_payload)"
  prompt_silent "J6 prompt" && {
    set_size manual 14000
    run_hook stop '{"session_id":"11111111-2222-3333-4444-555555555555/x","hook_event_name":"Stop","stop_hook_active":false}'
    j_pass "J6 session_id with a slash"
    run_hook stop '{"session_id":".11111111","hook_event_name":"Stop","stop_hook_active":false}'
    j_pass "J6b session_id starting with a dot"
  }
  end_case
}

# ---------------------------------------------------------------- K
# The live memoria-agente engine, by the same proof as boot-memory.sh:
# config at the root and fresh telemetry in this host's folder. The host
# folder follows boot-memory-test.sh: identity when uname -n is already in
# the engine's character set, else derived.
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
  echo "info  hostname outside the identity, K runs with a derived name: $HOST_DIR"
fi

# k_case NAME WHICH EXPECTED [MARKER]: engine alive, WHICH grows from under
# to above its cap.
k_case() {
  name="$1"
  new_case "$name" || return
  layout new
  mkdir -p "$W/.claude/data/sensor-efeito/$HOST_DIR"
  echo "{}" > "$W/.claude/memoria-config.json"
  echo "{}" > "$W/.claude/data/sensor-efeito/$HOST_DIR/2026-10.jsonl"
  if [ "$2" = cf ]; then set_size cf 3800; else set_size manual 12900; fi
  run_hook prompt "$(prompt_payload)" "$4"
  if prompt_silent "$name"; then
    if [ "$2" = cf ]; then set_size cf 4100; else set_size manual 13200; fi
    run_hook stop "$(stop_payload false)" "$4"
    if [ "$3" = pass ]; then
      if is_pass; then ok "$name"; else fail "$name: expected {} (exit $rc, stdout: $out)"; fi
    else
      runtime=claude
      [ "$4" = codex ] && runtime=codex
      if [ "$2" = cf ]; then
        block_ok "$runtime" "$CF_LABEL" 3800 4100 3900 3000
      else
        block_ok "$runtime" "$MANUAL_LABEL" 12900 13200 13000 10000
      fi
      if [ -z "$why" ]; then ok "$name"; else fail "$name: expected a $runtime block ($why)"; fi
    fi
  fi
  end_case
}
k_case "K1 live engine: CRITICAL_FACTS.md growing above the cap passes" cf pass
k_case "K2 live engine: the manual growing above the cap blocks" manual block
k_case "K3 live engine with codex: CRITICAL_FACTS.md blocks" cf block codex
k_case "K4 live engine with codex: the manual blocks" manual block codex

# K5: a stale engine (telemetry older than 2 days) is not live.
new_case "K5" && {
  layout new
  mkdir -p "$W/.claude/data/sensor-efeito/$HOST_DIR"
  echo "{}" > "$W/.claude/memoria-config.json"
  echo "{}" > "$W/.claude/data/sensor-efeito/$HOST_DIR/2000-01.jsonl"
  TZ=UTC0 touch -t 200001010000 "$W/.claude/data/sensor-efeito/$HOST_DIR/2000-01.jsonl"
  set_size cf 3800
  run_hook prompt "$(prompt_payload)"
  prompt_silent "K5 prompt" && {
    set_size cf 4100
    run_hook stop "$(stop_payload false)"
    if block_ok claude "$CF_LABEL" 3800 4100 3900 3000; then ok "K5 stale engine: CRITICAL_FACTS.md blocks"
    else fail "K5 stale engine: expected a block ($why)"; fi
  }
  end_case
}

# ---------------------------------------------------------------- L
# Block shape in both runtimes (the claude shape is checked by every block
# above; these add the codex shape for each file).
gate_case "L1 codex block for the manual" new manual 12000 14000 block codex
gate_case "L2 codex block for CRITICAL_FACTS.md" old cf 3000 4000 block codex
gate_case "L3 codex pass when nothing grows" new manual 14000 14000 pass codex

# L4: the message is English, plain text with no path of the folder and no
# quote or backslash that would need escaping.
new_case "L4" && {
  layout new
  run_hook prompt "$(prompt_payload)"
  prompt_silent "L4 prompt" && {
    set_size manual 14000
    set_size cf 4500
    run_hook stop "$(stop_payload false)"
    if block_ok claude "$MANUAL_LABEL" 2000 14000 13000 10000 \
      && ! grep -qF "$T" "$T/out" && ! grep -q '\\' "$T/out" \
      && [ "$(LC_ALL=C tr -d '\040-\176' < "$T/msg" | wc -c | tr -d ' ')" -eq 0 ]; then
      ok "L4 message is printable ASCII without the folder path"
    else
      fail "L4 message is printable ASCII without the folder path (${why:-path, backslash or non-ASCII byte found})"
    fi
  }
  end_case
}

# ---------------------------------------------------------------- M
# Hostile session_id in both events: the prompt is silent, the stop is {},
# and nothing is written anywhere (data folder empty, case folder
# unchanged).
LONG200=$(LC_ALL=C awk 'BEGIN { for (i = 0; i < 200; i++) printf "a" }')
LONG128=$(LC_ALL=C awk 'BEGIN { for (i = 0; i < 128; i++) printf "b" }')
LONG129=$(LC_ALL=C awk 'BEGIN { for (i = 0; i < 129; i++) printf "c" }')
m_case() {
  name="$1"
  payload_p="$2"
  payload_s="$3"
  new_case "$name" || return
  layout new
  mkdir "$T/escape"
  payload_p=$(printf '%s' "$payload_p" | sed "s|@T@|$T|g")
  payload_s=$(printf '%s' "$payload_s" | sed "s|@T@|$T|g")
  before=$(snapshot)
  run_hook prompt "$payload_p"
  if prompt_silent "$name"; then
    set_size manual 14000
    run_hook stop "$payload_s"
    after=$(snapshot)
    if is_pass && [ "$before" = "$after" ]; then
      ok "$name"
    else
      fail "$name: expected {} and nothing written (exit $rc, stdout: $out)"
    fi
  fi
  end_case
}
m_sid() {
  m_case "$1" \
    "{\"session_id\":\"$2\",\"hook_event_name\":\"UserPromptSubmit\",\"prompt\":\"x\"}" \
    "{\"session_id\":\"$2\",\"hook_event_name\":\"Stop\",\"stop_hook_active\":false}"
}
m_sid "M1 session_id ../x" "../x"
m_sid "M2 session_id /tmp/x" "/tmp/x"
m_sid "M3 session_id pointing into the case folder" "@T@/escape/x"
m_sid "M4 empty session_id" ""
m_case "M5 missing session_id" \
  '{"hook_event_name":"UserPromptSubmit","prompt":"x"}' \
  '{"hook_event_name":"Stop","stop_hook_active":false}'
m_sid "M6 session_id of 200 characters" "$LONG200"
m_sid "M7 session_id of 129 characters" "$LONG129"
m_sid "M8 session_id starting with a dot" ".hidden"
m_sid "M9 session_id with a space" "a b"
m_sid "M10 session_id with an escaped quote" 'a\"b'

# M11: 128 characters is the longest accepted session_id.
new_case "M11" && {
  layout new
  run_hook prompt "$(prompt_payload "$LONG128")"
  prompt_silent "M11 prompt" && {
    set_size manual 14000
    printf '{"session_id":"%s","stop_hook_active":false}' "$LONG128" > "$T/stop.json"
    run_hook stop "$(cat "$T/stop.json")"
    if block_ok claude "$MANUAL_LABEL" 2000 14000 13000 10000; then
      ok "M11 session_id of 128 characters is accepted"
    else
      fail "M11 session_id of 128 characters: expected a block ($why)"
    fi
  }
  end_case
}

# ---------------------------------------------------------------- N
# Spaces around the colon, a payload on several lines, and decoy keys
# inside string values, which JSON escapes.
n_case() {
  name="$1"
  new_case "$name" || return
  layout new
  run_hook prompt "$2"
  if prompt_silent "$name"; then
    set_size manual 14000
    run_hook stop "$3"
    if [ "$4" = pass ]; then
      if is_pass; then ok "$name"; else fail "$name: expected {} (exit $rc, stdout: $out)"; fi
    else
      if block_ok claude "$MANUAL_LABEL" 2000 14000 13000 10000; then ok "$name"
      else fail "$name: expected a block ($why)"; fi
    fi
  fi
  end_case
}
n_case "N1 spaces around the colon, active false blocks" \
  "{\"session_id\" : \"$SID\", \"prompt\" : \"x\"}" \
  "{\"session_id\" :  \"$SID\", \"stop_hook_active\" : false}" block
n_case "N2 spaces around the colon, active true passes" \
  "{\"session_id\" : \"$SID\", \"prompt\" : \"x\"}" \
  "{\"session_id\" : \"$SID\", \"stop_hook_active\"	:	true}" pass
n_case "N3 payload on several lines" \
  "{
  \"session_id\": \"$SID\",
  \"prompt\": \"x\"
}" \
  "{
  \"session_id\":
    \"$SID\",
  \"stop_hook_active\":
    false
}" block
n_case "N4 decoy keys inside string values" \
  "{\"prompt\":\"say \\\"session_id\\\":\\\"evil\\\"\",\"session_id\":\"$SID\"}" \
  "{\"last_assistant_message\":\"\\\"stop_hook_active\\\":true \\\"session_id\\\":\\\"evil\\\"\",\"session_id\":\"$SID\",\"stop_hook_active\":false}" block

# ---------------------------------------------------------------- O
# Failing wc, tr, mkdir and mv: each fake exits 1 without reading stdin.
FAKES=$(mktemp -d 2>/dev/null)
for tool in wc tr mkdir mv; do
  mkdir -p "$FAKES/$tool"
  printf '#!/bin/sh\necho "fake %s: error" >&2\nexit 1\n' "$tool" > "$FAKES/$tool/$tool"
  chmod +x "$FAKES/$tool/$tool"
done
for tool in wc tr mkdir mv; do
  # Fresh: both events under the fake.
  new_case "O1" || continue
  layout new
  path_front="$FAKES/$tool"
  run_hook prompt "$(prompt_payload)"
  if prompt_silent "O1 failing $tool, fresh"; then
    set_size manual 14000
    run_hook stop "$(stop_payload false)"
    if is_pass; then ok "O1 failing $tool, fresh: prompt silent and stop {}"
    else fail "O1 failing $tool, fresh: expected {} (exit $rc, stdout: $out)"; fi
  fi
  end_case
done
for tool in wc tr mv; do
  # A good record from a real prompt, then the stop under the fake.
  new_case "O2" || continue
  layout new
  run_hook prompt "$(prompt_payload)"
  if prompt_silent "O2 failing $tool at the stop"; then
    set_size manual 14000
    path_front="$FAKES/$tool"
    run_hook stop "$(stop_payload false)"
    if is_pass; then ok "O2 failing $tool at the stop: {}"
    else fail "O2 failing $tool at the stop: expected {} (exit $rc, stdout: $out)"; fi
  fi
  end_case
done
rm -rf "$FAKES"

# ---------------------------------------------------------------- P
# Records older than 30 days leave; a fresh record, a file with another
# name, a link with the record name (and its target outside) and a folder
# with the record name stay.
new_case "P1" && {
  layout new
  sd="$D/size-gate"
  mkdir "$sd"
  echo old > "$sd/turn-old.state"
  echo fresh > "$sd/turn-fresh.state"
  echo notes > "$sd/notes.txt"
  echo target > "$T/target.state"
  ln -s "$T/target.state" "$sd/turn-link.state"
  mkdir "$sd/turn-dir.state"
  TZ=UTC0 touch -t 200001010000 "$sd/turn-old.state" "$sd/notes.txt" "$T/target.state" "$sd/turn-dir.state"
  run_hook prompt "$(prompt_payload)"
  if prompt_silent "P1 old records leave"; then
    why=""
    [ -e "$sd/turn-old.state" ] && why="$why old record stayed;"
    [ -f "$sd/turn-fresh.state" ] || why="$why fresh record left;"
    [ -f "$sd/notes.txt" ] || why="$why other name left;"
    [ -L "$sd/turn-link.state" ] || why="$why link left;"
    [ -f "$T/target.state" ] || why="$why link target left;"
    [ -d "$sd/turn-dir.state" ] || why="$why folder left;"
    [ -f "$sd/turn-$SID.state" ] || why="$why own record missing;"
    if [ -z "$why" ]; then ok "P1 old records leave, other names, links and folders stay"
    else fail "P1 old records leave:$why"; fi
  fi
  end_case
}

# ---------------------------------------------------------------- Q
# The four new registrations, read from the manifests and run through sh -c
# with the plugin root in a folder with spaces, as both agents run a hook
# command. UserPromptSubmit and Stop take no matcher.
q_case() {
  name="$1"
  file="$2"
  base="$3"
  runtime="$4"
  cmd_p=$(json_command "$ROOT/$file" "$base.UserPromptSubmit.0.hooks.0.command")
  cmd_s=$(json_command "$ROOT/$file" "$base.Stop.0.hooks.0.command")
  if [ -z "$cmd_p" ] || [ -z "$cmd_s" ]; then
    fail "$name: UserPromptSubmit or Stop command missing in $file"
    return
  fi
  if json_command "$ROOT/$file" "$base.UserPromptSubmit.0.matcher" >/dev/null \
    || json_command "$ROOT/$file" "$base.Stop.0.matcher" >/dev/null; then
    fail "$name: UserPromptSubmit or Stop carries a matcher in $file"
    return
  fi
  new_case "$name" || return
  package="$T/pacote do plugin"
  W="$T/user work folder"
  mkdir -p "$package/hooks" "$W"
  cp -p "$HOOK" "$package/hooks/size-gate.sh"
  layout new
  prompt_payload > "$T/in"
  (cd "$W" && env CLAUDE_PLUGIN_ROOT="$package" CLAUDE_PLUGIN_DATA="$D" sh -c "$cmd_p") < "$T/in" > "$T/out" 2>/dev/null
  rc=$?
  out=$(cat "$T/out")
  if prompt_silent "$name"; then
    set_size manual 14000
    stop_payload false > "$T/in"
    (cd "$W" && env CLAUDE_PLUGIN_ROOT="$package" CLAUDE_PLUGIN_DATA="$D" sh -c "$cmd_s") < "$T/in" > "$T/out" 2>/dev/null
    rc=$?
    out=$(cat "$T/out")
    if block_ok "$runtime" "$MANUAL_LABEL" 2000 14000 13000 10000; then ok "$name"
    else fail "$name: expected a $runtime block ($why)"; fi
  fi
  end_case
}
q_case "Q1 Claude registrations with spaces" hooks/hooks.json hooks claude
q_case "Q2 Codex registrations with spaces" .codex-plugin/plugin.json hooks.hooks codex

# ---------------------------------------------------------------- R
# Differential oracle: for every shape of the five names that the gate of
# boot-memory.sh reads (CRITICAL_FACTS.md, CLAUDE.md, AGENTS.md,
# navigation.md, navegacao.md), each absent, a file or a folder, both hooks
# decide the same: boot-memory.sh is active when it prints anything, and
# size-gate.sh is active when its prompt writes anything in the data
# folder. Three root modes: the cwd, CLAUDE_PROJECT_DIR naming the shape
# from another cwd, and CLAUDE_PROJECT_DIR naming a missing folder.
NAMES="CRITICAL_FACTS.md CLAUDE.md AGENTS.md navigation.md navegacao.md"
r_disagree=0
r_active=0
r_total=0
r_first=""
new_case "R" && {
  shape="$T/shape"
  elsewhere="$T/elsewhere"
  mkdir -p "$elsewhere"
  code=0
  while [ "$code" -lt 243 ]; do
    rm -rf "$shape"
    mkdir "$shape"
    c=$code
    desc=""
    for nm in $NAMES; do
      st=$((c % 3))
      c=$((c / 3))
      case "$st" in
        1) echo "content of $nm" > "$shape/$nm"; desc="$desc $nm=file" ;;
        2) mkdir "$shape/$nm"; desc="$desc $nm=dir" ;;
      esac
    done
    for mode in cwd project missing; do
      case "$mode" in
        cwd) run_dir="$shape"; pd="" ;;
        project) run_dir="$elsewhere"; pd="$shape" ;;
        missing) run_dir="$shape"; pd="$T/missing" ;;
      esac
      if [ -n "$pd" ]; then
        b_out=$(cd "$run_dir" && CLAUDE_PROJECT_DIR="$pd" "$BOOT" 2>/dev/null < /dev/null)
      else
        b_out=$(cd "$run_dir" && "$BOOT" 2>/dev/null < /dev/null)
      fi
      b=mute
      [ -n "$b_out" ] && b=active
      rm -rf "$D"
      mkdir "$D"
      project_dir="$pd"
      run_hook prompt "$(prompt_payload)"
      g=mute
      [ -n "$(find "$D" -mindepth 1 -print)" ] && g=active
      if [ "$rc" -ne 0 ] || [ -s "$T/out" ]; then g="noisy"; fi
      r_total=$((r_total + 1))
      [ "$b" = active ] && r_active=$((r_active + 1))
      if [ "$b" != "$g" ]; then
        r_disagree=$((r_disagree + 1))
        [ -n "$r_first" ] || r_first="$mode:$desc (boot $b, gate $g)"
      fi
    done
    code=$((code + 1))
  done
  run_dir=""
  project_dir=""
  end_case
}
if [ "$r_total" -eq 729 ] && [ "$r_disagree" -eq 0 ] && [ "$r_active" -gt 0 ] && [ "$r_active" -lt "$r_total" ]; then
  ok "R1 differential oracle: $r_total shapes, $r_active active, both hooks agree"
else
  fail "R1 differential oracle: $r_disagree of $r_total disagree ($r_active active); first: $r_first"
fi

# ---------------------------------------------------------------- S
# S1: CLAUDE_PROJECT_DIR names the root while the cwd is a subfolder; the
# stop from the same root blocks.
new_case "S1" && {
  layout new
  mkdir "$W/sub"
  run_dir="$W/sub"
  project_dir="$W"
  run_hook prompt "$(prompt_payload)"
  prompt_silent "S1 prompt" && {
    set_size manual 14000
    run_hook stop "$(stop_payload false)"
    if block_ok claude "$MANUAL_LABEL" 2000 14000 13000 10000; then ok "S1 CLAUDE_PROJECT_DIR is the root"
    else fail "S1 CLAUDE_PROJECT_DIR is the root: expected a block ($why)"; fi
    # The same stop from the subfolder without CLAUDE_PROJECT_DIR is not a
    # Chief of Staff folder.
    project_dir=""
    run_hook stop "$(stop_payload false)"
    j_pass "S2 the cwd subfolder without CLAUDE_PROJECT_DIR is not a Chief of Staff"
  }
  run_dir=""
  project_dir=""
  end_case
}

# S3: CDPATH=. exported and a relative CLAUDE_PROJECT_DIR: cd prints
# nothing on stdout, and the relative name resolves under the cwd.
new_case "S3" && {
  mkdir -p "$T/base/the cos" "$T/base/cdp/the cos"
  W="$T/base/the cos"
  layout new
  printf '%s' "$(prompt_payload)" > "$T/in"
  (cd "$T/base" && CDPATH=. CLAUDE_PROJECT_DIR="the cos" CLAUDE_PLUGIN_DATA="$D" "$HOOK" prompt) < "$T/in" > "$T/out" 2>/dev/null
  rc=$?
  out=$(cat "$T/out")
  prompt_silent "S3 prompt under CDPATH" && {
    set_size manual 14000
    printf '%s' "$(stop_payload false)" > "$T/in"
    (cd "$T/base" && CDPATH="$T/base/cdp" CLAUDE_PROJECT_DIR="the cos" CLAUDE_PLUGIN_DATA="$D" "$HOOK" stop) < "$T/in" > "$T/out" 2>/dev/null
    rc=$?
    out=$(cat "$T/out")
    if block_ok claude "$MANUAL_LABEL" 2000 14000 13000 10000; then ok "S3 CDPATH and a relative CLAUDE_PROJECT_DIR"
    else fail "S3 CDPATH and a relative CLAUDE_PROJECT_DIR: expected a block ($why)"; fi
  }
  end_case
}

# S4: an unknown event and no event print nothing and exit 0.
new_case "S4" && {
  layout new
  run_hook other "$(prompt_payload)"
  prompt_silent "S4 unknown event" && ok "S4 unknown event is silent"
  run_hook "" "$(prompt_payload)"
  prompt_silent "S4b no event" && ok "S4b no event is silent"
  end_case
}

# ---------------------------------------------------------------- T
# T1: the session_id filter does not depend on the locale. The non-ASCII
# bytes of the audit probe X5 (e acute in UTF-8, a lone 0xff, a full-width
# A), in the middle of the id, under every installed UTF-8 locale, set by
# LANG alone and by LC_ALL, with the hook under /bin/sh: prompt silent,
# stop {}, nothing written. The allowed id still blocks in the same locale,
# so the case cannot pass by a hook that does nothing.
T1_LOCALES=""
for l in C.UTF-8 C.utf8 en_US.UTF-8 en_US.utf8 pt_BR.UTF-8 pt_BR.utf8; do
  if locale -a 2>/dev/null | grep -qx "$l"; then T1_LOCALES="$T1_LOCALES $l"; fi
done
[ -n "$T1_LOCALES" ] || fail "T1 no UTF-8 locale installed among C, en_US and pt_BR: the locale cases cannot run"
T1_BYTES=$(printf '\303\251 \377 \357\274\241')
for l in $T1_LOCALES; do
  for var in LANG LC_ALL; do
    name="T1 non-ASCII session_id under $var=$l"
    new_case "$name" || continue
    layout new
    loc_var="$var"
    loc_val="$l"
    t1_bad=""
    for c in $T1_BYTES; do
      hex=$(printf '%s' "$c" | od -An -tx1 | tr -d ' ')
      set_size manual 2000
      before=$(snapshot)
      run_hook prompt "$(prompt_payload "a${c}b")"
      [ "$rc" -eq 0 ] && [ ! -s "$T/out" ] || t1_bad="$t1_bad prompt $hex not silent;"
      set_size manual 14000
      run_hook stop "{\"session_id\":\"a${c}b\",\"hook_event_name\":\"Stop\",\"stop_hook_active\":false}"
      is_pass || t1_bad="$t1_bad stop $hex not {};"
      [ "$before" = "$(snapshot)" ] || t1_bad="$t1_bad $hex wrote $(find "$D" -mindepth 1 -print | tr '\n' ' ');"
    done
    set_size manual 2000
    run_hook prompt "$(prompt_payload)"
    set_size manual 14000
    run_hook stop "$(stop_payload false)"
    block_ok claude "$MANUAL_LABEL" 2000 14000 13000 10000 || t1_bad="$t1_bad the allowed id did not block ($why);"
    if [ -z "$t1_bad" ]; then ok "$name"; else fail "$name:$t1_bad"; fi
    end_case
  done
done

# Fakes for T2 to T4, none reading stdin: wc and mv failing with no output;
# wc printing a partial count and failing; mkdir that loses a race (the
# folder gets created, by the real mkdir, and the call fails).
TF=$(mktemp -d 2>/dev/null)
REAL_MKDIR=$(command -v mkdir)
mkdir -p "$TF/wc" "$TF/mv" "$TF/wc-partial" "$TF/mkdir-race"
printf '#!/bin/sh\necho "fake wc: error" >&2\nexit 1\n' > "$TF/wc/wc"
printf '#!/bin/sh\necho "fake mv: error" >&2\nexit 1\n' > "$TF/mv/mv"
printf '#!/bin/sh\necho "       1"\necho "fake wc: read error" >&2\nexit 1\n' > "$TF/wc-partial/wc"
printf '#!/bin/sh\n"%s" "$@"\necho "fake mkdir: File exists" >&2\nexit 1\n' "$REAL_MKDIR" > "$TF/mkdir-race/mkdir"
chmod +x "$TF/wc/wc" "$TF/mv/mv" "$TF/wc-partial/wc" "$TF/mkdir-race/mkdir"

# T2: an event that fails after it knows the record path (measuring or
# writing) drops the record of this session, so no later turn compares with
# an old start. For each failing tool and each event: a real prompt records
# the manual at 2000; the manual grows to 14000 (another session, or this
# turn); the event runs under the fake; then a stop with real tools and no
# change passes, and the record was gone after the failure.
for tool in wc mv wc-partial; do
  for ev in prompt stop; do
    name="T2 failing $tool at the $ev drops the old record"
    new_case "$name" || continue
    layout new
    run_hook prompt "$(prompt_payload)"
    if prompt_silent "$name"; then
      set_size manual 14000
      path_front="$TF/$tool"
      if [ "$ev" = prompt ]; then
        run_hook prompt "$(prompt_payload)"
        prompt_silent "$name" || { end_case; continue; }
      else
        run_hook stop "$(stop_payload false)"
        is_pass || { fail "$name: the failing stop must print {} (exit $rc, stdout: $out)"; end_case; continue; }
      fi
      path_front=""
      why=""
      [ -e "$D/size-gate/turn-$SID.state" ] && why=" the record stayed after the failure;"
      run_hook stop "$(stop_payload false)"
      is_pass || why="$why the next stop without change did not pass (stdout: $out);"
      if [ -z "$why" ]; then ok "$name"; else fail "$name:$why"; fi
    fi
    end_case
  done
done

# T3: the mkdir of the hook's folder loses a race with another session: the
# folder exists after the failed call, so the prompt goes on and records
# the start, and the stop that grows the manual past the cap blocks.
new_case "T3" && {
  layout new
  path_front="$TF/mkdir-race"
  run_hook prompt "$(prompt_payload)"
  if prompt_silent "T3 mkdir race"; then
    path_front=""
    set_size manual 14000
    run_hook stop "$(stop_payload false)"
    if block_ok claude "$MANUAL_LABEL" 2000 14000 13000 10000; then
      ok "T3 the prompt goes on when mkdir loses a race"
    else
      fail "T3 the prompt goes on when mkdir loses a race: expected a block ($why)"
    fi
  fi
  end_case
}
rm -rf "$TF"

# T4: the record holds whole or not at all. Each of the four fields of line
# 1 spoiled one at a time, the others valid (start 12000 and 1000), with the
# manual ending at 14000 and CRITICAL_FACTS.md at 4500: the stop passes.
# The same record unspoiled blocks for both, so the written form is one the
# hook reads.
new_case "T4" && {
  layout new
  mkdir "$D/size-gate"
  rec="$D/size-gate/turn-$SID.state"
  set_size manual 14000
  set_size cf 4500
  why=""
  printf 'size-gate 1 12000 1000\n%s\n' "$W" > "$rec"
  run_hook stop "$(stop_payload false)"
  block_ok claude "$MANUAL_LABEL" 12000 14000 13000 10000 \
    && grep -qF "$CF_LABEL grew from 1000 to 4500 bytes" "$T/msg" \
    || why=" the unspoiled record did not block for both ($why);"
  for pos in 1 2 3 4; do
    for bad in INVALID -5 012 1x '' 1234567890 -; do
      [ "$pos" = 4 ] && [ "$bad" = - ] && continue
      set -- size-gate 1 12000 1000
      case "$pos" in
        1) line="$bad $2 $3 $4" ;;
        2) line="$1 $bad $3 $4" ;;
        3) line="$1 $2 $bad $4" ;;
        4) line="$1 $2 $3 $bad" ;;
      esac
      printf '%s\n%s\n' "$line" "$W" > "$rec"
      run_hook stop "$(stop_payload false)"
      is_pass || why="$why field $pos as [$bad] did not pass;"
    done
  done
  if [ -z "$why" ]; then ok "T4 a record with any field out of form gives no start"
  else fail "T4 a record with any field out of form gives no start:$why"; fi
  end_case
}

# T5: session_id counts only as a JSON string. Each other JSON value in both
# events: prompt silent, stop {}, nothing written.
for v in null true false 123 '{}' '[]'; do
  m_case "T5 session_id as $v" \
    "{\"session_id\":$v,\"hook_event_name\":\"UserPromptSubmit\",\"prompt\":\"x\"}" \
    "{\"session_id\":$v,\"hook_event_name\":\"Stop\",\"stop_hook_active\":false}"
done

# T6: stop_hook_active counts only as true or false. Every other form
# (missing, truncated after the colon, truncated after the value, null, a
# number, a string, another word) does not block a turn that grew past the
# cap; false still blocks.
t6_case() {
  name="T6 stop_hook_active $1"
  new_case "$name" || return
  layout new
  run_hook prompt "$(prompt_payload)"
  if prompt_silent "$name"; then
    set_size manual 14000
    run_hook stop "$2"
    if [ "$3" = pass ]; then
      if is_pass; then ok "$name"; else fail "$name: expected {} (exit $rc, stdout: $out)"; fi
    else
      if block_ok claude "$MANUAL_LABEL" 2000 14000 13000 10000; then ok "$name"
      else fail "$name: expected a block ($why)"; fi
    fi
  fi
  end_case
}
t6_case "missing" "{\"session_id\":\"$SID\",\"hook_event_name\":\"Stop\"}" pass
t6_case "truncated after the colon" "{\"session_id\":\"$SID\",\"hook_event_name\":\"Stop\",\"stop_hook_active\":" pass
t6_case "truncated after false" "{\"session_id\":\"$SID\",\"hook_event_name\":\"Stop\",\"stop_hook_active\":false" pass
for v in null 0 1 '"false"' '"true"' fals falsey False tru; do
  t6_case "as $v" "{\"session_id\":\"$SID\",\"hook_event_name\":\"Stop\",\"stop_hook_active\":$v}" pass
done
t6_case "false, last key" "{\"session_id\":\"$SID\",\"stop_hook_active\":false}" block
t6_case "false, then another key" "{\"session_id\":\"$SID\",\"stop_hook_active\" : false , \"x\":1}" block

[ "$failures" -eq 0 ] || exit 1
exit 0
