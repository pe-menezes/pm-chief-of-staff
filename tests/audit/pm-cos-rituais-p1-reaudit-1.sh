#!/bin/sh
# Probes from the reaudit of the optional-routines front, part 1, fix round 1.
# Behavior only, pinned by content.
# Run by hand: sh tests/audit/pm-cos-rituais-p1-reaudit-1.sh
# setup, the seeds and the PROMPTs are instructions, so the probes check the
# contracts the agent follows at run time:
#   RR1 (risk code: the consumer check) setup plants capabilities.md and
#       write-gate.md with their consumer line as it stands in the plugin,
#       even naming a routine the person did not pick, and plant never
#       writes a module's consumer line, so a routine planted later is still
#       on the line the consumer check reads;
#   RR2 (risk code: date boundary) the expiry of a dated prospective item
#       covers the weekly journal as well as the hub, in setup's write rules
#       and both PROMPTs, in the journal folder of each language, and the
#       person settles it;
#   RR3 close-week step 10 still promotes the week's last seed for tomorrow,
#       and a week with no such line (no day closed) has an explicit way out:
#       a first task from the step 9 calls, or nothing, said in 1 line;
#   RR4 (risk code: the standalone close-day condition) close-day alone
#       decides by content (today's block holds no numbered 3, including the
#       empty block it created earlier today), a second run the same day only
#       adds to that block and never writes a second one, and a week with no
#       journal gets it created first in the journal folder with no task
#       migrated.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

# An exported CDPATH makes cd print the folder inside $(...), which would
# double every path built from ROOT.
unset CDPATH
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
VOC="$ROOT/modules/vocabulary.md"
SETUP="$ROOT/skills/setup/SKILL.md"
PLANT="$ROOT/skills/plant/SKILL.md"
DAY="$ROOT/seeds/close-day/SKILL.md"
WEEK="$ROOT/seeds/close-week/SKILL.md"
GATE="$ROOT/modules/write-gate.md"
CAP="$ROOT/modules/capabilities.md"
P_EN="$ROOT/PROMPT.md"
P_PT="$ROOT/PROMPT.pt-BR.md"
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi
work=$(cd "$work" && pwd -P)

for f in "$VOC" "$SETUP" "$PLANT" "$DAY" "$WEEK" "$GATE" "$CAP" "$P_EN" "$P_PT"; do
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

# sentences FILE: the text of FILE, one sentence per line.
sentences() {
  awk '{ gsub(/\. /, ".\n"); print }' "$1"
}

j_en=$(cell "weekly journal folder" 3)
j_pt=$(cell "weekly journal folder" 4)
day_block=$(cell "today's 3 block" 3)
seed_lbl=$(cell "seed for tomorrow" 3)
refl_lbl=$(cell "reflection" 3)
bal_lbl=$(cell "balance" 3)
bal_lbl=${bal_lbl%% *}
if [ -z "$j_en" ] || [ -z "$j_pt" ] || [ -z "$day_block" ] || [ -z "$seed_lbl" ] || [ -z "$refl_lbl" ] || [ -z "$bal_lbl" ]; then
  echo "FAIL  vocabulary: a person-facing cell this probe reads is missing"
  rm -rf "$work"
  exit 1
fi

# ---------------------------------------------------------------------------
# RR1 the planted modules keep the plugin's consumer line.

awk '/^## Plant the seeds/ { on = 1 } on' "$SETUP" > "$work/plantstep"
sentences "$work/plantstep" | grep -F '`capabilities.md`' | grep -F '`write-gate.md`' | grep -F '`**Loaded by:**`' > "$work/rr1"
rr1_bad=""
[ -s "$work/plantstep" ] || rr1_bad="$rr1_bad [setup has no Plant the seeds section]"
if [ ! -s "$work/rr1" ]; then
  rr1_bad="$rr1_bad [no sentence binds the consumer line to both planted modules]"
else
  grep -q 'as it stands in the plugin' "$work/rr1" || rr1_bad="$rr1_bad [the line is not kept as in the plugin]"
  grep -q 'did not pick' "$work/rr1" || rr1_bad="$rr1_bad [not kept when it names a routine not picked]"
  grep -q 'never take a name out' "$work/rr1" || rr1_bad="$rr1_bad [nothing forbids taking a name out of the line]"
