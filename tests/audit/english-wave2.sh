#!/bin/sh
# Probes from the audit of the english front, wave 2 (P5 support skills and
# reviewer, P6 and P7 seeds). Behavior only, pinned by content.
# Run by hand: sh tests/audit/english-wave2.sh
# The seeds and skills are instructions, so the probes check the contracts
# between files that an agent follows at run time: the label a seed writes is
# the label the next seed reads, every label and path a seed uses is a cell of
# modules/vocabulary.md (the plant swaps those cells for the folder's names),
# the module paths and capability names a seed reads exist in the module, and
# the scan regexes of remove-ai-tells find what they promise when run.
# The legacy cases (AW10, AW11) need the git history of this repo (commit
# 318ea9c); without it they print "info" and the rest runs the same.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
VOC="$ROOT/modules/vocabulary.md"
CAP="$ROOT/modules/capabilities.md"
GATE="$ROOT/modules/write-gate.md"
TELLS="$ROOT/skills/remove-ai-tells/SKILL.md"
CONNECT="$ROOT/skills/connect/SKILL.md"
SEEDS="start-day close-day close-week prep-conversation process-meeting absorb"
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi

seed() { echo "$ROOT/seeds/$1/SKILL.md"; }
# body FILE: the file without its frontmatter (lines 1 to 4).
body() { sed -n '5,$p' "$1"; }

# cell ROLE COLUMN: the backticked value of a row of the person-facing table
# of the vocabulary (COLUMN 3 is en, 4 is pt-BR), by its role name.
cell() {
  awk -F'|' -v role="$1" -v col="$2" '
    /^## Person-facing vocabulary/ { on = 1; next }
    /^## / { on = 0 }
    on {
      r = $2; gsub(/^ +| +$/, "", r)
      if (r == role) { v = $col; sub(/^ *`/, "", v); sub(/` *$/, "", v); print v; exit }
    }' "$VOC"
}

# head: the fixed part of a label, the part a reader matches on: the bold
# label of "**X:** ...", "## [HH:MM]" of the log entry, a heading up to its
# first placeholder, the key of a frontmatter line with a placeholder value.
head_en() {
  sed -E -e 's/^(\*\*[^*]*:\*\*).*$/\1/' \
    -e 's/^## \[HH:MM\].*$/## [HH:MM]/' \
    -e '/^## /s/ *(\{|YYYY).*$//' \
    -e 's/^(type|with|date): *(\{|YYYY).*$/\1:/'
}

# ---------------------------------------------------------------------------
# AW1 to AW3: the three scan regexes of remove-ai-tells, read from the skill
# and run with perl the way step 3 tells the agent to run them.

anti=$(grep -F -- '- Antithesis with the regex `' "$TELLS" | sed 's/^[^`]*`//; s/`.*$//')
punct=$(grep -F -- '- Em dash, en dash and curly quotes with the regex `' "$TELLS" | sed 's/^[^`]*`//; s/`.*$//')
colon=$(grep -F -- '- Colons and semicolons with the regex `' "$TELLS" | sed 's/^[^`]*`//; s/`.*$//')

t="$work/anti"
mkdir -p "$t"
cat > "$t/hit.txt" <<'EOF'
The drop isn't a bug, it's a pricing problem.
It is not a patch, it is a rebuild.
We want speed, not polish.
Not only faster, but also cheaper.
This is not just a tool.
It is more than a dashboard, it is a habit.
Não é um bug, é preço.
Queremos rapidez, não polimento.
Não só mais rápido, mas também mais barato.
Isso não apenas mede, ensina.
Mais do que um painel, é um hábito.
EOF
cat > "$t/miss.txt" <<'EOF'
The plan works and ships on Friday.
O plano funciona e sai na sexta.
EOF
hits=$(perl -CSD -Mutf8 -ne "print if /$anti/i" "$t/hit.txt" | wc -l | tr -d ' ')
misses=$(perl -CSD -Mutf8 -ne "print if /$anti/i" "$t/miss.txt" | wc -l | tr -d ' ')
if [ -n "$anti" ] && [ "$hits" -eq 11 ] && [ "$misses" -eq 0 ]; then
  ok "AW1 antithesis regex finds the 6 English and 5 Portuguese forms, not plain prose"
