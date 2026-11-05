# QA-Ergebnisse PROJ-3: Erlaubnisse & Einführung

**Geprüft:** 2026-11-05 (Nachprüfung nach der Korrektur von BUG-1 bis BUG-6)
**App-Adresse:** nicht hier lauffähig (`probe.kind: none`, native Menüleisten-App). Laufzeitkriterien sind `[!] NOT VERIFIED`, außer wo ein Test durch Timur aufgezeichnet ist (Protokollzeilen der App gegen Zeitstempel von macOS/tccd).
**Prüfer:** QA Engineer (KI). Drei unabhängige `qa-engineer`-Prüfer (Abnahme, Sicherheit, Regression) ohne Kenntnis des Baus; zusammengeführt vom Owner, dazu ein Test durch Timur mit dem fertigen Bau.
**Umfang:** Nachprüfung in der Breite der Korrektur. Grundlage `git diff --stat f2154a4..HEAD` (f2154a4 = Commit des vorigen Berichts, HEAD = 3c1d11b). Geänderte Produktionsdateien:
- `Packages/InnoWhisperKit/Sources/Permissions/PermissionChecking.swift`
- `Packages/InnoWhisperKit/Sources/Permissions/PermissionMonitor.swift`
- `Packages/InnoWhisperKit/Sources/Permissions/PermissionSteps.swift`
- `Packages/InnoWhisperKit/Sources/Permissions/PermissionStepView.swift`
- `Packages/InnoWhisperKit/Sources/Onboarding/WelcomeAndDoneViews.swift`
- dazu geteilte Dokumente `docs/decisions.md` und `features/PROJ-1-app-rahmen-einstellungen/spec.md`, deshalb volle Aufteilung auf drei Prüfer
**Testlauf:** `swift test --package-path Packages/InnoWhisperKit` einmal vor der Aufteilung (16:33): 119 Tests in 18 Suites bestanden, 0 Fehlschläge.
**Geprüfter Bau:** Debug-Bau vom 05.11. 16:23:48 (Codestand von 3c1d11b, `stat` der Binärdatei), Prozess gestartet 16:40:19 nach Zurücksetzen von Mikrofon, Bedienungshilfen und Einführungs-Fortschritt.

> Legende: `[x]` in diesem Lauf belegt (mit Nachweis) · `[ ] BUG` als fehlerhaft belegt · `[!] NOT VERIFIED` nicht prüfbar (mit Grund) · „übernommen“ = unverändert seit dem Bericht vom 05.11. vormittags, in diesem Lauf nicht neu geprüft, weil der Diff die Dateien nicht berührt.

## Abnahmekriterien

### Ablauf der Einführung
- AC-1, AC-2, AC-5, AC-7 — übernommen (Diff berührt `OnboardingFlow.swift`, `OnboardingView.swift`, `OnboardingWindowController.swift` nicht)
- [x] **AC-3** Text wortgleich zur Spec — `WelcomeAndDoneViews.swift:8-11`; im Diff nur `.symbolRenderingMode` (`:46`)
- [x] **AC-4** Text wortgleich — `WelcomeAndDoneViews.swift:22-23`; Test `fertigStoresFinishAndCallsBack` im Testlauf bestanden
- [x] **AC-6** Erklärsätze — `PermissionSteps.swift:25-30`; Test `explanationsSayWhyItIsNeeded` bestanden

### Erlaubnisse in der Einführung
- [ ] **BUG-7 AC-8** Mikrofon in der Einführung erlaubt, App erkennt es nicht. Test durch Timur, 05.11.: macOS meldet die Erlaubnis 16:41:55,413 (tccd „Create kTCCServiceMicrophone“), bis 16:43:43 (108 s) keine Zeile „Permission changed“, kein grünes Häkchen; weitere Klicks lösen nur „Microphone permission requested“ aus (16:42:16 bis 16:43:07). Die Abnahme-Lane hatte das Risiko vorab benannt: Anfrage über `AVCaptureDevice.requestAccess` (`PermissionChecking.swift:39-41`), Stand über `AVAudioApplication` (`:26-33`). Siehe BUG-7.
- [x] **AC-9** Satz „Schalte dort InnoWhisper ein.“ — `PermissionSteps.swift:54`; Test `settingsOpenAtTheRightPage` bestanden
- [!] **AC-10** Bedienungshilfen mit dem fertigen Bau — durch BUG-7 nicht erreicht (Einführung bleibt beim Mikrofon stehen); Mikrofon über die Systemeinstellungen mit dem fertigen Bau erteilt und nach 1,03 s erkannt (tccd 16:25:38,052, Protokoll 16:25:39,078)
- [x] **AC-11** Logik: Hinweistexte für abgelehnt und gesperrt — `PermissionSteps.swift:50-53`; Test `hintsExplainWhatToDo` bestanden
  - [!] echter Klick auf „Nicht erlauben“ — no way to run and probe this project was recorded; Test durch Timur folgt nach BUG-7

