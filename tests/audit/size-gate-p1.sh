#!/bin/sh
# Probes from the audit of the stop-size-gate front, part 1 (hooks/size-gate.sh,
# the end-of-turn size gate). Behavior only, pinned by content.
# Run by hand: sh tests/audit/size-gate-p1.sh < /dev/null
# Every case works in folders under one mktemp -d, removed at the end.
# Nothing inherited from the caller decides where the hook looks or writes:
# CDPATH, CLAUDE_PROJECT_DIR and CLAUDE_PLUGIN_DATA are dropped. Each hook
# run goes through every shell found among /bin/sh and /bin/dash. Fake tools
# never read stdin. No case compares against the real clock: old files carry
# a fixed date in 2000.
# Cases:
# X1 cleanup over generated entries in the hook's own folder (regular file,
#    link with an old mtime of its own, folder; names of the hook's pattern
#    and near misses), plus old records nested one level down, at the top of
#    the data folder and in another plugin subfolder: only regular files with
#    the hook's name pattern, directly in its folder, leave; link targets stay.
# X2 the hook's own folder is a link to a folder outside: nothing written or
#    deleted there, the stop passes with {}.
# X3 the record is a link to a forged record outside: the target is neither
#    read as the start nor written, and the record becomes a regular file.
# X4 CLAUDE_PLUGIN_DATA forms: relative names that exist under the cwd write
#    nothing in the person's folder; absolute names with a trailing slash or
#    dot work.
# X5 session_id charset: every printable ASCII character outside
#    [A-Za-z0-9._-], and non-ASCII bytes under C and every installed UTF-8
#    locale among C, en_US and pt_BR, in
#    the middle of the id: prompt silent, stop {}, nothing written; every
#    allowed character works.
# X6 noisy fakes for each external tool of the hook (stdout and stderr noise,
#    exit 1 and exit 0): the prompt prints nothing and exits 0, the stop
#    prints one JSON object without the noise and exits 0.
# X7 sizes around both caps (cap - 1, cap, cap + 1, cap + 2 as start and
#    end), a manual file appearing or leaving, both files at once, in both
#    runtimes: block exactly when a file grew and ended above its cap, and
#    the message names exactly the files that grew.
# X8 a record of a root that is a prefix, a child or a parent of the current
#    one, or with a corrupt first line: the stop passes, and the next turn
#    compares with the end it recorded.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

unset CDPATH
unset CLAUDE_PROJECT_DIR
unset CLAUDE_PLUGIN_DATA
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
HOOK="$ROOT/hooks/size-gate.sh"
SID=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee
MANUAL_LABEL="the manual (AGENTS.md plus CLAUDE.md)"
CF_LABEL="CRITICAL_FACTS.md"
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi
work=$(cd "$work" && pwd -P)

SHELLS=""
for s in /bin/sh /bin/dash; do [ -x "$s" ] && SHELLS="$SHELLS $s"; done

# json_object FILE: 0 when FILE holds one JSON object.
# json_str FILE KEY: the string at the dotted KEY, empty with exit 1 when
# missing or not a string.
if command -v node >/dev/null 2>&1; then
  json_object() {
    node -e 'const v=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));if(v===null||typeof v!=="object"||Array.isArray(v))process.exit(1)' "$1" < /dev/null 2>/dev/null
  }
  json_str() {
    node -e 'let v=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));for(const k of process.argv[2].split("."))v=v==null?v:v[k];if(typeof v!=="string")process.exit(1);process.stdout.write(v)' "$1" "$2" < /dev/null 2>/dev/null
  }
elif command -v plutil >/dev/null 2>&1; then
  json_object() {
    [ "$(head -c 1 "$1")" = "{" ] && plutil -convert xml1 -o /dev/null "$1" < /dev/null 2>/dev/null
  }
  json_str() {
    plutil -extract "$2" raw -o - "$1" < /dev/null 2>/dev/null
  }
else
  echo "FAIL  neither node nor plutil to read JSON"
  exit 1
fi

# fill FILE BYTES: FILE with exactly BYTES bytes.
fill() {
  LC_ALL=C awk -v n="$2" 'BEGIN { while (n >= 100) { printf "%099d\n", 0; n -= 100 } while (n-- > 0) printf "x" }' > "$1"
}

