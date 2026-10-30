#!/bin/sh
# Probes from the final codex-compat-funcional audit (modules/codex-bridge.sh).
# Run by hand: sh tests/audit/codex-compat-final.sh
# Each case builds a folder from mktemp -d with a space in its name, runs the
# bridge inside it and removes the folder. Checks disk state and exit code,
# never the bridge's text.
# Output: one ok or FAIL line per case; exit 0 only when everything passes.

DIR=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
BRIDGE="$DIR/modules/codex-bridge.sh"
failures=0

ok() { echo "ok    $1"; }
fail() { echo "FAIL  $1: $2"; failures=$((failures + 1)); }

# Fake ln on the PATH only while the bridge runs: a system without symbolic
# links.
fake=$(mktemp -d 2>/dev/null)
printf '#!/bin/sh\nexit 1\n' > "$fake/ln"
chmod +x "$fake/ln"

# A1 SKILL.md in .agents/skills is a link to a VALID and intact wrapper of
# the bridge, kept by the person outside the folder, with no edit at all. The
# marker and the proof match through the link, so only the link guard stops
# the bridge from replacing the link with a regular file. With the source
# changed, an undue update would show: the link and the target stay as they
# are, exit 2.
tmp=$(mktemp -d 2>/dev/null)
if [ -z "$tmp" ] || [ ! -d "$tmp" ]; then
  fail A1 "mktemp -d returned no folder"
else
  folder="$tmp/my cos folder"
  mkdir -p "$folder/.claude/skills/start-day"
  printf -- '---\nname: start-day\ndescription: probe start.\n---\n\n# Start\n' > "$folder/.claude/skills/start-day/SKILL.md"
  (cd "$folder" && PATH="$fake:$PATH" sh "$BRIDGE" >/dev/null 2>&1)
  w="$folder/.agents/skills/start-day/SKILL.md"
  target="$tmp/the persons wrapper.md"
  cp "$w" "$target"
  before=$(cksum < "$target")
  rm "$w"
  ln -s "../../../../the persons wrapper.md" "$w"
  printf -- '---\nname: start-day\ndescription: probe start, changed.\n---\n\n# Start\n' > "$folder/.claude/skills/start-day/SKILL.md"
  (cd "$folder" && PATH="$fake:$PATH" sh "$BRIDGE" >/dev/null 2>&1)
  rc=$?
  if [ "$rc" -eq 2 ] && [ -L "$w" ] && [ "$(readlink "$w")" = "../../../../the persons wrapper.md" ] \
    && [ "$(cksum < "$target")" = "$before" ]; then
    ok "A1 SKILL.md linked to a valid and intact wrapper stays a link"
  else
    fail A1 "exit $rc, link: $(readlink "$w" 2>/dev/null || echo replaced by a file)"
  fi
  rm -rf "$tmp"
fi

rm -rf "$fake"
[ "$failures" -eq 0 ] || exit 1
exit 0
