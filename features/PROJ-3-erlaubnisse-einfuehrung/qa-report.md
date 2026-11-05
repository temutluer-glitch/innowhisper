# QA-Ergebnisse PROJ-3: Erlaubnisse & Einführung

**Geprüft:** 2026-11-05
**App-Adresse:** nicht hier lauffähig (`probe.kind: none`, native Menüleisten-App). Laufzeitkriterien sind `[!] NOT VERIFIED`, außer wo ein Test durch Timur oder eine eigene Messung am laufenden Programm aufgezeichnet ist.
**Prüfer:** QA Engineer (KI). Drei unabhängige `qa-engineer`-Prüfer (Abnahme, Sicherheit, Regression) ohne Kenntnis des Baus; zusammengeführt vom Owner, dazu eigene Messungen des Owners am laufenden Entwicklungsbau.
**Umfang:** vollständig (erster Lauf)
**Testlauf:** `swift test --package-path Packages/InnoWhisperKit` einmal vor der Aufteilung: 116 Tests in 18 Suites bestanden. Nach den QA-Tests (Schritt 6): 118 Tests.

> Legende: `[x]` in diesem Lauf belegt (mit Nachweis) · `[ ] BUG` als fehlerhaft belegt · `[!] NOT VERIFIED` nicht prüfbar (mit Grund). „Logik“ = durch Test oder Quelltext belegt, nicht am laufenden Programm beobachtet. „Timur, 05.11.“ = Sichtprüfung durch Timur auf seinem Mac (macOS 26.5.1) am 05.11.2026, mit Protokollzeilen in `design.md` → Bau-Notizen.

## Abnahmekriterien

### Ablauf der Einführung
- [x] **AC-1** Logik: Willkommen, Mikrofon (30), Bedienungshilfen (40), Fertig; mittig und vorne — `Onboarding/OnboardingFlow.swift:30-33`, `Permissions/PermissionSteps.swift:10,15`, `OnboardingWindowController.swift:38-41,48-53`; Test `firstStartShowsAllStepsInOrder`. Live: Fenster „InnoWhisper einrichten“, „Schritt 1 von 4“, Timur, 05.11. (Protokoll 09:24:12 „page 1 of 4, closable false“)
- [x] **AC-2** Logik: „Schritt X von Y“ — `OnboardingFlow.swift:94`, `OnboardingView.swift:11`; Tests `firstStartShowsAllStepsInOrder`, `weiterIsLockedUntilPermissionIsGranted`, `afterUpdateOnlyNewOpenStepsAndDoneAreShown`
- [x] **AC-3** Text wortgleich zur Spec, Knopf „Los geht's“ — `WelcomeAndDoneViews.swift:8-12`, `OnboardingView.swift:35`; Live durchgeklickt, Timur, 05.11. (Protokoll 10:53:08 „welcome completed“)
- [x] **AC-4** Logik: „Fertig“ speichert, schließt, kommt nicht wieder — `OnboardingFlow.swift:133-137`, `App/AppEnvironment.swift:91-96`; Test `fertigStoresFinishAndCallsBack`; Live: Timur, 05.11. (Protokoll 10:54:11 „Onboarding finished“, beim Neustart 11:08:49 keine Einführung)
- [x] **AC-5** Logik: „Zurück“ ab Seite 2, ändert keine Erlaubnis — `OnboardingView.swift:60-66`, `OnboardingFlow.swift:97,105-108`; Test `backKeepsGrantsAndIsMissingOnFirstPage`
- [x] **AC-6** Erklärsätze — `PermissionSteps.swift:25-31`; Test `explanationsSayWhyItIsNeeded`
- [x] **AC-7** Logik: „Weiter“ gesperrt bis erfüllt, kein Überspringen — `OnboardingFlow.swift:100-103,112`, `OnboardingView.swift:72`; Test `weiterIsLockedUntilPermissionIsGranted`