n_case=0
# new_case: C (case folder), W (the person's folder, new layout with the
# 11-byte bridge, manual 2000 and CRITICAL_FACTS.md 1000), D (plugin data
# folder, created empty) and SD (the hook's own folder).
new_case() {
  n_case=$((n_case + 1))
  C="$work/c$n_case"
  W="$C/work"
  D="$C/data"
  SD="$D/size-gate"
  mkdir -p "$W" "$D"
  printf '@AGENTS.md\n' > "$W/CLAUDE.md"
  fill "$W/AGENTS.md" 1989
  echo "navigation" > "$W/navigation.md"
  fill "$W/CRITICAL_FACTS.md" 1000
  data_val="$D"
  path_front=""
  lc=""
}
# set_manual BYTES: AGENTS.md takes what the bridge leaves.
set_manual() { fill "$W/AGENTS.md" $(($1 - 11)); }
set_cf() { fill "$W/CRITICAL_FACTS.md" "$1"; }

prompt_in() {
  printf '{"session_id":"%s","hook_event_name":"UserPromptSubmit","prompt":"x"}' "${1:-$SID}" > "$work/in"
}
stop_in() {
  printf '{"session_id":"%s","hook_event_name":"Stop","stop_hook_active":%s,"last_assistant_message":"done"}' "${2:-$SID}" "$1" > "$work/in"
}

# run SHELL EVENT [MARKER]: the hook in W with $work/in on stdin; rc and
# $work/out. Knobs: data_val (empty leaves CLAUDE_PLUGIN_DATA unset),
# path_front, lc (LC_ALL for the hook).
run() {
  (
    cd "$W" || exit 97
    if [ -n "$data_val" ]; then CLAUDE_PLUGIN_DATA="$data_val"; export CLAUDE_PLUGIN_DATA; fi
    if [ -n "$lc" ]; then LC_ALL="$lc"; export LC_ALL; fi
    [ -n "$path_front" ] && PATH="$path_front:$PATH"
    exec "$1" "$HOOK" "$2" ${3:+"$3"}
  ) < "$work/in" > "$work/out" 2>/dev/null
  rc=$?
}
silent() { [ "$rc" -eq 0 ] && [ ! -s "$work/out" ]; }
passes() { [ "$rc" -eq 0 ] && [ "$(cat "$work/out")" = "{}" ]; }

# msg_of RUNTIME: the block message of the last stop, empty when none.
msg_of() {
  if [ "$1" = codex ]; then
    [ "$(json_str "$work/out" decision)" = block ] && json_str "$work/out" reason
  else
    [ "$(json_str "$work/out" hookSpecificOutput.hookEventName)" = Stop ] \
      && json_str "$work/out" hookSpecificOutput.additionalContext
  fi
}

# listing DIR...: every path under DIR, sorted, with the type of each.
listing() {
  for d in "$@"; do
    find "$d" -print 2>/dev/null | LC_ALL=C sort | while IFS= read -r p; do
      if [ -L "$p" ]; then echo "L $p"; elif [ -d "$p" ]; then echo "d $p"; else echo "f $p $(cksum < "$p")"; fi
    done
  done
}

OLD=200001010000

