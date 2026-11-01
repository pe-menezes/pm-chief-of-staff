#!/bin/sh
# Probes from re-audit 3 of part 1 of the destination yardstick front (fix
# round 3, the two findings of the final Codex review). Behavior only, pinned
# by content, accepting paraphrases.
# Run by hand: sh tests/audit/yardstick-p1-reaudit-3.sh < /dev/null
# Optional argument: the plugin root to check (default: this repository).
# R5: the close of create-skill step 4 tells the agent that a subject rule
#     skill (user-invocable: false) gets no command and loads by itself, so
#     the agent does not promise the person a /{name} that will never run.
# R6: R2 of yardstick-p1-reaudit-1.sh (the probe beside this file) rejects
#     the four yardsticks when the missing index line loses its negation, and
#     accepts the right paraphrases. Each case runs R2 on a temporary copy of
#     the four texts with one sentence changed.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

unset CDPATH
if [ -n "$1" ]; then
  ROOT=$(cd "$1" && pwd) || exit 1
else
  ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
fi
HERE=$(cd "$(dirname "$0")" && pwd) || exit 1
PROBE="$HERE/yardstick-p1-reaudit-1.sh"
SETUP="$ROOT/skills/setup/SKILL.md"
CREATE="$ROOT/skills/create-skill/SKILL.md"
P_EN="$ROOT/PROMPT.md"
P_PT="$ROOT/PROMPT.pt-BR.md"
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

for f in "$SETUP" "$CREATE" "$P_EN" "$P_PT" "$PROBE"; do
  [ -f "$f" ] || { echo "FAIL  missing $f"; exit 1; }
done

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi

# ---------------------------------------------------------------------------
# R5 (CF4 of the final Codex review) step 4 of create-skill, in one sentence
# about user-invocable: false, says the subject rule skill gets no command (or
# stays out of the / menu) and loads by itself when the subject comes up.
# r5 FILE: empty when FILE passes, else the reason.

r5() {
  awk '/^## Step 4: plant/ { on = 1; next } on && /^## / { exit } on' "$1" | tr '\n' ' ' |
    awk '{ s = $0; while (match(s, /\. [A-Z]/)) { print substr(s, 1, RSTART); s = substr(s, RSTART + 2) } print s }' |
    grep -F 'user-invocable: false' > "$work/r5-s"
  if [ ! -s "$work/r5-s" ]; then echo "[no sentence about user-invocable: false in step 4]"; return; fi
  grep -q -i -E '(gets|has|takes) no (slash )?command|(no|without) (a )?(slash )?command|(out of|hidden from) the `/` menu' "$work/r5-s" ||
    echo "[the subject rule skill may be promised a command]"
  grep -q -i -E '(loads|is loaded|fires)[^.;]{0,30}(by itself|on its own|automatically)' "$work/r5-s" ||
    echo "[no word that the subject rule skill loads by itself]"
}

r5_now=$(r5 "$CREATE")
if [ -z "$r5_now" ]; then
  ok "R5 create-skill does not promise a command to a subject rule skill"
else
  fail "R5 create-skill close" "$r5_now"
fi

# The close of the round before the fix (ba22d60) must fail; a paraphrase
# must pass; dropping the self-loading words must fail.
old_close='The command (`/{name}`) registers in the next session; to test now, read the SKILL.md you created and follow its content directly.'
awk -v l="$old_close" '/^A workflow.s command \(`\/\{name\}`\)/ { print l; next } { print }' "$CREATE" > "$work/c-old"
para='A workflow'"'"'s command (`/{name}`) registers in the next session. A skill for a subject rule (`user-invocable: false`) has no slash command and is hidden from the `/` menu; Claude loads it on its own when the subject comes up.'
awk -v l="$para" '/^A workflow.s command \(`\/\{name\}`\)/ { print l; next } { print }' "$CREATE" > "$work/c-para"
sed 's/, and from the next session it loads by itself when the subject comes up, through its description//' "$CREATE" > "$work/c-noload"
r5m=""
cmp -s "$CREATE" "$work/c-old" && r5m="$r5m [old close not applied]"
cmp -s "$CREATE" "$work/c-noload" && r5m="$r5m [no-load mutant not applied]"
[ -z "$(r5 "$work/c-old")" ] && r5m="$r5m [the close of ba22d60 passes]"
[ -z "$(r5 "$work/c-noload")" ] && r5m="$r5m [the close without self-loading passes]"
[ -n "$(r5 "$work/c-para")" ] && r5m="$r5m [a paraphrase fails]"
if [ -z "$r5m" ]; then
  ok "R5 the old close fails, a paraphrase passes"
