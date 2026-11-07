# QA-Ergebnisse PROJ-5: Aufnahme per Tastenkürzel

## Nachtrag 2026-11-07: Nachprüfung BUG-1, BUG-2, BUG-3, BUG-10

**Umfang:** `git diff --stat e31e217..HEAD`. e31e217 ist der Commit des Berichts, HEAD ist f36c9de. Geänderte Produktionsdateien:
- `App/AppEnvironment.swift`
- `Sources/Recording/Hotkey/HotkeyMonitor.swift`
- `Sources/Recording/Hotkey/ShortcutAvailability.swift`
- `Sources/Recording/Session/InterruptionWatcher.swift`
- `Sources/Recording/Session/RecordingController.swift`
- `Sources/Recording/UI/ShortcutStep.swift`

Sechs Dateien, darunter die gemeinsame Verdrahtung. Deshalb haben drei unabhängige `qa-engineer`-Prüfer in voller Breite geprüft.

**Prüfläufe:**
- Testlauf einmal vorher: 274 Tests in 37 Suites bestanden (`scratchpad/qa-proj5-suite-2.log`).
- Lint: Exit 0. Bau: BUILD SUCCEEDED, 0 Warnungen (Regressions-Prüfer).
- SEC-08: Nur 2 Testzeilen entfernt. Die Probe nutzt jetzt eigene Test-Einstellungen statt der echten; das verschärft die Prüfung.

**Ergebnisse zu den offenen Fehlern:**
- [x] **BUG-1 behoben.** Die Suche liefert 5 Treffer, jeder ist abgesichert.
  - Jede Ablehnung in `open()` und Esc ohne Aufnahme setzen den Wächter zurück (`RecordingController.swift:172, 177, 185, 191, 203, 345-348`).
  - Ein Moduswechsel gilt erst nach der Aufnahme (`HotkeyMonitor.swift:149-159`). Eine Pause beendet die Aufnahme zuerst (`:165-168`).
  - Tests `HotkeyControllerSyncTests` (3). Gegenproben mit echter verzögerter Zustellung: Esc wird danach nicht abgefangen, der nächste Druck startet.
  - Neuer Randfall daraus: BUG-13.
- [x] **BUG-2 behoben.** Der Kürzel-Schritt liest den gespeicherten Probe-Wert (`ShortcutStep.swift:20-31`).
  - Test `probeSurvivesARestartOnTheLastPage`.
  - Ohne gelungene Probe bleibt der Schritt offen: Der Wert ist anfangs false und wird nur bei Erfolg gesetzt; der Schritt erledigt sich nie automatisch.
- [ ] **BUG-3 nur teilweise behoben, bleibt Open.** ⌘ und ⇧⌘ mit normalen Tasten gelten jetzt als belegt (Test `standardProgramShortcutsAreTaken`).
  - Apples Standardkürzel mit ⌥⌘ und ⌃⌘ gelten weiter als frei, Gegenprobe 5 von 5: ⌥⌘H, ⌥⌘M, ⌥⌘W, ⌃⌘F, ⌃⌘Leertaste.
  - Ebenso Systemkürzel von macOS, die nicht geändert und deshalb nicht gespeichert sind: ⌘F5 (VoiceOver), ⌥⌘D (Dock), ⌃⌘Q (Bildschirm sperren). Die Liste `macOSDefaults` hat nur 11 Einträge, und ein neuer Test hält ⌘F5 als frei fest.
  - Leicht zu breit: ⌘F13 bis F19 und ⌘Return gelten als belegt.
  - Neue Suche: `grep -cE '^\s+"[0-9]+": SystemShortcut' Packages/InnoWhisperKit/Sources/Recording/Hotkey/ShortcutAvailability.swift` → 11 Einträge.
- [x] **BUG-10 behoben.** `screensDidSleepNotification` hat 0 Treffer. Beobachtet werden nur noch Ruhezustand, Benutzerwechsel und Bildschirmsperre.
  - Während einer Aufnahme bleibt der Mac wach. Die Gegenprobe deckt alle neun Endwege ab, „an“ und „aus“ sind jedes Mal ausgeglichen.
  - Test `recordingKeepsTheMacAwakeAndScreenSleepIsNoInterruption`.
  - Neuer Befund daraus: BUG-12.

