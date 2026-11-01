#!/bin/sh
# Probes from the audit of part 1 of the destination yardstick front (the
# manual last). Behavior only, pinned by content.
# Run by hand: sh tests/audit/yardstick-p1.sh < /dev/null
# Optional argument: the plugin root to check (default: this repository).
# setup, create-skill and the two pastable PROMPTs are instructions the agent
# follows when a change request or a correction arrives, so the probes check
# the cross-file contract it acts on: the five places give the destinations in
# one order (skill, module, rule, manual last); the script question comes
# before the destinations and never lets the agent create a hook alone; the
# manual destination carries the double test and the format of the line, and a
# rule fired by a subject becomes a hidden skill; the sentence setup sends "copied
# literally" into the generated AGENTS.md is the CLAUDE.md bridge sentence;
# the rule destination keeps the rules index with the vocabulary's order
# sentence; the who-they-are bound reaches both PROMPTs; and connect swaps the
# removed command for the one the vocabulary maps it to, only with the ok.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

# An exported CDPATH makes cd print the folder inside $(...), which would
# double every path built from ROOT.
unset CDPATH
if [ -n "$1" ]; then
  ROOT=$(cd "$1" && pwd) || exit 1
else
  ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
fi
VOC="$ROOT/modules/vocabulary.md"
CAPS="$ROOT/modules/capabilities.md"
SETUP="$ROOT/skills/setup/SKILL.md"
CREATE="$ROOT/skills/create-skill/SKILL.md"
CONNECT="$ROOT/skills/connect/SKILL.md"
P_EN="$ROOT/PROMPT.md"
P_PT="$ROOT/PROMPT.pt-BR.md"
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

for f in "$VOC" "$CAPS" "$SETUP" "$CREATE" "$CONNECT" "$P_EN" "$P_PT"; do
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

# cell ROLE COLUMN: a cell of the vocabulary's person-facing table, without
# the backticks (column 3 is en, 4 is pt-BR).
cell() {
  awk -F'|' -v role="$1" -v col="$2" '
    /^## Person-facing vocabulary/ { on = 1; next }
    /^## / { on = 0 }
    on {
      r = $2; gsub(/^ +| +$/, "", r)
      if (r == role) { v = $col; sub(/^ *`/, "", v); sub(/` *$/, "", v); print v; exit }
    }' "$VOC"
}

# inorder FILE A B C ...: every anchor is in FILE (joined into one line) and
# the first occurrence of each comes after the first occurrence of the one
# before it. Prints the anchors that are missing or out of order.
inorder() {
  file=$1
  shift
  tr '\n' ' ' < "$file" > "$work/joined"
  : > "$work/anchors"
  for a in "$@"; do
    printf '%s\n' "$a" >> "$work/anchors"
  done
  awk '
    NR == FNR { a[++n] = $0; next }
    { t = t $0 }
    END {
      prev = 0
      for (i = 1; i <= n; i++) {
        p = index(t, a[i])
        if (p == 0) { printf " [missing: %s]", a[i]; continue }
        if (p <= prev) printf " [out of order: %s]", a[i]
        prev = p
      }
    }' "$work/anchors" "$work/joined"
}

# has FILE TEXT...: prints each TEXT that FILE (joined into one line) lacks.
has() {
  file=$1
  shift
  tr '\n' ' ' < "$file" > "$work/joined-has"
  for t in "$@"; do
    grep -q -F -- "$t" "$work/joined-has" || printf ' [lacks: %s]' "$t"
  done
}

# The five places. Setup's principle 1 and the yardstick section; the triage
# of create-skill; principle 1 of each PROMPT.
grep -m1 '^1\. \*\*The system self-modulates' "$SETUP" > "$work/setup-p1"
awk '/^### The 4-destination yardstick/ { on = 1; next } on && (/^#/ || /^Format of a rule file/) { exit } on' "$SETUP" > "$work/setup-y"
awk '/^## Step 1: triage/ { on = 1; next } on && (/^#/ || /^Say which destination/) { exit } on' "$CREATE" > "$work/create-y"
grep -m1 '^1\. You self-modulate\.' "$P_EN" > "$work/en-p1"
grep -m1 '^1\. Você se auto-modula\.' "$P_PT" > "$work/pt-p1"
pre=""
for f in setup-p1 setup-y create-y en-p1 pt-p1; do
  [ -s "$work/$f" ] || pre="$pre [$f not found]"
done
if [ -n "$pre" ]; then
  echo "FAIL  places not found:$pre"
  rm -rf "$work"
  exit 1
