#!/bin/sh
# Test for the Codex bridge (modules/codex-bridge.sh): the person's folder
# gets .agents/skills pointing at the single source .claude/skills, without
# replacing anything that already exists.
# Run by hand: sh tests/codex-bridge-test.sh
# Each case builds a folder from mktemp -d with a space in its name, runs the
# bridge inside it (the bridge reads paths relative to the cwd, as in a real
# session) and removes the folder. The cases check disk state and exit code,
# never the bridge's text.
# With codex on the PATH, the D cases run `codex debug prompt-input` in the
# built folder, which assembles the prompt without calling a model: it proves
# discovery, not execution. Without codex, the D cases print "info" and the
# rest runs the same.
# Cases L1 and L2 start from the wrappers the 0.7.0 bridge wrote in installed
# folders (frozen marker, Portuguese body, proof), built here byte by byte.
# Output: one ok or FAIL line per case; exit 0 only when everything passes.
#
# Manual proof, outside this test, because it depends on a model or on a
# persistent install (done by whoever decides to install, never by this
# script):
# 1) install: `codex plugin add` from the local marketplace writes cache and
#    config; afterwards the plugin skills show up and the six seeds do not.
# 2) hook: review and trust the hook in Codex /hooks; open a session in a
#    Chief of Staff folder with memoria-agente telemetry and check the boot
#    at session start; check whether Codex reads only the manifest hook or
#    also hooks/hooks.json (a double boot is the accepted side).
# 3) model: setup, plant and create-skill run the bridge and handle the
#    conflict without deleting; a skill edited in .claude/skills shows up in
#    the next Codex session; the generated AGENTS.md carries the rules index;
#    remove-ai-tells opens a fresh subagent for the reviewer, with no
#    history, and another one for the reread.
# 4) Claude regression: session with --plugin-dir on this repo, boot and
#    handoff.

# An exported CDPATH makes cd print the folder inside $(...), which would
# double every path built from DIR.
unset CDPATH
DIR=$(cd "$(dirname "$0")/.." && pwd) || exit 1
BRIDGE="$DIR/modules/codex-bridge.sh"
SENT="COS_BRIDGE_SENTINEL"
failures=0

ok() { echo "ok    $1"; }
fail() { echo "FAIL  $1: $2"; failures=$((failures + 1)); }

# build FOLDER: source with two skills and _shared, which is not a skill.
build() {
  mkdir -p "$1/.claude/skills/start-day" "$1/.claude/skills/close-day" "$1/.claude/skills/_shared"
  printf -- '---\nname: start-day\ndescription: %s start.\n---\n\n# Start\nthe person'"'"'s body\n' "$SENT" > "$1/.claude/skills/start-day/SKILL.md"
  printf -- '---\nname: close-day\ndescription: >\n  %s close,\n  on two lines.\n---\n\n# Close\n' "$SENT" > "$1/.claude/skills/close-day/SKILL.md"
  echo "module" > "$1/.claude/skills/_shared/capabilities.md"
}

# fresh: temporary folder with a space in its name, returned in $tmp and $folder.
fresh() {
  tmp=$(mktemp -d 2>/dev/null)
  if [ -z "$tmp" ] || [ ! -d "$tmp" ]; then
    fail "$1" "mktemp -d returned no folder"
    return 1
  fi
  folder="$tmp/my cos folder"
  mkdir -p "$folder"
}

# run [PATH_PREFIX]: runs the bridge in $folder, keeps the exit code in $rc.
run() {
  if [ -n "$1" ]; then
    (cd "$folder" && PATH="$1:$PATH" sh "$BRIDGE" >/dev/null 2>&1)
  else
    (cd "$folder" && sh "$BRIDGE" >/dev/null 2>&1)
  fi
  rc=$?
}

if [ -f "$BRIDGE" ]; then
  ok "bridge exists"
else
  fail "bridge exists" "$BRIDGE missing"
fi

