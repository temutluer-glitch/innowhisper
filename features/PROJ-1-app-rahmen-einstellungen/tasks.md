# PROJ-1 Aufgaben

> Erstellt von `/tasks` aus `spec.md` + `design.md`. Geordneter, nachverfolgbarer Bauplan.
> `[P]` = parallel möglich: die Dateien der Aufgabe überschneiden sich mit keiner anderen `[P]`-Aufgabe derselben Stufe.
> Stufen laufen **nacheinander** (jede ist eine Schranke). Jede Aufgabe nennt die AC/EC-IDs aus `spec.md`, die sie erfüllt (AC → Aufgabe → Test).
> Owner: `/tasks` legt die Datei an; `/build` hakt ab.
> Pfade unter `Packages/InnoWhisperKit/` sind abgekürzt als `Kit/` — gemeint ist immer `Packages/InnoWhisperKit/`. `Src/` = `Kit/Sources/AppShell/`, `Tst/` = `Kit/Tests/AppShellTests/`.

## Stufe 1 — Grundgerüst

- [x] T1  Lokales Paket anlegen: Paketbeschreibung (macOS 26, Swift 6, Modul `AppShell`, Testziel `AppShellTests`), Platzhalter-Quelle, erster Test mit Swift Testing, Formatier-Regel, Git-Ausnahmen für Bau-Ordner  · files: Kit/Package.swift, Src/AppShell.swift, Tst/SmokeTests.swift, .swift-format, .gitignore  · → AC-1
- [x] T2  Xcode-Projekt anlegen: App-Ziel „InnoWhisper“, synchronisierter Ordner `App/`, Kennung `com.innosolv.InnoWhisper`, Mindestversion macOS 26, nur Menüleiste (kein Dock-Symbol), Hardened Runtime ohne App Sandbox, lokales Signieren, vorläufiges App-Symbol, minimaler Einstiegspunkt; einmal bauen und starten  · files: InnoWhisper.xcodeproj/project.pbxproj, App/Info.plist, App/InnoWhisper.entitlements, App/Assets.xcassets/, App/InnoWhisperApp.swift  · → AC-1

## Stufe 2 — Innere Logik

- [x] T3 [P]  Zustand der App: Diktat-Tätigkeit (`ruhend` / `nimmtAuf` / `wandeltUm`), Problem-Sammlung (melden, ersetzen, zurückziehen über feste Kennung), Ableitung des Menüleisten-Symbols mit Vorrangfolge und VoiceOver-Text; Tests  · files: Src/State/DictationActivity.swift, Src/State/ProblemCenter.swift, Src/State/MenuBarStatus.swift, Tst/StateTests.swift  · → AC-2, AC-10, AC-18
- [x] T4 [P]  Bereiche: acht Bereichskennungen mit Name, SF Symbol und Reihenfolge; Anmelden von Bereichen und Allgemein-Gruppen; letzter Bereich mit Rückfall auf `general`; Tests  · files: Src/Settings/SettingsSection.swift, Src/Settings/SettingsRegistry.swift, Tst/SettingsRegistryTests.swift  · → AC-7, AC-8, AC-9
- [x] T5 [P]  Fensterlage-Regel: liegt das Fenster nicht zu mindestens 80 % auf einem angeschlossenen Bildschirm, mittig auf den Hauptbildschirm; Tests mit erfundenen Bildschirmmaßen  · files: Src/System/WindowFramePolicy.swift, Tst/WindowFramePolicyTests.swift  · → EC-6

## Stufe 3 — Anschluss an macOS

