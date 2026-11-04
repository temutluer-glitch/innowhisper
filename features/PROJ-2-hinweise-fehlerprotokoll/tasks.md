# PROJ-2 Aufgaben

> Erstellt von `/tasks` aus `spec.md` + `design.md`. Geordneter, nachverfolgbarer Bauplan.
> `[P]` = parallel möglich: die Dateien der Aufgabe überschneiden sich mit keiner anderen `[P]`-Aufgabe derselben Stufe.
> Stufen laufen **nacheinander** (jede ist eine Schranke). Jede Aufgabe nennt die AC/EC-IDs aus `spec.md`, die sie erfüllt (AC → Aufgabe → Test).
> Owner: `/tasks` legt die Datei an; `/build` hakt ab.
> Abkürzungen: `Kit/` = `Packages/InnoWhisperKit/`, `Dia/` = `Kit/Sources/Diagnostics/`, `Not/` = `Kit/Sources/Notices/`, `DiaT/` = `Kit/Tests/DiagnosticsTests/`, `NotT/` = `Kit/Tests/NoticesTests/`.

## Stufe 1 — Grundgerüst

- [x] T1  Module `Diagnostics` und `Notices` samt Testzielen anlegen; `AppShell` hängt von `Diagnostics` ab, `Notices` von `AppShell` und `Diagnostics`; Platzhalter-Quellen und je ein erster Test  · files: Kit/Package.swift, Dia/Diagnostics.swift, Not/Notices.swift, DiaT/SmokeTests.swift, NotT/SmokeTests.swift  · → AC-11

## Stufe 2 — Innere Logik

- [x] T2 [P]  Protokoll-Meldung: nur feste Texte, Zahlen, Wahr/Falsch, Dauern, Aufzählungswerte, Programmkennungen und Fehler (nur Bereich und Nummer); freier Text lässt sich nicht einsetzen; Tests einschließlich Nachweis, dass ein Beispiel mit freiem Text nicht baut  · files: Dia/LogMessage.swift, DiaT/LogMessageTests.swift  · → AC-12
- [x] T3 [P]  Protokolldatei: Ort `~/Library/Logs/InnoWhisper/InnoWhisper.log` (im Test ein Testordner), Zeilenformat, Schreiben in eigener Warteschlange, Kürzen (7 Tage, ab 10 MB auf unter 8 MB), Zustand „nicht verfügbar“, leere Datei anlegen; Tests mit erfundenen Zeitpunkten  · files: Dia/LogFile.swift, Dia/LogRetention.swift, DiaT/LogFileTests.swift  · → AC-11, AC-13, EC-3, EC-4
- [x] T4 [P]  Hinweis-Zentrale: Hinweis (Art, Text ≤ 120 Zeichen), höchstens einer sichtbar, Ersetzen, Zeitgeber je Hinweis 2,0 s für Info/Erfolg, Fehler bleibt, Schließen per Klick/Esc/Aufnahmebeginn; Tests mit simulierter Zeit  · files: Not/Notice.swift, Not/NoticeCenter.swift, NotT/NoticeCenterTests.swift  · → AC-2, AC-3, AC-4, AC-5
- [x] T5 [P]  Platzierungs-Rechnung: unter gemeldeter Stelle (8 pt), im Bildschirm halten, sonst darüber; ohne Stelle oben mittig (12 pt) auf dem Bildschirm mit dem Mauszeiger; Tests mit erfundenen Bildschirmmaßen  · files: Not/NoticePlacement.swift, NotT/NoticePlacementTests.swift  · → AC-1, EC-1
- [x] T6 [P]  Töne: Schnittstelle zum Abspielen mit Attrappe, Start `Tink`, Ende `Pop`, Lautstärke 0,4, stoppt vorherigen Klang, Einstellung `sounds.enabled` Standard an; Tests  · files: Not/SoundPlayer.swift, NotT/SoundPlayerTests.swift  · → AC-9, AC-10, EC-5

## Stufe 3 — Anschluss und Oberflächen

- [x] T7 [P]  Protokoll-Zugang für alle Module (in Datei und Apples Protokoll) und Umstellung der Protokollstellen in `AppShell`  · files: Dia/Log.swift, Kit/Sources/AppShell/System/AppShellLog.swift, Kit/Sources/AppShell/System/LoginItemController.swift, Kit/Sources/AppShell/System/LegacyAppGuard.swift, Kit/Sources/AppShell/Settings/SettingsWindowController.swift  · → AC-11, AC-12
- [x] T8 [P]  Hinweis-Kapsel: Schwebefenster ohne Fokus über allen Fenstern und Vollbild, auf allen Schreibtischen; Glas-Kapsel mit Symbol und Text; feste Fläche bei „Transparenz reduzieren“, ohne Animation bei „Bewegung reduzieren“; VoiceOver-Ansage; Klick schließt Fehler; Esc-Beobachtung nur während ein Fehler sichtbar ist  · files: Not/NoticePanel.swift, Not/NoticeView.swift, Not/EscapeMonitor.swift  · → AC-1, AC-4, AC-6, AC-7, EC-2
- [x] T9 [P]  Gruppen in „Allgemein“: „Töne“ (Schalter, Reihenfolge 20) und „Fehlerprotokoll“ (Erklärsatz, Knopf „Fehlerprotokoll zeigen“ bzw. ausgegraut „Fehlerprotokoll nicht verfügbar“, Reihenfolge 90)  · files: Not/SoundSettingsGroup.swift, Not/LogSettingsGroup.swift  · → AC-10, AC-14, EC-3, EC-4

## Stufe 4 — Zusammensetzen und echt prüfen

- [x] T10  App verdrahten: Hinweis-Zentrale und Gruppen anmelden, Aufnahmebeginn schließt Fehler-Hinweis, „alte Version beendet“ als Erfolgs-Hinweis, Start-Eintrag ins Protokoll, `launchLog` im App-Delegate auf das neue Protokoll umstellen  · files: App/AppEnvironment.swift, App/LegacyAlerts.swift, App/AppDelegate.swift  · → AC-4, AC-8, AC-11
- [x] T11  Am laufenden Programm prüfen, erst selbst messen (Protokolldatei lesen, Fenster-Eigenschaften der Kapsel ins Protokoll), dann Timur: Hinweis zur alten App, Weitertippen während eines Hinweises, Knopf im Finder, Protokoll ohne Inhalte; Ergebnisse im Plan festhalten  · files: features/PROJ-2-hinweise-fehlerprotokoll/design.md  · → AC-1, AC-6, AC-8, AC-14

## Parallelisierung

- **Stufen sind Schranken.** Eine Stufe beginnt erst, wenn die vorige zusammengeführt und gegen ihre AC-IDs geprüft ist.
- **`[P]` verlangt getrennte Dateien.** Geprüft: Keine zwei `[P]`-Aufgaben einer Stufe nennen dieselbe Datei.
- **Keine `[user]`-Aufgaben.**
- **Bekannte Lücke:** Die Töne (AC-9) sind am echten Programm erst mit PROJ-5 hörbar; bis dahin nur durch Tests belegt.
