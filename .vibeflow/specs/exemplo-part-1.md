# Spec: exemplo, parte 1 (núcleo do sistema fictício)

## Objective
Quem chega no repo vê o núcleo de um sistema com 2 semanas de uso antes de investir 30 minutos no setup.

## Context
O README vende só com palavras; não existe forma de ver o fim do funil. A pasta `EXEMPLO/` retrata um caso 100% fictício: Marina, GPM de monetização na Meridiano (SaaS B2B de gestão pra clínicas veterinárias, empresa inventada), lidera Rafael (PM pleno) e Bia (APM), reporta à Cláudia (CPO). Sistema criado em 13/07/2026; retrato tirado na sexta 24/07/2026. A spec racha em 4 partes por causa do budget (≤4 arquivos por task); esta parte cria o núcleo que as outras referenciam.

## Definition of Done
1. [ ] `EXEMPLO/README.md` declara fictício (pessoas, empresa e números inventados), diz como a pasta foi montada (as skills do plugin sobre o caso) e aponta o que olhar em 5 minutos.
2. [ ] `EXEMPLO/CLAUDE.md` é um exemplar fiel do que o setup gera: identidade, princípios, postura, anti-padrões com os de liderança ativos, rigor, cânone de escrita, memória em 4 camadas, rotina de sessão, auto-modulação; inclui 1 modulação datada posterior ao setup (prova do princípio 1).
3. [ ] `EXEMPLO/CRITICAL_FACTS.md` no contrato do setup: identidade 1 linha, 3 prioridades numeradas com número que importa, eventos ativos ≤5, ~700 tokens.
4. [ ] `EXEMPLO/navegacao.md` indexa a pasta inteira (inclusive o que as partes 2-4 criam).
5. [ ] Craftsmanship: cânone de escrita; nenhum nome de pessoa ou empresa real.

## Scope
`EXEMPLO/README.md`, `EXEMPLO/CLAUDE.md`, `EXEMPLO/CRITICAL_FACTS.md`, `EXEMPLO/navegacao.md` (4 arquivos).

## Anti-scope
Conteúdo de contexto, hubs e vivência (partes 2-4). Nenhum arquivo fora de `EXEMPLO/` nesta parte.

## Applicable Patterns
`system-contracts` (formatos do CRITICAL_FACTS e da rotina), `writing-canon`.

## Risks
Empresa fictícia colidir com marca real do setor retratado → nome genérico (Meridiano) + setor (clínicas veterinárias) sem player homônimo conhecido + disclaimer no README da pasta.
