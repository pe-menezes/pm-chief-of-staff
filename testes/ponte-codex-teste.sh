#!/bin/sh
# Teste da ponte Codex (modulos/ponte-codex.sh), parte 1 da spec
# codex-compat-funcional: a pasta da pessoa ganha .agents/skills apontando
# pra fonte unica .claude/skills, sem substituir nada que ja exista.
# Roda a mao: sh testes/ponte-codex-teste.sh
# Cada caso monta uma pasta de mktemp -d com espaco no nome, roda a ponte
# la dentro (a ponte le caminhos relativos ao cwd, como na sessao real) e
# apaga a pasta. Os casos conferem o estado do disco e o codigo de saida,
# nunca o texto da ponte.
# Com o codex no PATH, os casos D rodam `codex debug prompt-input` na pasta
# montada, que monta o prompt sem chamar modelo: prova descoberta, nao
# execucao. Sem o codex, os casos D saem como "info" e o resto roda igual.
# Saida: uma linha ok ou FALHA por caso; exit 0 so com tudo passando.
#
# Prova manual, fora deste teste, porque depende de modelo ou de instalacao
# persistente (feita por quem decide instalar, nunca por este script):
# 1) instalacao: `codex plugin add` do marketplace local grava cache e
#    config; depois, as 5 skills do plugin aparecem e as 6 sementes nao.
# 2) hook: revisar e confiar o hook em /hooks do Codex; abrir sessao numa
#    pasta de Chief of Staff com telemetria da memoria-agente e conferir o
#    boot na abertura; conferir se o Codex le so o hook do manifest ou
#    tambem hooks/hooks.json (boot duplo e o lado aceito).
# 3) modelo: setup, plantar e criar-skill rodam a ponte e tratam o conflito
#    sem apagar; skill editada em .claude/skills aparece na sessao Codex
#    seguinte; AGENTS.md gerado traz o indice de regras; remove-ai-tells
#    abre subagente novo pro revisor, sem historico, e outro na releitura.
# 4) regressao Claude: sessao com --plugin-dir neste repo, boot e cessao.

DIR=$(cd "$(dirname "$0")/.." && pwd) || exit 1
PONTE="$DIR/modulos/ponte-codex.sh"
SENT="COS_PONTE_SENTINELA"
falhas=0

ok() { echo "ok    $1"; }
falha() { echo "FALHA $1: $2"; falhas=$((falhas + 1)); }

# monta PASTA: fonte com duas skills e o _shared, que nao e skill.
monta() {
  mkdir -p "$1/.claude/skills/abrir-dia" "$1/.claude/skills/fechar-dia" "$1/.claude/skills/_shared"
  printf -- '---\nname: abrir-dia\ndescription: %s abrir.\n---\n\n# Abrir\ncorpo da pessoa\n' "$SENT" > "$1/.claude/skills/abrir-dia/SKILL.md"
  printf -- '---\nname: fechar-dia\ndescription: >\n  %s fechar,\n  em duas linhas.\n---\n\n# Fechar\n' "$SENT" > "$1/.claude/skills/fechar-dia/SKILL.md"
  echo "modulo" > "$1/.claude/skills/_shared/capacidades.md"
}

# nova: pasta temporaria com espaco no nome, devolvida em $tmp e $pasta.
nova() {
  tmp=$(mktemp -d 2>/dev/null)
  if [ -z "$tmp" ] || [ ! -d "$tmp" ]; then
    falha "$1" "mktemp -d nao devolveu pasta"
    return 1
  fi
  pasta="$tmp/minha pasta de cos"
  mkdir -p "$pasta"
}

# roda [PASTA_PATH]: roda a ponte em $pasta, guarda o codigo em $rc.
roda() {
  if [ -n "$1" ]; then
    (cd "$pasta" && PATH="$1:$PATH" sh "$PONTE" >/dev/null 2>&1)
  else
    (cd "$pasta" && sh "$PONTE" >/dev/null 2>&1)
  fi
  rc=$?
}

if [ -f "$PONTE" ]; then
  ok "ponte existe"
else
  falha "ponte existe" "$PONTE ausente"
fi

