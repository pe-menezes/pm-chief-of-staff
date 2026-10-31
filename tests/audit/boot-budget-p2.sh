#!/bin/sh
# Probe from the audit of the boot-budget front, part 2 (documentation).
# Behavior only, pinned by content.
# Run by hand: sh tests/audit/boot-budget-p2.sh
# The README promises that hooks/boot-memory.sh "writes nothing and sends
# nothing anywhere"; no other test checks the folder after a run.
# Cases:
# W1 every exit path of the hook (a full pack with every section cut, the
#    same with the codex marker, a pack where nothing is cut, the handoff
#    line to a live engine and the one-line internal failure) leaves the
#    person's folder and HOME exactly as they were: the same paths, files
#    and folders, hidden ones included, with the same content.
# A fake date in front of the PATH makes "today" 2031-05-17 09:30 for the
# hook, and the probe names the same day for its own files, so the day
# cannot turn between them. The internal failure comes from a fake awk that
# exits 3, which no privilege can read past.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

# An exported CDPATH makes cd print the folder inside $(...), which would
# double every path built from ROOT.
unset CDPATH
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
HOOK="$ROOT/hooks/boot-memory.sh"
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi
work=$(cd "$work" && pwd)

# A fake uname names the host "audithost", so the engine's proof of life
# lives in a known folder. The fake date answers DAY for the day, so the
# hook's today and the probe's log name are one value.
DAY=2031-05-17
fakes="$work/fakes"
mkdir -p "$fakes"
printf '#!/bin/sh\necho audithost\n' > "$fakes/uname"
cat > "$fakes/date" <<'EOF'
#!/bin/sh
case "$*" in
  '+%Y-%m-%d') echo 2031-05-17 ;;
  '+%Y-%m-%d %H:%M') echo '2031-05-17 09:30' ;;
  *) exec /bin/date "$@" ;;
esac
EOF
chmod +x "$fakes/uname" "$fakes/date"
# The broken case runs with the same fakes plus an awk that exits 3, as B10
# of hooks/boot-memory-test.sh: the hook's internal failure path.
fakes_broken="$work/fakes broken"
mkdir -p "$fakes_broken"
cp "$fakes/uname" "$fakes/date" "$fakes_broken/"
printf '#!/bin/sh\nexit 3\n' > "$fakes_broken/awk"
chmod +x "$fakes_broken/awk"

# snapshot DIR: every path under DIR (type and name) and the checksum of
# every file, sorted.
snapshot() {
  (cd "$1" && find . -print | LC_ALL=C sort | while IFS= read -r p; do
    if [ -f "$p" ] && [ ! -r "$p" ]; then printf 'f unreadable %s\n' "$p"
    elif [ -f "$p" ]; then printf 'f %s %s\n' "$(cksum < "$p" | tr -s ' ' | cut -d' ' -f1,2)" "$p"
    elif [ -d "$p" ]; then printf 'd %s\n' "$p"
    else printf 'o %s\n' "$p"; fi
  done)
}

# new_cos DIR: a Chief of Staff folder with today's log.
new_cos() {
  mkdir -p "$1/memory"
  echo "fact W1" > "$1/CRITICAL_FACTS.md"
  echo "nav W1" > "$1/navigation.md"
  echo "manual W1" > "$1/AGENTS.md"
  echo "@AGENTS.md" > "$1/CLAUDE.md"
  printf '## [09:00] W1 topic\nbody\n' > "$1/memory/$DAY.md"
}

home="$work/home"
mkdir -p "$home"

# Case folders. "big": every section over its cap. "small": no log and
# nothing cut.
# "engine": a live engine, handoff. "broken": a whole folder, run with the
# failing awk.
big="$work/big cos"
new_cos "$big"
i=1; while [ $i -le 120 ]; do printf 'fact line %03d of the W1 probe, long enough to fill\n' $i; i=$((i + 1)); done > "$big/CRITICAL_FACTS.md"
i=1; while [ $i -le 200 ]; do printf 'nav line %03d of the W1 probe, long enough to fill\n' $i; i=$((i + 1)); done > "$big/navigation.md"
i=1; while [ $i -le 80 ]; do printf '## [10:%02d] W1 topic %02d\nbody %02d\n' $((i % 60)) $i $i; i=$((i + 1)); done > "$big/memory/$DAY.md"
small="$work/small cos"
new_cos "$small"
rm -f "$small/memory/$DAY.md"
engine="$work/engine cos"
new_cos "$engine"
mkdir -p "$engine/.claude/data/sensor-efeito/audithost"
echo '{}' > "$engine/.claude/memoria-config.json"
echo '{}' > "$engine/.claude/data/sensor-efeito/audithost/events.jsonl"
broken="$work/broken cos"
new_cos "$broken"

why=""
for spec in "big|claude|^=== MEMORY BOOT" "big|codex|^=== MEMORY BOOT" "small|claude|^Nothing is left out" \
  "engine|claude|^memoria-agente present" "broken|claude|^Memory boot pack not assembled"; do
  name=${spec%%|*}; rest=${spec#*|}; rt=${rest%%|*}; want=${rest#*|}
  eval "dir=\$$name"
  fb=$fakes
  [ "$name" = broken ] && fb=$fakes_broken
  before=$(snapshot "$dir")
  hbefore=$(snapshot "$home")
  if [ "$rt" = codex ]; then
    out=$(cd "$dir" && unset CLAUDE_PROJECT_DIR && HOME="$home" PATH="$fb:$PATH" "$HOOK" codex 2>/dev/null)
  else
    out=$(cd "$dir" && unset CLAUDE_PROJECT_DIR && HOME="$home" PATH="$fb:$PATH" "$HOOK" 2>/dev/null)
  fi
  rc=$?
  after=$(snapshot "$dir")
  hafter=$(snapshot "$home")
  if [ "$rc" -ne 0 ]; then why="$why [$name $rt: exit $rc]"
  elif ! printf '%s\n' "$out" | grep -Eq "$want"; then why="$why [$name $rt: not the expected exit path]"
  elif [ "$before" != "$after" ]; then why="$why [$name $rt: folder changed]"
  elif [ "$hbefore" != "$hafter" ]; then why="$why [$name $rt: HOME changed]"
  fi
done

if [ -z "$why" ]; then
  ok "W1 every exit path leaves the folder and HOME exactly as they were"
else
  fail "W1 the hook writes nothing" "$why"
fi

rm -rf "$work"
[ "$failures" -eq 0 ]
