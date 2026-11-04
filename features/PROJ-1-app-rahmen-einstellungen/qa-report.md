# QA-Ergebnisse PROJ-1: App-Rahmen & Einstellungen

**Geprüft:** 2026-11-04
**App-Adresse:** nicht hier lauffähig (`probe.kind: none`, native Menüleisten-App). Jedes Kriterium, das die laufende App braucht, ist `[!] NOT VERIFIED`, bis ein Test durch Timur aufgezeichnet ist.
**Prüfer:** QA Engineer (KI), drei unabhängige `qa-engineer`-Prüfer (Abnahme, Sicherheit, Regression) ohne Kenntnis des Baus; zusammengeführt vom Owner.
**Umfang:** vollständig (erster Lauf)
**Testlauf:** `swift test --package-path Packages/InnoWhisperKit` einmal vor der Aufteilung: 36 Tests in 6 Suites bestanden, 0 fehlgeschlagen.

> Legende: `[x]` in diesem Lauf belegt (mit Nachweis) · `[ ] BUG` als fehlerhaft belegt · `[!] NOT VERIFIED` in diesem Lauf nicht prüfbar (mit Grund)
> „Logik“ heißt: durch Test oder Quelltext belegt, Verhalten am laufenden Programm nicht beobachtet.

## Abnahmekriterien

### Menüleiste
- [x] **AC-1** Logik: nur Menüleiste — `App/Info.plist` LSUIElement true, auch im gebauten Produkt (PlistBuddy); `App/InnoWhisperApp.swift:11-27`
  - [!] kein Dock-Symbol, kein ⌘-Tab am laufenden Programm — no way to run and probe this project was recorded
- [x] **AC-2** Logik: vier Zustände, Vorrang, VoiceOver-Text — `State/MenuBarStatus.swift:10-36`; Tests `statusPriority` (6 Fälle), `everyStatusHasDistinctSymbolAndLabel`; Symbol direkt an Zustand gebunden `MenuBar/MenuBarLabel.swift:15-17`
  - [!] Zeitgrenze 0,5 s und VoiceOver-Ausgabe am Statussymbol — nicht gemessen; ein Unit-Test belegt keine Zeitgrenze
- [x] **AC-3** Logik: Esc schließt nur das Panel-Fenster — `MenuBar/PanelWindowCloser.swift:12-29`; Klick daneben ist Systemverhalten von `.menuBarExtraStyle(.window)`
  - [!] Laufzeit, insbesondere Esc beim zweiten und dritten Öffnen (An-/Abmelden über `onAppear`/`onDisappear`, `MenuBarPanel.swift:37-38`) — no way to run and probe this project was recorded
- [x] **AC-4** Logik: beide Knöpfe immer vorhanden — `MenuBar/MenuBarPanel.swift:26-33, 41-73`
  - [!] Laufzeit — no way to run and probe this project was recorded

### Einstellungsfenster
- [x] **AC-5** Logik: genau ein Fenster, nach vorne, ⌘, belegt — `Settings/SettingsWindowController.swift:32-45, 55`; `MenuBarPanel.swift:65`
  - [!] Laufzeit — no way to run and probe this project was recorded
- [x] **AC-6** Logik: erneutes Öffnen zeigt Einstellungen — `App/AppDelegate.swift:41-44`
  - [!] Laufzeit — no way to run and probe this project was recorded
- [x] **AC-7** Logik: Reihenfolge, Namen, SF-Symbole wie `docs/app-shell.md` — `Settings/SettingsSection.swift:3-44`, `Settings/SettingsWindowView.swift:11-15`; Test `sectionOrderMatchesAppShell`
- [x] **AC-8** Logik: nur angemeldete Bereiche, PROJ-1 meldet „Allgemein“ an — `Settings/SettingsRegistry.swift:67-69`, `App/AppEnvironment.swift:26`; Test `onlyRegisteredSectionsInFixedOrder`
- [x] **AC-9** Logik: letzter Bereich, sonst „Allgemein“ — `SettingsRegistry.swift:73-86`; Tests `firstOpenShowsGeneral`, `lastSectionIsRestored`, `unknownStoredSectionFallsBack` (2 Fälle)
- [x] **AC-10** Logik: Hinweis oben im Bereich, verschwindet ohne Neustart — `SettingsWindowView.swift:28-34`, `Components/ProblemBanner.swift:13-29`, `State/ProblemCenter.swift:35-54`; Tests `problemsPerSection`, `withdrawRemovesAndIgnoresUnknown`
  - [!] Laufzeit — no way to run and probe this project was recorded
