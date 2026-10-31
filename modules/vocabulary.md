**Loaded by:** setup, plant, create-skill, connect (plugin skills).

# Folder vocabulary

This file is the single source of the names the plugin and the planted seeds use, for the agent. It is also a template: setup copies it to `.claude/skills/_shared/vocabulary.md` in the person's folder, with the line `**Language:** <language>` under `**Loaded by:**` and a single column, this folder's, holding the names as they stood after review.
An older folder gets that copy only with the person's ok, and the copy records its legacy names as they are, without renaming anything.

## Fixed names

The same in every language, because a script or a skill reads them by name.

| name | read by name by |
|---|---|
| `CRITICAL_FACTS.md`, `AGENTS.md`, `CLAUDE.md`, `memory/` | hook, every seed |
| `navigation.md` (new folder) | hook, `absorb`, session routine in `AGENTS.md` |
| `setup-notes.md` | `setup` (resume), `connect` |
| `tells-draft.md` (temporary) | `remove-ai-tells` |
| `.claude/rules/`, `.claude/skills/`, `.agents/skills` | Claude Code, Codex, bridge |
| `.claude/skills/_shared/capabilities.md`, `write-gate.md`, `tells.md`, `vocabulary.md` | seeds and plugin skills |
| seeds `start-day`, `close-day`, `close-week`, `prep-conversation`, `process-meeting`, `absorb` | `plant`, `setup`, bridge (folder name in `.claude/skills/` and the `/<name>` command) |
| plugin skills `setup`, `plant`, `create-skill`, `connect`, `remove-ai-tells` | Claude Code (`/pm-chief-of-staff:<name>`), Codex |

## Person-facing vocabulary

Names that follow the person's language. The `pt-BR` column is exactly what 0.7.0 creates, so an 0.7.0 folder is a pt-BR folder. In another language, setup translates the `en` column with the person while proposing the structure and records the result in the folder copy, together with any folder the person renamed in review.

| role | en | pt-BR |
|---|---|---|
| context folder | `context/` | `contexto/` |
| people folder | `people/` | `pessoas/` |
| projects folder | `projects/` | `projetos/` |
| meetings folder | `meetings/` | `reunioes/` |
| reference folder | `reference/` | `referencia/` |
| weekly journal folder | `journal/` | `diario/` |
| tools and sources | `context/tools-and-sources.md` | `contexto/ferramentas-e-fontes.md` |
| rituals | `context/rituals.md` | `contexto/rituais.md` |
| pains | `context/pains.md` | `contexto/dores.md` |
| trajectory | `context/trajectory.md` | `contexto/trajetoria.md` |
| saved discovery | `context/discovery-YYYY-MM-DD.md` | `contexto/discovery-YYYY-MM-DD.md` |
| agenda | `meetings/{name}/YYYY-MM-DD agenda.md` | `reunioes/{nome}/YYYY-MM-DD pauta.md` |
| meeting note | `meetings/{person-or-ritual}/YYYY-MM-DD.md` | `reunioes/{pessoa-ou-ritual}/YYYY-MM-DD.md` |
| date format in labels | `YYYY-MM-DD` | `DD/MM` |
| today's 3 block | `## Today's 3: YYYY-MM-DD` | `## 3 do dia , DD/MM` |
| balance | `**Balance:** {N}/3, {reason}` | `**Balanço:** {N}/3 , {motivo}` |
| seed for tomorrow | `**→ tomorrow:**` | `**→ amanhã:**` |
| reflection | `**Reflection:**` | `**Reflexão:**` |
| week close | `## Week close: YYYY-MM-DD to YYYY-MM-DD` | `## Fechamento da semana , DD/MM a DD/MM` |
| hub section: context | `Context` | `Contexto` |
| hub section: facts | `Facts` | `Fatos` |
| hub section: current reading | `Current reading` | `Leitura vigente` |
| hub section: recent signals | `Recent signals` | `Sinais recentes` |
| hub section: history | `History` | `Histórico` |
| superseded mark (hub) | `superseded on YYYY-MM-DD by {what superseded it}` | `superada em DD/MM por {o que a superou}` |
| superseded mark (write gate) | `superseded on YYYY-MM-DD by {what superseded it}` | `superado em DD/MM por {o que o superou}` |
| expired mark | `expired on YYYY-MM-DD` | `expirado em DD/MM` |
| rules index heading | `## Rules by topic` | `## Regras por assunto` |
| rules index, empty | `no rules yet` | `nenhuma regra ainda` |
| rules index, order | `Before acting on a topic in this index, read its rule.` | `antes de atuar num assunto do índice, leia a regra dele` |
| note frontmatter: type | `type: meeting-note` | `tipo: nota-de-reuniao` |
| note frontmatter: with | `with:` | `com:` |
| note frontmatter: date | `date:` | `data:` |
| note section: context | `**Context:**` | `**Contexto:**` |
| note section: raw | `**Raw:**` | `**Bruto:**` |
| note section: decisions | `## Decisions` | `## Decisões` |
| note section: tasks | `## Tasks` | `## Tasks` |
| note section: signals | `## Signals` | `## Sinais` |
| note section: unresolved | `## Unresolved` | `## Não resolvido` |
| agenda section: open follow-ups | `## Open follow-ups` | `## Follow-ups abertos` |
| agenda section: decisions to make | `## Decisions to make` | `## Decisões a tomar` |
| agenda section: topics | `## Topics` | `## Tópicos` |
| agenda section: feedback | `## Feedback (1-2)` | `## Feedbacks (1-2)` |
| doubt mark | `to validate` | `a validar` |
| consumer line of `absorb` | `when I use this` | `quando eu uso isso` |
| log entry | `## [HH:MM] Topic` | `## [HH:MM] Tópico` |

