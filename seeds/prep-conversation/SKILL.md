---
name: prep-conversation
description: Builds the agenda before a conversation that matters. 1:1 with a direct report, 1:1 with your own manager, alignment with a peer or stakeholder. Use when the person says "prep my 1:1 with [name]", "build the agenda", "I'm meeting [name], prep me", "/prep-conversation", or in Portuguese "prepara o 1:1 com [nome]", "monta a pauta", "vou falar com [nome]", "tenho reunião com [nome], me prepara", "/preparar-conversa". Do NOT use to process the conversation after it happened (process-meeting).
---

# Prep a conversation

> pm-chief-of-staff seed. This file is YOURS: ask the agent to change the agenda format ("I want it to always have a section for X") and it edits this skill on the spot.

Writing: write to the person and in their files in the language this folder's instruction file defines (the `AGENTS.md`; in a folder without `AGENTS.md`, the `CLAUDE.md`); without one, in the language the person writes in, and fallback questions go in their language too. Follow that file's writing canon. Without it: no em dash (use a comma, parentheses or a colon), short dense sentences, 1 line per item.

A good agenda is born from what is already written. The flow: gather candidates → validate with the person → write the agenda with only what was validated.

## Step 1: gather candidates

1. Read the person's hub in `people/`, starting from the top: the Facts section (dated, with source) and the Current reading (the most recent, with no "superseded on YYYY-MM-DD by" mark) are the base of the prep; a reading marked as superseded is ignored. Recent signals and History come in as a complement.
2. Read the last 2 to 3 notes of conversations with them in `meetings/`: what was left as a follow-up (on both sides), what was agreed "for next time".
3. Grep the name in the journal and in `memory/` for the last 2 weeks: what came up about them or about their topics.
4. Every item in the hub's "Recent signals" section is a candidate. A signal sitting for more than 3 weeks comes in with the question: chase it again, or did it drop?
5. If `.claude/skills/_shared/capabilities.md` exists with `provider` and `how to call` filled in on `messages` or `tickets`, pull through there what came up in the last 2 weeks about the person and their topics (the same window as item 3), as a candidate like the others. Without the module, with the line empty or half-filled, or if the fetch fails, step 1 stays in the files, which is the default.

## Step 2: validate with the person

Present the candidates numbered, grouped (open follow-ups / signals / new topics), and ask what goes in: take / not today / drop / edit. Do not censor a candidate on your own; the person decides.

## Step 3: write the agenda

File at `meetings/{name}/YYYY-MM-DD agenda.md`, aiming at 15 lines at most, factual tone. A section with no content is omitted.

```markdown
**Context:** {1 line: the person's moment + what is hot}

Open by listening: "what do you bring me?"

## Open follow-ups
- {item + deadline + question, 1 line each; a pending item of YOURS that affects the person goes in with transparency}

## Decisions to make
- {1 line per decision that needs to come out of the conversation}

## Topics
- {what came in from step 2}
```

## Adjustments by conversation type

<!-- direct-report-feedback:start -->
* **Direct report (if you lead people):** add a `## Feedback (1-2)` section with concrete evidence (situation → behavior → impact; developmental feedback closes with the expected change). No concrete evidence from the last 1 to 2 weeks, no feedback: flag the gap and suggest observing during the week. Also add 1 development question anchored in the person's moment.
<!-- direct-report-feedback:end -->
* **Your manager:** lead with state and decision. What you need FROM THEM (unblocking, decision, context) goes in explicitly. Bring a recommendation for each problem you raise.
* **Peer or stakeholder:** what you need from them, what they need from you, and the misalignment that is costly. An alignment agenda with no decision to make is a meeting that could have been a message: say so.

## After generating

Ask whether anything needs adjusting before the conversation. The agenda propagates nothing to the hub: whoever propagates is `process-meeting`, after the conversation happens (it also compares what was planned with what happened).