- [x] **AC-11** Logik: Hinweis im Menüleisten-Fenster öffnet betroffenen Bereich — `MenuBarPanel.swift:77-89`, `SettingsWindowController.swift:33-34`
  - [!] Laufzeit — no way to run and probe this project was recorded
- [x] **AC-12** Logik: Mindestgröße 680 × 460, Lage über Fensternamen — `SettingsWindowController.swift:16-18, 56, 62-65`
  - [!] Lage über einen Neustart der App hinweg, Mindestgröße beim Ziehen — no way to run and probe this project was recorded

### Start beim Anmelden
- [x] **AC-13** Logik: Erststart schaltet ein — `System/LoginItemController.swift:39-45`; Test `firstLaunchEnables`
  - [!] echter Autostart nach dem Anmelden am Mac — no way to run and probe this project was recorded
- [x] **AC-14** Logik: bewusstes Aus bleibt aus — `LoginItemController.swift:48-60`; Test `laterLaunchKeepsOff`
  - [!] Laufzeit nach erneutem Anmelden — no way to run and probe this project was recorded
- [x] **AC-15** Logik: Schalter liest immer macOS — `GeneralPane.swift:27`, `AppDelegate.swift:46-48`, `LoginItemController.swift:14, 63-67`; Test `refreshMirrorsMacOS`

### Alte App
- [x] **AC-16** Logik: Meldung mit Spec-Wortlaut beim Start — `App/LegacyAlerts.swift:16-21`, `System/LegacyAppGuard.swift:67-73, 84-99`; Tests `promptAndTerminate`, `betaIsDetected`
  - [!] Laufzeit — no way to run and probe this project was recorded
- [x] **AC-17** Logik: Beenden und Bestätigung — `LegacyAppGuard.swift:113-128`, `LegacyAlerts.swift:24-31`; Test `promptAndTerminate`
  - [!] Laufzeit — no way to run and probe this project was recorded
- [ ] **AC-18** BUG (BUG-1): Hinweis und Problem-Symbol verschwinden nicht, wenn der Nutzer die alte App selbst beendet. Der erste Teil (Problem-Symbol und Hinweis nach „Später“) ist per Logik belegt (`LegacyAppGuard.swift:105-106, 150-161`, `MenuBarStatus.swift:14`).

### Beenden
- [x] **AC-19** Logik: sofort beenden ohne Diktat — `System/QuitPolicy.swift:13-16`, `AppDelegate.swift:50-53`; Test `quitDecision`
  - [!] ⌘Q bei offenem Einstellungsfenster — no way to run and probe this project was recorded
- [x] **AC-20** Logik: Rückfrage mit Spec-Wortlaut, „Abbrechen“ Standard, „Beenden“ destruktiv — `QuitPolicy.swift:8-11`, `AppDelegate.swift:54-63`; Tests `confirmationWording`, `quitDecision`
  - [!] Laufzeit — no way to run and probe this project was recorded; vor PROJ-5 gibt es keine echte Aufnahme

### Aussehen und Bedienbarkeit
- [!] **AC-21** Hell/Dunkel, Lesbarkeit, gleiche Knopfgrößen — no way to run and probe this project was recorded. Code: Knopfleiste im Glas-Container, alle `.controlSize(.regular)` (`MenuBarPanel.swift:50-73`). Auffällig: Der Knopf im Problem-Hinweis nutzt den Standard-Knopfstil, der Hinweis einen orangen Hintergrund statt Glas (`ProblemBanner.swift:23-27`); `docs/design-system.md` verlangt Glas für Hinweise und einheitliche Knöpfe. Am Bildschirm prüfen (siehe Test mit Timur).
- [x] **AC-22** Logik: eigene Prüfung von „Transparenz reduzieren“, dann feste Knopfstile — `MenuBarPanel.swift:12, 43-48`
  - [!] Fensterhintergrund des Panels und Laufzeit — no way to run and probe this project was recorded
- [!] **AC-23** Tastaturfokus und VoiceOver — no way to run and probe this project was recorded. Code: alle Knöpfe beschriftet, Statussymbol mit `accessibilityLabel` (`MenuBarLabel.swift:17`), Hinweis als Container „Problem: …“ (`ProblemBanner.swift:28-29`), kein entfernter Fokusring.

## Sonderfälle

