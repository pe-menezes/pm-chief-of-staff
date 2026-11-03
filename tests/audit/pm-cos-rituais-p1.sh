#!/bin/sh
# Probes from the audit of the optional-routines front, part 1 (the day and
# week routines picked at setup, curation at write time). Behavior only,
# pinned by content.
# Run by hand: sh tests/audit/pm-cos-rituais-p1.sh
# setup, the seeds and the PROMPTs are instructions, so the probes check the
# contracts between files that the agent follows at run time:
#   RD1 both READMEs promise the same plant as setup: their "always" table is
#       setup's always-planted list and their routine table is setup's offered
#       list;
#   RC1 close-day offers to close the week only when close-week (or its 0.7.0
#       name) is planted, and never pushes the plant of a routine the person
#       did not pick;
#   RN1 (risk code: the consumer check) close-week step 6 and connect step 4
#       keep a declared seed with no folder silent ("not planted") only when
#       the name is one of the catalog seeds, and still call any other name a
#       missing consumer; the judge is checked against mutated copies so it
#       is never vacuous;
#   RS1 (risk code: what setup plants) setup offers the plant command for any
#       routine not picked and never agrees on the later plant of one routine
#       by name (the 0.12.0 close-week agreement);
#   RX1 (risk code: date boundary) the expiry of a dated prospective item is
#       taught with the folder's expired mark and only for a written date that
#       has passed, in setup's write rules, both PROMPTs and close-week;
#   RW1 (risk code: date boundary) the new week's journal is created in the
#       vocabulary's journal folder with no task migrated, and start-day's
#       backlog scan reads that whole folder, which is what makes skipping the
#       migration safe;
#   RL1 the ceilings a writer measures are the same numbers in the write gate,
#       setup, both PROMPTs and close-week, and the manual's write rule names
#       the module path setup plants;
#   RG1 the size gate message with both files over their caps stays within
#       2000 bytes, names no day or week routine, and keeps both targets.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

# An exported CDPATH makes cd print the folder inside $(...), which would
# double every path built from ROOT.
unset CDPATH
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
VOC="$ROOT/modules/vocabulary.md"
SETUP="$ROOT/skills/setup/SKILL.md"
CONNECT="$ROOT/skills/connect/SKILL.md"
DAY="$ROOT/seeds/close-day/SKILL.md"
WEEK="$ROOT/seeds/close-week/SKILL.md"
START="$ROOT/seeds/start-day/SKILL.md"
GATE="$ROOT/modules/write-gate.md"
CAP="$ROOT/modules/capabilities.md"
P_EN="$ROOT/PROMPT.md"
P_PT="$ROOT/PROMPT.pt-BR.md"
R_EN="$ROOT/README.md"
R_PT="$ROOT/README.pt-BR.md"
HOOK="$ROOT/hooks/size-gate.sh"
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi
work=$(cd "$work" && pwd -P)

for f in "$VOC" "$SETUP" "$CONNECT" "$DAY" "$WEEK" "$START" "$GATE" "$CAP" "$P_EN" "$P_PT" "$R_EN" "$R_PT" "$HOOK"; do
  [ -f "$f" ] || { echo "FAIL  missing $f"; rm -rf "$work"; exit 1; }
done

# cell ROLE COLUMN: the backticked value of a row of the person-facing table
# (COLUMN 3 is en, 4 is pt-BR), by its role name.
cell() {
  awk -F'|' -v role="$1" -v col="$2" '
    /^## Person-facing vocabulary/ { on = 1; next }
    /^## / { on = 0 }
    on {
      r = $2; gsub(/^ +| +$/, "", r)
      if (r == role) { v = $col; sub(/^ *`/, "", v); sub(/` *$/, "", v); print v; exit }
    }' "$VOC"
}

# seed_names: every seed name of the vocabulary legacy table, both columns,
# one per line.
seed_names() {
  awk -F'|' '
    /^## Legacy 0.7.0 names/ { on = 1; next }
    /^## / { on = 0 }
    on {
      k = $2; gsub(/^ +| +$/, "", k)
      if (k == "seed") { n = $3; o = $4; gsub(/^ *`|` *$/, "", n); gsub(/^ *`|` *$/, "", o); print n; print o }
    }' "$VOC" | sort -u
}
seed_names > "$work/seeds"
[ "$(wc -l < "$work/seeds" | tr -d ' ')" -eq 12 ] || { echo "FAIL  vocabulary legacy table: $(wc -l < "$work/seeds" | tr -d ' ') seed names, expected 12"; rm -rf "$work"; exit 1; }

