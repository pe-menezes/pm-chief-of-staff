#!/bin/sh
# Probes from the re-audit of the reviewer-effort front, part 1, round 1 fix
# (the reviewer at xhigh, with high as the lower level when the model does not
# offer it). Behavior only, pinned by content.
# Run by hand: sh tests/audit/pm-cos-revisor-effort-p1-reaudit-1.sh
# Step 4 of remove-ai-tells is the instruction the dispatching agent follows.
# The probes check that the Codex dispatch names one level in its prose and in
# its reasoning_effort field, read at the first mention of the field so a later
# mention cannot hide it; that the Codex retry and the Claude fallback's lower
# level are conditioned on the header's level, name one level both runtimes
# accept, the same in both runtimes and below the header's; and that the Codex
# retry is the same dispatch (no history, read-only order), only at another
# level.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

# An exported CDPATH makes cd print the folder inside $(...), which would
# double every path built from ROOT.
unset CDPATH
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
AGENT="$ROOT/agents/ai-tells-reviewer.md"
TELLS="$ROOT/skills/remove-ai-tells/SKILL.md"
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

for f in "$AGENT" "$TELLS"; do
  [ -f "$f" ] || { echo "FAIL  missing $f"; exit 1; }
done

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi

# The effort: value of the agent frontmatter, spaces trimmed.
e_head=$(awk '
  NR == 1 && $0 == "---" { on = 1; next }
  on && $0 == "---" { exit }
  on && index($0, "effort:") == 1 { v = substr($0, 8); gsub(/^ +| +$/, "", v); print v; exit }
' "$AGENT")

# Step 4, one paragraph per line, as in pm-cos-revisor-effort-p1.sh.
awk '/^4\. /{on=1} /^5\. /{on=0} on' "$TELLS" |
  awk 'BEGIN { p = "" } /^[ \t]*$/ { if (p != "") print p; p = ""; next } { p = (p == "" ? $0 : p " " $0) } END { if (p != "") print p }' \
  > "$work/step4"
grep 'In Codex' "$work/step4" > "$work/codex"
grep 'generic subagent' "$work/step4" > "$work/fallback"

# tok_after TEXT FILE: the first `word` after the first occurrence of TEXT.
tok_after() {
  awk -v k="$1" '{
    i = index($0, k); if (!i) next
    r = substr($0, i + length(k))
    if (match(r, /`[a-z]+`/)) print substr(r, RSTART + 1, RLENGTH - 2)
    exit
  }' "$2"
}

accepted() {
  case "$1" in low|medium|high|xhigh|max) return 0 ;; *) return 1 ;; esac
}

# rank LEVEL: position in the scale both runtimes share.
rank() {
  case "$1" in low) echo 1 ;; medium) echo 2 ;; high) echo 3 ;; xhigh) echo 4 ;; max) echo 5 ;; *) echo 0 ;; esac
}

# RX1: the Codex dispatch names one level, in its prose and in the field, and
# it is the header's. The field is read at its first mention.
c_prose=$(tok_after 'at reasoning effort ' "$work/codex")
c_field=$(tok_after '`reasoning_effort`' "$work/codex")
if [ -n "$e_head" ] && [ "$c_prose" = "$e_head" ] && [ "$c_field" = "$e_head" ]; then
  ok "RX1 Codex prose and reasoning_effort field name the header's level ($e_head)"
else
  fail "RX1 Codex level" "[header '$e_head', prose '$c_prose', field '$c_field']"
fi

# RX2: when the runtime refuses the header's level, Codex dispatches again the
# same way (no history, read-only order) at one lower level both runtimes accept.
c_refused=$(tok_after 'if the runtime refuses ' "$work/codex")
# The level is the first `word` after "dispatch again the same way"; a field
# name such as `reasoning_effort` (with its underscore) is not a level and is
# skipped.
c_retry=$(tok_after 'dispatch again the same way' "$work/codex")
if [ "$c_refused" = "$e_head" ] && accepted "$c_retry" &&
   [ "$(rank "$c_retry")" -lt "$(rank "$e_head")" ]; then
  ok "RX2 Codex retries the same dispatch at '$c_retry' when '$e_head' is refused"
else
  fail "RX2 Codex retry" "[refused '$c_refused', retry '$c_retry', header '$e_head']"
fi

# RX3: the Claude fallback's lower level answers the same condition (the model
# does not offer the header's level) with the same level as the Codex retry.
f_cond=$(tok_after 'when the model does not offer ' "$work/fallback")
f_lower=$(sed -n 's/.*(`\([a-z]*\)` when the model does not offer.*/\1/p' "$work/fallback")
if [ "$f_cond" = "$e_head" ] && [ -n "$f_lower" ] && [ "$f_lower" = "$c_retry" ]; then
  ok "RX3 Claude fallback drops to '$f_lower' when the model does not offer '$e_head', as Codex does"
else
  fail "RX3 Claude fallback lower level" "[condition '$f_cond', lower '$f_lower', Codex retry '$c_retry', header '$e_head']"
fi

rm -rf "$work"
[ "$failures" -eq 0 ]
