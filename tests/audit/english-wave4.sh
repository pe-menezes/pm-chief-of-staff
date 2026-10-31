#!/bin/sh
# Probes from the audit of the english front, wave 4 (P10 and P11 docs, and the
# final fix in setup and plant). Behavior only, pinned by content.
# Run by hand: sh tests/audit/english-wave4.sh
# setup and plant are instructions, so the probes check what the agent follows
# at run time: the "look at the folder" cases of setup are checked in order and
# the first match decides, so every case must be reachable and the case that
# reviews a folder with an instruction file must come before the generic
# "folder with files"; the leftover search after an adapted copy must name
# every en name that a seed (or, for setup, a planted module) actually uses and
# that the folder maps differently; and the docs (both READMEs, both PROMPTs,
# the issue templates) only point at commands, seeds, plugin paths and section
# anchors that exist.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

# An exported CDPATH makes cd print the folder inside $(...), which would
# double every path built from ROOT.
unset CDPATH
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
VOC="$ROOT/modules/vocabulary.md"
SETUP="$ROOT/skills/setup/SKILL.md"
PLANT="$ROOT/skills/plant/SKILL.md"
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi

for f in "$VOC" "$SETUP" "$PLANT"; do
  [ -f "$f" ] || { echo "FAIL  missing $f"; rm -rf "$work"; exit 1; }
done

# legacy KIND: "new old" lines of the "Legacy 0.7.0 names" table for one kind.
legacy() {
  awk -F'|' -v kind="$1" '
    /^## Legacy 0.7.0 names/ { on = 1; next }
    /^## / { on = 0 }
    on {
      k = $2; gsub(/^ +| +$/, "", k)
      if (k == kind) {
        n = $3; o = $4
        gsub(/^ *`|` *$/, "", n); gsub(/^ *`|` *$/, "", o)
        print n " " o
      }
    }' "$VOC"
}

# ---------------------------------------------------------------------------
# AQ1 (risk code: the case that reviews without renaming) setup looks at the
# folder through a list of cases checked in order, where the first case that
# matches decides. A folder with AGENTS.md or CLAUDE.md is also a folder with
# files, and a folder being resumed has both the notes file and, often, an
# instruction file (the 0.7.0 fixture of E3.7). So the notes case comes first,
# the instruction-file case comes before "folder with files", and each case
# appears once. The instruction-file case names both instruction files (a
# folder from before 0.6 has only CLAUDE.md) and the notes case names the
# notes file under both names of the vocabulary legacy table.

awk '
  /^## Before you start: look at the folder/ { on = 1; next }
  /^## / { on = 0 }
  on && /^\* \*\*/ { print }' "$SETUP" > "$work/cases"
notes_new=$(legacy "folder file" | awk '$1 == "setup-notes.md" { print $1 }')
notes_old=$(legacy "folder file" | awk '$1 == "setup-notes.md" { print $2 }')
# pos PATTERN: the 1-based position of the only case whose bold head matches
# PATTERN (fixed string), "0" when none, "many" when more than one.
pos() {
  awk -v p="$1" '
    { h = $0; sub(/^\* \*\*/, "", h); e = index(h, ":**"); if (e) h = substr(h, 1, e) }
    index(h, p) { n++; at = NR }
    END { if (n == 0) print 0; else if (n > 1) print "many"; else print at }' "$work/cases"
}
aq1_bad=""
[ -n "$notes_new" ] && [ -n "$notes_old" ] || aq1_bad="$aq1_bad [no setup-notes.md row in the legacy table]"
p_notes=$(pos "\`$notes_new\`")
p_instr=$(pos '`AGENTS.md`')
p_empty=$(pos 'Empty folder')
p_files=$(pos 'with files')
for v in "notes:$p_notes" "instruction:$p_instr" "empty:$p_empty" "files:$p_files"; do
  case ${v#*:} in
    0) aq1_bad="$aq1_bad [no ${v%%:*} case]" ;;
    many) aq1_bad="$aq1_bad [more than one ${v%%:*} case]" ;;
  esac