**Berührte Abnahmekriterien in diesem Lauf:**
- [x] AC-3, AC-7, AC-8, AC-9, AC-19, AC-20, EC-3, EC-5, EC-6, EC-8: Logik belegt durch die genannten Tests und Gegenproben.
- [ ] AC-17: Randfall offen, BUG-13.
- [ ] AC-18: BUG-3 Rest.
- [x] **Regression:** PROJ-1 bis PROJ-4 unverändert.
  - Fortsetzen der Einführung, neuer Schritt nach einem Update, Rücksprung bei entzogener Erlaubnis: Tests grün.
  - Esc außerhalb einer Aufnahme wird nicht mehr abgefangen.
  - Die beiden früheren Regressionen aus dem ersten Lauf sind weg.
- [!] **Laufzeit:** Tastatur live, Bildschirm bleibt an, Darstellung. Grund: no way to run and probe this project was recorded.

**Neue Befunde dieser Nachprüfung.** Weil BUG-3 ohnehin noch eine Runde braucht, hat Timur am 07.11. entschieden, BUG-12 und BUG-13 gleich mit zu beheben (Open); BUG-14 bleibt Deferred:
- BUG-12 (Medium): Eine vergessene Aufnahme hält den Mac unbegrenzt wach.
- BUG-13 (Medium): Modus während einer Aufnahme hin und zurück stellen lässt den falschen Modus aktiv.
- BUG-14 (Low): Eine spätere fehlgeschlagene Probe wird nach einem Neustart vergessen.

**Ergebnis nach Nachtrag:** NICHT BEREIT, Status bleibt In Review. BUG-3 ist nicht vollständig behoben.

---

**Geprüft:** 2026-11-07, erste Prüfung
**App-Adresse:** hier nicht lauffähig (`probe.kind: none`, native Menüleisten-App). Laufzeitkriterien gelten nur dort als belegt, wo ein Test durch Timur aufgezeichnet ist: Zeilen aus `~/Library/Logs/InnoWhisper/InnoWhisper.log` vom 07.11. zwischen 14:10 und 14:39, dazu seine Rückmeldung.
**Prüfer:** QA Engineer (KI). Drei unabhängige `qa-engineer`-Prüfer ohne Kenntnis des Baus: Abnahme (Schritt 2), Sicherheit (Schritt 3), Regression (Schritt 4 und 5). Zusammengeführt vom Owner.
**Testlauf:** `swift test --package-path Packages/InnoWhisperKit` einmal vor dem Start der Prüfer: 268 Tests in 36 Suites bestanden, 0 Fehlschläge (`scratchpad/qa-proj5-suite.log`).
**Lint:** Exit 0, ohne Ausgabe. **Bau:** `commands.build` BUILD SUCCEEDED, keine Warnung (Regressions-Prüfer, `scratchpad/qa-proj5-build.log`).
**Geprüfter Stand:** Branch `feat/PROJ-5-aufnahme-tastenkuerzel`, Commit 813c048. Die Gegenproben der Prüfer liefen in Kopien des Pakets im Scratchpad; das Projekt wurde nicht verändert.

> Legende: `[x]` in diesem Lauf belegt (mit Nachweis) · `[ ] BUG` als fehlerhaft belegt · `[!] NOT VERIFIED` nicht prüfbar (mit Grund). „Timur, 07.11.“ = Live-Test auf seinem Mac (macOS 26.5.1, Shure MV6 und Systemmikrofon).

## Abnahmekriterien

### Aufnahme starten und beenden
- [x] **AC-1** Werkszustand rechte ⌘ allein, Modus Halten: `ShortcutStore.swift:17-18`, `Shortcut.swift:100-101`; Test `factorySettingIsRightCommandHeld`.
- [x] **AC-2** Halten öffnet nach 0,25 s, Loslassen beendet und gibt weiter: `KeyInterpreter.swift:170-181, 250-260`, `RecordingController.swift:316-319`; Tests `rightCommandHoldOpensAfterDelayAndFinishesOnRelease`, `recordingStartsWithSoundAndIsHandedOnInOrder`. Timur, 07.11.: 14:33:01 bis 14:33:28 sechs Aufnahmen hintereinander, jede geöffnet und beendet.
- [ ] **AC-3** BUG-1. Ein/aus grundsätzlich richtig (Tests `toggleTapStartsAndNextTapStops`), aber ein Antippen während die vorige Datei noch schließt geht verloren und verschiebt den nächsten.
- [x] **AC-4** Startton und „nimmt auf“ erst bei fließendem Ton: `RecordingController.swift:230-242`; Test `recordingStartsWithSoundAndIsHandedOnInOrder`. Timur, 07.11.: Ton nach 85 bis 187 ms ab Öffnen des Mikrofons (über 20 Aufnahmen). Einschränkung: Die 1-s-Grenze wird im Code ab dem Öffnen gemessen, nicht ab dem Tastendruck (BUG-4).
- [x] **AC-5** Endton und Rückkehr aus „nimmt auf“: `RecordingController.swift:280, 385-387`; Test `recordingStartsWithSoundAndIsHandedOnInOrder`.
- [!] **AC-6** Code ohne Höchstdauer, Datei fortlaufend geschrieben; Tests `tenMinutesInChunksStayComplete` (600 s ± 0,1 s), `unfinishedFileIsReadableUpToTheWrittenFrames`. Eine echte 10-Minuten-Aufnahme fehlt: von Timur übersprungen (07.11.).
- [x] **AC-7** Nummern synchron auf dem Main Actor aus einem nur wachsenden Zähler: `RecordingQueue.swift:115-127`; Tests `consumerReceivesInSpokenOrder`, `recordingStartsWithSoundAndIsHandedOnInOrder`. Timur, 07.11.: Nummern #1, #2, #3 in Sprech-Reihenfolge.

