---
tags: [seeds, lifecycle, ownership, updates, distribution]
modules: [seeds/, modulos/, skills/setup/, skills/plantar/, skills/conectar/]
applies_to: [seeds, skills, modules]
confidence: inferred
---
# Pattern: Seed Model

<!-- vibeflow:auto:start -->
## What
O ciclo de vida da semente: skill starter que vive no plugin só até ser copiada pra pasta da pessoa, onde vira arquivo dela, editável e fora do alcance de updates. É o mecanismo que resolve a tensão entre atualização do plugin e customização do usuário. Desde v0.2.x o mesmo ciclo vale pro módulo compartilhado (`modulos/capacidades.md` → `.claude/skills/_shared/capacidades.md`): template no plugin, arquivo da pessoa depois do plantio.

## Where
`seeds/` (o catálogo, 6 sementes), `modulos/` (template de módulo), `skills/setup/SKILL.md` (planta 5 sementes + o módulo no fim do setup), `skills/plantar/SKILL.md` (planta avulso), `skills/conectar/SKILL.md` (escreve e reescreve o módulo, e confere os consumidores), README (explica o modelo ao usuário).

## The Pattern
Sementes moram em `seeds/`, deliberadamente FORA de `skills/`: o Claude Code só registra como skill o que está em `skills/`, então a semente não vira comando do plugin nem colide com a cópia plantada. O plantio é uma cópia pra `.claude/skills/` da pasta da pessoa, e a partir daí o plugin nunca mais toca no arquivo.

File: skills/plantar/SKILL.md
```markdown
Semente é uma skill starter que vive no plugin só até ser plantada: copiada pra `.claude/skills/` da pasta da pessoa, ela vira arquivo DELA, editável, auto-modulável, fora do alcance de qualquer atualização do plugin.
```

Toda semente carrega, logo após o título, o banner de posse e a linha de escrita fallback (a semente plantada precisa funcionar sozinha, sem o plugin e antes do CLAUDE.md existir):

File: seeds/preparar-conversa/SKILL.md
```markdown
> Semente do pm-chief-of-staff. Este arquivo é SEU: peça pro agente mudar o formato da pauta ("quero que sempre tenha uma seção de X") e ele edita a skill na hora.

Escrita: siga o cânone do CLAUDE.md desta pasta. Na ausência dele: sem travessão (use vírgula, parênteses ou dois pontos), frases curtas e densas, 1 linha por item.
```

Colisão nunca resolve por sobrescrita:

File: skills/plantar/SKILL.md
```markdown
3. **Checar colisão.** Se já existe `.claude/skills/{nome}/` na pasta dela: **nunca sobrescrever**. Ofereça: manter a dela (default), plantar com outro nome pra comparar, ou mostrar o diff entre as duas.
```

O caminho do catálogo resolve por `${CLAUDE_PLUGIN_ROOT}` com fallback declarado:

File: skills/setup/SKILL.md
```markdown
copie as 5 skills-semente da pasta `seeds/` do plugin (em `${CLAUDE_PLUGIN_ROOT}/seeds/`; se a variável não resolver, localize a pasta do plugin `pm-chief-of-staff` no cache de plugins)
```

O catálogo tem 6 sementes e o setup planta 5: `fechar-semana` fica de fora de propósito, pra ser o primeiro plantio que a pessoa faz sozinha no fim da primeira semana de uso. Semente sem uso no dia 1 plantada no dia 1 é arquivo que ela não sabe que tem.

O módulo compartilhado segue o mesmo ciclo, com uma diferença: a pasta `_shared/` não leva `SKILL.md`, então não vira skill nem comando.

File: skills/conectar/SKILL.md
```markdown
* **O módulo é arquivo dela.** Atualização do plugin não toca nele, e melhoria futura no template não chega em quem já rodou: rodar esta skill de novo é o caminho.
```

