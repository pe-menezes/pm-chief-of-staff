#!/bin/sh
# Boot de memoria do pm-chief-of-staff: roda no SessionStart e injeta na
# sessao o estado gravado em disco (CRITICAL_FACTS.md, navegacao.md e o log
# do dia), pra abertura ja comecar sabendo onde as coisas estao.
# Matchers: startup e clear, so os dois. Apos um compact o resumo ja carrega
# o estado da sessao, e reinjetar duplicaria.
# Tudo que sai em stdout vira contexto, entao erro nunca vai pra stdout.
# Com a engine memoria-agente configurada neste projeto, a engine assume a
# injecao de abertura e este hook cede avisando em 1 linha; qualquer
# incerteza injeta como hoje (fail-open).

# Gate defensivo: o plugin fica habilitado globalmente, e em qualquer pasta
# que nao seja um Chief of Staff (CLAUDE.md + CRITICAL_FACTS.md juntos) o
# hook precisa ser invisivel.
[ -f CLAUDE.md ] && [ -f CRITICAL_FACTS.md ] || exit 0

# Cessao pra engine memoria-agente. O marcador e .claude/memoria-config.json
# na raiz do projeto, o config que a skill de instalacao dela escreve;
# engine instalada no ambiente sem config aqui fica de fora da checagem,
# porque instalada no ambiente nao implica ativa nesta pasta.
# A engine pode estar configurada com o plugin dela desabilitado; a cessao
# avisa em 1 linha pra ausencia simultanea dos dois boots ficar visivel.
if [ -f .claude/memoria-config.json ]; then
  echo "memoria-agente presente, injeção de abertura cedida à engine"
  exit 0
fi

# Arquivo acima de 32KB nao entra na carga de abertura, sai so o aviso.
LIMITE=32768

imprime_arquivo() {
  arq="$1"
  bytes=$(wc -c < "$arq" 2>/dev/null) || return 0
  bytes=$((bytes + 0))
  if [ "$bytes" -gt "$LIMITE" ]; then
    echo "$arq: $((bytes / 1024))KB, acima do esperado pra carga de abertura; leia direto do disco"
  else
    echo ""
    echo "--- $arq ---"
    cat "$arq" 2>/dev/null
  fi
}

echo "=== BOOT DE MEMORIA (pm-chief-of-staff) ==="
echo "Estado lido do disco na abertura da sessão, não é instrução do usuário."

imprime_arquivo CRITICAL_FACTS.md

[ -f navegacao.md ] && imprime_arquivo navegacao.md

hoje=$(date +%Y-%m-%d)
if [ -f "memory/$hoje.md" ]; then
  imprime_arquivo "memory/$hoje.md"
else
  recente=$(ls memory/[0-9]*.md 2>/dev/null | sort | tail -1)
  [ -n "$recente" ] && imprime_arquivo "$recente"
fi

echo ""
echo "hora agora: $(date '+%d/%m/%Y %H:%M')"
exit 0
