# pm-chief-of-staff

**Um Chief of Staff pessoal pra quem trabalha com produto.** Você abre o Claude Code numa pasta vazia, roda um comando, e ele te entrevista: quem você é, o que você toca, quem trabalha contigo, onde doem as coisas. Das respostas nasce o seu sistema: estrutura de pastas, memória em camadas, skills de rotina, e um agente que processa suas reuniões, prepara suas conversas difíceis, guarda o contexto de tudo e te confronta quando você está se enganando.

Não é um template pronto. **O sistema nasce do seu discovery e se molda a você no uso.** O que funciona pra outra pessoa não necessariamente funciona pra você, e o plugin foi desenhado em cima dessa premissa.

> Vem do sistema que eu uso todo dia como Sr Group PM na Stone, em produção há meses, e que outras pessoas do meu círculo adotaram e adaptaram ao jeito delas. Esta é a versão destilada pra qualquer pessoa de produto: PM, GPM, head, APM, quem lidera gente e quem não lidera (o discovery pergunta e o sistema se ajusta).

**Quer ver como fica?** A pasta [`EXEMPLO/`](EXEMPLO/) tem um sistema fictício com duas semanas de uso: o CLAUDE.md que o setup gera, o diário rodando o loop, uma reunião processada com a propagação, os hubs. Cinco minutos de leitura mostram onde o setup te leva.

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

São 7 blocos de perguntas, uns 20 a 30 minutos de conversa. No fim ele propõe a estrutura e o CLAUDE.md (o "manual de instruções" que ele mesmo vai seguir), **você revisa tudo antes de qualquer arquivo ser criado**, e ele planta as skills iniciais na sua pasta. Não comece 15 minutos antes de uma reunião: o discovery é a parte que define a qualidade do resto.

## O que vem plantado (e por que "plantado" importa)

O setup copia 4 skills-semente pra DENTRO da sua pasta:

| Skill | O que faz |
|---|---|
| `abrir-dia` | agenda + backlog + as 3 do dia ancoradas nas suas prioridades |
| `fechar-dia` | avalia as 3, classifica o que não fechou, semeia o #1 de amanhã |
| `preparar-conversa` | pauta pra 1:1 (liderado ou seu líder), par ou stakeholder, a partir do que está escrito |
| `processar-reuniao` | cola a transcrição, sai nota estruturada + propagação pros lugares certos |

A partir do momento em que são plantadas, **essas skills são arquivos seus**. Quer que a pauta de 1:1 sempre tenha uma seção de reconhecimento? Fala isso pro agente e ele edita a skill. Quer que o abrir-dia inclua seu dashboard? Mesma coisa. Minhas atualizações futuras **nunca tocam no que é seu**: elas só melhoram o setup e adicionam sementes novas no catálogo (`/pm-chief-of-staff:plantar` lista o que há).

## A memória (a parte que faz valer a pena)

O agente esquece entre sessões; os arquivos não. O sistema nasce com 4 camadas de memória, todas em markdown legível:

* **`CRITICAL_FACTS.md`**: o estado vivo (suas prioridades com número, eventos ativos). Lido no começo de toda sessão, existe pra ele nunca te perguntar de novo o que já foi decidido.
* **`memory/`**: o log diário, datado e imutável. O que aconteceu, quando, com ponteiro pra onde está o detalhe.
* **Hubs de pessoas e projetos**: o que estabilizou. Sinais recentes, histórico, contexto.
* **`CLAUDE.md` e as skills**: como ele opera com você. É o que se auto-modula.

O ciclo diário fecha sozinho: `abrir-dia` lê o que o `fechar-dia` de ontem semeou; o `fechar-dia` promove o que ficou solto no log pros hubs. Em duas semanas de uso, o agente conhece seu time, seus projetos e seus padrões.

## Onde ficam meus dados?

**No seu computador, e só nele.** O sistema inteiro é uma pasta de markdown que você abre, lê, versiona e apaga quando quiser. Nada é enviado pra mim. A conversa com o Claude segue as regras da sua conta Anthropic, como qualquer uso do Claude Code.

## Atualizações

* **Automático (recomendado):** uma vez só, rode `/plugin`, aba **Marketplaces**, selecione `pm-chief-of-staff` e ative **Enable auto-update**. Versões novas chegam sozinhas com aviso.
* **Manual:** `/plugin marketplace update pm-chief-of-staff` quando quiser checar.

Atualização troca o plugin (setup e catálogo de sementes). **Seus arquivos, suas skills plantadas e seu CLAUDE.md nunca são tocados.**

## Não tem Claude Code? (plano B)

O arquivo [`PROMPT.md`](PROMPT.md) tem a versão colável do setup: cola no Claude Code (ou adapta pra outra ferramenta de agente com acesso a arquivos) e roda o mesmo discovery na mão. Foi assim que as primeiras pessoas usaram esse sistema, antes de ele virar plugin. Você perde o canal de atualização e as sementes, mas o núcleo (discovery + CLAUDE.md + memória) funciona.

## Filosofia, em 4 princípios

1. **O sistema se auto-modula.** Pedido de mudança vira edição no CLAUDE.md ou na skill, na hora. O sistema se molda ao seu jeito de pensar, não o contrário.
2. **Você tem que ler tudo.** Erro que você não pega propaga. Sua responsabilidade é intransferível.
3. **Ele é thought partner, não assistente obediente.** Franqueza acima de validação, diagnóstico antes de sugestão, e anti-padrões nomeados na hora (executar sem questionar, escalar sem recomendação, showcase sem "e daí", otimismo ingênuo, e os de liderança pra quem lidera: Super-Líder, babá de luxo, feedback genérico, decisão dura adiada).
4. **Os arquivos são a memória.** O que não está escrito não existe amanhã.

## Licença

MIT. Use, adapte, distribua.
