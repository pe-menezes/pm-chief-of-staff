#!/bin/sh
# Sondas da auditoria final codex-compat-funcional (modulos/ponte-codex.sh).
# Roda a mao: sh testes/auditoria/codex-compat-final.sh
# Cada caso monta uma pasta de mktemp -d com espaco no nome, roda a ponte
# la dentro e apaga a pasta. Confere estado do disco e codigo de saida,
# nunca o texto da ponte.
# Saida: uma linha ok ou FALHA por caso; exit 0 so com tudo passando.

DIR=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
PONTE="$DIR/modulos/ponte-codex.sh"
falhas=0

ok() { echo "ok    $1"; }
falha() { echo "FALHA $1: $2"; falhas=$((falhas + 1)); }

# ln falso no PATH so durante a ponte: sistema sem link simbolico.
falso=$(mktemp -d 2>/dev/null)
printf '#!/bin/sh\nexit 1\n' > "$falso/ln"
chmod +x "$falso/ln"

# A1 SKILL.md em .agents/skills e link pra um wrapper VALIDO e integro da
# ponte, guardado pela pessoa fora da pasta, sem edicao nenhuma. A marca e a
# prova batem pelo link, entao so o guarda de link impede a ponte de trocar o
# link por arquivo comum. Com a fonte mudada, uma atualizacao indevida
# apareceria: o link e o alvo ficam como estao, exit 2.
tmp=$(mktemp -d 2>/dev/null)
if [ -z "$tmp" ] || [ ! -d "$tmp" ]; then
  falha A1 "mktemp -d nao devolveu pasta"
else
  pasta="$tmp/minha pasta de cos"
  mkdir -p "$pasta/.claude/skills/abrir-dia"
  printf -- '---\nname: abrir-dia\ndescription: sonda abrir.\n---\n\n# Abrir\n' > "$pasta/.claude/skills/abrir-dia/SKILL.md"
  (cd "$pasta" && PATH="$falso:$PATH" sh "$PONTE" >/dev/null 2>&1)
  w="$pasta/.agents/skills/abrir-dia/SKILL.md"
  alvo="$tmp/wrapper da pessoa.md"
  cp "$w" "$alvo"
  antes=$(cksum < "$alvo")
  rm "$w"
  ln -s "../../../../wrapper da pessoa.md" "$w"
  printf -- '---\nname: abrir-dia\ndescription: sonda abrir, mudada.\n---\n\n# Abrir\n' > "$pasta/.claude/skills/abrir-dia/SKILL.md"
  (cd "$pasta" && PATH="$falso:$PATH" sh "$PONTE" >/dev/null 2>&1)
  rc=$?
  if [ "$rc" -eq 2 ] && [ -L "$w" ] && [ "$(readlink "$w")" = "../../../../wrapper da pessoa.md" ] \
    && [ "$(cksum < "$alvo")" = "$antes" ]; then
    ok "A1 SKILL.md ligado a wrapper valido e integro fica como link"
  else
    falha A1 "exit $rc, link: $(readlink "$w" 2>/dev/null || echo trocado por arquivo)"
  fi
  rm -rf "$tmp"
fi

rm -rf "$falso"
[ "$falhas" -eq 0 ] || exit 1
exit 0
