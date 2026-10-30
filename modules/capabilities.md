**Loaded by:** `start-day`, `process-meeting`, `prep-conversation`. A new skill that fetches outside data adds itself to this line, because a module with no declared consumer never fires and nobody notices.

# Connected capabilities

Rule: **a skill cites a capability, never a tool name.** Switching providers is editing one line here, without opening any skill. The table is the map of what the person can reach, not the list of what today's skills consume: a capability with no consumer is filled in the same way, because it is what the next skill they create will read instead of asking again which tools they use.

| capability | provider | how to call | without connector |
|---|---|---|---|
| today's calendar | | | ask in 1 line what today's calendar looks like |
| email | | | ask them to paste what matters |
| messages | | | ask what mattered in the conversations |
| documents | | | ask for the link or the text |
| meeting transcript | | | ask them to paste the transcript or the summary |
| tickets | | | ask about the state of the team's tasks |
| data warehouse | | | ask for the number already worked out and its source |
| product analytics | | | ask for the number or a screenshot of the funnel |

The `without connector` column describes the question; it is asked in the person's language.

A capability name is software-agnostic: the product lives only in the `provider` column. Format of a filled-in line (generic example, not a default): `today's calendar | Google Calendar | session calendar connector, today's events | ask in 1 line`.

Read today by some skill: `today's calendar` (start-day), `meeting transcript` (process-meeting), `messages` and `tickets` (prep-conversation). The others wait for the skill that will read them. The "Loaded by" line at the top is something else: it lists the skills that read this file, not the capabilities filled in.

An empty provider is not a problem: the skill follows the "without connector" column, which is the usual behavior. A wrong or half-filled line costs more (a provider that left, a tool that changed its name, a blank `how to call`): the skill tries, fails and falls back to that column with a stumble in the middle. New or lost tool: run `/pm-chief-of-staff:connect` again, which updates the table and rechecks the consumers at the top.

## Calendar reading rules

* The response to the invite filters the map: a declined invite is neither a commitment nor a ritual of the person. When scanning the calendar, read the response field (rsvp) of each event; when the source does not return that field, ask before treating the event as a firm commitment.
* An atypical period is not a yardstick for recurrence: before settling a cadence from a window (vacation, intensive event, a week off the usual pattern), ask "is this window typical?".