else
  fail "R5 strength" "$r5m"
fi

# ---------------------------------------------------------------------------
# R6 (CF2 of the final Codex review) R2 bound to a negation. Each case copies
# the four texts, swaps one phrase and reads the R2 line of the probe.

# copy ID FILE FROM TO: a plugin copy in $work/ID with FROM swapped for TO in
# FILE (a path relative to the root); "-" keeps the texts as they are.
copy() {
  d="$work/$1"
  mkdir -p "$d/skills/setup" "$d/skills/create-skill"
  cp "$SETUP" "$d/skills/setup/SKILL.md"
  cp "$CREATE" "$d/skills/create-skill/SKILL.md"
  cp "$P_EN" "$P_PT" "$d/"
  [ "$2" = "-" ] && return 0
  awk -v a="$3" -v b="$4" '{ p = index($0, a); if (p) $0 = substr($0, 1, p - 1) b substr($0, p + length(a)); print }' "$ROOT/$2" > "$d/$2"
  cmp -s "$ROOT/$2" "$d/$2" && return 1
  return 0
}

r2_of() { sh "$PROBE" "$work/$1" < /dev/null 2>/dev/null | grep -E '^(ok|FAIL) +R2'; }

# must_fail ID FILE FROM TO / must_pass ID FILE FROM TO
r6=""
must_fail() {
  copy "$@" || { r6="$r6 [$1: mutation not applied]"; return; }
  r2_of "$1" | grep -q '^FAIL' || r6="$r6 [$1: R2 passes]"
}
must_pass() {
  copy "$@" || { r6="$r6 [$1: mutation not applied]"; return; }
  r2_of "$1" | grep -q '^ok' || r6="$r6 [$1: R2 fails]"
}

must_pass T0 -
# The sentence of the Codex review, and the same hole in the other English
# yardsticks.
must_fail M1 PROMPT.md 'without steps or index line' 'with steps or index line'
must_fail M2 skills/setup/SKILL.md 'no steps and no index line' 'steps or index line'
must_fail M3 skills/create-skill/SKILL.md 'no steps and no line in the rules index' 'steps or line in the rules index'
# The negation word must start a word.
must_fail M5 PROMPT.md 'without steps or index line' 'with steps and a mono index line'
must_fail M6 PROMPT.pt-BR.md 'sem passos nem linha no índice' 'com passos, e ordenem linha no índice'
must_fail M8 PROMPT.pt-BR.md 'sem passos nem linha no índice' 'com passos ou linha no índice'
# Right paraphrases.
must_pass P1 PROMPT.md 'without steps or index line' 'with no steps and no index line'
must_pass P2 PROMPT.md 'without steps or index line' 'without steps nor index line'
must_pass P7 PROMPT.pt-BR.md 'sem passos nem linha no índice' 'nem passos nem linha no índice'
must_pass P8 PROMPT.pt-BR.md 'sem passos nem linha no índice' 'sem passos ou linha no índice'
if [ -z "$r6" ]; then
  ok "R6 R2 rejects an index line without a negation and accepts the paraphrases"
else
  fail "R6 R2 strength" "$r6"
fi

rm -rf "$work"
[ "$failures" -eq 0 ]