fi
# The yardstick part of each PROMPT principle (after its opening sentence).
sed 's/.*The destination yardstick/The destination yardstick/' "$work/en-p1" > "$work/en-y"
sed 's/.*A régua de destino/A régua de destino/' "$work/pt-p1" > "$work/pt-y"
# The manual destination of each place, to the end of that destination.
grep -m1 'AGENTS.md, last\*\*' "$work/setup-y" > "$work/setup-m"
grep -m1 "^\* \*\*The folder's instruction file, last\*\*" "$work/create-y" > "$work/create-m"
sed 's/.*and the AGENTS.md last/the AGENTS.md last/; s/ When I correct you.*//' "$work/en-p1" > "$work/en-m"
sed 's/.*e o AGENTS.md por último/o AGENTS.md por último/; s/ Quando eu te corrigir.*//' "$work/pt-p1" > "$work/pt-m"

# ---------------------------------------------------------------------------
# Y1 the five places give the destinations in one order: the skill that owns
# the artifact, the shared module, the rule with paths:, the manual last. A
# place left in the old order (manual first) sends a correction to the
# manual before testing the homes that cost nothing per turn.

y1=""
r=$(inorder "$work/setup-p1" "the right skill" "the module shared between skills" "the rule in \`.claude/rules/\`" "last, the AGENTS.md"); [ -z "$r" ] || y1="$y1 [setup principle 1:$r]"
r=$(inorder "$work/setup-y" "skill that owns" "\`.claude/skills/_shared/" "\`.claude/rules/{topic}.md\`" "AGENTS.md, last"); [ -z "$r" ] || y1="$y1 [setup yardstick:$r]"
r=$(inorder "$work/create-y" "**Adjustment to a skill that already exists**" "\`.claude/skills/_shared/" "**Situational rule" "**The folder's instruction file, last**"); [ -z "$r" ] || y1="$y1 [create-skill triage:$r]"
r=$(inorder "$work/en-p1" "the right skill" "the file shared between skills" "the rule or" "last, the AGENTS.md"); [ -z "$r" ] || y1="$y1 [PROMPT.md opening:$r]"
r=$(inorder "$work/en-y" "skill that owns it" "\`.claude/skills/_shared/" "\`.claude/rules/{topic}.md\`" "the AGENTS.md last"); [ -z "$r" ] || y1="$y1 [PROMPT.md yardstick:$r]"
r=$(inorder "$work/pt-p1" "a skill certa" "o arquivo compartilhado entre skills" "a regra ou" "por último, o AGENTS.md"); [ -z "$r" ] || y1="$y1 [PROMPT.pt-BR.md opening:$r]"
r=$(inorder "$work/pt-y" "skill dona dele" "\`.claude/skills/_shared/" "\`.claude/rules/{tema}.md\`" "o AGENTS.md por último"); [ -z "$r" ] || y1="$y1 [PROMPT.pt-BR.md yardstick:$r]"
if [ -z "$y1" ]; then
  ok "Y1 the five places give skill, module, rule and the manual last"
else
  fail "Y1 destination order" "$y1"
fi

# ---------------------------------------------------------------------------
# Y2 the script question comes before the first destination in the four
# yardsticks, and the agent proposes the check without creating or changing a
# hook alone (a hook is persistent configuration).

y2=""
r=$(inorder "$work/setup-y" "can a script fail it?" "skill that owns"); [ -z "$r" ] || y2="$y2 [setup:$r]"
r=$(has "$work/setup-y" "never creating or changing a hook yourself"); [ -z "$r" ] || y2="$y2 [setup:$r]"
r=$(inorder "$work/create-y" "can a script fail it?" "**Adjustment to a skill that already exists**"); [ -z "$r" ] || y2="$y2 [create-skill:$r]"
r=$(has "$work/create-y" "never creating or changing a hook yourself"); [ -z "$r" ] || y2="$y2 [create-skill:$r]"
r=$(inorder "$work/en-y" "whether a script can fail it" "skill that owns it"); [ -z "$r" ] || y2="$y2 [PROMPT.md:$r]"
r=$(has "$work/en-y" "never creating or changing a hook yourself"); [ -z "$r" ] || y2="$y2 [PROMPT.md:$r]"
r=$(inorder "$work/pt-y" "se um script consegue reprovar" "skill dona dele"); [ -z "$r" ] || y2="$y2 [PROMPT.pt-BR.md:$r]"
r=$(has "$work/pt-y" "sem criar nem mudar hook sozinho"); [ -z "$r" ] || y2="$y2 [PROMPT.pt-BR.md:$r]"
if [ -z "$y2" ]; then
  ok "Y2 the script question comes first and never creates a hook alone"
