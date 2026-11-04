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
| Einführung | Führt beim ersten Start durch Erlaubnisse und Zugangsschlüssel | beim ersten Start oder bei fehlender Erlaubnis | PROJ-3 |
| Hinweise | Kurze Meldungen („Text eingefügt“, „Kein Internet“) | nach Ereignissen | PROJ-2 |

### Bereiche im Einstellungsfenster

| Bereich | Inhalt | Zuständiges Feature |
|---------|--------|---------------------|
| Allgemein | Start beim Anmelden, Töne, Ausgabe (einfügen oder Zwischenablage) | PROJ-1, PROJ-2, PROJ-7 |
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

- **Erster Start:** Die Einführung erscheint.
- **Erlaubnis oder Schlüssel fehlt:** Das Menüleisten-Symbol zeigt ein Warnzeichen; Menüleisten-Fenster und Einstellungen führen zum passenden Bereich.
- **Bereit:** Diktieren per Tastenkürzel, ohne ein Fenster zu öffnen.
- **Nimmt auf / wandelt um:** Symbol und Sprechblase zeigen den Zustand.

## Gemeinsame Bausteine des Rahmens

_Dateien legt `/architecture` für PROJ-1 fest; hier wird die Tabelle dann ergänzt._

| Baustein | Datei | Zweck |
|----------|-------|-------|
| Menüleisten-Symbol mit Zustand | _offen_ | Zustand auf einen Blick |
| Menüleisten-Fenster | _offen_ | Rahmen für Schnellzugriff |
| Einstellungsfenster mit Seitenleiste | _offen_ | Navigation zwischen den Bereichen |
| Problem-Hinweis | _offen_ | einheitlicher Hinweis mit Lösungsknopf |

---

_Lebendes Dokument. Fügt ein Feature einen Bereich, eine Stelle oder ein neues Seitenmuster hinzu, wird zuerst diese Übersicht angepasst. Verhaltensänderungen am Rahmen laufen über `/refine PROJ-1`._