## Rules
- Semente nova entra em `seeds/{nome}/SKILL.md`, nunca em `skills/`. Módulo novo entra em `modulos/{nome}.md` e é plantado em `.claude/skills/_shared/`.
- Toda semente carrega o banner de posse e a linha de escrita fallback logo após o título.
- Semente referencia só paths do sistema gerado (`pessoas/`, `reunioes/`, `diario/`, `memory/`, `contexto/`, `CRITICAL_FACTS.md`, `.claude/skills/_shared/`); nunca referencia o plugin, seus comandos ou `${CLAUDE_PLUGIN_ROOT}`.
- Plantio é cópia; colisão oferece manter, renomear ou diff. Sobrescrever não é opção, e reescrever do zero um arquivo dela também não.
- **Melhoria no catálogo alcança só plantios futuros.** A base instalada fica na versão que plantou, e o plugin não tem canal pra chegar nela. Corrigir bug de semente é metade do trabalho: a outra metade é dar à pessoa um jeito de descobrir que a cópia dela está velha (ver a consequência abaixo).
- Mudança em semente que a pessoa provavelmente editou nunca vira instrução de sobrescrita; vira detecção mais oferta, arquivo por arquivo, com o ok dela.

## Examples from this codebase
File: README.md
```markdown
A partir do momento em que são plantadas, **essas skills são arquivos seus**. [...] Minhas atualizações futuras **nunca tocam no que é seu**: elas só melhoram o setup e adicionam sementes novas no catálogo (`/pm-chief-of-staff:plantar` lista o que há).
```

File: skills/setup/SKILL.md
```markdown
Ao plantar, diga com todas as letras: **"essas 5 skills agora são arquivos seus. Me pede pra mudar qualquer uma ('quero que a pauta sempre tenha X') que eu edito a skill na hora. Atualização do plugin nunca toca nelas."**
```
<!-- vibeflow:auto:end -->

## A consequência que o modelo cobra (o caso medido, v0.2.x)

Em 30/07 esta seção registrava um risco latente: bug corrigido numa semente não alcança cópias já plantadas. A camada de capacidades transformou o risco em caso concreto, e vale registrar por extenso porque é a forma que todo aperfeiçoamento futuro de semente vai assumir.

O que aconteceu: `conectar` passou a escrever `.claude/skills/_shared/capacidades.md`, e as 3 sementes que buscam dado de fora ganharam, no catálogo, o passo que lê o módulo. Quem plantou antes dessa mudança tem 3 arquivos que nunca vão ler o módulo. O sintoma não é erro: a skill continua perguntando, exatamente como antes, e a pessoa recebe um mapa de capacidades que não muda nada no dia seguinte.

Os dois mecanismos que nasceram disso, e que são a resposta padrão do modelo:

File: skills/conectar/SKILL.md
```markdown
4. **Conferir os consumidores.** Abra cada skill declarada na linha "Carregado por" do módulo e veja se ela referencia `capacidades.md` no passo em que busca dado. Skill que não referencia não muda em nada com o módulo escrito: ela continua perguntando. É o caso de quem plantou as sementes antes desta camada existir, e o único jeito de saber é abrir e olhar. Ofereça a edição uma por uma e **nunca edite sem o ok**, porque skill plantada é arquivo dela.
```

File: seeds/fechar-semana/SKILL.md
```markdown
Existindo módulo em `.claude/skills/_shared/`, conferir se cada skill declarada no topo dele ainda o referencia: consumidor sem referência para de aplicar a disciplina sem dar erro, e essa linha do topo é a única pista.
```

A régua que sai do caso: melhoria de semente que muda contrato (passa a ler um arquivo novo, muda um rótulo, depende de uma camada nova) tem 3 partes, não 1. Editar o catálogo · escrever a detecção em alguma skill que a pessoa roda de novo (`conectar` no evento, `fechar-semana` na cadência) · declarar o sintoma silencioso, porque o que não dá erro ninguém procura. O setup faz a versão dele dessa checagem no plantio, pra colisão que mantém a cópia dela:

File: skills/setup/SKILL.md
```markdown
Se alguma delas foi mantida da pasta dela na checagem de colisão acima, abra e confira: cópia anterior a esta camada não referencia o módulo, e aí o módulo é escrito sem efeito nenhum. Ofereça a edição da skill dela, nunca sobrescreva.
```

## Anti-patterns (if found)
- `plantar` é o único dos quatro caminhos de plantio sem checagem de camada: planta a semente e avisa que virou arquivo dela, sem conferir se o módulo que ela lê existe e sem acrescentar a semente nova na linha "Carregado por" do módulo. Setup, `conectar` e `fechar-semana` fazem a conferência; `plantar` não (medido em 06/08/2026).
- O template `modulos/capacidades.md` já nasce com 3 consumidoras declaradas na linha "Carregado por". Se a pessoa plantou menos que as 3, a linha promete leitor que não existe na pasta dela, e o passo 4 do `conectar` vai procurar arquivo que não está lá.