else
  fail "Y2 script question" "$y2"
fi

# ---------------------------------------------------------------------------
# Y3 (risk: the CLAUDE.md bridge never receives a rule) setup tells the
# generated AGENTS.md to copy literally "the last sentence of the Nth
# destination"; that sentence exists and is the bridge rule. Reordering the
# destinations or appending a sentence to that one points the copy elsewhere.
# The PROMPTs and create-skill keep the same rule.

y3=""
ord=$(sentences < "$work/setup-y" | grep -F 'copied literally' | grep -o -E 'last sentence of the (first|second|third|fourth) destination' | head -1 | awk '{ print $5 }')
case "$ord" in
  first) n=1 ;; second) n=2 ;; third) n=3 ;; fourth) n=4 ;; *) n=0 ;;
esac
if [ "$n" -eq 0 ]; then
  y3="$y3 [setup names no destination for the literal copy]"
else
  grep -E '^([0-9]+\. |\* )' "$work/setup-y" | sed -n "${n}p" > "$work/item"
  last=$(sentences < "$work/item" | awk 'NF' | tail -1)
  case "$last" in
    *'`CLAUDE.md`'*'never receives a rule'*) ;;
    *) y3="$y3 [the $ord destination ends with: $last]" ;;
  esac
fi
r=$(has "$work/create-m" "never receives a rule"); [ -z "$r" ] || y3="$y3 [create-skill manual destination:$r]"
grep -q -F 'that this bridge never receives a rule' "$P_EN" || y3="$y3 [PROMPT.md lost the bridge rule]"
grep -q -F 'de que essa ponte nunca recebe regra' "$P_PT" || y3="$y3 [PROMPT.pt-BR.md lost the bridge rule]"
if [ -z "$y3" ]; then
  ok "Y3 the literal copy is the CLAUDE.md bridge sentence"
else
  fail "Y3 bridge sentence" "$y3"
fi

# ---------------------------------------------------------------------------
# Y4 (risk: the rules index, without which a rule is invisible to Codex) the
# rule destination of setup and of both PROMPTs writes the index line with
# the file and carries the vocabulary's order sentence, in the column of the
# text's language (setup carries both).

y4=""
o_en=$(cell "rules index, order" 3)
o_pt=$(cell "rules index, order" 4)
h_en=$(cell "rules index heading" 3)
h_pt=$(cell "rules index heading" 4)
[ -n "$o_en" ] && [ -n "$o_pt" ] && [ -n "$h_en" ] && [ -n "$h_pt" ] || y4="$y4 [vocabulary rows for the rules index not found]"
grep -m1 '`.claude/rules/{topic}.md`' "$work/setup-y" > "$work/setup-r"
r=$(has "$work/setup-r" "Codex" "rules index" "$o_en" "$o_pt"); [ -z "$r" ] || y4="$y4 [setup rule destination:$r]"
r=$(has "$work/en-y" "Codex" "in the same step" "$h_en" "$o_en"); [ -z "$r" ] || y4="$y4 [PROMPT.md:$r]"
r=$(has "$work/pt-y" "Codex" "no mesmo passo" "$h_pt" "$o_pt"); [ -z "$r" ] || y4="$y4 [PROMPT.pt-BR.md:$r]"
if [ -z "$y4" ]; then
  ok "Y4 the rule destination writes the index line with the order sentence"
else
  fail "Y4 rules index" "$y4"
fi

# ---------------------------------------------------------------------------
# Y5 the manual destination of the four yardsticks takes only what passes the
# double test and keeps the line without the story and without what another
# file carries. A rule fired by the subject of the conversation (paths: cannot
# load it, and a rule file without paths: loads in every session) becomes a
# skill hidden from the / menu whose description names the subject, so only
# the description sits in context; the manual gets no pointer to it.

y5=""
r=$(has "$work/setup-y" "user-invocable: false" "description names the subject"); [ -z "$r" ] || y5="$y5 [setup subject rule:$r]"
r=$(has "$work/create-y" "user-invocable: false" "description names the subject"); [ -z "$r" ] || y5="$y5 [create-skill subject rule:$r]"
r=$(has "$work/en-y" "user-invocable: false" "description names the subject"); [ -z "$r" ] || y5="$y5 [PROMPT.md subject rule:$r]"
r=$(has "$work/pt-y" "user-invocable: false" "descrição nomeia o assunto"); [ -z "$r" ] || y5="$y5 [PROMPT.pt-BR.md subject rule:$r]"
for m in setup-m create-m en-m pt-m; do
  grep -q -i -E 'pointer|ponteiro' "$work/$m" && y5="$y5 [$m: the manual still takes a pointer]"
