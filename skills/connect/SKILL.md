---
name: connect
description: Maps what this session can fetch on its own (today's calendar, email, messages, documents, meeting transcript, tickets, data warehouse, product analytics) and writes it to the module `.claude/skills/_shared/capabilities.md` in the person's folder (`_shared/capacidades.md` in a folder from 0.7.0), which the routine skills read before asking. Use when the person runs /pm-chief-of-staff:connect (named /pm-chief-of-staff:conectar up to 0.7.0), in the tools block of setup, when she gains or loses a connector, says "why don't you pull my calendar?", "hook this up to my calendar", "por que você não puxa minha agenda?", "liga isso no meu calendário", or after changing companies. Do not use to install or authenticate a connector (that is agent configuration, out of this skill's reach), nor to create a new skill (create-skill).
---

# Connect the sources

Infrastructure skill: it runs in setup and again when the person's toolbox changes. It produces no note and does not enter the daily routine.

Every message to the person goes in her language: the one the folder's `AGENTS.md` sets (or `.claude/skills/_shared/vocabulary.md`, line `**Language:**`); without either, the one she writes in. The module is text for the agent and stays in English in a new folder; the `provider` and `how to call` cells hold what she says, as she says it.

## The yardstick (it is the reason the layer exists)

**A skill cites a capability, never a tool name.** `start-day` asks for "today's calendar"; which connector answers that is the module's problem. Switching providers (she changed companies, the calendar became another one) is editing one line in the capabilities module, without opening any skill. A tool name copied into 3 skills breaks in 3 places the day it changes, and the copies already diverge before that, at the first one someone edits without looking at the others.

## Which file

The module is one file per folder, and the choice is made before step 1:

* `.claude/skills/_shared/capabilities.md` exists: that is the module.
* Only `.claude/skills/_shared/capacidades.md` exists (folder from 0.7.0): that is the module. It is updated in place, with its own names (capability column `capacidade`, columns `como chamar` and `sem conector`, capabilities `agenda do dia`, `e-mail`, `mensagens`, `documentos`, `transcrição de reunião`, `tickets`, `warehouse de dados`, `analytics de produto`, section `## Regras de leitura de agenda`), and `capabilities.md` is never created next to it, because the 0.7.0 seeds (`abrir-dia`, `processar-reuniao`, `preparar-conversa`) read `capacidades.md` and a second file would leave them reading the one that does not change.
* Both exist: show both to the person, say which one each consumer reads (step 4), and update only the one she picks. Never merge, rename or delete either one, because both are hers.
* Neither exists: the module is born as `capabilities.md` (step 3).

## Flow

1. **Look at what the session already has.** Say in capability language what you can exercise right now with this session's tools ("I can read your calendar", "I can search files in the drive"). Where you are not sure, ask instead of guessing: a capability declared without existing makes the consumer skill try, fail and stumble in the middle of its flow.
2. **Ask what is missing, without jargon, going through the whole table.** Where her meetings live, where the transcripts come from, where the work conversation happens, where the email lives, where the documents are, where the team's tasks are, and where the data is (the business number and user behavior in the product). She answers with a product name, and the translation to a connector is yours. A capability that no skill reads today is filled in the same way: it is what her next skill will read instead of asking everything again.
3. **Write the module** chosen in "Which file". A new one goes to `.claude/skills/_shared/capabilities.md` in her folder, from the template in `${CLAUDE_PLUGIN_ROOT}/modules/capabilities.md` (if the variable does not resolve, the plugin root is the folder two levels above this SKILL.md; only without it, locate the `pm-chief-of-staff` plugin folder in the plugin cache of the agent in use). Fill in only the lines the person confirmed, always with `provider` and `how to call` together (`como chamar` in `capacidades.md`), because `how to call` is what the consumer skill executes and a provider alone makes it try without instruction; the rest stays with both cells empty. **Called by setup, in the middle of discovery, this step does not write:** the conversation happens, the result stays in `setup-notes.md` (or in `setup-notas.md` when setup is resuming an 0.7.0 discovery that already uses it), and the file (with steps 4 and 5) is left for planting, because setup promises she reviews everything before any file exists.
4. **Check the consumers.** Open each skill declared in the module's consumer line (`**Loaded by:**`, or `**Carregado por:**` in an 0.7.0 module) and see whether it references the module (`capabilities.md` or `capacidades.md`, whichever this folder has) at the step where it fetches data. A declared consumer is found in `.claude/skills/` by its name or by its 0.7.0 name (`start-day` or `abrir-dia`, `process-meeting` or `processar-reuniao`, `prep-conversation` or `preparar-conversa`). A skill that does not reference it changes nothing with the module written: it keeps asking. That is the case of whoever planted the seeds before this layer existed, and the only way to know is to open and look. Offer the edit one by one and **never edit without the ok**, because a planted skill is her file.
5. **Close by saying what changes the next day:** which skills start pulling data on their own, which keep asking and which are waiting for the ok from step 4. Without this line the person expects automation that did not arrive.

## Running again (the most common case)

If the module already exists: read it, show the current table and ask what changed. Update line by line and **never rewrite from scratch**, because the file is hers and may have been edited by hand. Each edit touches only the cells of the line she confirmed, with the capability and column names the file already has; lines, sections and the consumer line she did not mention stay byte for byte. A provider that left clears both cells, not one; never leave a line pointing to a tool that no longer answers. Also check whether the calendar reading section (`## Calendar reading rules`, or `## Regras de leitura de agenda` in `capacidades.md`) exists after the table; if missing, offer to add it (the file is hers: only with the ok), in the language the file already uses. Step 4 runs again along with it.

## Limits (tell the person this, it is not a detail)

* **There is no automatic loading.** The module enters context only when a skill tells it to be read, and step 4 is what checks that. A new skill that fetches outside data needs to point to it too.
* **Installing and authenticating a connector is not done here.** That is agent configuration (in Claude Code, `/mcp` and the account's connectors; in Codex, the MCP servers and apps in its configuration). This skill maps what exists and writes the map.
* **The module is her file.** A plugin update does not touch it, and a future improvement to the template does not reach whoever already ran it: running this skill again is the way.
* **No company-internal tool name goes into the module as a default.** Fill in what the person uses, and only that.
* **A connector turned on now only exists in the next session.** The tool list loads at startup; on detecting that the person just turned something on, say so and agree to rerun connect in the next session.
* **The absence of a capability is stated only after measuring.** Before saying a connector is not in the session, list the tools present and prove it with a cheap read call; stating it without measuring has already produced a real error, with the list loaded and the proof call undoing the statement.