# list_of LABEL: the seeds of setup's "* LABEL...: `a` · `b`" list line.
list_of() {
  grep -E "^\* $1[^\`]*: \`[a-z-]+\`( · \`[a-z-]+\`)+\$" "$SETUP" | grep -o '`[a-z-]*`' | tr -d '`' | sort
}
list_of always > "$work/always"
list_of offered > "$work/offered"

# sentences FILE: the text of FILE, one sentence per line.
sentences() {
  awk '{ gsub(/\. /, ".\n"); print }' "$1"
}

# ---------------------------------------------------------------------------
# RD1 both READMEs promise the plant setup does.
# readme_table FILE N: the backticked first-column names of the rows of the
# Nth table of the "What comes planted" ("O que vem plantado") section.

readme_table() {
  awk -v want="$2" '
    /^## / { if (sec) exit; }
    /^## (What comes planted|O que vem plantado)/ { sec = 1; next }
    sec && /^\|[-| ]+\|$/ { t++; next }
    sec && t == want && /^\| `[a-z-]+` \|/ { s = $0; sub(/^\| `/, "", s); sub(/`.*$/, "", s); print s }
  ' "$1" | sort
}

rd1_bad=""
[ -s "$work/always" ] || rd1_bad="$rd1_bad [setup has no always list]"
[ -s "$work/offered" ] || rd1_bad="$rd1_bad [setup has no offered list]"
for r in "$R_EN" "$R_PT"; do
  b=$(basename "$r")
  readme_table "$r" 1 > "$work/rt1"
  readme_table "$r" 2 > "$work/rt2"
  cmp -s "$work/rt1" "$work/always" || rd1_bad="$rd1_bad [$b first table: $(tr '\n' ' ' < "$work/rt1")vs setup always: $(tr '\n' ' ' < "$work/always")]"
  cmp -s "$work/rt2" "$work/offered" || rd1_bad="$rd1_bad [$b routine table: $(tr '\n' ' ' < "$work/rt2")vs setup offered: $(tr '\n' ' ' < "$work/offered")]"
done
if [ -z "$rd1_bad" ]; then
  ok "RD1 both READMEs list the seeds setup always plants and the routines it offers"
else
  fail "RD1 README plant tables" "$rd1_bad"
fi

# ---------------------------------------------------------------------------
# RC1 close-day step 8: the Friday offer only with close-week planted.

grep -m1 '^8\. \*\*Answer short' "$DAY" > "$work/day8"
rc1_bad=""
[ -s "$work/day8" ] || rc1_bad="$rc1_bad [close-day step 8 not found]"
grep -q -F '.claude/skills/close-week/' "$work/day8" || rc1_bad="$rc1_bad [step 8 does not check the close-week folder]"
grep -q -F '.claude/skills/fechar-semana/' "$work/day8" || rc1_bad="$rc1_bad [step 8 does not check the 0.7.0 fechar-semana folder]"
grep -q -E 'pm-chief-of-staff:plant(ar)? +(close-week|fechar-semana)' "$work/day8" && rc1_bad="$rc1_bad [step 8 still pushes the plant of close-week]"
# The offer sentence itself sits in the sentence that names the folder.
sentences "$work/day8" | grep -i 'close the week' > "$work/day8offer"
[ -s "$work/day8offer" ] || rc1_bad="$rc1_bad [step 8 has no offer to close the week]"
while IFS= read -r s; do
  case "$s" in
    *'.claude/skills/close-week/'*) ;;
    *) rc1_bad="$rc1_bad [offer sentence not conditioned on the close-week folder: $s]" ;;
  esac
done < "$work/day8offer"
if [ -z "$rc1_bad" ]; then
  ok "RC1 close-day offers the week close only with close-week planted, and pushes no plant"
else
  fail "RC1 close-day Friday offer" "$rc1_bad"
fi

# ---------------------------------------------------------------------------
# RN1 the "seed not planted" silence is bounded to the catalog seeds.
# r6_judge FILE: 0 when the text of FILE (one consumer-check step) has a
# sentence that keeps a name silent as "not planted" only under the
# condition that it is one of the seeds, a sentence that calls a name that is
# not a seed a missing consumer (or absent), and no sentence that calls a
# name missing or absent without the "not a seed" condition. Sets why.

