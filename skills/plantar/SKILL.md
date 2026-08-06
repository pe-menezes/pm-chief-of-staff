---
name: plantar
description: Planta uma skill-semente do plugin na pasta da pessoa, transformando-a em arquivo dela (editável e auto-modulável). Use quando a pessoa rodar /pm-chief-of-staff:plantar (com ou sem o nome de uma semente), perguntar "que sementes tem disponíveis?", ou depois de uma atualização do plugin quando quiser adotar uma skill nova. Nunca sobrescreve skill existente da pessoa.
---

# Plantar uma semente

Semente é uma skill starter que vive no plugin só até ser plantada: copiada pra `.claude/skills/` da pasta da pessoa, ela vira arquivo DELA, editável, auto-modulável, fora do alcance de qualquer atualização do plugin.

## Fluxo

1. **Listar o catálogo.** As sementes vivem em `${CLAUDE_PLUGIN_ROOT}/seeds/` (se a variável não resolver, localize a pasta do plugin `pm-chief-of-staff` no cache de plugins). Liste as disponíveis com 1 linha de descrição cada, tirada da primeira frase do campo `description` do frontmatter (a linha após o título é o banner de semente, idêntico em todas, e não descreve nada). Compare com `.claude/skills/` da pasta atual e marque o que já está plantado.
2. **A pessoa escolhe** (ou já veio com o nome no comando).
3. **Checar colisão.** Se já existe `.claude/skills/{nome}/` na pasta dela: **nunca sobrescrever**. Ofereça: manter a dela (default), plantar com outro nome pra comparar, ou mostrar o diff entre as duas.
4. **Copiar** a pasta da semente pra `.claude/skills/{nome}/` da pasta da pessoa. Se ela referencia `.claude/skills/_shared/capacidades.md` e esse arquivo não existe, diga em 1 linha que a semente vai seguir perguntando o que daria pra puxar sozinha, e ofereça rodar `/pm-chief-of-staff:conectar`. Existindo, nada a dizer.
5. **Avisar:** "plantada. Essa skill agora é um arquivo seu: me pede pra mudar qualquer coisa nela que eu edito na hora. Atualização do plugin nunca toca nela."

## Se a pasta não tem sistema montado

Se não existe CLAUDE.md na pasta (o setup nunca rodou), diga que a semente funciona melhor plantada num sistema montado e ofereça rodar `/pm-chief-of-staff:setup` primeiro. Se a pessoa quiser a semente avulsa mesmo assim, plante.