- [x] T6 [P]  Start beim Anmelden: Schnittstelle zu den macOS-Anmeldeobjekten mit Attrappe, Erststart-Merker, Abbildung der vier macOS-Stände auf Schalter und Problem `autostartUnavailable` (inkl. Prüfung Programme-Ordner); Tests je Stand  · files: Src/System/LoginItemService.swift, Src/System/LoginItemController.swift, Tst/LoginItemControllerTests.swift  · → AC-13, AC-14, AC-15, EC-4
- [x] T7 [P]  Alte App: Schnittstelle zur Liste laufender Apps mit Attrappe; Erkennung von `com.innosolv.WhisperDictation` beim Start, bei neu gestarteten und beendeten Apps; Beenden höflich, nach 2 s sofort, nach 5 s Anleitung; Problem `legacyAppRunning`; Tests mit simulierter Zeit  · files: Src/System/RunningApplications.swift, Src/System/LegacyAppGuard.swift, Tst/LegacyAppGuardTests.swift  · → AC-16, AC-17, AC-18, EC-2, EC-3
- [x] T8 [P]  Nur eine InnoWhisper und Beenden-Regel: Erkennen eines zweiten Exemplars (eigene, eingesetzte Abfrage), Mitteilung „Einstellungen öffnen“ ohne Inhalt; Beenden sofort bei `ruhend`, Rückfrage bei Diktat, ohne Rückfrage beim Herunterfahren; Tests  · files: Src/System/SingleInstanceGuard.swift, Src/System/QuitPolicy.swift, Tst/SingleInstanceAndQuitTests.swift  · → EC-1, AC-19, AC-20, EC-5
- [x] T9 [P]  Problem-Hinweis als gemeinsamer Baustein: Warnsymbol, Satz, Lösungsknopf, VoiceOver-Beschriftung, sichtbarer Fokus  · files: Src/Components/ProblemBanner.swift  · → AC-10, AC-23

## Stufe 4 — Oberflächen

- [ ] T10 [P]  Menüleiste: Symbol mit Zustand, Menüleisten-Fenster mit Problem-Hinweisen, Inhaltsfläche für PROJ-13, Glas-Knopfleiste („Einstellungen …“ ⌘, · „InnoWhisper beenden“ ⌘Q), feste Flächen bei „Transparenz reduzieren“, Esc schließt  · files: Src/MenuBar/MenuBarLabel.swift, Src/MenuBar/MenuBarPanel.swift  · → AC-2, AC-3, AC-4, AC-18, AC-21, AC-22, AC-23
- [ ] T11 [P]  Einstellungsfenster: genau ein Fenster, nach vorne holen, Öffnen direkt in einem Bereich, Seitenleiste aus angemeldeten Bereichen, Problem-Hinweise je Bereich, letzter Bereich, Größe 760 × 520 / mindestens 680 × 460 und gespeicherte Lage (inkl. Fensterlage-Regel), Bereich „Allgemein“ mit Schalter „Start beim Anmelden“ und Platz für Gruppen  · files: Src/Settings/SettingsWindowController.swift, Src/Settings/SettingsWindowView.swift, Src/Settings/GeneralPane.swift  · → AC-5, AC-7, AC-9, AC-10, AC-11, AC-12, AC-13, AC-21, AC-23, EC-6

## Stufe 5 — Zusammensetzen und echt prüfen

- [ ] T12  App verdrahten: Szenen (Menüleiste, Einstellungsfenster), App-Delegate mit Start (zweite Instanz, alte App, Erststart-Autostart), erneutem Öffnen (Einstellungen), Beenden (Beenden-Regel) und Herunterfahren; Empfang der Mitteilung „Einstellungen öffnen“; Bereich „Allgemein“ anmelden  · files: App/InnoWhisperApp.swift, App/AppDelegate.swift  · → AC-1, AC-3, AC-4, AC-5, AC-6, AC-16, AC-19, AC-20, EC-1, EC-2, EC-5
- [ ] T13  Im laufenden Programm prüfen: Hell/Dunkel, „Transparenz reduzieren“, VoiceOver, nur Tastatur, Doppelstart, Wechsel auf zweiten Bildschirm, alte App (falls auf dem Mac vorhanden); offene Fragen klären (Rückfrage beim Beenden der alten App, Esc) und Ergebnis im Plan festhalten  · files: features/PROJ-1-app-rahmen-einstellungen/design.md  · → AC-2, AC-21, AC-22, AC-23

## Parallelisierung

- **Stufen sind Schranken.** Eine Stufe beginnt erst, wenn die vorige vollständig zusammengeführt und gegen ihre AC-IDs geprüft ist.
- **`[P]` verlangt getrennte Dateien.** Geprüft: Keine zwei `[P]`-Aufgaben einer Stufe nennen dieselbe Datei.
- **Grob, aber klein genug.** Je Aufgabe ein Thema und höchstens fünf Dateien.
- **Keine `[user]`-Aufgaben.** PROJ-1 braucht keine Einstellungen in fremden Konten.
- Nach Stufe 1 werden die Befehle für Bauen, Testen und Prüfen mit `/init checks` eingetragen (ADR-008).