# P1 pasta limpa: nasce o link relativo da colecao inteira.
if nova P1; then
  monta "$pasta"
  roda
  alvo=$(readlink "$pasta/.agents/skills" 2>/dev/null)
  if [ "$rc" -eq 0 ] && [ "$alvo" = "../.claude/skills" ] \
    && [ -f "$pasta/.agents/skills/abrir-dia/SKILL.md" ]; then
    ok "P1 pasta limpa ganha link relativo da colecao"
  else
    falha "P1 pasta limpa" "exit $rc, link: $alvo"
  fi
  # P2 de novo na mesma pasta: nada muda, exit 0.
  roda
  alvo2=$(readlink "$pasta/.agents/skills" 2>/dev/null)
  if [ "$rc" -eq 0 ] && [ "$alvo2" = "../.claude/skills" ]; then
    ok "P2 segunda rodada nao mexe"
  else
    falha "P2 segunda rodada" "exit $rc, link: $alvo2"
  fi
  # P3 edicao na fonte aparece pelo link, sem copia.
  echo "edicao canonica" >> "$pasta/.claude/skills/abrir-dia/SKILL.md"
  if grep -qx "edicao canonica" "$pasta/.agents/skills/abrir-dia/SKILL.md" 2>/dev/null; then
    ok "P3 edicao da fonte aparece na ponte"
  else
    falha "P3 edicao da fonte" "nao apareceu em .agents/skills"
  fi
  rm -rf "$tmp"
fi

# P4 .agents/skills ja e link pra outro lugar: fica como esta, exit 2.
if nova P4; then
  monta "$pasta"
  mkdir -p "$pasta/.agents" "$pasta/outra"
  ln -s ../outra "$pasta/.agents/skills"
  roda
  alvo=$(readlink "$pasta/.agents/skills" 2>/dev/null)
  if [ "$rc" -eq 2 ] && [ "$alvo" = "../outra" ]; then
    ok "P4 link da pessoa pra outro lugar fica"
  else
    falha "P4 link da pessoa" "exit $rc, link: $alvo"
  fi
  rm -rf "$tmp"
fi

# P5 .agents/skills e arquivo comum: fica como esta, exit 2.
if nova P5; then
  monta "$pasta"
  mkdir -p "$pasta/.agents"
  echo "arquivo da pessoa" > "$pasta/.agents/skills"
  roda
  if [ "$rc" -eq 2 ] && [ -f "$pasta/.agents/skills" ] && [ ! -L "$pasta/.agents/skills" ] \
    && grep -qx "arquivo da pessoa" "$pasta/.agents/skills"; then
    ok "P5 arquivo da pessoa no lugar da ponte fica"
  else
    falha "P5 arquivo da pessoa" "exit $rc"
  fi
  rm -rf "$tmp"
fi

# P6 link quebrado em .agents/skills: fica como esta, exit 2.
if nova P6; then
  monta "$pasta"
  mkdir -p "$pasta/.agents"
  ln -s ../nao-existe "$pasta/.agents/skills"
  roda
  alvo=$(readlink "$pasta/.agents/skills" 2>/dev/null)
  if [ "$rc" -eq 2 ] && [ "$alvo" = "../nao-existe" ]; then
    ok "P6 link quebrado fica"
  else
    falha "P6 link quebrado" "exit $rc, link: $alvo"
  fi
  rm -rf "$tmp"
fi

# P7 .agents/skills pasta real com skill da pessoa de mesmo nome: a dela
# fica intacta, a que falta ganha link individual, _shared nao entra, exit 2.
if nova P7; then
  monta "$pasta"
  mkdir -p "$pasta/.agents/skills/abrir-dia"
  echo "skill codex da pessoa" > "$pasta/.agents/skills/abrir-dia/SKILL.md"
  roda
  alvo=$(readlink "$pasta/.agents/skills/fechar-dia" 2>/dev/null)
  if [ "$rc" -eq 2 ] && [ ! -L "$pasta/.agents/skills" ] \
    && [ "$(cat "$pasta/.agents/skills/abrir-dia/SKILL.md")" = "skill codex da pessoa" ] \
    && [ "$alvo" = "../../.claude/skills/fechar-dia" ] \
    && [ ! -e "$pasta/.agents/skills/_shared" ] && [ ! -L "$pasta/.agents/skills/_shared" ]; then
    ok "P7 pasta real: a da pessoa fica, a que falta ganha link, _shared fora"
  else
    falha "P7 pasta real" "exit $rc, link fechar-dia: $alvo"
  fi
  # P8 rodada seguinte com a colisao resolvida pela pessoa: exit 0, link mantido.
  rm -rf "$pasta/.agents/skills/abrir-dia"
  roda
  if [ "$rc" -eq 0 ] && [ "$(readlink "$pasta/.agents/skills/abrir-dia" 2>/dev/null)" = "../../.claude/skills/abrir-dia" ] \
    && [ "$(readlink "$pasta/.agents/skills/fechar-dia" 2>/dev/null)" = "../../.claude/skills/fechar-dia" ]; then
    ok "P8 pasta real sem colisao fecha com exit 0"
  else
    falha "P8 pasta real sem colisao" "exit $rc"
  fi
  rm -rf "$tmp"