# P1 clean folder: the relative link to the whole collection is created.
if fresh P1; then
  build "$folder"
  run
  target=$(readlink "$folder/.agents/skills" 2>/dev/null)
  if [ "$rc" -eq 0 ] && [ "$target" = "../.claude/skills" ] \
    && [ -f "$folder/.agents/skills/start-day/SKILL.md" ]; then
    ok "P1 clean folder gets the relative collection link"
  else
    fail "P1 clean folder" "exit $rc, link: $target"
  fi
  # P2 again in the same folder: nothing changes, exit 0.
  run
  target2=$(readlink "$folder/.agents/skills" 2>/dev/null)
  if [ "$rc" -eq 0 ] && [ "$target2" = "../.claude/skills" ]; then
    ok "P2 second run changes nothing"
  else
    fail "P2 second run" "exit $rc, link: $target2"
  fi
  # P3 an edit in the source shows through the link, with no copy.
  echo "canonical edit" >> "$folder/.claude/skills/start-day/SKILL.md"
  if grep -qx "canonical edit" "$folder/.agents/skills/start-day/SKILL.md" 2>/dev/null; then
    ok "P3 source edit shows through the bridge"
  else
    fail "P3 source edit" "did not show in .agents/skills"
  fi
  rm -rf "$tmp"
fi

# P4 .agents/skills is already a link elsewhere: stays as is, exit 2.
if fresh P4; then
  build "$folder"
  mkdir -p "$folder/.agents" "$folder/other"
  ln -s ../other "$folder/.agents/skills"
  run
  target=$(readlink "$folder/.agents/skills" 2>/dev/null)
  if [ "$rc" -eq 2 ] && [ "$target" = "../other" ]; then
    ok "P4 the person's link elsewhere stays"
  else
    fail "P4 the person's link" "exit $rc, link: $target"
  fi
  rm -rf "$tmp"
fi

# P5 .agents/skills is a regular file: stays as is, exit 2.
if fresh P5; then
  build "$folder"
  mkdir -p "$folder/.agents"
  echo "the person's file" > "$folder/.agents/skills"
  run
  if [ "$rc" -eq 2 ] && [ -f "$folder/.agents/skills" ] && [ ! -L "$folder/.agents/skills" ] \
    && grep -qx "the person's file" "$folder/.agents/skills"; then
    ok "P5 the person's file in the bridge's place stays"
  else
    fail "P5 the person's file" "exit $rc"
  fi
  rm -rf "$tmp"
fi

# P6 broken link at .agents/skills: stays as is, exit 2.
if fresh P6; then
  build "$folder"
  mkdir -p "$folder/.agents"
  ln -s ../does-not-exist "$folder/.agents/skills"
  run
  target=$(readlink "$folder/.agents/skills" 2>/dev/null)
  if [ "$rc" -eq 2 ] && [ "$target" = "../does-not-exist" ]; then
    ok "P6 broken link stays"
  else
    fail "P6 broken link" "exit $rc, link: $target"
  fi
  rm -rf "$tmp"
fi

# P7 .agents/skills is a real folder with the person's skill of the same
# name: theirs stays intact, the missing one gets its own link, _shared stays
# out, exit 2.
if fresh P7; then
  build "$folder"
  mkdir -p "$folder/.agents/skills/start-day"
  echo "the person's codex skill" > "$folder/.agents/skills/start-day/SKILL.md"
  run
  target=$(readlink "$folder/.agents/skills/close-day" 2>/dev/null)
  if [ "$rc" -eq 2 ] && [ ! -L "$folder/.agents/skills" ] \
    && [ "$(cat "$folder/.agents/skills/start-day/SKILL.md")" = "the person's codex skill" ] \
    && [ "$target" = "../../.claude/skills/close-day" ] \
    && [ ! -e "$folder/.agents/skills/_shared" ] && [ ! -L "$folder/.agents/skills/_shared" ]; then
    ok "P7 real folder: theirs stays, the missing one gets a link, _shared out"
  else
    fail "P7 real folder" "exit $rc, close-day link: $target"
  fi
  # P8 next run with the collision solved by the person: exit 0, link kept.
  rm -rf "$folder/.agents/skills/start-day"
  run
  if [ "$rc" -eq 0 ] && [ "$(readlink "$folder/.agents/skills/start-day" 2>/dev/null)" = "../../.claude/skills/start-day" ] \
    && [ "$(readlink "$folder/.agents/skills/close-day" 2>/dev/null)" = "../../.claude/skills/close-day" ]; then
    ok "P8 real folder without collision ends with exit 0"
  else
    fail "P8 real folder without collision" "exit $rc"
  fi
  rm -rf "$tmp"
fi