- [x] **EC-1** Logik: zweites Exemplar übergibt und beendet sich — `AppDelegate.swift:15-25`, `System/SingleInstanceGuard.swift:9-27`; Test `findsOtherInstance`; Gegenprobe: `runningApplications` enthält auch Menüleisten-Apps
  - [!] ob das Fenster der ersten Instanz wirklich vorne aufgeht (kooperative Aktivierung seit macOS 14) — no way to run and probe this project was recorded
- [ ] **EC-2** BUG (BUG-1): Startet die alte App, während InnoWhisper läuft, erscheint keine Meldung. Die Logik `check()` ist korrekt (Test `launchedLaterPromptsOncePerInstance`), wird aber nie ausgelöst.
- [x] **EC-3** Ablauf per Logik: höflich, nach 2 s sofort, nach 5 s Anleitung — `LegacyAppGuard.swift:113-148`; Tests `forceAfterTwoSeconds`, `instructionsAfterFiveSeconds`
- [ ] **EC-3** BUG (BUG-2): Text der Anleitung nennt den falschen Namen.
- [x] **EC-4** Logik für die getesteten Stände — `LoginItemController.swift:63-128`; Tests `requiresApprovalShowsHint`, `refusalOutsideApplicationsAsksToMove`, `refusalInsideApplicationsOffersRetry`, `switchingOffClearsHint`, `detectsUserApplicationsFolder`
- [ ] **EC-4** BUG (BUG-3): Bei macOS-Stand „nicht gefunden“ bleibt der Hinweis auch nach bewusstem Ausschalten.
  - [!] echter Ablauf mit SMAppService — no way to run and probe this project was recorded
- [x] **EC-5** Logik: Herunterfahren setzt Merker, dann ohne Dialog — `AppDelegate.swift:31-36`, `QuitPolicy.swift:14`; Test `quitDecision`; Gegenprobe: Beobachter mit `queue: .main` läuft synchron
  - [!] Reihenfolge `willPowerOff` vor `applicationShouldTerminate` und Abmelden bei offenem Dialog — no way to run and probe this project was recorded
- [x] **EC-6** Logik: 80-%-Regel bei jedem Öffnen — `System/WindowFramePolicy.swift:12-34`, `SettingsWindowController.swift:40, 69-73`; 5 Tests in `WindowFramePolicyTests`
  - [!] echter zweiter Bildschirm — no way to run and probe this project was recorded

## Sicherheit

Plattform `desktop`, keine Konten, kein HTTP, kein Modell. Gewählte Kontrollen: SEC-01, SEC-02, SEC-08, SEC-03 (nur lokale Daten). SEC-04 bis SEC-07 entfallen.

- [!] Anmeldung umgehen — nicht anwendbar: keine Konten, keine geschützten Zugänge (SEC-03/04)
- [!] Zugriff auf Daten anderer Nutzer — nicht anwendbar: nur UserDefaults des angemeldeten Nutzers
- [x] Eingaben von außen (SEC-02): Mitteilung der zweiten Instanz wertet nur den Namen aus (`SingleInstanceGuard.swift:24-26`); NSWorkspace-Ereignisse lösen nur eine neue Abfrage aus (`RunningApplications.swift:47-55`); gespeicherter Bereich fällt bei ungültigem Wert auf „Allgemein“ (Test `unknownStoredSectionFallsBack`); keine URL-Schemata, Dokumenttypen oder Dienste in der gebauten `Info.plist` (`plutil -p`); kein Netzwerk, kein `Process`, kein `kill` (`grep` → 0 Treffer)
- [ ] BUG (BUG-5): Mitteilung „Einstellungen öffnen“ ohne Drosselung
- [!] Drosselung allgemein — nicht eingebaut (für MVP optional)
- [!] Brute Force, Konten-Erkennung, Zugangsdaten in URL — nicht anwendbar: keine Zugangsdaten, keine Formulare, kein HTTP (SEC-04/05)
- [x] Wächter beendet nur die alte App: exakter Abgleich auf genau zwei Kennungen (`LegacyAppGuard.swift:21-24, 76-80`), Liste vor jedem Beenden frisch abgefragt (`:114-119, :132`); Test `promptAndTerminate` mit fremder App beendet nur pid 100
- [x] Protokoll ohne Diktat-Inhalte und Personendaten: alle 11 Protokoll-Aufrufe geprüft (`grep -rn "Log\.|launchLog|Logger(|print(|NSLog|os_log" App Packages/InnoWhisperKit/Sources`); öffentlich nur Anzahlen, Aufzählungswerte, Bereichskennung, SMAppService-Fehlertext
- [x] Keine Geheimnisse im Programm (SEC-01): `strings` über das Release-Programm → nur ein Objective-C-Selektor, kein Wert; Entitlements-Datei leer
- [x] Keine Geheimnisse in der Git-Historie (SEC-01): `git log --all -p` und Dateinamen-Suche über alle Commits → keine Werte, keine Schlüsseldateien; `.gitignore` schließt `.env*` aus
- [x] Lokale Daten (SEC-03): nur `settings.lastSection`, `autostart.firstLaunchDone`, Fensterlage `InnoWhisperSettings` in den UserDefaults
- [x] Tastaturbeobachtung nur lokal, nur eigenes Fenster, nur Esc — `PanelWindowCloser.swift:14-19`; keine globalen Beobachter (`grep` → 0)
- [x] Projekteinstellung Sandbox aus, Hardened Runtime an, keine zusätzlichen Berechtigungen (ADR-007) — `project.pbxproj:195-196, 219-220`, `App/InnoWhisper.entitlements` leer
- [ ] BUG (BUG-4): gebaute Programme halten ADR-007 nicht vollständig ein
- [x] Keine abgeschwächten Prüfungen (SEC-08): keine deaktivierten Tests, keine Format-Ausnahmen (`grep` → 0)
- [x] Keine `[user]`-Aufgaben offen — `tasks.md`: keine vorhanden
- [!] Abmelden/Herunterfahren bei offenem Dialog, Fokus-Übernahme durch fremde Mitteilung, tatsächliche Protokoll-Einträge zur Laufzeit — no way to run and probe this project was recorded