fi
# The line only matters because the plugin's lines name routines that setup
# may leave out; and plant must not be the one to rewrite it.
head -1 "$CAP" | grep -q -F '`start-day`' || rr1_bad="$rr1_bad [capabilities.md line does not name start-day]"
head -1 "$GATE" | grep -q -F '`close-day`' && head -1 "$GATE" | grep -q -F '`close-week`' || rr1_bad="$rr1_bad [write-gate.md line does not name close-day and close-week]"
# plant names the label only in its leftover search; a sentence of plant that
# names the label with a verb that changes the line is plant rewriting it.
sentences "$PLANT" | grep -E 'Loaded by|Carregado por' \
  | grep -i -E '(^|[^a-z])(add|adds|remove|removes|take|takes|edit|edits|rewrite|rewrites|append|appends|insert|inserts|drop|drops)([^a-z]|$)' > "$work/plant-line"
[ -s "$work/plant-line" ] && rr1_bad="$rr1_bad [plant changes a module consumer line: $(head -1 "$work/plant-line" | cut -c1-160)]"
if [ -z "$rr1_bad" ]; then
  ok "RR1 setup plants both modules with the plugin's consumer line, routines not picked included, and plant never rewrites it"
else
  fail "RR1 planted consumer line" "$rr1_bad"
fi

# ---------------------------------------------------------------------------
# RR2 the expiry of a dated prospective item covers the journal too.
# scope FILE SUBJECT_HUB SUBJECT_JOURNAL FOLDER READ_RE DECIDE: the sentence
# with "prospective item" (or its pt-BR form) names, before "whose"/"cuja",
# the hub, the journal and the journal folder; is read when either is read;
# and leaves the decision to the person.

awk '/^Write rules the generated AGENTS.md carries/ { on = 1; next } /^Session routine the generated AGENTS.md carries/ { on = 0 } on' "$SETUP" > "$work/rules"
grep 'prospective item' "$work/rules" > "$work/s-setup"
grep -m1 '^Hub head' "$P_EN" | sentences /dev/stdin | grep 'prospective item' > "$work/s-pen"
grep -m1 '^Cabeça de hub' "$P_PT" | sentences /dev/stdin | grep 'Item prospectivo' > "$work/s-ppt"
rr2_bad=""
scope() {
  f="$work/$1"
  if [ ! -s "$f" ]; then rr2_bad="$rr2_bad [$1: no prospective item sentence]"; return; fi
  subj=$(sed -E "s/ ($6).*//" "$f")
  case "$subj" in *"$2"*) ;; *) rr2_bad="$rr2_bad [$1: subject has no '$2']" ;; esac
  case "$subj" in *"$3"*) ;; *) rr2_bad="$rr2_bad [$1: subject has no '$3' (the journal is left out)]" ;; esac
  case "$subj" in *"$4"*) ;; *) rr2_bad="$rr2_bad [$1: subject does not name the journal folder $4]" ;; esac
  grep -q -E -- "$5" "$f" || rr2_bad="$rr2_bad [$1: not an open question when the journal is read]"
  grep -q -F -- "$7" "$f" || rr2_bad="$rr2_bad [$1: the person does not settle it ('$7')]"
}
scope s-setup 'in a hub' 'weekly journal' "\`$j_en\`" 'hub or (weekly )?journal is read' 'whose' 'the person settles it'
scope s-pen 'in a hub' 'weekly journal' "in $j_en" 'hub or (weekly )?journal is read' 'whose' 'and I decide'
scope s-ppt 'num hub' 'diário semanal' "em $j_pt" 'hub ou diário é lido' 'cuja' 'e eu decido'
if [ -z "$rr2_bad" ]; then
  ok "RR2 the dated prospective item expires on reading a hub or a weekly journal, in setup and both PROMPTs, and the person settles it"
else
  fail "RR2 journal item expiry" "$rr2_bad"
fi

# ---------------------------------------------------------------------------
# RR3 close-week step 10 with no seed for tomorrow in the week.

