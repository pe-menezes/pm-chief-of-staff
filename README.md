# pm-chief-of-staff

[Read in Portuguese (pt-BR)](README.pt-BR.md)

**A personal Chief of Staff for people who work in product.** You open Claude Code or Codex in an empty folder and ask for the setup. It interviews you about who you are, what you cover, who works with you and where the pain points are. Your answers become your system, with a folder structure, layered memory, routine skills, and an agent that processes your meetings, prepares your hard conversations, keeps track of everything and calls you out when you are fooling yourself.

There is no ready-made template here. **The system is built from your discovery and adapts to you through use.**

> It comes from the system I have used every day for months as a product person, which other people in my circle have adopted and adapted to their own way of working. This version is for anyone in product: PM, GPM, head of product, APM, people who lead a team and people who do not (the discovery asks, and the system adjusts).

## What you need first

1. **One of the two agents, running on your computer:** **[Claude Code](https://claude.com/claude-code)**, by Anthropic (Mac or Windows), or **Codex**, by OpenAI, in the desktop app or the CLI.
2. **An account for the agent you chose:** a Claude subscription (Pro or higher) for Claude Code, or an OpenAI account whose plan includes Codex. The plugin itself is free.
3. Nothing else. You do not need to know how to code, and you do not need Obsidian or Notion (the system is a folder of markdown files that any editor can open, and it also works well as an Obsidian vault). If you have never used a terminal, paste this page into Claude itself and ask for help.

## Installing in Claude Code (3 steps, about 5 minutes)

**1.** Create a new folder (in Documents or on the Desktop, with any name you like: `my-cos`, `second-brain`). Open Claude Code inside it.

**2.** Install the plugin by pasting the three commands (the third loads the plugin into the open session; without it, the command in step 3 shows up as "Unknown command"):

```
/plugin marketplace add pe-menezes/pm-chief-of-staff
/plugin install pm-chief-of-staff@pm-chief-of-staff
/reload-plugins
```

**3.** Run the setup and answer as you go:

```
/pm-chief-of-staff:setup
```

The conversation and the files follow your language, and any language works. The bare command opens in English and tells you that you can answer in any language; your first answer sets it. Words after the command set it from the start (`/pm-chief-of-staff:setup monta meu chief of staff` opens in Portuguese).

There are 7 blocks of questions, about 20 to 30 minutes of conversation. At the end it proposes the folder structure, named in your language, and `AGENTS.md` (the "instruction manual" it will follow). **You review everything before any file is created**, and then it plants the starter skills in your folder. The one exception is `setup-notes.md`, where it saves your answers during the discovery so it can pick up where it left off if the session drops. During the planting, Claude may ask for your permission (how many times depends on what you have already allowed) for three things: reading the skills that come with the plugin, creating their files in your folder, and running the bridge that gets the folder ready for Codex (see [The same folder in Claude and Codex](#the-same-folder-in-claude-and-codex)). Accept the read and create requests, because without them the commands will not be created. The bridge request only matters if you also plan to open the folder in Codex. Do not start 15 minutes before a meeting, because the rest of the system is built from your discovery answers.

## Installing in Codex (desktop app or CLI)

**1.** In the terminal, register the marketplace and install the plugin:

```
codex plugin marketplace add pe-menezes/pm-chief-of-staff
codex plugin add pm-chief-of-staff@pm-chief-of-staff
```

In Codex the command is `plugin add` (`plugin install` is the Claude Code form). The plugin is not listed in OpenAI's plugin directory, so you install it from this repository.

**2.** Create the new folder and open a **new session** of Codex inside it. A session that was already open before the install does not see the plugin.

**3.** Ask for the setup in natural language, for example "run the pm-chief-of-staff setup" or "build my chief of staff". The language you ask in becomes the language of the conversation and of the files. The discovery, the proposal and the review are the same as in Claude Code, and apart from `setup-notes.md`, nothing is created until you approve it.

The plugin also ships two hooks: the memory load at session start (see [The memory](#the-memory)) and the size gate at the end of each turn (see [Where is my data?](#where-is-my-data)). **Installing the package does not authorize the hooks.** Codex asks you to trust them through its normal hook approval mechanism; until you approve them, the session opens without the memory load and without the size gate, and `AGENTS.md` still tells the agent to read the same files.

During planting, the setup runs the Codex bridge in your folder (see [The same folder in Claude and Codex](#the-same-folder-in-claude-and-codex)). A sandbox that does not allow creating `.agents/` blocks this step, and the agent stops there and tells you. In that case, ask it for the bridge command with the full path filled in and read it. Then either approve it through Codex's normal approval request or run it yourself in your terminal, from inside the folder. Without the bridge the folder still works, but the planted skills do not show up in Codex.

## What comes planted (and why "planted" matters)

Planting is copying a seed skill (the starter that ships in the plugin) INTO your folder, and the setup starts by planting 5:

| Skill | What it does |
|---|---|
| `start-day` | calendar + backlog + today's 3, anchored in your priorities |
| `close-day` | reviews today's 3, sorts what did not get done, picks tomorrow's #1 |
| `prep-conversation` | agenda for a 1:1 (direct report or your manager), a peer or a stakeholder, based on what is already in your folder |
| `process-meeting` | paste the transcript, get a structured note + propagation to the right places |
| `absorb` | files a doc, article or process in your system, with a home, a summary that cites its source and a line saying when it will be used |

From the moment they are planted, **these skills are your files**. Want the 1:1 agenda to always have a recognition section, or start-day to include your dashboard? Tell the agent and it edits the skill. Future updates will improve the setup and the plugin skills and add new seeds to the catalog (`/pm-chief-of-staff:plant` lists what is there).

The catalog also has **`close-week`**, which rolls up the daily wrap-ups, pushes you to make the decisions the week left open, checks the health of the system's memory (the files every session loads, against their size targets), keeps notes on how you are progressing (material for your performance review) and sets up next week's journal. Plant it at the end of your first week: `/pm-chief-of-staff:plant close-week`.

Also in the plugin: **`/pm-chief-of-staff:connect`**, which records, in a single file, what the agent can pull on its own (calendar, transcripts, messages, tickets), so the routine skills stop asking you for what it can already fetch. The setup runs it for you. If you planted skills before `connect` existed, it checks which of them still ask you for that material and offers to edit each one.

**`/pm-chief-of-staff:remove-ai-tells`** reviews a text you are about to send. A reviewer agent, which did not write the text, points out the tells of AI-generated writing (antithesis in series, punchlines, em dashes). You see the before and after of each excerpt. Only the changes you approve are applied to the original.

The commands with the `/pm-chief-of-staff:` prefix are the Claude Code form. In Codex, ask by name in natural language ("plant close-week", "remove the tells from this text").

## The same folder in Claude and Codex

The folder you build opens in both agents, and every file in it exists only once:

* **A single source for your skills.** They live in `.claude/skills/`, and every edit is made there. Codex looks for skills in `.agents/skills/`, so the bridge (`modules/codex-bridge.sh`, run by setup, plant and create-skill) points `.agents/skills/` at `.claude/skills/` with a relative link. Where a link is not possible, it writes one short `SKILL.md` per skill that says to read the source. An edit made in the source shows up in the next Codex session.
* **The bridge does not overwrite anything it did not create.** If you already had a `.agents/skills` folder, it stays in use: the bridge only adds the missing entries there, one per skill. An entry with the same name that the bridge did not create (a file, a link or a skill of yours) stays as it is and goes on the conflict list, for you to decide with the agent. If `.agents/skills` is already a link of yours or a file, the bridge writes nothing there and also reports a conflict. It only rewrites the short files it generated itself, so running it again is safe.
* **Situational rules are loaded through the index.** Codex does not read the `paths:` of the rules in `.claude/rules/`. The generated `AGENTS.md` has a rules index section (`## Rules by topic` in an English folder, `## Regras por assunto` in a Portuguese one), one line per rule with the topic and the path, and tells the agent to read the rule before acting on that topic. A new rule is added to the index in the same step. A rule that is not in the index applies only in Claude Code.
* **The tells reviewer stays independent.** In Claude Code it is the plugin's named agent. In Codex, `remove-ai-tells` opens a new subagent, without the conversation history and with read-only instructions. If the session has no subagents, it tells you that no separate reviewer read the text.

Known limits: the bridge depends on the session being able to write `.agents/` in the folder (if the sandbox refuses, see [Installing in Codex](#installing-in-codex-desktop-app-or-cli)). On Windows without symbolic link permission, the bridge falls back to the short per-skill files; the automated test suite covers that path, but nobody has run it on a Windows machine yet.

## The memory

The agent's memory is its files, and anything written in the folder is loaded by every future session. The system starts with 4 layers, all in readable markdown:

* **`CRITICAL_FACTS.md`**: the live state (your priorities with numbers, active events). Read at the start of every session, it exists so the agent never asks you again what has already been decided.
* **`memory/`**: the daily log, dated and immutable. Each entry records what happened and when, and points to where the details are.
* **People and project hubs**: what has stabilized, along with recent signals and history.
* **`AGENTS.md` and the skills**: how it works with you, and the layer that changes when you ask for a change.

The manual lives in `AGENTS.md`, which Claude Code, Codex and Cursor read. Next to it sits a `CLAUDE.md` with a single line, `@AGENTS.md`, which makes Claude Code load the manual. Do not delete that file, and do not write rules in it. A folder built before 0.6 keeps its manual in `CLAUDE.md` and works in Claude Code as it is. Codex reads `AGENTS.md` and skips `CLAUDE.md`, so that folder opens in Codex without the manual. In Codex, the planted skills are loaded through the bridge and the rules through the index in `AGENTS.md` (see [The same folder in Claude and Codex](#the-same-folder-in-claude-and-codex)).

The daily loop runs on its own. `start-day` reads what yesterday's `close-day` left for it, and `close-day` moves anything still unfiled in the log into the hubs. After two weeks of use, the agent knows your team, your projects and your patterns.

If the external engine `memoria-agente` is set up in the same folder, the two work together. This plugin provides the structure and the rituals, and the engine provides mechanical enforcement and takes over the memory load in Claude Code (the hook detects the engine and steps aside). In Codex, the plugin's hook always does the memory load. The telemetry the engine leaves in the folder does not prove that the engine is running in the current Codex session, so the hook registered for Codex does not step aside because of it. The same split holds for the size gate: with the engine alive in Claude Code, the plugin's gate leaves `CRITICAL_FACTS.md` to the engine, which measures it only when the engine's own gate is turned on, and keeps measuring the manual; in Codex the plugin's gate measures both.

## Where is my data?

**It stays on your computer and nowhere else.** The whole system is a folder of markdown that you open, read, version and delete whenever you want. Nothing is sent to me, and the plugin installs no server, connector or MCP integration. It has three short scripts, all local, and you can read each one in full in 2 minutes:

* **`hooks/boot-memory.sh` runs at session start and only reads.** It reads from your own folder the state (`CRITICAL_FACTS.md`), the index (`navigation.md`, and the older `navegacao.md` if there is one) and the day's log, or the latest dated log when today has none, and puts into the conversation a pack of at most 8,000 bytes: the start of the state, the latest headings of that log and the start of the index, and it ends by saying what was left out. It runs when the session opens and again after the conversation is compacted, so the agent keeps knowing where things are. It also reads the machine's name and, in Claude Code, checks whether `.claude/memoria-config.json` and recent telemetry of the `memoria-agente` engine for this machine exist. It writes nothing and sends nothing anywhere.
* **`modules/codex-bridge.sh` writes locally during planting.** It runs when setup, plant or create-skill ask for it, with your permission, and writes only inside `.agents/` in your folder (the link or the short files that point to your skills).
* **`hooks/size-gate.sh` measures sizes on each request and at the end of each turn.** It runs only in a Chief of Staff folder (one with `CRITICAL_FACTS.md` and either `CLAUDE.md` or `AGENTS.md` with the index, as setup builds it). It reads the sizes in bytes of `AGENTS.md`, `CLAUDE.md` and `CRITICAL_FACTS.md`. It also reads the machine's name and, in Claude Code, checks whether `.claude/memoria-config.json` and recent telemetry of the `memoria-agente` engine for this machine exist. It writes one small file per session, with those sizes and the path of your folder, in the plugin's own data folder, outside your folder, and deletes its own files there once they are more than a month old. It sends nothing anywhere. The effect: a turn that makes the manual (`AGENTS.md` plus `CLAUDE.md`) or `CRITICAL_FACTS.md` grow and end above its cap (13,000 and 3,900 bytes) goes back to the agent once, with the curation to do in three buckets (consolidate, move, and deletions, which are yours to decide), and the agent can answer in one line why the growth was intentional. A turn that does not make those files grow passes in silence. Known limits: the turn in which the folder becomes a Chief of Staff is not measured, and an edit made outside a session is not judged. When the script cannot record the start of a turn, the gate stays quiet, because it never stops a turn without a measured start.

Plugin updates never touch your files, your planted skills, or your `AGENTS.md` or `CLAUDE.md`, and none of the three scripts deletes, renames or replaces any file of yours.

The conversation itself falls under the policies of your agent's provider, which is Anthropic for Claude Code and OpenAI for Codex.

One thing is on you: meeting and 1:1 transcripts carry sensitive data about other people. Before pasting company material, check your company's AI policy (Claude's Team and Enterprise plans have their own data controls).

## Updates

* **Automatic (recommended):** run `/plugin` once, go to the **Marketplaces** tab, select `pm-chief-of-staff` and turn on **Enable auto-update**. New versions arrive on their own, and you are notified.
* **Manual:** `/plugin marketplace update pm-chief-of-staff` whenever you want to check.
* **In Codex:** `codex plugin marketplace upgrade pm-chief-of-staff` in the terminal, then start a new session.

An update replaces only the plugin (setup, plugin skills and the seed catalog).

**A folder built before 0.9.0:** the session routine in its manual (`AGENTS.md`, or `CLAUDE.md` in a folder from before 0.6) still says to read the most recent log in full. The session-start pack now brings the headings of that log, so you can ask the agent to change that line to reading the headings and reading an entry when it needs one. The plugin does not change anyone's manual, so that edit is yours to ask for.

**Updating to 0.10.0:** in Codex, review and trust the plugin's hooks when Codex asks, because this version brings two and Codex holds a new or changed hook for review until you trust it. If your folder has its own end-of-turn check on the manual (a local `Stop` hook), remove it after updating, because the plugin now does that check.

## Upgrading from 0.7

In 0.8.0 the plugin is written in English, and the commands and seeds have English names:

| 0.7 | 0.8 |
|---|---|
| `setup` | `setup` |
| `plantar` | `plant` |
| `criar-skill` | `create-skill` |
| `conectar` | `connect` |
| `remove-ai-tells` | `remove-ai-tells` |
| `abrir-dia` | `start-day` |
| `fechar-dia` | `close-day` |
| `fechar-semana` | `close-week` |
| `preparar-conversa` | `prep-conversation` |
| `processar-reuniao` | `process-meeting` |
| `absorver` | `absorb` |

The first five rows are plugin commands (`/pm-chief-of-staff:<name>` in Claude Code); the other six are seeds.

* **Nothing in your folder is renamed.** Folders, files, labels and modules keep the names they have, and the plugin reads them as they are.
* **Planted seeds keep their names and are still commands.** A seed planted as `abrir-dia` stays `abrir-dia` and still works both as a command and through its trigger phrases.
* **The old plugin commands no longer exist.** Typing `plantar`, `criar-skill` or `conectar` after the plugin prefix no longer works; the new name, or the same request in natural language ("plant close-week"), does the same thing.
* **In Codex**, if the session opens without the memory load after the update, approve the hook again, as in [Installing in Codex](#installing-in-codex-desktop-app-or-cli).

## Common problems

* **`/pm-chief-of-staff:setup` shows up as "Unknown command":** run `/reload-plugins` (step 2 of the install ends with it) or close and reopen the session.
* **The discovery got cut off (the session closed or the context ran out):** open the folder again and run the setup. It finds the `setup-notes.md` it was writing (`setup-notas.md` in a folder from 0.7) and resumes from the block where it stopped.
* **I planted a skill and the command (`/start-day`) does not show up:** a planted skill registers when the session opens. In a new session it is there, and the trigger phrase ("good morning") works the same way.
* **I connected my calendar (or email) and the agent does not see it:** a connector turned on while the session is open only appears in the next session. Close and reopen the session. If you do not use connectors, ignore this item: everything works by pasting the material.
* **In Codex, the planted skills do not show up:** the bridge either did not run or found a conflict. Check whether `.agents/skills` exists in the folder. If it does not, ask the agent to run the plugin's bridge again (plant also runs it) or follow the sandbox steps in [Installing in Codex](#installing-in-codex-desktop-app-or-cli). If the bridge listed conflicts, go through each line with the agent and decide what to do.
* **In Codex, the session opens without the memory load:** the hooks are still waiting for your approval (see [Installing in Codex](#installing-in-codex-desktop-app-or-cli)).

## Don't want to install the plugin?

Paste the content of [`PROMPT.md`](PROMPT.md) into any agent with file access (Claude Code and Codex included) and run the same setup by chatting with it. You end up with `AGENTS.md`, the one-line `CLAUDE.md` that points to `AGENTS.md`, the rules index and the skills in a single source, and Codex skill discovery is set up without overwriting anything that already exists. The plugin adds the seed skills, the `connect`, `create-skill` and `remove-ai-tells` skills, the session-start hook, the end-of-turn size gate, the bridge as a script and the update channel.

## Philosophy, in 4 principles

1. **You change the system by asking.** A change request becomes an edit to `AGENTS.md` or to the skill, on the spot, and the system adapts to the way you think.
2. **You have to read everything.** An error you do not catch propagates into the files every later session loads.
3. **It is a thought partner, not an obedient assistant.** Candor over validation, diagnosis before suggestion, and anti-patterns named on the spot (executing without questioning, escalating without a recommendation, a showcase without a "so what", naive optimism and, if you manage a team, the Super-Leader, the glorified babysitter, generic feedback and the hard decision postponed).
4. **The files are the memory:** the next session loads only what was written in the folder.

## Bug or missing seed

[Open an issue](../../issues/new/choose): there are templates for a bug and for a seed request. New catalog entries come from seed requests, and the request queue is public.

## License

MIT. Use it, adapt it, distribute it.