## Regression

- [!] Ausgelieferte Features — keine vorhanden (`features/INDEX.md`: kein Feature „Deployed“)
- [x] Testlauf: 36 bestanden, 0 fehlgeschlagen, 0 Warnungen
- [x] Stilprüfung: `swift format lint --strict --recursive App Packages` → keine Meldung
- [x] Bau: `xcodebuild … -configuration Debug … build` → BUILD SUCCEEDED, 0 Warnungen, 0 Fehler
- [x] Arbeitsbaum sauber: nur Statusänderung in `features/INDEX.md`; `.build/` über `.gitignore:4` ausgeschlossen
- [x] Bereichskennungen in `docs/app-shell.md` = Code (`SettingsSection.swift:4-11, 22-29, 35-42`)
- [ ] BUG (BUG-6, BUG-7): Bausteintabelle in `docs/app-shell.md` weicht vom Code ab
- [x] `docs/data-model.md` passt zum Code: nur Ding „Einstellungen“, lokal, keine neue Entität

## Unit-Tests

Keine zusätzlichen Unit-Tests in diesem Lauf. Die isolierte Logik ist durch die 36 vorhandenen Tests abgedeckt, die beim Bau einzeln rot geprüft wurden. Die gefundenen Lücken (BUG-1, BUG-3, BUG-8 bis BUG-10) sind Fehler im Code: `/build` schreibt dafür je Fehlerart einen Test, der zuerst rot ist.

## E2E-Tests
- Status: **nicht gelaufen** (`/e2e-tests` gibt es für diese Plattform nicht im Kit; Browser-Tests passen nicht zu einer Menüleisten-App)

## In diesem Lauf nicht geprüft

- [!] Alle Laufzeit-Beobachtungen zu AC-1 bis AC-23 und EC-1 bis EC-6 — no way to run and probe this project was recorded (`probe.kind: none`)
- [!] Zeitgrenze 0,5 s (AC-2) — nicht gemessen
- [!] Hell/Dunkel, Kontrast, Knopfhöhen, Fokusring, VoiceOver (AC-21 bis AC-23) — brauchen Bildschirm und Bedienung
- [!] echtes An- und Abmelden am Mac (AC-13, AC-14), Fensterlage über Neustart (AC-12), ⌘Q bei offenem Einstellungsfenster (AC-19), zweiter Bildschirm (EC-6), Reihenfolge beim Herunterfahren (EC-5)
- [!] Hinweis: Timur hat während `/build` (Aufgabe T13, 04.11.2026) am laufenden Programm bestätigt: Meldung zur alten App und Beenden, Menüleisten-Fenster mit gleich großen Glas-Knöpfen, Einstellungsfenster mit „Allgemein“, Ausschalten von „Start beim Anmelden“, Esc nach Korrektur. Das war vor diesem Prüflauf und ist hier nicht als bestanden gezählt; die Wiederholung kommt als aufgezeichneter Test nach den Korrekturen.

