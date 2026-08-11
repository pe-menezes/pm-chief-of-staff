# pm-chief-of-staff

**Um Chief of Staff pessoal pra quem trabalha com produto.** Você abre o Claude Code numa pasta vazia, roda um comando, e ele te entrevista: quem você é, o que você toca, quem trabalha contigo, onde doem as coisas. Das respostas nasce o seu sistema: estrutura de pastas, memória em camadas, skills de rotina, e um agente que processa suas reuniões, prepara suas conversas difíceis, guarda o contexto de tudo e te confronta quando você está se enganando.

Não é um template pronto. **O sistema nasce do seu discovery e se molda a você no uso.** O que funciona pra outra pessoa não necessariamente funciona pra você, e o plugin foi desenhado em cima dessa premissa.

> Vem do sistema que eu uso todo dia como pessoa de produto, em produção há meses, e que outras pessoas do meu círculo adotaram e adaptaram ao jeito delas. Esta é a versão destilada pra qualquer pessoa de produto: PM, GPM, head, APM, quem lidera gente e quem não lidera (o discovery pergunta e o sistema se ajusta).

## O que você precisa antes

1. **[Claude Code](https://claude.com/claude-code)**: o app da Anthropic que roda no seu computador (Mac ou Windows).
2. **Assinatura do Claude** (Pro ou superior). É a única coisa paga.
3. Mais nada. Não precisa saber programar, não precisa de Obsidian nem Notion (o sistema é uma pasta de arquivos markdown que qualquer editor abre; se você usa Obsidian, ele funciona bem por cima). Se você nunca usou um terminal, cole este README no próprio Claude e peça ajuda.

## Instalação (3 passos, ~5 minutos)

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

São 7 blocos de perguntas, uns 20 a 30 minutos de conversa. No fim ele propõe a estrutura e o CLAUDE.md (o "manual de instruções" que ele mesmo vai seguir), **você revisa tudo antes de qualquer arquivo ser criado**, e ele planta as skills iniciais na sua pasta. Nessa última parte o Claude pede sua permissão duas vezes, uma pra ler as skills que vêm com o plugin e outra pra criar os arquivos delas na sua pasta: aceite as duas, porque sem isso os comandos não passam a existir. Não comece 15 minutos antes de uma reunião: o discovery é a parte que define a qualidade do resto.

## O que vem plantado (e por que "plantado" importa)

O setup copia 5 skills-semente pra DENTRO da sua pasta:

| Skill | O que faz |
|---|---|
| `abrir-dia` | agenda + backlog + as 3 do dia ancoradas nas suas prioridades |
| `fechar-dia` | avalia as 3, classifica o que não fechou, semeia o #1 de amanhã |
| `preparar-conversa` | pauta pra 1:1 (liderado ou seu líder), par ou stakeholder, a partir do que está escrito |
| `processar-reuniao` | cola a transcrição, sai nota estruturada + propagação pros lugares certos |
| `absorver` | joga um doc, artigo ou processo pra dentro: ganha casa, resumo com proveniência e a linha de quando será usado |

A partir do momento em que são plantadas, **essas skills são arquivos seus**. Quer que a pauta de 1:1 sempre tenha uma seção de reconhecimento? Fala isso pro agente e ele edita a skill. Quer que o abrir-dia inclua seu dashboard? Mesma coisa. Minhas atualizações futuras **nunca tocam no que é seu**: elas só melhoram o setup e adicionam sementes novas no catálogo (`/pm-chief-of-staff:plantar` lista o que há).

No catálogo, além das plantadas: **`fechar-semana`**, que agrega os balanços diários, força as decisões da semana, mede a saúde da memória do sistema (os arquivos que toda sessão carrega, contra os alvos de tamanho), guarda sinal de trajetória (o material da sua avaliação de ciclo) e monta o diário da próxima. Plante no fim da sua primeira semana: `/pm-chief-of-staff:plantar fechar-semana`.

Também no plugin: **`/pm-chief-of-staff:conectar`**, que mapeia num arquivo único o que o agente consegue puxar sozinho (agenda, transcrição, mensagens, tickets), e com isso as skills de rotina param de perguntar o que ele já sabe buscar; o setup roda ele. Se você já tinha as skills plantadas antes dessa camada, o `conectar` confere quais delas ainda perguntam e oferece a edição de cada uma.

## A memória (a parte que faz valer a pena)

A memória do agente são os arquivos: o que está escrito na pasta, qualquer sessão futura carrega. O sistema nasce com 4 camadas, todas em markdown legível:

* **`CRITICAL_FACTS.md`**: o estado vivo (suas prioridades com número, eventos ativos). Lido no começo de toda sessão, existe pra ele nunca te perguntar de novo o que já foi decidido.
* **`memory/`**: o log diário, datado e imutável. O que aconteceu, quando, com ponteiro pra onde está o detalhe.
* **Hubs de pessoas e projetos**: o que estabilizou. Sinais recentes, histórico, contexto.
* **`CLAUDE.md` e as skills**: como ele opera com você. É o que se auto-modula.

O ciclo diário fecha sozinho: `abrir-dia` lê o que o `fechar-dia` de ontem semeou; o `fechar-dia` promove o que ficou solto no log pros hubs. Em duas semanas de uso, o agente conhece seu time, seus projetos e seus padrões.

Se a engine externa `memoria-agente` estiver configurada na mesma pasta, os dois compõem: este plugin dá a estrutura e os rituais, a engine dá o enforcement mecânico e assume a injeção de abertura (o hook detecta e cede a vez).

## Onde ficam meus dados?

**No seu computador, e só nele.** O sistema inteiro é uma pasta de markdown que você abre, lê, versiona e apaga quando quiser. Nada é enviado pra mim, e o plugin não instala nada. Ele roda uma coisa só, quando você abre uma sessão: um script curto que lê três arquivos da sua própria pasta (o estado, o índice e o log do dia) e joga o conteúdo pra dentro da conversa, pra você já começar com o agente sabendo onde as coisas estão. Ele não manda nada pra lugar nenhum e não toca em nada fora da pasta. Está em `hooks/boot-memoria.sh` e dá pra ler inteiro em 2 minutos. A conversa com o Claude segue as regras da sua conta Anthropic, como qualquer uso do Claude Code.

Um cuidado que é seu: transcrição de reunião e 1:1 carrega dado sensível de outras pessoas. Antes de colar material da empresa, cheque a política de IA dela (os planos Team e Enterprise do Claude têm controles próprios de dados).

## Atualizações

* **Automático (recomendado):** uma vez só, rode `/plugin`, aba **Marketplaces**, selecione `pm-chief-of-staff` e ative **Enable auto-update**. Versões novas chegam sozinhas com aviso.
* **Manual:** `/plugin marketplace update pm-chief-of-staff` quando quiser checar.

Atualização troca o plugin (setup e catálogo de sementes). **Seus arquivos, suas skills plantadas e seu CLAUDE.md nunca são tocados.**

## Problemas comuns

* **`/pm-chief-of-staff:setup` aparece como "Unknown command":** rode `/reload-plugins` (o passo 2 da instalação termina nele) ou feche e abra a sessão.
* **O discovery caiu no meio (sessão fechou, contexto acabou):** abra a pasta de novo e rode o setup; ele encontra o `setup-notas.md` que foi gravando e retoma do bloco onde parou.
* **Plantei uma skill e o comando (`/abrir-dia`) não aparece:** skill plantada registra quando a sessão abre. Numa sessão nova ela está lá, e o gatilho por frase ("bom dia") funciona igual.

## Não quer instalar o plugin?

Cola o conteúdo de [`PROMPT.md`](PROMPT.md) em qualquer agente com acesso a arquivos e roda o mesmo setup por conversa. O plugin só acrescenta as skills-semente e o canal de atualização.

## Filosofia, em 4 princípios

1. **O sistema se auto-modula.** Pedido de mudança vira edição no CLAUDE.md ou na skill, na hora. O sistema se molda ao seu jeito de pensar, não o contrário.
2. **Você tem que ler tudo.** Erro que você não pega propaga. Sua responsabilidade é intransferível.
3. **Ele é thought partner, não assistente obediente.** Franqueza acima de validação, diagnóstico antes de sugestão, e anti-padrões nomeados na hora (executar sem questionar, escalar sem recomendação, showcase sem "e daí", otimismo ingênuo, e os de liderança pra quem lidera: Super-Líder, babá de luxo, feedback genérico, decisão dura adiada).
4. **Os arquivos são a memória.** O que não está escrito não existe amanhã.

## Bug ou semente que falta

[Abra uma issue](../../issues/new/choose): tem template pra bug e pra pedido de semente. Pedido de semente é o que vira catálogo novo, e a fila é pública.

## Licença

MIT. Use, adapte, distribua.
