# pm-chief-of-staff

[Read in Portuguese (pt-BR)](README.pt-BR.md)

**A personal Chief of Staff for product people, inside Claude Code or Codex.** You open the agent in an empty folder, it interviews you for about 20 to 30 minutes, and your answers become a system of your own: the folders, the manual it follows and your work routines. Its memory is markdown files in that folder. No database and no server.

## What it looks like day to day

Before a 1:1, you ask for the agenda and it builds one from what is written in the folder: what you promised last time and did not do, and the topic that has been pushed back for weeks. After the meeting, you paste the transcript, and it writes the note and updates whatever changed.

Nothing comes from a template. Setup asks who you are, what you own, who works with you and where it hurts, and builds the folder from that. You review everything before any file is created.

## Install

Open your coding agent and ask:

```
install this for me, please: github.com/pe-menezes/pm-chief-of-staff
```

Then open the agent in an empty folder, in a new session, and ask: `build my chief of staff`.

You need Claude Code (a Claude Pro plan or higher) or Codex. You do not need to know how to code.

<details>
<summary>Install by hand</summary>

In Claude Code, opened in the empty folder:

```
/plugin marketplace add pe-menezes/pm-chief-of-staff
/plugin install pm-chief-of-staff@pm-chief-of-staff
/reload-plugins
/pm-chief-of-staff:setup
```

In Codex, from the terminal:

```
codex plugin marketplace add pe-menezes/pm-chief-of-staff
codex plugin add pm-chief-of-staff@pm-chief-of-staff
```

Then open a new Codex session in the empty folder and ask "build my chief of staff". Codex asks you to approve the plugin's hooks.

</details>

## What you get

| Skill | What it does |
|---|---|
| `prep-conversation` | builds the agenda for a 1:1, a peer or a stakeholder conversation from what is in the folder |
| `process-meeting` | turns a transcript into a note and carries what changed to the right places |
| `absorb` | files a document or article, with a summary and where it came from |
| `start-day`, `close-day`, `close-week` | optional daily and weekly routines; setup asks which ones you want |

Once installed in your folder, the skills are your files: ask for a change and it edits the skill.

## Your data

The folder stays on your computer. The plugin installs no server and no connector, and an update never touches your files. The conversation itself follows the terms of the agent account you use. Before pasting company transcripts, check your company's AI policy.

## More

* [Full guide](docs/full-guide.md): the memory, updates, one folder in both Claude and Codex, and common problems.
* [Setup without the plugin](PROMPT.md): the prompt to paste into any agent that works with files.
* Bug or missing seed: open an [issue](https://github.com/pe-menezes/pm-chief-of-staff/issues).

MIT license.