## Gefundene Fehler

#### BUG-1: Alte App wird nach dem Start von InnoWhisper nicht mehr bemerkt
- **Schwere:** High
- **Status:** Fixed (2026-11-04, re-verified)
- **Fehlerart:** Erkennung laufender Apps hängt an den macOS-Mitteilungen „App gestartet/beendet“, die macOS für Menüleisten-Apps (LSUIElement) nicht schickt; die Tests ersetzen genau diese Verdrahtung durch eine Attrappe.
- **Kontrolle / AC:** EC-2, AC-18 (Pflichtpunkt 1)
- **Sweep:** `grep -rn "didLaunchApplicationNotification\|didTerminateApplicationNotification" App Packages/InnoWhisperKit/Sources` — 1 Treffer (`RunningApplications.swift:49`)
- **Nachstellen:**
  1. InnoWhisper starten, während keine alte App läuft.
  2. `/Applications/InnoWhisper.app` (alte Version) starten.
  3. Erwartet: Meldung „Die alte Version läuft noch …“.
  4. Tatsächlich: keine Meldung. Ebenso bleibt nach „Später“ und eigenem Beenden der alten App das Problem-Symbol stehen.
- **Beleg:** Gegenprobe mit Wegwerf-App `LSUIElement=true`: keine Start-/Beenden-Mitteilung, als normale Dock-App je eine; `lsappinfo` zeigt die alte App als `type="UIElement"`.

#### BUG-2: Anleitung zum Beenden nennt einen Namen, den der Nutzer nicht findet
- **Schwere:** Medium
- **Status:** Fixed (2026-11-04, re-verified)
- **Fehlerart:** Für den Nutzer sichtbare Texte nennen den internen Namen (ausführbare Datei) statt des angezeigten App-Namens.
- **Kontrolle / AC:** EC-3
- **Sweep:** `grep -rn "WhisperDictation" App Packages/InnoWhisperKit/Sources` — 3 Treffer, davon 1 sichtbar (`App/LegacyAlerts.swift:40`); die zwei Kennungen in `LegacyAppGuard.swift:22-23` sind korrekt
- **Nachstellen:** Text „Suche nach WhisperDictation“ mit `lsappinfo` vergleichen: die alte App heißt im System „InnoWhisper“ bzw. „InnoWhisper Beta“. Folge: Nutzer findet sie nicht oder beendet versehentlich die neue InnoWhisper.

#### BUG-3: Hinweis zum Autostart bleibt nach bewusstem Ausschalten stehen
- **Schwere:** Medium
- **Status:** Fixed (2026-11-04, re-verified)
- **Fehlerart:** Problem-Meldung hängt am macOS-Stand statt an der Absicht des Nutzers.
- **Kontrolle / AC:** EC-4 (design.md: Hinweis wird zurückgezogen, wenn der Nutzer bewusst aus lässt)
- **Sweep:** `grep -rn "case \.notFound" Packages/InnoWhisperKit/Sources` — 2 Treffer, betroffen `LoginItemController.swift:80`
- **Nachstellen:** macOS meldet „nicht gefunden“ → Nutzer schaltet „Start beim Anmelden“ aus → Hinweis und Problem-Symbol bleiben dauerhaft. Die Testattrappe setzt beim Abmelden immer „nicht angemeldet“, der Pfad ist ungetestet.

#### BUG-4: Gebaute Programme halten die Härtung aus ADR-007 nicht vollständig ein
- **Schwere:** Medium (wird High ab PROJ-3, sobald Mikrofon und Bedienungshilfen erlaubt sind)
- **Status:** Fixed (2026-11-04, re-verified)
- **Fehlerart:** Signatur des benutzten bzw. auszuliefernden Programms entspricht nicht der Härtungszusage der Architektur-Entscheidung.
- **Kontrolle / AC:** SEC-08, ADR-007
- **Sweep:** `grep -c 'CODE_SIGN_IDENTITY = "-"' InnoWhisper.xcodeproj/project.pbxproj` — 2 Treffer; je Konfiguration `codesign -d --entitlements - --xml <app>`: 2 von 2 betroffen
- **Nachstellen:**
  1. Debug: `codesign -dv` → Flags nur `adhoc`, keine Hardened Runtime (`-o runtime` fehlt beim Signieren).
  2. Release: Hardened Runtime gesetzt, aber `com.apple.security.get-task-allow = true` → fremde Prozesse des Nutzers können sich anhängen; Apple beglaubigt so nicht.