### Fenster, Beenden, Einstellungen
- AC-12, AC-13, AC-14 — übernommen
  - [!] AC-12 echte Tasten Esc und ⌘W: Timur hat Runde 1 vor diesem Schritt begonnen, Ergebnis nicht gemeldet
  - [!] AC-13 Beenden mitten in der Einführung am echten Programm — noch nicht getestet

### Später entzogene Erlaubnis
- [ ] **BUG-1 AC-15** Mikrofon-Hälfte belegt mit dem fertigen Bau: im Hintergrund ausgeschaltet 16:28:00,464 (tccd), erkannt 16:28:02,450 (1,99 s, Grenze 5 s); Test durch Timur, 05.11. Bedienungshilfen-Hälfte `[!] NOT VERIFIED`: Die Messung 16:16:23 in `design.md` stammt von Prozess 52130 (Start 12:16:26), also einem früheren Bau; der Test mit dem fertigen Bau wurde durch BUG-7 nicht erreicht. Keine erneute Einführung: Test `revokedPermissionAfterFinishDoesNotReopen` bestanden.
- [ ] **BUG-1 AC-16** Mikrofon wieder erteilt im Hintergrund nach 1,03 s erkannt (siehe AC-10). Bedienungshilfen offen wie AC-15. Tests `missingPermissionsAreReportedAfterOnboardingWithOwnButton`, `problemDisappearsWhenPermissionComesBack` bestanden.
- [x] **AC-17** Stand „Erlaubt“/„Nicht erlaubt“ — `PermissionStepView.swift:45-60`; im Diff nur `.symbolRenderingMode`
  - [!] Darstellung — no way to run and probe this project was recorded

### Wachsende Einführung, Protokoll, Bedienbarkeit
- AC-18, AC-19 — übernommen
- [x] **AC-20** Protokollzeilen bei Änderungen — `PermissionMonitor.swift:107,110`; mit dem fertigen Bau gesehen 16:25:39,078 und 16:28:02,450 in `~/Library/Logs/InnoWhisper/InnoWhisper.log`
- [x] **AC-21** Logik: Überschrift `.isHeader`, Symbol vor VoiceOver verborgen, Ansage „Erlaubt“ — `WelcomeAndDoneViews.swift:49,53`, `PermissionStepView.swift:37-40,58`
  - [!] Tastatur und echte VoiceOver-Ausgabe — no way to run and probe this project was recorded
- [x] **AC-22** Symbole jetzt hierarchisch (`WelcomeAndDoneViews.swift:46`, `PermissionStepView.swift:53`), Knopfgröße `.regular` (`PermissionStepView.swift:18,32`)
  - [ ] BUG-3 Rest (Low): Knopfstile, siehe unten
  - [!] Hell- und Dunkelmodus — no way to run and probe this project was recorded

## Grenzfälle
- [x] **EC-1** erste Prüfung im Konstruktor `PermissionMonitor.swift:55`; Test `alreadyGrantedStepsAreShownOnFirstStart` bestanden
- [x] **EC-2** Test `revokedEarlierPermissionJumpsBack` bestanden; Ablauf nicht im Diff
- [x] **EC-3** Logik unverändert `PermissionMonitor.swift:148-161`; Test `restartIsOfferedTenSecondsAfterReturningWithoutGrant` bestanden
  - [!] echter Neustart — no way to run and probe this project was recorded
