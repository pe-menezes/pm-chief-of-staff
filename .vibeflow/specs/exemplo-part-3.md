# Spec: exemplo, parte 3 (hubs + vitrine no README raiz)

## Objective
Os hubs mostram a camada semântica (o que estabilizou sobre pessoa e projeto) e o README raiz ganha o link que faz a pasta existir pro visitante.

## Definition of Done
1. [ ] `pessoas/rafael.md` (liderado) com contexto 2 linhas, "Sinais recentes" datados em 1 linha e histórico apontando pras notas de reunião; o sinal de 22/07 é o mesmo que a nota processada da parte 4 propaga.
2. [ ] `pessoas/claudia.md` (líder) com o que ela valoriza e sinais de managing up.
3. [ ] `projetos/reajuste-de-planos.md` com estado, decisões datadas e próximo marco, consistente com a prioridade 1 do CRITICAL_FACTS.
4. [ ] README raiz linka `EXEMPLO/` em 1 parágrafo logo após a abertura.
5. [ ] Craftsmanship: cânone; detalhe mora no hub sem duplicar a nota (regra de ouro do processar-reuniao).

## Scope
`EXEMPLO/pessoas/rafael.md`, `EXEMPLO/pessoas/claudia.md`, `EXEMPLO/projetos/reajuste-de-planos.md`, `README.md` (4 arquivos).

## Anti-scope
Hub da Bia (APM) fica de fora do retrato: 2 hubs de pessoa bastam pra mostrar o padrão; a navegação a cita.

## Applicable Patterns
`system-contracts` (seção "Sinais recentes" como contrato), `writing-canon`.

## Dependencies
- .vibeflow/specs/exemplo-part-1.md
