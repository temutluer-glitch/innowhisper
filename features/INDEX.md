# Feature Index

> Central tracking for all features. Updated by skills automatically.

## Status Legend
- **Roadmap** - `/init` done, feature identified in feature map, no spec file yet
- **Mapped** - already built before the kit arrived; proposed by `/map`, confirmed at `/init`, no spec folder yet — `/reverse-spec` writes it
- **Spec'd** - `/reverse-spec` done: runs in production, criteria confirmed, not yet verified — `/qa` closes that gap
- **Planned** - `/write-spec` done, full spec written, architecture not yet designed
- **Architected** - `/architecture` done, tech design approved, ready to build
- **Tasked** - `/tasks` done, tasks.md approved, ready to build
- **In Progress** - `/build` active or completed, not yet in QA
- **In Review** - `/qa` active, testing in progress
- **Approved** - `/qa` passed, no critical/high bugs, ready to deploy
- **Deployed** - `/deploy` done, live in production
- **Merged** - spec folded into another feature by `/refine`; the Spec cell names it, the folder lies in `features/archive/`

## Features

> The **Spec** column links to the feature **folder** (`features/PROJ-X-name/`), not a single file. Each folder contains `spec.md`, `design.md`, `tasks.md`, and `qa-report.md`.
>
> **A row is never a log.** This file is loaded into every session. What was built, fixed, measured or decided goes into the feature's folder (`design.md`, `qa-report.md`) and the commit — here only the status changes.
>
> **Feature** is the name only — two to four words, the way you would say it ("User accounts & login", "Kanban board"). **Description** is one sentence of what it does. Priority and dependencies are not columns: they are the **build order** line under the table, and it is the only place they live — there is no second roadmap table anywhere else.

| ID | Feature | Description | Status | Spec | Created |
|----|---------|-------------|--------|------|---------|
| PROJ-1 | App-Rahmen & Einstellungen | Menüleisten-Symbol, Einstellungsfenster mit allen Bereichen und Start beim Anmelden. | Approved | [PROJ-1](PROJ-1-app-rahmen-einstellungen/) | 2026-11-04 |
| PROJ-2 | Hinweise & Fehlerprotokoll | Kurze Hinweise, Töne und ein Fehlerprotokoll ohne Diktat-Inhalte. | Approved | [PROJ-2](PROJ-2-hinweise-fehlerprotokoll/) | 2026-11-04 |
| PROJ-3 | Erlaubnisse & Einführung | Führt beim ersten Start durch Mikrofon und Bedienungshilfen und warnt, wenn eine Erlaubnis fehlt. | Approved | [PROJ-3](PROJ-3-erlaubnisse-einfuehrung/) | 2026-11-04 |
| PROJ-4 | Groq-Zugang | Zugangsschlüssel eintragen, prüfen und im Schlüsselbund ablegen. | Approved | [PROJ-4](PROJ-4-groq-zugang/) | 2026-11-04 |
| PROJ-5 | Aufnahme per Tastenkürzel | Startet und stoppt die Aufnahme (halten oder ein/aus), Mikrofonwahl, Abbruch mit Esc, stille Aufnahmen werden verworfen. | Approved | [PROJ-5](PROJ-5-aufnahme-tastenkuerzel/) | 2026-11-04 |
| PROJ-6 | Umwandlung in Text | Wandelt die Aufnahme über Groq in Text um, mit Modell- und Sprachwahl, langen Aufnahmen und Filter gegen Erfundenes. | Architected | [PROJ-6](PROJ-6-umwandlung-text/) | 2026-11-04 |
| PROJ-7 | Text einfügen | Fügt den Text ins aktive Eingabefeld ein oder legt ihn nur in die Zwischenablage und stellt die alte Zwischenablage wieder her. | Roadmap | — | 2026-11-04 |
| PROJ-8 | Sprechblase am Eingabefeld | Zeigt während der Aufnahme eine Sprechblase mit Tonwelle direkt am aktiven Eingabefeld. | Roadmap | — | 2026-11-04 |
| PROJ-9 | Wörterbuch & Ersetzungen | Namen und Fachbegriffe, Textersetzungen und gesprochene Satzzeichen, Weitergabe als Datei. | Roadmap | — | 2026-11-04 |
| PROJ-10 | Verlauf | Die letzten 50 Diktate mit Kopieren, Löschen und erneutem Umwandeln. | Roadmap | — | 2026-11-04 |
| PROJ-11 | KI-Nachbearbeitung | Überarbeitet den Text optional mit KI-Vorlagen, Standard ist „Ohne KI“. | Roadmap | — | 2026-11-04 |
| PROJ-12 | Mehrere Tastenkürzel | Mehrere Kürzel mit je eigener Vorlage, auch einzelne Tasten wie rechte ⌥ oder Fn. | Roadmap | — | 2026-11-04 |
| PROJ-13 | Schnellzugriff Menüleiste | Menüleisten-Fenster mit letztem Diktat und Schnellwahl von Mikrofon und Sprache. | Roadmap | — | 2026-11-04 |
| PROJ-14 | Updates & Auslieferung | Beglaubigte App zum Herunterladen, automatische Updates über Sparkle und Umzugsanleitung fürs Team. | Roadmap | — | 2026-11-04 |

**Build order:** P0 (MVP, alle in der ersten Version): PROJ-1 → PROJ-2 (needs PROJ-1) → PROJ-3 (needs PROJ-1, PROJ-2) → PROJ-4 (needs PROJ-1) → PROJ-5 (needs PROJ-3) → PROJ-6 (needs PROJ-4, PROJ-5) → PROJ-7 (needs PROJ-3, PROJ-6) → PROJ-8 (needs PROJ-3, PROJ-5) → PROJ-9 (needs PROJ-6) → PROJ-10 (needs PROJ-6) → PROJ-11 (needs PROJ-4, PROJ-6) → PROJ-12 (needs PROJ-5, PROJ-11) → PROJ-13 (needs PROJ-5, PROJ-10) → PROJ-14 (needs PROJ-1) · Nach PROJ-7 ist echtes Diktieren testbar; Umzug des Teams erst nach PROJ-14

<!-- Add features above this line -->

## Deployments

> One line per release, written by `/deploy` — **the single deployment record**: tag · date · production URL · the features it shipped. `/security-check` reads the production URL here, `/audit` expects every Deployed feature on one line. A feature that was live before the kit arrived (reconstructed from code) gets its line from `/qa`: `live before the kit — verified by /qa on <date> · PROJ-X`.

- _v1.0.0 · 2026-01-31 · https://app.example.com · PROJ-1, PROJ-2_

## Next Available ID: PROJ-15