done
r=$(has "$work/setup-m" "almost every turn" "costly" "no story" "the date" "\`CRITICAL_FACTS.md\`" "navigation" "another repository"); [ -z "$r" ] || y5="$y5 [setup:$r]"
r=$(has "$work/create-m" "almost every turn" "costly" "no story" "the date" "\`CRITICAL_FACTS.md\`" "navigation" "another repository"); [ -z "$r" ] || y5="$y5 [create-skill:$r]"
r=$(has "$work/en-m" "almost every turn" "costly to forget" "no story" "the date" "CRITICAL_FACTS.md" "navigation.md" "another repository"); [ -z "$r" ] || y5="$y5 [PROMPT.md:$r]"
r=$(has "$work/pt-m" "quase todo turno" "custa caro esquecer" "sem a história" "a data" "CRITICAL_FACTS.md" "navigation.md" "outro repositório"); [ -z "$r" ] || y5="$y5 [PROMPT.pt-BR.md:$r]"
if [ -z "$y5" ]; then
  ok "Y5 a subject rule becomes a hidden skill named by its subject, and the manual keeps the double test and the line format"
else
  fail "Y5 manual destination" "$y5"
fi

# ---------------------------------------------------------------------------
# Y6 the who-they-are bound and the sentence on what the manual keeps reach
# both PROMPTs (setup changes reach the pastable prompt, repository guide).

y6=""
grep -q -F 'who they are and what they cover (from the discovery, in at most 6 lines' "$SETUP" || y6="$y6 [setup lost the 6-line bound]"
grep -q -F 'departs from the default' "$SETUP" || y6="$y6 [setup lost the sentence on what the manual keeps]"
grep -q -F 'who I am and what I cover, in at most 6 lines' "$P_EN" || y6="$y6 [PROMPT.md lacks the 6-line bound]"
grep -q -F 'departs from the default' "$P_EN" || y6="$y6 [PROMPT.md lacks the sentence on what the manual keeps]"
grep -q -F 'quem eu sou e o que eu cubro, em no máximo 6 linhas' "$P_PT" || y6="$y6 [PROMPT.pt-BR.md lacks the 6-line bound]"
grep -q -F 'foge do padrão' "$P_PT" || y6="$y6 [PROMPT.pt-BR.md lacks the sentence on what the manual keeps]"
if [ -z "$y6" ]; then
  ok "Y6 both PROMPTs carry the who-they-are bound of setup"
else
  fail "Y6 who-they-are bound" "$y6"
fi

# ---------------------------------------------------------------------------
# Y7 (risk: connect edits a file of the person) on a rerun, connect swaps the
# removed command for the one the vocabulary maps it to, which is the command
# a fresh module points to; it shows the line before and after, swaps only
# with the ok, and keeps the line-by-line rule.

y7=""
awk '/^## Running again/ { on = 1; next } on && /^## / { exit } on' "$CONNECT" > "$work/rerun"
old=$(awk -F'|' '/^## Commands 0\.7\.0 to 0\.8\.0/ { on = 1; next } /^## / { on = 0 } on && $2 ~ /pm-chief-of-staff:conectar/ { v = $2; gsub(/^ *`|` *$/, "", v); print v; exit }' "$VOC")
new=$(awk -F'|' '/^## Commands 0\.7\.0 to 0\.8\.0/ { on = 1; next } /^## / { on = 0 } on && $2 ~ /pm-chief-of-staff:conectar/ { v = $3; gsub(/^ *`|` *$/, "", v); print v; exit }' "$VOC")
if [ -z "$old" ] || [ -z "$new" ]; then
  y7="$y7 [vocabulary command row for connect not found]"
else
  r=$(has "$work/rerun" "\`$old\`" "\`$new\` in its place" "before and after" "only with their ok" "never rewrite from scratch"); [ -z "$r" ] || y7="$y7 [connect Running again:$r]"
  grep -F 'New or lost tool' "$CAPS" | grep -q -F "\`$new\`" || y7="$y7 [the module template does not point to $new]"
fi
if [ -z "$y7" ]; then
  ok "Y7 connect swaps the removed command for the mapped one, only with the ok"
else
  fail "Y7 connect command swap" "$y7"
fi

rm -rf "$work"
[ "$failures" -eq 0 ]
