# Decision Log
> Newest first. Updated automatically by the architect agent.

Formato de entrada: título com a versão em que a decisão entrou (mais o commit, quando ela não coincide com um bump de versão), depois **Decisão**, **Por quê**, **Custo** e **Onde vive**. Entradas escritas em 06/08/2026 a partir do repo em v0.3.0 e do histórico de commits. Decisão cuja versão não foi medida fica marcada como tal.

## v0.3.0 (commit a08b67e) , o plantio avisa dos dois pedidos de permissão antes do primeiro deles

**Decisão:** no passo de plantio, antes da primeira leitura e da primeira escrita, o setup avisa em 1 frase que vão aparecer dois pedidos de permissão, um pra ler os arquivos do plugin (onde as sementes moram) e outro pra criar arquivos em `.claude/` da pasta da pessoa. Negado ou bloqueado, o setup diz o que ficou sem ser escrito e o que deixa de funcionar (os comandos como `/abrir-dia`), sem contorno silencioso.

**Por quê:** medido no caminho real de instalação, são dois pedidos, em momentos diferentes, no minuto mais frágil do setup: depois de 20 a 30 minutos de discovery, quando a pessoa já investiu a conversa inteira. Permissão negada por susto deixa ela sem os comandos e sem saber por quê. Skill escrita fora de `.claude/skills/` não vira comando, então contornar em silêncio entregaria um sistema que parece pronto e não dispara.

**Custo:** um parágrafo a mais no fim do setup, e uma dependência nova numa propriedade do ambiente. Quantos pedidos de permissão o Claude Code emite pode mudar de versão, e aviso desatualizado custa mais que aviso ausente: a pessoa espera dois, aparece um, e ela fica procurando o que não existe.

**Onde vive:** `skills/setup/SKILL.md:194`, `README.md:33`.

**Nota de registro:** a contagem de dois pedidos é medição do ambiente; a decisão registrada aqui é avisar antes e falhar alto.

## v0.3.0 (commit dc688ad, PR #9) , a régua de destino tem 4 saídas, e o eixo é o gatilho de carga

**Decisão:** pedido de mudança da pessoa tem 1 destino entre 4, escolhido pelo gatilho de carga: `CLAUDE.md` (carrega sempre), `.claude/rules/{tema}.md` com frontmatter `paths:` (carrega quando o trabalho toca aqueles arquivos), `.claude/skills/_shared/{nome}.md` (carrega no meio da execução, antes de o arquivo existir, e só quando uma skill manda ler), skill dona do artefato (carrega quando aquela skill roda). A terceira saída entrou em v0.2.0 com as regras por escopo; a quarta entrou aqui.

**Por quê:** o `CLAUDE.md` é o arquivo que toda sessão paga, e ele engorda com o que é situacional. Separar por assunto não resolve, porque duas instruções do mesmo assunto podem precisar carregar em momentos diferentes. O eixo que decide é quando o texto precisa estar em contexto, e é ele que separa os dois destinos que mais se confundem: regra com `paths:` dispara quando um arquivo é tocado, e disciplina de "antes de escrever a nota" tem que carregar antes de o arquivo existir.

**Custo:** 4 destinos é mais uma decisão na frente de cada pedido, e a triagem pode errar. A régua vive em 4 arquivos (`skills/setup/`, `PROMPT.md`, `skills/criar-skill/`, `seeds/absorver/`) e mudar o eixo custa 4 edições no mesmo change. Não há teste possível dentro do repo: os 4 destinos só existem na pasta da pessoa, e nem `.claude/rules/` nem `_shared/` têm arquivo em uso aqui pra conferir.

**Onde vive:** `skills/setup/SKILL.md:173-190`, `skills/criar-skill/SKILL.md:14-17` e `:32-36`, `seeds/absorver/SKILL.md:22`, `PROMPT.md:16`, `patterns/instruction-routing.md`.

