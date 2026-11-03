---
name: close-day
description: Closes the workday. Assesses today's 3, classifies what did not close, seeds tomorrow's #1 move and promotes what stayed in the log to the hubs. Use when the person says "close my day", "close the day", "I'm done for the day", "day review", "how did today go", "/close-day", or the 0.7.0 phrases "fechei o dia", "fecha o dia", "review do dia", "como foi hoje", "/fechar-dia". Do NOT use to start the day (start-day) or for a midday update.
---

# Close the day

> pm-chief-of-staff seed. This file is YOURS: ask the agent to change any step and it edits this skill on the spot.

Writing: write to the person and in their files in the language this folder's instruction file defines (the `AGENTS.md`; in a folder without `AGENTS.md`, the `CLAUDE.md`); without one, in the language the person writes in, and fallback questions go in their language too. Follow that file's writing canon. Without it: no em dash (use a comma, parentheses or a colon), short dense sentences, 1 line per item.

Pair of `start-day`: the opening proposes the 3, this close assesses them (did they close? why not? what to do tomorrow?) and records the answer where the opening reads it in the morning. Without a close, the 3 are proposals never assessed, and the system does not learn whether it errs in prioritization or in execution. It takes 5 minutes. A 0/3 day is data, read without judgment.

It also works alone. When today's block in the journal holds no numbered 3 (no `## Today's 3: YYYY-MM-DD` block for today, because no `start-day` is planted or the day had no opening, or only the block with no 3 inside that this close created earlier today), skip steps 2 and 4 and the `**Balance:**` line of step 5, run the rest, and say in 1 line that without today's 3 there is no balance. The `**Reflection:**` and `**→ tomorrow:**` lines then go into today's `## Today's 3: YYYY-MM-DD` block: with none yet, create it at the top of the current week's journal with no 3 inside; on a second run the same day, only add the new reflection and seed to the block that already exists, never a second block. A week with no journal yet gets it created first, in `journal/` and in the naming pattern the folder already uses, with no task migrated, by the same rule the instruction file applies to the week's first task. So the next opening, if one is ever planted, reads the seed where it always does.

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
6. **Promote what stayed in the log (reinforcement).** The write rules of the instruction file already write the destination of an entry in the same step as the entry, in any session; this close sweeps the day's log once for what slipped. Read `memory/{today}.md` and separate ONLY what has no destination besides the log: a signal about a person or project that no note propagated, a priority change that `CRITICAL_FACTS.md` does not reflect. **Cap of 3 items** (over it, take the 3 most costly to lose and declare the rest). Confirm with the person in 1 question: promote it where? Before asking, check whether the item already reached its destination during the day (then it is not a question). Before writing to a shared destination (hub, journal, `CRITICAL_FACTS.md`), read `.claude/skills/_shared/write-gate.md` and apply the admission decision (ADD, UPDATE, SUPERSEDE, NOOP). Without the module, the check in 1 line: read the destination before writing, and do not write what is already there.
7. **Overdue events (reinforcement).** The session routine of the instruction file already resolves these in any session; this close repeats it once a day. Each active event in `CRITICAL_FACTS.md` whose date has passed (the session-start pack marks it ` · OVERDUE YYYY-MM-DD`; without the pack, compare the event date with today) is an open question: look for its outcome in the logs dated after the event and in the line's source. Found: carry the outcome to its destination (hub or log), through the same admission decision of step 6, and remove the line. Not found: ask the person in 1 question, together with step 6's. The pains review line is the one exception to removal: overdue and not done, propose doing the review with the person, in that same question; done, update the review dates in the pains file (`context/pains.md` in English; the next review 3 months after the one done, unless the person gives another date) and, through the same admission decision of step 6, replace the line with the next review (the nearest of the pains file's review dates as the event date, the day of the review as the checked date), or remove it only when no pain is left open. No overdue event: the step stays out of the answer.
8. **Answer short:** compilation + balance (`N/3` + reason, or the 1 line saying there is no balance without today's 3) + tomorrow's seed. No cheerleading. On the last workday of the week, with `.claude/skills/close-week/` or `.claude/skills/fechar-semana/` in the folder, close with 1 line of offer: "it's Friday: shall I close the week too?". Without either folder, no offer: the person chose their routines at setup, and `/pm-chief-of-staff:plant` stays there for when they want it.

Ceiling, valid for steps 3, 5, 6 and 7: the day block stays within the format (`**Reflection:**`, `**Balance:**` and `**→ tomorrow:**` in 1 line each). Every other destination with a declared ceiling (`CRITICAL_FACTS.md`, the hub head, the entry in `memory/`) follows the ceiling rule of `.claude/skills/_shared/write-gate.md`, read at step 6; without the module: measure the destination at write time and, over its ceiling, propose the cut, never cut alone.

## The loop

`start-day` (reads `**→ tomorrow:**`, proposes the 3) → day (updates mark progress) → `close-day` (compiles, assesses, classifies, seeds) → tomorrow's `start-day`. Without `start-day`, the seed for tomorrow still lands in the journal, where the person reads it in the morning. Keep the `**Balance:**` and `**→ tomorrow:**` labels stable: they are the contract the opening reads.

## When NOT to use

In the morning → `start-day`. Middle of the day ("did X") → direct update in the journal.