fi

# P9 sem .claude/skills: nada nasce, exit 1.
if nova P9; then
  roda
  if [ "$rc" -eq 1 ] && [ ! -e "$pasta/.agents" ] && [ ! -L "$pasta/.agents" ]; then
    ok "P9 sem fonte nada nasce"
  else
    falha "P9 sem fonte" "exit $rc"
  fi
  rm -rf "$tmp"
fi

# E1 .agents e link pra pasta da pessoa fora do workspace: link e alvo
# ficam como estao, nada nasce la, exit 2.
if nova E1; then
  monta "$pasta"
  mkdir -p "$tmp/fora"
  echo "da pessoa" > "$tmp/fora/nota.md"
  ln -s ../fora "$pasta/.agents"
  antes=$(ls -lAR "$tmp/fora" | cksum)
  roda
  if [ "$rc" -eq 2 ] && [ "$(readlink "$pasta/.agents")" = "../fora" ] \
    && [ ! -e "$tmp/fora/skills" ] && [ ! -L "$tmp/fora/skills" ] \
    && [ "$(ls -lAR "$tmp/fora" | cksum)" = "$antes" ]; then
    ok "E1 .agents em link pra fora fica, nada nasce no alvo"
  else
    falha "E1 .agents em link" "exit $rc, alvo: $(ls -A "$tmp/fora" | tr '\n' ' ')"
  fi
  rm -rf "$tmp"
fi

# E2 .agents e link quebrado: fica, o alvo continua sem existir, exit 2.
if nova E2; then
  monta "$pasta"
  ln -s ../nao-existe "$pasta/.agents"
  roda
  if [ "$rc" -eq 2 ] && [ "$(readlink "$pasta/.agents")" = "../nao-existe" ] \
    && [ ! -e "$tmp/nao-existe" ] && [ ! -L "$tmp/nao-existe" ]; then
    ok "E2 .agents em link quebrado fica"
  else
    falha "E2 .agents em link quebrado" "exit $rc"
  fi
  rm -rf "$tmp"
fi

# Casos W: link indisponivel. Um ln falso, posto na frente do PATH so
# durante a ponte, sai com erro, como em sistema sem link simbolico.
falso=$(mktemp -d 2>/dev/null)
printf '#!/bin/sh\necho "ln falso: sem link" >&2\nexit 1\n' > "$falso/ln"
chmod +x "$falso/ln"

# W1 sem link: wrapper por skill com o frontmatter da fonte e a leitura dela.
if nova W1; then
  monta "$pasta"
  roda "$falso"
  w="$pasta/.agents/skills/fechar-dia/SKILL.md"
  fm_fonte=$(sed -n '1,/^---$/p' "$pasta/.claude/skills/fechar-dia/SKILL.md" | sed -n '2,$p')
  fm_w=$(sed -n '1,/^---$/p' "$w" 2>/dev/null | sed -n '2,$p')
  if [ "$rc" -eq 0 ] && [ ! -L "$pasta/.agents/skills" ] && [ -f "$w" ] && [ ! -L "$pasta/.agents/skills/fechar-dia" ] \
    && [ -n "$fm_w" ] && [ "$fm_w" = "$fm_fonte" ] \
    && grep -qF ".claude/skills/fechar-dia/SKILL.md" "$w" \
    && [ -f "$pasta/.agents/skills/abrir-dia/SKILL.md" ] \
    && [ ! -e "$pasta/.agents/skills/_shared" ]; then
    ok "W1 sem link: wrapper com frontmatter da fonte e ponteiro"
  else
    falha "W1 sem link" "exit $rc"
  fi
  # W2 description mudou na fonte: o wrapper gerado acompanha.
  sed 's/abrir\./abrir, mudada./' "$pasta/.claude/skills/abrir-dia/SKILL.md" > "$tmp/novo"
  cat "$tmp/novo" > "$pasta/.claude/skills/abrir-dia/SKILL.md"
  roda "$falso"
  if [ "$rc" -eq 0 ] && grep -qF "$SENT abrir, mudada." "$pasta/.agents/skills/abrir-dia/SKILL.md"; then
    ok "W2 wrapper gerado acompanha a description"
  else
    falha "W2 wrapper acompanha" "exit $rc"
  fi
  # W2b o wrapper atualizado segue integro: a rodada seguinte nao acusa conflito.
  antes=$(cksum < "$pasta/.agents/skills/abrir-dia/SKILL.md")
  roda "$falso"
  if [ "$rc" -eq 0 ] && [ "$(cksum < "$pasta/.agents/skills/abrir-dia/SKILL.md")" = "$antes" ]; then
    ok "W2b wrapper atualizado segue integro"
  else
    falha "W2b wrapper atualizado integro" "exit $rc"
  fi
  # W3 wrapper sem a marca da ponte e da pessoa: fica, exit 2.
  printf -- '---\nname: fechar-dia\ndescription: minha versao.\n---\nescrito a mao\n' > "$pasta/.agents/skills/fechar-dia/SKILL.md"
  roda "$falso"
  if [ "$rc" -eq 2 ] && grep -qx "escrito a mao" "$pasta/.agents/skills/fechar-dia/SKILL.md"; then
    ok "W3 SKILL.md da pessoa em .agents/skills fica"
  else
    falha "W3 SKILL.md da pessoa" "exit $rc"
  fi
  rm -rf "$tmp"