## v0.3.0 (commit dc688ad, PR #9) , skill cita capacidade, nunca nome de ferramenta

**Decisão:** skill que busca dado de fora cita capacidade (`agenda do dia`, `transcrição de reunião`, `mensagens`, `tickets`), e o mapa capacidade → provider vive em `.claude/skills/_shared/capacidades.md` na pasta da pessoa. Capacidade ligada leva `provider` e `como chamar` juntos; provider que sai limpa as duas células.

**Por quê:** nome de tool copiado em 3 skills quebra em 3 lugares no dia em que ele muda, e as cópias divergem antes disso, na primeira que alguém edita sem olhar as outras. Com a indireção, trocar de empresa ou de calendário é 1 linha editada, sem abrir skill nenhuma. As duas colunas andam juntas porque é `como chamar` que a consumidora executa: com `provider` sozinho ela tenta sem instrução, falha, e cai no fallback com um tropeço no meio do fluxo.

**Custo:** uma indireção a mais entre a skill e o dado, e um arquivo que pode mentir (provider que saiu, ferramenta renomeada). Não há carga automática: o módulo entra em contexto só quando uma skill manda ler, então a régua depende de cada consumidora referenciar o arquivo no passo certo, e a falta de referência não dá erro. A única pista de quem lê o módulo é a linha "Carregado por" no topo dele, mantida à mão.

**Onde vive:** `skills/conectar/SKILL.md:10-12`, `modulos/capacidades.md:1` e `:5`, `seeds/abrir-dia/SKILL.md:23`, `seeds/processar-reuniao/SKILL.md:18`, `seeds/preparar-conversa/SKILL.md:20`, `patterns/system-contracts.md` (contrato 7).

## v0.3.0 (commit dc688ad, PR #9) , o módulo compartilhado é plantado na pasta da pessoa

**Decisão:** o módulo compartilhado não mora no plugin. O plugin carrega o template (`modulos/capacidades.md`) e o plantio copia pra `.claude/skills/_shared/` da pessoa, onde ele vira arquivo dela: atualização nunca toca nele, colisão nunca resolve por sobrescrita, e rodar `/pm-chief-of-staff:conectar` de novo atualiza linha por linha. A pasta `_shared/` nasce sem `SKILL.md`.

**Por quê:** o mesmo motivo da semente, com o conteúdo pesando mais. O que está no módulo pertence à pessoa: quais ferramentas ela usa e como chamar cada uma. Arquivo desse tipo morando no plugin seria sobrescrito a cada update e levaria embora o que ela ajustou à mão. Módulo no plugin também não funcionaria: a skill plantada é arquivo dela e lê caminho dela.

**Custo:** herda a consequência da semente e agrava. Melhoria no template não chega em quem já rodou, e aqui a linha velha não é só velha: ela aponta pra ferramenta que não responde mais, e a consumidora tenta antes de descobrir. Por isso `conectar` reescreve linha por linha e nunca do zero. A pasta sem `SKILL.md` é condição do mecanismo: com um `SKILL.md` dentro, o scanner registraria o módulo como skill fantasma.

**Onde vive:** `skills/conectar/SKILL.md:18` e `:30`, `skills/setup/SKILL.md:202`, `modulos/capacidades.md`, `patterns/seed-model.md`.

## v0.1.3 , `.vibeflow/` fora do main público, e a análise numa branch

**Decisão:** o diretório `.vibeflow/` não entra no main. O `.gitignore` do repo tem uma linha só, `.vibeflow/`, e a análise vive numa branch de trabalho (hoje `vibeflow-analise`), que recebe merge do main quando precisa ser reanalisada.

**Por quê:** o repo é a landing de instalação de um produto pra pessoa de produto que não programa, e a promessa do README é que não precisa saber programar. Pasta de análise de código na raiz do main é ruído pra esse leitor e sugere que ele tem algo a configurar antes de usar. O mapa serve a quem edita o repo, não a quem instala o plugin.

