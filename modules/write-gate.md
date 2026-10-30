**Loaded by:** `process-meeting`, `close-day`, `close-week`, `absorb`. A new skill that writes a fact to a shared destination adds itself to this line, because a module with no declared consumer never fires and nobody notices.

# Write gate

Rule: **every fact that goes to a shared destination (hub in `people/` or `projects/`, journal in `journal/`, `CRITICAL_FACTS.md`) goes through 1 of the 4 decisions before the write.** Saving everything that was extracted is the root cause of the bloat; the decision happens at write time, because the future cleanup inherits whatever nobody decided.

The decision comes from reading: read or grep the stretch of the destination where the fact would go before classifying. An impression of similarity without reading classifies wrong.

| decision | criterion | action |
|---|---|---|
| ADD | the fact does not exist in the destination | write it with a date |
| UPDATE | the fact exists and changed (number, state, deadline) | edit the existing line |
| SUPERSEDE | the new one invalidates the old one, which has historical value | mark the old one with "superseded on YYYY-MM-DD by {what superseded it}" and write the new one |
| NOOP | the fact is already there | nothing is written, and recording nothing is the correct decision |

In a section the hub declares immutable (Facts, Current reading), UPDATE does not apply: a fact that changed comes in by SUPERSEDE, which marks the old one on the spot, or as a new dated line by ADD, and UPDATE is for the mutable destinations (`CRITICAL_FACTS.md`, journal).

The SUPERSEDE mark is the one the "Current reading" section of the hubs in `people/` and `projects/` already uses: a single format, greppable for both uses. Shortcut: an empty or newly created destination is ADD directly, with no prior reading.
