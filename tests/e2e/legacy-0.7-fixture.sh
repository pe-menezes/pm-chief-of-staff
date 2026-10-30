#!/bin/sh
# Builds a fictitious Chief of Staff folder as installed by v0.7.0, for the
# E2E runs of the 0.8.0 parts (the legacy-folder matrix of the common spec).
# Usage: sh tests/e2e/legacy-0.7-fixture.sh "<folder>" link|wrappers [with-fechar-semana]
#   link      the 0.7.0 bridge links .agents/skills -> ../.claude/skills
#   wrappers  the 0.7.0 bridge runs with a fake ln on the PATH, so it writes
#             one 0.7.0 wrapper per seed (frozen marker, Portuguese body,
#             proof)
#   with-fechar-semana  optional: adds the sixth seed, as in a folder that ran
#             "plantar fechar-semana"
# By default the folder gets the five seeds the 0.7.0 setup plants
# (abrir-dia, fechar-dia, preparar-conversa, processar-reuniao, absorver).
# The seeds, the two modules and the bridge come from the 0.7.0 commit
# by `git show 318ea9c:<path>`, never from a hand copy, so this script needs
# the git history of this repo (the deterministic suites do not). The other
# files are fictitious, in Portuguese like every 0.7.0 folder, and each one
# carries its own sentinel (COS07_...).
# Refuses a folder that already exists (or a dangling link in its place) and
# needs its parent to exist. Writes nothing outside the folder: the fake ln
# lives in .fixture-bin/ inside it and is removed before the end.
# Exit: 0 folder ready; 1 refused, git history missing or bridge failure; 64
# wrong usage.

BASE=318ea9c
DIR=$(cd "$(dirname "$0")/../.." && pwd) || exit 1

usage() {
  echo "usage: sh tests/e2e/legacy-0.7-fixture.sh \"<folder>\" link|wrappers [with-fechar-semana]" >&2
  exit 64
}
[ "$#" -eq 2 ] || [ "$#" -eq 3 ] || usage
case "$2" in link|wrappers) ;; *) usage ;; esac
[ -n "$1" ] || usage
mode=$2
seeds="abrir-dia absorver fechar-dia preparar-conversa processar-reuniao"
nseeds=5
if [ "$#" -eq 3 ]; then
  [ "$3" = with-fechar-semana ] || usage
  seeds="$seeds fechar-semana"
  nseeds=6
fi

if [ -e "$1" ] || [ -L "$1" ]; then
  echo "refused: $1 already exists, nothing was written" >&2
  exit 1
fi
mkdir -- "$1" || exit 1
cd -- "$1" || exit 1

# from07 PATH DEST: DEST gets PATH as it was in the 0.7.0 commit.
from07() {
  git -C "$DIR" show "$BASE:$1" > "$2" 2>/dev/null && [ -s "$2" ] && return 0
  echo "error: git show $BASE:$1 failed; this script needs the repo history" >&2
  exit 1
}

# put FILE LINE...: FILE gets one LINE per argument.
put() {
  f=$1
  shift
  printf '%s\n' "$@" > "$f" || exit 1
}

for seed in $seeds; do
  mkdir -p ".claude/skills/$seed" || exit 1
  from07 "seeds/$seed/SKILL.md" ".claude/skills/$seed/SKILL.md"
done
mkdir -p .claude/skills/_shared .claude/rules pessoas diario memory contexto projetos reunioes referencia || exit 1
from07 modulos/capacidades.md .claude/skills/_shared/capacidades.md
from07 modulos/gate-de-escrita.md .claude/skills/_shared/gate-de-escrita.md

put CLAUDE.md '@AGENTS.md'

put AGENTS.md \
  '# Chief of Staff da Marina Teste' \
  '' \
  'Sentinela: COS07_AGENTS' \
  '' \
  'Marina Teste é gerente de produto fictícia da Empresa Exemplo.' \
  '' \
  '## Rotina de sessão' \
  '' \
  'Toda sessão nova começa lendo `CRITICAL_FACTS.md`, `navegacao.md` e o log mais recente de `memory/`.' \
  '' \
  '## Regras por assunto' \
  '' \
  'Antes de atuar num assunto do índice, leia a regra dele.' \
  '' \
  '* nenhuma regra ainda'

