#!/bin/sh
# Probes from the audit of the 0.8.1 tidy front (skills and PROMPT, seeds,
# README and manifests). Behavior only, pinned by content.
# Run by hand: sh tests/audit/tidy-081.sh
# plant, connect, setup and the seeds are instructions, so the probes check
# what the agent follows at run time: plant takes the names of the
# capabilities module from the file the folder has, never from the folder's
# age, and its leftover search does not flag those names when they are right;
# the leftover search of setup and plant is one rule, and that rule never
# flags a correct pt-BR adaptation of the vocabulary; the consumer check of
# connect and of close-week finds a consumer under either seed name, with
# the same pairs as the vocabulary; the pastable PROMPT carries the intake
# rules of setup in both languages; and the two manifests carry one version.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
VOC="$ROOT/modules/vocabulary.md"
SETUP="$ROOT/skills/setup/SKILL.md"
PLANT="$ROOT/skills/plant/SKILL.md"
CONNECT="$ROOT/skills/connect/SKILL.md"
WEEK="$ROOT/seeds/close-week/SKILL.md"
P_EN="$ROOT/PROMPT.md"
P_PT="$ROOT/PROMPT.pt-BR.md"
M_CLAUDE="$ROOT/.claude-plugin/plugin.json"
M_CODEX="$ROOT/.codex-plugin/plugin.json"
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

for f in "$VOC" "$SETUP" "$PLANT" "$CONNECT" "$WEEK" "$P_EN" "$P_PT" "$M_CLAUDE" "$M_CODEX"; do
  [ -f "$f" ] || { echo "FAIL  missing $f"; exit 1; }
done

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi

# sentences: one sentence per output line (a period followed by a space and a
# capital letter ends a sentence).
sentences() {
  awk '{ s = $0; while (match(s, /\. [A-Z]/)) { print substr(s, 1, RSTART); s = substr(s, RSTART + 2) } print s }'
}

# seedpairs: "new old" lines of the seed rows of the "Legacy 0.7.0 names" table.
seedpairs() {
  awk -F'|' '
    /^## Legacy 0.7.0 names/ { on = 1; next }
    /^## / { on = 0 }
    on {
      k = $2; gsub(/^ +| +$/, "", k)
      if (k == "seed") { n = $3; o = $4; gsub(/^ *`|` *$/, "", n); gsub(/^ *`|` *$/, "", o); print n " " o }
    }' "$VOC" | sort -u
}
seedpairs > "$work/pairs"
[ "$(wc -l < "$work/pairs" | tr -d ' ')" -ge 6 ] || { echo "FAIL  fewer than 6 seed rows in the vocabulary legacy table"; rm -rf "$work"; exit 1; }

# ---------------------------------------------------------------------------
# TA1 (risk code: plant writes a seed that must find its line in the module)
# In a folder detected as 0.7.0 whose capabilities module is the English
# `_shared/capabilities.md` (connect creates that file when the folder has
# none), the copied seed must keep `today's calendar` and `how to call`, or it
# stops finding its line. So in step 4 of plant every sentence that sends the
# capabilities module names to the legacy 0.7.0 column decides by the file:
# it names both `_shared/capacidades.md` and `_shared/capabilities.md`, and
# says what happens with both; the leftover search does not count those names
# as leftovers in a copy adapted to `_shared/capabilities.md`; and the
# yardstick it cites (connect's "Which file") exists.

grep -m1 '^4\. \*\*Copy\*\*' "$PLANT" | sentences > "$work/copy"
grep -m1 '^ *\*\*Leftover search, after writing:\*\*' "$PLANT" | sentences > "$work/left"
ta1_bad=""
[ -s "$work/copy" ] || ta1_bad="$ta1_bad [plant step 4 not found]"
[ -s "$work/left" ] || ta1_bad="$ta1_bad [plant leftover search not found]"
grep -i -E "capabilit|today's calendar|how to call|calendar section" "$work/copy" | grep -F "legacy 0.7.0 column" > "$work/cap"
if [ ! -s "$work/cap" ]; then
  ta1_bad="$ta1_bad [no sentence sends the capabilities names to the legacy column: an _shared/capacidades.md folder would get English names]"
fi
while IFS= read -r s; do
  case $s in *'`_shared/capacidades.md`'*) ;; *) ta1_bad="$ta1_bad [sentence without _shared/capacidades.md: $(printf '%s' "$s" | cut -c1-80)]" ;; esac
  case $s in *'`_shared/capabilities.md`'*) ;; *) ta1_bad="$ta1_bad [capabilities names go legacy by folder age, not by file: $(printf '%s' "$s" | cut -c1-80)]" ;; esac
