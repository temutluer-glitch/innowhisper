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

_Recorded by `/init` on 2026-11-04._

- **Platform:** desktop (native macOS menu bar app, macOS 26+)
- **Stack:** Swift/SwiftUI (`MenuBarExtra`), Xcode 26, Swift Package Manager; no backend, data local on the Mac (settings, history, vocabulary; Groq key in Keychain); Groq Whisper + Groq LLM as external service; updates via Sparkle; deploy via public GitHub Releases + notarization. Tests: open, decided at `/architecture` PROJ-1
- **Start:** open, decided when the Xcode project is created (PROJ-1)
- **Verify:** open, decided at `/architecture` PROJ-1
- **Layers:** none
- **Closing check:** open, recorded once the Xcode project exists (`/init checks`)
- **Codebase map:** `docs/codebase/` — written by `/map`, read before designing anything; `/map` again after large changes

## Product Context

@docs/PRD.md

## Data Model

@docs/data-model.md

## Feature Overview

@features/INDEX.md
