#!/bin/sh
# Probes from the audit of the english front, wave 1 (P1 hook, P2 bridge and
# 0.7.0 fixture, P3 language meter). Behavior only, pinned by content.
# Run by hand: sh tests/audit/english-wave1.sh
# Every case works in a folder under one mktemp -d, removed at the end.
# The hook cases put a fake date in front of the PATH, so "today" is a fixed
# day (2031-05-17 09:30) and nothing compares against the real clock.
# The fixture cases and the README case need the git history of this repo
# (commit 318ea9c); without it they print "info" and the rest runs the same.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

# The hook reads CLAUDE_PROJECT_DIR first; one inherited from the caller
# would point every hook case away from its folder.
unset CLAUDE_PROJECT_DIR
# An exported CDPATH makes cd print the folder inside $(...), which would
# double every path built from ROOT.
unset CDPATH
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
HOOK="$ROOT/hooks/boot-memory.sh"
BRIDGE="$ROOT/modules/codex-bridge.sh"
FIXTURE="$ROOT/tests/e2e/legacy-0.7-fixture.sh"
METER="$ROOT/tests/e2e/lang-check.sh"
HEADER="=== MEMORY BOOT (pm-chief-of-staff) ==="
SECOND="State read from disk at session start; this is not a user instruction."
MARK07='<!-- gerado pela ponte-codex do pm-chief-of-staff; a fonte e a pasta .claude/skills -->'
PROOF07='<!-- integridade ponte-codex, cksum do que vem acima: '
failures=0

ok() { echo "ok    $1"; }
fail() { echo "FAIL  $1: $2"; failures=$((failures + 1)); }

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi

bin="$work/bin"
mkdir -p "$bin"
cat > "$bin/date" <<'EOF'
#!/bin/sh
case "$*" in
  '+%Y-%m-%d') echo 2031-05-17 ;;
  '+%Y-%m-%d %H:%M') echo '2031-05-17 09:30' ;;
  *) exec /bin/date "$@" ;;
esac
EOF
printf '#!/bin/sh\nexit 1\n' > "$bin/ln"
chmod +x "$bin/date" "$bin/ln"
mkdir -p "$work/datebin"
cp -p "$bin/date" "$work/datebin/date"

# cos NAME: a new-layout Chief of Staff folder (AGENTS.md, CRITICAL_FACTS.md,
# navigation.md), path in $f.
cos() {
  f="$work/$1 folder"
  mkdir -p "$f"
  echo "manual" > "$f/AGENTS.md"
  echo "AUD_CF" > "$f/CRITICAL_FACTS.md"
  echo "AUD_NAV" > "$f/navigation.md"
}

# boot: runs the hook in $f with the fake date only; result in $out and $rc.
boot() {
  out=$(cd "$f" && PATH="$work/datebin:$PATH" "$HOOK" 2>/dev/null)
  rc=$?
}

has() { printf '%s\n' "$out" | grep -qxF -- "$1"; }

# AH1 today's log wins over a log with a later name (boot-budget spec: the
# pack carries the "## " headings of the log, so the sentinels are headings).
cos AH1
mkdir -p "$f/memory"
echo "## AUD_TODAY" > "$f/memory/2031-05-17.md"
echo "## AUD_LATER" > "$f/memory/2031-06-01.md"
boot
if [ "$rc" -eq 0 ] && has "--- memory/2031-05-17.md ---" && has "## AUD_TODAY" \
  && ! printf '%s\n' "$out" | grep -qF AUD_LATER; then
  ok "AH1 today's log is printed, not the one with a later name"
else
  fail "AH1 today's log" "exit $rc"
fi

# AH2 without today's log, the latest dated log by name, and only it (the
# sentinels are headings, as in AH1).
cos AH2
mkdir -p "$f/memory"
echo "## AUD_OLD" > "$f/memory/2026-01-02.md"
echo "## AUD_LATEST" > "$f/memory/2026-10-28.md"
echo "## AUD_NOTES" > "$f/memory/notes.md"
boot
if [ "$rc" -eq 0 ] && has "--- memory/2026-10-28.md ---" && has "## AUD_LATEST" \
  && ! printf '%s\n' "$out" | grep -qF AUD_OLD && ! printf '%s\n' "$out" | grep -qF AUD_NOTES; then
  ok "AH2 fallback prints only the latest dated log"