put CRITICAL_FACTS.md \
  '# Fatos críticos' \
  '' \
  'Sentinela: COS07_CRITICAL_FACTS' \
  '' \
  'Marina Teste, gerente de produto fictícia.' \
  '' \
  '## Prioridades' \
  '' \
  '1. Lançar o módulo Exemplo até 30/11 (meta: 50 clientes piloto).' \
  '2. Fechar o plano do trimestre com a Ana Souza.'

put navegacao.md \
  '# Navegação' \
  '' \
  'Sentinela: COS07_NAVEGACAO' \
  '' \
  '* `pessoas/`: um hub por pessoa-chave' \
  '* `diario/`: o diário semanal' \
  '* `memory/`: o log diário'

put pessoas/ana-souza.md \
  '# Ana Souza' \
  '' \
  'Sentinela: COS07_HUB' \
  '' \
  '## Contexto' \
  '' \
  'Líder fictícia da Marina.' \
  '' \
  '## Fatos' \
  '' \
  '* 27/10: pediu o plano do trimestre até 05/11 (fonte: 1:1 de 27/10).' \
  '' \
  '## Leitura vigente' \
  '' \
  '* 27/10: quer previsibilidade antes de escopo novo.' \
  '' \
  '## Sinais recentes' \
  '' \
  '* 28/10: elogiou o resumo semanal.' \
  '' \
  '## Histórico'

put diario/2026-W44.md \
  '# Semana 2026-W44' \
  '' \
  'Sentinela: COS07_DIARIO' \
  '' \
  '## 3 do dia , 28/10' \
  '' \
  '1. Revisar o rascunho do plano do trimestre (feita)' \
  '2. Preparar a 1:1 com a Ana Souza (feita)' \
  '3. Responder o time de dados (não feita)' \
  '' \
  '**Balanço:** 2/3, o time de dados ficou para amanhã.' \
  '**→ amanhã:** responder o time de dados antes das 10h.' \
  '' \
  '## Tasks' \
  '' \
  '- [ ] Enviar o plano do trimestre para a Ana Souza 📅 2026-11-05'

put memory/2026-10-28.md \
  '# 2026-10-28' \
  '' \
  'Sentinela: COS07_MEMORY' \
  '' \
  '## [18:40] Fechamento do dia' \
  'Balanço 2/3; o time de dados ficou para amanhã.' \
  'Detalhe em `diario/2026-W44.md`.'

put .claude/skills/_shared/tells.md \
  '# Tells' \
  '' \
  'Sentinela: COS07_TELLS' \
  '' \
  '## Tells que eu flagrei' \
  '' \
  '* "no fim do dia" como abertura de conclusão' \
  '' \
  '## Meu jeito, não marcar' \
  '' \
  '* "vale ressaltar" quando eu mesma escrevo'

put rascunho-tells.md \
  'Sentinela: COS07_RASCUNHO' \
  '' \
  'Rascunho que sobrou de uma revisão interrompida da 0.7.0.'

bridge07=$(git -C "$DIR" show "$BASE:modulos/ponte-codex.sh" 2>/dev/null)
if [ -z "$bridge07" ]; then
  echo "error: git show $BASE:modulos/ponte-codex.sh failed; this script needs the repo history" >&2
  exit 1
fi
if [ "$mode" = link ]; then
  printf '%s\n' "$bridge07" | sh >/dev/null 2>&1
  rc=$?
else
  mkdir .fixture-bin || exit 1
  printf '#!/bin/sh\nexit 1\n' > .fixture-bin/ln || exit 1
  chmod +x .fixture-bin/ln || exit 1
  printf '%s\n' "$bridge07" | PATH="$PWD/.fixture-bin:$PATH" sh >/dev/null 2>&1
  rc=$?
  rm -f .fixture-bin/ln
  rmdir .fixture-bin || exit 1
fi
if [ "$rc" -ne 0 ]; then
  echo "error: the 0.7.0 bridge exited with $rc in mode $mode" >&2
  exit 1
fi
echo "0.7.0 fixture ready ($mode, $nseeds seeds): $PWD"
exit 0
