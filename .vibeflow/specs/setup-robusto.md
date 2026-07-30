# Spec: setup robusto (discovery crash-safe + destinos + fechamento honesto)

## Objective
O discovery de 20-30 minutos sobrevive a queda de sessão e as respostas dos 7 blocos têm destino: nada do que a pessoa contou evapora.

## Context
Hoje o setup segura tudo em conversa até o fim ("sem criar arquivo ainda"): queda, `/clear` ou compact no bloco 6 perde a entrevista, e o público-alvo não conhece resume de sessão. Os blocos 3 (ferramentas), 5 (rituais) e 6 (dores) não aparecem na lista de conteúdo de nenhum artefato gerado (known issue do index). O fechamento promete teste imediato com skill recém-plantada, que pode não estar registrada na sessão corrente, e não oferece rede de backup. PROMPT.md é o espelho colável do setup e precisa de paridade.

## Definition of Done
1. [ ] A seção do discovery instrui: resposta de bloco recebida vira append em `setup-notas.md` (`## Bloco N` + bullets) antes da pergunta seguinte.
2. [ ] "Antes de começar: olhe a pasta" cobre `setup-notas.md` existente: retomar do bloco seguinte ao último gravado, sem repetir pergunta respondida.
3. [ ] A proposta pós-discovery inclui `contexto/` com destino explícito dos blocos 3, 5 e 6 (`ferramentas-e-fontes.md`, `rituais.md`, `dores.md` com data de revisão a +3 meses por dor).
4. [ ] `setup-notas.md` tem fim de vida declarado: vira `contexto/discovery-YYYY-MM-DD.md` depois que os artefatos são criados.
5. [ ] O plantio avisa que skill plantada registra como comando na próxima sessão e que o teste imediato segue o SKILL.md plantado lido direto.
6. [ ] O fechamento oferece backup opcional (git init com o ganho em 1 linha, alternativa sem git, sem insistir).
7. [ ] PROMPT.md espelha os itens 1-4; craftsmanship: zero travessão novo, zero construção antitética nova, rótulos e paths de `patterns/system-contracts.md` intocados.

## Scope
`skills/setup/SKILL.md`, `PROMPT.md` (2 arquivos, budget ≤4 ok).

## Anti-scope
- Nenhuma semente é tocada; semente de fechamento de semana é outra spec.
- Sem bump de versão no plugin.json (bump único depois dos merges da série).
- Sem reescrita da narração existente do setup: a densidade de tells pré-existente é problema separado, registrado em `patterns/writing-canon.md`.
- Sem conector, automação ou hook.

## Technical Decisions
- `setup-notas.md` na raiz da pasta, visível: a pessoa precisa ver que existe pra confiar na retomada. É temporário e migra pra `contexto/` no fim.
- Formato `## Bloco N`: âncora estrutural, seguindo o Don't de nunca ancorar em posição de texto.
- Dores com data de revisão: o Bloco 6 pergunta o que melhorar em 3 meses; a data marca a cobrança.
- Arquivar em vez de apagar: material bruto de discovery segue o mesmo princípio do log (imutável, barato de guardar).

## Applicable Patterns
- `writing-canon` (todo texto novo)
- `system-contracts` (`contexto/` estende a estrutura proposta; nenhum rótulo existente muda)
- `skill-authoring` (verbo direto, validação antes de side effect)

## Risks
- Executor pode esquecer o append no meio da conversa longa → a instrução mora dentro da seção do discovery, onde o executor está lendo na hora, e o formato é 1 append curto por bloco.
- PROMPT.md é colável e não pode inchar → espelho em 3-4 linhas, sem duplicar explicação.
- Retomada com bloco meio-respondido → regra simples: bloco sem `## Bloco N` gravado se pergunta inteiro de novo.
