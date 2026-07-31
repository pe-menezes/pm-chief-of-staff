# Spec: bugs pequenos (catálogo do plantar + varredura de task)

## Objective
O catálogo do `plantar` lista a descrição real de cada semente e a varredura de backlog do `abrir-dia` enxerga subtask indentada.

## Context
`plantar` instrui listar o catálogo pela "primeira linha após o título de cada SKILL.md", mas as 4 sementes carregam o banner idêntico "> Semente do pm-chief-of-staff..." nessa posição: a listagem mostraria a mesma frase 4 vezes. `abrir-dia` varre o backlog com `grep "^- \[ \]"`, ancorado em início de linha: task aninhada com indentação (`  - [ ]`) fica invisível. Ambos registrados como known issues no index e como anti-pattern em `patterns/skill-authoring.md`.

## Definition of Done
1. [ ] `plantar` lista o catálogo pela primeira frase do campo `description` do frontmatter de cada semente.
2. [ ] `abrir-dia` varre `- [ ]` sem âncora de início de linha, com a nota de que subtask indentada conta.
3. [ ] Craftsmanship: âncora em estrutura (frontmatter), não em posição de texto (Don't de conventions.md); zero travessão novo; nenhum outro fluxo alterado.

## Scope
`skills/plantar/SKILL.md`, `seeds/abrir-dia/SKILL.md` (2 arquivos, budget ≤4 ok).

## Anti-scope
- Sem migração pra cópias já plantadas de `abrir-dia`: pelo modelo de semente, plantio existente mantém a versão antiga; o canal de correção é o diff que o `plantar` oferece em colisão.
- Sem mudança de fluxo, formato de saída ou gatilho em nenhuma das duas skills.

## Technical Decisions
- Descrição da semente sai do frontmatter porque é o único campo estruturado que toda skill tem por convenção (patterns/skill-authoring): âncora que não quebra quando o corpo muda.
- No grep, `--` antes do padrão evita o hífen inicial ser lido como flag.

## Applicable Patterns
- `skill-authoring` (o anti-pattern corrigido está registrado lá)
- `seed-model` (limite declarado do fix pra base plantada)
- `writing-canon`

## Risks
- Nenhum relevante: mudanças de 1 linha, sem contrato entre skills envolvido.