### Abbrechen und Verwerfen
- [x] **AC-8** Bis 30 s bricht ein Esc ab: `RecordingRules.swift:142-153`, `RecordingController.swift:343-346`; Tests `singleEscapeCancelsUpToThirtySeconds`, `escapeCancelsAtOnceOrAfterSecondPress`. Timur, 07.11.: 14:15:26 „Recording cancelled with Escape“, Meldung gesehen.
- [x] **AC-9** Regel und Texte: Tests `escapeAfterThirtySecondsAsksAgain`, `secondEscapeWithinThreeSecondsCancels` (2,9 s), `escapeAfterWindowAsksAgain` (3,1 s). Live nicht geprüft (Teil 2 übersprungen).
- [x] **AC-10** Kurzes Antippen still verworfen: `KeyInterpreter.swift:175-177`, `RecordingRules.swift:29-31`; Tests `tapShorterThanDelayDoesNothing`, `shortRecordingIsDroppedSilently`. Timur, 07.11.: 14:16:22 „too-short“, keine Meldung.
- [x] **AC-11** Stille mit Hinweis verworfen, Sprache gegen das eigene Hintergrundgeräusch gemessen (Abweichung vom Entwurf, in `design.md` dokumentiert): `RecordingRules.swift:88-95`; Tests `silentRecordingIsDroppedWithNotice`, `quietSpeechInAQuietRoomIsKept`, `silenceWithAClickIsDropped`. Timur, 07.11.: Stille mit Klopfen 2 bis 3 % Sprachanteil (verworfen), leise und normale Sprache 65 bis 69 % (behalten).

### Mikrofon
- [x] **AC-12** Auswahl Systemmikrofon oder Gerät mit Namen: `MicrophonePicker.swift:57-66`, `MicrophoneList.swift:39-53`. Timur, 07.11.: Shure MV6 gewählt, Protokoll „microphone chosen“ ab 14:39:11. Darstellung nur aus dem Quelltext.
- [x] **AC-13** Rückfall mit Meldung im Wortlaut: `MicrophoneCapture.swift:159-167`, `RecordingController.swift:210-213`; Tests `missingChosenMicrophoneFallsBackToSystem`, `missingChosenMicrophoneFallsBackWithNotice`. Live nicht geprüft.
- [x] **AC-14** Abbruch nach 1 s ohne Ton, Pakete aus Nullen zählen nicht: `RecordingController.swift:218-228`, `RecordingRules.swift:109-111`; Tests `noSoundCancelsAfterOneSecond`, `zeroOnlyChunkIsNoSignal`. Live nicht geprüft.
- [x] **AC-15** Ohne Erlaubnis keine Aufnahme, Hinweis mit „Jetzt erlauben“: `RecordingController.swift:174-181`, `AppEnvironment.swift:82`; Tests `missingPermissionShowsNoticeWithButton`, `buttonRunsItsActionAndClosesTheNotice`. Live nicht geprüft.

### Einstellungen
- [x] **AC-16** Erlaubte Eingaben und sofortige Wirkung: `Shortcut.swift:111-123`, `ShortcutField.swift:23-47`, `AppEnvironment.swift:153-162`; Tests `onlyAllowedShortcutsAreSaved`, `loneModifierPressedAndReleasedIsRecorded`, `modifierWithKeyBecomesACombination`.
- [ ] **AC-17** BUG-1: Ein Moduswechsel während einer laufenden Aufnahme wirkt sofort und lässt die Aufnahme verwaist weiterlaufen.
- [ ] **AC-18** BUG-3: Spotlight und geänderte Systemkürzel werden erkannt (Tests; Timur, 07.11.: ⌘ Leertaste „schon belegt“), aber Standardkürzel der Programme wie ⌘C oder ⌘Q gelten als frei.