#### BUG-5: Mitteilung „Einstellungen öffnen“ ohne Drosselung
- **Schwere:** Low
- **Status:** Deferred (entschieden von Timur, 2026-11-04)
- **Fehlerart:** Signal von außen löst ohne Drosselung eine Bedien-Aktion aus.
- **Kontrolle / AC:** SEC-02, EC-1
- **Sweep:** `grep -rn "DistributedNotificationCenter" App Packages/InnoWhisperKit/Sources` — 2 Treffer, betroffen nur der Empfänger (`SingleInstanceGuard.swift:21`)
- **Nachstellen:** Ein beliebiger lokaler Prozess sendet die Mitteilung in einer Schleife → InnoWhisper holt das Einstellungsfenster jedes Mal nach vorne.

#### BUG-6: Ordner des Problem-Hinweises fehlt in `docs/app-shell.md`
- **Schwere:** Low
- **Status:** Deferred (entschieden von Timur, 2026-11-04)
- **Fehlerart:** Code-Ordner gemeinsamer Bausteine nicht in der Rahmen-Doku nachgeführt.
- **Kontrolle / AC:** AC-10
- **Sweep:** `for d in Packages/InnoWhisperKit/Sources/AppShell/*/; do grep -q "$d" docs/app-shell.md || echo $d; done` — 2 Treffer, betroffen `Components/`
- **Nachstellen:** `docs/app-shell.md:74` nennt `State/`, `ProblemBanner` liegt in `Components/ProblemBanner.swift`.

#### BUG-7: Namen der Diktat-Tätigkeit in der Doku passen nicht zum Code
- **Schwere:** Low
- **Status:** Deferred (entschieden von Timur, 2026-11-04)
- **Fehlerart:** Deutsche Bezeichnungen in Code-Schreibweise in gemeinsamen Verträgen, die nicht zum Code passen.
- **Kontrolle / AC:** Vertrag für PROJ-5/PROJ-6
- **Sweep:** `grep -rn 'ruhend\|nimmtAuf\|wandeltUm' docs features/*/design.md` — 5 Treffer
- **Nachstellen:** Doku nennt `ruhend` / `nimmtAuf` / `wandeltUm`, Code heißt `idle` / `recording` / `transcribing` (`DictationActivity.swift:5-8`).

#### BUG-8: Merker „Mac fährt herunter“ wird nie zurückgesetzt
- **Schwere:** Low
- **Status:** Deferred (entschieden von Timur, 2026-11-04)
- **Fehlerart:** Einmal gesetzter Zustandsmerker ohne Rücksetzung.
- **Kontrolle / AC:** AC-20, EC-5
- **Sweep:** `grep -rn "systemIsShuttingDown = " App` — 1 Treffer (nur `= true`, `AppDelegate.swift:35`)
- **Nachstellen:** Eine andere App bricht das Abmelden ab → später ⌘Q während eines Diktats → App beendet ohne Rückfrage.

#### BUG-9: „Später“ meldet ein Problem, obwohl die alte App inzwischen beendet ist
- **Schwere:** Low
- **Status:** Deferred (entschieden von Timur, 2026-11-04)
- **Fehlerart:** Zustand nach einem Dialog wird nicht neu geprüft.
- **Kontrolle / AC:** AC-18
- **Sweep:** none
- **Nachstellen:** Meldung offen lassen, alte App selbst beenden, dann „Später“ → Problem-Symbol erscheint ohne Grund.

#### BUG-10: Doppelklick auf „Alte Version beenden“ startet zwei Beenden-Abläufe
- **Schwere:** Low
- **Status:** Deferred (entschieden von Timur, 2026-11-04)
- **Fehlerart:** Wiederholbare Aktion ohne Sperre gegen paralleles Auslösen.
- **Kontrolle / AC:** AC-17, EC-3
- **Sweep:** none
- **Nachstellen:** Im Hinweis schnell zweimal klicken → zwei Abläufe parallel, unter Umständen zwei Bestätigungsfenster.

