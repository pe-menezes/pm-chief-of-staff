---
name: absorb
description: Gives a home to material the person sends into the system (a doc about their product, an article, a study, a company process): routes it to the right destination, distills the essentials with provenance and declares when it will be used. Use when the person says "read this doc", "look at this article", "this is the process for X here", "keep this", "read this article and keep it", "/absorb", pastes a long text without asking for meeting processing, or in Portuguese "lê esse doc", "olha esse artigo", "esse é o processo de X aqui", "guarda isso". Do NOT use for a transcript or meeting note (process-meeting) or for a one-off question about a text with no intention of keeping it.
---

# Absorb material

> pm-chief-of-staff seed. This file is YOURS: ask the agent to change the routing or the summary format and it edits this skill on the spot.

Writing: write to the person and in their files in the language this folder's instruction file defines (the `AGENTS.md`; in a folder without `AGENTS.md`, the `CLAUDE.md`); without one, in the language the person writes in, and fallback questions go in their language too. Follow that file's writing canon. Without it: no em dash (use a comma, parentheses or a colon), short dense sentences, 1 line per item.

The value is not archiving: it is giving the material a destination, distilling what the system does not know yet and leaving in writing when it comes back. Material that stays only in the chat evaporates when the session closes.

## Step 1: understand the material

At most 1 question, and only if it cannot be inferred: what it is and what it is for.

## Step 2: route by nature

* **Living project doc** (spec, plan, analysis of what is in progress): the project folder in `projects/`.
* **Durable knowledge** (product, market, article, study): `reference/{topic}.md`.
* **Company operating process**, by its trigger: the trigger is a file type ("every note of X follows this format"), it becomes `.claude/rules/{topic}.md` with `paths:` frontmatter; the trigger is a ritual a planted skill covers (prep a conversation, close the week), the rule goes into the owning skill; the same step applies in 2 or more skills, it becomes a module in `.claude/skills/_shared/{name}.md` that each of them tells the agent to read (declare at its top who loads it); no clear trigger, `reference/` with the trigger written in the file.
* **About a key person**: their hub in `people/`, in the right section: dated fact with source in "Facts", signal in "Recent signals" (1 dated line), a reading that changes the previous one in "Current reading" (marking the previous one with "superseded on YYYY-MM-DD by {what superseded it}").

## Step 3: distill the delta

A dense summary of up to 20 lines, never a copy: date and source at the top (provenance always, where it came from and when it came in), a long article becomes the essentials. The original lives outside the vault (a cold folder, a drive, or the source itself), with 1 pointer line in the distillate.

## Step 4: declare the consumer

Every file closes with the line "when I use this" (example: the company's review process, I use it when we prepare your cycle). Material with no foreseeable use: say so and ask whether to keep it anyway.

## Step 5: create and index

Create the new file and update `navigation.md`. Before writing to a shared destination (the hub in `people/`), read `.claude/skills/_shared/write-gate.md` and apply the admission decision (ADD, UPDATE, SUPERSEDE, NOOP). Without the module, the check in 1 line: read the destination before writing, and do not write what is already there.

## Step 6: reply short

Up to 5 lines: where it ended up (clickable path) + when it will be used.
