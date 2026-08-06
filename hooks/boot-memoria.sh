#!/bin/sh
# Boot de memoria do pm-chief-of-staff: roda no SessionStart e injeta na
# sessao o estado gravado em disco (CRITICAL_FACTS.md, navegacao.md e o log
# do dia), pra abertura ja comecar sabendo onde as coisas estao.
# Matchers: startup e clear, so os dois. Apos um compact o resumo ja carrega
# o estado da sessao, e reinjetar duplicaria.
# Tudo que sai em stdout vira contexto, entao erro nunca vai pra stdout.

# Gate defensivo: o plugin fica habilitado globalmente, e em qualquer pasta
# que nao seja um Chief of Staff (CLAUDE.md + CRITICAL_FACTS.md juntos) o
# hook precisa ser invisivel.
[ -f CLAUDE.md ] && [ -f CRITICAL_FACTS.md ] || exit 0

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
