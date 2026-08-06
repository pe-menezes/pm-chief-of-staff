---
tags: [skills, frontmatter, triggers, claude-code, authoring]
modules: [skills/, seeds/]
applies_to: [skills, seeds]
confidence: inferred
---
# Pattern: Skill Authoring

<!-- vibeflow:auto:start -->
## What
Anatomia de um SKILL.md neste repo: frontmatter com gatilhos literais, corpo com fluxo numerado e delimitação explícita do que a skill NÃO cobre. Desde v0.2.0 as regras de autoria estão escritas dentro do produto, em `skills/criar-skill/SKILL.md`: o repo não só segue o padrão, ele ensina o padrão pra pessoa criar as skills dela.

## Where
Todas as 10 skills: `skills/setup/`, `skills/plantar/`, `skills/conectar/`, `skills/criar-skill/` (skills do plugin) e as 6 em `seeds/` (sementes plantáveis). As regras estão declaradas no Passo 2 do `criar-skill`.

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

As regras de autoria saem de restrições declaradas, não de gosto, e cada uma cita a restrição que a justifica:

File: skills/criar-skill/SKILL.md
```markdown
Skill é instrução pra agente, e as restrições que valem pra qualquer instrução valem aqui: contexto é finito, instrução longa degrada qualquer modelo, gatilho vago não dispara em agente nenhum.
```
```markdown
* **Corpo é guia leve que confia no julgamento do modelo.** Objetivo, etapas e as decisões de formato da pessoa, sem prescrever o que o agente resolve sozinho: instrução longa degrada a execução inteira. Regra rígida só em passo frágil ou destrutivo (sobrescrever, apagar, mandar algo pra fora), e sempre com o porquê: regra sem porquê quebra no primeiro caso que ela não previu, e o porquê é o que orienta o caso novo.
* **Progressive disclosure.** Corpo curto; template longo, tabela de referência ou detalhe que só serve em parte das execuções vai pra arquivo separado na mesma pasta da skill, que o corpo aponta. O detalhe só deve ocupar contexto quando a execução precisa dele.
* **Artefato tem alvo em número.** Skill que gera arquivo declara a mira ("nota de até 25 linhas", "1 linha por item"); sem número o output cresce a cada execução.
* **Sem exemplos de uso engessados.** Diálogo pronto e output modelo constrangem a exploração: o agente passa a imitar o exemplo em vez de resolver o caso real.
```

Antes de existir arquivo, o gatilho é testado com a pessoa:

File: skills/criar-skill/SKILL.md
```markdown
Antes de criar o arquivo, proponha 2 a 3 frases que devem disparar a skill e 1 a 2 vizinhas que não devem (dizendo o que atende cada vizinha: outra skill, o CLAUDE.md, uma regra). A pessoa valida: frase que ela nunca falaria sai da description; colisão com skill existente volta pro passo 1.
```

Antes de escrever qualquer skill, a pergunta é se aquilo é skill: a triagem de destino vive em `instruction-routing.md` e é o Passo 1 do `criar-skill`.

## Rules
- 1 diretório por skill, 1 único SKILL.md dentro, `name` do frontmatter idêntico ao nome do diretório.
- description sempre com as 3 partes: função, "Use quando" com frases literais entre aspas, "NÃO use" com o nome da skill vizinha. Ela é o que decide o disparo; o corpo só é lido depois.
- Passos de fluxo numerados; cada passo abre com o verbo da ação em negrito ou infinitivo direto.
- Ação com side effect (gravar, propagar, sobrescrever) passa por validação da pessoa antes de executar.
- Toda skill fecha dizendo o que não cobre e pra onde ir.
- Skill que gera artefato declara alvo em número (linhas, itens por seção).
- Detalhe que só serve em parte das execuções sai do corpo e vira arquivo na pasta da skill, apontado pelo corpo.
- Regra rígida só em passo frágil ou destrutivo, e sempre com o porquê escrito na frente.
- Sem diálogo de exemplo e sem output modelo no corpo; bloco de formato (o esqueleto do artefato) é outra coisa e continua valendo.
- Skill de plugin não se invoca por comando de dentro de outra execução: o caminho é ler o SKILL.md e seguir (`setup` faz isso com `conectar` no Bloco 3).

## Examples from this codebase
File: skills/conectar/SKILL.md
```yaml
description: Mapeia o que esta sessão consegue buscar sozinha (agenda, e-mail, mensagens, documentos, transcrição de reunião, tickets, warehouse de dados, analytics de produto) e escreve isso no módulo `.claude/skills/_shared/capacidades.md` da pasta da pessoa, que as skills de rotina leem antes de perguntar. Use quando a pessoa rodar /pm-chief-of-staff:conectar, no bloco de ferramentas do setup, quando ela ganhar ou perder um conector, disser "por que você não puxa minha agenda?", "liga isso no meu calendário", ou depois de trocar de empresa. Não use pra instalar ou autenticar conector (é configuração do agente, fora do alcance desta skill), nem pra criar skill nova (criar-skill).
```

File: seeds/processar-reuniao/SKILL.md
```markdown
## Passo 3: propagar (é aqui que o sistema fica vivo)

Propor a propagação e executar com o ok da pessoa:
```

File: seeds/processar-reuniao/SKILL.md
```markdown
Arquivo em `reunioes/{pessoa-ou-ritual}/YYYY-MM-DD.md`, mira de 25 linhas no máximo.
```
<!-- vibeflow:auto:end -->

## Proveniência das regras de autoria
`skills/criar-skill/SKILL.md` cita a fonte por link: "The new rules of context engineering for Claude 5 generation models" (https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models), o post que documenta um system prompt de agente cortado em mais de 80% sem perda mensurável. Regra de autoria que entrar aqui sem proveniência declarada fica marcada como opinião do repo, não como prática medida.

## Anti-patterns (if found)
- Resolvido desde 30/07: `plantar` listava o catálogo pela "primeira linha após o título de cada SKILL.md", que é o banner idêntico em todas as sementes. Hoje lista pelo `description` do frontmatter, com o motivo escrito no próprio passo. A régua que sobra: não ancorar parsing em posição de texto.
- `skills/setup/SKILL.md` tem 216 linhas e é a única skill do repo que não cabe na régua de "corpo curto + progressive disclosure" que o `criar-skill` ensina. Nada foi extraído pra arquivo separado (os 7 blocos do discovery, a arquitetura de memória, os 10 anti-padrões e a régua de destinos convivem no corpo). A skill roda uma vez por pessoa, o que reduz o custo, e o `criar-skill` não se aplica a si mesmo nem ao setup; ainda assim é a maior dívida de autoria do repo (medido em 06/08/2026).