r6_judge() {
  why=""
  sentences "$1" > "$work/judge"
  grep 'not planted' "$work/judge" | grep 'silent' | grep 'is one of the' | grep -q 'seeds of th' \
    || why="$why [no silence sentence bounded to the seeds]"
  grep -E 'is a missing consumer|is absent\.' "$work/judge" | grep -q 'not a seed' \
    || why="$why [no missing-consumer sentence for a name that is not a seed]"
  grep -E 'is a missing consumer|is absent\.' "$work/judge" | grep -v 'not a seed' > "$work/judge-loose"
  [ -s "$work/judge-loose" ] && why="$why [unbounded missing-consumer sentence: $(head -1 "$work/judge-loose")]"
  grep 'not planted' "$work/judge" | grep -v 'is one of the' > "$work/judge-open"
  [ -s "$work/judge-open" ] && why="$why [unbounded not-planted sentence: $(head -1 "$work/judge-open")]"
  [ -z "$why" ]
}

rn1_bad=""
grep -m1 '^6\. \*\*Memory health\*\*' "$WEEK" > "$work/week6"
grep -m1 '^4\. \*\*Check the consumers\.\*\*' "$CONNECT" > "$work/c4"
[ -s "$work/week6" ] || rn1_bad="$rn1_bad [close-week step 6 not found]"
[ -s "$work/c4" ] || rn1_bad="$rn1_bad [connect step 4 not found]"
r6_judge "$work/week6" || rn1_bad="$rn1_bad [close-week step 6:$why]"
r6_judge "$work/c4" || rn1_bad="$rn1_bad [connect step 4:$why]"
# The judge must reject the three regressions: silence dropped (the 0.12.0
# text), silence generalized to any name, and the missing-consumer condition
# dropped.
n=0
for f in week6 c4; do
  n=$((n + 1))
  sed -E 's/[^.]*not planted[^.]*\.//' "$work/$f" > "$work/m1-$f"
  sed -E 's/that is one of the (six )?seeds of th(at|e) (map|table) //' "$work/$f" > "$work/m2-$f"
  sed -E 's/that is not a seed of th(at|e) (map|table) //' "$work/$f" > "$work/m3-$f"
  for m in m1 m2 m3; do
    if cmp -s "$work/$f" "$work/$m-$f"; then
      rn1_bad="$rn1_bad [mutation $m did not apply to $f]"
    elif r6_judge "$work/$m-$f"; then
      rn1_bad="$rn1_bad [judge accepts mutation $m of $f]"
    fi
  done
done
if [ -z "$rn1_bad" ]; then
  ok "RN1 close-week and connect keep only a catalog seed silent, and still flag any other missing consumer"
else
  fail "RN1 consumer check silence" "$rn1_bad"
fi

# ---------------------------------------------------------------------------
# RS1 setup never agrees on the later plant of one named routine: from the
# plant step to the end (planting and closing), the plant command appears
# only with the <name> placeholder or bare, never with a seed name.

awk '/^## Plant the seeds/ { on = 1 } on' "$SETUP" > "$work/plantstep"
rs1_bad=""
[ -s "$work/plantstep" ] || rs1_bad="$rs1_bad [setup has no Plant the seeds section]"
grep -o -E 'pm-chief-of-staff:plant(ar)? +[a-z][a-z-]*' "$work/plantstep" | awk '{ print $2 }' > "$work/plantnamed"
while IFS= read -r s; do
  grep -qx -- "$s" "$work/seeds" && rs1_bad="$rs1_bad [setup agrees on planting $s later]"
done < "$work/plantnamed"
grep -q -F '`/pm-chief-of-staff:plant <name>`' "$work/plantstep" || rs1_bad="$rs1_bad [no plant command for a routine not picked]"
if [ -z "$rs1_bad" ]; then
  ok "RS1 setup offers the plant command for any routine not picked and agrees on none by name"
else
  fail "RS1 setup plant agreement" "$rs1_bad"
fi

# ---------------------------------------------------------------------------
# RX1 the expiry of a dated prospective item, at every place that teaches it.
# Each place: FILE, the text it is read from, the expired mark of its
# language, and the words that bound the expiry to a written date.

