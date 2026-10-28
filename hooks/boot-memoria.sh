#!/bin/sh
# Boot de memoria do pm-chief-of-staff: roda no SessionStart e injeta na
# sessao o estado gravado em disco (CRITICAL_FACTS.md, navegacao.md e o log
# do dia), pra abertura ja comecar sabendo onde as coisas estao.
# Matchers: startup e clear, so os dois. Apos um compact o resumo ja carrega
# o estado da sessao, e reinjetar duplicaria.
# Tudo que sai em stdout vira contexto, entao erro nunca vai pra stdout.
# Com a engine memoria-agente configurada E viva neste projeto, a engine
# assume a injecao de abertura e este hook cede avisando em 1 linha.
# Engine configurada mas sem sinal de vida recente NAO ganha a cessao:
# zero boot e pior que boot duplo. Engine recem-instalada tem boot duplo
# ate o primeiro evento de telemetria, aceito como fail-open.
# Prova de vida aceita, uma so: .claude/data/sensor-efeito/<pasta deste
# host>/*.jsonl modificado ha menos de 2 dias, que a engine grava da 0.14.0
# em diante (na engine: INSTALL.md, docs/architecture.md e
# scripts/sensor_efeito.py).
# So a pasta deste host conta: .claude/data viaja entre maquinas, e o evento
# de outra maquina faria esta, sem a engine, abrir sem boot nenhum.
# Sairam as provas da engine ate a 0.13.0 (.claude/data/sensor-efeito-log.jsonl
# e .claude/data/juiz-*-log.jsonl): nao tem host, e todo clone novo da a
# elas data de agora, entao uma maquina sem a engine cedia e ficava sem boot
# nenhum por ate 2 dias. Engine ate a 0.13.0 volta a ter boot duplo, o lado
# aceito.
# A pasta deste host segue a regra da engine (scripts/sensor_efeito.py,
# pasta_do_host) sobre uname -n: corte em 64, todo caractere fora de
# [A-Za-z0-9._-] vira hifen, saem os pontos do comeco, corte em 64, vazio
# vira sem-host. Limite: hostname fora de ASCII, ou trocado pela rede no
# macOS, pode dar nome diferente do da engine, e ai o hook nao cede (boot
# duplo, o lado aceito).

# Gate defensivo: o plugin fica habilitado globalmente, e em qualquer pasta
# que nao seja um Chief of Staff o hook precisa ser invisivel. Chief of Staff
# e CRITICAL_FACTS.md junto com CLAUDE.md (pasta antiga) ou junto com o par
# AGENTS.md + navegacao.md (pasta nova, com ou sem a ponte CLAUDE.md).
# AGENTS.md com CRITICAL_FACTS.md nao basta: pasta de outro sistema pode ter
# os dois nomes e ficaria com o boot duplicado. O navegacao.md, que o setup
# cria e este hook ja le, e a terceira evidencia.
[ -f CRITICAL_FACTS.md ] || exit 0
[ -f CLAUDE.md ] || { [ -f AGENTS.md ] && [ -f navegacao.md ]; } || exit 0

# Cessao pra engine memoria-agente, com duas evidencias obrigatorias:
# 1) .claude/memoria-config.json na raiz do projeto, o config que a skill
#    de instalacao dela escreve (instalada no ambiente nao implica ativa
#    nesta pasta);
# 2) a prova de vida do topo, na pasta deste host, modificada nos ultimos
#    2 dias.
# A cessao avisa em 1 linha pra ausencia simultanea dos dois boots ficar
# visivel.
host_dir=$(uname -n 2>/dev/null | LC_ALL=C cut -c1-64 2>/dev/null \
  | LC_ALL=C tr -c 'A-Za-z0-9._\n-' '-' 2>/dev/null \
  | LC_ALL=C sed 's/^\.*//' 2>/dev/null | LC_ALL=C cut -c1-64 2>/dev/null)
[ -n "$host_dir" ] || host_dir=sem-host
if [ -f .claude/memoria-config.json ] \
  && find ".claude/data/sensor-efeito/$host_dir" -maxdepth 1 -name '*.jsonl' -mtime -2 2>/dev/null | grep -q .; then
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
