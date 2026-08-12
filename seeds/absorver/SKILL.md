---
name: absorver
description: Dá casa a material que a pessoa manda pra dentro do sistema (doc do produto dela, artigo, estudo, processo da empresa): roteia pro destino certo, destila o essencial com proveniência e declara quando aquilo será usado. Use quando a pessoa disser "lê esse doc", "olha esse artigo", "esse é o processo de X aqui", "guarda isso", ou colar texto longo sem pedir processamento de reunião. NÃO use pra transcrição ou nota de reunião (processar-reuniao) nem pra pergunta pontual sobre um texto sem intenção de guardar.
---

# Absorver material

> Semente do pm-chief-of-staff. Este arquivo é SEU: peça pro agente mudar o roteamento ou o formato do resumo e ele edita esta skill na hora.

Escrita: siga o cânone do CLAUDE.md desta pasta. Na ausência dele: sem travessão (use vírgula, parênteses ou dois pontos), frases curtas e densas, 1 linha por item.

O valor não é arquivar: é dar destino ao material, destilar o que o sistema ainda não sabe e deixar escrito quando aquilo volta. Material que fica só no chat evapora quando a sessão fecha.

## Passo 1: entender o material

No máximo 1 pergunta, e só se não der pra inferir: o que é e pra que serve.

## Passo 2: rotear por natureza

* **Doc de projeto vivo** (spec, plano, análise do que está em andamento): pasta do projeto em `projetos/`.
* **Conhecimento durável** (produto, mercado, artigo, estudo): `referencia/{tema}.md`.
* **Processo operacional da empresa**, pelo gatilho dele: gatilho é tipo de arquivo ("toda nota de X segue este formato"), vira `.claude/rules/{tema}.md` com frontmatter `paths:`; gatilho é ritual que uma skill plantada cobre (preparar conversa, fechar semana), a regra entra na skill dona; o mesmo passo vale em 2 ou mais skills, vira módulo em `.claude/skills/_shared/{nome}.md` que cada uma manda ler (declare no topo dele quem carrega); sem gatilho claro, `referencia/` com o gatilho escrito no arquivo.
* **Sobre pessoa-chave**: hub dela em `pessoas/`, na seção certa: fato datado com fonte em "Fatos", sinal em "Sinais recentes" (1 linha datada), leitura que muda a anterior em "Leitura vigente" (marcando a anterior com "superada em DD/MM por {o que a superou}").

## Passo 3: destilar o delta

Resumo denso de até 20 linhas, nunca cópia: data e origem no topo (proveniência sempre, de onde veio e quando entrou), artigo longo vira o essencial. O original vive fora do vault (pasta fria, drive, ou a própria origem), com 1 linha de ponteiro no destilado.

## Passo 4: declarar o consumidor

Todo arquivo fecha com a linha "quando eu uso isso" (exemplo: processo de avaliação da empresa, uso quando a gente preparar o seu ciclo). Material sem uso previsível: diga isso e pergunte se guarda mesmo assim.

## Passo 5: criar e indexar

Crie o arquivo novo e atualize `navegacao.md`. Antes de escrever em destino compartilhado (o hub em `pessoas/`), leia `.claude/skills/_shared/gate-de-escrita.md` e aplique a decisão de admissão (ADD, UPDATE, SUPERSEDE, NOOP). Sem o módulo, a checagem em 1 linha: ler o destino antes de escrever, e não escrever o que já está lá.

## Passo 6: responder curto

Até 5 linhas: onde ficou (path clicável) + quando será usado.
