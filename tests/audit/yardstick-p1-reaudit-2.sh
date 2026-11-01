#!/bin/sh
# Probes from re-audit 2 of part 1 of the destination yardstick front (fix
# round 2). Behavior only, pinned by content, accepting paraphrases.
# Run by hand: sh tests/audit/yardstick-p1-reaudit-2.sh < /dev/null
# Optional argument: the plugin root to check (default: this repository).
# A shared module in .claude/skills/_shared/ has no automatic loading: it
# fires only because each consumer skill says to read it at its step. In a
# folder without the plugin the pastable PROMPT is the only source of the
# yardstick, so the module destination of every yardstick (setup, the
# create-skill implementation layer and the two PROMPTs) has to carry that
# order, not only the list of consumers.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

# An exported CDPATH makes cd print the folder inside $(...), which would
# double every path built from ROOT.
unset CDPATH
if [ -n "$1" ]; then
  ROOT=$(cd "$1" && pwd) || exit 1
else
  ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
fi
SETUP="$ROOT/skills/setup/SKILL.md"
CREATE="$ROOT/skills/create-skill/SKILL.md"
P_EN="$ROOT/PROMPT.md"
P_PT="$ROOT/PROMPT.pt-BR.md"
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

for f in "$SETUP" "$CREATE" "$P_EN" "$P_PT"; do
  [ -f "$f" ] || { echo "FAIL  missing $f"; exit 1; }
done

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi

# The module destination of each yardstick.
# setup: the second numbered destination of the yardstick section.
awk '/^### The 4-destination yardstick/ { on = 1; next } on && (/^#/ || /^Format of a rule file/) { exit } on' "$SETUP" \
  | grep -m1 '^2\. ' > "$work/setup-mod"
# create-skill: the implementation-layer paragraph about the shared module.
grep -m1 '^A shared module is ' "$CREATE" > "$work/create-mod"
# PROMPTs: principle 1, from the module path to the rule path.
grep -m1 '^1\. You self-modulate\.' "$P_EN" \
  | awk '{ p = index($0, "_shared/"); if (p == 0) exit; s = substr($0, p); q = index(s, "rules/"); if (q == 0) exit; print substr(s, 1, q - 1) }' > "$work/en-mod"
grep -m1 '^1\. Você se auto-modula\.' "$P_PT" \
  | awk '{ p = index($0, "_shared/"); if (p == 0) exit; s = substr($0, p); q = index(s, "rules/"); if (q == 0) exit; print substr(s, 1, q - 1) }' > "$work/pt-mod"
pre=""
for f in setup-mod create-mod en-mod pt-mod; do
  [ -s "$work/$f" ] || pre="$pre [$f not found]"
done
if [ -n "$pre" ]; then
  echo "FAIL  module destinations not found:$pre"
  rm -rf "$work"
  exit 1
fi

# ---------------------------------------------------------------------------
# R4 (B3 of re-audit 1) the module destination tells the agent that each
# consumer skill says to read the module at its step. Naming the consumers is
# not enough: the module does not load by itself, and a consumer that does
# not point to it loses the discipline silently.

r4=""
en_read='each (consumer )?(skill )?[^.;]{0,30}(tell|tells|telling|say|says|saying|ask|asks|asking)[^.;]{0,25}read|edit(ing)? each consumer skill[^.;]{0,40}read'
pt_read='cada (uma|skill|consumidora)[^.;]{0,30}(mand|diz|dizendo|ped|orient)[^.;]{0,25}(l[eê]|leitura)'
for m in setup-mod create-mod en-mod; do
  grep -q -i -E "$en_read" "$work/$m" || r4="$r4 [$m: no consumer skill says to read the module]"
done
grep -q -i -E "$pt_read" "$work/pt-mod" || r4="$r4 [pt-mod: no consumer skill says to read the module]"
if [ -z "$r4" ]; then
  ok "R4 each consumer skill says to read the shared module at its step"
else
  fail "R4 module read order" "$r4"
fi

rm -rf "$work"
[ "$failures" -eq 0 ]