# ---------------------------------------------------------------- X1
X1_NAMES='turn-@.state turn-@.state.tmp.1 @.state turn-@.statex xturn-@.state turn-@.txt turn-@.state.tmp turn_@.state'
for sh in $SHELLS; do
  new_case
  mkdir -p "$SD/sub" "$D/other" "$C/outside"
  expect=""
  for tmpl in $X1_NAMES; do
    for kind in f l d; do
      nm=$(printf '%s' "$tmpl" | sed "s/@/$kind/")
      case "$kind" in
        f) echo "$nm" > "$SD/$nm" ;;
        l) echo "target" > "$C/outside/$nm"
           TZ=UTC0 touch -t "$OLD" "$C/outside/$nm"
           ln -s "$C/outside/$nm" "$SD/$nm" ;;
        d) mkdir "$SD/$nm" ;;
      esac
      gone=no
      if [ "$kind" = f ]; then
        case "$nm" in turn-*.state|turn-*.state.tmp.*) gone=yes ;; esac
      fi
      expect="$expect $nm=$gone"
    done
  done
  echo nested > "$SD/sub/turn-n.state"
  echo top > "$D/turn-top.state"
  echo other > "$D/other/turn-o.state"
  echo fresh > "$SD/turn-fresh.state"
  for p in "$SD"/* "$SD/sub/turn-n.state" "$D/turn-top.state" "$D/other/turn-o.state"; do
    [ "$p" = "$SD/turn-fresh.state" ] && continue
    TZ=UTC0 touch -h -t "$OLD" "$p"
  done
  TZ=UTC0 touch -t "$OLD" "$SD/sub" "$D/other"
  outside_before=$(listing "$C/outside")
  prompt_in
  run "$sh" prompt
  why=""
  silent || why="$why prompt not silent;"
  for pair in $expect; do
    nm=${pair%=*}
    want=${pair#*=}
    if [ -e "$SD/$nm" ] || [ -L "$SD/$nm" ]; then have=no; else have=yes; fi
    [ "$have" = "$want" ] || why="$why $nm gone=$have (want $want);"
  done
  [ -f "$SD/sub/turn-n.state" ] || why="$why nested record left;"
  [ -f "$D/turn-top.state" ] || why="$why record at the top of the data folder left;"
  [ -f "$D/other/turn-o.state" ] || why="$why record in another subfolder left;"
  [ -f "$SD/turn-fresh.state" ] || why="$why fresh record left;"
  [ -f "$SD/turn-$SID.state" ] || why="$why own record missing;"
  [ "$(listing "$C/outside")" = "$outside_before" ] || why="$why a link target changed;"
  if [ -z "$why" ]; then ok "X1 cleanup removes only old regular files of the hook's pattern in its folder ($sh)"
  else fail "X1 cleanup ($sh)" "$why"; fi
done

# ---------------------------------------------------------------- X2
for sh in $SHELLS; do
  new_case
  mkdir -p "$C/outside"
  echo kept > "$C/outside/turn-v.state"
  TZ=UTC0 touch -t "$OLD" "$C/outside/turn-v.state"
  ln -s "$C/outside" "$SD"
  before=$(listing "$C/outside" "$D")
  prompt_in
  run "$sh" prompt
  why=""
  silent || why="$why prompt not silent;"
  set_manual 14000
  stop_in false
  run "$sh" stop
  passes || why="$why stop is not {}: $(cat "$work/out");"
  [ "$(listing "$C/outside" "$D")" = "$before" ] || why="$why the folder behind the link changed;"
  if [ -z "$why" ]; then ok "X2 own folder as a link: nothing written or deleted behind it ($sh)"
  else fail "X2 own folder as a link ($sh)" "$why"; fi
done

# ---------------------------------------------------------------- X3
for sh in $SHELLS; do
  new_case
  mkdir -p "$C/outside"
  prompt_in
  run "$sh" prompt
  why=""
  silent || why="$why prompt not silent;"
  rm -f "$SD/turn-$SID.state"
  printf 'size-gate 1 0 0\n%s\n' "$W" > "$C/outside/forged"
  ln -s "$C/outside/forged" "$SD/turn-$SID.state"
  before=$(listing "$C/outside")
  set_manual 14000
  stop_in false
  run "$sh" stop
  passes || why="$why stop is not {} (the link was read as the start): $(cat "$work/out");"
  [ "$(listing "$C/outside")" = "$before" ] || why="$why the link target changed;"
  if [ -L "$SD/turn-$SID.state" ] || [ ! -f "$SD/turn-$SID.state" ]; then
    why="$why the record is not a regular file after the stop;"
  fi
  if [ -z "$why" ]; then ok "X3 record as a link: target neither read nor written ($sh)"
  else fail "X3 record as a link ($sh)" "$why"; fi
done

# ---------------------------------------------------------------- X4
for sh in $SHELLS; do
  for form in rel ./rel rel/ rel/../rel; do
    new_case
    mkdir -p "$W/rel"
    data_val="$form"
    before=$(listing "$W")
    prompt_in
    run "$sh" prompt
    why=""
    silent || why="$why prompt not silent;"
    set_manual 14000
    stop_in false
    run "$sh" stop
    passes || why="$why stop is not {};"
    set_manual 2000
    [ "$(listing "$W")" = "$before" ] || why="$why something was written in the person's folder;"
    if [ -z "$why" ]; then ok "X4 relative CLAUDE_PLUGIN_DATA '$form' writes nothing ($sh)"
    else fail "X4 relative CLAUDE_PLUGIN_DATA '$form' ($sh)" "$why"; fi
  done
  for suffix in / /. //; do
    new_case
    data_val="$D$suffix"
    prompt_in
    run "$sh" prompt
    set_manual 14000
    stop_in false
    run "$sh" stop
    if [ -n "$(msg_of claude)" ] && [ -f "$SD/turn-$SID.state" ]; then
      ok "X4 absolute CLAUDE_PLUGIN_DATA with '$suffix' works ($sh)"
    else
      fail "X4 absolute CLAUDE_PLUGIN_DATA with '$suffix' ($sh)" "no block or no record: $(cat "$work/out")"
    fi
  done
done

# ---------------------------------------------------------------- X5
# Locales: C, then every UTF-8 one installed among the usual names (range
# matching in a bracket expression can follow the locale's collation).
LOCALES="C"
for l in C.UTF-8 C.utf8 en_US.UTF-8 en_US.utf8 pt_BR.UTF-8 pt_BR.utf8; do
  if locale -a 2>/dev/null | grep -qx "$l"; then LOCALES="$LOCALES $l"; fi
done
BAD_ASCII=$(LC_ALL=C awk 'BEGIN { for (i = 32; i < 127; i++) { c = sprintf("%c", i); if (c !~ /[A-Za-z0-9._-]/) printf "%s", c } }')
# The non-ASCII forms: e acute (UTF-8), a lone byte 0xff, a full-width A.
NON_ASCII=$(printf '\303\251 \377 \357\274\241')
for sh in $SHELLS; do
  for l in $LOCALES; do
    new_case
    lc="$l"
    bad=0
    first=""
    # Every bad printable ASCII character, one at a time, in the middle.
    i=1
    while [ "$i" -le "${#BAD_ASCII}" ]; do
      c=$(printf '%s' "$BAD_ASCII" | LC_ALL=C cut -c"$i")
      case "$c" in
        '"') j='\"' ;;
        '\') j='\\' ;;
        *) j="$c" ;;
      esac
      for ev in prompt stop; do
        if [ "$ev" = prompt ]; then prompt_in "a${j}b"; else set_manual 14000; stop_in false "a${j}b"; fi
        run "$sh" "$ev"
        if [ "$ev" = prompt ]; then silent || { bad=$((bad + 1)); first="${first:-prompt [$c] not silent}"; }
        else passes || { bad=$((bad + 1)); first="${first:-stop [$c] not the empty object}"; }; fi
        if [ -n "$(find "$D" -mindepth 1 ! -name size-gate -print)" ]; then
          bad=$((bad + 1)); first="${first:-[$c] wrote $(find "$D" -mindepth 1 -print | tr '\n' ' ')}"
          rm -rf "$D"; mkdir "$D"
        fi
      done
      i=$((i + 1))
    done
    for c in $NON_ASCII; do
      for ev in prompt stop; do
        if [ "$ev" = prompt ]; then prompt_in "a${c}b"; else stop_in false "a${c}b"; fi
        run "$sh" "$ev"
        if [ "$ev" = prompt ]; then silent || { bad=$((bad + 1)); first="${first:-prompt non-ASCII not silent}"; }
        else passes || { bad=$((bad + 1)); first="${first:-stop non-ASCII not the empty object}"; }; fi
        if [ -n "$(find "$D" -mindepth 1 ! -name size-gate -print)" ]; then
          bad=$((bad + 1)); first="${first:-non-ASCII $(printf '%s' "$c" | od -An -tx1 | tr -d ' ') wrote a record}"
          rm -rf "$D"; mkdir "$D"
        fi
      done
    done
    # Every allowed character works: one id holding all of them.
    good="-Az09._AZaz-"
    set_manual 2000
    prompt_in "$good"
    run "$sh" prompt
    set_manual 14000
    stop_in false "$good"
    run "$sh" stop
    [ -n "$(msg_of claude)" ] || { bad=$((bad + 1)); first="${first:-allowed id $good did not block}"; }
    if [ "$bad" -eq 0 ]; then ok "X5 session_id charset under LC_ALL=$l ($sh)"
    else fail "X5 session_id charset under LC_ALL=$l ($sh)" "$bad bad runs; first: $first"; fi
  done
done

# ---------------------------------------------------------------- X6
TOOLS="cat wc tr awk find grep mkdir mv rm sed cut uname"
fakes="$work/fakes"
for code in 1 0; do
  for t in $TOOLS; do
    mkdir -p "$fakes/$code/$t"
    printf '#!/bin/sh\necho NOISE-out\necho NOISE-err >&2\nexit %s\n' "$code" > "$fakes/$code/$t/$t"
    chmod +x "$fakes/$code/$t/$t"
  done
done
for sh in $SHELLS; do
  bad=0
  first=""
  total=0
  for code in 1 0; do
    for t in $TOOLS; do
      for when in fresh recorded; do
        total=$((total + 1))
        new_case
        set_manual 12900
        prompt_in
        [ "$when" = fresh ] && path_front="$fakes/$code/$t"
        run "$sh" prompt
        if ! silent; then bad=$((bad + 1)); first="${first:-prompt with $t exit $code ($when): exit $rc, $(head -c 80 "$work/out")}"; fi
        path_front="$fakes/$code/$t"
        set_manual 14000
        stop_in false
        run "$sh" stop
        if [ "$rc" -ne 0 ] || ! json_object "$work/out" || grep -q NOISE "$work/out"; then
          bad=$((bad + 1)); first="${first:-stop with $t exit $code ($when): exit $rc, $(head -c 80 "$work/out")}"
        fi
      done
    done
  done
  if [ "$bad" -eq 0 ]; then ok "X6 noisy fakes: prompt silent, stop one JSON object, $total runs ($sh)"
  else fail "X6 noisy fakes ($sh)" "$bad of $total bad; first: $first"; fi
done

# ---------------------------------------------------------------- X7
# x7 SHELL RUNTIME MS ME CS CE: manual from MS to ME, CRITICAL_FACTS.md from
# CS to CE, then checks the stop against the oracle. Sets x7_why.
x7() {
  new_case
  set_manual "$3"
  set_cf "$5"
  marker=""
  [ "$2" = codex ] && marker=codex
  prompt_in
  run "$1" prompt $marker
  set_manual "$4"
  set_cf "$6"
  stop_in false
  run "$1" stop $marker
  grew_m=no
  grew_c=no
  [ "$4" -gt "$3" ] && [ "$4" -gt 13000 ] && grew_m=yes
  [ "$6" -gt "$5" ] && [ "$6" -gt 3900 ] && grew_c=yes
  x7_check "$2" "$3" "$4" "$5" "$6"
}
# x7_check RUNTIME MS ME CS CE (with grew_m and grew_c set).
x7_check() {
  x7_why=""
  [ "$rc" -eq 0 ] || x7_why="exit $rc"
  if [ "$grew_m" = no ] && [ "$grew_c" = no ]; then
    passes || x7_why="$x7_why expected {} got $(head -c 120 "$work/out")"
    return
  fi
  m=$(msg_of "$1")
  if [ -z "$m" ]; then x7_why="$x7_why expected a $1 block got $(head -c 120 "$work/out")"; return; fi
  [ "${#m}" -le 2000 ] || x7_why="$x7_why message of ${#m} characters"
  has_m=no
  has_c=no
  case "$m" in *"$MANUAL_LABEL grew from $2 to $3 bytes"*) has_m=yes ;; esac
  case "$m" in *"$CF_LABEL grew from $4 to $5 bytes"*) has_c=yes ;; esac
  case "$m" in *"$MANUAL_LABEL grew"*) [ "$grew_m" = no ] && x7_why="$x7_why names the manual, which did not grow" ;; esac
  case "$m" in *"$CF_LABEL grew"*) [ "$grew_c" = no ] && x7_why="$x7_why names CRITICAL_FACTS.md, which did not grow" ;; esac
  [ "$grew_m" = yes ] && [ "$has_m" = no ] && x7_why="$x7_why lacks the manual numbers"
  [ "$grew_c" = yes ] && [ "$has_c" = no ] && x7_why="$x7_why lacks the CRITICAL_FACTS.md numbers"
}
for sh in $SHELLS; do
  for rt in claude codex; do
    bad=0
    first=""
    total=0
    for s in 12999 13000 13001 13002; do
      for e in 12999 13000 13001 13002; do
        total=$((total + 1))
        x7 "$sh" "$rt" "$s" "$e" 1000 1000
        [ -z "$x7_why" ] || { bad=$((bad + 1)); first="${first:-manual $s to $e:$x7_why}"; }
      done
    done
    for s in 3899 3900 3901 3902; do
      for e in 3899 3900 3901 3902; do
        total=$((total + 1))
        x7 "$sh" "$rt" 2000 2000 "$s" "$e"
        [ -z "$x7_why" ] || { bad=$((bad + 1)); first="${first:-CRITICAL_FACTS.md $s to $e:$x7_why}"; }
      done
    done
    for mp in "13001 13002" "13002 13002" "13002 13001"; do
      for cp in "3901 3902" "3902 3902" "3902 3901"; do
        total=$((total + 1))
        set -- $mp $cp
        x7 "$sh" "$rt" "$1" "$2" "$3" "$4"
        [ -z "$x7_why" ] || { bad=$((bad + 1)); first="${first:-both $mp / $cp:$x7_why}"; }
      done
    done
    # A manual file appearing: CLAUDE.md alone (old layout) at 12990, then
    # AGENTS.md of 20 bytes appears; and one leaving: AGENTS.md removed.
    total=$((total + 1))
    new_case
    marker=""
    [ "$rt" = codex ] && marker=codex
    rm -f "$W/AGENTS.md" "$W/navigation.md"
    fill "$W/CLAUDE.md" 12990
    prompt_in
    run "$sh" prompt $marker
    fill "$W/AGENTS.md" 20
    stop_in false
    run "$sh" stop $marker
    grew_m=yes
    grew_c=no
    x7_check "$rt" 12990 13010 1000 1000
    [ -z "$x7_why" ] || { bad=$((bad + 1)); first="${first:-AGENTS.md appearing:$x7_why}"; }
    total=$((total + 1))
    new_case
    set_manual 14000
    prompt_in
    run "$sh" prompt $marker
    rm -f "$W/AGENTS.md"
    stop_in false
    run "$sh" stop $marker
    grew_m=no
    x7_check "$rt" 14000 11 1000 1000
    [ -z "$x7_why" ] || { bad=$((bad + 1)); first="${first:-AGENTS.md leaving:$x7_why}"; }
    if [ "$bad" -eq 0 ]; then ok "X7 sizes around the caps, $total forms, $rt ($sh)"
    else fail "X7 sizes around the caps, $rt ($sh)" "$bad of $total wrong; first: $first"; fi
  done
done

# ---------------------------------------------------------------- X8
for sh in $SHELLS; do
  bad=0
  first=""
  total=0
  for form in prefix child parent extra-line short-head extra-field version negative plus empty; do
    total=$((total + 1))
    new_case
    mkdir -p "$W/sub"
    prompt_in
    run "$sh" prompt
    rec="$SD/turn-$SID.state"
    case "$form" in
      prefix) printf 'size-gate 1 2000 1000\n%s\n' "${W%k}" > "$rec" ;;
      child) printf 'size-gate 1 2000 1000\n%s\n' "$W/sub" > "$rec" ;;
      parent) printf 'size-gate 1 2000 1000\n%s\n' "$C" > "$rec" ;;
      extra-line) printf 'size-gate 1 2000 1000\n%s\nmore\n' "$W" > "$rec" ;;
      short-head) printf 'size-gate 1 2000\n%s\n' "$W" > "$rec" ;;
      extra-field) printf 'size-gate 1 2000 1000 9\n%s\n' "$W" > "$rec" ;;
      version) printf 'size-gate 2 2000 1000\n%s\n' "$W" > "$rec" ;;
      negative) printf 'size-gate 1 -5 1000\n%s\n' "$W" > "$rec" ;;
      plus) printf 'size-gate 1 +5 1000\n%s\n' "$W" > "$rec" ;;
      empty) : > "$rec" ;;
    esac
    set_manual 14000
    stop_in false
    run "$sh" stop
    if ! passes; then
      bad=$((bad + 1)); first="${first:-$form: stop is not the empty object: $(head -c 120 "$work/out")}"
      continue
    fi
    # The stop recorded its end: the next turn without a prompt compares
    # with it and blocks from 14000.
    set_manual 14100
    stop_in false
    run "$sh" stop
    case "$(msg_of claude)" in
      *"$MANUAL_LABEL grew from 14000 to 14100 bytes"*) ;;
      *) bad=$((bad + 1)); first="${first:-$form: the next turn did not block from 14000}" ;;
    esac
  done
  if [ "$bad" -eq 0 ]; then ok "X8 other-root and corrupt records pass and are replaced, $total forms ($sh)"
  else fail "X8 other-root and corrupt records ($sh)" "$bad of $total wrong; first: $first"; fi
done

chmod -R u+w "$work" 2>/dev/null
rm -rf "$work"
[ "$failures" -eq 0 ] || exit 1
exit 0