else
  fail "AH2 fallback to the latest log" "exit $rc"
fi

# AH3 no memory folder: full boot, header and second line, the time line on
# line 3 (boot-budget spec: it moved from the last line to line 3).
cos AH3
boot
first=$(printf '%s\n' "$out" | sed -n 1p)
second=$(printf '%s\n' "$out" | sed -n 2p)
third=$(printf '%s\n' "$out" | sed -n 3p)
if [ "$rc" -eq 0 ] && [ "$first" = "$HEADER" ] && [ "$second" = "$SECOND" ] \
  && [ "$third" = "time now: 2031-05-17 09:30" ] && has AUD_CF && has AUD_NAV \
  && ! printf '%s\n' "$out" | grep -q '^--- memory/'; then
  ok "AH3 boot without memory/: header, second line, time line on line 3"
else
  fail "AH3 boot without memory/" "exit $rc, lines: $first / $second / $third"
fi

# AH4 size limit (boot-budget spec: the 32768-byte rule per file became a
# cut at whole lines with a footer): a CRITICAL_FACTS.md of 40008 bytes and a
# navigation.md of exactly 32768 both give their first line, only whole
# lines, a footer line naming what is left out of each, and a pack of at
# most 8000 bytes.
cos AH4
awk 'BEGIN { print "AUD_BIG"; for (i = 0; i < 4000; i++) print "xxxxxxxxx" }' > "$f/CRITICAL_FACTS.md"
awk 'BEGIN { print "AUD_EDGE"; for (i = 0; i < 4094; i++) print "xxxxxxx"; printf "xxxxxxx" }' > "$f/navigation.md"
size_cf=$(wc -c < "$f/CRITICAL_FACTS.md" | tr -d ' ')
size_nav=$(wc -c < "$f/navigation.md" | tr -d ' ')
boot
size_out=$(printf '%s\n' "$out" | wc -c | tr -d ' ')
partial=$(printf '%s\n' "$out" | grep -c '^x\{1,6\}$\|^x\{8\}$\|^x\{10,\}$')
if [ "$size_cf" -eq 40008 ] && [ "$size_nav" -eq 32768 ] && [ "$rc" -eq 0 ] \
  && [ "$size_out" -le 8000 ] && [ "$partial" -eq 0 ] \
  && has "--- CRITICAL_FACTS.md ---" && has AUD_BIG && has xxxxxxxxx \
  && printf '%s\n' "$out" | grep -Eqx 'CRITICAL_FACTS\.md: lines [0-9]+ to 4001 of 4001 are not shown\.' \
  && has "--- navigation.md ---" && has AUD_EDGE && has xxxxxxx \
  && printf '%s\n' "$out" | grep -Eqx 'navigation\.md: lines [0-9]+ to 4096 of 4096 are not shown\.' \
  && ! printf '%s\n' "$out" | grep -qi 'read it from disk'; then
  ok "AH4 files above the budget are cut at whole lines, with a footer"
else
  fail "AH4 size limit" "exit $rc, sizes $size_cf and $size_nav, pack $size_out bytes, $partial partial lines"
fi

# AH5 the gate reads the navigation file by name: AGENTS.md and
# CRITICAL_FACTS.md with a folder named navigation.md stay silent.
f="$work/AH5 folder"
mkdir -p "$f/navigation.md"
echo "manual" > "$f/AGENTS.md"
echo "AUD_CF" > "$f/CRITICAL_FACTS.md"
boot
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
  ok "AH5 a folder named navigation.md is not a navigation file"
else
  fail "AH5 navigation.md as a folder" "exit $rc"
fi

# runb FOLDER: runs the bridge with links unavailable; exit in $rc.
runb() {
  (cd "$1" && PATH="$bin:$PATH" sh "$BRIDGE" >/dev/null 2>&1)
  rc=$?
}

