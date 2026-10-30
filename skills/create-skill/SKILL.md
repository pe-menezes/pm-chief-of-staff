---
name: create-skill
description: Creates a new skill tailored to the person, from triage to the trigger test. Use when she asks to automate a process of her own: "create a skill for X", "automate Y for me", "I want you to always run this process", "turn this ritual into a skill", "cria uma skill de X", "automatiza Y pra mim", "quero que você sempre rode esse processo", "transforma esse ritual numa skill", or runs /pm-chief-of-staff:create-skill (named /pm-chief-of-staff:criar-skill up to 0.7.0). Do not use for a simple preference about behavior or format, which becomes a line in the folder's instruction file or a situational rule scoped to files (this skill's triage explains the destinations), nor to adjust a seed or skill already planted, which is a direct edit of its file.
---

# Create a skill

The person asked you to automate a process. The path has 4 steps: triage whether it really becomes a skill, write the skill, test the trigger with her and plant it in her folder. Read this whole skill before proposing anything.

## Language and folder vocabulary

Triage, questions and every message to her go in her language: the one the folder's `AGENTS.md` sets (or `.claude/skills/_shared/vocabulary.md`, line `**Language:**`); without either, the one she writes in. The skill and the rule she creates are files she edits, so they are written in her language too, including the `description` and its trigger phrases, in the words she would use.

Folder names and labels come from the folder's vocabulary, never from memory. With `.claude/skills/_shared/vocabulary.md`, it rules. Without it, the folder is 0.7.0 when it has `navegacao.md`, `setup-notas.md`, `_shared/capacidades.md`, `_shared/gate-de-escrita.md` or any seed folder with a 0.7.0 name (`abrir-dia`, `fechar-dia`, `fechar-semana`, `preparar-conversa`, `processar-reuniao`, `absorver`); then the pt-BR column of `<plugin root>/modules/vocabulary.md` and its legacy names apply. Without either evidence, ask her language in 1 line and follow the `AGENTS.md`. A new skill that mentions a folder, a label, a module or a seed uses the name this folder has (`diario/`, `_shared/capacidades.md`, `/abrir-dia` in an 0.7.0 folder), because a name the folder does not have sends the first write where nobody reads.

## Step 1: triage (not every request becomes a skill)

Only a repeatable workflow with its own trigger becomes a skill: a process with steps and a result, which the person will invoke again and which is recognizable in one sentence ("process the retro", "build the committee report"). A request that does not pass this filter has another destination:

* **Preference that holds in every interaction** (tone, response format, vocabulary): 1 line in the folder's instruction file (the `AGENTS.md`; in a folder set up before 0.6, which has no `AGENTS.md`, the `CLAUDE.md`). In a new folder, the one-line `CLAUDE.md` (`@AGENTS.md`) is the bridge and never receives a rule.
* **Situational rule for a topic or file type** ("when touching a meeting note, do X"): a rule file that only loads when the work touches those files, and the folder's instruction file stays light (the mechanics are in the implementation layer, below).
* **Discipline for an execution step that 2 or more skills need** ("before writing the note, apply this"): shared module in `.claude/skills/_shared/{name}.md` (mechanics in the implementation layer, below). If only one skill needs it, it is a file in that skill's folder. And `.claude/rules/` does not replace the module: a rule with `paths:` fires when a file is touched, and a "before writing" discipline has to load in the middle of the execution, before the file exists.
* **Adjustment to a skill that already exists** (planted seed or skill created before): direct edit of that skill. A new skill with a trigger next to an existing one competes with it for firing.

Say which destination the request has and why, and go on to step 2 only with the person's confirmation.

## Step 2: write the skill

A skill is an instruction for an agent, and the constraints that hold for any instruction hold here: context is finite, a long instruction degrades any model, a vague trigger does not fire in any agent. The authoring rules come from these constraints:

* **description in the 3rd person: the WHAT + WHEN.** What the skill does, when to use it (with the terms the person herself would use to ask) and when NOT to use it, pointing to the right destination. The description decides the firing and the body is only read afterwards: a vague trigger does not fire.
* **The body is a light guide that trusts the model's judgment.** Goal, steps and the person's format decisions, without prescribing what the agent solves on its own: a long instruction degrades the whole execution. A rigid rule only in a fragile or destructive step (overwriting, deleting, sending something out), and always with the why: a rule without a why breaks on the first case it did not foresee, and the why is what guides the new case.
* **Progressive disclosure.** Short body; a long template, reference table or detail that only serves part of the runs goes to a separate file in the same skill folder, which the body points to. The detail should only take up context when the run needs it.
* **An artifact has a target in numbers.** A skill that generates a file declares the target ("note of up to 25 lines", "1 line per item"); without a number the output grows with every run.
* **No canned usage examples.** A ready dialogue and a model output constrain exploration: the agent starts imitating the example instead of solving the real case.
* **The skill encodes the PERSON's opinion and way of doing things.** Her agenda format, her vocabulary, what she considers done. A generic process that would serve anyone carries no opinion and does not need a skill.

### Implementation layer (the mechanics of each destination)

In Claude Code: a skill is a folder with `SKILL.md` and the description in the frontmatter; a situational rule is `.claude/rules/{topic}.md` with a `paths:` frontmatter (a list of globs; the rule loads only when the work touches those files) and one line in the rules index of the `AGENTS.md`; and `/doctor prompt-audit`, run from time to time, is the audit of the folder's instruction file, the rules and the skills.

A shared module is `.claude/skills/_shared/{name}.md`: a folder without `SKILL.md` is inert to the skill scanner, so the module does not become a ghost skill. The first line declares who loads it (`**Loaded by:**`; an 0.7.0 folder uses `**Carregado por:**`, and its modules keep it), because a module without a declared consumer never fires and nobody notices. **There is no automatic loading:** creating a module includes editing each consumer skill to tell it to read the file at the right step, and a skill that forgets to reference it loses the discipline silently. In Codex: the `AGENTS.md` is already the instruction file it loads, and skills arrive through `.agents/skills`, the bridge to `.claude/skills` (step 4). It does not read the rule's `paths:`: what carries the rule to it is the rules index of the `AGENTS.md`, one line with the topic and the path in `.claude/rules/`, under the order to read the rule before acting on the topic. A new rule includes the line in the index in the same step; without it, the rule holds only in Claude Code.

The index is the one the folder already has. Look for its heading in the `AGENTS.md` by the folder's vocabulary label: `## Rules by topic` in a new folder in English, `## Regras por assunto` in a pt-BR or 0.7.0 folder, the translated heading recorded in `_shared/vocabulary.md` in another language. The new line goes under that heading. Never create a second index in another language next to the one that exists. An older folder without the index gets the section, with the heading and the order line of the folder's vocabulary, along with the first rule, after the person's ok.

Provenance of the authoring rules: "The new rules of context engineering for Claude 5 generation models" (https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models), the post that documents an agent system prompt cut by more than 80% without measurable loss.

## Step 3: trigger test

Before creating the file, propose 2 to 3 sentences that should fire the skill and 1 to 2 neighbors that should not (saying what serves each neighbor: another skill, the folder's instruction file, a rule), in her language. The person validates: a sentence she would never say leaves the description; a collision with an existing skill goes back to step 1.

## Step 4: plant

Create the skill in `.claude/skills/{name}/` of the person's folder, never in the plugin. The file is hers: editable, self-modulating, out of reach of any plugin update. A `{name}` folder that already exists in `.claude/skills/` is her skill: never overwrite it, go back to the name with her.

Once the skill is created, run `sh "<plugin root>/modules/codex-bridge.sh"` in her folder, with the path in quotes. The plugin root is `${CLAUDE_PLUGIN_ROOT}`; if the variable does not resolve, the folder two levels above this SKILL.md; only without it, the `pm-chief-of-staff` plugin folder in the plugin cache of the agent in use. The bridge keeps `.agents/skills` pointing to `.claude/skills`, which is how Codex finds the new skill, and running it again does not touch what is already linked. Say first, in 1 sentence, that running the command may ask for permission. Exit 2 is something of the person's in the way, left intact: show the conflict lines and decide with her, never delete, rename or merge on your own. Exit 1 or command denied: say that in Codex the skill stays undiscovered until the bridge runs. If the `name` or `description` of one of her skills changes later, run the bridge again: in a folder without a link (one wrapper per skill), it is the bridge that carries the new frontmatter to Codex.

The command (`/{name}`) registers in the next session; to test now, read the SKILL.md you created and follow its content directly.