fi

# W4 a W6: wrapper com a marca mas mexido pela pessoa, ou sem a prova de
# integridade (formato anterior). A fonte muda, entao uma atualizacao
# indevida trocaria o arquivo; o wrapper fica byte a byte, exit 2.
# mexe CASO DESCRICAO: gera o wrapper, aplica a edicao em $w, muda a fonte,
# roda de novo e confere.
mexe() {
  if nova "$1"; then
    monta "$pasta"
    roda "$falso"
    w="$pasta/.agents/skills/abrir-dia/SKILL.md"
    case "$1" in
      W4) echo "Instrucao acrescentada pela pessoa." >> "$w" ;;
      W5) sed 's/abrir\./abrir, versao da pessoa./' "$w" > "$tmp/novo" && cat "$tmp/novo" > "$w" ;;
      W6) sed '$d' "$w" > "$tmp/novo" && cat "$tmp/novo" > "$w" ;;
    esac
    antes=$(cksum < "$w")
    sed 's/abrir\./abrir, mudada./' "$pasta/.claude/skills/abrir-dia/SKILL.md" > "$tmp/novo"
    cat "$tmp/novo" > "$pasta/.claude/skills/abrir-dia/SKILL.md"
    roda "$falso"
    if [ "$rc" -eq 2 ] && [ -f "$w" ] && [ ! -L "$w" ] && [ "$(cksum < "$w")" = "$antes" ]; then
      ok "$1 $2"
    else
      falha "$1 $2" "exit $rc, wrapper mudou: $(cksum < "$w") contra $antes"
    fi
    rm -rf "$tmp"
  fi
}
mexe W4 "corpo do wrapper editado com a marca fica"
mexe W5 "metadata do wrapper editada com a marca fica"
mexe W6 "wrapper com a marca e sem prova de integridade fica"

# E3 .agents e link pra fora com wrapper gerado la: nada no alvo muda,
# nem com a fonte mudada e sem link no sistema, exit 2.
if nova E3; then
  monta "$pasta"
  mkdir -p "$tmp/gera"
  monta "$tmp/gera"
  (cd "$tmp/gera" && PATH="$falso:$PATH" sh "$PONTE" >/dev/null 2>&1)
  mv "$tmp/gera/.agents" "$tmp/fora"
  ln -s ../fora "$pasta/.agents"
  echo "edicao canonica" >> "$pasta/.claude/skills/abrir-dia/SKILL.md"
  antes=$(ls -lAR "$tmp/fora" | cksum)
  wantes=$(cksum < "$tmp/fora/skills/abrir-dia/SKILL.md" 2>/dev/null)
  roda "$falso"
  if [ "$rc" -eq 2 ] && [ -n "$wantes" ] && [ "$(readlink "$pasta/.agents")" = "../fora" ] \
    && [ "$(cksum < "$tmp/fora/skills/abrir-dia/SKILL.md")" = "$wantes" ] \
    && [ "$(ls -lAR "$tmp/fora" | cksum)" = "$antes" ]; then
    ok "E3 wrapper fora do workspace nao se atualiza pelo link de .agents"
  else
    falha "E3 wrapper fora pelo link" "exit $rc"
  fi
  rm -rf "$tmp"
fi