# intact07 FILE: regular file, the frozen marker line, and a last line that is
# the frozen proof matching everything above it.
intact07() {
  [ -f "$1" ] && [ ! -L "$1" ] && grep -qxF "$MARK07" "$1" || return 1
  i07_last=$(tail -n 1 "$1")
  case "$i07_last" in "$PROOF07"*" -->") ;; *) return 1 ;; esac
  i07_sum=${i07_last#"$PROOF07"}
  i07_sum=${i07_sum%" -->"}
  [ -n "$i07_sum" ] && [ "$(sed '$d' "$1" | cksum)" = "$i07_sum" ]
}

# wrap07 FOLDER NAME: the wrapper the 0.7.0 bridge wrote for NAME, built from
# the source frontmatter with the 0.7.0 body and proof.
wrap07() {
  mkdir -p "$1/.agents/skills/$2"
  fm=$(awk 'NR == 1 { next } /^---$/ { exit } { print }' "$1/.claude/skills/$2/SKILL.md")
  b=$(printf -- '---\n%s\n---\n%s\n\n%s' "$fm" "$MARK07" "Esta skill mora em \`.claude/skills/$2/SKILL.md\`, a fonte desta pasta. Leia esse arquivo inteiro e siga o que ele diz; caminho relativo citado nele parte da pasta dele. Edição vai sempre na fonte: a próxima rodada da ponte atualiza o frontmatter aqui.")
  printf '%s\n%s%s -->\n' "$b" "$PROOF07" "$(printf '%s\n' "$b" | cksum)" > "$1/.agents/skills/$2/SKILL.md"
}

# src FOLDER NAME DESCRIPTION: a source skill with a frontmatter.
src() {
  mkdir -p "$1/.claude/skills/$2"
  printf -- '---\nname: %s\ndescription: %s\n---\n\n# %s\n' "$2" "$3" "$2" > "$1/.claude/skills/$2/SKILL.md"
}

# AB1 a file with a matching proof but without the marker line is the
# person's: conflict, byte for byte the same.
f="$work/AB1 folder"
src "$f" start-day "AUD start."
mkdir -p "$f/.agents/skills/start-day"
b=$(printf -- '---\nname: start-day\ndescription: my own.\n---\n\nmy own notes')
printf '%s\n%s%s -->\n' "$b" "$PROOF07" "$(printf '%s\n' "$b" | cksum)" > "$f/.agents/skills/start-day/SKILL.md"
before=$(cksum < "$f/.agents/skills/start-day/SKILL.md")
runb "$f"
if [ "$rc" -eq 2 ] && [ "$(cksum < "$f/.agents/skills/start-day/SKILL.md")" = "$before" ]; then
  ok "AB1 matching proof without the marker stays as the person's"
else
  fail "AB1 proof without the marker" "exit $rc"
fi

# AB2 one intact and one edited 0.7.0 wrapper in the same folder, sources
# changed: the intact one is upgraded to the English body, the edited one
# stays, exit 2; a second run leaves both byte for byte.
f="$work/AB2 folder"
src "$f" abrir-dia "AUD abrir."
src "$f" fechar-dia "AUD fechar."
wrap07 "$f" abrir-dia
wrap07 "$f" fechar-dia
echo "Linha da pessoa." >> "$f/.agents/skills/fechar-dia/SKILL.md"
edited=$(cksum < "$f/.agents/skills/fechar-dia/SKILL.md")
src "$f" abrir-dia "AUD abrir, changed."
src "$f" fechar-dia "AUD fechar, changed."
runb "$f"
rc1=$rc
w="$f/.agents/skills/abrir-dia/SKILL.md"
up=$(cksum < "$w")
runb "$f"
if [ "$rc1" -eq 2 ] && [ "$rc" -eq 2 ] && intact07 "$w" \
  && grep -qxF "description: AUD abrir, changed." "$w" \
  && grep -qF "This skill lives in \`.claude/skills/abrir-dia/SKILL.md\`" "$w" \
  && ! grep -qF "Esta skill mora em" "$w" \
  && [ "$(cksum < "$w")" = "$up" ] \
  && [ "$(cksum < "$f/.agents/skills/fechar-dia/SKILL.md")" = "$edited" ]; then
  ok "AB2 intact 0.7.0 wrapper upgraded next to an edited one, both stable"