# P9 no .claude/skills: nothing is created, exit 1.
if fresh P9; then
  run
  if [ "$rc" -eq 1 ] && [ ! -e "$folder/.agents" ] && [ ! -L "$folder/.agents" ]; then
    ok "P9 without a source nothing is created"
  else
    fail "P9 without a source" "exit $rc"
  fi
  rm -rf "$tmp"
fi

# E1 .agents is a link to the person's folder outside the workspace: link
# and target stay as they are, nothing is created there, exit 2.
if fresh E1; then
  build "$folder"
  mkdir -p "$tmp/outside"
  echo "the person's" > "$tmp/outside/note.md"
  ln -s ../outside "$folder/.agents"
  before=$(ls -lAR "$tmp/outside" | cksum)
  run
  if [ "$rc" -eq 2 ] && [ "$(readlink "$folder/.agents")" = "../outside" ] \
    && [ ! -e "$tmp/outside/skills" ] && [ ! -L "$tmp/outside/skills" ] \
    && [ "$(ls -lAR "$tmp/outside" | cksum)" = "$before" ]; then
    ok "E1 .agents linked outside stays, nothing is created in the target"
  else
    fail "E1 .agents as a link" "exit $rc, target: $(ls -A "$tmp/outside" | tr '\n' ' ')"
  fi
  rm -rf "$tmp"
fi

# E2 .agents is a broken link: stays, the target still does not exist, exit 2.
if fresh E2; then
  build "$folder"
  ln -s ../does-not-exist "$folder/.agents"
  run
  if [ "$rc" -eq 2 ] && [ "$(readlink "$folder/.agents")" = "../does-not-exist" ] \
    && [ ! -e "$tmp/does-not-exist" ] && [ ! -L "$tmp/does-not-exist" ]; then
    ok "E2 .agents as a broken link stays"
  else
    fail "E2 .agents as a broken link" "exit $rc"
  fi
  rm -rf "$tmp"
fi

# W cases: links unavailable. A fake ln, put at the front of the PATH only
# while the bridge runs, exits with an error, as on a system without
# symbolic links.
fake=$(mktemp -d 2>/dev/null)
printf '#!/bin/sh\necho "fake ln: no link" >&2\nexit 1\n' > "$fake/ln"
chmod +x "$fake/ln"

# W1 no link: one wrapper per skill with the source frontmatter and the
# order to read the source, in English.
if fresh W1; then
  build "$folder"
  run "$fake"
  w="$folder/.agents/skills/close-day/SKILL.md"
  fm_source=$(sed -n '1,/^---$/p' "$folder/.claude/skills/close-day/SKILL.md" | sed -n '2,$p')
  fm_w=$(sed -n '1,/^---$/p' "$w" 2>/dev/null | sed -n '2,$p')
  if [ "$rc" -eq 0 ] && [ ! -L "$folder/.agents/skills" ] && [ -f "$w" ] && [ ! -L "$folder/.agents/skills/close-day" ] \
    && [ -n "$fm_w" ] && [ "$fm_w" = "$fm_source" ] \
    && grep -qF ".claude/skills/close-day/SKILL.md" "$w" \
    && grep -qF "This skill lives in" "$w" \
    && [ -f "$folder/.agents/skills/start-day/SKILL.md" ] \
    && [ ! -e "$folder/.agents/skills/_shared" ]; then
    ok "W1 no link: wrapper with the source frontmatter and pointer"
  else
    fail "W1 no link" "exit $rc"
  fi
  # W2 the description changed in the source: the generated wrapper follows.
  sed 's/start\./start, changed./' "$folder/.claude/skills/start-day/SKILL.md" > "$tmp/new"
  cat "$tmp/new" > "$folder/.claude/skills/start-day/SKILL.md"
  run "$fake"
  if [ "$rc" -eq 0 ] && grep -qF "$SENT start, changed." "$folder/.agents/skills/start-day/SKILL.md"; then
    ok "W2 generated wrapper follows the description"
  else
    fail "W2 wrapper follows" "exit $rc"
  fi
  # W2b the updated wrapper stays intact: the next run reports no conflict.
  before=$(cksum < "$folder/.agents/skills/start-day/SKILL.md")
  run "$fake"
  if [ "$rc" -eq 0 ] && [ "$(cksum < "$folder/.agents/skills/start-day/SKILL.md")" = "$before" ]; then
    ok "W2b updated wrapper stays intact"
  else
    fail "W2b updated wrapper intact" "exit $rc"
  fi
  # W3 a wrapper without the bridge marker belongs to the person: stays, exit 2.
  printf -- '---\nname: close-day\ndescription: my version.\n---\nwritten by hand\n' > "$folder/.agents/skills/close-day/SKILL.md"
  run "$fake"
  if [ "$rc" -eq 2 ] && grep -qx "written by hand" "$folder/.agents/skills/close-day/SKILL.md"; then
    ok "W3 the person's SKILL.md in .agents/skills stays"
  else
    fail "W3 the person's SKILL.md" "exit $rc"
  fi
  rm -rf "$tmp"