done < "$work/cap"
if [ -s "$work/cap" ] && ! grep -q -i -E "with both.*ask|both.*ask" "$work/cap"; then
  ta1_bad="$ta1_bad [no answer for a folder with both modules]"
fi
grep -F '`capabilities.md`' "$work/left" | grep -F '`_shared/capacidades.md`' | grep -q -F '`_shared/capabilities.md`' \
  || ta1_bad="$ta1_bad [leftover search would flag the right English names in a copy adapted to _shared/capabilities.md]"
if grep -q -F '"Which file"' "$work/copy"; then
  grep -q '^## Which file' "$CONNECT" || ta1_bad="$ta1_bad [plant cites connect's \"Which file\", which connect does not have]"
fi
if [ -z "$ta1_bad" ]; then
  ok "TA1 plant names the capabilities module by the file the folder has"
else
  fail "TA1 plant capabilities names" "$ta1_bad"
fi

# ---------------------------------------------------------------------------
# TB1 the leftover search of setup and of plant is one rule (a folder gets
# seeds from both), its boundary is the one its own examples state (an end of
# the name that is a letter or digit is a word boundary, an end that is not
# has none, so `context/` is found in `context/dores.md` and `Context` is not
# found in `Contexto`), and that rule never flags a correct pt-BR adaptation:
# no en name of the person-facing table occurs, under the rule, in its pt-BR
# cell. A pt-BR name that did would make the search "fix" a correct copy.

# clause FILE: the parenthesis after "as a whole word (" in the leftover line.
clause() {
  grep -m1 -F 'Leftover search, after writing' "$1" | awk '{ s = index($0, "as a whole word ("); if (!s) exit; t = substr($0, s + 17); e = index(t, ") or, for a label"); if (e) print substr(t, 1, e - 1) }'
}
c_setup=$(clause "$SETUP")
c_plant=$(clause "$PLANT")
tb1_bad=""
[ -n "$c_setup" ] || tb1_bad="$tb1_bad [setup boundary clause not found]"
[ -n "$c_plant" ] || tb1_bad="$tb1_bad [plant boundary clause not found]"
[ "$c_setup" = "$c_plant" ] || tb1_bad="$tb1_bad [setup and plant state different boundary rules]"
# occurs NEEDLE HAY: exit 0 when NEEDLE occurs in HAY under the rule.
occurs() {
  LC_ALL=C awk -v n="$1" -v h="$2" '
    function word(c) { return c ~ /[A-Za-z0-9]/ || (c != "" && c !~ /[ -~]/) }
    BEGIN {
      first = substr(n, 1, 1); last = substr(n, length(n), 1); s = h; off = 0
      while ((i = index(s, n)) > 0) {
        before = (off + i > 1) ? substr(h, off + i - 1, 1) : ""
        after = substr(h, off + i + length(n), 1)
        if (!(word(first) && word(before)) && !(word(last) && word(after))) exit 0
        off += i; s = substr(h, off + 1)
      }
      exit 1
    }'
}
# the clause's own example: "so `X` is found in `Y`".
ex=$(printf '%s' "$c_plant" | awk '{ s = index($0, "so `"); if (!s) exit; t = substr($0, s + 4); e = index(t, "` is found in `"); if (!e) exit; x = substr(t, 1, e - 1); u = substr(t, e + 15); f = index(u, "`"); if (f) print x "\t" substr(u, 1, f - 1) }')
ex_n=$(printf '%s' "$ex" | cut -f1)
ex_h=$(printf '%s' "$ex" | cut -f2)
if [ -z "$ex_n" ] || [ -z "$ex_h" ]; then
  tb1_bad="$tb1_bad [the boundary clause gives no example of a name found across a non-word end]"
else
  occurs "$ex_n" "$ex_h" || tb1_bad="$tb1_bad [probe rule does not find $ex_n in $ex_h, as the clause says]"
  case $ex_n in *[A-Za-z0-9]) tb1_bad="$tb1_bad [clause example $ex_n ends in a word character]" ;; esac
fi
occurs "Context" "Contexto" && tb1_bad="$tb1_bad [probe rule finds Context in Contexto]"
grep -m1 -F 'Leftover search, after writing' "$PLANT" | grep -q -F '(`Contexto` for `Context`) is not a leftover' \
  || tb1_bad="$tb1_bad [plant no longer says Contexto is not a leftover of Context]"