else
  fail "AB2 mixed 0.7.0 wrappers" "exit $rc1 then $rc"
fi

# AB3 the source lost its frontmatter: the intact 0.7.0 wrapper stays byte
# for byte and the run reports an error, exit 1.
f="$work/AB3 folder"
src "$f" abrir-dia "AUD abrir."
wrap07 "$f" abrir-dia
before=$(cksum < "$f/.agents/skills/abrir-dia/SKILL.md")
printf '# abrir-dia\n\nno frontmatter\n' > "$f/.claude/skills/abrir-dia/SKILL.md"
runb "$f"
if [ "$rc" -eq 1 ] && [ "$(cksum < "$f/.agents/skills/abrir-dia/SKILL.md")" = "$before" ] \
  && [ "$(ls -A "$f/.agents/skills/abrir-dia" | wc -l | tr -d ' ')" -eq 1 ]; then
  ok "AB3 source without frontmatter keeps the 0.7.0 wrapper, exit 1"
else
  fail "AB3 source without frontmatter" "exit $rc"
fi

# AB4 the temporary path of this run is already a link to a file outside the
# folder (the bridge keeps its PID through exec, so the name is known): the
# write is refused, the outside file and the wrapper stay, exit 1.
f="$work/AB4 folder"
src "$f" start-day "AUD start."
runb "$f"
w="$f/.agents/skills/start-day/SKILL.md"
echo "outside, the person's" > "$work/AB4 outside.md"
before=$(cksum < "$w")
src "$f" start-day "AUD start, changed."
(cd "$f" && PATH="$bin:$PATH" sh -c '/bin/ln -s "$1" ".agents/skills/start-day/.SKILL.md.ponte.$$"; exec sh "$2"' probe "$work/AB4 outside.md" "$BRIDGE" >/dev/null 2>&1)
rc=$?
if [ "$rc" -eq 1 ] && [ "$(cat "$work/AB4 outside.md")" = "outside, the person's" ] \
  && [ "$(cksum < "$w")" = "$before" ]; then
  ok "AB4 a link at the temporary path is not written through"
else
  fail "AB4 link at the temporary path" "exit $rc, outside: $(cat "$work/AB4 outside.md")"
fi

