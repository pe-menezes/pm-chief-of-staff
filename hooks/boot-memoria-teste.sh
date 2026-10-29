#!/bin/sh
# Teste do gate do boot-memoria.sh, casos G1 a G6 da spec agents-md parte 1
# e G7 e G8 do conserto 1 da auditoria (pastas mudas sem CRITICAL_FACTS.md
# ou sem manual),
# e da cessao pra engine memoria-agente, casos C1 a C7 da parte 2 e C8, C9
# e H1 a H8 do conserto 1 da auditoria (janela de 2 dias e nome do host),
# e K1 e K2 do conserto 2 (prova de vida so por arquivo comum),
# e R1 a R5 da spec codex-compat-funcional (runtime Codex e caminho com espaco).
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
# .claude/data; terminado em / vira pasta vazia, nao arquivo. DATA: novo, ou
# o carimbo do touch -t (em UTC, sem horario de verao). PASTA_PATH: pasta
# posta na frente do PATH so durante o hook (o uname falso dos casos H e K).
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
  case "$prova" in
    */) mkdir -p "$tmp/.claude/data/$prova" ;;
    *) echo "{}" > "$tmp/.claude/data/$prova" ;;
  esac
  if [ "$data" != novo ]; then
    TZ=UTC0 touch -t "$data" "$tmp/.claude/data/$prova"
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
# (-v) ou do Linux (-d). O date e o touch -t rodam em UTC (TZ=UTC0): no fuso
# local, uma hora por ano o carimbo de 47 h cai na hora que o horario de
# verao repete, e o touch -t grava a primeira das duas.
ha_horas() {
  TZ=UTC0 date -v-"$1"H +%Y%m%d%H%M 2>/dev/null || TZ=UTC0 date -d "$1 hours ago" +%Y%m%d%H%M 2>/dev/null
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
# caso_h NOME CRU PASTA [ESPERADO]; CRU "-falha-" faz o uname sair com erro.
# ESPERADO e cede quando omitido; PASTA terminada em / e a pasta do host nova
# e vazia, sem prova dentro.
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
  case "$3" in
    */) caso_c "$1" "${4:-cede}" sim "sensor-efeito/$3" novo "$falso" ;;
    *) caso_c "$1" "${4:-cede}" sim "sensor-efeito/$3/2026-10.jsonl" novo "$falso" ;;
  esac
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

# Casos K1 e K2 do conserto 2 (achado K1 da revisao do Codex): so arquivo
# comum dentro da pasta deste host e prova de vida. Pasta com nome de .jsonl
# nao conta, nem a propria pasta do host quando o nome da maquina termina em
# .jsonl (o find testaria o ponto de partida).
caso_c "K1 pasta 2026-10.jsonl na pasta deste host" dispara sim "sensor-efeito/$HOST_DIR/2026-10.jsonl/" novo
caso_h "K2 host terminado em .jsonl com a pasta vazia" "maquina.jsonl" "maquina.jsonl/" dispara