**Custo:** o mapa não viaja com o clone, e quem for regenerar precisa trocar de branch antes. Pior que isso, ele deriva em silêncio, porque nenhum PR do main o vê: medido em 06/08/2026, a análise de 30/07 descrevia 4 sementes num repo que já tinha 6, não conhecia `skills/conectar/`, `skills/criar-skill/`, `hooks/` nem `modulos/`, e 12 commits passaram sem tocá-la. O merge do main pra dentro da branch é passo manual que ninguém cobra.

**Onde vive:** `.gitignore:1`, branch `vibeflow-analise`.

## Origem do projeto (versão exata não medida) , semente é copiada pra pasta da pessoa e vira arquivo dela

**Decisão:** semente vive em `seeds/`, deliberadamente fora de `skills/`, e o plantio é uma cópia pra `.claude/skills/` da pasta da pessoa. Copiada, ela é arquivo dela: editável, auto-modulável, e nenhuma atualização do plugin toca nela. Colisão oferece manter a dela (default), plantar com outro nome ou mostrar o diff; sobrescrever não é opção em nenhum fluxo.

**Por quê:** resolve a tensão entre atualizar o produto e preservar a customização. A tese do produto é que o sistema se molda à pessoa, e isso exige que ela edite as skills; skill que o update sobrescreve não pode ser editada. `seeds/` fora de `skills/` é o mecanismo, e não convenção de organização: o Claude Code só registra como skill o que está em `skills/`, então a semente não vira comando do plugin nem colide com a cópia plantada dela.

**Custo:** melhoria e correção de bug no catálogo alcançam só plantios futuros. A base instalada fica na versão que plantou, e o plugin não tem canal pra chegar nela. Isso faz de toda mudança de contrato em semente um trabalho de 3 partes: editar o catálogo, escrever a detecção em alguma skill que a pessoa roda de novo, e declarar o sintoma silencioso, porque o que não dá erro ninguém procura. A camada de capacidades foi o primeiro caso concreto, e é de lá que vêm o passo 4 do `conectar` (abrir cada consumidora e conferir a referência) e o passo 6 do `fechar-semana` (reconferir na cadência semanal).

**Onde vive:** `skills/plantar/SKILL.md:8` e `:14`, `skills/setup/SKILL.md:196-206`, `README.md:47`, `patterns/seed-model.md`.

## Origem do projeto (versão exata não medida) , o `PROMPT.md` é espelho do setup pra quem não instala o plugin

**Decisão:** `PROMPT.md` carrega o setup em bloco colável pra qualquer agente com acesso a arquivos, e é mantido como espelho do `skills/setup/SKILL.md`: mudança de régua, de princípio, de anti-padrão ou de arquitetura de memória passa nos dois arquivos no mesmo change.

**Por quê:** a instalação do plugin é onde a pessoa desiste (3 comandos, marketplace, reload de plugins), e o setup é a parte que define a qualidade de todo o resto. O canal colável foi como as primeiras pessoas usaram o sistema, e ele mantém o produto ao alcance de quem trava na instalação ou trabalha em outro agente.

**Custo:** duas fontes pro mesmo conteúdo, sem teste que as compare, e a divergência é a falha esperada. Ela já existe: medido em 06/08/2026, o `PROMPT.md` espelha a régua de 4 destinos no princípio 1, mas a lista de pastas propostas omite a pasta do módulo compartilhado, então quem segue o PROMPT recebe o quarto destino descrito e sem lugar declarado pra morar. O espelho cobre a régua, os princípios, a postura, os anti-padrões, o rigor, a memória e o discovery. Sementes e canal de atualização ficam fora por escopo, declarado no README e no topo do próprio `PROMPT.md`.

**Onde vive:** `PROMPT.md`, `README.md:85`, `skills/setup/SKILL.md`.