fi

# W4 to W6: a wrapper with the marker but touched by the person, or without
# the integrity proof (earlier format). The source changes, so an undue
# update would replace the file; the wrapper stays byte for byte, exit 2.
# touch_case CASE DESCRIPTION: generates the wrapper, applies the edit to
# $w, changes the source, runs again and checks.
touch_case() {
  if fresh "$1"; then
    build "$folder"
    run "$fake"
    w="$folder/.agents/skills/start-day/SKILL.md"
    case "$1" in
      W4) echo "Instruction added by the person." >> "$w" ;;
      W5) sed 's/start\./start, the person'"'"'s version./' "$w" > "$tmp/new" && cat "$tmp/new" > "$w" ;;
      W6) sed '$d' "$w" > "$tmp/new" && cat "$tmp/new" > "$w" ;;
    esac
    before=$(cksum < "$w")
    sed 's/start\./start, changed./' "$folder/.claude/skills/start-day/SKILL.md" > "$tmp/new"
    cat "$tmp/new" > "$folder/.claude/skills/start-day/SKILL.md"
    run "$fake"
    if [ "$rc" -eq 2 ] && [ -f "$w" ] && [ ! -L "$w" ] && [ "$(cksum < "$w")" = "$before" ]; then
      ok "$1 $2"
    else
      fail "$1 $2" "exit $rc, wrapper changed: $(cksum < "$w") against $before"
    fi
    rm -rf "$tmp"
  fi
}
touch_case W4 "wrapper body edited with the marker stays"
touch_case W5 "wrapper metadata edited with the marker stays"
touch_case W6 "wrapper with the marker and no integrity proof stays"

# E3 .agents is a link outside with a wrapper generated there: nothing in
# the target changes, even with the source changed and no links on the
# system, exit 2.
if fresh E3; then
  build "$folder"
  mkdir -p "$tmp/gen"
  build "$tmp/gen"
  (cd "$tmp/gen" && PATH="$fake:$PATH" sh "$BRIDGE" >/dev/null 2>&1)
  mv "$tmp/gen/.agents" "$tmp/outside"
  ln -s ../outside "$folder/.agents"
  echo "canonical edit" >> "$folder/.claude/skills/start-day/SKILL.md"
  before=$(ls -lAR "$tmp/outside" | cksum)
  wbefore=$(cksum < "$tmp/outside/skills/start-day/SKILL.md" 2>/dev/null)
  run "$fake"
  if [ "$rc" -eq 2 ] && [ -n "$wbefore" ] && [ "$(readlink "$folder/.agents")" = "../outside" ] \
    && [ "$(cksum < "$tmp/outside/skills/start-day/SKILL.md")" = "$wbefore" ] \
    && [ "$(ls -lAR "$tmp/outside" | cksum)" = "$before" ]; then
    ok "E3 wrapper outside the workspace is not updated through the .agents link"
  else
    fail "E3 wrapper outside through the link" "exit $rc"
  fi
  rm -rf "$tmp"
fi

# F3 the first write of the wrapper fails: the empty folder the run created
# goes away, exit 1; without the limit, the same folder gets the wrapper,
# exit 0.
if fresh F3; then
  build "$folder"
  long=$(awk 'BEGIN { for (i = 0; i < 400; i++) printf "word%03d ", i }')
  printf -- '---\nname: start-day\ndescription: %s %s\n---\n\n# Start\n' "$SENT" "$long" > "$folder/.claude/skills/start-day/SKILL.md"
  (cd "$folder" && ulimit -c 0 && ulimit -f 1 && PATH="$fake:$PATH" sh "$BRIDGE" >/dev/null 2>&1)
  rc=$?
  d="$folder/.agents/skills/start-day"
  if [ "$rc" -eq 1 ] && [ ! -e "$d" ] && [ ! -L "$d" ]; then
    ok "F3 failure on the first write leaves no empty folder"
  else
    fail "F3 failure on the first write" "exit $rc, entries: $(ls -A "$d" 2>/dev/null | tr '\n' ' ')"
  fi
  run "$fake"
  if [ "$rc" -eq 0 ] && grep -qF "word399" "$d/SKILL.md" 2>/dev/null \
    && [ "$(ls -A "$d" | wc -l | tr -d ' ')" -eq 1 ]; then
    ok "F3b next run creates the wrapper in the same folder"
  else
    fail "F3b next run" "exit $rc"
  fi
  rm -rf "$tmp"