done
if [ -z "$aq1_bad" ]; then
  [ "$p_notes" -eq 1 ] || aq1_bad="$aq1_bad [notes case is #$p_notes, not first]"
  [ "$p_instr" -lt "$p_files" ] || aq1_bad="$aq1_bad [instruction-file case #$p_instr comes after folder-with-files #$p_files: unreachable]"
  [ "$p_notes" -lt "$p_instr" ] || aq1_bad="$aq1_bad [notes case after the instruction-file case: resume unreachable]"
  head_instr=$(sed -n "${p_instr}p" "$work/cases" | sed 's/:\*\*.*$//')
  case $head_instr in *'`CLAUDE.md`'*) ;; *) aq1_bad="$aq1_bad [instruction-file case does not name CLAUDE.md]" ;; esac
  head_notes=$(sed -n "${p_notes}p" "$work/cases" | sed 's/:\*\*.*$//')
  case $head_notes in *"\`$notes_old\`"*) ;; *) aq1_bad="$aq1_bad [notes case does not name $notes_old]" ;; esac
fi
[ "$(wc -l < "$work/cases" | tr -d ' ')" -eq 4 ] || aq1_bad="$aq1_bad [$(wc -l < "$work/cases" | tr -d ' ') cases, expected 4]"
if [ -z "$aq1_bad" ]; then
  ok "AQ1 setup folder cases: notes, instruction file, then the generic ones, each reachable"
else
  fail "AQ1 setup folder cases" "$aq1_bad"
fi

# ---------------------------------------------------------------------------
# AQ2 the leftover search after an adapted copy covers what the copy can carry:
# every fixed part (text before the first "{" or "YYYY", only the bold label
# of a "**X:** ..." cell; in a cell with a placeholder, also the text after
# the last placeholder, as role "ROLE (end)") of an en cell of the
# person-facing table whose pt-BR
# fixed part differs, that a catalog seed uses, is named in plant's 0.7.0 list
# and in setup's pt-BR list; setup also plants capabilities.md and
# write-gate.md, so the names those modules use are in its list too. The
# date-format row is a format, not a name, and is left out.

