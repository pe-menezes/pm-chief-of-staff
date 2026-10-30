---
name: remove-ai-tells
description: Removes from a text the tells of AI-generated writing (antithesis in series, punchlines, em dashes, the same thing under three names) based on the findings of a separate reviewer agent, and returns the clean text with the before and after of each excerpt. Use when the person says "remove the AI tells from this text", "does this sound like AI?", "check the tells before I send this", "clean up the AI feel of this", "tira os AI tells desse texto", "isso tá com cara de IA?", "revisa os tells antes de eu mandar", "limpa a cara de IA disso" or runs /pm-chief-of-staff:remove-ai-tells. Do not use to write a text from scratch, review grammar and spelling or adjust the tone to a recipient, which are direct requests to the agent.
---

# Remove AI tells

One isolated tell goes unnoticed. The same form repeated across the text gives the generated writing away. Whoever wrote or is about to rewrite the text sees their own tells poorly, so the reading comes from `ai-tells-reviewer`, the plugin's reviewer, which reads in a separate context (named agent in Claude Code, new subagent in Codex).

Talk to the person in her language (the one the folder's instruction file sets; without it, the one she writes in). The text keeps its own language: the scan below covers English and Portuguese, and the reviewer reads either.

## Flow

1. Take the pasted text, the file path or the last text you wrote in the session. Without a clear text, ask which one.
2. Save a copy of the text to `tells-draft.md` at the root of the person's folder with the file-writing tool, because the mode that accepts edits allows that tool and a shell command can stop at an approval prompt. A file that already exists with that name is never replaced or deleted, including when it is the source itself, because it belongs to the person. In that case use the next free name (`tells-draft-2.md`, `tells-draft-3.md` and so on), and the following steps call draft the file created in this run. A `rascunho-tells.md` left by 0.7.0 is also hers: it stays untouched, and this run never reuses or deletes it. The draft keeps every line break. Lists, tables, headings and code blocks stay intact because the approved excerpt goes back to the source file by exact match. Scan, reviewer and rewrite work on the draft. It stays outside `.claude/`, which asks for write permission even in the mode that accepts edits. Before saving, say in 1 sentence that creating the file at the root may ask for write permission. If permission is denied, stop and tell the person that the reviewer reads the text from a file and without the draft it does not run.
3. Scan the draft with the three regexes below, since counting by eye gets it wrong. Use the Grep tool if it is in the session's tool list. Without it, use `rg -P` in the shell (Codex puts `rg` on the PATH; multiline mode is `-U`) and, without `rg`, `perl -CSD -Mutf8`: line by line with `-ne 'print "$.: $_" if /REGEX/i'`, and the whole file with `-0777 -ne 'print "$&\n" while /REGEX/g'` for a multiline regex. Never `grep -P`: the macOS grep has no `-P`, and `grep` without it returns empty and without error on the antithesis and colon regexes. The search returns candidates. Discard those that fall in a code block, inline code, URL, time of day (the colon of a URL or a time does not count) or table alignment row (`|:---|---:|`).
   - Em dash, en dash and curly quotes with the regex `[\x{2014}\x{2013}\x{201C}\x{201D}\x{2018}\x{2019}]`. The code point avoids confusing em dash, en dash and hyphen.
   - Antithesis with the regex `(não é [a-zà-ú]|, não [a-zà-ú]|não só |não apenas |mais do que |isn't [a-z]|is not [a-z]|, not [a-z]|not only |not just |more than )`. Use `-i` to catch the capital at the start of a sentence. It finds the bare antithesis in Portuguese and in English and also the legitimate comparative (`mais do que`, `more than`, `is not`), which the reviewer discards. The disguised antithesis stays with the reviewer.
   - Colons and semicolons with the regex `[:;](?:[^:;\n]|\n[^\n:;])*[:;]` in `multiline`. It finds each paragraph (consecutive lines without a blank line) with two or more of these signs added up and returns from it the excerpt between the first and the last sign.
4. Call the reviewer with the path of the draft and the path of `.claude/skills/_shared/tells.md` in the person's folder, if it exists. Send the paths without your reading of the text, which would bias the reviewer's. It returns the findings and the count of occurrences per form (a line with two em dashes counts two).

   In Claude Code, the reviewer is `ai-tells-reviewer` (`pm-chief-of-staff:ai-tells-reviewer` in the agent list).

   In Codex, which does not register the plugin's agent, open a new subagent, without a copy of this conversation's history and with the session's model. Its instruction is the body of `<plugin root>/agents/ai-tells-reviewer.md` below the frontmatter, the two paths and the explicit order to only read: do not edit, create or delete any file, and do not run any command that writes. The frontmatter `tools:` only restricts in Claude, so the order goes in the dispatch. The plugin root is `${CLAUDE_PLUGIN_ROOT}`; if the variable does not resolve, the folder two levels above this SKILL.md; only without it, the `pm-chief-of-staff` plugin folder in the Codex plugin cache. Without subagents in the session (feature off or denied), tell the person that the independent reading does not run here. She chooses to stop or to go on with only the scan of step 3, and the delivery states that no separate reviewer read the text. The reviewer's reading is never done in this session in its place.

   In Claude Code, someone who installed or updated the plugin with the session open may not see the reviewer in the agent list. In that case, suggest `/reload-plugins` and, if the reviewer is still missing from the list, a new session. If that is not possible, dispatch a generic subagent with the body of `${CLAUDE_PLUGIN_ROOT}/agents/ai-tells-reviewer.md` as its instruction and the explicit order to only read and edit nothing (if the variable does not resolve, the plugin root is the folder two levels above this SKILL.md; only without it, locate the `pm-chief-of-staff` plugin folder in the plugin cache). Say in 1 sentence that reading the plugin folder may ask for permission and that, if the read is denied, the reviewer does not run and the way out is the new session.
5. Before rewriting, save the count of occurrences per form of the findings the reviewer confirmed. It is the "before" of step 7 and is lost when the rewrite changes the draft. Then rewrite only the marked excerpts.
   - In an antithesis, cut the negative half and state only the fact.
   - A prose colon becomes a sentence.
   - A heading names the subject.
   - A punchline goes out whole. The fact it was dressing up stays.
   - Each thing gets a single name.
   - Em dash and en dash become a comma, parentheses or a period. A curly quote becomes straight.

   The rewrite keeps numbers, proper names and meaning, and stays in the language of the text. It does not create a new form (cleft sentence, elegant variation) or swap a verifiable claim for a hedge.
6. Check the rewrite with the scan of step 3 and with a new call to the reviewer, which takes the same two paths (in Codex, another new subagent, opened the same way as in step 4). A continuation of the first call already has the previous list in context. Without `tells.md`, what the person marked as her style comes back as a finding. The second reading catches the tell swapped for another and the grammar error the rewrite introduces. A new finding gets 1 more round, at most. Whatever remains goes stated in the delivery.
7. Deliver, in the person's language, the clean text ready to copy, one before-and-after line per excerpt and the count of each form in both versions. When the text has a code block, the outer fence takes more backticks than the inner one, because an equal fence closes the block in the middle and breaks the copy. The person approves everything or picks excerpts.
8. Apply to the source file only the approved excerpts, when there is a source. Before that, say in 1 sentence that editing the source and saving the pasted text may ask for permission. If permission is denied, the source stays as it was and the clean text stays in the conversation to copy. Each excerpt goes back one at a time, with enough context to appear only once in the source, and never by batch replacement, because the copy inside a code block would change along with it. An excerpt that disappeared from the source or is still repeated stays out and is stated to the person. At the end, after applying or after the person gives up, delete only the draft created in this run, never another `tells-draft*.md` nor a `rascunho-tells.md`. Before deleting, say in 1 sentence that deleting the draft asks for permission. If denied or failed, tell the person the path of the draft and that it stays in the folder until she deletes it, because the folder may be under git. For pasted text, the person chooses where to save the clean version. A path that already exists is never replaced, because the file belongs to the person, and she chooses between keeping the file, saving under another name or seeing the diff.

## Learning from the person

When she points out a tell that slipped through, or rejects a finding because it is her way of writing, offer to save it in `.claude/skills/_shared/tells.md` in her folder.

A new file has 2 sections, "Tells I caught" and "My style, do not flag", and its first line follows the module format, so the consumer check of `close-week` does not flag it as an orphan:

```
**Loaded by:** `remove-ai-tells` (plugin skill, outside `.claude/skills/`)
```

An existing file belongs to her and may have been edited by hand. It gets the line in the matching section it already has, under the 0.8.0 name or the 0.7.0 name ("Tells que eu flagrei" for a caught tell, "Meu jeito, não marcar" for her style), and the rest stays as it is: no section is renamed or translated, and a `**Carregado por:**` first line stays.

Create or edit the file after her ok. Say first, in 1 sentence, that the `.claude/` permission prompt will appear and is expected, and that, if the write is denied, what she marked holds only in this conversation.