- [x] **EC-4** Vermerk jetzt in PROJ-1 (`features/PROJ-1-app-rahmen-einstellungen/spec.md:55`); Umfang siehe BUG-9
- EC-5 — übernommen

## Sicherheitsprüfung

Angewendet nach `docs/kit/guides/security.md`: SEC-01, SEC-02, SEC-08 (Diff berührt SEC-03 nicht).

- [x] Keine Geheimnisse in git (SEC-01): `git log -p f2154a4..HEAD | grep -nE "gsk_|sk-[A-Za-z0-9]{10}|api_key|PRIVATE KEY|ghp_|github_pat_|AKIA|password *=|secret *=|token *="` — 0 Treffer
- [x] Keine Geheimnisse im Programm: `strings` über den Debug-Bau 16:23, `gsk_|sk-|PRIVATE KEY` — 0 Treffer
- [x] Protokoll ohne Inhalte: Diff fügt keine Protokollzeile hinzu (grep über `^\+` nach Log-Aufrufen, 0 Treffer); bestehende Zeilen setzen nur Aufzählungswerte ein (`PermissionMonitor.swift:107,110,123,157`)
- [x] Kein nachgeladener Code: `grep -rnE "dlopen|dlsym|NSClassFromString|Bundle\(path|performSelector|@_spi" App Packages/InnoWhisperKit/Sources` — 0 Treffer; `otool -L` nur Systemframeworks
- [x] Nur öffentliche Schnittstellen neu: `AVAudioApplication.recordPermission`, `ProcessInfo.beginActivity`, `DistributedNotificationCenter.addObserver(…suspensionBehavior:)`. Undokumentiert ist nur der Mitteilungsname `com.apple.accessibility.api` (schon vor dem Diff), mit der 3-s-Abfrage als Rückfall
- [x] Mitteilung von außen (SEC-02): `listChanged` liest keinen Inhalt, löst nur `refresh()` aus (`PermissionMonitor.swift:198-200`), kein falscher Stand möglich. Fehlende Drosselung siehe BUG-8
- [x] Berechtigungen und Unterschrift: Entitlements nur `audio-input`; Hardened Runtime in beiden Konfigurationen (`project.pbxproj:211,237`); Diff ändert keine dieser Dateien
- [x] Keine abgeschwächten Prüfungen (SEC-08): eine Erwartung ersetzt durch zwei strengere (`PermissionStepsTests.swift`), keine abgeschalteten Tests (`grep -rnE "\.disabled|withKnownIssue|\.enabled\(if"` 0 Treffer), `.swift-format` unverändert
- [x] SEC-08-Ausnahme Debug `get-task-allow` (BUG-6): Eintrag mit Kontroll-ID, Umfang, Zustimmung, Ausgleich und Neuprüfung in `docs/decisions.md:49`; Ausgleich gegengeprüft: `DevToolsSecurity -status` „Developer mode is currently disabled.“, Release `CODE_SIGN_INJECT_BASE_ENTITLEMENTS = NO` (`project.pbxproj:228`)
- [!] Release-Bau (Entitlements, `strings`) — in diesem Lauf nicht gebaut, braucht den Schlüsselbund
- [!] Anmeldung, Autorisierung zwischen Nutzern, Rate Limiting, Brute Force (SEC-04), URL/Kopfzeilen (SEC-05/06), Modellausgaben (SEC-07) — entfallen: kein Konto, kein HTTP, keine KI in diesem Feature

## Regression (PROJ-1, PROJ-2)
- [x] Testlauf 16:33: AppShellTests 44/44 (PROJ-1), DiagnosticsTests 18/18 und NoticesTests 15/15 (PROJ-2), OnboardingTests 18/18 und PermissionsTests 24/24 (PROJ-3)
- [x] Lint `swift format lint --strict --recursive App Packages`: Exit 0
- [x] Bau ohne Signatur ins Scratchpad: BUILD SUCCEEDED, keine Compiler-Warnungen (der signierte Bau wurde von den Prüfern nicht ausgeführt, weil er den Schlüsselbund braucht)
- [x] Geteilter Code nicht berührt: `git diff f2154a4..HEAD --stat -- App Packages/InnoWhisperKit/Sources/AppShell Packages/InnoWhisperKit/Sources/Notices Packages/InnoWhisperKit/Sources/Diagnostics` leer; `updateProblems` meldet und zieht nur einmal (`PermissionMonitor.swift:163-179`), häufigeres Prüfen erzeugt keine doppelten Hinweise
- [x] PROJ-1 EC-5 (Herunterfahren): `beginActivity` schaltet auch Sudden Termination ab, der Weg über `willPowerOffNotification` (`App/AppDelegate.swift:32-36,51-53`) bleibt unverändert
  - [!] tatsächliches Herunterfahren — no way to run and probe this project was recorded
