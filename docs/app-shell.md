# App-Rahmen & Navigation

> Die app-weite Übersicht über **den Rahmen, in dem jedes Feature erscheint**: wo die App sichtbar ist, wie man zwischen den Stellen wechselt und welche Muster jede Seite wiederholt.
>
> - Angelegt durch `/init` am 2026-11-04.
> - Verfeinert durch `/architecture`, sobald ein Feature geplant wird.
> - **Flughöhe:** Aufbau, nicht Gestaltung. Farben, Schrift und Bausteine stehen in `docs/design-system.md`; das Innere einer einzelnen Seite steht im `design.md` des Features.

## Zuständiges Feature

Owner: PROJ-1 App-Rahmen & Einstellungen. Änderungen am Rahmen laufen über `/refine PROJ-1`.

## Stellen, an denen die App erscheint

InnoWhisper ist eine Menüleisten-App ohne Dock-Symbol. Es gibt kein Hauptfenster; diktiert wird per Tastenkürzel, ohne ein Fenster zu öffnen.

| Stelle | Was der Nutzer dort macht | Sichtbar | Zuständiges Feature |
|--------|---------------------------|----------|---------------------|
| Menüleisten-Symbol | Sieht den Zustand: bereit, nimmt auf, wandelt um, Problem | immer | PROJ-1 |
| Menüleisten-Fenster | Letztes Diktat, Schnellwahl Mikrofon und Sprache, Einstellungen öffnen, Beenden | beim Klick aufs Symbol | PROJ-1 (Rahmen), PROJ-13 (Inhalt) |
| Einstellungsfenster | Alles einstellen | über Menüleisten-Fenster oder ⌘, | PROJ-1 (Rahmen) |
| Sprechblase | Zeigt während der Aufnahme die Tonwelle am aktiven Eingabefeld | während Aufnahme und Umwandlung | PROJ-8 |
| Einführung | Eigenes Fenster ohne Schließen-Knopf; führt durch Erlaubnisse, später auch Zugangsschlüssel, Tastenkürzel und Probe-Diktat | beim ersten Start, bis sie abgeschlossen ist, und wenn ein Update neue Schritte bringt | PROJ-3 (Rahmen), PROJ-4, PROJ-5, PROJ-7 (Schritte) |
| Hinweise | Kurze Meldungen („Text eingefügt“, „Kein Internet“) | nach Ereignissen | PROJ-2 |

### Bereiche im Einstellungsfenster

| Bereich | Inhalt | Zuständiges Feature |
|---------|--------|---------------------|
| Allgemein | Start beim Anmelden, Töne, Ausgabe (einfügen oder Zwischenablage), Fehlerprotokoll | PROJ-1, PROJ-2, PROJ-7 |
| Zugang & Erlaubnisse | Groq-Schlüssel, Mikrofon, Bedienungshilfen | PROJ-4, PROJ-3 |
| Tastenkürzel | Kürzel, Modus, verknüpfte Vorlage | PROJ-5, PROJ-12 |
| Umwandlung | Modell, Sprachhinweis | PROJ-6 |
| KI-Vorlagen | Vorlagen anlegen, ändern, löschen | PROJ-11 |
| Wörterbuch | Begriffe, Ersetzungen, gesprochene Satzzeichen, Weitergabe als Datei | PROJ-9 |
| Verlauf | Die letzten 50 Diktate | PROJ-10 |
| Info & Updates | Version, nach Updates suchen | PROJ-14 |

## Aufteilung des Einstellungsfensters

- **Seitenleiste (links):** Liste der Bereiche mit SF-Symbol und Namen, Reihenfolge wie oben, aufgebaut wie die macOS-Systemeinstellungen.
- **Inhalt (rechts):** der gewählte Bereich.
- **Fenstergröße:** veränderbar mit sinnvoller Mindestgröße; kein Mobil-Fall (reine Mac-App).

## Seitenmuster

Jeder Bereich im Einstellungsfenster wiederholt dieses Muster; `/build` hält sich daran.