# every person-facing row: each en fixed piece (the text before the first
# placeholder; in a cell with a placeholder, also the text after the last one;
# only the bold label of a "**X:** ..." cell) that differs from the same
# piece of the pt-BR cell, searched under the rule in the whole pt-BR cell.
awk -F'|' '
  function pieces(v, which,   e) {
    if (v ~ /^\*\*[^*]*:\*\*/) { match(v, /^\*\*[^*]*:\*\*/); v = substr(v, 1, RLENGTH) }
    e = v
    if (which == "end") { if (sub(/^.*([}]|YYYY-MM-DD|DD\/MM)/, "", e)) { sub(/^ +/, "", e); return e } return "" }
    sub(/ *(\{|YYYY|DD\/MM).*$/, "", v); return v
  }
  /^## Person-facing vocabulary/ { on = 1; next }
  /^## / { on = 0 }
  on && /^\| / {
    r = $2; gsub(/^ +| +$/, "", r)
    en = $3; pt = $4; sub(/^ *`/, "", en); sub(/` *$/, "", en); sub(/^ *`/, "", pt); sub(/` *$/, "", pt)
    if (r == "role" || r == "date format in labels" || en ~ /^-+$/ || en == pt) next
    s1 = pieces(en, "start"); s2 = pieces(pt, "start")
    if (s1 != "" && s1 != s2) print r "\t" s1 "\t" pt
    e1 = pieces(en, "end"); e2 = pieces(pt, "end")
    if (e1 != "" && e1 != e2) print r " (end)\t" e1 "\t" pt
  }' "$VOC" > "$work/rows"
[ "$(wc -l < "$work/rows" | tr -d ' ')" -ge 30 ] || tb1_bad="$tb1_bad [person-facing table: $(wc -l < "$work/rows" | tr -d ' ') pieces read, expected 30 or more]"
while IFS="$(printf '\t')" read -r role en pt; do
  occurs "$en" "$pt" && tb1_bad="$tb1_bad [$role: en '$en' is found in the right pt-BR cell '$pt']"
done < "$work/rows"
if [ -z "$tb1_bad" ]; then
  ok "TB1 one boundary rule in setup and plant, and it never flags a correct pt-BR name"
else
  fail "TB1 leftover boundary" "$tb1_bad"
fi

# ---------------------------------------------------------------------------
# TC1 (risk code: the consumer check) close-week runs in the person's folder,
# where the plugin vocabulary with the legacy table does not exist, so the
# seed-name pairs written in its step 6 are the only map it has: they must be
# exactly the six seed rows of the vocabulary, each pair 0.8.0 then 0.7.0.

grep -m1 '^6\. \*\*Memory health\*\*' "$WEEK" > "$work/week6"
tc1_bad=""
[ -s "$work/week6" ] || tc1_bad="$tc1_bad [close-week step 6 not found]"
awk '{ s = index($0, "0.7.0 map of the vocabulary ("); if (!s) exit; t = substr($0, s + 29); e = index(t, ")"); if (e) print substr(t, 1, e - 1) }' "$work/week6" \
  | grep -o '`[^`]*` `[^`]*`' | tr -d '`' | sort -u > "$work/weekpairs"
[ -s "$work/weekpairs" ] || tc1_bad="$tc1_bad [close-week step 6 has no seed-name map]"
if [ -s "$work/weekpairs" ] && ! cmp -s "$work/pairs" "$work/weekpairs"; then
  tc1_bad="$tc1_bad [map differs from the vocabulary: $(diff "$work/pairs" "$work/weekpairs" | grep '^[<>]' | tr '\n' ' ')]"
fi
grep -q -F '`**Carregado por:**`' "$work/week6" || tc1_bad="$tc1_bad [step 6 does not read the 0.7.0 consumer line]"
if [ -z "$tc1_bad" ]; then
  ok "TC1 close-week looks a consumer up under both seed names, with the vocabulary pairs"
else
  fail "TC1 close-week consumer map" "$tc1_bad"
fi

# ---------------------------------------------------------------------------
# TC2 (risk code: the consumer check) connect step 4 looks a declared consumer
# up under its other name in the vocabulary's "Legacy 0.7.0 names" table
# (which must exist, with its seed rows), reads both consumer-line labels of
# the vocabulary, and every "`a` or `b`" pair it writes is a seed row of that
# table, in either order.

