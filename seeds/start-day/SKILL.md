---
name: start-day
description: Starts the workday. Builds the calendar, scans the open tasks, proposes today's 3 anchored in the priorities and records them in the journal. Use when the person says "good morning", "start my day", "plan my day", "what should I do today", "/start-day", or the 0.7.0 phrases "bom dia", "abre meu dia", "monta meu dia", "o que faço hoje", "/abrir-dia". Always interactive (it proposes, the person validates). Do NOT use to close the day (close-day) or for an end-of-afternoon review.
---

# Start the day

> pm-chief-of-staff seed. This file is YOURS: ask the agent to change any step ("I want the opening to always include X") and it edits this skill on the spot.

Writing: write to the person and in their files in the language this folder's instruction file defines (the `AGENTS.md`; in a folder without `AGENTS.md`, the `CLAUDE.md`); without it, in the language they write in, and fallback questions go in their language. Follow that file's canon. Without it: no em dash (use a comma, parentheses or a colon), short dense sentences, 1 line per item.

Builds the day on what is already written: priorities, open tasks, calendar, and the seed that yesterday's close left. Proposes today's 3; the person validates before they are locked in.

## Principles

1. The priorities in `CRITICAL_FACTS.md` filter everything: a task that does not anchor in a priority needs a reason to enter the day.
2. Today's 3 live in the weekly journal, block `## Today's 3: YYYY-MM-DD` at the top.
3. The skill proposes, the person validates before locking in. Never decide for the person.

## Flow

1. **Read the state**: `CRITICAL_FACTS.md` (priorities) · the current week's journal · the `**→ tomorrow:**` line from yesterday's close (the strongest candidate for today's #1) · the most recent `memory/` log.
2. **Calendar**: if `.claude/skills/_shared/capabilities.md` exists, read the `today's calendar` line and pull today's events with what is in `how to call`, with `provider` identifying the source. Without the module, with that line empty or half filled (only one of the two columns), or if the fetch fails (expired connector, machine without it), ask in 1 line: "what does your calendar look like today? (meetings and free windows)". The day opening does not stop because of the calendar.
3. **Scan the backlog**: `grep -- "- \[ \]"` across the whole `journal/`, with no start-of-line anchor (an indented subtask counts). Categorize: **today** (due today or settled in a meeting today) · **overdue** · **this week** · **waiting** (blocked by a third party). An overdue task from another topic is read together with the new ones: if a new one invalidates the old one, propose closing the old one, not redoing it.
4. **Propose today's 3**, each one explicitly anchored ("{task} (anchors priority 1)"). Rules:
   * Yesterday's `**→ tomorrow:**` seed is the strongest candidate for #1.
   * A meeting is not one of today's 3 (it happens anyway); the 3 are execution.
   * **Calibrate against the calendar**: count the hours that are really free. With less than 2h left, propose 1 move + 1 monitor at most, and say so in the opening. Three ambitious ones on a day with no window guarantee failure by calibration, not by execution.
5. **Record** at the top of the weekly journal: `## Today's 3: YYYY-MM-DD` + the 3, numbered and anchored. Same day runs again: overwrite the block. New day: create it and leave the previous one in the history.
6. **Answer short**: calendar in 1 block · the 3 proposals · 1 to 2 critical questions if a contradiction was detected. Wait for validation before locking in.

## During the day (update mode)

"did X", "closed Y", "Z came up": mark it in the journal right away (`- [x]` or a new task), and reassess the 3 only if the person asks or if one of them became impossible (a new meeting swallowed the window). Answer with the delta in 1 line.

## When NOT to use

End of the day ("how did today go") → `close-day`. One-off question about a project → read the hub directly.
