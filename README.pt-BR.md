# pm-chief-of-staff

[Read in English](README.md)

**Um Chief of Staff pessoal pra quem trabalha com produto.** Você abre o Claude Code ou o Codex numa pasta vazia, pede o setup, e ele te entrevista: quem você é, o que você toca, quem trabalha contigo, onde doem as coisas. Das respostas nasce o seu sistema: estrutura de pastas, memória em camadas, skills de rotina, e um agente que processa suas reuniões, prepara suas conversas difíceis, guarda o contexto de tudo e te confronta quando você está se enganando.

Não tem template pronto aqui. **O sistema nasce do seu discovery e se molda a você no uso.** O que funciona pra outra pessoa não necessariamente funciona pra você, e o plugin foi desenhado em cima dessa premissa.

> Vem do sistema que eu uso todo dia como pessoa de produto, em produção há meses, e que outras pessoas do meu círculo adotaram e adaptaram ao jeito delas. Esta é a versão destilada pra qualquer pessoa de produto: PM, GPM, head, APM, quem lidera gente e quem não lidera (o discovery pergunta e o sistema se ajusta).

## O que você precisa antes

1. **Um dos dois agentes, rodando no seu computador:** o **[Claude Code](https://claude.com/claude-code)**, da Anthropic (Mac ou Windows), ou o **Codex**, da OpenAI, no app desktop ou no CLI.
2. **A conta do agente escolhido:** assinatura do Claude (Pro ou superior) pro Claude Code, ou uma conta com acesso ao Codex, nos termos do plano dela. O plugin em si é gratuito.
3. Mais nada. Não precisa saber programar, não precisa de Obsidian nem Notion (o sistema é uma pasta de arquivos markdown que qualquer editor abre; se você usa Obsidian, ele funciona bem por cima). Se você nunca usou um terminal, cole esta página no próprio Claude e peça ajuda.

## Instalação no Claude Code (3 passos, ~5 minutos)

**1.** Crie uma pasta nova (Documentos ou Desktop, nome que quiser: `meu-cos`, `segundo-cerebro`). Abra o Claude Code dentro dela.

**2.** Instale o plugin, colando os três comandos (o terceiro carrega o plugin na sessão aberta; sem ele, o comando do passo 3 aparece como "Unknown command"):

```
/plugin marketplace add pe-menezes/pm-chief-of-staff
/plugin install pm-chief-of-staff@pm-chief-of-staff
/reload-plugins
```

**3.** Rode o setup em português e vá respondendo:

```
/pm-chief-of-staff:setup em português
```

A conversa e os arquivos seguem o seu idioma, e qualquer idioma serve. As palavras depois do comando fixam o idioma desde o começo; o comando puro abre em inglês e avisa que você pode responder em qualquer idioma, e a sua primeira resposta fixa o idioma.

São 7 blocos de perguntas, uns 20 a 30 minutos de conversa. No fim ele propõe a estrutura e o AGENTS.md (o "manual de instruções" que ele mesmo vai seguir), com os nomes das pastas no seu idioma, **você revisa tudo antes de qualquer arquivo ser criado**, e ele planta as skills iniciais na sua pasta. Nessa última parte o Claude pode pedir sua permissão (quantas vezes depende do que você já liberou antes) pra três coisas: ler as skills que vêm com o plugin, criar os arquivos delas na sua pasta e rodar a ponte que deixa a pasta pronta pro Codex (adiante). Aceite os pedidos de leitura e de criação, porque sem eles os comandos não passam a existir; o da ponte só importa se você for abrir a pasta no Codex também. Não comece 15 minutos antes de uma reunião: o discovery é a parte que define a qualidade do resto.

## Instalação no Codex (app desktop ou CLI)

**1.** No terminal, cadastre o marketplace e instale o plugin:

```
codex plugin marketplace add pe-menezes/pm-chief-of-staff
codex plugin add pm-chief-of-staff@pm-chief-of-staff
```

No Codex o comando é `plugin add` (`plugin install` é a forma do Claude Code). O plugin não está publicado no diretório de plugins da OpenAI: a instalação é por este repositório.

**2.** Crie a pasta nova e abra uma **sessão nova** do Codex dentro dela. Sessão que já estava aberta antes da instalação não enxerga o plugin.

**3.** Peça o setup em linguagem natural, por exemplo "roda o setup do pm-chief-of-staff" ou "monta meu chief of staff". O idioma em que você pede vira o idioma da conversa e dos arquivos. O discovery, a proposta e a revisão são os mesmos do Claude Code: nada é criado antes do seu ok.

O plugin também traz um hook de abertura (a carga de memória, adiante). **Instalar o pacote não autoriza o hook.** O Codex pede sua confiança pra ele pelo mecanismo normal de aprovação de hooks; enquanto você não aprovar, a sessão abre sem a carga automática e o `AGENTS.md` continua mandando ler os mesmos arquivos. Nenhum passo da instalação desliga aprovação ou sandbox.

No plantio, o setup roda a ponte do Codex na sua pasta (próxima seção). Sandbox que não deixa criar `.agents/` bloqueia esse passo, e o agente para e avisa, sem contornar. Nesse caso, peça a ele o comando da ponte com o caminho resolvido, leia, e escolha: autorizar a execução pelo pedido de aprovação normal do Codex, ou rodar o comando você mesmo, no seu terminal, de dentro da pasta. Sem a ponte, a pasta funciona, mas as skills plantadas não aparecem no Codex.

## O que vem plantado (e por que "plantado" importa)

Plantar é copiar uma skill-semente (a starter que vem no plugin) pra DENTRO da sua pasta, e o setup começa plantando 5:

| Skill | O que faz |
|---|---|
| `start-day` | agenda + backlog + as 3 do dia ancoradas nas suas prioridades |
| `close-day` | avalia as 3, classifica o que não fechou, semeia o #1 de amanhã |
| `prep-conversation` | pauta pra 1:1 (liderado ou seu líder), par ou stakeholder, a partir do que está escrito |
| `process-meeting` | cola a transcrição, sai nota estruturada + propagação pros lugares certos |
| `absorb` | joga um doc, artigo ou processo pra dentro: ganha casa, resumo com proveniência e a linha de quando será usado |

A partir do momento em que são plantadas, **essas skills são arquivos seus**. Quer que a pauta de 1:1 sempre tenha uma seção de reconhecimento? Fala isso pro agente e ele edita a skill. Quer que o start-day inclua seu dashboard? Mesma coisa. Minhas atualizações futuras **nunca tocam no que é seu**: elas melhoram o setup e as skills do plugin e adicionam sementes novas no catálogo (`/pm-chief-of-staff:plant` lista o que há).

No catálogo, além das plantadas: **`close-week`**, que agrega os balanços diários, força as decisões da semana, mede a saúde da memória do sistema (os arquivos que toda sessão carrega, contra os alvos de tamanho), guarda sinal de trajetória (o material da sua avaliação de ciclo) e monta o diário da próxima. Plante no fim da sua primeira semana: `/pm-chief-of-staff:plant close-week`.

Também no plugin: **`/pm-chief-of-staff:connect`**, que mapeia num arquivo único o que o agente consegue puxar sozinho (agenda, transcrição, mensagens, tickets), e com isso as skills de rotina param de perguntar o que ele já sabe buscar; o setup roda ele. Se você já tinha as skills plantadas antes dessa camada, o `connect` confere quais delas ainda perguntam e oferece a edição de cada uma.

**`/pm-chief-of-staff:remove-ai-tells`** revisa um texto que você vai mandar. Um agente revisor, que não escreveu o texto, aponta os tells de escrita gerada por IA (antítese em série, frase de efeito, travessão). Você vê o antes e depois de cada trecho. O original só recebe os trechos que você aprovar.

Os comandos com o prefixo `/pm-chief-of-staff:` são a forma do Claude Code. No Codex, peça pelo nome em linguagem natural ("planta o fechar-semana", "tira os tells deste texto").

## A mesma pasta no Claude e no Codex

A pasta montada abre nos dois agentes, sem segunda cópia de nada:

* **Uma fonte só pras suas skills.** Elas moram em `.claude/skills/`, e é lá que toda edição acontece. O Codex procura skills em `.agents/skills/`, então a ponte (`modules/codex-bridge.sh`, rodada pelo setup, pelo plant e pelo create-skill) cria ali um link relativo pra `.claude/skills/`. Onde link não é possível, ela escreve por skill um `SKILL.md` curto que manda ler a fonte. Edição feita na fonte aparece na sessão seguinte do Codex.
* **A ponte não passa por cima do que é seu.** Se você já tinha uma pasta `.agents/skills`, ela continua sendo usada: a ponte só acrescenta ali as entradas que faltam, uma por skill. Uma entrada de mesmo nome que não foi a ponte que criou (arquivo, link ou skill sua) fica como está e sai na lista de conflitos, pra você decidir com o agente. Se `.agents/skills` já for um link seu ou um arquivo, a ponte não escreve nada ali e também relata conflito. Ela só reescreve os arquivos curtos que ela mesma gerou, então rodar de novo é seguro.
* **Regras situacionais chegam pelo índice.** O Codex não lê o `paths:` das regras de `.claude/rules/`. O `AGENTS.md` gerado tem a seção do índice de regras (`## Regras por assunto` numa pasta em português, `## Rules by topic` numa pasta em inglês), uma linha por regra com o assunto e o caminho, e manda ler a regra antes de atuar no assunto. Regra nova entra no índice no mesmo passo; regra fora dele vale só no Claude Code.
* **O revisor de tells continua independente.** No Claude Code é o agente nomeado do plugin. No Codex, o `remove-ai-tells` abre um subagente novo, sem o histórico da conversa e com ordem de só ler. Se a sessão não tiver subagente, ele avisa: nenhum revisor separado leu o texto.

Limites conhecidos: a ponte depende de a sessão poder escrever `.agents/` na pasta (o caminho quando a sandbox nega está na instalação do Codex, acima). No Windows sem permissão de link simbólico, a ponte cai nos arquivos curtos por skill; esse caminho foi provado por teste, e nenhuma máquina Windows rodou ele ainda.

## A memória (a parte que faz valer a pena)

A memória do agente são os arquivos: o que está escrito na pasta, qualquer sessão futura carrega. O sistema nasce com 4 camadas, todas em markdown legível:

* **`CRITICAL_FACTS.md`**: o estado vivo (suas prioridades com número, eventos ativos). Lido no começo de toda sessão, existe pra ele nunca te perguntar de novo o que já foi decidido.
* **`memory/`**: o log diário, datado e imutável. O que aconteceu, quando, com ponteiro pra onde está o detalhe.
* **Hubs de pessoas e projetos**: o que estabilizou. Sinais recentes, histórico, contexto.
* **`AGENTS.md` e as skills**: como ele opera com você, e a camada que se auto-modula.

O manual mora no `AGENTS.md`, que Claude Code, Codex e Cursor leem. Ao lado dele fica um `CLAUDE.md` com uma linha só, `@AGENTS.md`, a ponte que faz o Claude Code carregar o manual: não apague esse arquivo e não escreva regra nele. Pasta montada antes da 0.6 segue com o manual no `CLAUDE.md` e funciona igual no Claude Code, sem migrar nada; o Codex lê o `AGENTS.md` e pula o `CLAUDE.md`, então essa pasta abre nele sem o manual. No Codex, as skills plantadas chegam pela ponte e as regras pelo índice do `AGENTS.md` (seção anterior).

O ciclo diário fecha sozinho: `start-day` lê o que o `close-day` de ontem semeou; o `close-day` promove o que ficou solto no log pros hubs. Em duas semanas de uso, o agente conhece seu time, seus projetos e seus padrões.

Se a engine externa `memoria-agente` estiver configurada na mesma pasta, os dois compõem: este plugin dá a estrutura e os rituais, a engine dá o enforcement mecânico e assume a injeção de abertura no Claude Code (o hook detecta e cede a vez). No Codex, o hook do plugin faz a carga sempre: a telemetria que a engine deixa na pasta não comprova que ela está rodando nesta sessão do Codex, então o registro do Codex não cede a vez por essa evidência.

## Onde ficam meus dados?

**No seu computador, e só nele.** O sistema inteiro é uma pasta de markdown que você abre, lê, versiona e apaga quando quiser. Nada é enviado pra mim, e o plugin não instala servidor, conector nem integração MCP. Ele tem dois scripts curtos, os dois locais, e dá pra ler cada um inteiro em 2 minutos:

* **`hooks/boot-memory.sh`, leitura na abertura da sessão.** Lê três arquivos da sua própria pasta (o estado, o índice e o log do dia) e joga o conteúdo pra dentro da conversa, pra você já começar com o agente sabendo onde as coisas estão. Não escreve nada e não manda nada pra lugar nenhum. No Codex, só roda depois que você confiar no hook.
* **`modules/codex-bridge.sh`, escrita local no plantio.** Roda quando o setup, o plant ou o create-skill pedem, com sua permissão, e escreve só dentro de `.agents/` da sua pasta (o link ou os arquivos curtos que apontam pras suas skills). Não apaga, não renomeia e não substitui arquivo seu.

A conversa em si segue as regras da conta do agente que você usa: a Anthropic, no Claude Code; a OpenAI, no Codex.

Um cuidado que é seu: transcrição de reunião e 1:1 carrega dado sensível de outras pessoas. Antes de colar material da empresa, cheque a política de IA dela (os planos Team e Enterprise do Claude têm controles próprios de dados).

## Atualizações

* **Automático (recomendado):** uma vez só, rode `/plugin`, aba **Marketplaces**, selecione `pm-chief-of-staff` e ative **Enable auto-update**. Versões novas chegam sozinhas com aviso.
* **Manual:** `/plugin marketplace update pm-chief-of-staff` quando quiser checar.
* **No Codex:** `codex plugin marketplace upgrade pm-chief-of-staff` no terminal, e depois uma sessão nova.

Atualização troca o plugin (setup, skills do plugin e catálogo de sementes). **Seus arquivos, suas skills plantadas e seu `AGENTS.md` ou `CLAUDE.md` nunca são tocados.**

## Atualizando da 0.7

Na 0.8.0 o plugin é escrito em inglês, e os comandos e as sementes ganharam nomes em inglês:

| 0.7 | 0.8 |
|---|---|
| `setup` | `setup` |
| `plantar` | `plant` |
| `criar-skill` | `create-skill` |
| `conectar` | `connect` |
| `remove-ai-tells` | `remove-ai-tells` |
| `abrir-dia` | `start-day` |
| `fechar-dia` | `close-day` |
| `fechar-semana` | `close-week` |
| `preparar-conversa` | `prep-conversation` |
| `processar-reuniao` | `process-meeting` |
| `absorver` | `absorb` |

As cinco primeiras linhas são comandos do plugin (`/pm-chief-of-staff:<nome>` no Claude Code); as outras seis são sementes.

* **Nada na sua pasta é renomeado.** Pastas, arquivos, rótulos e módulos ficam com os nomes que têm, e o plugin lê do jeito que estão.
* **Sementes plantadas seguem com os nomes delas e continuam sendo comandos.** Uma semente plantada como `abrir-dia` continua `abrir-dia` e segue respondendo como comando e às frases de gatilho dela.
* **Os comandos antigos do plugin não existem mais.** Digitar `plantar`, `criar-skill` ou `conectar` depois do prefixo do plugin não funciona mais; o nome novo, ou o mesmo pedido em linguagem natural ("planta o fechar-semana"), faz a mesma coisa.
* **No Codex**, se a sessão abrir sem a carga de memória depois da atualização, aprove o hook de novo pelo mecanismo de hooks do Codex.

## Problemas comuns

* **`/pm-chief-of-staff:setup` aparece como "Unknown command":** rode `/reload-plugins` (o passo 2 da instalação termina nele) ou feche e abra a sessão.
* **O discovery caiu no meio (sessão fechou, contexto acabou):** abra a pasta de novo e rode o setup; ele encontra o `setup-notes.md` que foi gravando (`setup-notas.md` numa pasta da 0.7) e retoma do bloco onde parou.
* **Plantei uma skill e o comando (`/start-day`) não aparece:** skill plantada registra quando a sessão abre. Numa sessão nova ela está lá, e o gatilho por frase ("bom dia") funciona igual.
* **Conectei minha agenda (ou e-mail) e o agente não vê:** conector ligado com a sessão aberta só aparece na sessão seguinte. Feche e abra a sessão. Se você não usa conectores, ignore este item: tudo funciona colando o material.
* **No Codex, as skills plantadas não aparecem:** a ponte não rodou ou achou conflito. Confira se existe `.agents/skills` na pasta; se não existir, peça ao agente pra rodar a ponte do plugin de novo (o plant também roda) ou siga o caminho de sandbox da instalação do Codex. Se a ponte listou conflito, ela deixou o que era seu intacto: decida com o agente o que fazer com cada linha.
* **No Codex, a sessão abre sem a carga de memória:** o hook ainda não tem sua confiança. Aprove pelo mecanismo de hooks do Codex; até lá, o agente lê os arquivos pela rotina do `AGENTS.md`.

## Não quer instalar o plugin?

Cola o conteúdo de [`PROMPT.pt-BR.md`](PROMPT.pt-BR.md) em qualquer agente com acesso a arquivos (Claude Code e Codex incluídos) e roda o mesmo setup por conversa, em português. A pasta sai com `AGENTS.md`, a ponte `CLAUDE.md`, o índice de regras e as skills numa fonte só, com a descoberta do Codex criada sem passar por cima do que já existe. O plugin acrescenta as skills-semente, as skills `connect`, `create-skill` e `remove-ai-tells`, o hook de abertura, a ponte em script e o canal de atualização.

## Filosofia, em 4 princípios

1. **O sistema se auto-modula.** Pedido de mudança vira edição no AGENTS.md ou na skill, na hora, e o sistema se molda ao seu jeito de pensar.
2. **Você tem que ler tudo.** Erro que você não pega propaga. Sua responsabilidade é intransferível.
3. **Ele é thought partner, não assistente obediente.** Franqueza acima de validação, diagnóstico antes de sugestão, e anti-padrões nomeados na hora (executar sem questionar, escalar sem recomendação, showcase sem "e daí", otimismo ingênuo, e os de liderança pra quem lidera: Super-Líder, babá de luxo, feedback genérico, decisão dura adiada).
4. **Os arquivos são a memória.** O que não está escrito não existe amanhã.

## Bug ou semente que falta

[Abra uma issue](../../issues/new/choose): tem template pra bug e pra pedido de semente. Pedido de semente é o que vira catálogo novo, e a fila é pública.

## Licença

MIT. Use, adapte, distribua.