#### BUG-11: Fensterlage-Regel nimmt den Bildschirm mit Tastaturfokus und rechnet geteilte Fenster nicht zusammen
- **Schwere:** Low
- **Status:** Deferred (entschieden von Timur, 2026-11-04)
- **Fehlerart:** Bildschirmwahl und Sichtbarkeits-Anteil nicht wie im Plan beschrieben.
- **Kontrolle / AC:** EC-6
- **Sweep:** none
- **Nachstellen:** `SettingsWindowController.swift:71` nutzt `NSScreen.main` (Bildschirm mit Fokus) statt des Hauptbildschirms; ein je zur Hälfte auf zwei Bildschirmen liegendes Fenster (0,5 + 0,5) wird trotzdem in die Mitte versetzt (`WindowFramePolicy.swift:15-21`).

## Nachprüfung (2026-11-04)

Zwei Runden nach den Korrekturen von `/build`, jeweils von frischen `qa-engineer`-Prüfern ohne Kenntnis des Baus.
- Runde 1, Umfang `git diff --stat 16f13cf..HEAD` (5 Produktionsdateien: `App/LegacyAlerts.swift`, `InnoWhisper.xcodeproj/project.pbxproj`, `LegacyAppGuard.swift`, `LoginItemController.swift`, `RunningApplications.swift`), volle Breite mit drei Spuren.
- Runde 2, Umfang `git diff --stat 2552fa5..HEAD` (`LoginItemController.swift`, `SettingsWindowController.swift`), eine Spur mit allen drei Bereichen.
- Danach eine Korrektur der Fensterbreite (`2cc3936`, `SettingsWindowView.swift`), geprüft durch Messung im Protokoll und Timurs Sichtprüfung.
- Testlauf zuletzt: `swift test --package-path Packages/InnoWhisperKit` → 41 Tests in 6 Suites bestanden. Stilprüfung und Bau ohne Meldung.

### Offene Fehler
- [x] **BUG-1** geschlossen — Sweep `grep -rn "didLaunchApplicationNotification\|didTerminateApplicationNotification" App Packages/InnoWhisperKit/Sources` → 0 Treffer; Gegenprobe mit Menüleisten-Test-App: Beobachtung von `runningApplications` meldet Start und Ende; live: alte App 5 s nach InnoWhisper gestartet → Meldung erschien, Timur beendete sie (Protokoll 13:52:31, „Legacy app running … new: true“)
- [x] **BUG-2** geschlossen — Sweep `grep -rn "WhisperDictation" App Packages/InnoWhisperKit/Sources` → 2 Treffer, beide erlaubte Kennungen; Test `instructionsNameVisibleAppAndPID`
- [x] **BUG-3** geschlossen (Fehlerart) — Runde 1 fand eine weitere Stelle („wartet auf Erlaubnis“), in `c9c662f` behoben; Sweep `grep -n "problems.report\|reportRefusal()" …/LoginItemController.swift` → alle Meldestellen in `refresh()` beachten die Absicht; Tests `deliberateOffClearsHintEvenWhenNotFound`, `deliberateOffClearsHintWhenApprovalPending`, `enabledOutsideAppResetsDeliberateOff`, `switchingOnAgainShowsRefusal`
- [x] **BUG-4** geschlossen — Debug und Release frisch gebaut: `codesign -dv` → `flags=0x10002(adhoc,runtime)` für beide; Release-Berechtigungen leer; Debug behält `get-task-allow` als festgehaltene Ausnahme (`docs/decisions.md`, ADR-007)

### Neue Funde der Nachprüfung
- **Fensterbreite (BUG-12)**: In einem breiten Fenster stand der Inhalt von „Allgemein“ mittig (Timur, live). Behoben mit Höchstbreite 760 pt; erste Fassung wirkte nicht (Apples Fensterbaustein überschrieb die Grenze), zweite Fassung im Protokoll gemessen („max width 760“) und von Timur bestätigt.
- **Plan-Texte** (alte Anleitung, neuer Merker in `design.md`) nachgeführt in `c9c662f`.
- **BUG-5 erweitert**: Die Beobachtung von `runningApplications` ist ein zweiter ungedrosselter Auslöser derselben Fehlerart (wiederholte Starts einer gefälschten alten App lösen wiederholt die Rückfrage aus). Sweep jetzt: `grep -rnE "DistributedNotificationCenter|observe\(\\.runningApplications" App Packages/InnoWhisperKit/Sources` → 2 Empfänger. Bleibt Deferred.
- **BUG-13** (Low, Deferred): Erststart mit veralteter Absicht „bewusst aus“ unterdrückt den Autostart-Hinweis. Nur erreichbar, wenn jemand den Erststart-Merker von Hand löscht. Fehlerart: automatisches Einschalten löscht die gespeicherte Gegen-Absicht nicht. Sweep: `grep -n "attemptRegister()" Packages/InnoWhisperKit/Sources/AppShell/System/LoginItemController.swift` → 3 Treffer, betroffen `:45`.
- Vom Diff berührt, unverändert offen und weiter Deferred: BUG-9, BUG-10. Nicht berührt: BUG-6, BUG-7, BUG-8, BUG-11 (BUG-6 und BUG-7 betreffen `docs/app-shell.md`).

