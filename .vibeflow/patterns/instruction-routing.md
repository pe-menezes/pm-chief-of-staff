---
tags: [routing, load-trigger, rules, shared-module, self-modulation]
modules: [skills/setup/, skills/criar-skill/, seeds/absorver/, ./]
applies_to: [skills, seeds, docs]
confidence: high
---
# Pattern: Instruction Routing

<!-- vibeflow:auto:start -->
## What
Onde uma instrução nova vai morar. Pedido de mudança da pessoa tem 1 destino entre 4, e o que separa os quatro não é o assunto: é o **gatilho de carga**, ou seja, quando aquele texto entra no contexto do agente. Escolher pelo assunto coloca disciplina de execução num arquivo que só carrega depois que o arquivo é tocado, e ela nunca dispara.

## Where
Declarada em `skills/setup/SKILL.md` (a régua que o CLAUDE.md gerado carrega), aplicada como triagem em `skills/criar-skill/SKILL.md` (Passo 1), como roteamento de material em `seeds/absorver/SKILL.md` (Passo 2), e espelhada em `PROMPT.md` (princípio 1) pra quem roda sem plugin.

## The Pattern
Os 4 destinos, na ordem do gatilho que os dispara, de sempre a sob demanda:

| Destino | Gatilho de carga | Onde |
|---|---|---|
| Comportamento de toda interação (tom, formato, vocabulário) | sempre, em toda sessão | linha no `CLAUDE.md` |
| Regra situacional de um tema ou tipo de arquivo | quando o trabalho toca aqueles arquivos | `.claude/rules/{tema}.md` com frontmatter `paths:` |
| Disciplina de um passo que 2 ou mais skills precisam | no meio da execução, antes de o arquivo existir | `.claude/skills/_shared/{nome}.md`, que cada consumidora manda ler |
| Formato ou passo de um artefato (a pauta, a nota, o report) | quando aquela skill roda | edição na skill dona do artefato |

File: skills/setup/SKILL.md
```markdown
* **Disciplina de um passo que 2 ou mais skills precisam** ("antes de escrever a nota, aplique isto"): módulo em `.claude/skills/_shared/{nome}.md`, que cada skill consumidora manda ler. Regra com `paths:` não serve: ela dispara quando um arquivo é tocado, e isto carrega antes de o arquivo existir.
```

O eixo escrito por extenso na triagem, que é o que faz alguém escolher certo entre os dois destinos que mais se confundem:

File: skills/criar-skill/SKILL.md
```markdown
E `.claude/rules/` não substitui o módulo: regra com `paths:` dispara quando um arquivo é tocado, e disciplina de "antes de escrever" tem que carregar no meio da execução, antes de o arquivo existir.
```

A mecânica de cada destino, separada da régua pra não amarrar a régua ao Claude Code:

File: skills/criar-skill/SKILL.md
```markdown
Módulo compartilhado é `.claude/skills/_shared/{nome}.md`: pasta sem `SKILL.md` é inerte pro scanner de skills, então o módulo não vira skill fantasma. A primeira linha declara quem o carrega, porque módulo sem consumidor declarado nunca dispara e ninguém percebe. **Não há carga automática:** criar um módulo inclui editar cada skill consumidora pra mandar ler o arquivo no passo certo, e skill que esquece de referenciar perde a disciplina em silêncio.
```

O destino 4 tem um quinto caso vizinho, que não é destino novo: pedido que bate numa skill já plantada é edição direta naquele arquivo, porque skill plantada é arquivo da pessoa (ver `seed-model.md`).

## Rules
- Escolher o destino pelo gatilho de carga, nunca pelo assunto. A pergunta é "quando este texto precisa estar em contexto?", não "sobre o que ele fala?".
- Só uma coisa entra no `CLAUDE.md`: o que vale em toda interação. Situacional no CLAUDE.md engorda o arquivo que toda sessão paga.
- Módulo em `_shared/` não tem carga automática: criar módulo inclui editar cada consumidora e declarar na primeira linha do módulo quem o carrega.
- Pasta de módulo nunca leva `SKILL.md`: sem ele, o scanner de skills ignora a pasta e o módulo não vira skill fantasma.
- Régua mudou (destino novo, gatilho redefinido): edite `skills/setup/SKILL.md` e `PROMPT.md` no mesmo change, mais as skills que triam por ela (`criar-skill`, `absorver`).
- Instrução que gera artefato declara alvo em número; o destino escolhido não dispensa a mira.

## Examples from this codebase
File: seeds/absorver/SKILL.md
```markdown
* **Processo operacional da empresa**, pelo gatilho dele: gatilho é tipo de arquivo ("toda nota de X segue este formato"), vira `.claude/rules/{tema}.md` com frontmatter `paths:`; gatilho é ritual que uma skill plantada cobre (preparar conversa, fechar semana), a regra entra na skill dona; o mesmo passo vale em 2 ou mais skills, vira módulo em `.claude/skills/_shared/{nome}.md` que cada uma manda ler (declare no topo dele quem carrega); sem gatilho claro, `referencia/` com o gatilho escrito no arquivo.
```

File: skills/setup/SKILL.md
```
.claude/rules/   regras situacionais por escopo de arquivo (nasce vazia; a régua de 4 destinos, adiante, povoa)
.claude/skills/_shared/   módulos que mais de uma skill lê (nasce com capacidades.md, do conectar)
```

File: skills/setup/SKILL.md
```markdown
1. **O sistema se auto-modula.** Sempre que a pessoa pedir pra mudar algo (como você processa uma reunião, que vocabulário usa, que formato tem a pauta), você edita o CLAUDE.md, a regra em `.claude/rules/`, o módulo compartilhado entre skills ou a skill certa e incorpora na hora (a régua de 4 destinos, adiante).
```
<!-- vibeflow:auto:end -->

## Anti-patterns (if found)
- `PROMPT.md` carrega a régua de 4 destinos no princípio 1, mas a lista de pastas propostas (item 1 do "Depois do discovery") cita só a pasta de regras situacionais. O quarto destino chega descrito e sem lugar declarado pra morar, e o espelho fica parcial (medido em 06/08/2026).
- Nenhum arquivo de `.claude/rules/` ou de `_shared/` vive neste repo: os dois nascem vazios ou por plantio na pasta da pessoa. Logo, a régua não tem exemplo real de regra com `paths:` além do bloco de formato no setup; ao mudar a régua, o teste é ler as 4 citações (setup, PROMPT, criar-skill, absorver), não rodar nada.
