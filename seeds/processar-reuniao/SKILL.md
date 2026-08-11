---
name: processar-reuniao
description: Transforma uma reunião que aconteceu em nota estruturada e propaga o que importa. A pessoa cola a transcrição, o resumo automático ou as notas cruas. Use quando a pessoa disser "processa essa reunião", "processa esse 1:1", "olha o que rolou na reunião", colar uma transcrição pedindo organização, ou "/processar-reuniao". NÃO use pra preparar conversa futura (preparar-conversa).
---

# Processar uma reunião

> Semente do pm-chief-of-staff. Este arquivo é SEU: peça pro agente mudar o formato da nota ou as regras de propagação e ele edita esta skill na hora.

Escrita: siga o cânone do CLAUDE.md desta pasta. Na ausência dele: sem travessão (use vírgula, parênteses ou dois pontos), frases curtas e densas, 1 linha por item.

O valor não é resumir: é extrair o que muda o estado do sistema (decisão, task, sinal sobre pessoa ou projeto) e colocar cada coisa no lugar onde vai ser encontrada. Uma reunião processada e propagada vale mais que dez transcrições guardadas.

## Passo 1: receber o material

Aceitar qualquer forma: transcrição colada, resumo automático (Gemini, Zoom, Granola), foto de quadro, notas cruas digitadas. Perguntar só o que não dá pra inferir: com quem foi e quando (se não estiver no material).

Se existir `.claude/skills/_shared/capacidades.md` com `provider` e `como chamar` na linha `transcrição de reunião`, oferecer buscar a transcrição por ali em vez de esperar o material colado. Sem o módulo, com a linha pela metade, ou sem resultado na busca, seguir pelo que a pessoa colar.

Transcrição é evidência do que foi DITO, não do que é verdade: afirmação factual relevante que só existe na fala entra na nota marcada como "a validar".

## Passo 2: escrever a nota

Arquivo em `reunioes/{pessoa-ou-ritual}/YYYY-MM-DD.md`, mira de 25 linhas no máximo. O texto bruto (transcrição, resumo automático) NUNCA entra no vault operacional: guardado aqui dentro, vira distrator de toda busca futura. A nota é o destilado + 1 linha de ponteiro pra onde o bruto vive (pasta fria fora do vault, drive, ou a própria origem). A skill não move nem apaga o bruto: a pessoa decide onde ele fica.

```markdown
---
tipo: nota-de-reuniao
com: {pessoa ou ritual}
data: YYYY-MM-DD
---

**Contexto:** {1 linha}
**Bruto:** {ponteiro em 1 linha pra onde o texto original vive}

## Decisões
- {1 linha por decisão: o que foi decidido + quem decidiu}

## Tasks
- [ ] {ação + dono + prazo se dito} (suas tasks também vão pro diário, ver propagação)

## Sinais
- {o que a conversa revelou sobre pessoa, projeto ou risco, 1 linha cada}

## Não resolvido
- {o que ficou aberto e volta na próxima}
```

Se houve pauta preparada (`preparar-conversa`), comparar: o que da pauta não foi falado volta como candidato pra próxima.

## Passo 3: propagar (é aqui que o sistema fica vivo)

Régua da subida, "o que persiste vs o que passa": decisão, acordo, fato de pessoa, preferência e compromisso propagam (hub, diário, `memory/`); estado emocional momentâneo, detalhe operacional transitório e observação circunstancial ficam na nota e morrem lá. A nota retém tudo; a régua só decide o que sobe.

Antes de escrever em destino compartilhado (hub, diário, `CRITICAL_FACTS.md`), ler `.claude/skills/_shared/gate-de-escrita.md` e aplicar a decisão de admissão (ADD, UPDATE, SUPERSEDE, NOOP). Sem o módulo, a checagem em 1 linha: ler o destino antes de escrever, e não escrever o que já está lá.

Propor a propagação e executar com o ok da pessoa:

1. **Tasks da pessoa** → diário da semana, com prazo.
2. **Sobre pessoa-chave** → hub dela em `pessoas/`, na seção certa: fato datado com fonte em "Fatos", sinal em "Sinais recentes" (1 linha datada), leitura que muda a vigente em "Leitura" (datada, marcando a anterior com "superada em DD/MM por {o que a superou}").
3. **Decisão ou virada de projeto** → hub do projeto em `projetos/`.
4. **Marco do dia** → 1 bloco no `memory/{hoje}.md` apontando pra nota (`## [HH:MM] {título} + 2 linhas`).
5. **Mudou prioridade ou evento ativo** → propor atualização do `CRITICAL_FACTS.md`.

Regra de ouro: o detalhe vive na nota; hub e log apontam. Nunca duplicar o conteúdo inteiro em dois lugares.

## Passo 4: responder curto

A nota em path clicável + o que foi propagado (1 linha por destino) + o que ficou "a validar". Sem recontar a reunião no chat.