heads() {
  awk -F'|' -v col="$1" '
    /^## Person-facing vocabulary/ { on = 1; next }
    /^## / { on = 0 }
    on && /^\| / {
      r = $2; gsub(/^ +| +$/, "", r)
      v = $col; sub(/^ *`/, "", v); sub(/` *$/, "", v)
      if (r == "role" || r == "date format in labels" || v ~ /^-+$/) next
      if (v ~ /^\*\*[^*]*:\*\*/) { match(v, /^\*\*[^*]*:\*\*/); v = substr(v, 1, RLENGTH) }
      e = v
      if (sub(/^.*([}]|YYYY-MM-DD|DD\/MM)/, "", e)) { sub(/^ +/, "", e); if (e != "") print r " (end)\t" e }
      sub(/ *(\{|YYYY|DD\/MM).*$/, "", v)
      print r "\t" v
    }' "$VOC"
}
heads 3 > "$work/h-en"
heads 4 > "$work/h-pt"
# listed FILE INTRO: the backticked names between INTRO and "and the rest".
listed() {
  grep -F -- "$2" "$1" | head -1 | awk -v i="$2" '{ s = index($0, i); t = substr($0, s); e = index(t, "and the rest of the column"); if (s && e) print substr(t, 1, e - 1) }' \
    | grep -o '`[^`]*`' | tr -d '`'
}
listed "$PLANT" "In an 0.7.0 folder the search covers" > "$work/l-plant"
listed "$SETUP" "For a pt-BR folder the search covers" > "$work/l-setup"
cat "$ROOT"/seeds/*/SKILL.md > "$work/seeds"
cat "$work/seeds" "$ROOT/modules/capabilities.md" "$ROOT/modules/write-gate.md" > "$work/seeds-mods"
aq2_bad=""
[ "$(wc -l < "$work/l-plant" | tr -d ' ')" -ge 8 ] || aq2_bad="$aq2_bad [plant list not found]"
[ "$(wc -l < "$work/l-setup" | tr -d ' ')" -ge 8 ] || aq2_bad="$aq2_bad [setup list not found]"
while IFS="$(printf '\t')" read -r role en; do
  pt=$(awk -F'\t' -v r="$role" '$1 == r { print $2; exit }' "$work/h-pt")
  [ -n "$en" ] && [ "$en" != "$pt" ] || continue
  if grep -q -F -- "$en" "$work/seeds"; then
    grep -q -x -F -- "$en" "$work/l-plant" || aq2_bad="$aq2_bad [plant list misses $en ($role), used by a seed]"
  fi
  if grep -q -F -- "$en" "$work/seeds-mods"; then
    grep -q -x -F -- "$en" "$work/l-setup" || aq2_bad="$aq2_bad [setup list misses $en ($role), used by a seed or module]"
  fi
done < "$work/h-en"
if [ -z "$aq2_bad" ]; then
  ok "AQ2 leftover lists name every differing en name a planted copy carries"
else
  fail "AQ2 leftover lists" "$aq2_bad"
fi

# ---------------------------------------------------------------------------
# AQ3 the docs promise only what the plugin has: every /pm-chief-of-staff:<name>
# in the two READMEs, the two PROMPTs and the issue templates is a plugin skill;
# every seed command `/<name>` they cite is a catalog seed; every backticked
# plugin path (hooks/, modules/, skills/, seeds/, agents/, tests/) exists; and
# the upgrade table of each README is exactly the 0.7.0 to 0.8.0 map of the
# vocabulary (commands table plus the six legacy seed rows).

docs="$ROOT/README.md $ROOT/README.pt-BR.md $ROOT/PROMPT.md $ROOT/PROMPT.pt-BR.md"
for t in "$ROOT"/.github/ISSUE_TEMPLATE/*.md; do docs="$docs $t"; done
aq3_bad=""
for d in $docs; do
  [ -f "$d" ] || { aq3_bad="$aq3_bad [missing $d]"; continue; }
  b=$(basename "$d")
  for c in $(grep -o '/pm-chief-of-staff:[a-z][a-z-]*' "$d" | sed 's#^/pm-chief-of-staff:##' | sort -u); do
    [ -f "$ROOT/skills/$c/SKILL.md" ] || aq3_bad="$aq3_bad [$b: /pm-chief-of-staff:$c has no skills/$c]"
  done
  # `/plugin` and `/reload-plugins` are Claude Code's own commands; a 0.7.0
  # seed name is a live command in an 0.7.0 folder.
  for s in $(grep -o '`/[a-z][a-z-]*`' "$d" | tr -d '`/' | grep -v -x -E 'plugin|reload-plugins' | sort -u); do
    [ -f "$ROOT/seeds/$s/SKILL.md" ] || legacy seed | awk -v s="$s" '$2 == s { f = 1 } END { exit !f }' \
      || aq3_bad="$aq3_bad [$b: /$s is not a catalog seed]"
  done
  for p in $(grep -o -E '`(hooks|modules|skills|seeds|agents|tests)/[^` ]+`' "$d" | tr -d '`' | sort -u); do
    [ -e "$ROOT/$p" ] || aq3_bad="$aq3_bad [$b: $p does not exist]"
  done
done
# the vocabulary map: the plugin rows of the commands table plus the six seed
# rows of the legacy table, "old new".
awk -F'|' '
  /^## Commands 0.7.0 to 0.8.0/ { on = 1; next }
  /^## / { on = 0 }
  on && /^\| `\/pm-chief-of-staff:/ { o = $2; n = $3; gsub(/^ *`|` *$/, "", o); gsub(/^ *`|` *$/, "", n); sub(/^\/pm-chief-of-staff:/, "", o); sub(/^\/pm-chief-of-staff:/, "", n); print o " " n }' "$VOC" > "$work/map"
legacy seed | awk '{ print $2 " " $1 }' >> "$work/map"
sort -u "$work/map" -o "$work/map"
[ "$(wc -l < "$work/map" | tr -d ' ')" -ge 11 ] || aq3_bad="$aq3_bad [vocabulary map has $(wc -l < "$work/map" | tr -d ' ') rows, expected 11]"
for r in "$ROOT/README.md" "$ROOT/README.pt-BR.md"; do
  awk -F'|' '
    /^\| 0\.7 \| 0\.8 \|/ { on = 1; next }
    on && !/^\|/ { on = 0 }
    on && /^\| `/ { o = $2; n = $3; gsub(/^ *`|` *$/, "", o); gsub(/^ *`|` *$/, "", n); print o " " n }' "$r" | sort -u > "$work/up"
  cmp -s "$work/map" "$work/up" || aq3_bad="$aq3_bad [$(basename "$r") upgrade table differs from the vocabulary: $(diff "$work/map" "$work/up" | grep '^[<>]' | tr '\n' ' ')]"
done
if [ -z "$aq3_bad" ]; then
  ok "AQ3 docs cite only existing commands, seeds and paths; upgrade tables match the vocabulary"
else
  fail "AQ3 docs references" "$aq3_bad"
fi

# ---------------------------------------------------------------------------
# AQ4 every in-page link of the two READMEs ("](#anchor)") lands on a heading
# of the same file, by the GitHub rule: lowercase, punctuation dropped, spaces
# turned into hyphens (accented letters are kept as they are).

slugs() {
  grep -E '^#{1,6} ' "$1" | sed -E 's/^#+ //' | tr 'A-Z' 'a-z' | sed -E 's/[][()?,.:!"`*/&'"'"']//g; s/ /-/g'
}
aq4_bad=""
for r in "$ROOT/README.md" "$ROOT/README.pt-BR.md"; do
  [ -f "$r" ] || { aq4_bad="$aq4_bad [missing $(basename "$r")]"; continue; }
  slugs "$r" > "$work/slugs"
  for a in $(grep -o '](#[^)]*)' "$r" | sed 's/^](#//; s/)$//' | sort -u); do
    grep -q -x -F -- "$a" "$work/slugs" || aq4_bad="$aq4_bad [$(basename "$r"): #$a has no heading]"
  done