## Agent-side labels

Labels inside `.claude/` are text for the agent: fixed in English in a new folder, with the 0.7.0 name accepted as legacy (next table).

| label | value |
|---|---|
| module consumer line | `**Loaded by:**` |
| capabilities, in module order | `today's calendar`, `email`, `messages`, `documents`, `meeting transcript`, `tickets`, `data warehouse`, `product analytics` |
| capabilities module columns | `capability`, `provider`, `how to call`, `without connector` |
| calendar section of the capabilities module | `## Calendar reading rules` |
| `tells.md` sections | `Tells I caught`, `My style, do not flag` |

## Legacy 0.7.0 names

What an 0.7.0 folder or the 0.7.0 plugin uses. Accepted wherever the plugin reads them; nothing in the plugin renames them in a person's folder.

| kind | 0.8.0 | legacy 0.7.0 |
|---|---|---|
| seed | `start-day` | `abrir-dia` |
| seed | `close-day` | `fechar-dia` |
| seed | `close-week` | `fechar-semana` |
| seed | `prep-conversation` | `preparar-conversa` |
| seed | `process-meeting` | `processar-reuniao` |
| seed | `absorb` | `absorver` |
| module | `_shared/capabilities.md` | `_shared/capacidades.md` |
| module | `_shared/write-gate.md` | `_shared/gate-de-escrita.md` |
| module | `_shared/tells.md` | `_shared/tells.md` |
| module | `_shared/vocabulary.md` | (none) |
| folder file | `navigation.md` | `navegacao.md` |
| folder file | `setup-notes.md` | `setup-notas.md` |
| folder file | `tells-draft.md` | `rascunho-tells.md` |
| agent label | `**Loaded by:**` | `**Carregado por:**` |
| capability | `today's calendar` | `agenda do dia` |
| capability | `email` | `e-mail` |
| capability | `messages` | `mensagens` |
| capability | `documents` | `documentos` |
| capability | `meeting transcript` | `transcrição de reunião` |
| capability | `tickets` | `tickets` |
| capability | `data warehouse` | `warehouse de dados` |
| capability | `product analytics` | `analytics de produto` |
| capabilities column | `capability` | `capacidade` |
| capabilities column | `provider` | `provider` |
| capabilities column | `how to call` | `como chamar` |
| capabilities column | `without connector` | `sem conector` |
| capabilities section | `## Calendar reading rules` | `## Regras de leitura de agenda` |
| `tells.md` section | `Tells I caught` | `Tells que eu flagrei` |
| `tells.md` section | `My style, do not flag` | `Meu jeito, não marcar` |
| plugin skill | `setup` | `setup` |
| plugin skill | `plant` | `plantar` |
| plugin skill | `create-skill` | `criar-skill` |
| plugin skill | `connect` | `conectar` |
| plugin skill | `remove-ai-tells` | `remove-ai-tells` |
| plugin file (repository only) | `modules/codex-bridge.sh` | `modulos/ponte-codex.sh` |
| plugin file (repository only) | `modules/capabilities.md` | `modulos/capacidades.md` |
| plugin file (repository only) | `modules/write-gate.md` | `modulos/gate-de-escrita.md` |
| plugin file (repository only) | `modules/vocabulary.md` | (none) |
| plugin file (repository only) | `hooks/boot-memory.sh` (keeps the execute bit) | `hooks/boot-memoria.sh` |
| plugin file (repository only) | `hooks/boot-memory-test.sh` (keeps the execute bit) | `hooks/boot-memoria-teste.sh` |
| plugin file (repository only) | `hooks/size-gate.sh` (keeps the execute bit) | (none) |
| plugin file (repository only) | `hooks/size-gate-test.sh` | (none) |
| plugin file (repository only) | `hooks/hooks.json` | `hooks/hooks.json` |
| plugin file (repository only) | `tests/codex-bridge-test.sh` | `testes/ponte-codex-teste.sh` |
| plugin file (repository only) | `tests/audit/codex-compat-final.sh` | `testes/auditoria/codex-compat-final.sh` |
| plugin file (repository only) | `.github/ISSUE_TEMPLATE/request-seed.md` | `.github/ISSUE_TEMPLATE/pedir-semente.md` |
| plugin file (repository only) | `.github/ISSUE_TEMPLATE/bug.md` | `.github/ISSUE_TEMPLATE/bug.md` |
| plugin file (repository only) | `agents/ai-tells-reviewer.md` | `agents/ai-tells-reviewer.md` |
| plugin file (repository only) | `.claude/skills/guia-pm-chief-of-staff/SKILL.md` (content in English) | `.claude/skills/guia-pm-chief-of-staff/SKILL.md` |
| plugin file (repository only) | `README.pt-BR.md`, `PROMPT.pt-BR.md` | (none) |

## Commands 0.7.0 to 0.8.0

No alias: a typed 0.7.0 plugin command is an unknown command in Claude Code, while a request in natural language still reaches the new skill. Seed commands follow the seed folder name, so an 0.7.0 folder keeps `/abrir-dia` and the rest.

| 0.7.0 | 0.8.0 |
|---|---|
| `/pm-chief-of-staff:setup` | `/pm-chief-of-staff:setup` |
| `/pm-chief-of-staff:plantar` | `/pm-chief-of-staff:plant` |
| `/pm-chief-of-staff:criar-skill` | `/pm-chief-of-staff:create-skill` |
| `/pm-chief-of-staff:conectar` | `/pm-chief-of-staff:connect` |
| `/pm-chief-of-staff:remove-ai-tells` | `/pm-chief-of-staff:remove-ai-tells` |
| `/abrir-dia` (seed in an 0.7.0 folder) | `/start-day` (seed in a new folder) |
| `/fechar-dia` | `/close-day` |
| `/fechar-semana` | `/close-week` |
| `/preparar-conversa` | `/prep-conversation` |
| `/processar-reuniao` | `/process-meeting` |
| `/absorver` | `/absorb` |
