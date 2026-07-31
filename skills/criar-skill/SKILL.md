---
name: criar-skill
description: Cria uma skill nova sob medida pra pessoa, da triagem ao teste de disparo. Use quando ela pedir pra automatizar um processo próprio: "cria uma skill de X", "automatiza Y pra mim", "quero que você sempre rode esse processo", "transforma esse ritual numa skill". Não use pra preferência simples de comportamento ou formato, que vira linha no CLAUDE.md ou regra situacional com escopo de arquivo (a triagem desta skill explica os destinos), nem pra ajustar uma semente ou skill já plantada, que é edição direta do arquivo dela.
---

# Criar uma skill

A pessoa pediu pra você automatizar um processo. O caminho tem 4 passos: triar se aquilo vira skill mesmo, escrever a skill, testar o disparo com ela e plantar na pasta dela. Leia esta skill inteira antes de propor qualquer coisa.

## Passo 1: triagem (nem todo pedido vira skill)

Vira skill só o workflow repetível com gatilho próprio: um processo com passos e resultado, que a pessoa vai invocar de novo e que se reconhece numa frase ("processa a retro", "monta o report do comitê"). Pedido que não passa nesse filtro tem outro destino:

* **Preferência que vale em toda interação** (tom, formato de resposta, vocabulário): 1 linha no CLAUDE.md.
* **Regra situacional de um tema ou tipo de arquivo** ("quando mexer em nota de reunião, faça X"): arquivo de regra que só carrega quando o trabalho toca aqueles arquivos, e o CLAUDE.md continua leve (a mecânica está na camada de implementação, adiante).
* **Ajuste em skill que já existe** (semente plantada ou skill criada antes): edição direta daquela skill. Skill nova com gatilho vizinho de uma existente disputa o disparo com ela.

Diga qual destino o pedido tem e por quê, e siga pro passo 2 só com a confirmação da pessoa.

## Passo 2: escrever a skill

Skill é instrução pra agente, e as restrições que valem pra qualquer instrução valem aqui: contexto é finito, instrução longa degrada qualquer modelo, gatilho vago não dispara em agente nenhum. As regras de autoria saem dessas restrições:

* **description em 3ª pessoa: o QUE + QUANDO.** O que a skill faz, quando usar (com os termos que a própria pessoa usaria pra pedir) e quando NÃO usar, apontando o destino certo. A description decide o disparo e o corpo só é lido depois: gatilho vago não dispara.
* **Corpo é guia leve que confia no julgamento do modelo.** Objetivo, etapas e as decisões de formato da pessoa, sem prescrever o que o agente resolve sozinho: instrução longa degrada a execução inteira. Regra rígida só em passo frágil ou destrutivo (sobrescrever, apagar, mandar algo pra fora), e sempre com o porquê: regra sem porquê quebra no primeiro caso que ela não previu, e o porquê é o que orienta o caso novo.
* **Progressive disclosure.** Corpo curto; template longo, tabela de referência ou detalhe que só serve em parte das execuções vai pra arquivo separado na mesma pasta da skill, que o corpo aponta. O detalhe só deve ocupar contexto quando a execução precisa dele.
* **Artefato tem alvo em número.** Skill que gera arquivo declara a mira ("nota de até 25 linhas", "1 linha por item"); sem número o output cresce a cada execução.
* **Sem exemplos de uso engessados.** Diálogo pronto e output modelo constrangem a exploração: o agente passa a imitar o exemplo em vez de resolver o caso real.
* **A skill codifica a opinião e o jeito DA PESSOA.** O formato de pauta dela, o vocabulário dela, o que ela considera pronto. Processo genérico que serviria pra qualquer um não carrega opinião e não precisa de skill.

### Camada de implementação (a mecânica de cada destino)

No Claude Code: skill é uma pasta com `SKILL.md` e a description no frontmatter; regra situacional é `.claude/rules/{tema}.md` com frontmatter `paths:` (lista de globs; a regra carrega só quando o trabalho toca aqueles arquivos); e `/doctor` revisa e simplifica CLAUDE.md e skills de tempos em tempos. Em outro agente, o equivalente local: o arquivo de instrução que ele sempre carrega faz o papel do CLAUDE.md, e a regra situacional usa o mecanismo de escopo que ele tiver (ou declara o escopo no topo do próprio arquivo, que o agente respeita).

Proveniência das regras de autoria: "The new rules of context engineering for Claude 5 generation models" (https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models), o post que documenta um system prompt de agente cortado em mais de 80% sem perda mensurável.

## Passo 3: teste de disparo

Antes de criar o arquivo, proponha 2 a 3 frases que devem disparar a skill e 1 a 2 vizinhas que não devem (dizendo o que atende cada vizinha: outra skill, o CLAUDE.md, uma regra). A pessoa valida: frase que ela nunca falaria sai da description; colisão com skill existente volta pro passo 1.

## Passo 4: plantar

Crie a skill em `.claude/skills/{nome}/` da pasta da pessoa, nunca no plugin. O arquivo é dela: editável, auto-modulável, fora do alcance de qualquer atualização do plugin. O comando (`/{nome}`) registra na próxima sessão; pra testar agora, leia o SKILL.md criado e siga o conteúdo direto.