fi

# F4 the write fails, but the folder got the person's content in the
# meantime (a fake mkdir that creates the file): the content stays, only the
# write fails.
fake2=$(mktemp -d 2>/dev/null)
printf '#!/bin/sh\nexit 1\n' > "$fake2/ln"
printf '#!/bin/sh\n/bin/mkdir "$@" || exit $?\nfor a; do case "$a" in -*) ;; *) echo "the person'"'"'s" > "$a/notes.md" ;; esac; done\n' > "$fake2/mkdir"
chmod +x "$fake2/ln" "$fake2/mkdir"
if fresh F4; then
  build "$folder"
  mkdir -p "$folder/.agents/skills"
  long=$(awk 'BEGIN { for (i = 0; i < 400; i++) printf "word%03d ", i }')
  printf -- '---\nname: start-day\ndescription: %s %s\n---\n\n# Start\n' "$SENT" "$long" > "$folder/.claude/skills/start-day/SKILL.md"
  (cd "$folder" && ulimit -c 0 && ulimit -f 1 && PATH="$fake2:$PATH" sh "$BRIDGE" >/dev/null 2>&1)
  rc=$?
  d="$folder/.agents/skills/start-day"
  if [ "$rc" -eq 1 ] && grep -qx "the person's" "$d/notes.md" 2>/dev/null \
    && [ "$(ls -A "$d" | wc -l | tr -d ' ')" -eq 1 ]; then
    ok "F4 failure on the first write keeps what appeared in the folder"
  else
    fail "F4 content kept" "exit $rc, entries: $(ls -A "$d" 2>/dev/null | tr '\n' ' ')"
  fi
  rm -rf "$tmp"
fi
rm -rf "$fake2"

# S1 SKILL.md in .agents/skills is a link to the person's file, and the
# target carries the bridge marker: link and target stay as they are, exit 2.
if fresh S1; then
  build "$folder"
  run "$fake"
  w="$folder/.agents/skills/start-day/SKILL.md"
  cp "$w" "$tmp/the persons.md"
  echo "the person's text" >> "$tmp/the persons.md"
  before=$(cksum < "$tmp/the persons.md")
  rm "$w"
  ln -s "../../../../the persons.md" "$w"
  run "$fake"
  if [ "$rc" -eq 2 ] && [ -L "$w" ] && [ "$(readlink "$w")" = "../../../../the persons.md" ] \
    && [ "$(cksum < "$tmp/the persons.md")" = "$before" ]; then
    ok "S1 SKILL.md linked to the person's file with the marker stays"
  else
    fail "S1 linked SKILL.md" "exit $rc, target changed or link replaced"
  fi
  rm -rf "$tmp"
fi

# S2 SKILL.md in .agents/skills is a broken link: stays, nothing is created
# at the target, exit 2.
if fresh S2; then
  build "$folder"
  run "$fake"
  w="$folder/.agents/skills/start-day/SKILL.md"
  rm "$w"
  ln -s "../../../../does-not-exist.md" "$w"
  run "$fake"
  if [ "$rc" -eq 2 ] && [ -L "$w" ] && [ "$(readlink "$w")" = "../../../../does-not-exist.md" ] \
    && [ ! -e "$tmp/does-not-exist.md" ]; then
    ok "S2 SKILL.md as a broken link stays"
  else
    fail "S2 SKILL.md as a broken link" "exit $rc"
  fi
  rm -rf "$tmp"
fi