### Einrichtung
- [x] **AC-19** Schritt `shortcut`, Reihenfolge 60, Text im Wortlaut, Pegel, Mikrofonwahl, „Weiter“ erst nach Probe: `ShortcutStep.swift:38-46, 63-64`; Tests `stepComesAfterThePermissionsAndNeedsAProbe`, `probeResultFromTheControllerUnlocksTheStep`, `tallestStateFitsTheOnboardingWindow`. Timur, 07.11.: 14:10:44 und 14:14:36 Probe gelungen, Schritt erledigt. Nach einem Neustart auf „Fertig“ siehe BUG-2.
- [x] **AC-20** Probe nie weitergegeben, Datei gelöscht, Meldung im Wortlaut: `RecordingController.swift:312-315`; Test `probeIsNeverHandedOn`. Timur, 07.11.: „Recording discarded: probe, file deleted true“.

### Protokoll
- [ ] **AC-21** BUG-5: Inhaltsfrei belegt (`LogMessage` nimmt nur feste Texte; 130 Protokollzeilen der Kategorie `recording` ergeben 26 Muster ohne Tastencode, Text oder Gerätenamen), aber Abbruch- und Verwerf-Zeilen nennen weder Dauer noch Mikrofon-Art.

## Grenzfälle

- [x] **EC-1** Zusatztaste nie abgefangen, andere Taste verwirft still: `KeyInterpreter.swift:121-140, 229-246`; Tests `commandCBeforeDelayNeverOpens`, `commandCAfterOpenDiscards`, `otherKeyDropsSilently`. Timur, 07.11.: rund 20 × ⌘C/⌘V ohne Startton; einmal öffnete das Mikrofon kurz und wurde verworfen (14:14:56). Mausklick mit gehaltener ⌘ siehe BUG-7.
- [x] **EC-2** Gerät getrennt beendet normal und gibt weiter: `MicrophoneCapture.swift:316-331`, `RecordingController.swift:358-361`; Test `interruptionsHandOnWhatWasSaid`. Live nicht geprüft.
- [x] **EC-3** Ruhezustand und Sperre beenden und geben weiter: `InterruptionWatcher.swift:17-23`, `AppEnvironment.swift:137`; Test `interruptionsHandOnWhatWasSaid`. Live nicht geprüft. Bildschirm-Ruhezustand ohne Sperre siehe BUG-10.
- [x] **EC-4** Speicher beim Start und alle 10 s geprüft: `RecordingController.swift:182-187, 245-258`; Tests `lowDiskSpaceEndsTheRecording`, `diskSpaceBoundary`.
- [x] **EC-5** Echter Tastenzustand alle 0,5 s, Flags jedes Ereignisses gelten: `HotkeyMonitor.swift:168-179, 202-219`; Tests `lostKeyUpIsRepairedByStateCheck`, `secondPressWorksEvenWhenTheKeyWasStillCountedAsHeld`. Einschränkung durch BUG-1.
- [x] **EC-6** Sperre während der Einführung: `AppEnvironment.swift:190, 200`, `ShortcutStep.swift:76-77`; Test `blockedGateRecordsNothing`.
- [!] **EC-7** Videocall: nicht nachstellbar. Code ohne exklusiven Zugriff und ohne Sprachverarbeitung (`MicrophoneCapture.swift:170-175`).
- [x] **EC-8** Ein Zustandsautomat, Start nur aus „bereit“, Generationszähler gegen späte Antworten: `RecordingController.swift:108-110, 165, 222, 250, 290, 297`; Tests `onlyOneRecordingAtATime`, `noSecondOpenWhileActive`. Keine zweite Aufnahme möglich; der Folgefehler beim schnellen Mehrfachdruck steht unter BUG-1.

## Sicherheit

Grundlage `docs/kit/guides/security.md`. Geprüft: SEC-01, SEC-02 (Einstellungen, Systemkürzel-Datei), SEC-03 (Schutz der lokalen Dateien), SEC-08. Entfallen mangels Oberfläche: SEC-04 (keine Zugangsprüfung), SEC-05/06 (kein HTTP, keine Formulare), SEC-07 (kein KI-Aufruf).