# F3 a primeira gravacao do wrapper falha: a pasta vazia que a rodada criou
# sai, exit 1; sem o limite, a mesma pasta ganha o wrapper, exit 0.
if nova F3; then
  monta "$pasta"
  longa=$(awk 'BEGIN { for (i = 0; i < 400; i++) printf "palavra%03d ", i }')
  printf -- '---\nname: abrir-dia\ndescription: %s %s\n---\n\n# Abrir\n' "$SENT" "$longa" > "$pasta/.claude/skills/abrir-dia/SKILL.md"
  (cd "$pasta" && ulimit -c 0 && ulimit -f 1 && PATH="$falso:$PATH" sh "$PONTE" >/dev/null 2>&1)
  rc=$?
  d="$pasta/.agents/skills/abrir-dia"
  if [ "$rc" -eq 1 ] && [ ! -e "$d" ] && [ ! -L "$d" ]; then
    ok "F3 falha na primeira gravacao nao deixa pasta vazia"
  else
    falha "F3 falha na primeira gravacao" "exit $rc, entradas: $(ls -A "$d" 2>/dev/null | tr '\n' ' ')"
  fi
  roda "$falso"
  if [ "$rc" -eq 0 ] && grep -qF "palavra399" "$d/SKILL.md" 2>/dev/null \
    && [ "$(ls -A "$d" | wc -l | tr -d ' ')" -eq 1 ]; then
    ok "F3b rodada seguinte cria o wrapper na mesma pasta"
  else
    falha "F3b rodada seguinte" "exit $rc"
  fi
  rm -rf "$tmp"
fi

# F4 a gravacao falha, mas a pasta ganhou conteudo da pessoa nesse meio
# tempo (ln falso que cria o arquivo): o conteudo fica, so a gravacao falha.
falso2=$(mktemp -d 2>/dev/null)
printf '#!/bin/sh\nexit 1\n' > "$falso2/ln"
printf '#!/bin/sh\n/bin/mkdir "$@" || exit $?\nfor a; do case "$a" in -*) ;; *) echo "da pessoa" > "$a/notas.md" ;; esac; done\n' > "$falso2/mkdir"
chmod +x "$falso2/ln" "$falso2/mkdir"
if nova F4; then
  monta "$pasta"
  mkdir -p "$pasta/.agents/skills"
  longa=$(awk 'BEGIN { for (i = 0; i < 400; i++) printf "palavra%03d ", i }')
  printf -- '---\nname: abrir-dia\ndescription: %s %s\n---\n\n# Abrir\n' "$SENT" "$longa" > "$pasta/.claude/skills/abrir-dia/SKILL.md"
  (cd "$pasta" && ulimit -c 0 && ulimit -f 1 && PATH="$falso2:$PATH" sh "$PONTE" >/dev/null 2>&1)
  rc=$?
  d="$pasta/.agents/skills/abrir-dia"
  if [ "$rc" -eq 1 ] && grep -qx "da pessoa" "$d/notas.md" 2>/dev/null \
    && [ "$(ls -A "$d" | wc -l | tr -d ' ')" -eq 1 ]; then
    ok "F4 falha na primeira gravacao preserva o que apareceu na pasta"
  else
    falha "F4 conteudo preservado" "exit $rc, entradas: $(ls -A "$d" 2>/dev/null | tr '\n' ' ')"
  fi
  rm -rf "$tmp"
fi
rm -rf "$falso2"

# S1 SKILL.md em .agents/skills e link pra arquivo da pessoa, e o alvo tem a
# marca da ponte: link e alvo ficam como estao, exit 2.
if nova S1; then
  monta "$pasta"
  roda "$falso"
  w="$pasta/.agents/skills/abrir-dia/SKILL.md"
  cp "$w" "$tmp/da pessoa.md"
  echo "texto da pessoa" >> "$tmp/da pessoa.md"
  antes=$(cksum < "$tmp/da pessoa.md")
  rm "$w"
  ln -s "../../../../da pessoa.md" "$w"
  roda "$falso"
  if [ "$rc" -eq 2 ] && [ -L "$w" ] && [ "$(readlink "$w")" = "../../../../da pessoa.md" ] \
    && [ "$(cksum < "$tmp/da pessoa.md")" = "$antes" ]; then
    ok "S1 SKILL.md ligado a arquivo da pessoa com a marca fica"
  else
    falha "S1 SKILL.md ligado" "exit $rc, alvo mudou ou link trocado"
  fi
  rm -rf "$tmp"
