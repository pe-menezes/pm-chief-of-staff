---
name: process-meeting
description: Turns a meeting that happened into a structured note and propagates what matters. The person pastes the transcript, the automatic summary or raw notes. Use when the person says "process this meeting", "process this 1:1", "look at what happened in the meeting", pastes a transcript asking for it to be organized, "/process-meeting", or in Portuguese "processa essa reunião", "processa esse 1:1", "olha o que rolou na reunião", "/processar-reuniao". Do NOT use to prepare a future conversation (prep-conversation).
---

# Process a meeting

> pm-chief-of-staff seed. This file is YOURS: ask the agent to change the note format or the propagation rules and it edits this skill on the spot.

Writing: write to the person and in their files in the language this folder's instruction file defines (the `AGENTS.md`; in a folder without `AGENTS.md`, the `CLAUDE.md`); without one, in the language the person writes in, and fallback questions go in their language too. Follow that file's writing canon. Without it: no em dash (use a comma, parentheses or a colon), short dense sentences, 1 line per item.

The value is not summarizing: it is extracting what changes the state of the system (decision, task, signal about a person or project) and putting each thing in the place where it will be found. One meeting processed and propagated is worth more than ten stored transcripts.

## Step 1: receive the material

Accept any form: pasted transcript, automatic summary (Gemini, Zoom, Granola), photo of a whiteboard, raw typed notes. Ask only what cannot be inferred: who it was with and when (if it is not in the material).

If `.claude/skills/_shared/capabilities.md` exists with `provider` and `how to call` filled in on the `meeting transcript` line, offer to fetch the transcript through there instead of waiting for pasted material. Without the module, with the line half-filled, or with no result from the fetch, go on with what the person pastes.

A transcript is evidence of what was SAID, not of what is true: a relevant factual claim that exists only in speech goes into the note marked as "to validate".

## Step 2: write the note

File at `meetings/{person-or-ritual}/YYYY-MM-DD.md`, aiming at 25 lines at most. The raw text (transcript, automatic summary) NEVER goes into the operational vault: kept in here, it becomes a distractor for every future search. The note is the distillate + 1 pointer line to where the raw text lives (a cold folder outside the vault, a drive, or the source itself). The skill does not move or delete the raw text: the person decides where it stays.

```markdown
---
type: meeting-note
with: {person or ritual}
date: YYYY-MM-DD
---

**Context:** {1 line}
**Raw:** {1-line pointer to where the original text lives}

## Decisions
- {1 line per decision: what was decided + who decided}

## Tasks
- [ ] {action + owner + deadline if stated} (your tasks also go to the journal, see propagation)

## Signals
- {what the conversation revealed about a person, project or risk, 1 line each}

## Unresolved
- {what was left open and comes back next time}
```

If there was a prepared agenda (`prep-conversation`), compare: what from the agenda was not discussed comes back as a candidate for next time.

## Step 3: propagate (this is where the system comes alive)

The rise rule, "what persists vs what passes": decision, agreement, fact about a person, preference and commitment propagate (hub, journal, `memory/`); a momentary emotional state, transient operational detail and circumstantial observation stay in the note and die there. The note keeps everything; the rule only decides what rises.

Before writing to a shared destination (hub, journal, `CRITICAL_FACTS.md`), read `.claude/skills/_shared/write-gate.md` and apply the admission decision (ADD, UPDATE, SUPERSEDE, NOOP). Without the module, the check in 1 line: read the destination before writing, and do not write what is already there.

Propose the propagation and carry it out with the person's ok:

1. **The person's tasks** → the week's journal, with a deadline.
2. **About a key person** → their hub in `people/`, in the right section: dated fact with source in "Facts", signal in "Recent signals" (1 dated line), a reading that changes the previous one in "Current reading" (dated, marking the previous one with "superseded on YYYY-MM-DD by {what superseded it}").
3. **Project decision or turn** → the project hub in `projects/`.
4. **Milestone of the day** → 1 block in `memory/{today}.md` pointing to the note (`## [HH:MM] {title} + 2 lines`).
5. **A priority or active event changed** → propose an update to `CRITICAL_FACTS.md`.

Golden rule: the detail lives in the note; hub and log point to it. Never duplicate the whole content in two places.

## Step 4: reply short

The note as a clickable path + what was propagated (1 line per destination) + what was left "to validate". No retelling of the meeting in the chat.