- [x] **Keine getippten Tasten im Protokoll:** `grep … | grep -ci keycode` = 0; Protokollmuster ohne Inhalte (siehe AC-21).
- [x] **Abgriff merkt sich keine Tastenfolgen, nur Tastatur, abgefangen nur Esc und die Haupttaste einer Kombination während einer Aufnahme:** `KeyInterpreter.swift:70-79, 190-213`, `HotkeyMonitor.swift:311-312`; 9 Stellen geprüft. Ausnahme BUG-1.
- [x] **Abgeschalteter Abgriff wird wieder eingeschaltet:** `HotkeyMonitor.swift:168-173`; Test `disabledTapIsReenabledAndLogged`; live 0-mal aufgetreten.
- [x] **Ablage:** Ordner unter `~/Library` (0700 darüber), zufällige Dateinamen, abgebrochene, stille, zu kurze und Probe-Aufnahmen gelöscht (Protokoll: „file deleted true“ 14-mal, „false“ 0-mal), Reste beim Start entfernt, nur die letzte Aufnahme bleibt, Löschen nur im eigenen Ordner (Tests `discardDeletesFileWithoutConsumingNumber`, `leftoversAreRemovedAndCounted`, `placeholderKeepsOnlyTheLatestFile`, `deleteRefusesFilesOutsideTheFolder`). Datensicherung siehe BUG-6.
- [x] **Hinweis-Knopf nur über den aktuellen Hinweis auslösbar, Handlung fest im Code:** `NoticeCenter.performAction`; keine URL-Schemata, kein XPC.
- [x] **Systemkürzel-Datei nur gelesen und geprüft, Carbon-Probe meldet sofort wieder ab:** `ShortcutAvailability.swift:49-50, 80-85, 97-114`.
- [x] **Gespeicherte Einstellungen geprüft, Rückfall auf den Werkszustand:** `ShortcutStore.swift:39-45`; Test `brokenStoredValueFallsBackToFactory`.
- [x] **Keine Geheimnisse in Repo und Bau:** `git log --all -p` 0 Treffer, `strings` auf das Programm 0 Treffer.
- [x] **Berechtigungen unverändert** (nur Mikrofon; Hardened Runtime; keine Sandbox nach ADR-007); **keine abgeschwächten Prüfungen** (SEC-08: keine bestehende Testdatei geändert).
- [ ] **Esc außerhalb einer Aufnahme abgefangen:** BUG-1.
- [!] Hängender Hauptthread verzögert jede Taste im System; Passwortfelder mit Secure Input; Carbon-Probe im Betrieb: no way to run and probe this project was recorded.

**Sicherheit gesamt:** 22 Prüfungen belegt, davon 2 mit Befund (BUG-1, BUG-6); 11 NOT VERIFIED (davon 7 mangels Oberfläche entfallen).

## Regression

- [x] Testlauf 268/268 inklusive aller Suites von PROJ-1 bis PROJ-4; Lint und Bau grün.
- [x] PROJ-2: Hinweise ohne Knopf unverändert (`Notice.swift:52, 60-62`, `NoticeView.swift:21-25`); Töne und Protokoll unverändert.
- [x] PROJ-1: Bereiche und Reihenfolge, nur Titel „Aufnahme“ neu (`SettingsSection.swift:39`); Zustand „nimmt auf“ und Rückfrage beim Beenden laufen über die bestehenden Wege.
- [x] PROJ-3: Reihenfolge und Zählung der Schritte, neuer Schritt nach einem Update (Tests `afterUpdateOnlyNewOpenStepsAndDoneAreShown`, `firstStartShowsAllStepsInOrder`).
- [ ] PROJ-3 AC-13/EC-2: BUG-2.
- [ ] PROJ-2 AC-4 und PROJ-1 AC-3 (Esc schließt Hinweis bzw. Menüleisten-Fenster): gestört im Zustand von BUG-1.
- [x] PROJ-4: Schlüssel-Schritt zuerst, Fenster 520 × 540, Passt-Tests grün.

## Gefundene Fehler

