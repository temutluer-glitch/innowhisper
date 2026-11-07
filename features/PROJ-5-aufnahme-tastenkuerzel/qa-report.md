# QA-Ergebnisse PROJ-5: Aufnahme per Tastenkürzel

## Nachtrag 3 vom 2026-11-07: Nachprüfung BUG-15, BUG-16, BUG-17

**Umfang:** `git diff --stat a7f24cc..HEAD`. a7f24cc hat den Bericht zuletzt geschrieben, HEAD ist 46a8d31. Geänderte Produktionsdateien:
- `App/AppEnvironment.swift`
- `Sources/Recording/Hotkey/ShortcutAvailability.swift`
- `Sources/Recording/Recording.swift`
- `Sources/Recording/Session/RecordingController.swift`

Vier Dateien, darunter die gemeinsame Verdrahtung, deshalb drei unabhängige Prüfer (Abnahme, Sicherheit, Regression).

**Prüfläufe:**
- Testlauf einmal vorher: 281 Tests in 37 Suites bestanden (`scratchpad/qa3-suite.log`). Gegenprobe des Abnahme-Prüfers: 13 Tests der betroffenen Bereiche bestanden.
- Lint: Exit 0. Bau: BUILD SUCCEEDED beim Abschluss von `/build`; das Programm enthält den neuen Protokolltext (`strings | grep -c "no keyboard or mouse input"` = 1).
- SEC-08: Der Test-Diff fügt nur hinzu (`git diff a7f24cc..HEAD -- Packages/InnoWhisperKit/Tests | grep -cE '^-.*#expect'` → 0). ⌘F5 und ⌥⌘D bleiben durch die unveränderten Tests belegt.

**Ergebnisse:**
- [x] **BUG-15 behoben.** Suche → 10 (Soll 10). Alle gemeldeten Beispiele stehen im Code (`ShortcutAvailability.swift:93-134`). Test `fullAppleListRespectsSwitchedOffSystemShortcuts`. Rest: BUG-19.
- [x] **BUG-16 behoben.** Suche `awakeSpeechLevel` → 0.
  - Laute Richtung: gleichmäßiger Raum bei −42 dB ±4 über 30 Minuten zählt nicht mehr als Sprache, Freigabe nach 120 s (Modell `scratchpad/probe/awake.py`, Test `steadyNoiseDoesNotKeepTheMacAwake`).
  - Schwankender Lärm (Fernseher, Musik) kann weiter als Sprache zählen; dann greift Timurs Obergrenze: Freigabe 20:00 bis 20:30 Minuten nach der letzten Tastatur- oder Mauseingabe, Sprache holt das Wachhalten nicht zurück, eine neue Eingabe schon (`RecordingController.swift:260, 308`, Test `twentyMinutesWithoutInputLetTheMacSleep`).
  - Leise Richtung: leise Sprache bei −48 dB mit Pausen in einem stillen Raum bleibt wach (Test `quietSpeechKeepsTheMacAwake`).
  - Eingabepause gemessen: `CGEventType(rawValue: ~0)` ist nicht leer, Mausbewegungen zählen mit, keine Erlaubnisabfrage im Code (`grep -rnE "CGRequestListenEventAccess|IOHIDRequestAccess" App Packages` → 0). Verdrahtet in `App/AppEnvironment.swift:84`.
  - Rest: BUG-18.
- [x] **BUG-17 behoben.** Suche → 0. Ausgeschaltetes ⌥⌘8 und ⌥⌘D gelten als frei (Test `fullAppleListRespectsSwitchedOffSystemShortcuts`). Rest: BUG-20.
- [x] **AC-4, AC-5, AC-14, AC-18, AC-21, EC-3, EC-8** in der Logik belegt (Tests im Testlauf, `RecordingController.swift:231, 254-273, 303, 461-464`). Neue Protokollzeilen sind feste Texte ohne Inhalt (`RecordingController.swift:306, 309`).
- [x] **AC-6** in der Logik: kein Höchstwert für die Aufnahmedauer, Test `tenMinutesInChunksStayComplete`.
- [x] **Sicherheit:** 13 Prüfungen belegt, keine neue Lücke (keine Geheimnisse in Diff, Verlauf oder Programm; Sperren ⌃⌘Q und Abmelden ⌥⇧⌘Q bleiben unantastbar; die App erzeugt keine eigenen Eingaben). 7 nicht geprüft, davon 4 ohne passende Oberfläche (SEC-04 bis SEC-07).
- [x] **Regression:** PROJ-1 bis PROJ-4 im Diff unberührt, ihre Tests grün. Start/Stopp, Esc-Regeln, Speicherplatz, Unterbrechungen, rechte ⌘ allein und ⌘F13 bis F19 halten.
- [!] **Laufzeit:** Freigabe des Wachhaltens am echten Mac (nach 2 Minuten Ruhe, nach 20 Minuten ohne Eingabe), Bildschirm aus mit Sperre, echte laute und leise Räume, Eingabepause in der laufenden App, ob macOS 26 beim Lesen der Eingabepause etwas abfragt, Programme, die künstliche Mausbewegungen erzeugen. Grund: no way to run and probe this project was recorded.

