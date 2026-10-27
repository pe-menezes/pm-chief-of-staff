---
name: tirar-tells
description: Tira de um texto os tells de escrita gerada por IA (antítese em série, frase de efeito, travessão, a mesma coisa com três nomes) a partir dos achados de um agente revisor separado e devolve o texto limpo com o antes e depois de cada trecho. Use quando a pessoa disser "tira os AI tells desse texto", "isso tá com cara de IA?", "revisa os tells antes de eu mandar", "limpa a cara de IA disso" ou rodar /pm-chief-of-staff:tirar-tells. Não use pra escrever texto do zero, revisar gramática e ortografia ou ajustar o tom a um destinatário, que são pedidos diretos ao agente.
---

# Tirar os tells

Um tell isolado passa despercebido. A mesma forma repetida no texto denuncia a escrita gerada. Quem escreveu ou vai reescrever o texto enxerga mal os próprios tells, por isso a leitura sai do `revisor-tells`, um agente do plugin que roda em contexto separado.

## Fluxo

1. Pegue o texto colado, o caminho de arquivo ou o último texto que você escreveu na sessão. Sem texto claro, pergunte qual.
2. Copie o texto pra `rascunho-tells.md` na raiz da pasta da pessoa. Arquivo que já existe com esse nome nunca é substituído nem apagado, inclusive quando é a própria origem. Nesse caso use o próximo nome livre (`rascunho-tells-2.md`, `rascunho-tells-3.md` e assim por diante), e os passos seguintes chamam de rascunho o arquivo criado nesta execução. O rascunho mantém cada quebra de linha. Lista, tabela, título e bloco de código ficam intactos porque o trecho aprovado volta pro arquivo de origem por correspondência exata. Varredura, revisor e reescrita trabalham no rascunho. Ele fica fora de `.claude/`, que pede permissão de escrita até no modo que aceita edição. Antes de gravar, avise em 1 frase que criar o arquivo na raiz pode pedir permissão de escrita. Negada a permissão, pare e diga à pessoa que o revisor lê o texto de um arquivo e sem o rascunho ele não roda.
3. Varra o rascunho com a ferramenta Grep, já que contagem a olho erra. Sem a ferramenta Grep na sessão, rode as mesmas três regex no `grep -P` do Bash, porque sem o `-P` a regex de dois-pontos volta vazia e sem erro. A busca devolve candidatos. Descarte os que caem em bloco de código, código inline, URL, horário (o dois-pontos de URL e de hora não conta) ou linha de alinhamento de tabela (`|:---|---:|`).
   - Travessão, bife e aspas curvas pela regex `[\x{2014}\x{2013}\x{201C}\x{201D}\x{2018}\x{2019}]`. O code point evita a confusão entre travessão, bife e hífen.
   - Antítese pela regex `(não é [a-zà-ú]|, não [a-zà-ú]|não só |não apenas |mais do que )`. Use `-i` pra pegar a maiúscula do início da frase. Ela acha a antítese nua e também o comparativo legítimo, que o revisor descarta. A antítese disfarçada fica com ele.
   - Dois-pontos e ponto e vírgula pela regex `[:;](?:[^:;\n]|\n[^\n:;])*[:;]` com `multiline`. Ela acha cada parágrafo (linhas seguidas sem linha em branco) com dois ou mais desses sinais somados e devolve dele o trecho entre o primeiro e o último sinal.
4. Chame o `revisor-tells` (`pm-chief-of-staff:revisor-tells` na lista de agentes) com o caminho do rascunho e o de `.claude/skills/_shared/tells.md` da pasta da pessoa, se existir. Mande os caminhos sem a sua leitura do texto, que enviesaria a dele. Ele devolve os achados e a contagem de ocorrências por forma (uma linha com dois travessões soma dois).

   Quem instalou ou atualizou o plugin com a sessão aberta pode não ver o revisor na lista de agentes. Nesse caso, sugira `/reload-plugins` e, se o revisor seguir fora da lista, uma sessão nova. Se não der, despache um sub-agente genérico com o corpo de `${CLAUDE_PLUGIN_ROOT}/agents/revisor-tells.md` como instrução e a ordem explícita de só ler e não editar nada (se a variável não resolver, localize a pasta do plugin `pm-chief-of-staff` no cache de plugins). Avise em 1 frase que ler a pasta do plugin pode pedir permissão e que, negada a leitura, o revisor não roda e a saída é a sessão nova.
5. Antes de reescrever, guarde a contagem de ocorrências por forma dos achados que o revisor confirmou. Ela é o "antes" do passo 7 e se perde quando a reescrita muda o rascunho. Depois reescreva só os trechos marcados.
   - Na antítese, corte a metade negativa e afirme só o fato.
   - Dois-pontos de prosa vira frase.
   - Título nomeia o assunto.
   - Frase de efeito sai inteira. O fato que ela enfeitava fica.
   - Cada coisa leva um nome só.
   - Travessão e bife viram vírgula, parênteses ou ponto. Aspa curva vira reta.

   A reescrita mantém número, nome próprio e sentido. Ela não cria forma nova (clivada, sinônimo de enfeite) nem troca afirmação verificável por hedge.
6. Confira a reescrita com a varredura do passo 3 e com uma chamada nova do revisor, que leva os mesmos dois caminhos. A continuação da primeira chamada já tem a lista anterior no contexto. Sem o `tells.md`, o que a pessoa marcou como jeito dela volta como achado. A segunda leitura pega o tell trocado por outro e o erro de gramática que a reescrita introduz. Achado novo ganha 1 rodada a mais, no máximo. O que sobrar vai declarado na entrega.
7. Entregue o texto limpo pronto pra copiar, uma linha de antes e depois por trecho e a contagem de cada forma nas duas versões. A pessoa aprova tudo ou escolhe trechos.
8. Só os aprovados voltam pro arquivo de origem, quando houver. Cada trecho volta um por vez, com contexto bastante para aparecer uma vez só na origem, e nunca por substituição em lote, porque a cópia de dentro de um bloco de código mudaria junto. Trecho que sumiu da origem ou segue repetido fica de fora e vai declarado à pessoa. No fim, depois de aplicar ou de a pessoa desistir, apague só o rascunho criado nesta execução. Antes de apagar, avise em 1 frase que apagar o rascunho pede permissão. Negada ou com falha, diga à pessoa o caminho do rascunho e que ele fica na pasta até ela apagar, porque a pasta pode estar sob git. Pra texto colado, a pessoa escolhe onde salvar a versão limpa. Caminho que já existe nunca é substituído, e a pessoa escolhe entre manter o arquivo, salvar com outro nome ou ver o diff.

## Aprender com a pessoa

Quando ela apontar um tell que passou, ou recusar um achado porque é o jeito dela de escrever, ofereça guardar isso em `.claude/skills/_shared/tells.md` da pasta dela. O arquivo tem 2 seções, "Tells que eu flagrei" e "Meu jeito, não marcar". A primeira linha segue o formato dos módulos, pra que a conferência de consumidores do `fechar-semana` não acuse órfão:

```
**Carregado por:** `tirar-tells` (skill do plugin, fora de `.claude/skills/`)
```

Crie o arquivo depois do ok dela. Avise antes, em 1 frase, que o pedido de permissão do `.claude/` vai aparecer e é esperado, e que, negada a escrita, o que ela marcou vale só nesta conversa. Arquivo existente é dela e pode ter sido editado à mão. Ele ganha a linha na seção certa e o resto fica como está.
