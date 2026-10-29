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
#    abaixo, e so wrapper com a MARCA se reescreve, pra description seguir a
#    fonte na rodada seguinte.
# Nunca substitui, apaga, renomeia ou mescla: link, arquivo ou pasta que ja
# existe e nao e desta ponte fica como esta e sai como conflito.
# Pasta comecada por _ ou . nao vira skill (_shared/ e modulo).
# Saida: 0 tudo ligado; 1 sem .claude/skills ou erro de disco; 2 sobrou
# conflito, listado no stdout pra quem rodou decidir com a pessoa.
# Limite: no Windows sem permissao de link cai sempre no wrapper.

MARCA="<!-- gerado pela ponte-codex do pm-chief-of-staff; a fonte e a pasta .claude/skills -->"

if [ ! -d .claude/skills ]; then
  echo "sem .claude/skills nesta pasta: nada a ligar"
  exit 1
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
if [ -e .agents ] && [ ! -d .agents ]; then
  echo "conflito: .agents ja existe e nao e pasta, ficou como estava"
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

# wrapper FONTE NOME DESTINO: escreve o wrapper com o frontmatter da fonte.
wrapper() {
  fm=$(awk 'NR == 1 { if ($0 != "---") exit; next } /^---$/ { achou = 1; exit } { print } END { exit !achou }' "$1") || return 1
  {
    echo "---"
    printf '%s\n' "$fm"
    echo "---"
    echo "$MARCA"
    echo ""
    echo "Esta skill mora em \`.claude/skills/$2/SKILL.md\`, a fonte desta pasta. Leia esse arquivo inteiro e siga o que ele diz; caminho relativo citado nele parte da pasta dele. Edição vai sempre na fonte: a próxima rodada da ponte atualiza o frontmatter aqui."
  } > "$3/SKILL.md"
}

conflitos=0
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
    if mkdir "$destino" && wrapper "$fonte" "$nome" "$destino"; then
      echo "wrapper: $nome"
    else
      echo "erro: wrapper de $nome nao gravou (frontmatter ausente na fonte ou disco)"
      conflitos=$((conflitos + 1))
    fi
    continue
  fi
  if [ -f "$destino/SKILL.md" ] && grep -qxF "$MARCA" "$destino/SKILL.md"; then
    if wrapper "$fonte" "$nome" "$destino"; then
      echo "wrapper atualizado: $nome"
    else
      echo "erro: wrapper de $nome nao atualizou (frontmatter ausente na fonte ou disco)"
      conflitos=$((conflitos + 1))
    fi
    continue
  fi
  echo "conflito: $destino ja existe e nao e desta ponte, ficou como estava"
  conflitos=$((conflitos + 1))
done

if [ "$conflitos" -gt 0 ]; then
  echo "$conflitos conflito(s): nada foi substituido; decida com a pessoa"
  exit 2
fi
exit 0
