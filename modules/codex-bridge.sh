#!/bin/sh
# Codex bridge of pm-chief-of-staff: lets Codex find the person's skills
# without a second copy. The single source is .claude/skills/ in their folder;
# Codex scans .agents/skills/. Runs inside the person's folder:
#   sh "<plugin root>/modules/codex-bridge.sh"
# Loaded by: setup (planting), plant (step 4), create-skill (step 4).
# Running it again is safe: what is already linked stays, what is missing is
# created.
#
# Order, from simplest to most laborious:
# 1) no .agents/skills: relative link to the collection, .agents/skills ->
#    ../.claude/skills. A new skill shows up by itself, without running the
#    bridge again.
# 2) .agents/skills is a real folder (the person already had it, or the
#    link failed): one entry per skill, relative link ../../.claude/skills/NAME.
# 3) links unavailable on the system: wrapper .agents/skills/NAME/SKILL.md
#    with the source frontmatter and the order to read the source. The
#    wrapper carries the MARCA below and ends with the integrity PROVA; only
#    a wrapper with the MARCA and a matching PROVA is rewritten, so the
#    description follows the source on the next run.
# Never replaces, deletes, renames or merges: a link, file or folder that
# already exists and is not from this bridge stays as it is and is reported
# as a conflict.
# A folder starting with _ or . is not a skill (_shared/ is a module).
# Exit: 0 everything linked; 1 no .claude/skills or disk error (includes a
# wrapper that was not written, with the previous one intact); 2 conflicts
# left, listed on stdout for whoever ran it to decide with the person.
# Limit: on Windows without link permission it always falls back to wrappers.

# MARCA and PROVA are frozen literals, byte for byte those of 0.7.0, in
# Portuguese on purpose. They are written into the wrappers of installed
# folders and are how this bridge recognizes its own files; changing either
# one would turn every 0.7.0 wrapper into a conflict on the next run. The
# PROVA covers whatever sits above it, so the body may change language.
MARCA="<!-- gerado pela ponte-codex do pm-chief-of-staff; a fonte e a pasta .claude/skills -->"
PROVA="<!-- integridade ponte-codex, cksum do que vem acima: "

if [ ! -d .claude/skills ]; then
  echo "no .claude/skills in this folder: nothing to link"
  exit 1
fi

# .agents as a link, even a broken one, would take writes outside the
# folder: check it before looking at anything inside it.
if [ -L .agents ]; then
  echo "conflict: .agents is already a link to $(readlink .agents), left as it was"
  exit 2
fi
if [ -e .agents ] && [ ! -d .agents ]; then
  echo "conflict: .agents already exists and is not a folder, left as it was"
  exit 2
fi

if [ -L .agents/skills ]; then
  target=$(readlink .agents/skills)
  if [ "$target" = "../.claude/skills" ] && [ -d .agents/skills ]; then
    echo "bridge ok: .agents/skills points to .claude/skills"
    exit 0
  fi
  echo "conflict: .agents/skills is already a link to $target, left as it was"
  exit 2
fi
if [ -e .agents/skills ] && [ ! -d .agents/skills ]; then
  echo "conflict: .agents/skills already exists and is not a folder, left as it was"
  exit 2
fi

if [ ! -e .agents/skills ]; then
  mkdir -p .agents || exit 1
  if ln -s ../.claude/skills .agents/skills 2>/dev/null; then
    echo "bridge created: .agents/skills -> ../.claude/skills"
    exit 0
  fi
  mkdir .agents/skills || exit 1
  echo "collection link unavailable: linking skill by skill"
fi

# A file size limit becomes a write error, not the death of the process.
trap '' XFSZ

