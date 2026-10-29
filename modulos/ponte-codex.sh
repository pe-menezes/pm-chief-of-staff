#!/bin/sh
# Ponte Codex do pm-chief-of-staff: faz o Codex achar as skills da pessoa
# sem segunda copia. A fonte unica e .claude/skills/ da pasta dela; o Codex
# varre .agents/skills/. Roda dentro da pasta da pessoa:
#   sh "<raiz do plugin>/modulos/ponte-codex.sh"
# Carregado por: setup (plantio), plantar (passo 4), criar-skill (passo 4).
# Rodar de novo e seguro: o que ja esta ligado fica, o que falta nasce.
#
# Ordem, da mais simples pra mais trabalhosa:
# 1) sem .agents/skills: link relativo da colecao, .agents/skills ->
#    ../.claude/skills. Skill nova aparece sozinha, sem rodar a ponte de novo.
# 2) .agents/skills pasta real (a pessoa ja tinha, ou o link falhou): uma
#    entrada por skill, link relativo ../../.claude/skills/NOME.
# 3) link indisponivel no sistema: wrapper .agents/skills/NOME/SKILL.md com
#    o frontmatter da fonte e a ordem de ler a fonte. O wrapper leva a MARCA
#    abaixo e fecha com a PROVA de integridade; so wrapper com a MARCA e a
#    PROVA batendo se reescreve, pra description seguir a fonte na rodada
#    seguinte.
# Nunca substitui, apaga, renomeia ou mescla: link, arquivo ou pasta que ja
# existe e nao e desta ponte fica como esta e sai como conflito.
# Pasta comecada por _ ou . nao vira skill (_shared/ e modulo).
# Saida: 0 tudo ligado; 1 sem .claude/skills ou erro de disco (inclui wrapper
# que nao gravou, com o anterior intacto); 2 sobrou
# conflito, listado no stdout pra quem rodou decidir com a pessoa.
# Limite: no Windows sem permissao de link cai sempre no wrapper.

MARCA="<!-- gerado pela ponte-codex do pm-chief-of-staff; a fonte e a pasta .claude/skills -->"
PROVA="<!-- integridade ponte-codex, cksum do que vem acima: "

if [ ! -d .claude/skills ]; then
  echo "sem .claude/skills nesta pasta: nada a ligar"
  exit 1
fi

# .agents em link, ate quebrado, levaria a escrita pra fora da pasta: confere
# antes de olhar qualquer coisa dentro dele.
if [ -L .agents ]; then
  echo "conflito: .agents ja e link pra $(readlink .agents), ficou como estava"
  exit 2
fi
if [ -e .agents ] && [ ! -d .agents ]; then
  echo "conflito: .agents ja existe e nao e pasta, ficou como estava"
  exit 2
fi

if [ -L .agents/skills ]; then
  alvo=$(readlink .agents/skills)
  if [ "$alvo" = "../.claude/skills" ] && [ -d .agents/skills ]; then
    echo "ponte ok: .agents/skills aponta pra .claude/skills"
    exit 0
  fi
  echo "conflito: .agents/skills ja e link pra $alvo, ficou como estava"
  exit 2
fi
if [ -e .agents/skills ] && [ ! -d .agents/skills ]; then
  echo "conflito: .agents/skills ja existe e nao e pasta, ficou como estava"
  exit 2
fi

if [ ! -e .agents/skills ]; then
  mkdir -p .agents || exit 1
  if ln -s ../.claude/skills .agents/skills 2>/dev/null; then
    echo "ponte criada: .agents/skills -> ../.claude/skills"
    exit 0
  fi
  mkdir .agents/skills || exit 1
  echo "link de colecao indisponivel: ligando skill por skill"
fi

# Limite de tamanho de arquivo vira erro de escrita, nao morte do processo.
trap '' XFSZ

