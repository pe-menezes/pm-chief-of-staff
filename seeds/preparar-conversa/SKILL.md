---
name: preparar-conversa
description: Monta a pauta antes de uma conversa que importa. 1:1 com liderado, 1:1 com o próprio líder, alinhamento com par ou stakeholder. Use quando a pessoa disser "prepara o 1:1 com [nome]", "monta a pauta", "vou falar com [nome]", "tenho reunião com [nome], me prepara", "/preparar-conversa". NÃO use pra processar a conversa depois que aconteceu (processar-reuniao).
---

# Preparar uma conversa

> Semente do pm-chief-of-staff. Este arquivo é SEU: peça pro agente mudar o formato da pauta ("quero que sempre tenha uma seção de X") e ele edita esta skill na hora.

Escrita: siga o cânone do CLAUDE.md desta pasta. Na ausência dele: sem travessão (use vírgula, parênteses ou dois pontos), frases curtas e densas, 1 linha por item.

Pauta boa nasce do que já está escrito, não da memória. O fluxo: levantar candidatos → validar com a pessoa → escrever a pauta só com o validado.

## Passo 1: levantar candidatos

1. Ler o hub da pessoa em `pessoas/`, começando pela cabeça: a seção Fatos (datados, com fonte) e a Leitura vigente (a mais recente, sem marca de superada) são a base da preparação; leitura marcada como superada é ignorada. Sinais recentes e Histórico entram como complemento.
2. Ler as 2 a 3 últimas notas de conversa com ela em `reunioes/`: o que ficou de follow-up (dos dois lados), o que foi combinado "pra próxima".
3. Grep do nome no diário e no `memory/` das últimas 2 semanas: o que apareceu sobre ela ou sobre os temas dela.
4. Todo item da seção "Sinais recentes" do hub é candidato. Sinal parado há mais de 3 semanas entra com a pergunta: cobra de novo ou caiu?
5. Se existir `.claude/skills/_shared/capacidades.md` com `provider` e `como chamar` em `mensagens` ou `tickets`, puxar por ali o que apareceu nas últimas 2 semanas sobre a pessoa e os temas dela (a mesma janela do item 3), como candidato igual aos outros. Sem o módulo, com a linha vazia ou pela metade, ou se a busca falhar, o passo 1 fica nos arquivos, que é o default.

## Passo 2: validar com a pessoa

Apresentar os candidatos numerados, agrupados (follow-ups abertos / sinais / tópicos novos), e perguntar o que entra: levar / hoje não / descartar / editar. Não censurar candidato por conta própria; a pessoa decide.

## Passo 3: escrever a pauta

Arquivo em `reunioes/{nome}/YYYY-MM-DD pauta.md`, mira de 15 linhas no máximo, tom factual. Seção sem conteúdo é omitida.

```markdown
**Contexto:** {1 linha: momento da pessoa + o que está quente}

Abrir ouvindo: "o que você me traz?"

## Follow-ups abertos
- {item + prazo + pergunta, 1 linha cada; pendência SUA que impacta a pessoa entra com transparência}

## Decisões a tomar
- {1 linha por decisão que precisa sair da conversa}

## Tópicos
- {o que entrar do passo 2}
```

## Ajustes por tipo de conversa

* **Liderado (se você lidera):** acrescente uma seção `## Feedbacks (1-2)` com evidência concreta (situação → comportamento → impacto; feedback de desenvolvimento fecha com a mudança esperada). Sem evidência concreta de 1 a 2 semanas, sem feedback: flagre a lacuna e sugira observar na semana. Acrescente também 1 pergunta de desenvolvimento ancorada no momento da pessoa.
* **Seu líder:** liderar com estado e decisão, não com atividade. O que você precisa DELE (desbloqueio, decisão, contexto) entra explícito. Leve recomendação, não lista de problemas.
* **Par ou stakeholder:** o que você precisa dele, o que ele precisa de você, e o desalinhamento que está caro. Pauta de alinhamento sem decisão pra tomar é reunião que podia ser mensagem: diga isso.

## Depois de gerar

Perguntar se ajusta algo antes da conversa. A pauta não propaga nada pro hub: quem propaga é o `processar-reuniao`, depois que a conversa acontecer (ele também compara o planejado com o acontecido).