# F1 a write fails while updating the wrapper (file size limit only in the
# bridge's subshell, no core): the previous one stays identical, the
# person's file in the same folder stays, no temporary is left, exit 1.
if fresh F1; then
  build "$folder"
  run "$fake"
  d="$folder/.agents/skills/start-day"
  echo "the person's notes" > "$d/notes.md"
  before=$(cksum < "$d/SKILL.md")
  long=$(awk 'BEGIN { for (i = 0; i < 400; i++) printf "word%03d ", i }')
  printf -- '---\nname: start-day\ndescription: %s %s\n---\n\n# Start\n' "$SENT" "$long" > "$folder/.claude/skills/start-day/SKILL.md"
  (cd "$folder" && ulimit -c 0 && ulimit -f 1 && PATH="$fake:$PATH" sh "$BRIDGE" >/dev/null 2>&1)
  rc=$?
  if [ "$rc" -eq 1 ] && [ -f "$d/SKILL.md" ] && [ ! -L "$d/SKILL.md" ] \
    && [ "$(cksum < "$d/SKILL.md")" = "$before" ] \
    && grep -qx "the person's notes" "$d/notes.md" \
    && [ "$(ls -A "$d" | wc -l | tr -d ' ')" -eq 2 ]; then
    ok "F1 a write failure keeps the previous wrapper and does not claim success"
  else
    fail "F1 write failure" "exit $rc, entries: $(ls -A "$d" | tr '\n' ' ')"
  fi
  # F2 without the limit, the same folder updates the wrapper and ends with exit 0.
  run "$fake"
  if [ "$rc" -eq 0 ] && grep -qF "word399" "$d/SKILL.md" \
    && [ "$(ls -A "$d" | wc -l | tr -d ' ')" -eq 2 ]; then
    ok "F2 next run without the limit updates the wrapper"
  else
    fail "F2 run without the limit" "exit $rc"
  fi
  rm -rf "$tmp"
fi

# L cases: folders installed by 0.7.0 with wrappers. The marker and the
# proof prefix are frozen literals (spec I6), copied here as bytes instead of
# read from the bridge, so a change to the bridge constants fails L1.
MARK07='<!-- gerado pela ponte-codex do pm-chief-of-staff; a fonte e a pasta .claude/skills -->'
PROOF07='<!-- integridade ponte-codex, cksum do que vem acima: '

# legacy_build FOLDER: the 0.7.0 seed names as sources, and in .agents/skills
# the wrapper the 0.7.0 bridge wrote for each one: frontmatter of the source,
# marker, the Portuguese body of modulos/ponte-codex.sh:82 at 318ea9c, and
# the proof computed the way 0.7.0 computed it.
legacy_build() {
  for n in abrir-dia fechar-dia; do
    mkdir -p "$1/.claude/skills/$n" "$1/.agents/skills/$n"
    printf -- '---\nname: %s\ndescription: %s %s.\n---\n\n# %s\n' "$n" "$SENT" "$n" "$n" > "$1/.claude/skills/$n/SKILL.md"
    fm=$(awk 'NR == 1 { next } /^---$/ { exit } { print }' "$1/.claude/skills/$n/SKILL.md")
    body07=$(printf -- '---\n%s\n---\n%s\n\n%s' "$fm" "$MARK07" "Esta skill mora em \`.claude/skills/$n/SKILL.md\`, a fonte desta pasta. Leia esse arquivo inteiro e siga o que ele diz; caminho relativo citado nele parte da pasta dele. Edição vai sempre na fonte: a próxima rodada da ponte atualiza o frontmatter aqui.")
    printf '%s\n%s%s -->\n' "$body07" "$PROOF07" "$(printf '%s\n' "$body07" | cksum)" > "$1/.agents/skills/$n/SKILL.md"
  done
}

# intact07 FILE: regular file, the marker line present, and the last line is
# the frozen proof matching everything above it.
intact07() {
  [ -f "$1" ] && [ ! -L "$1" ] && grep -qxF "$MARK07" "$1" || return 1
  last=$(tail -n 1 "$1")
  case "$last" in "$PROOF07"*" -->") ;; *) return 1 ;; esac
  sum=${last#"$PROOF07"}
  sum=${sum%" -->"}
  [ -n "$sum" ] && [ "$(sed '$d' "$1" | cksum)" = "$sum" ]
}