### BUG-1: Kürzel-Wächter und Aufnahme-Steuerung laufen auseinander
- **Schwere:** Medium
- **Status:** Fixed (Nachprüfung 07.11., f36c9de)
- **Klasse:** Eine Seite verwirft eine Aufnahme oder setzt sich zurück, ohne die andere mitzunehmen.
- **Suche:** `grep -n "interpreter.reset()\|interpreter.configure(" Packages/InnoWhisperKit/Sources/Recording/Hotkey/HotkeyMonitor.swift; grep -n "a recording is already running" Packages/InnoWhisperKit/Sources/Recording/Session/RecordingController.swift` → 5 Treffer (HotkeyMonitor.swift:133, 140, 146, 155; RecordingController.swift:166).
- **Fall A (AC-3, Pflichtpunkt 1, Esc):**
  1. Modus „Ein/aus“: antippen, sprechen, antippen.
  2. Während die Datei noch schließt, ein drittes Mal antippen. Die Steuerung ignoriert es, ohne den Wächter zurückzusetzen (`RecordingController.swift:165-168`).
  3. Folge: Der nächste Druck wird als „Stopp“ gelesen, startet also still keine Aufnahme. Bis dahin wird jedes Esc in jedem Programm abgefangen (`KeyInterpreter.swift:190-195`).
  - Gegenproben: `probeToggleTapDuringFinishingEatsNextTap` (Abnahme) und `Desync/main.swift` (Regression).
- **Fall B (AC-17, EC-5):** Moduswechsel oder Klick ins Kürzel-Feld während einer laufenden Aufnahme setzt nur den Wächter zurück. Die Aufnahme läuft verwaist weiter, Esc und Loslassen beenden sie nicht, erst ein neuer Druck. Gegenprobe `probeModeChangeDuringRecordingOrphansIt`.

### BUG-2: Neustart auf „Fertig“ verlangt die Kürzel-Probe noch einmal
- **Schwere:** Medium
- **Status:** Fixed (Nachprüfung 07.11., f36c9de)
- **Klasse:** Einführungsschritt, dessen „erfüllt“ flüchtigen Zustand im Speicher liest, wird von der dauerhaften Nachprüfung aus PROJ-3 EC-2 erfasst.
- **Suche:** `grep -rn "isSatisfied:" Packages/InnoWhisperKit/Sources` → 6 Treffer, davon betroffen 1 (`ShortcutStep.swift:41`).
- **Nachstellen:** Einführung bis „Fertig“ durchlaufen, auf „Fertig“ die App beenden, neu starten, „Fertig“ klicken. Die Einführung springt zurück auf „Tastenkürzel“ und nimmt den Schritt aus den erledigten. Gegenprobe `probe/main.swift`: nach `advance()` `finished = false`, Seite 4.

### BUG-3: Standardkürzel der Programme gelten als frei
- **Schwere:** Medium
- **Status:** Open
- **Klasse:** Belegt-Prüfung ohne Apples Standardkürzel der Programme.
- **Suche:** `grep -cE "kVK_ANSI_(C|V|X|Z|Q|W|A|S|H|M)\b|kVK_Tab" Packages/InnoWhisperKit/Sources/Recording/Hotkey/ShortcutAvailability.swift` → 0.
- **Folge:** Wer ⌘C als Kürzel wählt, bekommt keine Warnung. Im Modus Halten fängt InnoWhisper danach das C mit ⌘ systemweit ab: Kopieren geht in keinem Programm mehr, jeder Druck startet ein Diktat (AC-18). Gegenprobe `probeCommandCIsReportedFree`.

### BUG-4: 1-Sekunden-Grenze ab Öffnen des Mikrofons statt ab Tastendruck gemessen
- **Schwere:** Low
- **Status:** Deferred
- **Klasse:** Zeitgrenze ab falschem Bezugspunkt.
- **Suche:** `grep -n "openedAt = services.now()\|RecordingInfo.noSoundTimeout" Packages/InnoWhisperKit/Sources/Recording/Session/RecordingController.swift` → 2.
- **Folge:** Bei rechter ⌘ allein öffnet das Mikrofon erst nach 0,25 s; ein Startton kann so bis etwa 1,3 s nach dem Druck kommen (AC-4). Gemessen live: 85 bis 187 ms ab Öffnen, also weit darunter.

### BUG-5: Abbruch- und Verwerf-Zeilen im Protokoll ohne Dauer und Mikrofon-Art
- **Schwere:** Low
- **Status:** Deferred
- **Klasse:** Protokollzeilen der Abbruchwege unvollständig (AC-21).
- **Suche:** `grep -n "cancelRecording(reason:" Packages/InnoWhisperKit/Sources/Recording/Session/RecordingController.swift` → 4 Aufrufe und 1 Definition.

### BUG-6: Aufnahme-Ordner nicht von der Datensicherung ausgeschlossen
- **Schwere:** Low
- **Status:** Deferred
- **Klasse:** Zwischengespeicherte personenbezogene Dateien ohne Ausschluss aus Time Machine.
- **Suche:** `grep -rn "isExcludedFromBackup" Packages/InnoWhisperKit/Sources` → 0.