grep -m1 '^10\. \*\*Set up next week\*\*' "$WEEK" > "$work/week10"
rr3_bad=""
if [ ! -s "$work/week10" ]; then
  rr3_bad="$rr3_bad [close-week step 10 not found]"
else
  sentences "$work/week10" > "$work/w10s"
  grep -F "last \`$seed_lbl\`" "$work/w10s" | grep -q 'Promote' || rr3_bad="$rr3_bad [step 10 no longer promotes the week's last $seed_lbl]"
  grep -F "no \`$seed_lbl\` line" "$work/w10s" > "$work/w10none"
  if [ ! -s "$work/w10none" ]; then
    rr3_bad="$rr3_bad [no way out for a week with no $seed_lbl line]"
  else
    grep -q 'step 9 calls' "$work/w10none" || rr3_bad="$rr3_bad [the way out does not draw on the step 9 calls]"
    grep -q 'promote nothing' "$work/w10none" || rr3_bad="$rr3_bad [the way out cannot promote nothing]"
    grep -q 'say which in 1 line' "$work/w10none" || rr3_bad="$rr3_bad [the way out is silent]"
  fi
fi
if [ -z "$rr3_bad" ]; then
  ok "RR3 close-week promotes the last seed for tomorrow, and a week with none takes the step 9 calls or nothing, said in 1 line"
else
  fail "RR3 close-week with no seed for tomorrow" "$rr3_bad"
fi

# ---------------------------------------------------------------------------
# RR4 close-day alone decides by the block's content and never doubles it.

grep -m1 '^It also works alone' "$DAY" > "$work/alone"
rr4_bad=""
if [ ! -s "$work/alone" ]; then
  rr4_bad="$rr4_bad [close-day has no standalone paragraph]"
else
  sentences "$work/alone" > "$work/alone-s"
  # The condition: the sentence that carries the skip.
  grep -m1 'skip steps' "$work/alone-s" > "$work/cond"
  grep -q 'holds no numbered 3' "$work/cond" || rr4_bad="$rr4_bad [the skip is not decided by the numbered 3]"
  grep -q 'with no 3 inside that this close created' "$work/cond" || rr4_bad="$rr4_bad [the empty block this close created does not count as no 3]"
  grep -q 'skip steps 2 and 4' "$work/cond" || rr4_bad="$rr4_bad [steps 2 and 4 are not skipped]"
  grep -q -F -- "$bal_lbl" "$work/cond" || rr4_bad="$rr4_bad [the $bal_lbl line is not skipped]"
  # Where the reflection and the seed go: the vocabulary's block and labels.
  grep -F -- "$refl_lbl" "$work/alone-s" | grep -F -- "$seed_lbl" | grep -q -F -- "$day_block" \
    || rr4_bad="$rr4_bad [reflection and seed do not go into the $day_block block]"
  grep 'second run the same day' "$work/alone-s" > "$work/second"
  if [ ! -s "$work/second" ]; then
    rr4_bad="$rr4_bad [nothing says what a second run the same day does]"
  else
    grep -q 'block that already exists' "$work/second" || rr4_bad="$rr4_bad [a second run does not reuse the existing block]"
    grep -q 'never a second block' "$work/second" || rr4_bad="$rr4_bad [a second run may write a second block]"
  fi
  grep 'no journal yet' "$work/alone-s" > "$work/nojournal"
  if [ ! -s "$work/nojournal" ]; then
    rr4_bad="$rr4_bad [nothing says what to do in a week with no journal]"
  else
    grep -q -F -- "\`$j_en\`" "$work/nojournal" || rr4_bad="$rr4_bad [the journal is not created in \`$j_en\`]"
    grep -q 'created first' "$work/nojournal" || rr4_bad="$rr4_bad [the journal is not created before the block]"
    grep -q 'no task migrated' "$work/nojournal" || rr4_bad="$rr4_bad [the new journal migrates tasks]"
  fi
fi
if [ -z "$rr4_bad" ]; then
  ok "RR4 close-day alone skips the assessment while today's block holds no numbered 3, reuses that block on a second run, and creates the week's journal first"
else
  fail "RR4 standalone close-day" "$rr4_bad"
fi

rm -rf "$work"
[ "$failures" -eq 0 ]
