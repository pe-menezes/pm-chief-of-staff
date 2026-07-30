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

Transcrição é evidência do que foi DITO, não do que é verdade: afirmação factual relevante que só existe na fala entra na nota marcada como "a validar".

## Passo 2: escrever a nota

Arquivo em `reunioes/{pessoa-ou-ritual}/YYYY-MM-DD.md`, mira de 25 linhas no máximo. A transcrição crua NÃO entra na nota (se a pessoa quiser guardar, vai pra `reunioes/{pessoa-ou-ritual}/raw/`).

```markdown
---
tipo: nota-de-reuniao
com: {pessoa ou ritual}
data: YYYY-MM-DD
---

**Contexto:** {1 linha}

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

Propor a propagação e executar com o ok da pessoa:

1. **Tasks da pessoa** → diário da semana, com prazo.
2. **Sinal sobre pessoa-chave** → seção "Sinais recentes" do hub dela em `pessoas/`, 1 linha datada.
3. **Decisão ou virada de projeto** → hub do projeto em `projetos/`.
4. **Marco do dia** → 1 bloco no `memory/{hoje}.md` apontando pra nota (`## [HH:MM] {título} + 2 linhas`).
5. **Mudou prioridade ou evento ativo** → propor atualização do `CRITICAL_FACTS.md`.

Regra de ouro: o detalhe vive na nota; hub e log apontam. Nunca duplicar o conteúdo inteiro em dois lugares.

## Passo 4: responder curto

A nota em path clicável + o que foi propagado (1 linha por destino) + o que ficou "a validar". Sem recontar a reunião no chat.