# wrapper FONTE NOME DESTINO: escreve o wrapper com o frontmatter da fonte.
# Grava num temporario desta rodada na mesma pasta e so troca por rename
# depois de conferir o conteudo; falha deixa o SKILL.md anterior intacto e
# remove so o temporario que esta rodada criou.
# A ultima linha e a PROVA: cksum de tudo que vem antes dela. Wrapper so se
# atualiza com a PROVA batendo; qualquer edicao, ate mantendo a MARCA, ou o
# formato antigo sem PROVA, sai como conflito.
wrapper() {
  fm=$(awk 'NR == 1 { if ($0 != "---") exit; next } /^---$/ { achou = 1; exit } { print } END { exit !achou }' "$1") || return 1
  corpo=$(printf -- '---\n%s\n---\n%s\n\n%s' "$fm" "$MARCA" "Esta skill mora em \`.claude/skills/$2/SKILL.md\`, a fonte desta pasta. Leia esse arquivo inteiro e siga o que ele diz; caminho relativo citado nele parte da pasta dele. Edição vai sempre na fonte: a próxima rodada da ponte atualiza o frontmatter aqui.")
  conteudo="$corpo
$PROVA$(printf '%s\n' "$corpo" | cksum) -->"
  tmp="$3/.SKILL.md.ponte.$$"
  (set -C; : > "$tmp") 2>/dev/null || return 1
  if printf '%s\n' "$conteudo" > "$tmp" 2>/dev/null && [ "$(cat "$tmp")" = "$conteudo" ] \
    && mv -f "$tmp" "$3/SKILL.md" 2>/dev/null; then
    return 0
  fi
  rm -f "$tmp"
  return 1
}

# integro ARQUIVO: a ultima linha e a PROVA e bate com o resto do arquivo.
integro() {
  ultima=$(tail -n 1 "$1") || return 1
  case "$ultima" in "$PROVA"*" -->") ;; *) return 1 ;; esac
  soma=${ultima#"$PROVA"}
  soma=${soma%" -->"}
  [ -n "$soma" ] && [ "$(sed '$d' "$1" | cksum)" = "$soma" ]
}

conflitos=0
erros=0
for fonte in .claude/skills/*/SKILL.md; do
  [ -f "$fonte" ] || continue
  nome=${fonte#.claude/skills/}
  nome=${nome%/SKILL.md}
  case "$nome" in _*|.*) continue ;; esac
  destino=".agents/skills/$nome"
  if [ -L "$destino" ]; then
    alvo=$(readlink "$destino")
    if [ "$alvo" = "../../.claude/skills/$nome" ]; then
      echo "ok: $nome"
    else
      echo "conflito: $destino ja e link pra $alvo, ficou como estava"
      conflitos=$((conflitos + 1))
    fi
    continue
  fi
  if [ ! -e "$destino" ]; then
    if ln -s "../../.claude/skills/$nome" "$destino" 2>/dev/null; then
      echo "ligada: $nome"
      continue
    fi
    if mkdir "$destino"; then
      if wrapper "$fonte" "$nome" "$destino"; then
        echo "wrapper: $nome"
        continue
      fi
      # A pasta e desta rodada: sai so se continua vazia, pra proxima
      # rodada criar de novo; o que apareceu nela fica.
      rmdir "$destino" 2>/dev/null
    fi
    echo "erro: wrapper de $nome nao gravou (frontmatter ausente na fonte ou disco)"
    erros=$((erros + 1))
    continue
  fi
  # So arquivo regular com a marca e a prova batendo e wrapper desta ponte:
  # SKILL.md em link, ate quebrado ou com alvo marcado, ou editado, e da pessoa.
  if [ -f "$destino/SKILL.md" ] && [ ! -L "$destino/SKILL.md" ] && grep -qxF "$MARCA" "$destino/SKILL.md" \
    && integro "$destino/SKILL.md"; then
    if wrapper "$fonte" "$nome" "$destino"; then
      echo "wrapper atualizado: $nome"
    else
      echo "erro: wrapper de $nome nao atualizou, o anterior ficou (frontmatter ausente na fonte ou disco)"
      erros=$((erros + 1))
    fi
    continue
  fi
  echo "conflito: $destino ja existe e nao e desta ponte, ficou como estava"
  conflitos=$((conflitos + 1))
done

if [ "$erros" -gt 0 ]; then
  echo "$erros erro(s) de escrita; $conflitos conflito(s); nada foi substituido pela metade"
  exit 1
fi
if [ "$conflitos" -gt 0 ]; then
  echo "$conflitos conflito(s): nada foi substituido; decida com a pessoa"
  exit 2
fi
exit 0
