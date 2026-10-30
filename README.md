# pm-chief-of-staff

[Read in Portuguese (pt-BR)](README.pt-BR.md)

**A personal Chief of Staff for people who work in product.** You open Claude Code or Codex in an empty folder, ask for the setup, and it interviews you: who you are, what you cover, who works with you, where things hurt. Your answers become your system: a folder structure, layered memory, routine skills, and an agent that processes your meetings, prepares your hard conversations, keeps the context of everything and confronts you when you are fooling yourself.

There is no ready-made template here. **The system is born from your discovery and adapts to you through use.** What works for someone else does not necessarily work for you, and the plugin was designed on that premise.

> It comes from the system I use every day as a product person, in production for months, which other people in my circle have adopted and adapted to their own way of working. This is the distilled version for anyone in product: PM, GPM, head of product, APM, people who lead a team and people who do not (the discovery asks, and the system adjusts).

## What you need first

1. **One of the two agents, running on your computer:** **[Claude Code](https://claude.com/claude-code)**, by Anthropic (Mac or Windows), or **Codex**, by OpenAI, in the desktop app or the CLI.
2. **An account for the agent you chose:** a Claude subscription (Pro or higher) for Claude Code, or an account with access to Codex, under the terms of its plan. The plugin itself is free.
3. Nothing else. You do not need to know how to code, and you do not need Obsidian or Notion (the system is a folder of markdown files that any editor opens; if you use Obsidian, it works well on top). If you have never used a terminal, paste this page into Claude itself and ask for help.

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

There are 7 blocks of questions, about 20 to 30 minutes of conversation. At the end it proposes the structure and the AGENTS.md (the "instruction manual" it will follow), with the folder names in your language, **you review everything before any file is created**, and it plants the starter skills in your folder. In that last part Claude may ask for your permission (how many times depends on what you have already allowed) for three things: reading the skills that come with the plugin, creating their files in your folder, and running the bridge that gets the folder ready for Codex (below). Accept the read and create requests, because without them the commands never come into existence; the bridge request only matters if you will also open the folder in Codex. Do not start 15 minutes before a meeting: the discovery is the part that sets the quality of everything else.

## Installing in Codex (desktop app or CLI)

**1.** In the terminal, register the marketplace and install the plugin:

```
codex plugin marketplace add pe-menezes/pm-chief-of-staff
codex plugin add pm-chief-of-staff@pm-chief-of-staff
```

In Codex the command is `plugin add` (`plugin install` is the Claude Code form). The plugin is not published in OpenAI's plugin directory: you install it from this repository.

**2.** Create the new folder and open a **new session** of Codex inside it. A session that was already open before the install does not see the plugin.

**3.** Ask for the setup in natural language, for example "run the pm-chief-of-staff setup" or "build my chief of staff". The language you ask in becomes the language of the conversation and of the files. The discovery, the proposal and the review are the same as in Claude Code: nothing is created before your ok.

The plugin also ships a session-start hook (the memory load, below). **Installing the package does not authorize the hook.** Codex asks for your trust in it through its normal hook approval mechanism; until you approve, the session opens without the automatic load and the `AGENTS.md` still tells the agent to read the same files. No install step turns off approval or the sandbox.

During planting, the setup runs the Codex bridge in your folder (next section). A sandbox that does not allow creating `.agents/` blocks this step, and the agent stops and tells you, with no workaround. In that case, ask it for the bridge command with the path resolved, read it, and choose: authorize it through Codex's normal approval request, or run the command yourself, in your terminal, from inside the folder. Without the bridge the folder works, but the planted skills do not show up in Codex.

## What comes planted (and why "planted" matters)

Planting is copying a seed skill (the starter that ships in the plugin) INTO your folder, and the setup starts by planting 5:

| Skill | What it does |
|---|---|
| `start-day` | calendar + backlog + today's 3, anchored in your priorities |
| `close-day` | assesses the 3, classifies what did not close, seeds tomorrow's #1 |
| `prep-conversation` | agenda for a 1:1 (direct report or your manager), a peer or a stakeholder, from what is written |
| `process-meeting` | paste the transcript, get a structured note + propagation to the right places |
| `absorb` | brings a doc, article or process inside: it gets a home, a summary with provenance and the line saying when it will be used |

From the moment they are planted, **these skills are your files**. Want the 1:1 agenda to always have a recognition section? Tell the agent and it edits the skill. Want start-day to include your dashboard? Same thing. My future updates **never touch what is yours**: they improve the setup and the plugin skills and add new seeds to the catalog (`/pm-chief-of-staff:plant` lists what is there).

In the catalog, besides the planted ones: **`close-week`**, which aggregates the daily balances, forces the week's decisions, measures the health of the system's memory (the files every session loads, against their size targets), keeps a trajectory signal (the material for your cycle review) and sets up next week's journal. Plant it at the end of your first week: `/pm-chief-of-staff:plant close-week`.

Also in the plugin: **`/pm-chief-of-staff:connect`**, which maps in a single file what the agent can pull on its own (calendar, transcripts, messages, tickets), so the routine skills stop asking for what it already knows how to fetch; the setup runs it. If you already had planted skills before this layer, `connect` checks which of them still ask and offers to edit each one.

**`/pm-chief-of-staff:remove-ai-tells`** reviews a text you are about to send. A reviewer agent, which did not write the text, points out the tells of AI-generated writing (antithesis in series, punchlines, em dashes). You see the before and after of each excerpt. The original only receives the excerpts you approve.

The commands with the `/pm-chief-of-staff:` prefix are the Claude Code form. In Codex, ask by name in natural language ("plant close-week", "remove the tells from this text").

## The same folder in Claude and Codex

The folder you build opens in both agents, with no second copy of anything:

* **A single source for your skills.** They live in `.claude/skills/`, and that is where every edit happens. Codex looks for skills in `.agents/skills/`, so the bridge (`modules/codex-bridge.sh`, run by setup, plant and create-skill) creates there a relative link to `.claude/skills/`. Where a link is not possible, it writes one short `SKILL.md` per skill that says to read the source. An edit made in the source shows up in the next Codex session.
* **The bridge does not run over what is yours.** If you already had a `.agents/skills` folder, it stays in use: the bridge only adds the missing entries there, one per skill. An entry with the same name that the bridge did not create (a file, a link or a skill of yours) stays as it is and goes on the conflict list, for you to decide with the agent. If `.agents/skills` is already a link of yours or a file, the bridge writes nothing there and also reports a conflict. It only rewrites the short files it generated itself, so running it again is safe.
* **Situational rules arrive through the index.** Codex does not read the `paths:` of the rules in `.claude/rules/`. The generated `AGENTS.md` has a rules index section (`## Rules by topic` in an English folder, `## Regras por assunto` in a Portuguese one), one line per rule with the topic and the path, and tells the agent to read the rule before acting on that topic. A new rule enters the index in the same step; a rule outside it holds only in Claude Code.
* **The tells reviewer stays independent.** In Claude Code it is the plugin's named agent. In Codex, `remove-ai-tells` opens a new subagent, without the conversation history and with orders to only read. If the session has no subagents, it says so: no separate reviewer read the text.

Known limits: the bridge depends on the session being able to write `.agents/` in the folder (the path for when the sandbox refuses is in the Codex install, above). On Windows without symbolic link permission, the bridge falls back to the short per-skill files; that path was proven by test, and no Windows machine has run it yet.

## The memory (the part that makes it worth it)

The agent's memory is the files: whatever is written in the folder, any future session loads. The system is born with 4 layers, all in readable markdown:

* **`CRITICAL_FACTS.md`**: the live state (your priorities with numbers, active events). Read at the start of every session, it exists so the agent never asks you again what has already been decided.
* **`memory/`**: the daily log, dated and immutable. What happened, when, with a pointer to where the detail is.
* **People and project hubs**: what has stabilized. Recent signals, history, context.
* **`AGENTS.md` and the skills**: how it works with you, and the layer that self-modulates.

The manual lives in `AGENTS.md`, which Claude Code, Codex and Cursor read. Next to it sits a `CLAUDE.md` with a single line, `@AGENTS.md`, the bridge that makes Claude Code load the manual: do not delete that file and do not write rules in it. A folder built before 0.6 keeps its manual in `CLAUDE.md` and works the same in Claude Code, with nothing to migrate; Codex reads `AGENTS.md` and skips `CLAUDE.md`, so that folder opens there without the manual. In Codex, the planted skills arrive through the bridge and the rules through the `AGENTS.md` index (previous section).

The daily loop closes on its own: `start-day` reads what yesterday's `close-day` seeded; `close-day` promotes what was left loose in the log to the hubs. After two weeks of use, the agent knows your team, your projects and your patterns.

If the external engine `memoria-agente` is configured in the same folder, the two compose: this plugin provides the structure and the rituals, and the engine provides mechanical enforcement and takes over the session-start injection in Claude Code (the hook detects it and steps aside). In Codex, the plugin's hook always does the load: the telemetry the engine leaves in the folder does not prove it is running in this Codex session, so the Codex registration does not step aside on that evidence.

## Where is my data?

**On your computer, and only there.** The whole system is a folder of markdown that you open, read, version and delete whenever you want. Nothing is sent to me, and the plugin installs no server, connector or MCP integration. It has two short scripts, both local, and you can read each one in full in 2 minutes:

* **`hooks/boot-memory.sh`, a read at session start.** It reads three files from your own folder (the state, the index and the day's log) and puts their content into the conversation, so you start with the agent already knowing where things are. It writes nothing and sends nothing anywhere. In Codex, it only runs after you trust the hook.
* **`modules/codex-bridge.sh`, a local write at planting.** It runs when setup, plant or create-skill ask for it, with your permission, and writes only inside `.agents/` in your folder (the link or the short files that point to your skills). It does not delete, rename or replace any file of yours.

The conversation itself follows the rules of the account of the agent you use: Anthropic, in Claude Code; OpenAI, in Codex.

One thing is on you: meeting and 1:1 transcripts carry sensitive data about other people. Before pasting company material, check your company's AI policy (Claude's Team and Enterprise plans have their own data controls).

## Updates

* **Automatic (recommended):** once, run `/plugin`, go to the **Marketplaces** tab, select `pm-chief-of-staff` and turn on **Enable auto-update**. New versions arrive on their own, with a notice.
* **Manual:** `/plugin marketplace update pm-chief-of-staff` whenever you want to check.
* **In Codex:** `codex plugin marketplace upgrade pm-chief-of-staff` in the terminal, then a new session.

An update replaces the plugin (setup, plugin skills and the seed catalog). **Your files, your planted skills and your `AGENTS.md` or `CLAUDE.md` are never touched.**

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
* **Planted seeds keep their names and are still commands.** A seed planted as `abrir-dia` stays `abrir-dia` and keeps answering as a command and to its trigger phrases.
* **The old plugin commands no longer exist.** Typing `plantar`, `criar-skill` or `conectar` after the plugin prefix no longer works; the new name, or the same request in natural language ("plant close-week"), does the same thing.
* **In Codex**, if the session opens without the memory load after the update, approve the hook again through Codex's hook mechanism.

## Common problems

* **`/pm-chief-of-staff:setup` shows up as "Unknown command":** run `/reload-plugins` (step 2 of the install ends with it) or close and reopen the session.
* **The discovery dropped in the middle (session closed, context ran out):** open the folder again and run the setup; it finds the `setup-notes.md` it was writing (`setup-notas.md` in a folder from 0.7) and resumes from the block where it stopped.
* **I planted a skill and the command (`/start-day`) does not show up:** a planted skill registers when the session opens. In a new session it is there, and the phrase trigger ("good morning") works the same way.
* **I connected my calendar (or email) and the agent does not see it:** a connector turned on while the session is open only appears in the next session. Close and reopen the session. If you do not use connectors, ignore this item: everything works by pasting the material.
* **In Codex, the planted skills do not show up:** the bridge did not run or found a conflict. Check whether `.agents/skills` exists in the folder; if it does not, ask the agent to run the plugin's bridge again (plant also runs it) or follow the sandbox path in the Codex install. If the bridge listed a conflict, it left what was yours intact: decide with the agent what to do with each line.
* **In Codex, the session opens without the memory load:** the hook does not have your trust yet. Approve it through Codex's hook mechanism; until then, the agent reads the files through the `AGENTS.md` routine.

## Don't want to install the plugin?

Paste the content of [`PROMPT.md`](PROMPT.md) into any agent with file access (Claude Code and Codex included) and run the same setup by conversation. The folder comes out with `AGENTS.md`, the `CLAUDE.md` bridge, the rules index and the skills in a single source, with Codex discovery created without running over what already exists. The plugin adds the seed skills, the `connect`, `create-skill` and `remove-ai-tells` skills, the session-start hook, the bridge as a script and the update channel.

## Philosophy, in 4 principles

1. **The system self-modulates.** A change request becomes an edit to the AGENTS.md or to the skill, on the spot, and the system adapts to the way you think.
2. **You have to read everything.** An error you do not catch propagates. Your responsibility cannot be handed off.
3. **It is a thought partner, not an obedient assistant.** Candor over validation, diagnosis before suggestion, and anti-patterns named on the spot (executing without questioning, escalating without a recommendation, a showcase without a "so what", naive optimism, and the leadership ones for people who lead: the Super-Leader, the luxury babysitter, generic feedback, the hard decision postponed).
4. **The files are the memory.** What is not written does not exist tomorrow.

## Bug or missing seed

[Open an issue](../../issues/new/choose): there are templates for a bug and for a seed request. Seed requests are what turn into new catalog entries, and the queue is public.

## License

MIT. Use it, adapt it, distribute it.
