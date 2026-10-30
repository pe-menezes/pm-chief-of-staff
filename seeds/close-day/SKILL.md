---
name: close-day
description: Closes the workday. Assesses today's 3, classifies what did not close, seeds tomorrow's #1 move and promotes what stayed in the log to the hubs. Use when the person says "close my day", "close the day", "I'm done for the day", "day review", "how did today go", "/close-day", or the 0.7.0 phrases "fechei o dia", "fecha o dia", "review do dia", "como foi hoje", "/fechar-dia". Do NOT use to start the day (start-day) or for a midday update.
---

# Close the day

> pm-chief-of-staff seed. This file is YOURS: ask the agent to change any step and it edits this skill on the spot.

Writing: write to the person and in their files in the language this folder's instruction file defines (the `AGENTS.md`; in a folder without `AGENTS.md`, the `CLAUDE.md`); without one, in the language the person writes in, and fallback questions go in their language too. Follow that file's writing canon. Without it: no em dash (use a comma, parentheses or a colon), short dense sentences, 1 line per item.

Pair of `start-day`: the opening proposes the 3, this close assesses them (did they close? why not? what to do tomorrow?) and records the answer where the opening reads it in the morning. Without a close, the 3 are proposals never assessed, and the system does not learn whether it errs in prioritization or in execution. It takes 5 minutes. A 0/3 day is data, read without judgment.

## Flow

1. **Compile the day (pull from the traces).** Pull from what already left a trace: today's conversation, the diff of what was written in the folder (journal, hubs, notes), the calendar. Deliver "your day" in 5 to 8 lines grouped by priority. The person only adds what leaves no trace (in person, verbal, what they thought). Asking for an account of what you can gather yourself is handing work back.
2. **Assess the 3.** Read the `## Today's 3: YYYY-MM-DD` block in the journal and propose the status of each as a hypothesis (done / not done / partial); the person settles it. Mark it inline in the journal.
3. **Reflect (the part that is only theirs).** Two questions: what important thing happened that left no trace? · what did you learn or would do differently? A relevant account becomes a `**Reflection:**` line in the day block; learning about themselves goes to `memory/{today}.md`. A reflection that repeats a pattern already seen (the same gap coming back) gets named, frankly.
4. **Classify what did not close.** Each one not done gets one of three reasons: **out of time** (right task, the day did not fit it) · **outside attack** (the unplanned took the day; was it unavoidable?) · **wrong 3** (the error is in the prioritization). The classification is the value of the skill: the same reason 3 days in a row points at what to adjust.
5. **Seed tomorrow.** At the end of the day block:
   ```
   **Balance:** {N}/3, {1 sentence with the reason for what did not close}
   **→ tomorrow:** {#1 move, anchored in the priorities; carry-over only of what still stands}
   ```
   A task not done that no longer matches the priorities gets rescoped or dropped, never carried over by inertia.
6. **Promote what stayed in the log.** Read `memory/{today}.md` and separate ONLY what has no destination besides the log: a signal about a person or project that no note propagated, a priority change that `CRITICAL_FACTS.md` does not reflect. **Cap of 3 items** (over it, take the 3 most costly to lose and declare the rest). Confirm with the person in 1 question: promote it where? Before asking, check whether the item already reached its destination during the day (then it is not a question). Before writing to a shared destination (hub, journal, `CRITICAL_FACTS.md`), read `.claude/skills/_shared/write-gate.md` and apply the admission decision (ADD, UPDATE, SUPERSEDE, NOOP). Without the module, the check in 1 line: read the destination before writing, and do not write what is already there.
7. **Answer short:** compilation + balance (`N/3` + reason) + tomorrow's seed. No cheerleading. On the last workday of the week, close with 1 line of offer: with `.claude/skills/close-week/` or `.claude/skills/fechar-semana/` in the folder, "it's Friday: shall I close the week too?"; without either folder, "it's Friday: want to close the week too? I'll plant the ritual: /pm-chief-of-staff:plant close-week (the skill copied from the plugin becomes a file of yours, editable)".

Ceiling rule, valid for steps 3, 5 and 6: a destination with a declared ceiling is measured at write time. The day block within the format (`**Reflection:**`, `**Balance:**` and `**→ tomorrow:**` in 1 line each; the entry in `memory/` in 2 to 4 lines), `CRITICAL_FACTS.md` against ~700 tokens (~3KB) and the hub head (Facts + Current reading) against ~half a page (~15 lines). Noticed an overflow: ask "what goes?" already with the cut proposal (which line becomes history, which leaves the file), because a cut without a proposal hands work back, and never cut alone. `close-week` stays the owner of the systematic measurement; this close enforces the ceiling of the destination it touches, on the day it writes.

## The loop

`start-day` (reads `**→ tomorrow:**`, proposes the 3) → day (updates mark progress) → `close-day` (compiles, assesses, classifies, seeds) → tomorrow's `start-day`. Keep the `**Balance:**` and `**→ tomorrow:**` labels stable: they are the contract the opening reads.

## When NOT to use

In the morning → `start-day`. Middle of the day ("did X") → direct update in the journal.
