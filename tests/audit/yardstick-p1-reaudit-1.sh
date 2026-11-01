#!/bin/sh
# Probes from re-audit 1 of part 1 of the destination yardstick front (fix
# round 1). Behavior only, pinned by content, accepting paraphrases.
# Run by hand: sh tests/audit/yardstick-p1-reaudit-1.sh < /dev/null
# Optional argument: the plugin root to check (default: this repository).
# The four yardsticks (setup, the create-skill triage and the two pastable
# PROMPTs) are the instruction the agent follows when a correction arrives.
# These probes check three things the agent acts on that yardstick-p1.sh does
# not pin: a fact of the period and a source address have a destination of
# their own (not only "do not repeat them"); a rule fired by a subject becomes
# a skill with no line in the rules index; and a check a script can run takes
# the place of the manual line instead of sitting next to it.
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

# The same places yardstick-p1.sh reads.
awk '/^### The 4-destination yardstick/ { on = 1; next } on && (/^#/ || /^Format of a rule file/) { exit } on' "$SETUP" > "$work/setup-y"
awk '/^## Step 1: triage/ { on = 1; next } on && (/^#/ || /^Say which destination/) { exit } on' "$CREATE" > "$work/create-y"
grep -m1 '^1\. You self-modulate\.' "$P_EN" > "$work/en-p1"
grep -m1 '^1\. Você se auto-modula\.' "$P_PT" > "$work/pt-p1"
pre=""
for f in setup-y create-y en-p1 pt-p1; do
  [ -s "$work/$f" ] || pre="$pre [$f not found]"
done
if [ -n "$pre" ]; then
  echo "FAIL  places not found:$pre"
  rm -rf "$work"
  exit 1
fi
sed 's/.*The destination yardstick/The destination yardstick/' "$work/en-p1" > "$work/en-y"
sed 's/.*A régua de destino/A régua de destino/' "$work/pt-p1" > "$work/pt-y"
grep -m1 'AGENTS.md, last\*\*' "$work/setup-y" > "$work/setup-m"
grep -m1 "^\* \*\*The folder's instruction file, last\*\*" "$work/create-y" > "$work/create-m"
sed 's/.*and the AGENTS.md last/the AGENTS.md last/; s/ When I correct you.*//' "$work/en-p1" > "$work/en-m"
sed 's/.*e o AGENTS.md por último/o AGENTS.md por último/; s/ Quando eu te corrigir.*//' "$work/pt-p1" > "$work/pt-m"

# joined FILE: FILE as one line.
joined() { tr '\n' ' ' < "$1"; }

# clauses: one clause per line (a period followed by a space and a capital
# letter, or a semicolon, ends a clause).
clauses() {
  awk '{ s = $0; while (match(s, /(\. [A-Z]|; )/)) { print substr(s, 1, RSTART); s = substr(s, RSTART + 2) } print s }'
}

# between FILE A B: the text of FILE (joined) from the first A to the first B
# after it; empty when either is missing.
between() {
  joined "$1" | awk -v a="$2" -v b="$3" '{
    p = index($0, a); if (p == 0) exit
    s = substr($0, p); q = index(s, b); if (q == 0) exit
    print substr(s, 1, q - 1) }'
}

# ---------------------------------------------------------------------------
# R1 (D1 of the audit) the manual destination of the four yardsticks sends a
# fact of the period to CRITICAL_FACTS.md and a source address to the
# navigation as a destination, not only as a label of what not to repeat. The
# round text said "nothing that CRITICAL_FACTS.md (facts of the period) ...
# already carries", which lets a new fact of the period into the manual.

r1=""
en_fact='fact of the period[^.();]{0,20}to[^.();]{0,12}CRITICAL_FACTS'
en_src='source address[^.();]{0,20}to[^.();]{0,12}navigation'
pt_fact='fato do período[^.();]{0,20}(pr[oa]|para)[^.();]{0,12}CRITICAL_FACTS'
pt_src='endereço de fonte[^.();]{0,20}(pr[oa]|para)[^.();]{0,12}navigation'
for m in setup-m create-m en-m; do
  joined "$work/$m" | grep -q -i -E "$en_fact" || r1="$r1 [$m: no destination for a fact of the period]"
  joined "$work/$m" | grep -q -i -E "$en_src" || r1="$r1 [$m: no destination for a source address]"
done
joined "$work/pt-m" | grep -q -i -E "$pt_fact" || r1="$r1 [pt-m: no destination for a fact of the period]"
joined "$work/pt-m" | grep -q -i -E "$pt_src" || r1="$r1 [pt-m: no destination for a source address]"
if [ -z "$r1" ]; then
  ok "R1 a fact of the period and a source address have a destination outside the manual"
else
  fail "R1 fact and source destinations" "$r1"
fi

# ---------------------------------------------------------------------------
# R2 (the decision on the subject rule) in the four yardsticks, the clause
# that sets user-invocable: false makes the subject rule a skill with no line
# in the rules index. A line in the index would load, in every turn, what the
# skill description already carries.

r2=""
for y in setup-y create-y en-y pt-y; do
  joined "$work/$y" | clauses | grep -F 'user-invocable: false' > "$work/$y-c"
  if [ ! -s "$work/$y-c" ]; then
    r2="$r2 [$y: no clause with user-invocable: false]"
    continue
  fi
  grep -q -F 'skill' "$work/$y-c" || r2="$r2 [$y: the subject rule is not a skill]"
  case $y in
    pt-y) grep -q -E '(sem|nem) (passos nem )?linha no índice' "$work/$y-c" || r2="$r2 [$y: the subject rule may take an index line]" ;;
    *) grep -q -E '(no|without|or) (index line|line in the rules index)' "$work/$y-c" || r2="$r2 [$y: the subject rule may take an index line]" ;;
  esac
done
if [ -z "$r2" ]; then
  ok "R2 a subject rule becomes a skill with no index line"
else
  fail "R2 subject rule" "$r2"
fi

# ---------------------------------------------------------------------------
# R3 (done item 2) the check a script can run takes the place of the line,
# in the script question of the four yardsticks. Without it, setup's "1
# destination among 4" sends the same correction to the manual as well.

r3=""
en_inst='(instead of|in place of|rather than) (a |the )?line|not (as )?a line'
pt_inst='(no lugar|em vez) d[ae] linha|não (como )?linha'
between "$work/setup-y" "can a script fail it?" "skill that owns" > "$work/setup-q"
between "$work/create-y" "can a script fail it?" "**Adjustment to a skill" > "$work/create-q"
between "$work/en-y" "whether a script can fail it" "skill that owns it" > "$work/en-q"
between "$work/pt-y" "se um script consegue reprovar" "skill dona dele" > "$work/pt-q"
for q in setup-q create-q en-q; do
  if [ ! -s "$work/$q" ]; then
    r3="$r3 [$q: script question not found before the first destination]"
  else
    grep -q -i -E "$en_inst" "$work/$q" || r3="$r3 [$q: the check does not replace the line]"
  fi
done
if [ ! -s "$work/pt-q" ]; then
  r3="$r3 [pt-q: script question not found before the first destination]"
else
  grep -q -i -E "$pt_inst" "$work/pt-q" || r3="$r3 [pt-q: the check does not replace the line]"
fi
if [ -z "$r3" ]; then
  ok "R3 a check a script can run replaces the manual line"
else
  fail "R3 script check instead of the line" "$r3"
fi

rm -rf "$work"
[ "$failures" -eq 0 ]
