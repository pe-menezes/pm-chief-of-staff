**Carregado por:** `processar-reuniao`, `fechar-dia`, `fechar-semana`, `absorver`. Skill nova que escreve fato em destino compartilhado se acrescenta nesta linha, porque módulo sem consumidor declarado nunca dispara e ninguém percebe.

# Gate de escrita

Régua: **todo fato que vai pra destino compartilhado (hub em `pessoas/` ou `projetos/`, diário em `diario/`, `CRITICAL_FACTS.md`) passa por 1 das 4 decisões antes da escrita.** Salvar tudo que foi extraído é a causa raiz do inchaço; a decisão acontece na escrita, porque a faxina futura herda o que ninguém decidiu.

A decisão sai de leitura: leia ou grepe o trecho do destino onde o fato entraria antes de classificar. Impressão de semelhança sem leitura classifica errado.

| decisão | critério | ação |
|---|---|---|
| ADD | o fato não existe no destino | escrever com data |
| UPDATE | o fato existe e mudou (número, estado, prazo) | editar a linha existente |
| SUPERSEDE | o novo invalida o antigo, que tem valor histórico | marcar o antigo com "superado em DD/MM por {o que o superou}" e escrever o novo |
| NOOP | o fato já está lá | nada é escrito, e registrar nada é a decisão correta |

A marca de SUPERSEDE é a que a seção "Leitura" dos hubs de `pessoas/` e `projetos/` já usa: um formato só, grepável pros dois usos. Atalho: destino vazio ou recém-criado é ADD direto, sem leitura prévia.