- [!] Kein Feature ist „Deployed“; Laufzeit von PROJ-1/PROJ-2 — no way to run and probe this project was recorded

## QA-Tests (Schritt 6)
- Keine neuen Tests in diesem Lauf. BUG-7 betrifft den Systemanschluss (`SystemPermissionChecker`), der nur am laufenden Programm prüfbar ist; die Tests nutzen einen Ersatz.

## E2E-Tests
- Status: **nicht gelaufen** (`/e2e-tests` für kritische Abläufe; für diese native App gibt es noch keinen E2E-Stack)

## Nicht geprüft in diesem Lauf
- [!] Bedienungshilfen im Hintergrund mit dem fertigen Bau entziehen und wieder erteilen (AC-10, AC-15, AC-16) — durch BUG-7 nicht erreicht; Test durch Timur nach der Korrektur
- [!] AC-11 echtes „Nicht erlauben“, AC-12 echte Tasten Esc/⌘W, AC-13 Beenden mittendrin, AC-21 Tastatur/VoiceOver, AC-22 Hell/Dunkel, EC-3 echter Neustart, EC-5 zweiter Bildschirm — no way to run and probe this project was recorded; Test durch Timur folgt
- [!] Mikrofon „eingeschränkt“ an einem echten, von der IT verwalteten Mac — kein solcher Mac verfügbar

## Gefundene Fehler

### BUG-1: Entzogene Erlaubnis wird im Hintergrund nicht bemerkt
- **Schweregrad:** High
- **Status:** Open (Mikrofon-Hälfte belegt behoben, Bedienungshilfen-Hälfte mit dem fertigen Bau noch nicht gemessen)
- **Fehlerart (Class):** Regelmäßige Arbeit einer Menüleisten-App im Hintergrund ohne Schutz gegen App Nap; Erlaubnis-Abfragen, die macOS je Prozess zwischenspeichert
- **Kriterium:** AC-15, AC-16
- **Sweep:** `grep -rn "beginActivity\|NSAppSleepDisabled\|NSProcessInfo.*activity" App Packages` — 1 Treffer (`PermissionMonitor.swift:76`, vorher 0); `grep -rn "authorizationStatus(for" App Packages/InnoWhisperKit/Sources` — 1 Treffer, nur noch für „eingeschränkt“ (`PermissionChecking.swift:31`)
- **Offen:** Bedienungshilfen im Hintergrund mit dem fertigen Bau aus- und einschalten (nur echte Schalter, `tccutil` erreicht eine laufende App nicht). Die Abnahme-Lane sah zwischen 16:23:49 und 16:24:52 keine Bedienungshilfen-Anfrage des Prozesses bei tccd; ob `AXIsProcessTrusted()` im Prozess zwischenspeichert, klärt nur dieser Test.

### BUG-2: Falscher Hinweis bei gesperrtem Mikrofon
- **Schweregrad:** Low
- **Status:** Deferred
- **Fehlerart:** Text und Knopf fassen Zustände mit unterschiedlicher Ursache zusammen
- **Kriterium:** AC-11 (Randfall „eingeschränkt“)
- **Sweep:** `grep -n "return \"In den Systemeinstellungen erlauben\"" Packages/InnoWhisperKit/Sources/Permissions/PermissionSteps.swift` — 1 Treffer
- **Stand:** Hinweistext behoben (`PermissionSteps.swift:50-51`, Test `hintsExplainWhatToDo`). Rest: Der Knopf heißt bei „eingeschränkt“ weiter „In den Systemeinstellungen erlauben“ (`PermissionSteps.swift:41-44`) und steht über dem Satz „Wende dich an die Person, die deinen Mac verwaltet“.

