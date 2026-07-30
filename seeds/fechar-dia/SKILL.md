---
name: fechar-dia
description: Fecha o dia de trabalho. Avalia as 3 do dia, classifica o que não fechou, semeia o movimento #1 de amanhã e promove o que ficou no log pros hubs. Use quando a pessoa disser "fechei o dia", "fecha o dia", "review do dia", "como foi hoje", "/fechar-dia". NÃO use pra abrir o dia (abrir-dia) nem pra update de meio de dia.
---

# Fechar o dia

> Semente do pm-chief-of-staff. Este arquivo é SEU: peça pro agente mudar qualquer passo e ele edita esta skill na hora.

Par do `abrir-dia`: a abertura propõe as 3, este fechamento avalia (fecharam? por que não? o que fazer amanhã?) e grava a resposta onde a abertura lê de manhã. Sem fechamento, as 3 são propostas nunca avaliadas e o sistema não aprende se erra na priorização ou na execução. Leva 5 minutos. Um dia 0/3 é dado, não falha moral.

## Fluxo

1. **Compilar o dia (pull, não interrogatório).** Puxar do que já tem rastro: a conversa de hoje, o diff do que foi escrito na pasta (diário, hubs, notas), a agenda. Entregar "teu dia" em 5 a 8 linhas agrupadas por prioridade. A pessoa só acrescenta o que não deixa rastro (presencial, verbal, o que pensou). Pedir relato do que dá pra levantar sozinho é devolver trabalho.
2. **Avaliar as 3.** Ler o bloco `## 3 do dia , DD/MM` do diário e propor o status de cada uma como hipótese (feita / não feita / parcial); a pessoa crava. Marcar inline no diário.
3. **Refletir (a parte que só é dela).** Duas perguntas: o que rolou de importante que não deixou rastro? · o que aprendeu ou faria diferente? Relato relevante vira linha `**Reflexão:**` no bloco do dia; aprendizado sobre ela mesma vai pro `memory/{hoje}.md`. Reflexão que repete padrão já visto (mesmo gap reaparecendo) se nomeia, com franqueza.
4. **Classificar o que não fechou.** Cada não-feita recebe um de três motivos: **faltou tempo** (task certa, dia não coube) · **ataque externo** (o não-planejado tomou o dia; era inevitável?) · **a 3 errada** (erro de priorização, não de execução). A classificação é o valor da skill: o mesmo motivo 3 dias seguidos aponta o que ajustar.
5. **Semear amanhã.** No fim do bloco do dia:
   ```
   **Balanço:** {N}/3 , {1 frase com o motivo do que não fechou}
   **→ amanhã:** {movimento #1, ancorado nas prioridades; carry-over só do que segue de pé}
   ```
   Não-feita que não bate mais com as prioridades reescopa ou descarta, nunca vira carry-over por inércia.
6. **Promover o que ficou no log.** Ler `memory/{hoje}.md` e separar SÓ o que não tem destino além do log: sinal de pessoa ou projeto que nenhuma nota propagou, mudança de prioridade que o `CRITICAL_FACTS.md` não reflete. **Cap de 3 itens** (passou, leva os 3 mais caros de perder e declara o resto). Confirmar com a pessoa em 1 pergunta: promover pra onde? Antes de perguntar, checar se o item já chegou ao destino durante o dia (aí não vira pergunta).
7. **Responder curto:** compilado + balanço (`N/3` + motivo) + semente de amanhã. Sem cheerleading.

## O loop

`abrir-dia` (lê `**→ amanhã:**`, propõe as 3) → dia (updates marcam progresso) → `fechar-dia` (compila, avalia, classifica, semeia) → `abrir-dia` de amanhã. Manter os rótulos `**Balanço:**` e `**→ amanhã:**` estáveis: é o contrato que a abertura lê.

## Quando NÃO usar

De manhã → `abrir-dia`. Meio do dia ("fiz X") → update direto no diário.
