#!/bin/sh
# Teste do gate do boot-memoria.sh, casos G1 a G6 da spec agents-md parte 1
# e G7 e G8 do conserto 1 da auditoria (pastas mudas sem CRITICAL_FACTS.md
# ou sem manual),
# e da cessao pra engine memoria-agente, casos C1 a C7 da parte 2 e C8, C9
# e H1 a H8 do conserto 1 da auditoria (janela de 2 dias e nome do host).
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
caso "G7 so CLAUDE.md" mudo CLAUDE.md
caso "G8 CF e nav sem manual" mudo CRITICAL_FACTS.md navegacao.md

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
  echo "info  hostname fora da identidade, C1/C5/C6/C8/C9 rodam com nome derivado: $HOST_DIR"
fi

# caso_c NOME ESPERADO CONFIG PROVA DATA [PASTA_PATH]
# ESPERADO: cede ou dispara. CONFIG: sim ou nao. PROVA: caminho sob
# .claude/data. DATA: novo, ou o carimbo do touch -t. PASTA_PATH: pasta
# posta na frente do PATH so durante o hook (o uname falso dos casos H).
caso_c() {
  nome="$1"
  esperado="$2"
  config="$3"
  prova="$4"
  data="$5"
  na_frente="$6"
  if [ -z "$data" ]; then
    echo "FALHA $nome: carimbo de data vazio"
    falhas=$((falhas + 1))
    return
  fi
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
  if [ -n "$na_frente" ]; then
    saida=$(cd "$tmp" && PATH="$na_frente:$PATH" "$HOOK" 2>/dev/null)
  else
    saida=$(cd "$tmp" && "$HOOK" 2>/dev/null)
  fi
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
# C3 e C7 reescritos no conserto 1 (achado B1): os logs sem host ganham data
# nova em todo clone, entao deixaram de ser prova e fazem o boot.
caso_c "C3 juiz novo" dispara sim "juiz-escrita-log.jsonl" novo
caso_c "C4 juiz de 12/10/2026" dispara sim "juiz-escrita-log.jsonl" 202610120000
caso_c "C5 sem config" dispara nao "sensor-efeito/$HOST_DIR/2026-10.jsonl" novo
caso_c "C6 sensor deste host antigo" dispara sim "sensor-efeito/$HOST_DIR/2000-01.jsonl" 200001010000
caso_c "C7 sensor-efeito-log novo" dispara sim "sensor-efeito-log.jsonl" novo

# Casos C8 e C9 do conserto 1 (achado A1): a fronteira da janela de 2 dias.
# -mtime -2 e idade abaixo de 48 h; 47 h cede e 49 h faz o boot, com 1 h de
# folga de cada lado. O carimbo e "agora menos N horas", pelo date do macOS
# (-v) ou do Linux (-d).
ha_horas() {
  date -v-"$1"H +%Y%m%d%H%M 2>/dev/null || date -d "$1 hours ago" +%Y%m%d%H%M 2>/dev/null
}
caso_c "C8 sensor deste host com 47 h" cede sim "sensor-efeito/$HOST_DIR/2026-10.jsonl" "$(ha_horas 47)"
caso_c "C9 sensor deste host com 49 h" dispara sim "sensor-efeito/$HOST_DIR/2026-10.jsonl" "$(ha_horas 49)"

# Casos H1 a H8 do conserto 1 (achado A2): a regra do nome do host. Um uname
# falso, numa pasta posta na frente do PATH so durante o hook, serve o nome;
# a prova nova fica na pasta que a engine grava. As pastas esperadas sao
# literais da tabela REGRA do caso "sensor 7n-t" do tests/smoke.sh da engine
# (origin/main 3558597), menos a do H7, que e a pasta_do_host da engine
# rodada sobre o nome cortado em 64 (o corte de host_maquina). Nada aqui cria
# variavel de ambiente nem muda o hook.
# caso_h NOME CRU PASTA; CRU "-falha-" faz o uname sair com erro.
caso_h() {
  falso=$(mktemp -d 2>/dev/null)
  if [ -z "$falso" ] || [ ! -d "$falso" ]; then
    echo "FALHA $1: mktemp -d nao devolveu pasta"
    falhas=$((falhas + 1))
    return
  fi
  if [ "$2" = "-falha-" ]; then
    printf '#!/bin/sh\necho "uname falso: erro" >&2\nexit 1\n' > "$falso/uname"
  else
    printf '%s\n' "$2" > "$falso/nome"
    printf '#!/bin/sh\ncat "%s/nome"\n' "$falso" > "$falso/uname"
  fi
  chmod +x "$falso/uname"
  caso_c "$1" cede sim "sensor-efeito/$3/2026-10.jsonl" novo "$falso"
  rm -rf "$falso"
}
caso_h "H1 ponto no comeco sai" ".oculto" "oculto"
caso_h "H2 barra vira hifen" "a/b" "a-b"
caso_h "H3 espacos viram hifen" "  " "--"
caso_h "H4 so pontos vira sem-host" "..." "sem-host"
caso_h "H5 vazio vira sem-host" "" "sem-host"
caso_h "H6 80 caracteres cortam em 64" \
  "hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh" \
  "hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh"
caso_h "H7 corte em 64 antes de tirar os pontos" \
  "..........aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" \
  "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
caso_h "H8 uname falhando vira sem-host" "-falha-" "sem-host"

[ "$falhas" -eq 0 ] || exit 1
exit 0