### BUG-3: Abweichungen vom Design-System
- **Schweregrad:** Low
- **Status:** Deferred
- **Fehlerart:** Gestaltungsvorgaben aus `docs/design-system.md` in neuen Ansichten nicht übernommen
- **Kriterium:** AC-22
- **Sweep:** `grep -rn "buttonStyle(" Packages/InnoWhisperKit/Sources/Onboarding Packages/InnoWhisperKit/Sources/Permissions` — 6 Treffer
- **Stand:** Symbole behoben (2/2 hierarchisch). Rest: `.bordered` (`PermissionStepView.swift:17,31`) neben Glas (`OnboardingView.swift:52,54`). `docs/design-system.md:11` erlaubt Glas für Knopfleisten, `:52` verlangt schlichte Nebenknöpfe; ob das so gemeint ist, entscheidet Timur.

### BUG-4: „Jetzt erlauben“ doppelt im Bereich „Zugang & Erlaubnisse“
- **Schweregrad:** Low
- **Status:** Deferred
- **Fehlerart:** Gleiche Handlung an zwei Stellen derselben Fläche
- **Kriterium:** AC-16, AC-17
- **Sweep:** `grep -rn "Jetzt erlauben" Packages/InnoWhisperKit/Sources` — 3 Treffer (`AccessPane.swift:21`, `PermissionMonitor.swift:173`, Kommentar `ProblemCenter.swift:20`)
- **Stand:** vom Diff nicht berührt. AC-16 und AC-17 verlangen den Knopf beide; eine Änderung braucht `/refine PROJ-3`.

### BUG-5: PROJ-1 AC-16 ohne Ausnahme-Vermerk
- **Schweregrad:** Low
- **Status:** Fixed (in diesem Lauf bestätigt)
- **Fehlerart:** Verhaltensänderung an einem freigegebenen Nachbar-Feature ohne Vermerk in dessen spec.md
- **Sweep:** `grep -n "PROJ-1[, ]*AC-\|AC-5 und AC-6" features/PROJ-3-erlaubnisse-einfuehrung/spec.md` — 2 Treffer (`:70`, `:79`), beide mit Gegenstück in PROJ-1 (`spec.md:40`, `:55`). Restumfang siehe BUG-9.

### BUG-6: SEC-08-Eintrag zur Debug-Ausnahme unvollständig
- **Schweregrad:** Low
- **Status:** Fixed (in diesem Lauf bestätigt)
- **Fehlerart:** Sicherheits-Ausnahme ohne vollständigen SEC-08-Eintrag
- **Sweep:** `grep -nE "\*\*Ausnahme|Debug trägt weiter .get-task-allow" docs/decisions.md features/*/design.md` — 3 Treffer, davon `docs/decisions.md:49` mit SEC-ID und allen Pflichtfeldern; `design.md:146` verweist nur auf ADR-007 (kosmetisch)

### BUG-7: Mikrofon in der Einführung erlaubt, App erkennt es nicht
- **Schweregrad:** High
- **Status:** Open
- **Fehlerart (Class):** Erlaubnis über eine Schnittstelle angefragt und über eine andere gelesen; die lesende Schnittstelle erfährt von der Antwort nichts
- **Kriterium:** AC-8 (auch AC-7: „Weiter“ bleibt gesperrt, die Einführung kommt nicht weiter)
- **Sweep:** `grep -rn "requestAccess(for: .audio)\|requestRecordPermission" Packages/InnoWhisperKit/Sources App` — 1 Treffer (`PermissionChecking.swift:40`, `AVCaptureDevice.requestAccess`), gelesen wird über `AVAudioApplication.shared.recordPermission` (`PermissionChecking.swift:26`)
- **Nachstellen (Test durch Timur, 05.11., fertiger Bau 16:23:48):**
  1. Mikrofon und Bedienungshilfen für `com.innosolv.InnoWhisper` zurückgesetzt, Einführungs-Fortschritt gelöscht, App gestartet (16:40:19, „microphone notDetermined“).
  2. Im Schritt „Mikrofon“ auf den Knopf, im macOS-Fenster „Erlauben“.
  3. Erwartet: binnen 2 s „Erlaubt“ mit grünem Häkchen. Tatsächlich: macOS speichert die Erlaubnis (tccd 16:41:55,413 „Create“), die App bleibt bei „noch nie gefragt“, auch nach 108 s; jeder weitere Klick schreibt nur „Microphone permission requested“.