# Fixture cases: need the 0.7.0 commit.
if git -C "$ROOT" cat-file -e 318ea9c^{commit} 2>/dev/null; then
  # AF1 an existing folder or a dangling link is refused, nothing written.
  f="$work/AF1 folder"
  mkdir -p "$f"
  echo "the person's" > "$f/note.md"
  before=$(ls -lAR "$f" | cksum)
  sh "$FIXTURE" "$f" link >/dev/null 2>&1
  rc1=$?
  ln -s "$work/AF1 nowhere" "$work/AF1 dangling"
  sh "$FIXTURE" "$work/AF1 dangling" wrappers >/dev/null 2>&1
  rc2=$?
  if [ "$rc1" -eq 1 ] && [ "$(ls -lAR "$f" | cksum)" = "$before" ] \
    && [ "$rc2" -eq 1 ] && [ ! -e "$work/AF1 nowhere" ]; then
    ok "AF1 fixture refuses an existing folder and a dangling link"
  else
    fail "AF1 fixture refusal" "exit $rc1 and $rc2"
  fi

  # count07 FOLDER TEXT SEED...: how many SEEDs have an intact wrapper in
  # FOLDER whose body holds TEXT; result in $n.
  count07() {
    c7_dir=$1
    c7_text=$2
    shift 2
    n=0
    for s in "$@"; do
      intact07 "$c7_dir/.agents/skills/$s/SKILL.md" && grep -qF "$c7_text" "$c7_dir/.agents/skills/$s/SKILL.md" && n=$((n + 1))
    done
  }
  FIVE07="abrir-dia absorver fechar-dia preparar-conversa processar-reuniao"

  # AF2 default build, as the 0.7.0 setup plants it: the five seeds, no
  # fechar-semana. Wrappers mode: five 0.7.0 wrappers, which the new bridge
  # upgrades to the English body with exit 0; link mode: the new bridge keeps
  # the link.
  fw="$work/AF2 wrappers"
  fl="$work/AF2 link"
  sh "$FIXTURE" "$fw" wrappers >/dev/null 2>&1
  rcw=$?
  sh "$FIXTURE" "$fl" link >/dev/null 2>&1
  rcl=$?
  # shellcheck disable=SC2086
  count07 "$fw" "Esta skill mora em" $FIVE07
  n07=$n
  (cd "$fw" && sh "$BRIDGE" >/dev/null 2>&1)
  rcb=$?
  # shellcheck disable=SC2086
  count07 "$fw" "This skill lives in" $FIVE07
  nen=$n
  (cd "$fl" && sh "$BRIDGE" >/dev/null 2>&1)
  rclb=$?
  if [ "$rcw" -eq 0 ] && [ "$rcl" -eq 0 ] && [ "$n07" -eq 5 ] && [ "$rcb" -eq 0 ] && [ "$nen" -eq 5 ] \
    && [ ! -e "$fw/.claude/skills/fechar-semana" ] && [ ! -e "$fw/.agents/skills/fechar-semana" ] \
    && [ ! -e "$fl/.claude/skills/fechar-semana" ] \
    && [ ! -e "$fw/.fixture-bin" ] && [ "$rclb" -eq 0 ] \
    && [ "$(readlink "$fl/.agents/skills")" = "../.claude/skills" ]; then
    ok "AF2 default fixture has the five 0.7.0 seeds, upgraded by the new bridge, link kept"
  else
    fail "AF2 fixture and new bridge" "fixture $rcw/$rcl, 0.7.0 wrappers $n07, bridge $rcb/$rclb, English $nen"
  fi

  # AF5 with-fechar-semana adds the sixth seed, as a folder that ran
  # "plantar fechar-semana": six 0.7.0 wrappers, all six upgraded by the new
  # bridge with exit 0; link mode carries the sixth source too. A third
  # argument other than with-fechar-semana exits 64 and writes nothing.
  fw5="$work/AF5 wrappers"
  fl5="$work/AF5 link"
  sh "$FIXTURE" "$fw5" wrappers with-fechar-semana >/dev/null 2>&1
  rcw=$?
  sh "$FIXTURE" "$fl5" link with-fechar-semana >/dev/null 2>&1
  rcl=$?
  # shellcheck disable=SC2086
  count07 "$fw5" "Esta skill mora em" $FIVE07 fechar-semana
  n07=$n
  (cd "$fw5" 2>/dev/null && sh "$BRIDGE" >/dev/null 2>&1)
  rcb=$?
  # shellcheck disable=SC2086
  count07 "$fw5" "This skill lives in" $FIVE07 fechar-semana
  nen=$n
  sh "$FIXTURE" "$work/AF5 bad" wrappers fechar-semana >/dev/null 2>&1
  rcu=$?
  if [ "$rcw" -eq 0 ] && [ "$rcl" -eq 0 ] && [ "$n07" -eq 6 ] && [ "$rcb" -eq 0 ] && [ "$nen" -eq 6 ] \
    && [ -f "$fl5/.claude/skills/fechar-semana/SKILL.md" ] \
    && [ "$(readlink "$fl5/.agents/skills")" = "../.claude/skills" ] \
    && [ ! -e "$fw5/.fixture-bin" ] \
    && [ "$rcu" -eq 64 ] && [ ! -e "$work/AF5 bad" ]; then
    ok "AF5 with-fechar-semana adds the sixth seed, all six upgraded"
  else
    fail "AF5 fixture with-fechar-semana" "fixture $rcw/$rcl, 0.7.0 wrappers $n07, bridge $rcb, English $nen, bad usage $rcu"
  fi

  # AF3 the new hook boots on the 0.7.0 fixture: header, the facts, the
  # legacy navegacao.md and the heading of the latest log, whose body stays
  # on disk (boot-budget spec).
  f="$fl"
  boot
  if [ "$rc" -eq 0 ] && [ "$(printf '%s\n' "$out" | sed -n 1p)" = "$HEADER" ] \
    && printf '%s\n' "$out" | grep -qF COS07_CRITICAL_FACTS \
    && has "--- navegacao.md ---" && printf '%s\n' "$out" | grep -qF COS07_NAVEGACAO \
    && has "--- memory/2026-10-28.md ---" && has "## [18:40] Fechamento do dia" \
    && ! printf '%s\n' "$out" | grep -qF COS07_MEMORY; then
    ok "AF3 new hook boots on the 0.7.0 fixture"
  else
    fail "AF3 new hook on the fixture" "exit $rc"
  fi

  # AF4 two builds in new folders give the same files with the same content.
  fa="$work/AF4 a"
  fb="$work/AF4 b"
  sh "$FIXTURE" "$fa" wrappers >/dev/null 2>&1
  sh "$FIXTURE" "$fb" wrappers >/dev/null 2>&1
  la=$(cd "$fa" && find . -type f | LC_ALL=C sort | while read -r p; do printf '%s %s\n' "$p" "$(cksum < "$p")"; done)
  lb=$(cd "$fb" && find . -type f | LC_ALL=C sort | while read -r p; do printf '%s %s\n' "$p" "$(cksum < "$p")"; done)
  nf=$(printf '%s\n' "$la" | grep -c .)
  if [ -n "$la" ] && [ "$la" = "$lb" ] && [ "$nf" -ge 20 ]; then
    ok "AF4 two fixture builds are identical ($nf files)"
  else
    fail "AF4 fixture determinism" "files $nf"
  fi

  # AF6 (reaudit 1) wrong usage around the optional third argument exits 64
  # and creates nothing: four arguments, an empty third one, the option in
  # the mode slot, and the option in another case.
  sh "$FIXTURE" "$work/AF6 a" wrappers with-fechar-semana extra >/dev/null 2>&1
  u1=$?
  sh "$FIXTURE" "$work/AF6 b" wrappers "" >/dev/null 2>&1
  u2=$?
  sh "$FIXTURE" "$work/AF6 c" with-fechar-semana wrappers >/dev/null 2>&1
  u3=$?
  sh "$FIXTURE" "$work/AF6 d" link WITH-FECHAR-SEMANA >/dev/null 2>&1
  u4=$?
  if [ "$u1$u2$u3$u4" = 64646464 ] && [ ! -e "$work/AF6 a" ] && [ ! -e "$work/AF6 b" ] \
    && [ ! -e "$work/AF6 c" ] && [ ! -e "$work/AF6 d" ]; then
    ok "AF6 fixture wrong usage with the third argument exits 64, writes nothing"
  else
    fail "AF6 fixture wrong usage" "exits $u1 $u2 $u3 $u4"
  fi
