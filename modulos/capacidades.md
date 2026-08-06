**Carregado por:** `abrir-dia`, `processar-reuniao`, `preparar-conversa`. Skill nova que busca dado de fora se acrescenta nesta linha, porque módulo sem consumidor declarado nunca dispara e ninguém percebe.

# Capacidades conectadas

Régua: **skill cita capacidade, nunca nome de ferramenta.** Trocar de provider é editar uma linha daqui, sem abrir skill nenhuma. A tabela é o mapa do que a pessoa alcança, não a lista do que as skills de hoje consomem: capacidade sem consumidor entra preenchida do mesmo jeito, porque é o que a próxima skill que ela criar vai ler em vez de perguntar de novo quais ferramentas ela usa.

| capacidade | provider | como chamar | sem conector |
|---|---|---|---|
| agenda do dia | | | perguntar em 1 linha como está a agenda de hoje |
| e-mail | | | pedir pra colar o que importa |
| mensagens | | | pedir o que importou nas conversas |
| documentos | | | pedir o link ou o texto |
| transcrição de reunião | | | pedir pra colar a transcrição ou o resumo |
| tickets | | | perguntar o estado das tarefas do time |
| warehouse de dados | | | pedir o número já apurado e a fonte dele |
| analytics de produto | | | pedir o número ou o print do funil |

Nome de capacidade é agnóstico ao software: o produto vive só na coluna `provider`. Formato de linha preenchida (exemplo genérico, não default): `agenda do dia | Google Calendar | conector de calendário da sessão, eventos de hoje | perguntar em 1 linha`.

Lido hoje por alguma skill: `agenda do dia` (abrir-dia), `transcrição de reunião` (processar-reuniao), `mensagens` e `tickets` (preparar-conversa). As outras esperam a skill que vai ler. A linha "Carregado por" do topo é outra coisa: lista as skills que leem este arquivo, não as capacidades preenchidas.

Provider vazio não é problema: a skill segue pela coluna "sem conector", que é o comportamento de sempre. Linha errada ou pela metade custa mais (provider que saiu, ferramenta que mudou de nome, `como chamar` em branco): a skill tenta, falha e volta pra essa coluna com um tropeço no meio. Ferramenta nova ou perdida: rode `/pm-chief-of-staff:conectar` de novo, que atualiza a tabela e reconfere os consumidores do topo.
