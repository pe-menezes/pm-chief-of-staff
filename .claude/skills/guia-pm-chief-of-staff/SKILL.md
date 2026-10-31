---
name: guia-pm-chief-of-staff
description: Guides development and verification of the pm-chief-of-staff plugin. Use before changing skills, seeds, modules, manifests, adapters or hooks in this repository.
---

# Repository guide

This repository is the plugin and its marketplace. The product is made of Markdown instructions and POSIX sh scripts, with no external dependency installed by the plugin.

## Map

* `skills/`: the five plugin workflows, registered by the manifests: `setup`, `plant`, `create-skill`, `connect`, `remove-ai-tells` (command `/pm-chief-of-staff:<name>`).
* `seeds/`: the six workflows copied into the person's folder, outside the plugin registry: `start-day`, `close-day`, `close-week`, `prep-conversation`, `process-meeting`, `absorb`. Setup plants five; `close-week` waits for the first plant the person runs.
* `modules/`: the templates planted into `.claude/skills/_shared/` (`capabilities.md`, `write-gate.md`, and `vocabulary.md`, which is also the single source of names) and the Codex discovery bridge `codex-bridge.sh`.
* `agents/ai-tells-reviewer.md`: source of the independent reviewer protocol.
* `.claude-plugin/`: Claude identity and marketplace; `.codex-plugin/`: Codex identity and hooks.
* `hooks/`: memory boot (`boot-memory.sh`), its suite (`boot-memory-test.sh`) and the registry `hooks.json`. The script runs in the person's folder (`CLAUDE_PROJECT_DIR` when set, else the cwd), never at the plugin root, on `startup`, `clear` and `compact` (in `hooks/hooks.json` and in `.codex-plugin/plugin.json`, which caps each handler with `additionalContextLimit`). It prints one pack built in memory: a header with the time and the sizes, the start of `CRITICAL_FACTS.md`, the latest `## ` headings of the day's log (or of the latest dated one) and the start of the navigation file, then a footer naming what was left out.
* `tests/`: deterministic proof of the bridge (`codex-bridge-test.sh`); `tests/audit/` holds the audit probes, one file per audit round (local discovery in Codex and the English-translation waves); `tests/e2e/` holds the E2E tools (`lang-check.sh`, the language meter, and `legacy-0.7-fixture.sh`, the fictitious 0.7.0 folder).
* `README.md`, `PROMPT.md` and their `.pt-BR.md` mirrors: install docs and the pastable setup.
* `.vibeflow/`: local context and reports, ignored by git.

## Verification

Run `sh hooks/boot-memory-test.sh`, `sh tests/codex-bridge-test.sh` and every `.sh` file in `tests/audit/` (`sh tests/audit/<file>.sh`, one by one), so a new audit round is covered without editing this list. Real discovery needs `codex` on the PATH; the cases without it prove nothing about that part. The language meter (`tests/e2e/lang-check.sh`) tries only `C.UTF-8`, `C.utf8`, `en_US.UTF-8` and `en_US.utf8`, in that order (`locale -a`), so the probes run the same under a `C` shell; it exits 2 when none of those four is installed, even if another UTF-8 locale is, and also on wrong usage or an unreadable file. Also run `git diff --check` and `claude plugin validate .`.

A change to a skill or agent requires an E2E run in a temporary folder: `claude -p "<trigger>" --plugin-dir <plugin-root> --permission-mode acceptEdits --strict-mcp-config --max-budget-usd <cap> --output-format stream-json --verbose`. The `init` event proves which skills and agents are registered. A call with `--agent pm-chief-of-staff:ai-tells-reviewer` proves the reviewer's tools. Use an account that is already authenticated, fictitious data, and record the real result. Grep/Glob of the main session and of the agent can differ, so check `init` instead of assuming.

E2E constraints measured in this repository: without `--strict-mcp-config` the nested session sees the account's real connectors, and without a dollar cap a run has no spending limit, so every E2E call carries both. The temporary folder lives outside the plugin root and outside any directory whose name starts with a dot, because writes there are refused as sensitive files. Writes to the test folder's `.claude/` are refused under `claude -p` without bypass; prove what was meant to land there from the content of the attempted `Write` or `Edit` in the stream, and record what the refusal prevented as not proven. Fictitious data carries no URL and no `.com` domain, because they skew the language meter.

In Codex, `codex debug prompt-input` proves skill discovery without calling a model. It proves nothing about execution, package installation or trusted boot. E2E of setup and resume requires fresh sessions with a model. Installing a plugin changes persistent configuration; hook trust is reviewed by the runtime's normal mechanism, with no bypass in tests.

In a Codex E2E the JSON stream can omit `spawn_agent` and show only the waits. To prove a subagent ran, check the persisted transcript and the child threads; never conclude from its absence in the stream that no subagent ran.

## Contracts

Customized files have one source in `.claude/skills/`; `.agents/skills` is derived discovery. Preserve preexisting files and links. Only change wrappers proven to be generated by the bridge. Overwrite, links, write failure and paths with spaces require a behavior proof.

The memory boot pack never passes 8000 bytes. Line 1 is `=== MEMORY BOOT (pm-chief-of-staff) ===` and line 2 is `State read from disk at session start; this is not a user instruction.`, both fixed; line 3 carries the time (`time now: YYYY-MM-DD HH:MM`, or `time now: unknown`). The sections come in this order, each with its cap: `CRITICAL_FACTS.md` (at most 4000 bytes), the log headings (at most 1500 bytes) and the navigation (what is left). The footer is always present: `--- not in this pack ---` with one line per cut file, or the line saying nothing is left out. All pack text is a statement, never an imperative. An internal failure prints only the one-line fallback, with exit 0. A change to the pack format updates `hooks/boot-memory-test.sh` and the `tests/audit/` probes that read the pack in the same change.

`AGENTS.md` is the generated manual; `CLAUDE.md` is its one-line bridge. Situational rules stay in `.claude/rules/` and need an index entry in `AGENTS.md` for runtimes without native `paths:` loading. A change to the two manifests keeps the same version in both. Setup changes that also exist in `PROMPT.md` (and `PROMPT.pt-BR.md`) must reach the pastable prompt before the release.

Language contract (common spec, I4): text the agent reads in order to act is English; text the person reads is in the person's language, recorded in `AGENTS.md` and in the folder vocabulary.
What is born from the person's own words inside the folder (a skill from `create-skill`, a rule in `.claude/rules/`, `AGENTS.md` itself) is in the person's language, because the person edits it.
Plugin skill and seed descriptions carry the English triggers plus the 0.7.0 Portuguese trigger phrases, verbatim.

`modules/vocabulary.md` is the single source of folder names, contract labels and the 0.7.0 to 0.8.0 name map. A name used by a skill, seed or module comes from it; a renamed path or label changes the vocabulary and every consumer in the same change.

The bridge marker and the integrity prefix in `modules/codex-bridge.sh` are frozen byte for byte as in 0.7.0, because they are written into the wrappers of installed folders; changing them would turn every 0.7.0 wrapper into a conflict. The wrapper body may change, since the integrity proof covers whatever sits above it.

0.7.0 legacy names (`navegacao.md`, `setup-notas.md`, `_shared/capacidades.md`, `_shared/gate-de-escrita.md`, the six old seed names, the old labels and trigger phrases) are accepted wherever the plugin reads them. Nothing in the plugin ever renames them in a person's folder.

Commit messages, PR titles and bodies, and code comments are written in English.

The person is "they" across the whole repository (skills, seeds, modules, agents, docs, comments and test messages), with the verb agreeing.