**Neue Befunde dieser Nachprüfung** (blockieren nicht, deshalb Deferred): BUG-18 (Medium), BUG-19, BUG-20, BUG-21 (Low).

**Weitere Hinweise:**
- Spec-Abweichung: `spec.md` sagt „Keine Obergrenze für die Aufnahmedauer“. Timurs 20-Minuten-Regel begrenzt nicht die Aufnahme, sondern nur das Wachhalten; bei kurzer Bildschirm-aus-Zeit endet ein freihändiges Diktat aber praktisch nach etwa 20 Minuten ohne Eingabe. Gehört per `/refine PROJ-5` in die Spec.
- Zoom-Kürzel (⌥⌘8, ⌥⌘=, ⌥⌘−) gelten auf einem frischen Mac ohne gespeicherten Eintrag als belegt, obwohl sie ab Werk vermutlich aus sind. Schützt eher zu viel.
- `features/INDEX.md` → Deployments enthält noch die Musterzeile `v1.0.0 · 2026-01-31 · https://app.example.com`.

**Ergebnis nach Nachtrag 3:** Kein Fehler mehr Open. Bereit unter einer Bedingung: Timur nimmt die nicht geprüften Laufzeit-Punkte bewusst in Kauf (Teil 2 des Live-Tests wurde übersprungen, die 10-Minuten-Aufnahme steht vor dem Umzug des Teams aus).

---

## Nachtrag 2 vom 2026-11-07: Nachprüfung BUG-3 (Rest), BUG-12, BUG-13

**Umfang:** `git diff --stat 7399d5a..HEAD -- App Packages`. 7399d5a hat den Bericht zuletzt geschrieben, HEAD ist 620908f. Geänderte Produktionsdateien:
- `App/AppEnvironment.swift`
- `Sources/Recording/Hotkey/ShortcutAvailability.swift`
- `Sources/Recording/Hotkey/ShortcutFollower.swift` (neu)
- `Sources/Recording/Recording.swift`
- `Sources/Recording/Session/RecordingController.swift`

Fünf Dateien, darunter die gemeinsame Verdrahtung, deshalb drei unabhängige Prüfer.

**Prüfläufe:**
- Testlauf einmal vorher: 277 Tests in 37 Suites bestanden (`scratchpad/qa-proj5-suite-3.log`).
- Lint: Exit 0. Bau: BUILD SUCCEEDED, 0 Warnungen.
- SEC-08: Eine einzige Testerwartung wurde umgedreht: „⌘F5 frei“ wird zu „belegt“ (VoiceOver). Begründung in `design.md`. Das verschärft die Prüfung.

**Ergebnisse:**
- [x] **BUG-13 behoben.** Die Suche liefert 0 Treffer, auch die breitere Suche nach demselben Vergleich.
  - Tests `modeChangedThereAndBackKeepsTheLastChoice`, `modeChangeWaitsForTheNextRecording`.
  - Rot-Probe des Prüfers: Mit dem alten Vergleich bleibt der falsche Modus aktiv, das nächste Antippen startet nichts.
  - Dieselbe Klasse beim Kürzel (hin und zurück während einer Aufnahme) ist ebenfalls behoben.
  - Keine Schleife, keine Nebenwirkung beim App-Start.