else
  echo "info  no 318ea9c in the git history: AF1 to AF6 not measured"
fi

# meter TEXT_FILE LANG: runs the meter; line in $mout, exit in $rc.
meter() {
  mout=$(sh "$METER" "$1" "$2" 2>/dev/null)
  rc=$?
}
# words WORD N: N copies of WORD, one per line.
words() { awk -v w="$1" -v n="$2" 'BEGIN { for (i = 0; i < n; i++) print w }'; }

# AL1 thresholds of the common spec, on both sides of each edge.
m="$work/meter"
mkdir -p "$m"
words the 15 > "$m/en15"
words the 14 > "$m/en14"
{ words the 15; echo "não"; } > "$m/en15pt1"
{ words para 15; words the 2; } > "$m/pt15en2"
{ words para 15; words the 3; } > "$m/pt15en3"
{ words para 14; } > "$m/pt14"
r=""
meter "$m/en15" en; r="$r$rc:$mout;"
meter "$m/en14" en; r="$r$rc:$mout;"
meter "$m/en15pt1" en; r="$r$rc:$mout;"
meter "$m/pt15en2" pt; r="$r$rc:$mout;"
meter "$m/pt15en3" pt; r="$r$rc:$mout;"
meter "$m/pt14" pt; r="$r$rc:$mout;"
want="0:en ok en=15 pt=0;1:en FALHA en=14 pt=0;1:en FALHA en=15 pt=1;0:pt ok en=2 pt=15;1:pt FALHA en=3 pt=15;1:pt FALHA en=0 pt=14;"
if [ "$r" = "$want" ]; then
  ok "AL1 meter thresholds on both sides of each edge"
