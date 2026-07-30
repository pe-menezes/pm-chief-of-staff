---
tags: [seeds, lifecycle, ownership, updates, distribution]
modules: [seeds/, skills/setup/, skills/plantar/]
applies_to: [seeds, skills]
confidence: inferred
---
# Pattern: Seed Model

<!-- vibeflow:auto:start -->
## What
O ciclo de vida da semente: skill starter que vive no plugin só até ser copiada pra pasta da pessoa, onde vira arquivo dela, editável e fora do alcance de updates. É o mecanismo que resolve a tensão entre atualização do plugin e customização do usuário.

## Where
`seeds/` (o catálogo), `skills/setup/SKILL.md` (planta as 4 no fim do setup), `skills/plantar/SKILL.md` (planta avulso), README (explica o modelo ao usuário).

## The Pattern
Sementes moram em `seeds/`, deliberadamente FORA de `skills/`: o Claude Code só registra como skill o que está em `skills/`, então a semente não vira comando do plugin nem colide com a cópia plantada. O plantio é uma cópia pra `.claude/skills/` da pasta da pessoa, e a partir daí o plugin nunca mais toca no arquivo.

File: skills/plantar/SKILL.md
```markdown
Semente é uma skill starter que vive no plugin só até ser plantada: copiada pra `.claude/skills/` da pasta da pessoa, ela vira arquivo DELA, editável, auto-modulável, fora do alcance de qualquer atualização do plugin.
```

Toda semente carrega, logo após o título, o banner de posse e a linha de escrita fallback (a semente plantada precisa funcionar sozinha, sem o plugin e antes do CLAUDE.md existir):

File: seeds/preparar-conversa/SKILL.md
```markdown
> Semente do pm-chief-of-staff. Este arquivo é SEU: peça pro agente mudar o formato da pauta ("quero que sempre tenha uma seção de X") e ele edita a skill na hora.

Escrita: siga o cânone do CLAUDE.md desta pasta. Na ausência dele: sem travessão (use vírgula, parênteses ou dois pontos), frases curtas e densas, 1 linha por item.
```

Colisão nunca resolve por sobrescrita:

File: skills/plantar/SKILL.md
```markdown
3. **Checar colisão.** Se já existe `.claude/skills/{nome}/` na pasta dela: **nunca sobrescrever**. Ofereça: manter a dela (default), plantar com outro nome pra comparar, ou mostrar o diff entre as duas.
```

O caminho do catálogo resolve por `${CLAUDE_PLUGIN_ROOT}` com fallback declarado:

File: skills/setup/SKILL.md
```markdown
copie as 4 skills-semente da pasta `seeds/` do plugin (em `${CLAUDE_PLUGIN_ROOT}/seeds/`; se a variável não resolver, localize a pasta do plugin `pm-chief-of-staff` no cache de plugins)
```

## Rules
- Semente nova entra em `seeds/{nome}/SKILL.md`, nunca em `skills/`.
- Toda semente carrega o banner de posse e a linha de escrita fallback logo após o título.
- Semente referencia só paths do sistema gerado (`pessoas/`, `reunioes/`, `diario/`, `memory/`, `contexto/`, `CRITICAL_FACTS.md`); nunca referencia o plugin, seus comandos ou `${CLAUDE_PLUGIN_ROOT}`.
- Plantio é cópia; colisão oferece manter, renomear ou diff. Sobrescrever não é opção.
- Update de semente no catálogo só alcança plantios futuros; cópia plantada no mundo mantém a versão antiga (consequência aceita do modelo, considerar ao corrigir bug de semente).

## Examples from this codebase
File: README.md
```markdown
A partir do momento em que são plantadas, **essas skills são arquivos seus**. [...] Minhas atualizações futuras **nunca tocam no que é seu**: elas só melhoram o setup e adicionam sementes novas no catálogo (`/pm-chief-of-staff:plantar` lista o que há).
```

File: skills/setup/SKILL.md
```markdown
Ao plantar, diga com todas as letras: **"essas 4 skills agora são arquivos seus. Me pede pra mudar qualquer uma ('quero que a pauta sempre tenha X') que eu edito a skill na hora. Atualização do plugin nunca toca nelas."**
```
<!-- vibeflow:auto:end -->

## Anti-patterns (if found)
Nenhum encontrado no código. Risco latente documentado: bug corrigido numa semente não alcança cópias já plantadas; o canal de correção pra usuário existente é o diff oferecido pelo `plantar` em caso de colisão.