### Erlaubnisse in der Einführung
- [x] **AC-8** Logik — `PermissionMonitor.swift:112-117`, `PermissionStepView.swift:49-54`; Tests `undeterminedMicrophoneAsksMacOS`, `buttonTitlesFollowTheState`. Live: Klick 10:53:12, „Erlaubt“ im Protokoll 10:53:14 (2 s), Timur, 05.11.
- [x] **AC-9** Logik — `PermissionMonitor.swift:118-120`, `SystemSettingsLinks.swift:20-32`, Satz `PermissionSteps.swift:52`; Tests `accessibilityRegistersAndOpensSystemSettings`, `settingsOpenAtTheRightPage`, `refusedPageFallsBackToSystemSettings`. Live: nur das Einstellungsfenster öffnet sich, Seite „Bedienungshilfen“, InnoWhisper steht in der Liste (Bildschirmfoto), Timur, 05.11. (Protokoll 11:33:01)
- [x] **AC-10** Logik — `PermissionMonitor.swift:62-64,78-88`; Tests `grantIsRecognizedOnNextCheck`, `stepIsSatisfiedOnlyWhenGranted`. Live: Einschalten ohne Neustart erkannt (10:54:02 und 11:33:44), Timur, 05.11. Genaue Klickzeit nicht protokolliert, daher die 2-s-Grenze nur für das Mikrofon gemessen.
- [x] **AC-11** Logik: Knopf „In den Systemeinstellungen erlauben“, Hinweissatz, Seite Mikrofon — `PermissionSteps.swift:43,50-51`, `SystemSettingsLinks.swift:18-19`; Tests `deniedMicrophoneOpensSystemSettings`, `hintsExplainWhatToDo`
  - [!] echter Klick auf „Nicht erlauben“ — no way to run and probe this project was recorded; nicht live getestet

### Fenster, Beenden, Einstellungen
- [x] **AC-12** Logik: nur `.titled`, Esc und ⌘W wirkungslos — `OnboardingWindowController.swift:7-8,29,35`; Test `escapeAndCloseDoNotCloseTheWindow`. Live: keine Fensterknöpfe, Timur, 05.11.
  - [!] echte Tasten Esc und ⌘W — no way to run and probe this project was recorded
- [x] **AC-13** Logik: Fortschritt sofort gespeichert, Fortsetzen am ersten offenen Schritt — `OnboardingFlow.swift:34-38,113-114`; Test `quittingMidwayResumesAtFirstOpenStep`
  - [!] Beenden mitten in der Einführung am echten Programm, ⌘Q bei vorderem Einführungsfenster — no way to run and probe this project was recorded; nicht live getestet
- [x] **AC-14** Ein einziger Weg zum Öffnen der Einstellungen — `App/AppEnvironment.swift:78-85`; Sweep `grep -rn "settingsWindow\.\|\.open(section" App Packages/InnoWhisperKit/Sources` 1 Treffer. Live: zweites Öffnen holt die Einführung nach vorne (Protokoll 09:24:21 „Settings requested during onboarding“), nur eine Instanz lief

### Später entzogene Erlaubnis
- [ ] **BUG-1 AC-15** Logik vorhanden (`PermissionMonitor.swift:153-169`, Tests `missingPermissionsAreReportedAfterOnboardingWithOwnButton`, `revokedPermissionAfterFinishDoesNotReopen`), **am laufenden Programm aber nicht erfüllt**: Läuft InnoWhisper im Hintergrund, wird eine entzogene Erlaubnis nach 90 s noch nicht bemerkt (Grenze laut Spec: 5 s). Siehe BUG-1.
- [ ] **BUG-1 AC-16** Hinweis mit „Jetzt erlauben“ — Logik `PermissionMonitor.swift:158-167`, `MenuBarPanel.swift:78-79`; Live mit App im Vordergrund: Warndreieck und Knopf erschienen, verschwanden nach Erlauben, Timur, 05.11. Im Hintergrund kommt der Hinweis nicht (BUG-1).
- [x] **AC-17** Gruppe „Erlaubnisse“ mit Stand und „Jetzt erlauben“ — `Permissions/AccessPane.swift:13-31`, angemeldet `App/AppEnvironment.swift:61`
  - [!] Darstellung — no way to run and probe this project was recorded; siehe BUG-4

