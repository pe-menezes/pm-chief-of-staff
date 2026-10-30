#!/bin/sh
# Probes from the audit of the english front, wave 3 (P4: setup and plant).
# Behavior only, pinned by content.
# Run by hand: sh tests/audit/english-wave3.sh
# setup and plant are instructions, so the probes check the contracts between
# files that the agent follows at run time: the 0.7.0 seed map the plant and
# setup use to recognize a seed planted under its old name is the map of
# modules/vocabulary.md; both skills detect an 0.7.0 folder by the same legacy
# files; every plugin path and command they tell the agent to read or run
# exists; the names they search for after an adapted copy are real names that
# the folder maps differently; the labels setup writes into AGENTS.md and the
# hubs are the vocabulary cells the other skills read; the direct-report block
# setup strips is delimited the way the seed marks it; and the 0.7.0 trigger
# phrases of setup and plantar still fire the new skills.
# AP8 needs the git history of this repo (commit 318ea9c); without it, it
# prints "info" and the rest runs the same. GIT_ROOT (default: this repo)
# points the history lookup elsewhere, to run the probes over a copy.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
GIT_ROOT=${GIT_ROOT:-$ROOT}
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

# heads COLUMN: the fixed part of every cell of the person-facing table in that
# column (the text before the first "{" or "YYYY", and only the bold label of
# a "**X:** ..." cell; in a cell with a placeholder, also the text after the
# last placeholder, as role "ROLE (end)"), one per line, tab, the role.
heads() {
  awk -F'|' -v col="$1" '
    /^## Person-facing vocabulary/ { on = 1; next }
    /^## / { on = 0 }
    on && /^\| / {
      r = $2; gsub(/^ +| +$/, "", r)
      v = $col; sub(/^ *`/, "", v); sub(/` *$/, "", v)
      if (r == "role" || v ~ /^-+$/) next
      if (v ~ /^\*\*[^*]*:\*\*/) { match(v, /^\*\*[^*]*:\*\*/); v = substr(v, 1, RLENGTH) }
      e = v
      if (sub(/^.*([}]|YYYY-MM-DD|DD\/MM)/, "", e)) { sub(/^ +/, "", e); if (e != "") print e "\t" r " (end)" }
      sub(/ *(\{|YYYY|DD\/MM).*$/, "", v)
      print v "\t" r
    }' "$VOC"
}

# ---------------------------------------------------------------------------
# AP1 the plant marks a seed as planted, and treats a request as a collision,
# by the 0.7.0 map it spells out in step 1: that map is the six seed rows of
# the vocabulary legacy table, pair by pair, and each 0.8.0 name is a seed of
# the catalog.

legacy seed | sort > "$work/voc-seeds"
grep -o -E '`[a-z-]+` for `[a-z-]+`' "$PLANT" | sed -E 's/^`([a-z-]+)` for `([a-z-]+)`$/\2 \1/' | sort -u > "$work/plant-seeds"
ap1_bad=""
[ "$(wc -l < "$work/voc-seeds" | tr -d ' ')" -eq 6 ] || ap1_bad="$ap1_bad [vocabulary has $(wc -l < "$work/voc-seeds" | tr -d ' ') seed rows]"
cmp -s "$work/voc-seeds" "$work/plant-seeds" || ap1_bad="$ap1_bad [plant map differs from the vocabulary: $(diff "$work/voc-seeds" "$work/plant-seeds" | grep '^[<>]' | tr '\n' ' ')]"
for s in $(cut -d' ' -f1 "$work/voc-seeds"); do
  [ -f "$ROOT/seeds/$s/SKILL.md" ] || ap1_bad="$ap1_bad [no seeds/$s]"