# L1 intact 0.7.0 wrapper and a new description in the source: the wrapper
# is rewritten with the new frontmatter, keeps the frozen marker and a proof
# that matches, exit 0.
if fresh L1; then
  legacy_build "$folder"
  w="$folder/.agents/skills/abrir-dia/SKILL.md"
  if intact07 "$w"; then built=yes; else built=no; fi
  before=$(cksum < "$w")
  sed 's/abrir-dia\./abrir-dia, changed./' "$folder/.claude/skills/abrir-dia/SKILL.md" > "$tmp/new"
  cat "$tmp/new" > "$folder/.claude/skills/abrir-dia/SKILL.md"
  run "$fake"
  fm_source=$(sed -n '1,/^---$/p' "$folder/.claude/skills/abrir-dia/SKILL.md" | sed -n '2,$p')
  fm_w=$(sed -n '1,/^---$/p' "$w" 2>/dev/null | sed -n '2,$p')
  if [ "$built" = yes ] && [ "$rc" -eq 0 ] && intact07 "$w" \
    && [ "$(cksum < "$w")" != "$before" ] \
    && [ -n "$fm_w" ] && [ "$fm_w" = "$fm_source" ] \
    && grep -qF "$SENT abrir-dia, changed." "$w" \
    && grep -qF ".claude/skills/abrir-dia/SKILL.md" "$w" \
    && intact07 "$folder/.agents/skills/fechar-dia/SKILL.md"; then
    ok "L1 intact 0.7.0 wrapper follows the new description, marker and proof frozen"
  else
    fail "L1 intact 0.7.0 wrapper" "exit $rc, fixture intact: $built"
  fi
  # L1b the rewritten wrapper carries the English body and no longer the
  # Portuguese one of 0.7.0.
  if grep -qF "This skill lives in \`.claude/skills/abrir-dia/SKILL.md\`" "$w" \
    && ! grep -qF "Esta skill mora em" "$w"; then
    ok "L1b rewritten 0.7.0 wrapper has the English body"
  else
    fail "L1b rewritten 0.7.0 wrapper" "body still in Portuguese or missing"
  fi
  rm -rf "$tmp"
fi

# L2 the same 0.7.0 wrapper edited by the person: the source changes, the
# wrapper stays byte for byte, exit 2.
if fresh L2; then
  legacy_build "$folder"
  w="$folder/.agents/skills/abrir-dia/SKILL.md"
  echo "Line added by the person." >> "$w"
  before=$(cksum < "$w")
  sed 's/abrir-dia\./abrir-dia, changed./' "$folder/.claude/skills/abrir-dia/SKILL.md" > "$tmp/new"
  cat "$tmp/new" > "$folder/.claude/skills/abrir-dia/SKILL.md"
  run "$fake"
  if [ "$rc" -eq 2 ] && [ -f "$w" ] && [ ! -L "$w" ] && [ "$(cksum < "$w")" = "$before" ]; then
    ok "L2 0.7.0 wrapper edited by the person stays byte for byte"
  else
    fail "L2 edited 0.7.0 wrapper" "exit $rc, wrapper changed: $(cksum < "$w") against $before"
  fi
  rm -rf "$tmp"
fi
rm -rf "$fake"

# D cases: native discovery in Codex, without a model.
# discovers NAME: runs prompt-input in $folder and looks for "- NAME: SENT".
discovers() {
  (cd "$folder" && codex debug prompt-input 2>/dev/null) | grep -qF -- "- $1: $SENT"
}
if command -v codex >/dev/null 2>&1; then
  if fresh D1; then
    build "$folder"
    run
    if [ "$rc" -eq 0 ] && discovers start-day && discovers close-day \
      && ! (cd "$folder" && codex debug prompt-input 2>/dev/null) | grep -qF -- "- _shared:"; then
      ok "D1 codex discovers the skills through the bridge, without _shared"
    else
      fail "D1 discovery through the bridge" "exit $rc"
    fi
    rm -rf "$tmp"
  fi
  fake=$(mktemp -d 2>/dev/null)
  printf '#!/bin/sh\nexit 1\n' > "$fake/ln"
  chmod +x "$fake/ln"
  if fresh D2; then
    build "$folder"
    run "$fake"
    if [ "$rc" -eq 0 ] && discovers start-day && discovers close-day; then
      ok "D2 codex discovers the skills through the wrappers"
    else
      fail "D2 discovery through the wrappers" "exit $rc"
    fi
    rm -rf "$tmp"
  fi
  rm -rf "$fake"
else
  echo "info  codex not on the PATH: native discovery (D1, D2) not measured on this machine"
fi

[ "$failures" -eq 0 ] || exit 1
exit 0