### Wachsende Einführung, Protokoll, Bedienbarkeit
- [x] **AC-18** Nach Update nur offene Schritte plus Fertig — `OnboardingFlow.swift:41-48`; Test `afterUpdateOnlyNewOpenStepsAndDoneAreShown`
- [x] **AC-19** Erfüllte neue Schritte still erledigt — `OnboardingFlow.swift:43-46,81-87`; Tests `newSatisfiedStepCompletesAutomatically`, `stepsHaveFixedIdsOrderAndAutoCompletion`
- [x] **AC-20** Protokollzeilen für Änderungen und Schritte — `PermissionMonitor.swift:96-100`, `OnboardingFlow.swift:83-85,116-119,126-128,134`; Live gesehen in `~/Library/Logs/InnoWhisper/InnoWhisper.log` (z. B. 10:53:14 „Permission changed: microphone notDetermined -> granted“, 10:53:21 „Onboarding step completed: microphone“)
- [x] **AC-21** Logik: Textbeschriftungen, Return auf Hauptknopf, VoiceOver-Hinweise und Ansage — `OnboardingView.swift:71-73`, `PermissionStepView.swift:37-40,56`, `WelcomeAndDoneViews.swift:48,52`
  - [!] Bedienung nur mit Tastatur, Fokus, tatsächliche VoiceOver-Ausgabe — no way to run and probe this project was recorded
- [x] **AC-22** Einheitliche Knopfgröße `.regular`, nur SF Symbols — `OnboardingView.swift:64,70`, `PermissionStepView.swift:18,32`
  - [ ] BUG-3 (Low): Abweichungen von `docs/design-system.md`
  - [!] Hell- und Dunkelmodus — no way to run and probe this project was recorded

## Grenzfälle
- [x] **EC-1** Bereits erteilte Erlaubnisse erscheinen beim ersten Start mit „Erlaubt“ — `OnboardingFlow.swift:31-39`; Test `alreadyGrantedStepsAreShownOnFirstStart`
- [x] **EC-2** Rückprüfung bei „Weiter“ und „Fertig“ — `OnboardingFlow.swift:122-131,142-147`; Tests `revokedEarlierPermissionJumpsBack`, `revokedPermissionIsCheckedAgainOnFertig`
- [x] **EC-3** Logik: Neustart-Angebot nach 10 s, Pfad als Argument — `PermissionMonitor.swift:127-151`, `AppRelauncher.swift:36-49`; Tests `restartIsOfferedTenSecondsAfterReturningWithoutGrant`, `relaunchPassesPathAsArgumentThenQuits`, `failedRelaunchDoesNotQuit`
  - [!] echter Neustart — no way to run and probe this project was recorded. Risiko: Dauert das Beenden länger als 1 s, findet `open` noch die alte Instanz; dann könnte am Ende keine laufen (`AppRelauncher.swift:38`, `AppDelegate.swift:14-22`). Nicht provozierbar ohne Laufzeit.
- [x] **EC-4** Prüfung auf die alte App erst nach „Fertig“ — `App/AppDelegate.swift:38-39`, `AppEnvironment.swift:89-101`; Live: „Onboarding finished“ 10:54:11.598, Meldung 10:54:11.634, Timur, 05.11. Siehe BUG-5 zur Spec von PROJ-1.
- [x] **EC-5** Mittig auf dem Bildschirm mit dem Mauszeiger, sonst dem ersten — `OnboardingWindowController.swift:62-66`; Tests `screenWithTheMouseIsChosen`, `mouseOutsideEveryScreenFallsBackToTheFirst` (neu, an 2 echten Bildschirmen dieses Macs)
  - [!] Fenster tatsächlich auf dem zweiten Bildschirm — no way to run and probe this project was recorded

## Sicherheitsprüfung

Angewendet nach `docs/kit/guides/security.md`: SEC-01, SEC-02, SEC-03, SEC-08. Native App ohne Server, ohne Konten, ohne Netzwerk in diesem Feature.