- **Kopf:** Titel des Bereichs oben, darunter die Einstellungen in Gruppen wie in den macOS-Systemeinstellungen.
- **Problem-Hinweis:** Fehlt etwas Wichtiges (Erlaubnis, Schlüssel, Internet), steht oben im Bereich ein gut sichtbarer Hinweis mit einem Knopf, der direkt zur Lösung führt.
- **Laden:** kleine Fortschrittsanzeige direkt an der Stelle, die lädt (z. B. beim Prüfen des Schlüssels), nie ein blockierendes Fenster.
- **Leer:** ein kurzer Satz, was hier später erscheint, plus die nächste sinnvolle Handlung.
- **Fehler:** verständliche Worte und ein Lösungsweg, nie ein technischer Code allein.
- **Bestätigungen:** über die app-weiten Hinweise (PROJ-2), nicht pro Bereich neu erfunden.

## Zustände der App

Es gibt keine Anmeldung; der Rahmen unterscheidet stattdessen diese Zustände:

- **Erster Start:** Die Einführung erscheint. Solange sie offen ist, holen „Einstellungen …“, erneutes Öffnen der App und ein Zweitstart die Einführung nach vorne statt des Einstellungsfensters; „Beenden“ geht immer.
- **Erlaubnis oder Schlüssel fehlt (nach der Einführung):** Das Menüleisten-Symbol zeigt ein Warnzeichen; Menüleisten-Fenster und Einstellungen führen zum passenden Bereich bzw. bei Erlaubnissen direkt in die Systemeinstellungen. Die Einführung erscheint dafür nicht erneut.
- **Bereit:** Diktieren per Tastenkürzel, ohne ein Fenster zu öffnen.
- **Nimmt auf / wandelt um:** Symbol und Sprechblase zeigen den Zustand.

## Gemeinsame Bausteine des Rahmens

_Festgelegt in `features/PROJ-1-app-rahmen-einstellungen/design.md`. Bereichskennungen: `general`, `access`, `hotkeys`, `transcription`, `prompts`, `vocabulary`, `history`, `about`._

| Baustein | Datei | Zweck |
|----------|-------|-------|
| Menüleisten-Symbol mit Zustand | `Packages/InnoWhisperKit/Sources/AppShell/MenuBar/` | Zustand auf einen Blick |
| Menüleisten-Fenster | `Packages/InnoWhisperKit/Sources/AppShell/MenuBar/` | Rahmen für Schnellzugriff (Inhalt PROJ-13) |
| Einstellungsfenster mit Seitenleiste | `Packages/InnoWhisperKit/Sources/AppShell/Settings/` | Navigation zwischen den Bereichen; Bereiche und Allgemein-Gruppen werden von Features angemeldet |
| Problem-Hinweis und Problem-Sammlung | `Packages/InnoWhisperKit/Sources/AppShell/State/` | einheitlicher Hinweis mit Lösungsknopf; Features melden Probleme mit fester Kennung |
| Diktat-Tätigkeit | `Packages/InnoWhisperKit/Sources/AppShell/State/` | `ruhend` / `nimmtAuf` / `wandeltUm`, gesetzt von PROJ-5 und PROJ-6 |
| Hinweis-Kapsel | `Packages/InnoWhisperKit/Sources/Notices/` | eine Rückmeldung (Info, Erfolg, Fehler) am Eingabefeld oder oben mittig; jedes Feature zeigt seine Hinweise darüber (PROJ-2) |
| Einführungs-Rahmen | `Packages/InnoWhisperKit/Sources/Onboarding/` | Einführungsfenster; Features melden ihre Schritte nach dem Schritt-Vertrag in `features/PROJ-3-erlaubnisse-einfuehrung/design.md` an (PROJ-3) |
| Erlaubnis-Wächter | `Packages/InnoWhisperKit/Sources/Permissions/` | Stand von Mikrofon und Bedienungshilfen, Problem-Meldung bei Fehlen (PROJ-3) |
| Fehlerprotokoll | `Packages/InnoWhisperKit/Sources/Diagnostics/` | Protokoll ohne Diktat-Inhalte; jedes Feature protokolliert darüber (PROJ-2) |

---

_Lebendes Dokument. Fügt ein Feature einen Bereich, eine Stelle oder ein neues Seitenmuster hinzu, wird zuerst diese Übersicht angepasst. Verhaltensänderungen am Rahmen laufen über `/refine PROJ-1`._
