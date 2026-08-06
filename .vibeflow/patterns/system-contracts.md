---
tags: [contracts, memory, labels, integration, folders, capabilities]
modules: [seeds/, modulos/, skills/setup/, skills/conectar/]
applies_to: [seeds, skills, docs]
confidence: inferred
---
# Pattern: System Contracts

<!-- vibeflow:auto:start -->
## What
Os rótulos, paths e formatos que ligam as skills entre si através dos arquivos do usuário. As skills não se chamam: uma escreve, a outra lê. Mudar um lado do contrato sem o outro quebra o loop silenciosamente. Sete contratos hoje; seis passam por nota, diário ou hub, e o sétimo (skill ↔ conector) passa por um módulo em `.claude/skills/_shared/`, que é a mesma mecânica com um arquivo de outra natureza: escrito por uma skill de infraestrutura, lido por várias skills de rotina.

## Where
Definidos em `skills/setup/SKILL.md` (estrutura de pastas e arquitetura de memória) e `skills/conectar/SKILL.md` (o contrato de capacidade), consumidos pelas 6 sementes.

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

**Contrato 3, a estrutura de pastas.** O setup propõe a base e as sementes a assumem por path literal: `preparar-conversa` lê `pessoas/` e `reunioes/`, escreve `reunioes/{nome}/YYYY-MM-DD pauta.md`; `processar-reuniao` escreve `reunioes/{pessoa-ou-ritual}/YYYY-MM-DD.md` e compara com a pauta; `abrir-dia` faz grep no `diario/` inteiro; `absorver` roteia pra `projetos/`, `referencia/`, `.claude/rules/` ou `pessoas/` e indexa em `navegacao.md`; `fechar-semana` lê `contexto/dores.md` e escreve `contexto/trajetoria.md`.

File: skills/setup/SKILL.md
```markdown
contexto/        quem ela é, prioridades, time
pessoas/         um hub por pessoa-chave (liderado, par, líder, stakeholder)
projetos/        um hub por projeto ou frente
reunioes/        pautas e notas processadas, por pessoa ou ritual
referencia/      conhecimento durável que a pessoa joga pra dentro (docs do produto dela, artigos, processos da empresa)
diario/          o diário semanal (tasks e 3 do dia)
memory/          o log diário (um arquivo por dia, append-only)
.claude/rules/   regras situacionais por escopo de arquivo (nasce vazia; a régua de 4 destinos, adiante, povoa)
.claude/skills/_shared/   módulos que mais de uma skill lê (nasce com capacidades.md, do conectar)
```

**Contrato 4, a memória.** `CRITICAL_FACTS.md` (~700 tokens, prioridades numeradas) e o log `memory/YYYY-MM-DD.md` no formato `## [HH:MM] Tópico` + 2 a 4 linhas. Toda semente que grava marco usa esse formato; toda sessão nova começa lendo os dois. Com o plugin ativo, o hook `SessionStart` injeta `CRITICAL_FACTS.md`, `navegacao.md` e o log mais recente, e por isso o nome desses três arquivos é contrato de duas pontas: uma em markdown (a rotina escrita no CLAUDE.md, pra quem roda sem plugin) e uma em shell (`hooks/boot-memoria.sh`).

File: seeds/processar-reuniao/SKILL.md
```markdown
4. **Marco do dia** → 1 bloco no `memory/{hoje}.md` apontando pra nota (`## [HH:MM] {título} + 2 linhas`).
```

**Contrato 5, hub de pessoa.** Setup cria hubs com seção "Sinais recentes"; `processar-reuniao` escreve nela, `preparar-conversa` lê dela ("Todo item da seção 'Sinais recentes' do hub é candidato") e `fechar-semana` propõe poda do que já consolidou no corpo.

**Contrato 6, o loop semanal.** Extensão do contrato 1: `fechar-semana` consome a série de `**Balanço:** N/3` e as linhas `**Reflexão:**` que os fechamentos diários gravaram, appenda a análise sob `## Fechamento da semana , DD/MM a DD/MM` no diário que fecha, e promove o último `**→ amanhã:**` da semana pra primeira task de segunda no diário novo.

File: seeds/fechar-semana/SKILL.md
```markdown
Promover o último `**→ amanhã:**` da semana pra primeira task de segunda: é o elo da virada, sem ele a semente de sexta fica órfã no diário velho.
```

**Contrato 7, skill ↔ conector.** `conectar` escreve `.claude/skills/_shared/capacidades.md`; as sementes que buscam dado de fora leem a linha da capacidade que precisam. O contrato tem três partes, e cada uma quebra de um jeito diferente:

1. **O nome da capacidade é o rótulo.** A skill cita capacidade, nunca nome de ferramenta: `abrir-dia` pede `agenda do dia`, `processar-reuniao` pede `transcrição de reunião`, `preparar-conversa` pede `mensagens` e `tickets`. Trocar de provider é editar uma linha do módulo, sem abrir skill nenhuma. Renomear a capacidade sem editar as consumidoras deixa a skill lendo linha que não existe.
2. **`provider` e `como chamar` andam juntos.** É `como chamar` que a skill executa; provider sozinho faz a consumidora tentar sem instrução, falhar, e cair na coluna "sem conector" com um tropeço no meio do fluxo. Provider que saiu limpa as duas células, não uma.
3. **A linha "Carregado por" do topo do módulo é a única pista de quem o lê.** Não há carga automática: o módulo entra em contexto só quando uma skill manda ler. Consumidora que não referencia o módulo continua perguntando, sem dar erro.

File: skills/conectar/SKILL.md
```markdown
**Skill cita capacidade, nunca nome de ferramenta.** O `abrir-dia` pede "a agenda do dia"; qual conector responde isso é problema do módulo. Trocar de provider (mudou de empresa, o calendário virou outro) é editar uma linha em `capacidades.md`, sem abrir skill nenhuma.
```

File: seeds/abrir-dia/SKILL.md
```markdown
2. **Agenda**: se existir `.claude/skills/_shared/capacidades.md`, ler a linha `agenda do dia` e puxar os eventos de hoje pelo que está em `como chamar`, com `provider` identificando a fonte. Sem o módulo, com essa linha vazia ou pela metade (só uma das duas colunas), ou se a busca falhar (conector expirado, máquina sem ele), perguntar em 1 linha [...]
```

A degradação do contrato 7 é declarada em toda consumidora, e é o que o separa dos outros seis: linha ausente ou pela metade não quebra a skill, faz ela voltar ao comportamento de sempre (perguntar). O custo não é erro, é automação que a pessoa espera e não chega.

## Rules
- Rótulo de contrato (`**Balanço:**`, `**→ amanhã:**`, `## 3 do dia , DD/MM`, `## [HH:MM]`, `## Fechamento da semana`, "Sinais recentes", nome de capacidade) muda só com os dois lados editados no mesmo change.
- Path de pasta do sistema gerado muda só editando setup + todas as sementes que o citam (grep antes: `grep -rl "reunioes/" seeds/ skills/`).
- Semente nova que entra no loop declara de quem lê e pra quem escreve, e usa os rótulos existentes em vez de criar variante.
- Semente nova que busca dado de fora lê `capacidades.md` pela capacidade e se acrescenta na linha "Carregado por" do template em `modulos/capacidades.md`.
- Toda leitura de capacidade declara o fallback no mesmo passo: sem módulo, com a linha pela metade ou com busca falhando, a skill pergunta e segue.
- Cópia plantada no mundo mantém o rótulo antigo: renomear contrato é breaking change pra base instalada, evitar.
- Contrato de duas pontas (o nome dos 3 arquivos do boot) muda em markdown e em shell no mesmo change: `hooks/boot-memoria.sh` cita `CRITICAL_FACTS.md`, `navegacao.md` e `memory/*.md` por nome literal.

## Examples from this codebase
File: seeds/fechar-dia/SKILL.md
```markdown
`abrir-dia` (lê `**→ amanhã:**`, propõe as 3) → dia (updates marcam progresso) → `fechar-dia` (compila, avalia, classifica, semeia) → `abrir-dia` de amanhã.
```

File: seeds/preparar-conversa/SKILL.md
```markdown
A pauta não propaga nada pro hub: quem propaga é o `processar-reuniao`, depois que a conversa acontecer (ele também compara o planejado com o acontecido).
```

File: modulos/capacidades.md
```markdown
**Carregado por:** `abrir-dia`, `processar-reuniao`, `preparar-conversa`. Skill nova que busca dado de fora se acrescenta nesta linha, porque módulo sem consumidor declarado nunca dispara e ninguém percebe.
```
<!-- vibeflow:auto:end -->

## Anti-patterns (if found)
- O contrato 7 é o único que pode ser escrito sem efeito nenhum: `conectar` grava o módulo e a semente plantada antes desta camada não o referencia, então a pessoa ganha o mapa e nada muda no dia seguinte. Por isso `conectar` tem o passo 4 (abrir cada skill da linha "Carregado por" e conferir a referência, com edição oferecida uma por uma) e `fechar-semana` reconfere isso no passo 6. `plantar` ainda não participa dessa conferência.
- Os dois anti-padrões registrados em 30/07 foram resolvidos: a promessa "fechar dias e semanas" ganhou `seeds/fechar-semana/`, e os blocos 3, 5 e 6 do discovery ganharam destino declarado em `contexto/ferramentas-e-fontes.md`, `contexto/rituais.md` e `contexto/dores.md`.
