# Spec: exemplo, parte 4 (a vivência: diário, pauta, nota, log)

## Objective
A parte que prova o sistema em movimento: o loop diário rodando no diário, o par pauta → nota processada, e o log do dia apontando pros destinos.

## Definition of Done
1. [ ] `diario/2026-07-20 semana.md` com: blocos `## 3 do dia , DD/MM` de seg a qui fechados (`**Balanço:** N/3` + motivo + `**→ amanhã:**`), sexta 24/07 aberta com as 3 propostas ancoradas nas prioridades, tasks com prazo, e o encadeamento correto (o `**→ amanhã:**` de cada dia é a #1 do seguinte).
2. [ ] `reunioes/rafael/2026-07-22 pauta.md` no template do preparar-conversa (≤15 linhas, com seção de feedback com situação → comportamento → impacto) e `reunioes/rafael/2026-07-22.md` no template do processar-reuniao (≤25 linhas, com decisões, tasks, sinais, não resolvido).
3. [ ] `memory/2026-07-22.md` no formato `## [HH:MM] Tópico` + 2-4 linhas com ponteiro, cobrindo os marcos do dia retratado.
4. [ ] Coerência cruzada verificada: task da nota está no diário com prazo; sinal da nota está no hub do Rafael (parte 3) com a mesma data; prioridades citadas batem com o CRITICAL_FACTS (parte 1).
5. [ ] Craftsmanship: cânone; os rótulos de contrato com a grafia exata dos seeds.

## Scope
`EXEMPLO/diario/2026-07-20 semana.md`, `EXEMPLO/reunioes/rafael/2026-07-22 pauta.md`, `EXEMPLO/reunioes/rafael/2026-07-22.md`, `EXEMPLO/memory/2026-07-22.md` (4 arquivos).

## Anti-scope
Semana de 13/07 fica só referida (trajetoria e navegação): um diário basta pra mostrar o loop.

## Applicable Patterns
`system-contracts` (é a demonstração viva deles), `writing-canon`.

## Dependencies
- .vibeflow/specs/exemplo-part-1.md
- .vibeflow/specs/exemplo-part-3.md (o sinal do hub nasce da nota desta parte)