### BUG-7: ⌘-Klick oder Scrollen mit gehaltener rechter ⌘ startet eine Aufnahme
- **Schwere:** Low
- **Status:** Deferred
- **Klasse:** Der Abgriff hört nur auf Tasten; Mausaktionen während des Haltens zählen nicht als „andere Taste“ (EC-1).
- **Suche:** `grep -n "\[.flagsChanged, .keyDown, .keyUp\]" Packages/InnoWhisperKit/Sources/Recording/Hotkey/HotkeyMonitor.swift` → 1.
- **Folge:** Startton und danach meist „Nichts gehört“.

### BUG-8: Töne bei still verworfenen Aufnahmen
- **Schwere:** Low
- **Status:** Deferred
- **Klasse:** Endton vor der Entscheidung gespielt.
- **Suche:** `grep -n "services.playEnd()" Packages/InnoWhisperKit/Sources/Recording/Session/RecordingController.swift` → 1 (Zeile 280).
- **Folge:** Ein Antippen von etwa 0,35 bis 0,5 s kann Start- und Endton spielen, obwohl es still verworfen wird (AC-10).

### BUG-9: Effektive Mindestlänge länger als 0,5 s
- **Schwere:** Low
- **Status:** Deferred
- **Klasse:** Mindestdauer gilt für die aufgenommene Länge, das Mikrofon öffnet aber erst nach der Wartezeit.
- **Suche:** none.
- **Folge:** Ein sehr kurzes Diktat („Ja.“) mit 0,5 bis 0,9 s Druck kann still verworfen werden.

### BUG-10: Bildschirm-Ruhezustand ohne Sperre beendet eine Aufnahme
- **Schwere:** Medium
- **Status:** Fixed (Nachprüfung 07.11., f36c9de)
- **Klasse:** Unterbrechung durch ein Ereignis, das keine Sperre ist.
- **Suche:** `grep -n "screensDidSleepNotification" Packages/InnoWhisperKit/Sources/Recording/Session/InterruptionWatcher.swift` → 1 (Zeile 18); `grep -rn "IOPMAssertion\|beginActivity" Packages/InnoWhisperKit/Sources/Recording` → 0.
- **Folge:** Im Modus „Ein/aus“ kann ein langes Diktat ohne Tastatur- oder Mauseingabe abgeschnitten werden, sobald der Bildschirm nach der eingestellten Zeit ausgeht, besonders im Akkubetrieb. Das trifft Pflichtpunkt 2 (lange Aufnahmen). Spec EC-3 nennt nur Ruhezustand und Sperre.

### BUG-11: Meldungen und Protokoll auf seltenen Wegen
- **Schwere:** Low
- **Status:** Deferred
- **Klasse:** Randwege ohne passende Meldung.
- **Suche:** none.
- **Belege:**
  - Ein Laufzeitfehler der Aufnahme zeigt „Mikrofon getrennt …“, obwohl nichts getrennt wurde (`RecordingController.swift:360-361`).
  - Abstecken vor dem ersten Ton endet ohne Meldung (`:267-271`).
  - Für ⌘Esc im Kürzel-Feld erscheint „Drücke dazu mindestens ⌘, ⌥, ⌃ oder ⇧.“, obwohl ⌘ gedrückt war (`ShortcutField.swift:44`).
  - Ein unlesbarer gespeicherter Modus fällt ohne Protokollzeile zurück (`ShortcutStore.swift:18`).

### BUG-12: Eine vergessene Aufnahme hält den Mac unbegrenzt wach
- **Schwere:** Medium
- **Status:** Open
- **Klasse:** Systemweite Ausnahme gegen Ruhezustand ohne zeitliche Obergrenze.
- **Suche:** `grep -rn 'idleSystemSleepDisabled\|idleDisplaySleepDisabled' Packages/InnoWhisperKit/Sources App` → 1 (`InterruptionWatcher.swift:53`).
- **Folge:** Eine im Modus „Ein/aus“ vergessene Aufnahme läuft ohne Höchstdauer weiter und verhindert, dass Mac und Bildschirm schlafen gehen. Damit greift vermutlich auch die automatische Sperre über „Bildschirm aus“ nicht, und der Mac bleibt entsperrt, bis der Akku leer oder der Speicher unter 200 MB ist. Das Gerät bleibt also unbeaufsichtigt offen. Nicht am laufenden Programm geprüft.