- [x] **BUG-12 für den gemeldeten Ablauf behoben.** Es gibt nur noch eine Stelle, die das Wachhalten schaltet (`RecordingController.swift:282`).
  - Die Freigabe kommt nach 120 bis 150 s ohne Pegel ab −45 dB.
  - Alle Endwege sind ausgeglichen: Esc, Verwerfen, Fehler, Unterbrechung, 500 Pegelmeldungen ohne Flattern.
  - In Timurs Raum trennt die Schwelle sauber. Stille mit Klopfen erreicht höchstens −51 bis −57 dB, leise Sprache −28 bis −36 dB.
  - Test `keepAwakeEndsAfterTwoMinutesWithoutSpeech`.
  - Rest: BUG-16.
- [x] **BUG-3 für die gemeldeten Kürzel behoben.** ⌘ und ⇧⌘ sowie die Beispiele der Nachprüfung (⌥⌘H, ⌥⌘M, ⌥⌘W, ⌃⌘F, ⌃⌘Leertaste, ⌘F5, ⌥⌘D, ⌃⌘Q) gelten als belegt; ⌘F13 bis F19 sind frei.
  - Test `appleShortcutsWithOptionOrControlCommandAreTaken`.
  - Die Liste von Apples Kürzeln ist aber nicht vollständig, Rest: BUG-15.
- [x] **AC-3, AC-5, AC-17, EC-3, EC-4, EC-8** in der Logik belegt (Tests und Gegenproben).
- [x] **Regression:** Keine Rückfälle in PROJ-1 bis PROJ-4. BUG-1, BUG-2 und BUG-10 halten.
- [!] **Laufzeit:** Freigabe des Wachhaltens am echten Mac, Bildschirm aus mit anschließender Sperre, laute Räume, Tastatur live. Grund: no way to run and probe this project was recorded.

**Neue Befunde dieser Nachprüfung.** Timur hat am 07.11. „noch eine Runde“ gewählt: alle drei werden jetzt behoben (Open). Für BUG-16 hat er festgelegt: Eine Aufnahme hält den Mac höchstens 20 Minuten ohne Tastatur- oder Mauseingabe wach.
- BUG-15 (Low): restliche Apple- und macOS-Kürzel.
- BUG-16 (Medium): Wachhalten an fester Lautstärke statt an Sprache.
- BUG-17 (Low): Die feste Liste übersteuert ausgeschaltete Systemkürzel.

**Ergebnis nach Nachtrag 2:** BUG-15, BUG-16 und BUG-17 sind Open, Status bleibt In Review.

---

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
- **Status:** Fixed (Nachprüfung 07.11., 620908f; Reste siehe BUG-15, BUG-16)
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
- **Status:** Fixed (Nachprüfung 07.11., 620908f; Reste siehe BUG-15, BUG-16)
- **Klasse:** Systemweite Ausnahme gegen Ruhezustand ohne zeitliche Obergrenze.
- **Suche:** `grep -rn 'idleSystemSleepDisabled\|idleDisplaySleepDisabled' Packages/InnoWhisperKit/Sources App` → 1 (`InterruptionWatcher.swift:53`).
- **Folge:** Eine im Modus „Ein/aus“ vergessene Aufnahme läuft ohne Höchstdauer weiter und verhindert, dass Mac und Bildschirm schlafen gehen. Damit greift vermutlich auch die automatische Sperre über „Bildschirm aus“ nicht, und der Mac bleibt entsperrt, bis der Akku leer oder der Speicher unter 200 MB ist. Das Gerät bleibt also unbeaufsichtigt offen. Nicht am laufenden Programm geprüft.

### BUG-13: Modus während einer Aufnahme hin und zurück stellen lässt den falschen Modus aktiv
- **Schwere:** Medium
- **Status:** Fixed (Nachprüfung 07.11., 620908f; Reste siehe BUG-15, BUG-16)
- **Klasse:** Eine zurückgestellte Einstellung wird gegen den aktiven Stand verglichen statt gegen den gewünschten.
- **Suche:** `grep -rn "hotkeyMonitor\.shortcut\|hotkeyMonitor\.mode" App` → 1 (`AppEnvironment.swift:162`).
- **Nachstellen:** Modus „Ein/aus“, Aufnahme läuft. In den Einstellungen auf „Halten“ und zurück auf „Ein/aus“ stellen, dann die Aufnahme beenden. Danach zeigt die Einstellung „Ein/aus“, der Wächter arbeitet aber im Modus „Halten“. Ein Antippen startet still nichts (Pflichtpunkt 1), bis zur nächsten Änderung oder bis zum Neustart. Gegenproben beider Prüfer: rot.

