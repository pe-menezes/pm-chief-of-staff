#!/bin/sh
# Teste do gate do boot-memoria.sh, casos G1 a G6 da spec agents-md parte 1,
# e da cessao pra engine memoria-agente, casos C1 a C7 da parte 2.
# Roda a mao: sh hooks/boot-memoria-teste.sh
# Cada caso monta uma pasta de mktemp -d, roda o hook la dentro num subshell
# (o hook le caminhos relativos ao cwd, como na sessao real) e apaga a pasta.
# Disparo se confere pelo cabecalho fixo do boot e pela fixture do
# CRITICAL_FACTS.md na carga, nunca pelo texto inteiro.
# Saida: uma linha ok ou FALHA por caso; exit 0 so com tudo passando.

DIR=$(cd "$(dirname "$0")" && pwd) || exit 1
HOOK="$DIR/boot-memoria.sh"
MARCA="=== BOOT DE MEMORIA (pm-chief-of-staff) ==="
FIXTURE="fixture-critical-facts-g"
falhas=0

if [ -x "$HOOK" ]; then
  echo "ok    bit de execucao do hook"
else
  echo "FALHA bit de execucao do hook ausente: $HOOK"
  falhas=$((falhas + 1))
fi

# caso NOME ESPERADO ARQUIVO...
# ESPERADO: dispara ou mudo. CLAUDE.md nasce com a ponte de uma linha.
caso() {
  nome="$1"
  esperado="$2"
  shift 2
  tmp=$(mktemp -d 2>/dev/null)
  if [ -z "$tmp" ] || [ ! -d "$tmp" ]; then
    echo "FALHA $nome: mktemp -d nao devolveu pasta"
    falhas=$((falhas + 1))
    return
  fi
  for arq in "$@"; do
    case "$arq" in
      CLAUDE.md) echo "@AGENTS.md" > "$tmp/$arq" ;;
      CRITICAL_FACTS.md) echo "$FIXTURE" > "$tmp/$arq" ;;
      *) echo "conteudo de $arq" > "$tmp/$arq" ;;
    esac
  done
  saida=$(cd "$tmp" && "$HOOK" 2>/dev/null)
  rc=$?
  rm -rf "$tmp"
  primeira=$(printf '%s\n' "$saida" | sed -n 1p)
  if [ "$esperado" = dispara ]; then
    if [ "$rc" -eq 0 ] && [ "$primeira" = "$MARCA" ] \
      && printf '%s\n' "$saida" | grep -qx "$FIXTURE"; then
      echo "ok    $nome"
    else
      echo "FALHA $nome: esperava disparo (exit $rc, primeira linha: $primeira)"
      falhas=$((falhas + 1))
    fi
  else
    if [ "$rc" -eq 0 ] && [ -z "$saida" ]; then
      echo "ok    $nome"
    else
      echo "FALHA $nome: esperava exit 0 e stdout vazio (exit $rc, stdout: $primeira)"
      falhas=$((falhas + 1))
    fi
  fi
}

caso "G1 pasta antiga" dispara CLAUDE.md CRITICAL_FACTS.md
caso "G2 nova com ponte" dispara AGENTS.md CLAUDE.md CRITICAL_FACTS.md navegacao.md
caso "G3 nova sem ponte" dispara AGENTS.md CRITICAL_FACTS.md navegacao.md
caso "G4 molde do vault" mudo AGENTS.md CRITICAL_FACTS.md
caso "G5 repo com AGENTS.md" mudo AGENTS.md navegacao.md
caso "G6 vazia" mudo

# Casos C1 a C7 da spec agents-md parte 2: a cessao pra engine memoria-agente.
# Toda pasta parte do molde antigo (CLAUDE.md + CRITICAL_FACTS.md), pro gate
# passar. A prova e um arquivo sob .claude/data com mtime nova (touch sem
# data) ou forcada por touch -t.
CEDE="memoria-agente presente, injeção de abertura cedida à engine"

