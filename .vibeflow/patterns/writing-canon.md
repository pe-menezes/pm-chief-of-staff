---
tags: [writing, style, canon, anti-tells, pt-br, tone]
modules: [skills/, seeds/, ./]
applies_to: [skills, seeds, docs, configs]
confidence: inferred
---
# Pattern: Writing Canon

<!-- vibeflow:auto:start -->
## What
O cânone de escrita que todo arquivo do repo segue e que o produto propaga: o setup o escreve no CLAUDE.md gerado, e cada semente carrega uma versão fallback. Quem edita este repo escreve sob as mesmas regras que o repo ensina.

## Where
Definido em `skills/setup/SKILL.md` (seção "Como você escreve") e `PROMPT.md`; aplicado em 100% dos arquivos; propagado pelas sementes via linha fallback.

## The Pattern
File: skills/setup/SKILL.md
```markdown
* Nunca use travessão (— ou –). Substitua por vírgula, parênteses, dois pontos, ou reescreva a frase. Sem exceção.
* Tom factual: título descritivo, adjetivo só quando medido, número com fonte. O texto informa, não vende e não se explica.
* Frases curtas e densas. Sem preâmbulo, sem "basicamente", sem resumir o que acabou de fazer.
* Report lidera com decisão e estado, 1 linha por item. Escreva o delta, não o episódio.
* Repetição de forma denuncia texto gerado. Os tells a caçar: o paralelismo antitético ("não é X, é Y"), a cláusula final que repete a conclusão da frase anterior, a regra de três retórica ("claro, direto e objetivo") e o superlativo sem medida ("poderoso", "essencial", "game-changer"). Apareceu duas vezes no mesmo texto, uma cai.
* Termine o parágrafo com informação, nunca com frase curta sentenciosa de veredito.
```

A propagação em 2 níveis: o setup injeta a seção no CLAUDE.md gerado ("Esta seção entra no CLAUDE.md gerado como cânone de escrita"), e cada semente abre com o fallback pra funcionar antes do CLAUDE.md existir:

File: seeds/abrir-dia/SKILL.md
```markdown
Escrita: siga o cânone do CLAUDE.md desta pasta. Na ausência dele: sem travessão (use vírgula, parênteses ou dois pontos), frases curtas e densas, 1 linha por item.
```

## Rules
- Zero travessão (em dash ou en dash) em qualquer arquivo do repo; a única ocorrência permitida é dentro da própria regra que o proíbe.
- Conteúdo em pt-BR; termo técnico consagrado fica em inglês (thought partner, follow-up, grep).
- Tom factual, sem venda; adjetivo só quando medido.
- Tells de IA sob a regra "apareceu 2x, uma cai": paralelismo antitético, cláusula-eco, regra de três retórica, superlativo sem medida, veredito curto de fechamento.
- Artefato que instrui outro agente (skill, semente, prompt colável) carrega o cânone dentro de si, não só o segue.

## Examples from this codebase
File: PROMPT.md
```markdown
Nunca use travessão (— ou –): substitua por vírgula, parênteses, dois pontos, ou reescreva. Tom factual: adjetivo só quando medido, número com fonte, o texto informa e não vende.
```

File: seeds/fechar-dia/SKILL.md
```markdown
7. **Responder curto:** compilado + balanço (`N/3` + motivo) + semente de amanhã. Sem cheerleading.
```
<!-- vibeflow:auto:end -->

## Anti-patterns (if found)
A narração do próprio repo usa o paralelismo antitético acima da régua declarada ("apareceu 2x, uma cai"): 14 ocorrências de construção ", não " em `skills/setup/SKILL.md` e 10 em `PROMPT.md` (medido em 30/07/2026). Parte é resposta enlatada de anti-padrão (martelo proposital); a densidade na narração fica acima da própria regra. Ao editar esses arquivos, não adicionar novas ocorrências.