- [!] Authentifizierung umgehen — entfällt: kein Konto, keine Sitzung (`design.md:6`)
- [!] Autorisierung über Nutzergrenzen — entfällt: keine geteilten Daten. Lokal (SEC-03): Einstellungsdatei `~/Library/Preferences/com.innosolv.InnoWhisper.plist` mit `-rw-------` (`ls -l`); gespeichert nur Schritt-Kennungen und Ja/Nein
- [x] Eingaben (SEC-02): beschädigter Fortschritt setzt zurück — `OnboardingProgressStore.swift:17-20`, Tests `damagedProgressStartsFromTheBeginning`, `unknownStoredIdsAreIgnored`; Neustart übergibt den Pfad als `$0`, Gegenprobe mit präpariertem Pfad legte keine Datei an — `AppRelauncher.swift:37`; nur feste Adressen geöffnet — `SystemSettingsLinks.swift:14-21`; systemweite Mitteilung löst nur `refresh()` aus — `PermissionMonitor.swift:84-88`
- [!] Rate Limiting — not implemented (optional for MVP): kein Endpunkt
- [!] Brute Force, Konto-Erkennung (SEC-04) — entfällt: keine Zugangsdatenprüfung in PROJ-3 (Groq-Schlüssel erst PROJ-4)
- [!] Zugangsdaten in der URL (SEC-05), Kopfzeilen (SEC-06), Modellausgaben (SEC-07) — entfällt: kein HTTP, keine Formulare, keine KI
- [x] Keine Geheimnisse (SEC-01): `git log --all -p` nach `gsk_`, `sk-`, `api_key=`, `PRIVATE KEY`, `ghp_`, `AKIA`, `password=`: 0 Treffer; `strings` über Debug- und frischen Release-Bau: 0 Treffer; nie Schlüsseldateien committet
- [x] Protokoll ohne Inhalte: nur feste Texte und Aufzählungen, freier Text schon beim Übersetzen ausgeschlossen — `LogMessage.swift:17-78`, Test `compilerRejectsFreeText`; keine Audio- oder Zwischenablage-Aufrufe in Onboarding/ und Permissions/ (grep 0 Treffer)
- [x] Erlaubnisse nicht weiter als nötig: nur `audio-input` (`App/InnoWhisper.entitlements`), Release ohne `get-task-allow` (`codesign -d --entitlements -` am frischen Release-Bau), keine Ausnahmen der Hardened Runtime
- [ ] BUG-6 (Low): Ausnahme `get-task-allow` im Debug-Bau ohne vollständigen SEC-08-Eintrag

## Regression (PROJ-1, PROJ-2)
- [x] Testsuite: 116/116, darunter alle Suites von PROJ-1 und PROJ-2 — Testlauf vor der Aufteilung
- [x] Lint `swift format lint --strict --recursive App Packages`: Exit 0; Bau ohne Signatur: BUILD SUCCEEDED
- [x] PROJ-1 AC-5/AC-6 mit neuer Ausnahme, AC-7 bis AC-11, AC-13 bis AC-15, AC-19/AC-20 im Code unverändert bzw. über den einen Weg in `AppEnvironment.swift:78-85`; neuer Schalter `keepsOwnActionInPanel` nur bei Erlaubnis-Problemen gesetzt (`PermissionMonitor.swift:164`), Standard `false`
- [x] PROJ-2: Notices unverändert (0 geänderte Dateien), neue Protokollzeilen nur mit festen Werten
- [ ] BUG-5 (Low): PROJ-1 AC-16 ohne Ausnahme-Vermerk für EC-4
- [!] Wiederöffnen nach längerer Ruhe: Zweimal `open` auf die laufende, ruhende App (12:05:37) öffnete kein Einstellungsfenster, kurz nach dem Start (11:12:44) schon. Vermutlich dieselbe Ursache wie BUG-1; ob PROJ-1 AC-6 schon vor PROJ-3 so war, ist nicht geprüft.

## QA-Tests (Schritt 6)
- `Tests/OnboardingTests/OnboardingWindowTests.swift`: `screenWithTheMouseIsChosen`, `mouseOutsideEveryScreenFallsBackToTheFirst` (Bildschirmwahl hatte keinen Test). Rot-Probe gemacht: erwartete Werte vertauscht, 3 Fehlschläge, wiederhergestellt, grün.