### BUG-14: Fehlgeschlagene Probe nach einer gelungenen wird nach dem Neustart vergessen
- **Schwere:** Low
- **Status:** Deferred
- **Klasse:** Gespeicherter und flüchtiger Zustand werden auf verschiedenen Wegen fortgeschrieben.
- **Suche:** `grep -rn "succeededDefaultsKey" Packages/InnoWhisperKit/Sources` → 3 (geschrieben nur bei Erfolg).

### BUG-15: Restliche Apple- und macOS-Kürzel gelten als frei
- **Schwere:** Low
- **Status:** Fixed (Nachprüfung 3, 07.11., c555206; Rest siehe BUG-19)
- **Klasse:** Belegt-Prüfung ohne vollständige Liste von Apples Standardkürzeln (Rest von BUG-3).
- **Suche:** `grep -cE '"(7|8|9|10|11|12|13|29|31|57)": SystemShortcut' Packages/InnoWhisperKit/Sources/Recording/Hotkey/ShortcutAvailability.swift` → 0. Nach einer Korrektur sollten es 10 sein.
- **Belege:**
  - Auf einem frischen Mac gelten ⌃⇧⌘3 und ⌃⇧⌘4 (Bildschirmfoto in die Zwischenablage) als frei, ebenso ⌃F1 bis ⌃F8 (Tastaturnavigation).
  - Ebenso Programmkürzel wie ⌥⇧⌘V, ⌥⌘C, ⌥⌘F, ⌥⌘L, ⌥⌘P, ⌃⌘A, ⌃⌘T und ⌥⌘←/→.
  - Auf Timurs Mac sind die macOS-Kürzel gespeichert und werden deshalb erkannt.

### BUG-16: Wachhalten hängt an fester Lautstärke statt an Sprache
- **Schwere:** Medium
- **Status:** Fixed (Nachprüfung 3, 07.11., 46a8d31; Rest siehe BUG-18)
- **Klasse:** Die Ausnahme gegen den Ruhezustand verlängert sich durch einen festen Pegel (−45 dB) statt durch erkannte Sprache oder die Anwesenheit des Nutzers.
- **Suche:** `grep -rn "awakeSpeechLevel" Packages/InnoWhisperKit/Sources` → 2.
- **Folge laut:** In einem lauten Raum (Großraumbüro, Fernseher, Musik) hält eine vergessene Aufnahme im Modus „Ein/aus“ den Mac weiter wach und entsperrt. Sie nimmt dabei Gespräche Dritter auf, die ab PROJ-6 an Groq gehen. Gegenprobe: Pegel −42 dB über 30 Minuten, keine Freigabe.
- **Folge leise:** Sehr leise Sprache unter −45 dB gibt das Wachhalten nach 2 Minuten frei. Dann kann eine Bildschirmsperre ein laufendes Diktat beenden. Gegenprobe: −48 dB durchgehend, Freigabe nach etwa 2,5 Minuten. In Timurs Raum war leise Sprache aber −28 bis −36 dB.
- **Hinweis:** Eine gute Lösung ist eine Produktentscheidung. Mögliche Wege sind eine Obergrenze ohne Tastatur- und Mauseingabe oder Sprache gemessen am eigenen Hintergrund wie bei AC-11.

### BUG-17: Feste Kürzel-Liste übersteuert ausgeschaltete Systemkürzel
- **Schwere:** Low
- **Status:** Fixed (Nachprüfung 3, 07.11., c555206; Rest siehe BUG-20)
- **Klasse:** Die feste Liste wird vor dem gespeicherten Zustand der Systemkürzel geprüft.
- **Suche:** `grep -cE '\((kVK_ANSI_D, optionCommand|kVK_F5, \.command|kVK_F5, optionCommand|kVK_ANSI_8, optionCommand|kVK_ANSI_Equal, optionCommand|kVK_ANSI_Minus, optionCommand)\)' Packages/InnoWhisperKit/Sources/Recording/Hotkey/ShortcutAvailability.swift` → 6.
- **Folge:** Ein in macOS ausgeschaltetes Kürzel, etwa ⌥⌘8 für Zoom, wird trotzdem als „schon belegt“ abgelehnt.