# Casos R1 a R5 da spec codex-compat-funcional: o runtime Codex e o caminho
# com espaco. A engine memoria-agente grava telemetria so pelo Claude, entao
# o Codex nao cede a ela: o registro Codex passa o marcador codex ao hook,
# e sem marcador o hook segue a cessao de sempre. R1 roda o hook direto; R2
# a R5 leem o comando de cada registro (hooks/hooks.json do Claude e o hook
# inline de .codex-plugin/plugin.json), rodam por sh -c, como os dois
# agentes rodam comando de hook, com a raiz do plugin numa pasta com espaco.
# caso_r NOME ESPERADO ARQ CHAVE VAR [MARCADOR]
# ESPERADO: cede ou dispara. ARQ: registro relativo a raiz do repo. CHAVE:
# caminho do comando no JSON, em pontos. VAR: variavel da raiz do plugin.
# Toda pasta tem config e prova de vida nova deste host, a condicao da
# cessao no Claude.
comando_json() {
  if command -v plutil >/dev/null 2>&1; then
    plutil -extract "$2" raw -o - "$1" 2>/dev/null
  elif command -v node >/dev/null 2>&1; then
    node -e 'let v=require(process.argv[1]);for(const k of process.argv[2].split("."))v=v==null?v:v[k];if(typeof v!=="string")process.exit(1);process.stdout.write(v)' "$1" "$2" 2>/dev/null
  else
    return 1
  fi
}
RAIZ=$(cd "$DIR/.." && pwd)
caso_r() {
  nome="$1"
  esperado="$2"
  cmd=$(comando_json "$RAIZ/$3" "$4")
  if [ -z "$cmd" ]; then
    echo "FALHA $nome: comando ausente em $3 ($4), ou sem plutil e sem node pra ler"
    falhas=$((falhas + 1))
    return
  fi
  tmp=$(mktemp -d 2>/dev/null)
  if [ -z "$tmp" ] || [ ! -d "$tmp" ]; then
    echo "FALHA $nome: mktemp -d nao devolveu pasta"
    falhas=$((falhas + 1))
    return
  fi
  pacote="$tmp/pacote do plugin"
  pasta="$tmp/pasta da pessoa"
  mkdir -p "$pacote/hooks" "$pasta/.claude/data/sensor-efeito/$HOST_DIR"
  cp -p "$HOOK" "$pacote/hooks/boot-memoria.sh"
  echo "@AGENTS.md" > "$pasta/CLAUDE.md"
  echo "$FIXTURE" > "$pasta/CRITICAL_FACTS.md"
  echo "{}" > "$pasta/.claude/memoria-config.json"
  echo "{}" > "$pasta/.claude/data/sensor-efeito/$HOST_DIR/2026-10.jsonl"
  saida=$(cd "$pasta" && env "$5=$pacote" sh -c "$cmd" 2>/dev/null)
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
    if [ "$rc" -eq 0 ] && [ "$primeira" = "$MARCA" ] \
      && printf '%s\n' "$saida" | grep -qx "$FIXTURE"; then
      echo "ok    $nome"
    else
      echo "FALHA $nome: esperava boot completo (exit $rc, primeira linha: $primeira)"
      falhas=$((falhas + 1))
    fi
  fi
}

# R1: o hook direto com o marcador codex e a engine viva no Claude.
tmp=$(mktemp -d 2>/dev/null)
echo "@AGENTS.md" > "$tmp/CLAUDE.md"
echo "$FIXTURE" > "$tmp/CRITICAL_FACTS.md"
mkdir -p "$tmp/.claude/data/sensor-efeito/$HOST_DIR"
echo "{}" > "$tmp/.claude/memoria-config.json"
echo "{}" > "$tmp/.claude/data/sensor-efeito/$HOST_DIR/2026-10.jsonl"
saida=$(cd "$tmp" && "$HOOK" codex 2>/dev/null)
rc=$?
rm -rf "$tmp"
if [ "$rc" -eq 0 ] && [ "$(printf '%s\n' "$saida" | sed -n 1p)" = "$MARCA" ] \
  && printf '%s\n' "$saida" | grep -qx "$FIXTURE"; then
  echo "ok    R1 marcador codex nao cede a engine do Claude"
else
  echo "FALHA R1 marcador codex: esperava boot completo (exit $rc)"
  falhas=$((falhas + 1))
fi

caso_r "R2 registro Claude startup com espaco cede" cede \
  hooks/hooks.json hooks.SessionStart.0.hooks.0.command CLAUDE_PLUGIN_ROOT
caso_r "R3 registro Claude clear com espaco cede" cede \
  hooks/hooks.json hooks.SessionStart.1.hooks.0.command CLAUDE_PLUGIN_ROOT
caso_r "R4 registro Codex startup com espaco dispara" dispara \
  .codex-plugin/plugin.json hooks.hooks.SessionStart.0.hooks.0.command CLAUDE_PLUGIN_ROOT
caso_r "R5 registro Codex clear com espaco dispara" dispara \
  .codex-plugin/plugin.json hooks.hooks.SessionStart.1.hooks.0.command CLAUDE_PLUGIN_ROOT

[ "$falhas" -eq 0 ] || exit 1
exit 0