### BUG-13: Modus während einer Aufnahme hin und zurück stellen lässt den falschen Modus aktiv
- **Schwere:** Medium
- **Status:** Open
- **Klasse:** Eine zurückgestellte Einstellung wird gegen den aktiven Stand verglichen statt gegen den gewünschten.
- **Suche:** `grep -rn "hotkeyMonitor\.shortcut\|hotkeyMonitor\.mode" App` → 1 (`AppEnvironment.swift:162`).
- **Nachstellen:** Modus „Ein/aus“, Aufnahme läuft. In den Einstellungen auf „Halten“ und zurück auf „Ein/aus“ stellen, dann die Aufnahme beenden. Danach zeigt die Einstellung „Ein/aus“, der Wächter arbeitet aber im Modus „Halten“. Ein Antippen startet still nichts (Pflichtpunkt 1), bis zur nächsten Änderung oder bis zum Neustart. Gegenproben beider Prüfer: rot.

### BUG-14: Fehlgeschlagene Probe nach einer gelungenen wird nach dem Neustart vergessen
- **Schwere:** Low
- **Status:** Deferred
- **Klasse:** Gespeicherter und flüchtiger Zustand werden auf verschiedenen Wegen fortgeschrieben.
- **Suche:** `grep -rn "succeededDefaultsKey" Packages/InnoWhisperKit/Sources` → 3 (geschrieben nur bei Erfolg).

## Nicht geprüft in diesem Lauf

- [!] AC-6: echte 10-Minuten-Aufnahme. Grund: Live-Test Teil 2 von Timur übersprungen; nötig vor dem Umzug des Teams (Pflichtpunkt 2).
- [!] AC-9, AC-13, AC-14, AC-15, EC-2, EC-3, EC-7 live. Grund: Teil 2 übersprungen; sonst no way to run and probe this project was recorded.
- [!] AC-3 (Modus „Ein/aus“) live. Grund wie oben.
- [!] Stille-Regel in sehr ruhigen oder sehr lauten Räumen: In sehr ruhigen Räumen kann Rascheln als Sprache zählen (Pflichtpunkt 6), in lauten Räumen gilt fest −35 dB und leise Sprache fällt weg. Grund: braucht echte Aufnahmen in verschiedenen Räumen.
- [!] Darstellung von Einstellungsbereich, Einführungsschritt, Pegel und Hinweis-Knopf. Grund: kein Bildschirmzugriff auf die Menüleisten-App.

## Weitere Hinweise

- **PROJ-4 BUG-4 (Deferred) hat eine neue Stelle:** VoiceOver liest beim gesperrten „Weiter“ im Kürzel-Schritt „Erst nach der Erlaubnis möglich“ vor. Die Suche aus PROJ-4 BUG-4 findet die Stelle bereits (`OnboardingView.swift:73`).
- **PROJ-4 BUG-9 (Deferred) hat eine neue Stelle, die seine Suche nicht findet:** `ShortcutStepTests.swift:64` nutzt die feste Rahmenhöhe 131. Bessere Suche: `grep -rnE "131" Packages/InnoWhisperKit/Tests` → 3.
- **Frage an die Spec:** Im Modus Halten verwirft ⌘Q mit der rechten ⌘ eine laufende Aufnahme still (EC-1). Danach beendet die App ohne die Rückfrage aus PROJ-1 AC-20.
- **`dictationStarted` wird doppelt ausgelöst** (über die Steuerung und über `observeActivity`), ohne sichtbare Folge.
- **„Nochmal Esc drücken …“ schließt nach 2 s**, das Fenster für das zweite Esc ist 3 s lang.

## Neue Tests (Schritt 6)

Keine. Die reine Logik (Entscheidungslogik, Regeln, Ablage, Belegt-Prüfung, Kürzel-Feld) ist durch bestehende Tests abgedeckt, die alle beim Bau eine Rot-Probe hatten. Die Lücken liegen im Zusammenspiel von Wächter und Steuerung (BUG-1) und an der Laufzeit. Einen Test dafür schreibt `/build` zusammen mit der Korrektur, rot zuerst.

## E2E-Tests

Nicht ausgeführt (für native Menüleisten-Apps gibt es hier keinen Browser-Ablauf).

## Ergebnis

**NICHT BEREIT.** Es gibt keinen Fehler der Stufe Critical oder High. Gefunden wurden vier Fehler der Stufe Medium als Open (BUG-1, BUG-2, BUG-3, BUG-10) und sieben Fehler der Stufe Low als Deferred (BUG-4 bis BUG-9, BUG-11). Timur hat am 07.11. entschieden: BUG-1, BUG-2, BUG-3 und BUG-10 werden jetzt behoben (Open), BUG-4 bis BUG-9 und BUG-11 kommen später gesammelt (Deferred). Status bleibt In Review.
