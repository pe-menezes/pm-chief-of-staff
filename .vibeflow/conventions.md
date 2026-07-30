# Conventions

<!-- vibeflow:auto:start -->
## Idioma e escrita
- Todo conteúdo em pt-BR; termo técnico consagrado fica em inglês (via README.md e uso uniforme nos 11 arquivos).
- Cânone completo em `patterns/writing-canon.md`: sem travessão, tom factual, caça aos tells de IA. Vale pra qualquer arquivo novo do repo, inclusive estes docs.

## Estrutura de arquivos
- Skill do plugin: `skills/{nome}/SKILL.md`. Vira comando `/pm-chief-of-staff:{nome}` e carrega em toda sessão com o plugin instalado.
- Semente: `seeds/{nome}/SKILL.md`. Fora de `skills/` de propósito: não registra como skill até ser plantada (via `patterns/seed-model.md`).
- Diretórios e nomes de arquivo em kebab-case, sem acento (acento é permitido e correto no conteúdo, nunca em filename).
- Manifests em `.claude-plugin/`: `plugin.json` (name, description, version semver, author, homepage, license) e `marketplace.json` (o repo é o próprio marketplace, `source: "./"`).

## Frontmatter de skill
- Exatamente 2 campos: `name` (igual ao diretório) e `description`.
- description com 3 partes na ordem: o que faz, "Use quando" com frases literais entre aspas, "NÃO use" apontando a skill vizinha (via `patterns/skill-authoring.md`).

## Versionamento e commits
- Bump de `version` no plugin.json a cada mudança significativa de conteúdo (histórico: 0.1.0 → 0.1.1 → 0.1.2); é o que dispara o auto-update de quem instalou.
- Mensagem de commit: lowercase, pt-BR, formato "área: o que mudou" ou "vX.Y.Z: o que entrou" (via git log: "README: /reload-plugins como 3o comando da instalação").

## Comportamento das skills
- Side effect na pasta da pessoa sempre propõe antes de executar ("propõe, a pessoa valida antes de cravar").
- Sobrescrita de arquivo do usuário não existe: colisão oferece manter, renomear ou diff.
- Path do plugin resolve por `${CLAUDE_PLUGIN_ROOT}` com fallback declarado (cache de plugins).
- Referência dentro de semente aponta só pro sistema gerado (`pessoas/`, `reunioes/`, `contexto/`...), nunca pro plugin.

## Don'ts
- NÃO usar travessão (em dash ou en dash) em nenhum arquivo; única ocorrência permitida é dentro da regra que o proíbe.
- NÃO colocar semente em `skills/`: registraria como skill do plugin e colidiria com a cópia plantada do usuário.
- NÃO instruir sobrescrita de arquivo do usuário em nenhum fluxo; a alternativa é manter, renomear ou diff.
- NÃO adicionar dependência executável (script, hook, MCP obrigatório, pacote): a promessa do README é "não precisa saber programar" e zero dependência além do Claude Code.
- NÃO renomear rótulo ou path de contrato entre skills sem editar os dois lados no mesmo change (`patterns/system-contracts.md`); renomear contrato consumido por semente plantada é breaking change pra base instalada.
- NÃO criar promessa de comportamento sem o mecanismo do outro lado (anti-pattern registrado: "fechar dias e semanas" sem semente de semana).
- NÃO ancorar parsing em posição de texto ("primeira linha após o título"); ancorar em estrutura (frontmatter, rótulo declarado).
<!-- vibeflow:auto:end -->