## E2E-Tests
- Status: **nicht gelaufen** (`/e2e-tests` für kritische Abläufe; für diese native App gibt es noch keinen E2E-Stack)

## Nicht geprüft in diesem Lauf
- [!] AC-11 echtes „Nicht erlauben“, AC-12 echte Tasten Esc/⌘W, AC-13 Beenden mitten in der Einführung, AC-21 Tastatur/VoiceOver, AC-22 Hell/Dunkel, EC-3 echter Neustart, EC-5 zweiter Bildschirm — no way to run and probe this project was recorded; offen für einen Test durch Timur
- [!] Signierter Debug-Bau durch die Prüfer — nicht ausgeführt, weil er den Schlüsselbund braucht; der vorhandene Bau ist mit „Developer ID Application … (N5QKANW6QY)“ unterschrieben (`codesign -dvv`)
- [!] `[user]`-Aufgabe T3 (Schlüsselbund „Immer erlauben“) nicht abgehakt; kein Anmelde-Weg, daher kein Bug. Die Unterschrift funktioniert, Timur muss den Haken bestätigen

## Gefundene Fehler

### BUG-1: Entzogene Erlaubnis wird im Hintergrund nicht bemerkt
- **Schweregrad:** High
- **Status:** Open
- **Fehlerart (Class):** Regelmäßige Arbeit einer Menüleisten-App im Hintergrund ohne Schutz gegen das Drosseln durch macOS (App Nap); dazu Erlaubnis-Abfragen, die macOS je Prozess zwischenspeichern kann. Ursache ist eine Vermutung aus den Messungen, nicht belegt.
- **Kriterium:** AC-15, AC-16 (auch PROJ-1 AC-6, siehe Regression)
- **Sweep:** `grep -rn "beginActivity\|NSAppSleepDisabled\|NSProcessInfo.*activity" App Packages` — 0 Treffer
- **Nachstellen (gemessen 05.11., Entwicklungsbau):**
  1. Einführung abgeschlossen, Mikrofon und Bedienungshilfen erlaubt. InnoWhisper starten und nicht anklicken.
  2. Nach 75 s Mikrofon entziehen (`tccutil reset Microphone com.innosolv.InnoWhisper`, 12:02:44).
  3. Erwartet: binnen 5 s Protokollzeile „Permission changed“ und Warndreieck. Tatsächlich: nichts, auch nach Holen der App nach vorne per `open` nicht. Systemprotokoll: Nach dem Start fragt der Prozess bei macOS (tccd) nicht mehr nach.
  4. Zweite Probe nach normalem Start: Bedienungshilfen entzogen 12:06:02, nach 90 s keine Erkennung, Rechenzeit des Prozesses blieb bei 0:00.37 (`ps -o time=`).
  5. Gegenprobe: Mit App im Vordergrund (Einstellungsfenster, Klicks) wurde dieselbe Änderung sofort erkannt (10:54:02, 11:33:44).
- **Hinweis:** `tccutil reset` ist nicht derselbe Weg wie Ausschalten in den Systemeinstellungen. Die zweite Probe (Bedienungshilfen) betrifft aber eine Abfrage ohne Zwischenspeicher, deshalb gilt der Fehler als belegt.

### BUG-2: Falscher Hinweis bei gesperrtem Mikrofon
- **Schweregrad:** Low
- **Status:** Deferred (Vorschlag)
- **Fehlerart:** Hinweistext fasst Zustände mit unterschiedlicher Ursache zusammen
- **Kriterium:** AC-11 (Randfall „eingeschränkt“, z. B. durch die IT)
- **Sweep:** `grep -rn "case (.microphone, _)" Packages/InnoWhisperKit/Sources/Permissions` — 1 Treffer
- **Nachstellen:** Stand „restricted“ → Text „Du hast die Abfrage abgelehnt …“ (`PermissionSteps.swift:50-51`), obwohl niemand abgelehnt hat und die Systemeinstellungen nicht helfen.