exp_en=$(cell "expired mark" 3)
exp_pt=$(cell "expired mark" 4)
awk '/^Write rules the generated AGENTS.md carries/ { on = 1; next } /^Session routine the generated AGENTS.md carries/ { on = 0 } on' "$SETUP" > "$work/rules"
grep 'prospective item' "$work/rules" > "$work/setup-exp"
grep -m1 '^Hub head' "$P_EN" > "$work/pen"
grep -m1 '^Cabeça de hub' "$P_PT" > "$work/ppt"
grep -m1 '^10\. \*\*Set up next week\*\*' "$WEEK" > "$work/week10"
rx1_bad=""
[ -n "$exp_en" ] && [ -n "$exp_pt" ] || rx1_bad="$rx1_bad [no expired mark in the vocabulary]"
# place FILE MARK WRITTEN PASSED
place() {
  if [ ! -s "$work/$1" ]; then rx1_bad="$rx1_bad [$1: text not found]"; return; fi
  grep -q -F -- "$2" "$work/$1" || rx1_bad="$rx1_bad [$1: no expired mark '$2']"
  grep -q -F -- "$3" "$work/$1" || rx1_bad="$rx1_bad [$1: expiry not bound to '$3']"
  grep -q -E -- "$4" "$work/$1" || rx1_bad="$rx1_bad [$1: no passed-date condition]"
}
place setup-exp "$exp_en" "no written date" 'written date has passed'
place pen "$exp_en" "no written date" 'written date has passed'
place ppt "$exp_pt" "sem data escrita" 'data escrita já passou'
place week6 "$exp_en" "only what has a written date expires" 'date already passed'
place week10 "$exp_en" "no written date" 'date that already passed'
if [ -z "$rx1_bad" ]; then
  ok "RX1 a dated prospective item expires with the folder's mark, only for a written date that has passed"
else
  fail "RX1 prospective item expiry" "$rx1_bad"
fi

# ---------------------------------------------------------------------------
# RW1 the week's journal on its first task, with no migration, is safe only
# because start-day's backlog scan reads the whole journal folder.

j_en=$(cell "weekly journal folder" 3)
j_pt=$(cell "weekly journal folder" 4)
rw1_bad=""
grep 'first task written in a week' "$work/rules" > "$work/setup-week"
grep -q -F -- "\`$j_en\`" "$work/setup-week" || rw1_bad="$rw1_bad [setup week rule does not create the journal in \`$j_en\`]"
grep -q 'no task migrated' "$work/setup-week" || rw1_bad="$rw1_bad [setup week rule migrates tasks]"
grep -q -F -- "in $j_en" "$work/pen" && grep -q 'no task migrated' "$work/pen" || rw1_bad="$rw1_bad [PROMPT.md week rule: journal folder $j_en or no-migration missing]"
grep -q -F -- "em $j_pt" "$work/ppt" && grep -q 'sem migrar tarefa' "$work/ppt" || rw1_bad="$rw1_bad [PROMPT.pt-BR.md week rule: journal folder $j_pt or no-migration missing]"
grep -m1 '^3\. \*\*Scan the backlog\*\*' "$START" > "$work/start3"
grep -q -F -- "across the whole \`$j_en\`" "$work/start3" || rw1_bad="$rw1_bad [start-day backlog scan does not read the whole \`$j_en\`]"
if [ -z "$rw1_bad" ]; then
  ok "RW1 a new week's journal starts with no migration, and the backlog reads the whole journal folder"
else
  fail "RW1 week journal without close-week" "$rw1_bad"
fi

# ---------------------------------------------------------------------------
# RL1 one set of ceilings, and the manual's write rule names the planted gate.

rl1_bad=""
awk '/^## Ceiling rule/ { on = 1; next } /^## / { on = 0 } on' "$GATE" > "$work/ceil"
[ -s "$work/ceil" ] || rl1_bad="$rl1_bad [write-gate.md has no Ceiling rule section]"
for w in '~700 tokens' '~3KB' '~15 lines' '2 to 4 lines' 'never cut alone' '"History"'; do
  grep -q -F -- "$w" "$work/ceil" || rl1_bad="$rl1_bad [write gate ceiling rule lacks $w]"
done
grep -q -F '~700 tokens' "$SETUP" && grep -q -F '(~15 lines)' "$SETUP" && grep -q -F '2 to 4 lines' "$SETUP" \
  || rl1_bad="$rl1_bad [setup ceilings differ from the write gate]"
grep -q -F 'CRITICAL_FACTS.md 700 tokens, hub head half a page (~15 lines), log entry 2 to 4 lines' "$work/pen" \
  || rl1_bad="$rl1_bad [PROMPT.md ceilings differ from the write gate]"
grep -q -F 'CRITICAL_FACTS.md 700 tokens, cabeça de hub meia página (~15 linhas), marco de log 2 a 4 linhas' "$work/ppt" \
  || rl1_bad="$rl1_bad [PROMPT.pt-BR.md ceilings differ from the write gate]"