done
if [ -z "$aq4_bad" ]; then
  ok "AQ4 README in-page links land on existing headings"
else
  fail "AQ4 README anchors" "$aq4_bad"
fi

# ---------------------------------------------------------------------------
# AQ5 (risk code: the agent-side names of an 0.7.0 folder) an 0.7.0 folder
# keeps the 0.7.0 names on the agent side too: its file is navegacao.md and
# its capabilities module names the capability rows and the columns the 0.7.0
# way, so a planted seed that reads `navigation.md` or the `how to call`
# column reads what is not there. For every row of the vocabulary legacy table
# of kind folder file, agent label, capability, capabilities column,
# capabilities section or tells.md section whose 0.7.0 name differs and that
# a catalog seed cites in backticks: plant's 0.7.0 leftover list names it,
# and setup's pt-BR list (a new folder, where these names stay in English)
# does not. The adaptation step of plant takes the legacy column of both
# tables that hold these names, and names the fixed file it maps.

awk -F'|' '
  /^## Legacy 0.7.0 names/ { on = 1; next }
  /^## / { on = 0 }
  on {
    k = $2; gsub(/^ +| +$/, "", k)
    if (k != "folder file" && k != "agent label" && k != "capability" && k != "capabilities column" \
        && k != "capabilities section" && k != "`tells.md` section") next
    n = $3; o = $4
    gsub(/^ *`|` *$/, "", n); gsub(/^ *`|` *$/, "", o)
    if (n != o) print k "\t" n "\t" o
  }' "$VOC" > "$work/agent-legacy"
aq5_bad=""
[ "$(wc -l < "$work/agent-legacy" | tr -d ' ')" -ge 10 ] || aq5_bad="$aq5_bad [agent-side legacy rows not found]"
used=0
while IFS="$(printf '\t')" read -r kind en old; do
  grep -q -F -- "\`$en\`" "$work/seeds" || continue
  used=$((used + 1))
  grep -q -x -F -- "$en" "$work/l-plant" || aq5_bad="$aq5_bad [plant list misses $en ($kind, 0.7.0 $old), cited by a seed]"
  grep -q -x -F -- "$en" "$work/l-setup" && aq5_bad="$aq5_bad [setup list names $en, which a new folder keeps]"
done < "$work/agent-legacy"
[ "$used" -ge 4 ] || aq5_bad="$aq5_bad [only $used agent-side names found in the seeds]"
step=$(grep -F -- "adapted to the folder's vocabulary before writing" "$PLANT" | head -1)
[ -n "$step" ] || aq5_bad="$aq5_bad [plant adaptation step not found]"
for t in '"Agent-side labels"' '"Legacy 0.7.0 names"' '`navigation.md`' '`navegacao.md`'; do
  printf '%s\n' "$step" | grep -q -F -- "$t" || aq5_bad="$aq5_bad [plant adaptation step does not name $t]"
done
if [ -z "$aq5_bad" ]; then
  ok "AQ5 plant adapts and searches the agent-side 0.7.0 names in an 0.7.0 folder only"
else
  fail "AQ5 agent-side 0.7.0 names" "$aq5_bad"
fi

rm -rf "$work"
[ "$failures" -eq 0 ]
