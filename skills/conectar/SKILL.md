---
name: conectar
description: Mapeia o que esta sessão consegue buscar sozinha (agenda, e-mail, mensagens, documentos, transcrição de reunião, tickets, warehouse de dados, analytics de produto) e escreve isso no módulo `.claude/skills/_shared/capacidades.md` da pasta da pessoa, que as skills de rotina leem antes de perguntar. Use quando a pessoa rodar /pm-chief-of-staff:conectar, no bloco de ferramentas do setup, quando ela ganhar ou perder um conector, disser "por que você não puxa minha agenda?", "liga isso no meu calendário", ou depois de trocar de empresa. Não use pra instalar ou autenticar conector (é configuração do agente, fora do alcance desta skill), nem pra criar skill nova (criar-skill).
---

# Conectar as fontes

Skill de infraestrutura: roda no setup e de novo quando a caixa de ferramentas da pessoa muda. Não produz nota nem entra na rotina diária.

## A régua (é a razão de existir da camada)

**Skill cita capacidade, nunca nome de ferramenta.** O `abrir-dia` pede "a agenda do dia"; qual conector responde isso é problema do módulo. Trocar de provider (mudou de empresa, o calendário virou outro) é editar uma linha em `capacidades.md`, sem abrir skill nenhuma. Nome de tool copiado em 3 skills quebra em 3 lugares no dia em que ele muda, e as cópias já divergem antes, na primeira que alguém edita sem olhar as outras.

## Fluxo

1. **Olhar o que a sessão já tem.** Diga em linguagem de capacidade o que você consegue exercer agora com as ferramentas desta sessão ("consigo ler tua agenda", "consigo buscar arquivo no drive"). Onde não houver certeza, pergunte em vez de chutar: capacidade declarada sem existir faz a skill consumidora tentar, falhar e tropeçar no meio do fluxo.
2. **Perguntar o que falta, sem jargão, percorrendo a tabela inteira.** Onde ficam as reuniões dela, de onde vêm as transcrições, onde a conversa de trabalho acontece, onde vive o e-mail, onde ficam os documentos, onde estão as tarefas do time, e onde estão os dados (o número do negócio e o comportamento do usuário no produto). Ela responde com nome de produto, e a tradução pra conector é sua. Capacidade que nenhuma skill lê hoje entra preenchida do mesmo jeito: é o que a próxima skill dela vai ler em vez de perguntar tudo de novo.
3. **Escrever o módulo** em `.claude/skills/_shared/capacidades.md` da pasta dela, a partir do template em `${CLAUDE_PLUGIN_ROOT}/modulos/capacidades.md` (se a variável não resolver, localize a pasta do plugin `pm-chief-of-staff` no cache de plugins). Preencha só as linhas que a pessoa confirmou, sempre com `provider` e `como chamar` juntos, porque é `como chamar` que a skill consumidora executa e provider sozinho a faz tentar sem instrução; o resto fica com as duas células vazias. **Chamado pelo setup, no meio do discovery, este passo não escreve:** a conversa acontece, o resultado fica em `setup-notas.md`, e o arquivo (com os passos 4 e 5) fica pro plantio, porque o setup promete que ela revisa tudo antes de qualquer arquivo existir.
4. **Conferir os consumidores.** Abra cada skill declarada na linha "Carregado por" do módulo e veja se ela referencia `capacidades.md` no passo em que busca dado. Skill que não referencia não muda em nada com o módulo escrito: ela continua perguntando. É o caso de quem plantou as sementes antes desta camada existir, e o único jeito de saber é abrir e olhar. Ofereça a edição uma por uma e **nunca edite sem o ok**, porque skill plantada é arquivo dela.
5. **Fechar dizendo o que muda no dia seguinte:** quais skills passam a puxar dado sozinhas, quais continuam perguntando e quais estão esperando o ok do passo 4. Sem essa linha a pessoa espera automação que não chegou.

## Rodar de novo (o caso mais comum)

Se `capacidades.md` já existe: leia, mostre a tabela atual e pergunte o que mudou. Atualize linha por linha e **nunca reescreva do zero**, porque o arquivo é dela e pode ter sido editado à mão. Provider que saiu limpa as duas células, não uma; nunca deixe linha apontando pra ferramenta que não responde mais. Confira também se a seção "Regras de leitura de agenda" existe depois da tabela; faltando, ofereça acrescentá-la (o arquivo é dela: só com o ok). O passo 4 roda de novo junto.

## Limites (diga isso pra pessoa, não é detalhe)

* **Não há carga automática.** O módulo entra em contexto só quando uma skill manda ler, e é o passo 4 que verifica isso. Skill nova que busque dado de fora precisa apontar pra ele também.
* **Instalar e autenticar conector não é aqui.** Isso é configuração do agente (no Claude Code, `/mcp` e os conectores da conta). Esta skill mapeia o que existe e escreve o mapa.
* **O módulo é arquivo dela.** Atualização do plugin não toca nele, e melhoria futura no template não chega em quem já rodou: rodar esta skill de novo é o caminho.
* **Nenhum nome de ferramenta interna de empresa entra no módulo como default.** Preencha com o que a pessoa usa, e só.
* **Conector ligado agora só passa a existir na próxima sessão.** A lista de ferramentas carrega na abertura; ao detectar que a pessoa acabou de ligar algo, diga isso e combine re-rodar o conectar na sessão seguinte.
* **Ausência de capacidade se afirma só depois de medir.** Antes de dizer que um conector não está na sessão, liste as ferramentas presentes e prove com uma chamada de leitura barata; afirmar sem medir já produziu erro real, com a lista carregada e a chamada de prova desfazendo a afirmação.