# wrapper SOURCE NAME DEST: writes the wrapper with the source frontmatter.
# Writes to a temporary file of this run in the same folder and only swaps
# it in by rename after checking the content; a failure leaves the previous
# SKILL.md intact and removes only the temporary file this run created.
# The last line is the PROVA: cksum of everything before it. A wrapper is
# only updated when the PROVA matches; any edit, even keeping the MARCA, or
# the old format without a PROVA, is reported as a conflict.
wrapper() {
  fm=$(awk 'NR == 1 { if ($0 != "---") exit; next } /^---$/ { found = 1; exit } { print } END { exit !found }' "$1") || return 1
  body=$(printf -- '---\n%s\n---\n%s\n\n%s' "$fm" "$MARCA" "This skill lives in \`.claude/skills/$2/SKILL.md\`, the source in this folder. Read that whole file and follow it; relative paths in it start from its folder. Edits always go to the source: the next bridge run updates the frontmatter here.")
  content="$body
$PROVA$(printf '%s\n' "$body" | cksum) -->"
  tmp="$3/.SKILL.md.ponte.$$"
  (set -C; : > "$tmp") 2>/dev/null || return 1
  if printf '%s\n' "$content" > "$tmp" 2>/dev/null && [ "$(cat "$tmp")" = "$content" ] \
    && mv -f "$tmp" "$3/SKILL.md" 2>/dev/null; then
    return 0
  fi
  rm -f "$tmp"
  return 1
}

# integro FILE: the last line is the PROVA and matches the rest of the file.
integro() {
  last=$(tail -n 1 "$1") || return 1
  case "$last" in "$PROVA"*" -->") ;; *) return 1 ;; esac
  sum=${last#"$PROVA"}
  sum=${sum%" -->"}
  [ -n "$sum" ] && [ "$(sed '$d' "$1" | cksum)" = "$sum" ]
}

conflicts=0
errors=0
for source in .claude/skills/*/SKILL.md; do
  [ -f "$source" ] || continue
  name=${source#.claude/skills/}
  name=${name%/SKILL.md}
  case "$name" in _*|.*) continue ;; esac
  dest=".agents/skills/$name"
  if [ -L "$dest" ]; then
    target=$(readlink "$dest")
    if [ "$target" = "../../.claude/skills/$name" ]; then
      echo "ok: $name"
    else
      echo "conflict: $dest is already a link to $target, left as it was"
      conflicts=$((conflicts + 1))
    fi
    continue
  fi
  if [ ! -e "$dest" ]; then
    if ln -s "../../.claude/skills/$name" "$dest" 2>/dev/null; then
      echo "linked: $name"
      continue
    fi
    if mkdir "$dest"; then
      if wrapper "$source" "$name" "$dest"; then
        echo "wrapper: $name"
        continue
      fi
      # The folder is from this run: it goes away only if it is still
      # empty, so the next run creates it again; whatever appeared in it
      # stays.
      rmdir "$dest" 2>/dev/null
    fi
    echo "error: wrapper for $name was not written (frontmatter missing in the source, or disk)"
    errors=$((errors + 1))
    continue
  fi
  # Only a regular file with the marker and a matching proof is a wrapper of
  # this bridge: a SKILL.md that is a link, even a broken one or one whose
  # target carries the marker, or one that was edited, belongs to the person.
  if [ -f "$dest/SKILL.md" ] && [ ! -L "$dest/SKILL.md" ] && grep -qxF "$MARCA" "$dest/SKILL.md" \
    && integro "$dest/SKILL.md"; then
    if wrapper "$source" "$name" "$dest"; then
      echo "wrapper updated: $name"
    else
      echo "error: wrapper for $name was not updated, the previous one stayed (frontmatter missing in the source, or disk)"
      errors=$((errors + 1))
    fi
    continue
  fi
  echo "conflict: $dest already exists and is not from this bridge, left as it was"
  conflicts=$((conflicts + 1))
done

if [ "$errors" -gt 0 ]; then
  echo "$errors write error(s); $conflicts conflict(s); nothing was half replaced"
  exit 1
fi
if [ "$conflicts" -gt 0 ]; then
  echo "$conflicts conflict(s): nothing was replaced; decide with the person"
  exit 2
fi
exit 0
