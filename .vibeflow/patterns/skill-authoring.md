---
tags: [skills, frontmatter, triggers, claude-code, authoring]
modules: [skills/, seeds/]
applies_to: [skills, seeds]
confidence: inferred
---
# Pattern: Skill Authoring

<!-- vibeflow:auto:start -->
## What
Anatomia de um SKILL.md neste repo: frontmatter com gatilhos literais, corpo com fluxo numerado e delimitação explícita do que a skill NÃO cobre.

## Where
Todas as 6 skills: `skills/setup/`, `skills/plantar/` (skills do plugin) e as 4 em `seeds/` (sementes plantáveis).

## The Pattern
Cada skill é um diretório kebab-case com um único `SKILL.md`. O frontmatter tem exatamente `name` (igual ao nome do diretório) e `description`. A description carrega 3 partes na ordem: o que faz em 1-2 frases, "Use quando" com frases literais que a pessoa diria, e "NÃO use" apontando a skill vizinha certa.

File: seeds/abrir-dia/SKILL.md
```yaml
---
name: abrir-dia
description: Abre o dia de trabalho. Monta a agenda, varre as tasks abertas, propõe as 3 do dia ancoradas nas prioridades e grava no diário. Use quando a pessoa disser "bom dia", "abre meu dia", "monta meu dia", "o que faço hoje", "/abrir-dia". Sempre interativo (propõe, a pessoa valida). NÃO use pra fechar o dia (fechar-dia) nem pra review de fim de tarde.
---
```

O corpo segue a sequência: parágrafo de abertura com a tese da skill, seções de princípios ou preparação quando existem, `## Fluxo` (ou passos `## Passo N`) numerado com verbos no infinitivo, e fechamento `## Quando NÃO usar` com o redirecionamento explícito.

File: seeds/fechar-dia/SKILL.md
```markdown
## Quando NÃO usar

De manhã → `abrir-dia`. Meio do dia ("fiz X") → update direto no diário.
```

Skills que interagem com o estado da pessoa propõem antes de gravar. O padrão aparece como princípio declarado:

File: seeds/abrir-dia/SKILL.md
```markdown
3. A skill propõe, a pessoa valida antes de cravar. Nunca decidir pela pessoa.
```

## Rules
- 1 diretório por skill, 1 único SKILL.md dentro, `name` do frontmatter idêntico ao nome do diretório.
- description sempre com as 3 partes: função, "Use quando" com frases literais entre aspas, "NÃO use" com o nome da skill vizinha.
- Passos de fluxo numerados; cada passo abre com o verbo da ação em negrito ou infinitivo direto.
- Ação com side effect (gravar, propagar, sobrescrever) passa por validação da pessoa antes de executar.
- Toda skill fecha dizendo o que não cobre e pra onde ir.

## Examples from this codebase
File: skills/plantar/SKILL.md
```yaml
description: Planta uma skill-semente do plugin na pasta da pessoa, transformando-a em arquivo dela (editável e auto-modulável). Use quando a pessoa rodar /pm-chief-of-staff:plantar (com ou sem o nome de uma semente), perguntar "que sementes tem disponíveis?", ou depois de uma atualização do plugin quando quiser adotar uma skill nova. Nunca sobrescreve skill existente da pessoa.
```

File: seeds/processar-reuniao/SKILL.md
```markdown
## Passo 3: propagar (é aqui que o sistema fica vivo)

Propor a propagação e executar com o ok da pessoa:
```
<!-- vibeflow:auto:end -->

## Anti-patterns (if found)
- `skills/plantar/SKILL.md` instrui listar o catálogo pela "primeira linha após o título de cada SKILL.md", mas nas 4 sementes essa linha é o banner idêntico "> Semente do pm-chief-of-staff...". O anchor correto é o `description` do frontmatter. Não replicar contagem ancorada em posição de texto.
