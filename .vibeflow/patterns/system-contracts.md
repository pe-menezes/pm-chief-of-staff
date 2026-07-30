---
tags: [contracts, memory, labels, integration, folders]
modules: [seeds/, skills/setup/]
applies_to: [seeds, skills, docs]
confidence: inferred
---
# Pattern: System Contracts

<!-- vibeflow:auto:start -->
## What
Os rótulos, paths e formatos que ligam as skills entre si através dos arquivos do usuário. As skills não se chamam: uma escreve, a outra lê. Mudar um lado do contrato sem o outro quebra o loop silenciosamente.

## Where
Definidos em `skills/setup/SKILL.md` (estrutura de pastas e arquitetura de memória) e consumidos pelas 4 sementes.

## The Pattern
**Contrato 1, o loop diário.** `fechar-dia` escreve dois rótulos no bloco do dia; `abrir-dia` lê um deles na manhã seguinte.

File: seeds/fechar-dia/SKILL.md
```markdown
   **Balanço:** {N}/3 , {1 frase com o motivo do que não fechou}
   **→ amanhã:** {movimento #1, ancorado nas prioridades; carry-over só do que segue de pé}
```
```markdown
Manter os rótulos `**Balanço:**` e `**→ amanhã:**` estáveis: é o contrato que a abertura lê.
```

File: seeds/abrir-dia/SKILL.md
```markdown
1. **Ler o estado**: `CRITICAL_FACTS.md` (prioridades) · o diário da semana corrente · a linha `**→ amanhã:**` do fechamento de ontem (candidata mais forte a #1 do dia) · o log `memory/` mais recente.
```

**Contrato 2, o bloco das 3.** `abrir-dia` grava `## 3 do dia , DD/MM` no topo do diário; `fechar-dia` lê esse bloco pra avaliar.

**Contrato 3, a estrutura de pastas.** O setup propõe a base e as sementes a assumem por path literal: `preparar-conversa` lê `pessoas/` e `reunioes/`, escreve `reunioes/{nome}/YYYY-MM-DD pauta.md`; `processar-reuniao` escreve `reunioes/{pessoa-ou-ritual}/YYYY-MM-DD.md` e compara com a pauta; `abrir-dia` faz grep no `diario/` inteiro.

File: skills/setup/SKILL.md
```markdown
contexto/        quem ela é, prioridades, time
pessoas/         um hub por pessoa-chave (liderado, par, líder, stakeholder)
projetos/        um hub por projeto ou frente
reunioes/        pautas e notas processadas, por pessoa ou ritual
diario/          o diário semanal (tasks e 3 do dia)
memory/          o log diário (um arquivo por dia, append-only)
```

**Contrato 4, a memória.** `CRITICAL_FACTS.md` (~700 tokens, prioridades numeradas) e o log `memory/YYYY-MM-DD.md` no formato `## [HH:MM] Tópico` + 2 a 4 linhas. Toda semente que grava marco usa esse formato; toda sessão nova começa lendo os dois.

File: seeds/processar-reuniao/SKILL.md
```markdown
4. **Marco do dia** → 1 bloco no `memory/{hoje}.md` apontando pra nota (`## [HH:MM] {título} + 2 linhas`).
```

**Contrato 5, hub de pessoa.** Setup cria hubs com seção "Sinais recentes"; `processar-reuniao` escreve nela e `preparar-conversa` lê dela ("Todo item da seção 'Sinais recentes' do hub é candidato").

## Rules
- Rótulo de contrato (`**Balanço:**`, `**→ amanhã:**`, `## 3 do dia , DD/MM`, `## [HH:MM]`, "Sinais recentes") muda só com os dois lados editados no mesmo change.
- Path de pasta do sistema gerado muda só editando setup + todas as sementes que o citam (grep antes: `grep -rl "reunioes/" seeds/ skills/`).
- Semente nova que entra no loop declara de quem lê e pra quem escreve, e usa os rótulos existentes em vez de criar variante.
- Cópia plantada no mundo mantém o rótulo antigo: renomear contrato é breaking change pra base instalada, evitar.

## Examples from this codebase
File: seeds/fechar-dia/SKILL.md
```markdown
`abrir-dia` (lê `**→ amanhã:**`, propõe as 3) → dia (updates marcam progresso) → `fechar-dia` (compila, avalia, classifica, semeia) → `abrir-dia` de amanhã.
```

File: seeds/preparar-conversa/SKILL.md
```markdown
A pauta não propaga nada pro hub: quem propaga é o `processar-reuniao`, depois que a conversa acontecer (ele também compara o planejado com o acontecido).
```
<!-- vibeflow:auto:end -->

## Anti-patterns (if found)
- `PROMPT.md` e `skills/setup/SKILL.md` prometem "fechar dias e semanas", mas nenhuma semente fecha semana: promessa sem contrato do outro lado.
- Blocos 3 (ferramentas), 5 (rituais) e 6 (dores) do discovery não têm destino declarado em nenhum artefato gerado; contrato de escrita sem consumidor.
