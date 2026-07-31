---
name: fechar-semana
description: Fecha a semana de trabalho e monta a próxima. Agrega os balanços diários, lê o padrão da semana, força 1 a 3 decisões, revisita as dores registradas, mede a saúde da memória do sistema, guarda sinal de trajetória e deixa o diário da semana nova pronto. Use quando a pessoa disser "fecha a semana", "fechar a semana", "review da semana", "como foi minha semana", "monta a próxima semana", "/fechar-semana", em geral na tarde do último dia útil. NÃO use pra fechar um dia (fechar-dia), abrir o dia (abrir-dia) nem pra update de meio de semana (diário direto).
---

# Fechar a semana

> Semente do pm-chief-of-staff. Este arquivo é SEU: peça pro agente mudar qualquer passo e ele edita esta skill na hora.

Escrita: siga o cânone do CLAUDE.md desta pasta. Na ausência dele: sem travessão (use vírgula, parênteses ou dois pontos), frases curtas e densas, 1 linha por item.

O `fechar-dia` avalia um dia; esta skill lê a semana inteira e decide. O dia a dia deixa passar o que só aparece em série: o mesmo motivo 4 vezes, a mesma task escorregando, a prioridade parada há 10 dias. Compilar é pull do que os fechamentos diários já gravaram; entrevistar é exceção.

## Fluxo

1. **Compilar a semana do que está escrito**: os blocos `## 3 do dia` do diário (a sequência de `**Balanço:** N/3` + motivos), as linhas `**Reflexão:**`, os logs `memory/` de cada dia, o diff da pasta, e o `## Fechamento da semana` anterior se existir (tendência: o padrão que repete pesa mais que o da semana isolada). Sem balanços porque os dias não foram fechados: compilar do que há e dizer que o padrão fica mais pobre sem o fechamento diário.
2. **Prioridades**: pra cada prioridade do `CRITICAL_FACTS.md`, responder com evidência: avançou, parcial ou parada? Fechou de vez: propor a atualização do arquivo. Parada 2+ semanas: entra nos calls.
3. **Ler o padrão nos motivos agregados**: o mesmo motivo em 3+ dias é padrão de autogestão, e cada um aponta um ajuste diferente: **faltou tempo** recorrente = ambição descalibrada com a agenda · **ataque externo** = filtro de aceitação furado ou semana estruturalmente reativa · **a 3 errada** = a priorização da manhã errando o alvo. Fechar com a semana em 2-3 frases: focada ou reativa, e as entregas serviram as prioridades?
4. **(Se você lidera) passada pelo time**: quem entregou, quem escorregou repetido, e task de liderado que você acabou assumindo (some as horas: é o Super-Líder da semana aparecendo em número).
5. **Dores**: existe `contexto/dores.md`? Reler: alguma melhorou, piorou ou venceu a data de revisão? Dor vencida sem movimento vira call.
6. **Saúde da memória**: `wc -c` no `CRITICAL_FACTS.md` contra ~3KB (os ~700 tokens do alvo, em bytes) e no `CLAUDE.md` contra ~10KB; esses arquivos entram em toda sessão, e régua sem medição infla em silêncio. Dentro do alvo, o passo fica em silêncio na resposta. Estourou: propor curadoria concreta, nunca cortar sozinho. No `CRITICAL_FACTS.md`: evento que deixou de ser ativo vira histórico (log ou hub) e prioridade resolvida sai. No `CLAUDE.md`: regra que pertence a uma skill específica migra pra skill plantada correspondente (ela é da pessoa, editável); regra que parece morta, a pessoa decide se mata. Na mesma passada, hub com "Sinais recentes" acumulando sinal antigo já consolidado no corpo pede poda: propor em 1 linha. A skill mede e propõe; a decisão é sempre da pessoa.
7. **Trajetória**: 1 a 2 sinais de impacto seu na semana (entrega que moveu número, decisão difícil tomada, reconhecimento recebido) → propor 1 linha datada em `contexto/trajetoria.md`. É o material que a avaliação de ciclo e a conversa de promoção pedem, e que ninguém reconstrói de memória depois; quem não lidera é quem mais precisa do registro.
8. **Os calls (1 a 3, obrigatório)**: decisões nomeadas a partir do que apareceu, no formato dado → decisão: "{prioridade} não anda há 2 semanas: repriorize ou admita que morreu" · "o motivo {X} fechou {N} dias: {ajuste do passo 3}" · "{task} escorregou 2 semanas: fazer, delegar ou matar". Semana sem call pede desconfiança (review rasa é mais comum que semana perfeita); se a semana foi boa mesmo, o call é "repetir {o que funcionou}".
9. **Montar a próxima semana**: criar o diário novo em `diario/`, no padrão de nome que a pasta já usa. Migrar toda `- [ ]` ainda relevante, dedupada e com data; task escorregando 2+ semanas só migra com a decisão do passo 8 tomada. Promover o último `**→ amanhã:**` da semana pra primeira task de segunda: é o elo da virada, sem ele a semente de sexta fica órfã no diário velho.
10. **Gravar e responder curto**: a análise (padrão + calls) appendada no fim do diário que fecha, sob `## Fechamento da semana , DD/MM a DD/MM`; no chat, o padrão em 2-3 frases + os calls + os links dos dois diários. Sem recontar a semana.

## O loop

`abrir-dia` e `fechar-dia` giram o dia; esta skill gira a semana: consome os fechamentos diários, decide o que o dia não decide e deixa o diário novo pronto pro `abrir-dia` de segunda.

## Quando NÃO usar

Fim de um dia comum → `fechar-dia`. Começo de dia → `abrir-dia`. Meio da semana ("fiz X") → update direto no diário.
