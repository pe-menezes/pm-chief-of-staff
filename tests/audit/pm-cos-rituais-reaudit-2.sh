#!/bin/sh
# Audit probe of the optional-rituals front, reaudit of fix round 2 (parts 1 and 2).
#
# Run: sh tests/audit/pm-cos-rituais-reaudit-2.sh < /dev/null
#
# Cases:
#   RQ1 the size gate case RG1 of tests/audit/pm-cos-rituais-p1.sh decides
#       on its own fixture whatever CLAUDE_PROJECT_DIR the caller exports
#       (the size gate prefers that variable to its working directory): RG1
#       passes with the variable at the repository root, which is not a
#       Chief of Staff folder, and at an empty folder.
#   RQ2 no seed glosses a person-facing path with "in English": plant swaps
#       each path of the vocabulary's person-facing table for the folder's
#       name, so a gloss next to it reads wrong in any other language
#       (`contexto/dores.md` in English).
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

# An exported CDPATH makes cd print the folder inside $(...), which would
# double every path built from ROOT.
unset CDPATH
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
VOC="$ROOT/modules/vocabulary.md"
P1="$ROOT/tests/audit/pm-cos-rituais-p1.sh"
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi

for f in "$VOC" "$P1"; do
  [ -f "$f" ] || { echo "FAIL  missing $f"; rm -rf "$work"; exit 1; }
done

# ---------------------------------------------------------------------------
# RQ1 RG1 ignores the caller's CLAUDE_PROJECT_DIR.

rq1_bad=""
mkdir -p "$work/empty"
for dir in "$ROOT" "$work/empty"; do
  CLAUDE_PROJECT_DIR="$dir" sh "$P1" < /dev/null > "$work/p1.out" 2>&1
  if ! grep -q '^ok    RG1' "$work/p1.out"; then
    line=$(grep 'RG1' "$work/p1.out" | head -n 1)
    rq1_bad="$rq1_bad [with CLAUDE_PROJECT_DIR=$dir: ${line:-no RG1 line}]"
  fi
done
if [ -z "$rq1_bad" ]; then
  ok "RQ1 RG1 decides on its fixture with CLAUDE_PROJECT_DIR at the repository root and at an empty folder"
else
  fail "RQ1 RG1 depends on the caller's CLAUDE_PROJECT_DIR" "$rq1_bad"
fi

# ---------------------------------------------------------------------------
# RQ2 no seed glosses a swappable path with "in English".

# The en cell of every person-facing row that is a path (holds a /).
awk -F'|' '
  /^## Person-facing vocabulary/ { on = 1; next }
  /^## / { on = 0 }
  on {
    v = $3; gsub(/^ *`|` *$/, "", v)
    if (v ~ /\//) print v
  }' "$VOC" > "$work/paths"
rq2_bad=""
if [ ! -s "$work/paths" ]; then
  rq2_bad="$rq2_bad [no path read from the vocabulary]"
else
  n=0
  for seed in "$ROOT"/seeds/*/SKILL.md; do
    n=$((n + 1))
    while IFS= read -r p; do
      if grep -q -F -- "\`$p\` in English" "$seed" || grep -q -F -- "$p in English" "$seed"; then
        rq2_bad="$rq2_bad [${seed#"$ROOT"/} glosses $p with in English]"
      fi
    done < "$work/paths"
  done
  [ "$n" -gt 0 ] || rq2_bad="$rq2_bad [no seed found]"
fi
if [ -z "$rq2_bad" ]; then
  ok "RQ2 no seed glosses a person-facing path with in English, so the plant swap reads right in any language"
else
  fail "RQ2 a seed glosses a swappable path" "$rq2_bad"
fi

rm -rf "$work"
[ "$failures" -eq 0 ]
