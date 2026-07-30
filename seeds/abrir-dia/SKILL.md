---
name: abrir-dia
description: Abre o dia de trabalho. Monta a agenda, varre as tasks abertas, propõe as 3 do dia ancoradas nas prioridades e grava no diário. Use quando a pessoa disser "bom dia", "abre meu dia", "monta meu dia", "o que faço hoje", "/abrir-dia". Sempre interativo (propõe, a pessoa valida). NÃO use pra fechar o dia (fechar-dia) nem pra review de fim de tarde.
---

# Abrir o dia

> Semente do pm-chief-of-staff. Este arquivo é SEU: peça pro agente mudar qualquer passo ("quero que a abertura sempre inclua X") e ele edita esta skill na hora.

Monta o dia em cima do que já está escrito: prioridades, tasks abertas, agenda, e a semente que o fechamento de ontem deixou. Propõe as 3 do dia; a pessoa valida antes de cravar.

## Princípios

1. As prioridades de `CRITICAL_FACTS.md` filtram tudo: task que não ancora em prioridade precisa de motivo pra entrar no dia.
2. As 3 do dia vivem no diário da semana, bloco `## 3 do dia , DD/MM` no topo.
3. A skill propõe, a pessoa valida antes de cravar. Nunca decidir pela pessoa.

## Fluxo

1. **Ler o estado**: `CRITICAL_FACTS.md` (prioridades) · o diário da semana corrente · a linha `**→ amanhã:**` do fechamento de ontem (candidata mais forte a #1 do dia) · o log `memory/` mais recente.
2. **Agenda**: se houver calendário conectado (MCP ou conector), puxar os eventos de hoje. Sem conexão, perguntar em 1 linha: "como tá tua agenda hoje? (reuniões e janelas livres)".
3. **Varrer o backlog**: `grep "^- \[ \]"` no `diario/` inteiro. Categorizar: **hoje** (prazo hoje ou resolve em reunião de hoje) · **atrasadas** · **esta semana** · **espera** (bloqueada por terceiro). Task atrasada de outro tema se lê junto com as novas: se uma nova invalida a velha, propor fechamento da velha, não re-execução.
4. **Propor as 3 do dia**, cada uma ancorada explícita ("{tarefa} (ancora prioridade 1)"). Regras:
   * A semente `**→ amanhã:**` de ontem é a candidata mais forte a #1.
   * Reunião não é "3 do dia" (acontece de qualquer jeito); as 3 são execução.
   * **Calibrar contra a agenda**: contar as horas realmente livres. Sobrando menos de 2h, propor 1 movimento + 1 monitor no máximo, e dizer isso na abertura. Três ambiciosas num dia sem janela garantem o fracasso por calibragem, não por execução.
5. **Gravar** no topo do diário da semana: `## 3 do dia , DD/MM` + as 3 numeradas e ancoradas. Mesmo dia roda de novo: sobrescreve o bloco. Dia novo: cria e deixa o anterior no histórico.
6. **Responder curto**: agenda em 1 bloco · as 3 propostas · 1 a 2 perguntas críticas se houver contradição detectada. Aguardar validação antes de cravar.

## Durante o dia (modo update)

"fiz X", "fechei Y", "surgiu Z": marcar no diário na hora (`- [x]` ou task nova), e reavaliar as 3 só se a pessoa pedir ou se uma delas ficou impossível (reunião nova engoliu a janela). Responder com o delta em 1 linha.

## Quando NÃO usar

Fim do dia ("como foi hoje") → `fechar-dia`. Pergunta pontual sobre um projeto → leitura direta do hub.
