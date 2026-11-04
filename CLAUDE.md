# InnoWhisper

> The AI Engineering Kit is installed in this project — a spec-driven workflow.
> This file is the one place the project's context is maintained.

<!-- AI-ENG-KIT:START (managed — do not edit by hand; refreshed by /verify-setup) -->
## AI Engineering Workflow

`/init → /write-spec → /architecture → /tasks → /build → /qa → /deploy`

Feature artifacts: `features/PROJ-X-name/{spec,design,tasks,qa-report}.md`.
Use `/refine` for changes, `/audit` for drift, `/dsgvo` for personal data, `/e2e-tests` for critical
journeys, `/security-check` and `/cleanup` after release. Phase details live in the skills;
specialist guidance in `docs/kit/guides/` and matching `docs/stacks/` packs is read on demand.

@.claude/rules/general.md
@.claude/rules/security.md
<!-- AI-ENG-KIT:END -->

## Key Conventions

- **Working language: Deutsch.** Talk to the user in Deutsch and write every project document in Deutsch — see `.claude/rules/general.md` → Working Language.
- **Feature IDs:** PROJ-1, PROJ-2, etc. (sequential)
- **Commits:** `feat(PROJ-X): description`, `fix(PROJ-X): description`
- **Single Responsibility:** One feature per folder
- **Feature branches:** you create a branch `feat/PROJ-X-name` before `/build`; work stays there through build/QA, and `/deploy` merges it in. The main branch always stays deployable.
- **Human-in-the-loop:** All workflows have user approval checkpoints.
- **Secrets / env files:** Never read/write real env or credential files. Edit only dummy examples;
  state the key name and provider location so the user enters real values privately.
- **Neuaufbau von InnoWhisper.** Der alte Stand liegt in `../WhisperDictation/` (Swift, GitHub temutluer-glitch/whisperdictation) und dient nur als Nachschlagewerk: lesen ja, Code ungeprüft übernehmen nein. Ausgangslage und Pflichtpunkte: `docs/ausgangslage.md`.
- **Name:** Das Programm heißt überall InnoWhisper (Ordner, Repo, Programmname, Dateien). Keine neuen Vorkommen von „WhisperDictation“.

## How This Project Runs

_Recorded by `/init`. Until then, do not guess these — ask._

- **Platform:** _web / mobile / desktop / mcp / cli / extension / other_
- **Stack:** _framework, backend, tests, deploy_
- **Start:** _the command that runs the app locally_
- **Verify:** _how to probe a running instance (HTTP, stdio/JSON-RPC, …)_
- **Layers:** _additional runtimes beside the app — name → root, start, test, packs under `docs/stacks/`; or "none"_
- **Closing check:** _aggregate or individual commands; confirmed stages per runtime (`checkCoverage`)_
- **Codebase map:** `docs/codebase/` — written by `/map`, read before designing anything; `/map` again after large changes

## Product Context

@docs/PRD.md

## Data Model

@docs/data-model.md

## Feature Overview

@features/INDEX.md