# Pasta deste host em sensor-efeito. Com uname -n so em [A-Za-z0-9._-], sem
# ponto no comeco e com ate 64 caracteres, a regra da engine e a identidade e
# o teste usa o proprio nome. Fora disso o teste deriva o nome por conta
# propria (sem copiar o hook) e avisa na saida.
HOST_CRU=$(uname -n 2>/dev/null)
case "$HOST_CRU" in
  ''|.*|*[!A-Za-z0-9._-]*) identidade=nao ;;
  *) identidade=sim ;;
esac
[ "${#HOST_CRU}" -le 64 ] || identidade=nao
if [ "$identidade" = sim ]; then
  HOST_DIR="$HOST_CRU"
else
  HOST_DIR=$(printf '%s' "$HOST_CRU" | LC_ALL=C cut -c1-64 | LC_ALL=C sed 's/[^A-Za-z0-9._-]/-/g; s/^\.\{1,\}//' | LC_ALL=C cut -c1-64)
  [ -n "$HOST_DIR" ] || HOST_DIR=sem-host
  echo "info  hostname fora da identidade, C1/C5/C6 rodam com nome derivado: $HOST_DIR"
fi

# caso_c NOME ESPERADO CONFIG PROVA DATA
# ESPERADO: cede ou dispara. CONFIG: sim ou nao. PROVA: caminho sob
# .claude/data. DATA: novo, ou o carimbo do touch -t.
caso_c() {
  nome="$1"
  esperado="$2"
  config="$3"
  prova="$4"
  data="$5"
  tmp=$(mktemp -d 2>/dev/null)
  if [ -z "$tmp" ] || [ ! -d "$tmp" ]; then
    echo "FALHA $nome: mktemp -d nao devolveu pasta"
    falhas=$((falhas + 1))
    return
  fi
  echo "@AGENTS.md" > "$tmp/CLAUDE.md"
  echo "$FIXTURE" > "$tmp/CRITICAL_FACTS.md"
  mkdir -p "$tmp/.claude/data/$(dirname "$prova")"
  [ "$config" = sim ] && echo "{}" > "$tmp/.claude/memoria-config.json"
  echo "{}" > "$tmp/.claude/data/$prova"
  if [ "$data" != novo ]; then
    touch -t "$data" "$tmp/.claude/data/$prova"
  fi
  saida=$(cd "$tmp" && "$HOOK" 2>/dev/null)
  rc=$?
  rm -rf "$tmp"
  primeira=$(printf '%s\n' "$saida" | sed -n 1p)
  if [ "$esperado" = cede ]; then
    if [ "$rc" -eq 0 ] && [ "$saida" = "$CEDE" ]; then
      echo "ok    $nome"
    else
      echo "FALHA $nome: esperava so a linha da cessao (exit $rc, primeira linha: $primeira)"
      falhas=$((falhas + 1))
    fi
  else
    if [ "$rc" -eq 0 ] && printf '%s\n' "$saida" | grep -qxF "$MARCA"; then
      echo "ok    $nome"
    else
      echo "FALHA $nome: esperava boot completo (exit $rc, primeira linha: $primeira)"
      falhas=$((falhas + 1))
    fi
  fi
}

caso_c "C1 sensor deste host novo" cede sim "sensor-efeito/$HOST_DIR/2026-10.jsonl" novo
caso_c "C2 sensor de outro host novo" dispara sim "sensor-efeito/outra-maquina-de-teste/2026-10.jsonl" novo
caso_c "C3 juiz novo" cede sim "juiz-escrita-log.jsonl" novo
caso_c "C4 juiz de 12/10/2026" dispara sim "juiz-escrita-log.jsonl" 202610120000
caso_c "C5 sem config" dispara nao "sensor-efeito/$HOST_DIR/2026-10.jsonl" novo
caso_c "C6 sensor deste host antigo" dispara sim "sensor-efeito/$HOST_DIR/2000-01.jsonl" 200001010000
caso_c "C7 sensor-efeito-log novo" cede sim "sensor-efeito-log.jsonl" novo

[ "$falhas" -eq 0 ] || exit 1
exit 0
