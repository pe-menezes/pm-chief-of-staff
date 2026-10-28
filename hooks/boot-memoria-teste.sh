#!/bin/sh
# Teste do gate do boot-memoria.sh, casos G1 a G6 da spec agents-md parte 1.
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

[ "$falhas" -eq 0 ] || exit 1
exit 0
