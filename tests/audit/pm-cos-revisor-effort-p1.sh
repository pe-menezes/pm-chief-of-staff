#!/bin/sh
# Probes from the audit of the reviewer-effort front, part 1 (the tells
# reviewer at a fixed effort on its three dispatch paths). Behavior only,
# pinned by content.
# Run by hand: sh tests/audit/pm-cos-revisor-effort-p1.sh
# The agent header and step 4 of remove-ai-tells are instructions, so the
# probes check what the runtime and the dispatching agent follow: the three
# paths name one effort level, and it is a level both runtimes accept; the
# Codex dispatch that overrides the effort starts the subagent without the
# parent history (a full-history fork refuses the override and the reviewer
# would lose its independence); and the two generic dispatches, where the
# header's tools: does not apply, still carry the written order to only read,
# while the registered agent keeps its read-only tools.
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

# front KEY: the value of KEY in the agent frontmatter (between the first two
# --- lines), spaces trimmed.
front() {
  awk -v k="$1" '
    NR == 1 && $0 == "---" { on = 1; next }
    on && $0 == "---" { exit }
    on && index($0, k ":") == 1 { v = substr($0, length(k) + 2); gsub(/^ +| +$/, "", v); print v; exit }
  ' "$AGENT"
}

# Step 4 of the skill, from "4. " up to "5. ", split into paragraphs, one per
# line (blank lines separate paragraphs).
awk '/^4\. /{on=1} /^5\. /{on=0} on' "$TELLS" |
  awk 'BEGIN { p = "" } /^[ \t]*$/ { if (p != "") print p; p = ""; next } { p = (p == "" ? $0 : p " " $0) } END { if (p != "") print p }' \
  > "$work/step4"
grep 'In Codex' "$work/step4" > "$work/codex"
grep 'generic subagent' "$work/step4" > "$work/fallback"

n_codex=$(wc -l < "$work/codex" | tr -d ' ')
n_fallback=$(wc -l < "$work/fallback" | tr -d ' ')
if [ "$n_codex" = 1 ] && [ "$n_fallback" = 1 ]; then
  ok "RE0 step 4 has one Codex dispatch and one generic Claude fallback"
else
  fail "RE0 step 4 paragraphs" "Codex $n_codex, fallback $n_fallback (expected 1 and 1)"
fi

e_head=$(front effort)
e_codex=$(sed -n 's/.*`reasoning_effort`[^`]*`\([a-z]*\)`.*/\1/p' "$work/codex")
e_fallback=$(sed -n 's/.*generic subagent[^`]*effort `\([a-z]*\)`.*/\1/p' "$work/fallback")

# RE1: the three paths move together (guide, Contracts). An edit to one level
# without the others leaves the reviewer at different efforts per runtime.
if [ -n "$e_head" ] && [ "$e_head" = "$e_codex" ] && [ "$e_head" = "$e_fallback" ]; then
  ok "RE1 header, Codex and fallback name one effort ($e_head)"
else
  fail "RE1 one effort on the three paths" "[header '$e_head', codex '$e_codex', fallback '$e_fallback']"
fi

# RE2: the level is one both runtimes accept: claude --effort takes low,
# medium, high, xhigh, max; spawn_agent's models list low to ultra
# (codex-cli 0.166.0-alpha.5.1). A typo or a Codex-only level would be
# ignored or refused at dispatch.
case "$e_head" in
  low|medium|high|xhigh|max) ok "RE2 effort level '$e_head' is accepted by both runtimes" ;;
  *) fail "RE2 effort level" "'$e_head' is not one of low, medium, high, xhigh, max" ;;
esac

# RE3: the Codex override starts without the parent history. The runtime
# refuses reasoning_effort on a full-history fork, and a fork with history
# breaks the reviewer's independence.
fork=$(sed -n 's/.*`fork_turns`[^`]*`\([a-z]*\)`.*/\1/p' "$work/codex")
if [ -n "$e_codex" ] && [ "$fork" = "none" ] && grep -q 'without a copy of this conversation'"'"'s history' "$work/codex"; then
  ok "RE3 Codex dispatch sets reasoning_effort with fork_turns none and no history"
else
  fail "RE3 Codex override without history" "[reasoning_effort '$e_codex', fork_turns '$fork']"
fi
if grep -q '`fork_turns`[^`]*`all`' "$work/codex"; then
  fail "RE3b Codex dispatch" "names fork_turns all"
else
  ok "RE3b Codex dispatch never names fork_turns all"
fi

# RE4: the two generic dispatches carry the order to only read. There the
# header's tools: does not apply, so the written order is the only guard
# against the reviewer writing to the person's folder.
if grep -q 'explicit order to only read' "$work/codex" &&
   grep -q 'do not edit, create or delete any file' "$work/codex" &&
   grep -q 'do not run any command that writes' "$work/codex"; then
  ok "RE4 Codex dispatch carries the read-only order (no edit, create, delete or writing command)"
else
  fail "RE4 Codex read-only order" "the Codex paragraph of step 4 lost part of the order to only read"
fi
if grep -q 'explicit order to only read and edit nothing' "$work/fallback"; then
  ok "RE5 Claude fallback dispatch carries the read-only order"
else
  fail "RE5 fallback read-only order" "the generic-subagent paragraph of step 4 lost the order to only read"
fi

# RE6: the registered agent keeps read-only tools and inherits the model, so
# the effort line is the only thing that sets its run apart from the session.
t_head=$(front tools)
m_head=$(front model)
if [ "$t_head" = "Read, Grep, Glob" ] && [ "$m_head" = "inherit" ]; then
  ok "RE6 registered reviewer keeps tools Read, Grep, Glob and model inherit"
else
  fail "RE6 reviewer header" "[tools '$t_head', model '$m_head']"
fi

rm -rf "$work"
[ "$failures" -eq 0 ]