fi

# S2 SKILL.md em .agents/skills e link quebrado: fica, nada nasce no alvo, exit 2.
if nova S2; then
  monta "$pasta"
  roda "$falso"
  w="$pasta/.agents/skills/abrir-dia/SKILL.md"
  rm "$w"
  ln -s "../../../../nao-existe.md" "$w"
  roda "$falso"
  if [ "$rc" -eq 2 ] && [ -L "$w" ] && [ "$(readlink "$w")" = "../../../../nao-existe.md" ] \
    && [ ! -e "$tmp/nao-existe.md" ]; then
    ok "S2 SKILL.md em link quebrado fica"
  else
    falha "S2 SKILL.md em link quebrado" "exit $rc"
  fi
  rm -rf "$tmp"
fi

# F1 escrita falha na atualizacao do wrapper (limite de tamanho de arquivo
# so no subshell da ponte, sem core): o anterior fica identico, o arquivo da
# pessoa na mesma pasta fica, nao sobra temporario, exit 1.
if nova F1; then
  monta "$pasta"
  roda "$falso"
  d="$pasta/.agents/skills/abrir-dia"
  echo "notas da pessoa" > "$d/notas.md"
  antes=$(cksum < "$d/SKILL.md")
  longa=$(awk 'BEGIN { for (i = 0; i < 400; i++) printf "palavra%03d ", i }')
  printf -- '---\nname: abrir-dia\ndescription: %s %s\n---\n\n# Abrir\n' "$SENT" "$longa" > "$pasta/.claude/skills/abrir-dia/SKILL.md"
  (cd "$pasta" && ulimit -c 0 && ulimit -f 1 && PATH="$falso:$PATH" sh "$PONTE" >/dev/null 2>&1)
  rc=$?
  if [ "$rc" -eq 1 ] && [ -f "$d/SKILL.md" ] && [ ! -L "$d/SKILL.md" ] \
    && [ "$(cksum < "$d/SKILL.md")" = "$antes" ] \
    && grep -qx "notas da pessoa" "$d/notas.md" \
    && [ "$(ls -A "$d" | wc -l | tr -d ' ')" -eq 2 ]; then
    ok "F1 falha de escrita deixa o wrapper anterior e nao declara sucesso"
  else
    falha "F1 falha de escrita" "exit $rc, entradas: $(ls -A "$d" | tr '\n' ' ')"
  fi
  # F2 sem o limite, a mesma pasta atualiza o wrapper e fecha com exit 0.
  roda "$falso"
  if [ "$rc" -eq 0 ] && grep -qF "palavra399" "$d/SKILL.md" \
    && [ "$(ls -A "$d" | wc -l | tr -d ' ')" -eq 2 ]; then
    ok "F2 rodada seguinte sem limite atualiza o wrapper"
  else
    falha "F2 rodada sem limite" "exit $rc"
  fi
  rm -rf "$tmp"
fi
rm -rf "$falso"

# Casos D: descoberta nativa no Codex, sem modelo.
# descobre NOME: roda prompt-input em $pasta e procura "- NOME: SENT".
descobre() {
  (cd "$pasta" && codex debug prompt-input 2>/dev/null) | grep -qF -- "- $1: $SENT"
}
if command -v codex >/dev/null 2>&1; then
  if nova D1; then
    monta "$pasta"
    roda
    if [ "$rc" -eq 0 ] && descobre abrir-dia && descobre fechar-dia \
      && ! (cd "$pasta" && codex debug prompt-input 2>/dev/null) | grep -qF -- "- _shared:"; then
      ok "D1 codex descobre as skills pela ponte, sem _shared"
    else
      falha "D1 descoberta pela ponte" "exit $rc"
    fi
    rm -rf "$tmp"
  fi
  falso=$(mktemp -d 2>/dev/null)
  printf '#!/bin/sh\nexit 1\n' > "$falso/ln"
  chmod +x "$falso/ln"
  if nova D2; then
    monta "$pasta"
    roda "$falso"
    if [ "$rc" -eq 0 ] && descobre abrir-dia && descobre fechar-dia; then
      ok "D2 codex descobre as skills pelos wrappers"
    else
      falha "D2 descoberta pelos wrappers" "exit $rc"
    fi
    rm -rf "$tmp"
  fi
  rm -rf "$falso"
else
  echo "info  codex fora do PATH: descoberta nativa (D1, D2) nao medida nesta maquina"
fi

[ "$falhas" -eq 0 ] || exit 1
exit 0