### BUG-18: Wachhalten verlangt in lauten Räumen mehr als die Aufnahme selbst
- **Schwere:** Medium
- **Status:** Deferred (neuer Befund einer Nachprüfung, blockiert nicht)
- **Klasse:** Die Sprachregel fürs Wachhalten weicht von der Sprachregel der Aufnahme (AC-11) ab: AC-11 zählt alles über −35 dB als Sprache, das Wachhalten verlangt immer 10 dB über dem Grundrauschen, ohne diese Obergrenze.
- **Suche:** `grep -rn "awakeSpeechMarginDecibels\|voicedThresholdDecibels" Packages/InnoWhisperKit/Sources | grep -v "public static let"` → 5; nur `RecordingController.swift:292` nutzt die Regel ohne die −35-dB-Grenze.
- **Folge:** Freihändiges Diktat in einem gleichmäßig lauten Raum (Café, Lüfter, etwa −32 dB), Sprache nur 6 bis 8 dB lauter: Das Wachhalten endet nach 2 Minuten. Ist die Bildschirm-aus-Zeit kürzer als die Zeit seit der letzten Eingabe, sperrt der Mac und beendet das Diktat (EC-3). Das Gesagte bleibt erhalten. Ausweg: Maus kurz bewegen. Beleg: Modell des Codes (`scratchpad/probe/awake.py`), keine echte Aufnahme.

### BUG-19: Weitere Apple- und macOS-Kürzel gelten auf einem frischen Mac als frei
- **Schwere:** Low
- **Status:** Deferred (neuer Befund einer Nachprüfung)
- **Klasse:** Belegt-Prüfung ohne vollständige Liste der Standardkürzel (Rest von BUG-15).
- **Suche:** `python3 -I scratchpad/probe/fresh.py` (bildet die Prüfung für einen frischen Mac nach) → 8 Treffer: ⌃⇧↑/↓/←/→ (Kennungen 34, 35, 80, 82), ⇧F11 (37), ⇧F12 (63), ⌥F14/⌥F15 (55, 56). Dazu Finder: ⌃⇧⌘T und ⌥⇧⌘⌫, `grep -cE 'kVK_ANSI_T, \[?\.control, \.shift|kVK_Delete' Packages/InnoWhisperKit/Sources/Recording/Hotkey/ShortcutAvailability.swift` → 0.
- **Einschränkung:** Ob diese Kürzel auf einem frischen macOS 26 ab Werk eingeschaltet sind, ist nicht geprüft.

### BUG-20: macOS-Kürzel mit ⌘ oder ⇧⌘ bleiben belegt, auch wenn sie ausgeschaltet sind
- **Schwere:** Low
- **Status:** Deferred (neuer Befund einer Nachprüfung)
- **Klasse:** Die feste Regel für ⌘ und ⇧⌘ wird vor dem gespeicherten Zustand der Systemkürzel geprüft (Rest von BUG-17).
- **Suche:** `grep -nE '"[0-9]+": SystemShortcut\(keyCode: UInt16\(kVK_[A-Za-z0-9_]+\), modifiers: (\.command|\[\.command, \.shift\]|\[\.shift, \.command\])\)' Packages/InnoWhisperKit/Sources/Recording/Hotkey/ShortcutAvailability.swift | grep -vE 'kVK_Space|kVK_F[0-9]+\)'` → 3 (⇧⌘3, ⇧⌘4, ⇧⌘5); dazu auf diesem Mac Kennung 27 (⌘´) und 98 (⇧⌘ß).
- **Folge:** Wer in macOS das Bildschirmfoto-Kürzel ⇧⌘4 ausschaltet, kann es trotzdem nicht für InnoWhisper wählen. ⌘ Leertaste ist korrekt ausgenommen.

### BUG-21: Bau-Notiz zu BUG-15/17 beschreibt die falsche Kürzelgruppe
- **Schwere:** Low
- **Status:** Deferred (neuer Befund einer Nachprüfung)
- **Klasse:** Entscheidungs-Log beschreibt eine andere Änderung als den Code.
- **Suche:** none (Abgleich Notiz gegen Diff). Stelle: `design.md:186` nennt „⌘ und ⇧⌘“; geändert wurde die Liste mit ⌥⌘, ⌥⇧⌘ und ⌃⌘ sowie der Umzug von ⌥⌘D, ⌘F5, ⌥⌘F5 und Zoom in die macOS-Werkstabelle.

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