### BUG-3: Abweichungen vom Design-System
- **Schweregrad:** Low
- **Status:** Deferred (Vorschlag)
- **Fehlerart:** Gestaltungsvorgaben aus `docs/design-system.md` in neuen Ansichten nicht übernommen
- **Kriterium:** AC-22
- **Sweep:** `grep -rn "Image(systemName" Packages/InnoWhisperKit/Sources/Onboarding Packages/InnoWhisperKit/Sources/Permissions` — 2 Treffer ohne `symbolRenderingMode` (0 Treffer); `grep -rn "buttonStyle(" …` — 6 Treffer, gemischt `.bordered` und Glas im selben Schritt
- **Nachstellen:** `WelcomeAndDoneViews.swift:45`, `PermissionStepView.swift:52` ohne hierarchische Darstellung; `PermissionStepView.swift:17,31` neben `OnboardingView.swift:52,54`.

### BUG-4: „Jetzt erlauben“ doppelt im Bereich „Zugang & Erlaubnisse“
- **Schweregrad:** Low
- **Status:** Deferred (Vorschlag)
- **Fehlerart:** Gleiche Handlung an zwei Stellen derselben Fläche
- **Kriterium:** AC-16, AC-17
- **Sweep:** `grep -rn "Jetzt erlauben" Packages/InnoWhisperKit/Sources` — 2 Treffer (Problem-Hinweis über `SettingsWindowView.swift:34-38`, Zeile `AccessPane.swift:22`)
- **Nachstellen:** Erlaubnis fehlt, Bereich öffnen: Hinweis oben mit Knopf und Zeile mit Knopf. Darstellung nicht gesehen.

### BUG-5: PROJ-1 AC-16 ohne Ausnahme-Vermerk
- **Schweregrad:** Low
- **Status:** Deferred (Vorschlag)
- **Fehlerart:** Verhaltensänderung an einem freigegebenen Nachbar-Feature ohne Vermerk in dessen spec.md
- **Kriterium:** EC-4, PROJ-1 AC-16/EC-2/AC-18
- **Sweep:** `grep -n "PROJ-1[, ]*AC-\|AC-5 und AC-6" features/PROJ-3-erlaubnisse-einfuehrung/spec.md` — 2 Treffer, einer ohne Vermerk in PROJ-1
- **Nachstellen:** PROJ-1 spec AC-16 sagt „wenn InnoWhisper startet, erscheint die Meldung“; beim ersten Start kommt sie jetzt erst nach „Fertig“.

### BUG-6: SEC-08-Eintrag zur Debug-Ausnahme unvollständig
- **Schweregrad:** Low
- **Status:** Deferred (Vorschlag)
- **Fehlerart:** Sicherheits-Ausnahme ohne vollständigen SEC-08-Eintrag (Kontroll-ID, Zustimmung, Ausgleich)
- **Kriterium:** SEC-08, ADR-007
- **Sweep:** `grep -nE "\*\*Ausnahme|Debug trägt weiter .get-task-allow" docs/decisions.md features/*/design.md` — 2 Treffer, 0 mit SEC-ID
- **Nachstellen:** Debug ist jetzt mit derselben Team-Unterschrift signiert wie später Release; Erlaubnisse gelten damit auch für Debug-Bauten mit `get-task-allow`. Der Eintrag nennt das nicht und hat keine SEC-ID.

## Zusammenfassung
- **Abnahmekriterien:** 20/22 in Logik belegt, davon 11 zusätzlich live; 2 fehlerhaft (AC-15, AC-16 durch BUG-1); 7 Teilpunkte nicht geprüft
- **Grenzfälle:** 5/5 in Logik belegt, EC-4 live
- **Fehler:** 6 (0 kritisch, 1 hoch, 0 mittel, 5 niedrig) — Open: 1, Deferred: 5 (Vorschlag)
- **Sicherheit:** 5 Prüfungen belegt, 6 NOT VERIFIED (entfallen in diesem Feature: Anmeldung, Autorisierung, Rate Limiting, Brute Force, URL/Kopfzeilen, Modellausgaben)
- **Produktionsreif:** NEIN
- **Empfehlung:** BUG-1 mit `/build PROJ-3` beheben, danach `/qa` in der Breite der Korrektur