### Aufgezeichneter Test durch Timur (2026-11-04, sein Mac mit macOS 26.5, Testversion)
- [x] **AC-1** Symbol in der Menüleiste, kein Dock-Symbol, nicht in ⌘-Tab — Timur: passt
- [x] **AC-2** Symbol zeigt „Problem“ (Warndreieck) bei offenem Autostart-Hinweis und „bereit“ (Mikrofon) nach dem Ausschalten — Timur: passt
- [x] **AC-3** Esc schließt das Menüleisten-Fenster, auch beim erneuten Öffnen — Timur: passt
- [x] **AC-4** Knöpfe „Einstellungen …“ und „InnoWhisper beenden“, gleich groß, Glas — Timur: passt
- [x] **AC-5** ⌘, öffnet die Einstellungen, nur ein Fenster — Timur: passt
- [x] **AC-7, AC-9** Seitenleiste mit „Allgemein“, öffnet dort — Timur: passt
- [x] **AC-10, AC-11** Hinweis im Menüleisten-Fenster öffnet „Allgemein“ mit demselben Hinweis oben; Hinweis verschwindet beim Ausschalten — Timur: passt
- [x] **AC-12** Fenstergröße bleibt nach Schließen und Öffnen; Höchstbreite greift — Timur: passt
- [x] **AC-14** (In-App-Teil) Ausschalten wirkt, Hinweis verschwindet — Timur: passt
- [x] **AC-16, AC-17, EC-2** Meldung zur alten App beim Start und beim späteren Start, „Alte Version beenden“ beendet sie — Timur live, Protokoll 13:06 und 13:52
- [x] **AC-21** Hell und Dunkel gut lesbar — Timur: passt
- [x] **AC-23** Tab-Taste zeigt sichtbaren Fokus — Timur: passt
- [x] **AC-6, EC-1** erneutes Öffnen und zweites Exemplar → Einstellungen, nur ein Prozess — Protokoll und `pgrep` (13:12)

### Weiterhin nicht geprüft
- [!] **AC-22** „Transparenz reduzieren“ — der Schritt war optional; Timur meldete „passt“ für die Prüfung, ob dieser Schritt dabei war, ist nicht eindeutig
- [!] **AC-13, AC-14** echtes Ab- und Anmelden am Mac; **AC-19** ⌘Q bei offenem Einstellungsfenster; **AC-20** Rückfrage bei laufendem Diktat (erst mit PROJ-5 echte Aufnahmen); **EC-5** Herunterfahren; **EC-6** zweiter Bildschirm; **AC-2** gemessene Zeitgrenze 0,5 s und VoiceOver-Ausgabe; **EC-3** Darstellung in der Aktivitätsanzeige

## Zusammenfassung
- **Abnahmekriterien:** alle 23 per Logik belegt; 14 davon zusätzlich am laufenden Programm durch Timur oder das Protokoll bestätigt; AC-22 und die oben genannten Laufzeitfälle nicht geprüft. Sonderfälle: alle 6 per Logik belegt, EC-1 und EC-2 auch live.
- **Fehler:** 13 insgesamt (0 Critical, 1 High, 3 Medium, 9 Low). Behoben und nachgeprüft: BUG-1 bis BUG-4 und BUG-12. Deferred: BUG-5 bis BUG-11, BUG-13 (alle Low). Open: keiner.
- **Sicherheit:** BUG-4 geschlossen; Ausnahme `get-task-allow` nur im Debug-Bau festgehalten (ADR-007); keine neuen Befunde über Low.
- **Produktionsreif:** JA — keine offenen Critical- oder High-Fehler, Laufzeitkriterien durch aufgezeichneten Test von Timur ausgeübt. Nicht geprüft bleiben die oben genannten Punkte.
- **Empfehlung:** Freigeben (Approved). Die 8 zurückgestellten kleinen Fehler gesammelt mit `/build PROJ-1 deferred` beheben, spätestens vor der Auslieferung (PROJ-14).