done
for d in "$ROOT"/seeds/*/; do
  s=$(basename "$d")
  grep -q "^$s " "$work/voc-seeds" || ap1_bad="$ap1_bad [catalog seed $s has no 0.7.0 row]"
done
if [ -z "$ap1_bad" ]; then
  ok "AP1 plant recognizes the six 0.7.0 seeds by the vocabulary map"
else
  fail "AP1 plant legacy seed map" "$ap1_bad"
fi

# ---------------------------------------------------------------------------
# AP2 setup plants five seeds of the catalog, never overwrites the 0.7.0
# predecessor of any of them (same map as the vocabulary), and leaves exactly
# the sixth, close-week, for the "/pm-chief-of-staff:plant close-week" it
# agrees on at the close.

ap2_bad=""
planted=$(grep -E '^\* `[a-z-]+`( · `[a-z-]+`)+$' "$SETUP" | grep -o '`[a-z-]*`' | tr -d '`' | sort)
[ "$(printf '%s\n' "$planted" | grep -c .)" -eq 5 ] || ap2_bad="$ap2_bad [setup lists $(printf '%s\n' "$planted" | grep -c .) seeds]"
for s in $planted; do
  [ -f "$ROOT/seeds/$s/SKILL.md" ] || ap2_bad="$ap2_bad [no seeds/$s]"
done
left=$(ls "$ROOT/seeds" | sort | comm -23 - "$(printf '%s\n' "$planted" > "$work/planted"; echo "$work/planted")")
[ "$left" = close-week ] || ap2_bad="$ap2_bad [catalog seeds setup does not plant: $left]"
grep -qF '`/pm-chief-of-staff:plant close-week`' "$SETUP" || ap2_bad="$ap2_bad [no /pm-chief-of-staff:plant close-week]"
grep -o -E '`[a-z-]+` for `[a-z-]+`' "$SETUP" | sed -E 's/^`([a-z-]+)` for `([a-z-]+)`$/\2 \1/' | sort -u > "$work/setup-seeds"
grep -v '^close-week ' "$work/voc-seeds" > "$work/voc-five"
cmp -s "$work/voc-five" "$work/setup-seeds" || ap2_bad="$ap2_bad [setup predecessor map differs: $(diff "$work/voc-five" "$work/setup-seeds" | grep '^[<>]' | tr '\n' ' ')]"
if [ -z "$ap2_bad" ]; then
  ok "AP2 setup plants five catalog seeds, checks their 0.7.0 predecessors, leaves close-week"
else
  fail "AP2 setup seeds" "$ap2_bad"
fi

# ---------------------------------------------------------------------------
# AP3 setup and plant decide "this is an 0.7.0 folder" by the same legacy
# files, and each one is a legacy name of the vocabulary (folder file or
# module), so the two skills never read the same folder with different columns.

# evidence FILE: the backticked names between "is from 0.7.0 when it has" and
# the end of that sentence.
evidence() {
  grep -o 'is from 0\.7\.0 when it has [^;]*' "$1" | head -1 | sed 's/ or any of the six seed folders.*$//' | grep -o '`[^`]*`' | tr -d '`' | sort -u
}
evidence "$SETUP" > "$work/ev-setup"
evidence "$PLANT" > "$work/ev-plant"
{ legacy "folder file"; legacy module; } | awk '{ print $2 }' | sort -u > "$work/voc-legacy-files"
ap3_bad=""
[ -s "$work/ev-setup" ] || ap3_bad="$ap3_bad [setup states no 0.7.0 evidence]"
cmp -s "$work/ev-setup" "$work/ev-plant" || ap3_bad="$ap3_bad [setup and plant differ: $(diff "$work/ev-setup" "$work/ev-plant" | grep '^[<>]' | tr '\n' ' ')]"
while IFS= read -r n; do
  grep -qxF -- "$n" "$work/voc-legacy-files" || ap3_bad="$ap3_bad [$n is not a vocabulary legacy name]"
done < "$work/ev-setup"
for n in navegacao.md setup-notas.md; do
  grep -qxF -- "$n" "$work/ev-setup" || ap3_bad="$ap3_bad [$n missing]"
done
grep -q 'or any of the six seed folders under its 0\.7\.0 name' "$SETUP" || ap3_bad="$ap3_bad [setup: seed folders are no evidence]"
grep -q 'or any of the six seed folders under its 0\.7\.0 name' "$PLANT" || ap3_bad="$ap3_bad [plant: seed folders are no evidence]"
if [ -z "$ap3_bad" ]; then
  ok "AP3 setup and plant detect an 0.7.0 folder by the same vocabulary legacy names"
else
  fail "AP3 0.7.0 detection" "$ap3_bad"
fi

# ---------------------------------------------------------------------------
# AP4 every plugin path setup and plant tell the agent to read or run exists in
# the plugin (the bridge as a script sh can read), and every plugin command they
# cite is a plugin skill, except the 0.7.0 name of plant, which must be the
# legacy column of the commands table.

ap4_bad=""
grep -h -o -E '\$\{CLAUDE_PLUGIN_ROOT\}/[A-Za-z0-9_./-]*|<plugin root>/[A-Za-z0-9_./-]*' "$SETUP" "$PLANT" \
  | sed -E 's#^(\$\{CLAUDE_PLUGIN_ROOT\}|<plugin root>)/##' | sort -u > "$work/paths"
[ "$(wc -l < "$work/paths" | tr -d ' ')" -ge 6 ] || ap4_bad="$ap4_bad [only $(wc -l < "$work/paths" | tr -d ' ') plugin paths]"
while IFS= read -r p; do
  [ -e "$ROOT/$p" ] || ap4_bad="$ap4_bad [$p does not exist]"
done < "$work/paths"
grep -qx 'modules/codex-bridge.sh' "$work/paths" || ap4_bad="$ap4_bad [no bridge path]"
sh -n "$ROOT/modules/codex-bridge.sh" 2>/dev/null || ap4_bad="$ap4_bad [bridge is not a valid sh script]"
grep -h -o -E '/pm-chief-of-staff:[a-z-]+' "$SETUP" "$PLANT" | sed 's#^/pm-chief-of-staff:##' | sort -u > "$work/cmds"
old_plant=$(awk -F'|' '/^## Commands 0.7.0 to 0.8.0/ { on = 1; next } on && /`\/pm-chief-of-staff:plant`/ { v = $2; gsub(/^ *`\/pm-chief-of-staff:|` *$/, "", v); print v; exit }' "$VOC")
[ -n "$old_plant" ] || ap4_bad="$ap4_bad [no 0.7.0 name of plant in the commands table]"
while IFS= read -r c; do
  [ -f "$ROOT/skills/$c/SKILL.md" ] && continue
  [ -n "$old_plant" ] && [ "$c" = "$old_plant" ] && continue
  ap4_bad="$ap4_bad [/pm-chief-of-staff:$c is not a plugin skill]"
done < "$work/cmds"
if [ -z "$ap4_bad" ]; then
  ok "AP4 every plugin path and command cited by setup and plant exists"
else
  fail "AP4 plugin paths and commands" "$ap4_bad"
fi

# ---------------------------------------------------------------------------
# AP5 the leftover search after an adapted copy: each name setup lists for a
# pt-BR folder and plant lists for an 0.7.0 folder is the fixed part of an en
# cell whose pt-BR fixed part differs (so a hit is a real unadapted name), or,
# only in the 0.7.0 list, a module whose 0.7.0 name differs. A module name in
# the pt-BR list would make the agent "fix" the right path of a new folder.

heads 3 > "$work/h-en"
heads 4 > "$work/h-pt"
# listed FILE INTRO: the backticked names between INTRO and "and the rest".
listed() {
  grep -F -- "$2" "$1" | head -1 | awk -v i="$2" '{ s = index($0, i); t = substr($0, s); e = index(t, "and the rest of the column"); if (s && e) print substr(t, 1, e - 1) }' \
    | grep -o '`[^`]*`' | tr -d '`'
}
ap5_bad=""
check_list() {
  file=$1; intro=$2; allow_modules=$3; tag=$4
  listed "$file" "$intro" > "$work/list"
  [ "$(wc -l < "$work/list" | tr -d ' ')" -ge 8 ] || { ap5_bad="$ap5_bad [$tag: list not found]"; return; }
  while IFS= read -r n; do
    role=$(awk -F'\t' -v n="$n" '$1 == n { print $2; exit }' "$work/h-en")
    if [ -n "$role" ]; then
      en=$(awk -F'\t' -v r="$role" '$2 == r { print $1; exit }' "$work/h-en")
      pt=$(awk -F'\t' -v r="$role" '$2 == r { print $1; exit }' "$work/h-pt")
      [ "$en" != "$pt" ] || ap5_bad="$ap5_bad [$tag: $n is the same in pt-BR]"
      continue
    fi
    case $n in
      capabilities.md|write-gate.md)
        if [ "$allow_modules" = yes ]; then
          old=$(legacy module | awk -v n="_shared/$n" '$1 == n { print $2 }')
          [ -n "$old" ] && [ "$old" != "_shared/$n" ] || ap5_bad="$ap5_bad [$tag: $n has no different 0.7.0 name]"
        else
          ap5_bad="$ap5_bad [$tag: $n is a fixed name in a new folder]"
        fi ;;
      *) ap5_bad="$ap5_bad [$tag: $n is no en name of the vocabulary]" ;;
    esac
  done < "$work/list"
}
check_list "$SETUP" "For a pt-BR folder the search covers" no setup
check_list "$PLANT" "In an 0.7.0 folder the search covers" yes plant
if [ -z "$ap5_bad" ]; then
  ok "AP5 the leftover search lists real en names the folder maps differently"
else
  fail "AP5 leftover search" "$ap5_bad"
fi

# ---------------------------------------------------------------------------
# AP6 the labels setup writes into AGENTS.md, the hubs, the log and the context
# folder are the vocabulary cells the seeds, create-skill and connect read:
# a heading or a folder name setup spells differently is a second index or a
# folder nobody reads.

ap6_bad=""
for pair in "rules index heading:3" "rules index heading:4" "rules index, empty:3" "rules index, empty:4" \
  "rules index, order:3" "rules index, order:4" "doubt mark:3" "doubt mark:4" "log entry:3" \
  "superseded mark (hub):3" "saved discovery:3" "saved discovery:4" "tools and sources:3" \
  "rituals:3" "pains:3" "hub section: context:3" "hub section: facts:3" \
  "hub section: current reading:3" "hub section: recent signals:3" "hub section: history:3" \
  "context folder:3" "people folder:3" "projects folder:3" "meetings folder:3" "reference folder:3" \
  "weekly journal folder:3"; do
  role=${pair%:*}
  col=${pair##*:}
  v=$(cell "$role" "$col")
  [ -n "$v" ] || { ap6_bad="$ap6_bad [no cell $role]"; continue; }
  grep -qF -- "\`$v\`" "$SETUP" || ap6_bad="$ap6_bad [$role ($col): \`$v\`]"
done
glob=$(cell "meetings folder" 3)
grep -qF -- "  - \"$glob**\"" "$SETUP" || ap6_bad="$ap6_bad [rule glob is not the meetings folder]"
if [ -z "$ap6_bad" ]; then
  ok "AP6 setup writes the vocabulary labels and folder names"
else
  fail "AP6 setup labels" "$ap6_bad"
fi

# ---------------------------------------------------------------------------
# AP7 for a person with no direct reports setup strips the stretch between two
# markers of prep-conversation: they are the seed's delimiter lines, and the
# strip leaves the rest of the agenda.

ap7_bad=""
pc="$ROOT/seeds/prep-conversation/SKILL.md"
start=$(grep -o '`<!-- [a-z-]*:start -->`' "$SETUP" | tr -d '`' | head -1)
end=$(grep -o '`<!-- [a-z-]*:end -->`' "$SETUP" | tr -d '`' | head -1)
[ -n "$start" ] && [ -n "$end" ] || ap7_bad="$ap7_bad [setup names no markers]"
if [ -z "$ap7_bad" ]; then
  [ "$(grep -c -xF -- "$start" "$pc")" -eq 1 ] || ap7_bad="$ap7_bad [$start is not one line of the seed]"
  [ "$(grep -c -xF -- "$end" "$pc")" -eq 1 ] || ap7_bad="$ap7_bad [$end is not one line of the seed]"
  before=$(wc -l < "$pc" | tr -d ' ')
  after=$(awk -v s="$start" -v e="$end" '$0 == s { skip = 1 } !skip { print } $0 == e { skip = 0 }' "$pc" | wc -l | tr -d ' ')
  [ "$after" -lt "$before" ] && [ "$after" -gt $((before / 2)) ] || ap7_bad="$ap7_bad [strip leaves $after of $before lines]"
fi
if [ -z "$ap7_bad" ]; then
  ok "AP7 setup strips the direct-report block by the seed's own markers"
else
  fail "AP7 direct-report block" "$ap7_bad"
fi

# ---------------------------------------------------------------------------
# AP8 the 0.7.0 trigger phrases of setup and plantar fire the new skills: each
# quoted phrase of the 0.7.0 description is in the new one, and the plant
# description names the 0.7.0 command, so "plantar" in a request still reaches it.

if git -C "$GIT_ROOT" cat-file -e 318ea9c^{commit} 2>/dev/null; then
  ap8_bad=""
  for pair in setup:setup plant:plantar; do
    new=${pair%%:*}
    old=${pair#*:}
    git -C "$GIT_ROOT" show "318ea9c:skills/$old/SKILL.md" | sed -n 3p | grep -o '"[^"]*"' > "$work/trig"
    [ -s "$work/trig" ] || ap8_bad="$ap8_bad [$old: no phrases]"
    while IFS= read -r q; do
      sed -n 3p "$ROOT/skills/$new/SKILL.md" | grep -qF -- "$q" || ap8_bad="$ap8_bad [$new: $q]"
    done < "$work/trig"
  done
  [ -n "$old_plant" ] && sed -n 3p "$PLANT" | grep -qF -- "/pm-chief-of-staff:$old_plant" \
    || ap8_bad="$ap8_bad [plant description without /pm-chief-of-staff:$old_plant]"
  if [ -z "$ap8_bad" ]; then
    ok "AP8 the 0.7.0 trigger phrases of setup and plantar survive"
  else
    fail "AP8 0.7.0 triggers" "$ap8_bad"
  fi
else
  echo "info  no 318ea9c in the git history: AP8 not measured"
fi

# ---------------------------------------------------------------------------
# AP9 the vocabulary tables setup copies into the folder and plant reads exist
# in the module under the names the two skills give them.

ap9_bad=""
for t in "Fixed names" "Person-facing vocabulary" "Agent-side labels" "Legacy 0.7.0 names"; do
  grep -qxF -- "## $t" "$VOC" || ap9_bad="$ap9_bad [vocabulary has no ## $t]"
done
for t in "Fixed names" "Person-facing vocabulary" "Agent-side labels"; do
  grep -qF -- "\"$t\"" "$SETUP" || ap9_bad="$ap9_bad [setup does not name \"$t\"]"
done
grep -qF -- '"Person-facing vocabulary"' "$PLANT" || ap9_bad="$ap9_bad [plant does not name \"Person-facing vocabulary\"]"
grep -qF -- '"Legacy 0.7.0 names"' "$PLANT" || ap9_bad="$ap9_bad [plant does not name \"Legacy 0.7.0 names\"]"
if [ -z "$ap9_bad" ]; then
  ok "AP9 the vocabulary tables setup and plant name exist"
else
  fail "AP9 vocabulary tables" "$ap9_bad"
fi

rm -rf "$work"
[ "$failures" -eq 0 ] || exit 1
exit 0