- **Hinweis:** Eingeführt mit der Korrektur von BUG-1 (Wechsel der lesenden Schnittstelle). Vor dem Wechsel war AC-8 live erfüllt (Bericht vom Vormittag, 10:53:14).

### BUG-8: Prüfung von außen beliebig oft auslösbar
- **Schweregrad:** Low
- **Status:** Deferred
- **Fehlerart (Class):** Von außen auslösbare Arbeit ohne Bündelung oder Drosselung am Eingang (SEC-02)
- **Sweep:** `grep -rn "suspensionBehavior: .deliverImmediately" App Packages` — 1 Treffer (`PermissionMonitor.swift:194`); die zweite Stelle `SingleInstanceGuard.swift:15` sendet nur
- **Nachstellen (nicht ausgeführt, probe none):** InnoWhisper im Hintergrund, eine Schleife sendet `com.apple.accessibility.api`; jede Zustellung löst `refresh()` mit zwei Abfragen bei macOS aus. Folge höchstens Rechenlast, kein falscher Stand, kein Datenabfluss.

### BUG-9: Vermerk zur verzögerten Prüfung auf die alte App enger als das Verhalten
- **Schweregrad:** Low
- **Status:** Deferred
- **Fehlerart (Class):** Vermerk an einem freigegebenen Nachbar-Feature fasst den Geltungsbereich enger als der Code (Restbestand von BUG-5)
- **Kriterium:** EC-4, PROJ-1 AC-16/EC-2/AC-18
- **Sweep:** `grep -n "Beim ersten Start, solange" features/PROJ-1-app-rahmen-einstellungen/spec.md` — 1 Treffer; `grep -rn "startOnboardingIfNeeded" App` — 2 Treffer
- **Nachstellen (Code-Pfad):** Die Prüfung wartet bei jedem Start mit offener Einführung auf „Fertig“ (`App/AppDelegate.swift:39`, `App/AppEnvironment.swift:89-104`), also auch beim Fortsetzen (AC-13) und nach einem Update mit neuem Schritt (AC-18). Vermerk und EC-4 sagen „beim ersten Start“. Lösung: Vermerk per `/refine` erweitern oder Verzögerung im Code auf den ersten Start begrenzen.

### BUG-10: App Nap für den ganzen Prozess dauerhaft aus
- **Schweregrad:** Low
- **Status:** Deferred
- **Fehlerart (Class):** Energiespar-Ausnahme ohne Ende und für mehr als die nötige Arbeit
- **Sweep:** `grep -rn "endActivity" Packages/InnoWhisperKit/Sources App` — 0 Treffer
- **Nachstellen:** `beginActivity` in `PermissionMonitor.swift:84` gilt bis zum Beenden der App; Stromverbrauch auf Akku nicht gemessen.

## Zusammenfassung
- **Abnahmekriterien im Diff:** belegt AC-3, AC-4, AC-6, AC-9, AC-11 (Logik), AC-17, AC-20, AC-21 (Logik), AC-22 (Teil); fehlerhaft AC-8 (BUG-7), AC-15/AC-16 Bedienungshilfen-Hälfte offen (BUG-1); übrige übernommen
- **Fehler:** 10 (0 kritisch, 2 hoch, 0 mittel, 8 niedrig) — Open: BUG-1, BUG-7; Fixed: BUG-5, BUG-6; Deferred: BUG-2, BUG-3, BUG-4, BUG-8, BUG-9, BUG-10
- **Sicherheit:** 9 Prüfungen belegt, 2 NOT VERIFIED (Release-Bau; entfallene Prüfungen ohne Konto, HTTP und KI)
- **Produktionsreif:** NEIN
- **Empfehlung:** BUG-7 mit `/build PROJ-3` beheben (Anfrage und Abfrage über dieselbe Schnittstelle), danach den Test durch Timur wiederholen und dabei die Bedienungshilfen-Hälfte von BUG-1 messen