else
  fail "AL1 meter thresholds" "$r"
fi

# AL2 whole words in UTF-8: "força" is not "for", an uppercase "NÃO" counts.
{ words para 15; words "força" 3; } > "$m/forca"
{ words the 15; echo "NÃO"; } > "$m/upper"
meter "$m/forca" pt
r1="$rc:$mout"
meter "$m/upper" en
r2="$rc:$mout"
if [ "$r1" = "0:pt ok en=0 pt=15" ] && [ "$r2" = "1:en FALHA en=15 pt=1" ]; then
  ok "AL2 meter counts whole words with accents"
else
  fail "AL2 meter whole words" "$r1 / $r2"
fi

# AL5 real prose has many words per line, and a word that only contains a
# listed word ("list" holds "is") must not hide the listed words after it on
# the same line: an English line inside a Portuguese text is counted whole,
# so the pt verdict fails.
printf 'This is the plan and the list for the team, with this the end.\n' > "$m/line"
{ words para 15; echo "Welcome to the setup, this is the list and the plan for you and the team with the rest."; } > "$m/mixed"
meter "$m/line" en
r1="$mout"
meter "$m/mixed" pt
r2="$rc:$mout"
if [ "$r1" = "en FALHA en=8 pt=0" ] && [ "$r2" = "1:pt FALHA en=11 pt=15" ]; then
  ok "AL5 meter counts every listed word on a line"
else
  fail "AL5 meter on one line of prose" "$r1 / $r2"
fi

# AL6 (reaudit 1) word boundaries in prose after the word-by-word split: a
# word is a run of letters, digits and underscores, as with grep -w. Listed
# words next to punctuation, an apostrophe, a hyphen, a slash or a CR count;
# a listed word glued to a letter, a digit or an underscore does not; case
# folds for accented capitals. Expected counts agree with a perl \w oracle.
{
  printf '%s\n' 'the the,the.the;the' \
    'theme island isle forum list' \
    'força paraíso parada compara comunidade com' \
    "you're the one, it's for you" \
    'is2 the1 the_ _the the-end para-raio' \
    'NÃO VoCê EsTá PESSOA uma'
  printf 'the and\r\n'
  printf '%s\n' 'https://example.com/the'
} > "$m/bounds"
meter "$m/bounds" en
if [ "$mout" = "en FALHA en=13 pt=8" ]; then
  ok "AL6 meter word boundaries in prose"
else
  fail "AL6 meter word boundaries" "$mout"
fi

# AL3 usage errors exit 2: no arguments, a bad language, a missing file.
sh "$METER" >/dev/null 2>&1
u1=$?
sh "$METER" "$m/en15" fr >/dev/null 2>&1
u2=$?
sh "$METER" "$m/does-not-exist" en >/dev/null 2>&1
u3=$?
if [ "$u1" -eq 2 ] && [ "$u2" -eq 2 ] && [ "$u3" -eq 2 ]; then
  ok "AL3 meter usage errors exit 2"
else
  fail "AL3 meter usage errors" "exits $u1 $u2 $u3"
fi

# AL4 real texts: the 0.7.0 README is pt and not en; the new write gate is en
# and not pt.
meter "$ROOT/modules/write-gate.md" en
g1=$rc
meter "$ROOT/modules/write-gate.md" pt
g2=$rc
if git -C "$ROOT" show 318ea9c:README.md > "$m/readme07" 2>/dev/null; then
  meter "$m/readme07" pt
  g3=$rc
  meter "$m/readme07" en
  g4=$rc
else
  g3=0
  g4=1
  echo "info  no 318ea9c in the git history: the README half of AL4 not measured"
fi
if [ "$g1" -eq 0 ] && [ "$g2" -eq 1 ] && [ "$g3" -eq 0 ] && [ "$g4" -eq 1 ]; then
  ok "AL4 meter on the write gate and the 0.7.0 README"
else
  fail "AL4 meter on real texts" "write gate en $g1 pt $g2, README pt $g3 en $g4"
fi

rm -rf "$work"
[ "$failures" -eq 0 ] || exit 1
exit 0