else
  fail "AW1 antithesis regex" "regex '$anti', $hits of 11 hit lines, $misses false hits"
fi

t="$work/punct"
mkdir -p "$t"
printf 'a\342\200\224b\na\342\200\223b\n\342\200\234q\342\200\235\n\342\200\230q\342\200\231\nplain - hyphen and "straight"\n' > "$t/p.txt"
hits=$(perl -CSD -Mutf8 -ne "print if /$punct/" "$t/p.txt" | wc -l | tr -d ' ')
if [ -n "$punct" ] && [ "$hits" -eq 4 ]; then
  ok "AW2 punctuation regex finds em dash, en dash and curly quotes, not the hyphen"
else
  fail "AW2 punctuation regex" "regex '$punct', $hits of 4 lines"
fi

t="$work/colon"
mkdir -p "$t"
printf 'One: two; three.\n\nSolo: fine.\n\nAcross: a line\nbreak; still one paragraph.\n\nSplit: here.\n\nAnd: there.\n' > "$t/c.txt"
found=$(perl -CSD -Mutf8 -0777 -ne "while (/$colon/g) { (my \$m = \$&) =~ s/\\n/ /g; print \"[\$m]\" }" "$t/c.txt")
n=$(printf '%s' "$found" | tr -cd '[' | wc -c | tr -d ' ')
if [ -n "$colon" ] && [ "$n" -eq 2 ] && printf '%s' "$found" | grep -qF '[: two;]' \
  && printf '%s' "$found" | grep -qF '[: a line break;]' && ! printf '%s' "$found" | grep -qF 'Split'; then
  ok "AW3 colon regex finds paragraphs with 2+ signs, not signs in separate paragraphs"
else
  fail "AW3 colon regex" "regex '$colon', found: $found"
fi

# ---------------------------------------------------------------------------
# AW4 every label a seed writes or reads (bold labels and headings in
# backticks or in a template block, note frontmatter keys) is a vocabulary
# cell, by its fixed part. A label outside the vocabulary is one the plant
# cannot adapt, so in a pt-BR folder it stays in English and the reader
# looks for a label nobody writes.

