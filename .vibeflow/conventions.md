# Conventions

<!-- vibeflow:auto:start -->
## Idioma e escrita
- Todo conteúdo em pt-BR; termo técnico consagrado fica em inglês (via README.md e uso uniforme nos 15 markdown de produto).
- Cânone completo em `patterns/writing-canon.md`: sem travessão, tom factual, caça aos tells de IA. Vale pra qualquer arquivo novo do repo, inclusive estes docs e os comentários do hook.

## Estrutura de arquivos
- Skill do plugin: `skills/{nome}/SKILL.md`. Vira comando `/pm-chief-of-staff:{nome}` e carrega em toda sessão com o plugin instalado. Hoje são 4: `setup`, `plantar`, `conectar`, `criar-skill`.
- Semente: `seeds/{nome}/SKILL.md`. Fora de `skills/` de propósito: não registra como skill até ser plantada (via `patterns/seed-model.md`). Hoje são 6, e o setup planta 5 (`fechar-semana` fica pro primeiro plantio que a pessoa faz sozinha).
- Módulo compartilhado: template em `modulos/{nome}.md`, plantado em `.claude/skills/_shared/{nome}.md` da pessoa. A pasta `_shared/` nunca leva `SKILL.md`, senão o módulo vira skill fantasma.
- Hook: `hooks/hooks.json` (registro, auto-descoberto pelo Claude Code na raiz do plugin) + o script em `hooks/{nome}.sh`. Único executável do repo.
- Diretórios e nomes de arquivo em kebab-case, sem acento (acento é permitido e correto no conteúdo, nunca em filename).
- Manifests em `.claude-plugin/`: `plugin.json` (name, description, version semver, author, homepage, license) e `marketplace.json` (o repo é o próprio marketplace, `source: "./"`).
- `.gitignore` tem uma linha só: `.vibeflow/`. O mapa do repo não viaja no main público (via `decisions.md`).

## Frontmatter de skill
- Exatamente 2 campos: `name` (igual ao diretório) e `description`.
- description com 3 partes na ordem: o que faz, "Use quando" com frases literais entre aspas, "NÃO use" apontando a skill vizinha (via `patterns/skill-authoring.md`).

## Versionamento e commits
- Bump de `version` no plugin.json a cada mudança significativa de conteúdo (histórico: 0.1.0 → 0.1.1 → 0.1.2 → 0.1.3 → 0.2.0 → 0.3.0); é o que dispara o auto-update de quem instalou.
- Mensagem de commit: lowercase, pt-BR, formato "área: o que mudou" ou "vX.Y.Z: o que entrou" (via git log: "README: /reload-plugins como 3o comando da instalação", "v0.3.0: aviso dos dois pedidos de permissao no plantio").

## Comportamento das skills
- Side effect na pasta da pessoa sempre propõe antes de executar ("propõe, a pessoa valida antes de cravar").
- Sobrescrita de arquivo do usuário não existe: colisão oferece manter, renomear ou diff. Arquivo dela que já existe se atualiza linha por linha, nunca reescrito do zero.
- Path do plugin resolve por `${CLAUDE_PLUGIN_ROOT}` com fallback declarado (cache de plugins).
- Referência dentro de semente aponta só pro sistema gerado (`pessoas/`, `reunioes/`, `contexto/`, `.claude/skills/_shared/`...), nunca pro plugin.
- Skill que busca dado de fora cita capacidade e lê `.claude/skills/_shared/capacidades.md`; nome de ferramenta não entra em skill (via `patterns/system-contracts.md`, contrato 7).
- Todo passo que depende de capacidade declara o fallback ali mesmo: sem módulo, com a linha pela metade ou com busca falhando, a skill pergunta em 1 linha e segue.
- Skill de plugin não se invoca por comando de dentro de outra execução: lê o SKILL.md e segue.
- Passo que vai disparar pedido de permissão avisa antes, em 1 frase, e diz o que deixa de funcionar se for negado.

## Don'ts
- NÃO usar travessão (em dash ou en dash) em nenhum arquivo; única ocorrência permitida é dentro da regra que o proíbe.
- NÃO colocar semente em `skills/`: registraria como skill do plugin e colidiria com a cópia plantada do usuário.
- NÃO instruir sobrescrita de arquivo do usuário em nenhum fluxo; a alternativa é manter, renomear ou diff.
- NÃO adicionar dependência externa (pacote, MCP obrigatório, binário, chamada de rede, passo de instalação): a promessa do README é "não precisa saber programar" e nada além do Claude Code. Script próprio é permitido desde v0.2.0, sob 4 condições que `hooks/boot-memoria.sh` cumpre: POSIX sh, só utilitário de base (`wc`, `cat`, `ls`, `date`, `sort`, `tail`), gate defensivo que sai em silêncio fora de uma pasta de Chief of Staff, e erro nunca em stdout (stdout do hook vira contexto).
- NÃO renomear rótulo ou path de contrato entre skills sem editar os dois lados no mesmo change (`patterns/system-contracts.md`); renomear contrato consumido por semente plantada é breaking change pra base instalada.
- NÃO criar promessa de comportamento sem o mecanismo do outro lado (anti-pattern registrado em 30/07: "fechar dias e semanas" sem semente de semana, resolvido em v0.2.0).
- NÃO ancorar parsing em posição de texto ("primeira linha após o título"); ancorar em estrutura (frontmatter, rótulo declarado).
- NÃO mudar a régua de destinos em um lado só: `skills/setup/SKILL.md` e `PROMPT.md` são espelho um do outro, e `criar-skill` e `absorver` triam por ela (`patterns/instruction-routing.md`).
- NÃO criar módulo em `_shared/` sem editar as consumidoras e sem declarar na primeira linha do módulo quem o carrega: não há carga automática, e a falta de referência não dá erro.
- NÃO mexer em semente do catálogo assumindo que a correção chega em quem já plantou; a melhoria precisa de um caminho de detecção (`patterns/seed-model.md`).
<!-- vibeflow:auto:end -->