grep -q -F '~3KB' "$work/week6" && grep -q -F '(~15 lines)' "$work/week6" \
  || rl1_bad="$rl1_bad [close-week step 6 ceilings differ from the write gate]"
# The module path the manual's write rule names is the one setup plants.
grep 'Every fact written to a shared destination' "$work/rules" > "$work/setup-gate"
grep -q -F '`.claude/skills/_shared/write-gate.md`' "$work/setup-gate" || rl1_bad="$rl1_bad [manual write rule does not name the planted gate]"
grep -q -F 'copy `${CLAUDE_PLUGIN_ROOT}/modules/write-gate.md` to their `.claude/skills/_shared/write-gate.md`' "$SETUP" \
  || rl1_bad="$rl1_bad [setup does not plant the gate at the path the manual names]"
grep -q -F '`.claude/skills/_shared/write-gate.md`' "$DAY" || rl1_bad="$rl1_bad [close-day does not point at the gate]"
if [ -z "$rl1_bad" ]; then
  ok "RL1 one set of ceilings in the gate, setup, both PROMPTs and close-week, and the manual names the planted gate"
else
  fail "RL1 ceilings and gate path" "$rl1_bad"
fi

# ---------------------------------------------------------------------------
# RG1 the size gate message names no routine.

json_msg() {
  if command -v plutil >/dev/null 2>&1; then
    plutil -extract hookSpecificOutput.additionalContext raw -o - "$1" 2>/dev/null
  elif command -v node >/dev/null 2>&1; then
    node -e 'const v=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));const m=v&&v.hookSpecificOutput&&v.hookSpecificOutput.additionalContext;if(typeof m!=="string")process.exit(1);process.stdout.write(m)' "$1" 2>/dev/null
  else
    return 1
  fi
}
fill() {
  LC_ALL=C awk -v n="$2" 'BEGIN { while (n >= 100) { printf "%099d\n", 0; n -= 100 } while (n-- > 0) printf "x" }' > "$1"
}
rg1_bad=""
W="$work/folder"
D="$work/data"
mkdir -p "$W" "$D"
fill "$W/AGENTS.md" 1989
echo "@AGENTS.md" > "$W/CLAUDE.md"
echo "navigation" > "$W/navigation.md"
fill "$W/CRITICAL_FACTS.md" 1000
SID="rituais-p1-rg1"
printf '{"session_id":"%s","hook_event_name":"UserPromptSubmit","prompt":"hello"}' "$SID" > "$work/in1"
printf '{"session_id":"%s","hook_event_name":"Stop","stop_hook_active":false,"last_assistant_message":"done"}' "$SID" > "$work/in2"
(cd "$W" && CLAUDE_PROJECT_DIR="$W" CLAUDE_PLUGIN_DATA="$D" sh "$HOOK" prompt) < "$work/in1" > "$work/out1" 2>/dev/null
fill "$W/AGENTS.md" 13989
fill "$W/CRITICAL_FACTS.md" 4500
(cd "$W" && CLAUDE_PROJECT_DIR="$W" CLAUDE_PLUGIN_DATA="$D" sh "$HOOK" stop) < "$work/in2" > "$work/out2" 2>/dev/null
if json_msg "$work/out2" > "$work/msg" && [ -s "$work/msg" ]; then
  n=$(wc -c < "$work/msg" | tr -d ' ')
  [ "$n" -le 2000 ] || rg1_bad="$rg1_bad [message of $n bytes]"
  while IFS= read -r s; do
    grep -q -w -F -- "$s" "$work/msg" && rg1_bad="$rg1_bad [message names the routine $s]"
  done < "$work/seeds"
  grep -q -F 'grew from 2000 to 14000 bytes' "$work/msg" || rg1_bad="$rg1_bad [manual numbers missing]"
  grep -q -F 'grew from 1000 to 4500 bytes' "$work/msg" || rg1_bad="$rg1_bad [CRITICAL_FACTS.md numbers missing]"
  grep -q -w 10000 "$work/msg" && grep -q -w 3000 "$work/msg" || rg1_bad="$rg1_bad [a curation target is missing]"
else
  rg1_bad="$rg1_bad [no block message read from the stop output: $(cat "$work/out2")]"
fi
if [ -z "$rg1_bad" ]; then
  ok "RG1 size gate message over both caps: within 2000 bytes, both targets, no routine named"
else
  fail "RG1 size gate message" "$rg1_bad"
fi

rm -rf "$work"
[ "$failures" -eq 0 ]
