# pm-chief-of-staff

**Um Chief of Staff pessoal pra quem trabalha com produto.** Você abre o Claude Code ou o Codex numa pasta vazia, pede o setup, e ele te entrevista: quem você é, o que você toca, quem trabalha contigo, onde doem as coisas. Das respostas nasce o seu sistema: estrutura de pastas, memória em camadas, skills de rotina, e um agente que processa suas reuniões, prepara suas conversas difíceis, guarda o contexto de tudo e te confronta quando você está se enganando.

Não é um template pronto. **O sistema nasce do seu discovery e se molda a você no uso.** O que funciona pra outra pessoa não necessariamente funciona pra você, e o plugin foi desenhado em cima dessa premissa.

> Vem do sistema que eu uso todo dia como pessoa de produto, em produção há meses, e que outras pessoas do meu círculo adotaram e adaptaram ao jeito delas. Esta é a versão destilada pra qualquer pessoa de produto: PM, GPM, head, APM, quem lidera gente e quem não lidera (o discovery pergunta e o sistema se ajusta).

## O que você precisa antes

1. **Um dos dois agentes, rodando no seu computador:** o **[Claude Code](https://claude.com/claude-code)**, da Anthropic (Mac ou Windows), ou o **Codex**, da OpenAI, no app desktop ou no CLI.
2. **A conta do agente escolhido:** assinatura do Claude (Pro ou superior) pro Claude Code, ou uma conta com acesso ao Codex. É a única coisa paga.
3. Mais nada. Não precisa saber programar, não precisa de Obsidian nem Notion (o sistema é uma pasta de arquivos markdown que qualquer editor abre; se você usa Obsidian, ele funciona bem por cima). Se você nunca usou um terminal, cole este README no próprio Claude e peça ajuda.

## Instalação no Claude Code (3 passos, ~5 minutos)

**1.** Crie uma pasta nova (Documentos ou Desktop, nome que quiser: `meu-cos`, `segundo-cerebro`). Abra o Claude Code dentro dela.

**2.** Instale o plugin, colando os três comandos (o terceiro carrega o plugin na sessão aberta; sem ele, o comando do passo 3 aparece como "Unknown command"):

```
/plugin marketplace add pe-menezes/pm-chief-of-staff
/plugin install pm-chief-of-staff@pm-chief-of-staff
/reload-plugins
```

**3.** Rode o setup e vá respondendo:

```
/pm-chief-of-staff:setup
```

São 7 blocos de perguntas, uns 20 a 30 minutos de conversa. No fim ele propõe a estrutura e o AGENTS.md (o "manual de instruções" que ele mesmo vai seguir), **você revisa tudo antes de qualquer arquivo ser criado**, e ele planta as skills iniciais na sua pasta. Nessa última parte o Claude pede sua permissão três vezes: uma pra ler as skills que vêm com o plugin, outra pra criar os arquivos delas na sua pasta e a última pra rodar a ponte que deixa a pasta pronta pro Codex (adiante). Aceite as duas primeiras, porque sem elas os comandos não passam a existir; a terceira só importa se você for abrir a pasta no Codex também. Não comece 15 minutos antes de uma reunião: o discovery é a parte que define a qualidade do resto.

## Instalação no Codex (app desktop ou CLI)

**1.** No terminal, cadastre o marketplace e instale o plugin:

```
codex plugin marketplace add pe-menezes/pm-chief-of-staff
codex plugin add pm-chief-of-staff@pm-chief-of-staff
```

No Codex o comando é `plugin add`, não `plugin install`. O plugin não está publicado no diretório de plugins da OpenAI: a instalação é por este repositório.

**2.** Crie a pasta nova e abra uma **sessão nova** do Codex dentro dela. Sessão que já estava aberta antes da instalação não enxerga o plugin.

**3.** Peça o setup em linguagem natural, por exemplo "roda o setup do pm-chief-of-staff" ou "monta meu chief of staff". O discovery, a proposta e a revisão são os mesmos do Claude Code: nada é criado antes do seu ok.

O plugin também traz um hook de abertura (a carga de memória, adiante). **Instalar o pacote não autoriza o hook.** O Codex pede sua confiança pra ele pelo mecanismo normal de aprovação de hooks; enquanto você não aprovar, a sessão abre sem a carga automática e o `AGENTS.md` continua mandando ler os mesmos arquivos. Nenhum passo deste README desliga aprovação ou sandbox.

No plantio, o setup roda a ponte do Codex na sua pasta (próxima seção). Sandbox que não deixa criar `.agents/` bloqueia esse passo, e o agente avisa em vez de contornar. Nesse caso, peça a ele o comando da ponte com o caminho resolvido, leia, e escolha: autorizar a execução pelo pedido de aprovação normal do Codex, ou rodar o comando você mesmo, no seu terminal, de dentro da pasta. Sem a ponte, a pasta funciona, mas as skills plantadas não aparecem no Codex.

## O que vem plantado (e por que "plantado" importa)

Plantar é copiar uma skill-semente (a starter que vem no plugin) pra DENTRO da sua pasta, e o setup começa plantando 5:

| Skill | O que faz |
|---|---|
| `abrir-dia` | agenda + backlog + as 3 do dia ancoradas nas suas prioridades |
| `fechar-dia` | avalia as 3, classifica o que não fechou, semeia o #1 de amanhã |
| `preparar-conversa` | pauta pra 1:1 (liderado ou seu líder), par ou stakeholder, a partir do que está escrito |
| `processar-reuniao` | cola a transcrição, sai nota estruturada + propagação pros lugares certos |
| `absorver` | joga um doc, artigo ou processo pra dentro: ganha casa, resumo com proveniência e a linha de quando será usado |

A partir do momento em que são plantadas, **essas skills são arquivos seus**. Quer que a pauta de 1:1 sempre tenha uma seção de reconhecimento? Fala isso pro agente e ele edita a skill. Quer que o abrir-dia inclua seu dashboard? Mesma coisa. Minhas atualizações futuras **nunca tocam no que é seu**: elas melhoram o setup e as skills do plugin e adicionam sementes novas no catálogo (`/pm-chief-of-staff:plantar` lista o que há).

No catálogo, além das plantadas: **`fechar-semana`**, que agrega os balanços diários, força as decisões da semana, mede a saúde da memória do sistema (os arquivos que toda sessão carrega, contra os alvos de tamanho), guarda sinal de trajetória (o material da sua avaliação de ciclo) e monta o diário da próxima. Plante no fim da sua primeira semana: `/pm-chief-of-staff:plantar fechar-semana`.

Também no plugin: **`/pm-chief-of-staff:conectar`**, que mapeia num arquivo único o que o agente consegue puxar sozinho (agenda, transcrição, mensagens, tickets), e com isso as skills de rotina param de perguntar o que ele já sabe buscar; o setup roda ele. Se você já tinha as skills plantadas antes dessa camada, o `conectar` confere quais delas ainda perguntam e oferece a edição de cada uma.

**`/pm-chief-of-staff:remove-ai-tells`** revisa um texto que você vai mandar. Um agente revisor, que não escreveu o texto, aponta os tells de escrita gerada por IA (antítese em série, frase de efeito, travessão). Você vê o antes e depois de cada trecho. O original só recebe os trechos que você aprovar.

Os comandos com `/pm-chief-of-staff:` são a forma do Claude Code. No Codex, peça pelo nome em linguagem natural ("planta o fechar-semana", "tira os tells deste texto").

## A mesma pasta no Claude e no Codex

A pasta montada abre nos dois agentes, sem segunda cópia de nada:

* **Uma fonte só pras suas skills.** Elas moram em `.claude/skills/`, e é lá que toda edição acontece. O Codex procura skills em `.agents/skills/`, então a ponte (`modulos/ponte-codex.sh`, rodada pelo setup, pelo plantar e pelo criar-skill) cria ali um link relativo pra `.claude/skills/`. Onde link não é possível, ela escreve por skill um `SKILL.md` curto que manda ler a fonte. Edição feita na fonte aparece na sessão seguinte do Codex.
* **A ponte não passa por cima do que é seu.** Um `.agents/skills` que você já tinha, um link seu ou uma skill de mesmo nome ficam intactos e saem como conflito, pra você decidir com o agente. Ela só reescreve os arquivos curtos que ela mesma gerou. Rodar de novo é seguro.
* **Regras situacionais chegam pelo índice.** O Codex não lê o `paths:` das regras de `.claude/rules/`. O `AGENTS.md` gerado tem a seção `## Regras por assunto`, uma linha por regra com o assunto e o caminho, e manda ler a regra antes de atuar no assunto. Regra nova entra no índice no mesmo passo; regra fora dele vale só no Claude Code.
* **O revisor de tells continua independente.** No Claude Code é o agente nomeado do plugin. No Codex, o `remove-ai-tells` abre um subagente novo, sem o histórico da conversa e com ordem de só ler. Se a sessão não tiver subagente, ele avisa que nenhum revisor separado leu o texto, em vez de fingir a leitura.

Limites conhecidos: a ponte depende de a sessão poder escrever `.agents/` na pasta (o caminho quando a sandbox nega está na instalação do Codex, acima). No Windows sem permissão de link simbólico, a ponte cai nos arquivos curtos por skill; esse caminho foi provado por teste, não numa máquina Windows.

## A memória (a parte que faz valer a pena)

A memória do agente são os arquivos: o que está escrito na pasta, qualquer sessão futura carrega. O sistema nasce com 4 camadas, todas em markdown legível:

* **`CRITICAL_FACTS.md`**: o estado vivo (suas prioridades com número, eventos ativos). Lido no começo de toda sessão, existe pra ele nunca te perguntar de novo o que já foi decidido.
* **`memory/`**: o log diário, datado e imutável. O que aconteceu, quando, com ponteiro pra onde está o detalhe.
* **Hubs de pessoas e projetos**: o que estabilizou. Sinais recentes, histórico, contexto.
* **`AGENTS.md` e as skills**: como ele opera com você. É o que se auto-modula.

O manual mora no `AGENTS.md`, que Claude Code, Codex e Cursor leem. Ao lado dele fica um `CLAUDE.md` com uma linha só, `@AGENTS.md`, a ponte que faz o Claude Code carregar o manual: não apague esse arquivo e não escreva regra nele. Pasta montada antes da 0.6 segue com o manual no `CLAUDE.md` e funciona igual no Claude Code, sem migrar nada; o Codex lê o `AGENTS.md`, não o `CLAUDE.md`, então essa pasta abre nele sem o manual. No Codex, as skills plantadas chegam pela ponte e as regras pelo índice do `AGENTS.md` (seção anterior).

O ciclo diário fecha sozinho: `abrir-dia` lê o que o `fechar-dia` de ontem semeou; o `fechar-dia` promove o que ficou solto no log pros hubs. Em duas semanas de uso, o agente conhece seu time, seus projetos e seus padrões.

Se a engine externa `memoria-agente` estiver configurada na mesma pasta, os dois compõem: este plugin dá a estrutura e os rituais, a engine dá o enforcement mecânico e assume a injeção de abertura no Claude Code (o hook detecta e cede a vez). A engine roda só no Claude, então no Codex o hook do plugin faz a carga sempre.

## Onde ficam meus dados?

**No seu computador, e só nele.** O sistema inteiro é uma pasta de markdown que você abre, lê, versiona e apaga quando quiser. Nada é enviado pra mim, e o plugin não instala servidor, conector nem integração MCP. Ele tem dois scripts curtos, os dois locais, e dá pra ler cada um inteiro em 2 minutos:

* **`hooks/boot-memoria.sh`, leitura na abertura da sessão.** Lê três arquivos da sua própria pasta (o estado, o índice e o log do dia) e joga o conteúdo pra dentro da conversa, pra você já começar com o agente sabendo onde as coisas estão. Não escreve nada e não manda nada pra lugar nenhum. No Codex, só roda depois que você confiar no hook.
* **`modulos/ponte-codex.sh`, escrita local no plantio.** Roda quando o setup, o plantar ou o criar-skill pedem, com sua permissão, e escreve só dentro de `.agents/` da sua pasta (o link ou os arquivos curtos que apontam pras suas skills). Não apaga, não renomeia e não substitui arquivo seu.

A conversa em si segue as regras da conta do agente que você usa: a Anthropic, no Claude Code; a OpenAI, no Codex.

Um cuidado que é seu: transcrição de reunião e 1:1 carrega dado sensível de outras pessoas. Antes de colar material da empresa, cheque a política de IA dela (os planos Team e Enterprise do Claude têm controles próprios de dados).

## Atualizações

* **Automático (recomendado):** uma vez só, rode `/plugin`, aba **Marketplaces**, selecione `pm-chief-of-staff` e ative **Enable auto-update**. Versões novas chegam sozinhas com aviso.
* **Manual:** `/plugin marketplace update pm-chief-of-staff` quando quiser checar.
* **No Codex:** `codex plugin marketplace upgrade pm-chief-of-staff` no terminal, e depois uma sessão nova.

Atualização troca o plugin (setup, skills do plugin e catálogo de sementes). **Seus arquivos, suas skills plantadas e seu `AGENTS.md` ou `CLAUDE.md` nunca são tocados.**

## Problemas comuns

* **`/pm-chief-of-staff:setup` aparece como "Unknown command":** rode `/reload-plugins` (o passo 2 da instalação termina nele) ou feche e abra a sessão.
* **O discovery caiu no meio (sessão fechou, contexto acabou):** abra a pasta de novo e rode o setup; ele encontra o `setup-notas.md` que foi gravando e retoma do bloco onde parou.
* **Plantei uma skill e o comando (`/abrir-dia`) não aparece:** skill plantada registra quando a sessão abre. Numa sessão nova ela está lá, e o gatilho por frase ("bom dia") funciona igual.
* **Conectei minha agenda (ou e-mail) e o agente não vê:** conector ligado com a sessão aberta só aparece na sessão seguinte. Feche e abra a sessão. Se você não usa conectores, ignore este item: tudo funciona colando o material.
* **No Codex, as skills plantadas não aparecem:** a ponte não rodou ou achou conflito. Confira se existe `.agents/skills` na pasta; se não existir, peça ao agente pra rodar a ponte do plugin de novo (o plantar também roda) ou siga o caminho de sandbox da instalação do Codex. Se a ponte listou conflito, ela deixou o que era seu intacto: decida com o agente o que fazer com cada linha.
* **No Codex, a sessão abre sem a carga de memória:** o hook ainda não tem sua confiança. Aprove pelo mecanismo de hooks do Codex; até lá, o agente lê os arquivos pela rotina do `AGENTS.md`.

## Não quer instalar o plugin?

Cola o conteúdo de [`PROMPT.md`](PROMPT.md) em qualquer agente com acesso a arquivos (Claude Code e Codex incluídos) e roda o mesmo setup por conversa. A pasta sai com `AGENTS.md`, a ponte `CLAUDE.md`, o índice de regras e as skills numa fonte só, com a descoberta do Codex criada sem passar por cima do que já existe. O plugin acrescenta as skills-semente, as skills `conectar`, `criar-skill` e `remove-ai-tells`, o hook de abertura, a ponte em script e o canal de atualização.

## Filosofia, em 4 princípios

1. **O sistema se auto-modula.** Pedido de mudança vira edição no AGENTS.md ou na skill, na hora. O sistema se molda ao seu jeito de pensar, não o contrário.
2. **Você tem que ler tudo.** Erro que você não pega propaga. Sua responsabilidade é intransferível.
3. **Ele é thought partner, não assistente obediente.** Franqueza acima de validação, diagnóstico antes de sugestão, e anti-padrões nomeados na hora (executar sem questionar, escalar sem recomendação, showcase sem "e daí", otimismo ingênuo, e os de liderança pra quem lidera: Super-Líder, babá de luxo, feedback genérico, decisão dura adiada).
4. **Os arquivos são a memória.** O que não está escrito não existe amanhã.

## Bug ou semente que falta

[Abra uma issue](../../issues/new/choose): tem template pra bug e pra pedido de semente. Pedido de semente é o que vira catálogo novo, e a fila é pública.

## Licença

MIT. Use, adapte, distribua.
