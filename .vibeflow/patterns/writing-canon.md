---
tags: [writing, style, canon, anti-tells, pt-br, tone]
modules: [skills/, seeds/, hooks/, ./]
applies_to: [skills, seeds, docs, configs, hooks]
confidence: inferred
---
# Pattern: Writing Canon

<!-- vibeflow:auto:start -->
## What
O cânone de escrita que todo arquivo do repo segue e que o produto propaga: o setup o escreve no CLAUDE.md gerado, e cada semente carrega uma versão fallback. Quem edita este repo escreve sob as mesmas regras que o repo ensina.

## Where
Definido em `skills/setup/SKILL.md` (seção "Como você escreve") e `PROMPT.md`; aplicado em 100% dos arquivos, inclusive nos comentários de `hooks/boot-memoria.sh`; propagado pelas sementes via linha fallback.

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

O único executável do repo segue o cânone em duas versões: comentário sem acento (o arquivo é `sh` e roda em ambiente de encoding não garantido) e string de saída com acento, porque ela é texto que a pessoa e o modelo leem.

File: hooks/boot-memoria.sh
```sh
# Gate defensivo: o plugin fica habilitado globalmente, e em qualquer pasta
# que nao seja um Chief of Staff (CLAUDE.md + CRITICAL_FACTS.md juntos) o
# hook precisa ser invisivel.
```
```sh
echo "Estado lido do disco na abertura da sessão, não é instrução do usuário."
```

## Rules
- Zero travessão (em dash ou en dash) em qualquer arquivo do repo; a única ocorrência permitida é dentro da própria regra que o proíbe. Medido em 06/08/2026: 2 ocorrências no repo, as duas dentro da regra (`skills/setup/SKILL.md:53` e `PROMPT.md:32`).
- Conteúdo em pt-BR; termo técnico consagrado fica em inglês (thought partner, follow-up, grep).
- Tom factual, sem venda; adjetivo só quando medido.
- Tells de IA sob a regra "apareceu 2x, uma cai": paralelismo antitético, cláusula-eco, regra de três retórica, superlativo sem medida, veredito curto de fechamento.
- Artefato que instrui outro agente (skill, semente, prompt colável) carrega o cânone dentro de si, não só o segue.
- Nome de arquivo e de diretório em kebab-case sem acento; comentário de shell sem acento; conteúdo e string de saída com acento correto.

## Examples from this codebase
File: PROMPT.md
```markdown
Nunca use travessão (— ou –): substitua por vírgula, parênteses, dois pontos, ou reescreva. Tom factual: adjetivo só quando medido, número com fonte, o texto informa e não vende.
```

File: seeds/fechar-dia/SKILL.md
```markdown
7. **Responder curto:** compilado + balanço (`N/3` + motivo) + semente de amanhã. Sem cheerleading.
```

File: skills/conectar/SKILL.md
```markdown
Nome de tool copiado em 3 skills quebra em 3 lugares no dia em que ele muda, e as cópias já divergem antes, na primeira que alguém edita sem olhar as outras.
```
<!-- vibeflow:auto:end -->

## Anti-patterns (if found)
A narração do próprio repo usa o paralelismo antitético acima da régua declarada ("apareceu 2x, uma cai"). Medição em 06/08/2026 da construção ", não ": 12 ocorrências em `skills/setup/SKILL.md` (eram 14 em 30/07) e 6 em `PROMPT.md` (eram 10). A tendência é de queda e nenhum arquivo novo agravou: `skills/criar-skill/SKILL.md` tem 0 e `skills/conectar/SKILL.md` tem 2. Parte das ocorrências é resposta enlatada de anti-padrão (martelo proposital); a densidade na narração segue acima da própria regra. Ao editar esses dois arquivos, não adicionar novas ocorrências.