v="$work/vocab-heads"
awk -F'|' '
  /^## Person-facing vocabulary/ { on = 1; next }
  /^## Agent-side labels/ { on = 2; next }
  /^## Legacy 0.7.0 names/ { on = 3; next }
  /^## / { on = 0 }
  on == 1 && $3 ~ /`/ { v = $3; sub(/^ *`/, "", v); sub(/` *$/, "", v); print v }
  on == 2 && $3 ~ /`/ { n = split($3, p, "`"); for (i = 2; i <= n; i += 2) print p[i] }
  on == 3 && $2 ~ /agent label/ { n = split($4, p, "`"); for (i = 2; i <= n; i += 2) print p[i] }
' "$VOC" | head_en | sort -u > "$v"
missing=""
for s in $SEEDS; do
  f=$(seed "$s")
  {
    body "$f" | grep -o -E '`(\*\*|## )[^`]*`' | sed 's/^`//; s/`$//'
    body "$f" | awk '/^ *```/ { inb = !inb; next } inb' | sed 's/^ *//' | grep -E '^(\*\*[^*]*:\*\*|## |type: |with: |date: )'
  } | head_en | sort -u > "$work/labels-$s"
  while IFS= read -r l; do
    grep -qxF -- "$l" "$v" || missing="$missing [$s: $l]"
  done < "$work/labels-$s"
done
if [ "$(wc -l < "$v" | tr -d ' ')" -gt 30 ] && [ -z "$missing" ]; then
  ok "AW4 every label the seeds write or read is a vocabulary cell"
else
  fail "AW4 seed labels outside the vocabulary" "$missing"
fi

# ---------------------------------------------------------------------------
# AW5 the daily and weekly loop: the label each writer seed writes is in the
# reader seed, both taken from the vocabulary cell (fixed part).

loop_bad=""
# check ROLE WRITER READER...
check() {
  role=$1
  shift
  h=$(cell "$role" 3 | head_en)
  [ -n "$h" ] || { loop_bad="$loop_bad [no cell: $role]"; return; }
  for s in "$@"; do
    grep -qF -- "$h" "$(seed "$s")" || loop_bad="$loop_bad [$s lacks $h]"
  done
}
check "today's 3 block" start-day close-day close-week
check "balance" close-day close-week
check "seed for tomorrow" close-day start-day close-week
check "reflection" close-day close-week
check "week close" close-week
check "weekly journal folder" start-day close-week
if [ -z "$loop_bad" ]; then
  ok "AW5 loop labels: written by one seed, read by the next, all from the vocabulary"
else
  fail "AW5 loop labels" "$loop_bad"
fi

# ---------------------------------------------------------------------------
# AW6 the note, agenda and hub contract of the conversation seeds, from the
# vocabulary cells, plus the direct-report block that setup strips by its two
# delimiter lines for a person with no direct reports.

conv_bad=""
pm=$(seed process-meeting)
pc=$(seed prep-conversation)
ab=$(seed absorb)
for role in "note frontmatter: type" "note frontmatter: with" "note frontmatter: date" \
  "note section: context" "note section: raw" "note section: decisions" "note section: tasks" \
  "note section: signals" "note section: unresolved" "doubt mark" "meeting note"; do
  h=$(cell "$role" 3 | head_en)
  [ -n "$h" ] && grep -qF -- "$h" "$pm" || conv_bad="$conv_bad [process-meeting: $role]"
done
for role in "agenda" "note section: context" "agenda section: open follow-ups" \
  "agenda section: decisions to make" "agenda section: topics" "agenda section: feedback" \
  "hub section: history"; do
  h=$(cell "$role" 3 | head_en)
  [ -n "$h" ] && grep -qF -- "$h" "$pc" || conv_bad="$conv_bad [prep-conversation: $role]"
done
for role in "hub section: facts" "hub section: current reading" "hub section: recent signals"; do
  h=$(cell "$role" 3)
  for f in "$pm" "$pc" "$ab"; do
    [ -n "$h" ] && grep -qw -- "$h" "$f" || conv_bad="$conv_bad [$(basename "$(dirname "$f")"): $role]"
  done
done
sup=$(cell "superseded mark (hub)" 3 | sed 's/ *{.*$//')
for f in "$pm" "$pc" "$ab"; do
  [ -n "$sup" ] && grep -qF -- "$sup" "$f" || conv_bad="$conv_bad [$(basename "$(dirname "$f")"): superseded mark]"
done
h=$(cell "consumer line of \`absorb\`" 3)
[ -n "$h" ] && grep -qF -- "$h" "$ab" || conv_bad="$conv_bad [absorb: when I use this]"
fb=$(cell "agenda section: feedback" 3)
starts=$(grep -c -xF '<!-- direct-report-feedback:start -->' "$pc")
ends=$(grep -c -xF '<!-- direct-report-feedback:end -->' "$pc")
stripped=$(sed '/^<!-- direct-report-feedback:start -->$/,/^<!-- direct-report-feedback:end -->$/d' "$pc")
if [ "$starts" -ne 1 ] || [ "$ends" -ne 1 ]; then
  conv_bad="$conv_bad [delimiters: $starts start, $ends end]"
elif printf '%s\n' "$stripped" | grep -qF -- "$fb"; then
  conv_bad="$conv_bad [$fb survives the strip]"
elif ! printf '%s\n' "$stripped" | grep -qF -- '**Your manager:**' \
  || ! printf '%s\n' "$stripped" | grep -qF -- '## Open follow-ups'; then
  conv_bad="$conv_bad [the strip removes more than the direct-report block]"
fi
if [ -z "$conv_bad" ]; then
  ok "AW6 note, agenda and hub labels from the vocabulary; direct-report block strips cleanly"
else
  fail "AW6 conversation seeds contract" "$conv_bad"
fi

# ---------------------------------------------------------------------------
# AW7 every module a seed reads exists in modules/ (tells.md is created by
# remove-ai-tells), and each seed that reads capabilities.md or write-gate.md
# is in the module's **Loaded by:** line, the line connect and close-week
# check consumers by.

mod_bad=""
for s in $SEEDS; do
  for m in $(body "$(seed "$s")" | grep -o '_shared/[A-Za-z0-9._-]*\.md' | sed 's#_shared/##' | sort -u); do
    [ -f "$ROOT/modules/$m" ] || [ "$m" = tells.md ] || mod_bad="$mod_bad [$s reads missing $m]"
  done
  if grep -qF '_shared/capabilities.md' "$(seed "$s")"; then
    head -1 "$CAP" | grep -qF -- "\`$s\`" || mod_bad="$mod_bad [$s not in capabilities Loaded by]"
  fi
  if grep -qF '_shared/write-gate.md' "$(seed "$s")"; then
    head -1 "$GATE" | grep -qF -- "\`$s\`" || mod_bad="$mod_bad [$s not in write-gate Loaded by]"
  fi
done
for m in "$CAP" "$GATE"; do
  for s in $(head -1 "$m" | grep -o '`[a-z-]*`' | tr -d '`'); do
    [ -f "$(seed "$s")" ] && grep -qF "_shared/$(basename "$m")" "$(seed "$s")" \
      || mod_bad="$mod_bad [$(basename "$m") declares $s, which does not read it]"
  done
done
if [ -z "$mod_bad" ]; then
  ok "AW7 seeds read modules that exist, and the Loaded by lines match the readers"
else
  fail "AW7 module consumers" "$mod_bad"
fi

# ---------------------------------------------------------------------------
# AW8 each capability a seed names is a row of the capabilities module, and
# the module rows are the capabilities of the vocabulary, in order.

capv=$(awk -F'|' '$2 ~ /capabilities, in module order/ { n = split($3, p, "`"); for (i = 2; i <= n; i += 2) print p[i] }' "$VOC")
capm=$(awk -F'|' '/^\| capability \|/ { on = 1; next } on && /^\|---/ { next } on && /^\|/ { c = $2; gsub(/^ +| +$/, "", c); print c; next } on { exit }' "$CAP")
cap_bad=""
[ -n "$capv" ] && [ "$capv" = "$capm" ] || cap_bad="$cap_bad [module rows differ from the vocabulary]"
for s in $SEEDS; do
  printf '%s\n' "$capv" | while IFS= read -r c; do
    if grep -qF -- "\`$c\`" "$(seed "$s")"; then
      printf '%s\n' "$capm" | grep -qxF -- "$c" || echo "[$s: $c]"
    fi
  done >> "$work/capbad"
done
[ -s "$work/capbad" ] && cap_bad="$cap_bad $(cat "$work/capbad")"
for pair in "start-day:today's calendar" "process-meeting:meeting transcript" \
  "prep-conversation:messages" "prep-conversation:tickets"; do
  s=${pair%%:*}
  c=${pair#*:}
  grep -qF -- "\`$c\`" "$(seed "$s")" || cap_bad="$cap_bad [$s does not read $c]"
done
if [ -z "$cap_bad" ]; then
  ok "AW8 capability names the seeds read are rows of the module, as in the vocabulary"
else
  fail "AW8 capability names" "$cap_bad"
fi

# ---------------------------------------------------------------------------
# AW9 no pt-BR folder or label value of the vocabulary in a catalog seed body:
# the catalog is English and the plant adapts it. A pt-BR name left in the
# catalog sends an English folder's first write where nobody reads.

pt_bad=""
awk -F'|' '
  /^## Person-facing vocabulary/ { on = 1; next }
  /^## / { on = 0 }
  on && $3 ~ /`/ {
    e = $3; p = $4
    sub(/^ *`/, "", e); sub(/` *$/, "", e); sub(/^ *`/, "", p); sub(/` *$/, "", p)
    if (e != p) print p
  }' "$VOC" \
  | sed -E -e 's/^(\*\*[^*]*:\*\*).*$/\1/' -e 's/ *(\{|DD\/MM).*$//' -e 's/ *,$//' \
  | sed -E -e '/^(com|data):$/d' -e '/^$/d' | sort -u > "$work/pt-heads"
for s in $SEEDS; do
  while IFS= read -r p; do
    body "$(seed "$s")" | grep -qF -- "$p" && pt_bad="$pt_bad [$s: $p]"
  done < "$work/pt-heads"
done
if [ "$(wc -l < "$work/pt-heads" | tr -d ' ')" -gt 25 ] && [ -z "$pt_bad" ]; then
  ok "AW9 catalog seed bodies carry no pt-BR folder or label name"
else
  fail "AW9 pt-BR names in the catalog seeds" "$pt_bad"
fi

# ---------------------------------------------------------------------------
# AW10 connect updates an 0.7.0 capacidades.md in place "with its own names":
# each name it lists is a name the 0.7.0 module really has (columns,
# capabilities, calendar section, consumer line and consumers).
# AW11 every 0.7.0 trigger phrase in quotes survives in the new description,
# so a request in Portuguese still fires the skill (Codex has no slash command).

if git -C "$ROOT" cat-file -e 318ea9c^{commit} 2>/dev/null; then
  git -C "$ROOT" show 318ea9c:modulos/capacidades.md > "$work/cap07"
  leg_bad=""
  {
    awk -F'|' '/^\| capacidade \|/ { for (i = 2; i < NF; i++) { c = $i; gsub(/^ +| +$/, "", c); print c }; on = 1; next } on && /^\|---/ { next } on && /^\|/ { c = $2; gsub(/^ +| +$/, "", c); print c; next } on { exit }' "$work/cap07"
    grep -o '^## Regras de leitura de agenda' "$work/cap07"
    grep -o '^\*\*Carregado por:\*\*' "$work/cap07"
    head -1 "$work/cap07" | grep -o '`[a-z-]*`' | tr -d '`'
  } | sort -u > "$work/names07"
  while IFS= read -r n; do
    [ "$n" = provider ] && continue
    grep -qF -- "\`$n\`" "$CONNECT" || leg_bad="$leg_bad [$n]"
  done < "$work/names07"
  if [ "$(wc -l < "$work/names07" | tr -d ' ')" -ge 15 ] && [ -z "$leg_bad" ]; then
    ok "AW10 connect lists the real names of the 0.7.0 capacidades.md"
  else
    fail "AW10 connect legacy names" "missing in connect:$leg_bad"
  fi

  trig_bad=""
  for pair in start-day:seeds/abrir-dia close-day:seeds/fechar-dia close-week:seeds/fechar-semana \
    prep-conversation:seeds/preparar-conversa process-meeting:seeds/processar-reuniao \
    absorb:seeds/absorver skills/connect:skills/conectar skills/create-skill:skills/criar-skill \
    skills/remove-ai-tells:skills/remove-ai-tells; do
    new=${pair%%:*}
    old=${pair#*:}
    case $new in skills/*) nf="$ROOT/$new/SKILL.md" ;; *) nf=$(seed "$new") ;; esac
    git -C "$ROOT" show "318ea9c:$old/SKILL.md" | sed -n 3p | grep -o '"[^"]*"' > "$work/trig"
    [ -s "$work/trig" ] || trig_bad="$trig_bad [$old: no phrases]"
    while IFS= read -r q; do
      sed -n 3p "$nf" | grep -qF -- "$q" || trig_bad="$trig_bad [$new: $q]"
    done < "$work/trig"
  done
  if [ -z "$trig_bad" ]; then
    ok "AW11 the 0.7.0 trigger phrases survive in the nine new descriptions"
  else
    fail "AW11 0.7.0 trigger phrases" "$trig_bad"
  fi
else
  echo "info  no 318ea9c in the git history: AW10 and AW11 not measured"
fi

rm -rf "$work"
[ "$failures" -eq 0 ] || exit 1
exit 0