grep -m1 '^4\. \*\*Check the consumers\.\*\*' "$CONNECT" > "$work/c4"
tc2_bad=""
[ -s "$work/c4" ] || tc2_bad="$tc2_bad [connect step 4 not found]"
grep -q -F '"Legacy 0.7.0 names"' "$work/c4" || tc2_bad="$tc2_bad [step 4 does not look the other name up in the vocabulary legacy table]"
grep -q '^## Legacy 0.7.0 names' "$VOC" || tc2_bad="$tc2_bad [vocabulary has no \"Legacy 0.7.0 names\" section]"
lab_new=$(awk -F'|' '/^## Legacy 0.7.0 names/ { on = 1 } on && $2 ~ /agent label/ { v = $3; gsub(/^ *`|` *$/, "", v); print v; exit }' "$VOC")
lab_old=$(awk -F'|' '/^## Legacy 0.7.0 names/ { on = 1 } on && $2 ~ /agent label/ { v = $4; gsub(/^ *`|` *$/, "", v); print v; exit }' "$VOC")
[ -n "$lab_new" ] && [ -n "$lab_old" ] || tc2_bad="$tc2_bad [no agent label row in the vocabulary]"
grep -q -F -- "\`$lab_new\`" "$work/c4" || tc2_bad="$tc2_bad [step 4 does not read $lab_new]"
grep -q -F -- "\`$lab_old\`" "$work/c4" || tc2_bad="$tc2_bad [step 4 does not read $lab_old]"
grep -o '`[a-z-]*` or `[a-z-]*`' "$work/c4" | tr -d '`' | sed 's/ or / /' > "$work/cpairs"
[ "$(wc -l < "$work/cpairs" | tr -d ' ')" -ge 3 ] || tc2_bad="$tc2_bad [step 4 names fewer than 3 seed pairs]"
while read -r a b; do
  grep -q -x -F -- "$a $b" "$work/pairs" || grep -q -x -F -- "$b $a" "$work/pairs" \
    || tc2_bad="$tc2_bad [pair $a/$b is no seed row of the vocabulary]"
done < "$work/cpairs"
if [ -z "$tc2_bad" ]; then
  ok "TC2 connect looks a consumer up under its other name in the vocabulary table"
else
  fail "TC2 connect consumer check" "$tc2_bad"
fi

# ---------------------------------------------------------------------------
# TP1 setup changes reach the pastable prompt (repository guide): the three
# intake rules of setup's discovery (the micro-question for a nickname, the
# anchor date of a relative goal, scope kept apart from priority in Block 1)
# are in the discovery section of both PROMPTs, and the AGENTS.md v1 of both
# PROMPTs keeps the formal scope apart from the period's priorities, as
# setup's proposal does. Each row: setup text, PROMPT.md text, PROMPT.pt-BR.md
# text, PROMPT section (d = discovery, p = after the discovery).

# section FILE WHICH: the lines of the discovery (d) or proposal (p) section.
section() {
  awk -v w="$2" '
    /^## (The discovery|O discovery)/ { on = (w == "d"); next }
    /^## (After the discovery|Depois do discovery)/ { on = (w == "p"); next }
    /^## / { on = 0 }
    on' "$1"
}
section "$P_EN" d > "$work/en-d"
section "$P_EN" p > "$work/en-p"
section "$P_PT" d > "$work/pt-d"
section "$P_PT" p > "$work/pt-p"
tp1_bad=""
for f in en-d en-p pt-d pt-p; do
  [ -s "$work/$f" ] || tp1_bad="$tp1_bad [PROMPT section $f not found]"
done
while IFS='|' read -r s e p w; do
  grep -q -F -- "$s" "$SETUP" || { tp1_bad="$tp1_bad [setup no longer has: $s]"; continue; }
  grep -q -F -- "$e" "$work/en-$w" || tp1_bad="$tp1_bad [PROMPT.md misses: $e]"
  grep -q -F -- "$p" "$work/pt-$w" || tp1_bad="$tp1_bad [PROMPT.pt-BR.md misses: $p]"
done <<'EOF'
"who is {nickname}?"|"who is {nickname}?"|"quem é {apelido}?"|d
"counting from when?"|"counting from when?"|"contando a partir de quando?"|d
is not priority (the cut for the period)|is not priority (the cut for the period)|não é prioridade (o recorte do período)|d
formal scope separate from the period's priorities|formal scope separate from the period's priorities|escopo formal separado das prioridades do período|p
EOF
if [ -z "$tp1_bad" ]; then
  ok "TP1 both PROMPTs carry setup's intake rules where the agent applies them"
else
  fail "TP1 PROMPT intake rules" "$tp1_bad"
fi

# ---------------------------------------------------------------------------
# TV1 the two manifests keep the same version (repository guide), so Claude
# Code and Codex install the same release.

v_claude=$(grep -m1 '"version"' "$M_CLAUDE" | sed 's/.*"version" *: *"\([^"]*\)".*/\1/')
v_codex=$(grep -m1 '"version"' "$M_CODEX" | sed 's/.*"version" *: *"\([^"]*\)".*/\1/')
if [ -n "$v_claude" ] && [ "$v_claude" = "$v_codex" ]; then
  ok "TV1 both manifests carry one version"
else
  fail "TV1 manifest versions" "[.claude-plugin '$v_claude', .codex-plugin '$v_codex']"
fi

rm -rf "$work"
[ "$failures" -eq 0 ]
