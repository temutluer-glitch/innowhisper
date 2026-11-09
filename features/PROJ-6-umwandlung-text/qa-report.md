# QA-Ergebnisse PROJ-6: Umwandlung in Text

**Lauf:** erste Prüfung, 09.11.2026, Stand 36b9c3a auf `feat/PROJ-6-umwandlung-text`.
**Prüfweg:** `.ai-eng-kit` → `probe.kind: none`. Die App wurde nicht gestartet, Groq nicht aufgerufen, kein Schlüsselbund gelesen. Belegt sind Code, Tests und Gegenproben mit Attrappen. **Alles, was die laufende App braucht, ist NOT VERIFIED** (Grund: no way to run and probe this project was recorded) und braucht einen Live-Test mit Timur.
**Prüfer:** drei unabhängige `qa-engineer`-Läufe ohne Wissen über den Bau (Abnahme, Sicherheit, Regression). Zusammengeführt von dieser Sitzung.

**Prüfläufe:**
- Testlauf einmal vorher: 371 Tests in 45 Suites bestanden (`scratchpad/qa-proj6-suite.log`). Gegenprobe des Regressions-Prüfers mit frischem Bau auf einer Kopie: 73 + 54 Tests der Nachbarn und der zeitkritischen Suites bestanden.
- Lint `swift format lint --strict --recursive App Packages`: Exit 0. Bau `xcodebuild … build`: BUILD SUCCEEDED, 0 Warnungen.
- SEC-08: Test-Diff `813190f..HEAD` hat 0 gelöschte Zeilen, keine übersprungenen oder abgeschwächten Tests.
- `tasks.md`: keine `[user]`-Aufgaben.

## Nachtrag 3 vom 2026-11-09: Nachprüfung BUG-3, BUG-16, BUG-19 (dritte Runde, „Einfacher Weg“)

**Umfang:** `git diff --stat 3d8f1c3..HEAD` (HEAD d709113). Geändert: `Sources/Transcription/Text/TranscriptFilter.swift` und sein Test. Ein Prüfer mit allen drei Bereichen.

**Prüfläufe:** Testlauf einmal vorher: 377 Tests bestanden (`scratchpad/qa-proj6-suite-4.log`). Lint der Dateien: Exit 0. SEC-08: Zwei Erwartungen sind mit der Entscheidung „Einfacher Weg“ weggefallen („Gut, Untertitel im Auftrag des ZDF. Weiter.“ und der Ein-Abschnitt-Fall „Bis morgen dann Untertitel …“), begründet in `design.md`; die Zählung im Test wurde von `== 1` auf `>= 1` gelockert (Proben zeigen exakte Zählungen). Neuer Test mit Wanduhr-Grenze 5 s (`TranscriptFilterTests.swift:165`) gehört zur Klasse von BUG-15, deren Suche jetzt 3 Treffer hat.

**Ergebnisse:**
- [x] **BUG-3 behoben** für das Abschneiden innerhalb eines Satzes: alle gemeldeten Sätze und 27 neue bleiben unverändert; Abspann wird nur noch als ganzes Stück entfernt (`TranscriptFilter.swift:98-112, 127`). Rest über Abschnitts- und Satzgrenzen: BUG-20.
- [x] **BUG-16 behoben** für ganze Sätze und ganze Abschnitte: Anführungszeichen, Klammern, Strich, „…“, „;“, „!“, „?“, zwischen Zeilenumbrüchen, angehängter oder stiller Abschnitt, zwei hintereinander als eigene Abschnitte, allein → leer. Bewusst nicht entfernte Fälle: BUG-21.
- [x] **BUG-18 behoben:** ein Abspann wird ganz oder gar nicht entfernt, kein Rest mehr. Unbekannte Wortlaute („Untertitel von Stephanie Geiges“, „… im Auftrag der Amara.org-Community“) bleiben ganz stehen.
- [x] **BUG-19 behoben:** Suche → 0. 78 Läufe mit feindlichen Eingaben von 20.000 Zeichen, höchstens 0,054 s; lineares Wachstum bis 320.000 Zeichen; alter Stand 34,5 s.
- [x] **Gleichwertigkeit:** 60.000 Zufallseingaben ohne Abspann ergeben dieselbe Ausgabe wie vorher (0 Abweichungen).
- [x] **AC-15, AC-17 (Code), EC-1 (Filteranteil)** bestanden. **AC-16** bis auf BUG-21 bestanden.
- [x] **Sicherheit:** kein Text im Protokoll; die festen Muster sind unveränderlich, nur gelesen, unter ThreadSanitizer mit 16 parallelen Aufgaben ohne Warnung.
- [!] Laufzeit, echte Groq-Antworten (wie oft Groq mitten im Satz trennt), Release-Bau — no way to run and probe this project was recorded.

**Neue Befunde** (blockieren nicht, deshalb Deferred): BUG-20, BUG-21, BUG-22, BUG-23 (alle Low).

**Ergebnis nach Nachtrag 3:** Kein Fehler mehr Open. Es fehlt der Live-Test mit Timur (AC-5, AC-6, AC-17, AC-18 und alle sichtbaren Teile). Bis dahin: NICHT BEREIT — nicht geprüft. Status bleibt In Review.

---

## Nachtrag 2 vom 2026-11-09: Nachprüfung BUG-3 (zweite Runde) und BUG-16

**Umfang:** `git diff --stat ab9adb8..HEAD` (HEAD eb90efc). Geändert: `Sources/Transcription/Text/TranscriptFilter.swift` und sein Test. Eine Datei, deshalb ein Prüfer mit allen drei Bereichen.

**Prüfläufe:** Testlauf einmal vorher: 376 Tests bestanden (`scratchpad/qa-proj6-suite-3.log`). Ein früherer voller Lauf in dieser Runde war einmal rot durch den bekannten Zeit-Test (BUG-15), zwei Wiederholungen grün. Lint der Dateien: Exit 0. Test-Diff nur Ergänzungen (SEC-08). Hinweis zum Commit eb90efc: Von den 15 neuen Fällen schlugen 14 mit dem vorigen Filter fehl; „Die Untertitel vom ZDF, die sind schlecht.“ war schon vorher richtig.

**Ergebnisse:**
- [ ] **BUG-3 weiter offen.** Alle bisher gemeldeten Sätze und 16 neue bleiben stehen. Aber das Muster greift mitten im Satz, wenn der Satz mit dem Abspann-Wortlaut endet: „Schick mir bitte die Untertitel vom ZDF.“ → «Schick mir bitte die», „Ich danke der Amara.org-Community.“ → «Ich danke der», „Die Untertitel vom ZDF. Die sind schlecht.“ → «Die Die sind schlecht.». Mit „?“ statt „.“ bleibt der Satz stehen.
- [ ] **BUG-16 teilweise.** Die 8 gemeldeten Fälle sind behoben. Restfälle: Abspann eines stillen Mittelteils ohne Schlusspunkt vor einem weiteren Teil (EC-1-Weg), Satzzeichen hinter dem schließenden Anführungszeichen, Ende mit „…“ oder „;“, Abspann zwischen Zeilenumbrüchen, zwei Abspanne hintereinander.
- [x] AC-15 nach Entfernen des Abspanns (Ganz-Satz-Regel greift weiter), übriges Filterverhalten, keine Nutzer des entfernten `isSubtitleSentence`, kein Text im Protokoll, `try!` mit festem Muster stürzt nicht ab.
- [ ] **AC-16, EC-1 (Filteranteil)** nicht bestanden.

**Neue Befunde:** BUG-18 (Low, Deferred), BUG-19 (Medium, Rückschritt aus dieser Korrektur, Entscheidung offen).

**Ergebnis nach Nachtrag 2:** BUG-3 und BUG-16 Open, BUG-19 Open bis zur Entscheidung. Live-Test steht aus. Status bleibt In Review.

---

## Nachtrag vom 2026-11-09: Nachprüfung BUG-1 bis BUG-4

**Umfang:** `git diff --stat 82217f5..HEAD` (82217f5 hat den Bericht zuletzt geschrieben, HEAD ist ac30c7f). Geänderte Produktionsdateien:
- `Sources/Transcription/Delivery/ClipboardDelivery.swift`
- `Sources/Transcription/Delivery/TextDelivery.swift`
- `Sources/Transcription/Queue/TranscriptionQueue.swift`
- `Sources/Transcription/Text/TranscriptFilter.swift`

Vier Dateien, deshalb drei unabhängige Prüfer.

**Prüfläufe:**
- Testlauf einmal vorher: 375 Tests in 45 Suites bestanden (`scratchpad/qa-proj6-suite-2.log`).
- Lint: Exit 0. Bau: BUILD SUCCEEDED, 0 Warnungen.
- SEC-08: 4 Erwartungen ersetzt durch gleichwertige Prüfungen der Übergabe-Gruppen; das Zusammensetzen mit Leerzeile prüft jetzt `severalTextsGoTogetherInOrder`; Gegenprobe des Regressions-Prüfers verbindet echte Warteschlange und echte Zwischenablage: „Alt eins.\n\nAlt zwei.“ mit „Nachgeholtes …“. Keine Tests abgeschaltet.

**Ergebnisse:**
- [x] **BUG-1 behoben.** Suche → 1 (vorher 2). Tests `liveDoesNotOvertakeRecovered`, `textsLeaveInSpokenOrder`; Gegenproben mit zwei nachgeholten und einem Live-Diktat sowie mit einem endgültig gescheiterten nachgeholten Diktat bestanden.
- [x] **BUG-2 behoben.** Suche → 0 (vorher 1). Schlüssel wird nach dem Warten auf einen Platz gelesen (`TranscriptionQueue.swift:202-209`); Platz wird auf jedem Weg freigegeben; Gegenproben mit 4 und 7 Teilen ohne Hängenbleiben, höchstens 3 gleichzeitig. Test `removedKeyIsNotUsedAfterWaiting`.
- [x] **BUG-4 behoben.** Suche → 1 Schreibstelle, ein Aufruf pro Schritt, Texte mit Leerzeile verbunden, ein Hinweis. Test `severalTextsGoTogetherInOrder`.
- [ ] **BUG-3 nicht geschlossen.** Die drei gemeldeten Sätze bleiben jetzt stehen (Test `spokenSubtitleSentencesStay`). Aber das neue Muster ist nicht abgeschlossen: „Untertitel vom ZDF sind oft fehlerhaft.“, „Untertitel des ZDF fehlen bei dem Beitrag.“, „Untertitel im Auftrag des ZDF kosten uns zu viel.“, „Untertitelung des ZDF-Beitrags ist fertig.“, „Untertitel der Amara.org-Seite bitte prüfen.“, „Wir nutzen die Amara.org Community für Untertitel.“ werden weiter gelöscht. Neue Suche: `grep -nE 'prefixMatch\(of: /untertitel|contains\(/amara' Packages/InnoWhisperKit/Sources/Transcription/Text/TranscriptFilter.swift` → 2.
- [x] **AC-3, AC-8, AC-9, AC-10, AC-12, AC-14, AC-15, AC-20, AC-21 (geänderte Zeile), EC-2, EC-3, EC-5, EC-6, EC-7** in der Logik bestanden. **AC-16** nicht bestanden (BUG-3, BUG-16).
- [x] **Sicherheit:** 16 Prüfungen belegt, 0 neue Funde; Schlüssel nur direkt vor dem Senden gelesen, nie im Protokoll; Zwischenablage nur mit den Texten dieses Schritts; Filter-Muster ohne Rückschritt-Gefahr (20.000 Zeichen in unter 8 ms); BUG-9, BUG-10, BUG-11 unberührt. 6 NOT VERIFIED (Laufzeit und nicht anwendbare Prüfungen).
- [x] **Regression:** App-Verdrahtung unverändert und baut; kein anderer Nutzer der geänderten Übergabe-Schnittstelle.
- [!] **Laufzeit:** wie im Hauptbericht, no way to run and probe this project was recorded.

**Neue Befunde dieser Nachprüfung** (blockieren nicht, deshalb Deferred): BUG-16, BUG-17 (beide Low).

**Hinweise für Spec und PROJ-7:**
- Geht ein nachgeholter Text zusammen mit einem Live-Text raus, zeigt der Hinweis nur „Nachgeholtes Diktat in der Zwischenablage.“; mehrere Live-Texte eines Schritts werden ebenfalls mit Leerzeile zusammengesetzt. Beides steht in `design.md`, die Spec sagt dazu nichts.
- PROJ-7 muss eine gemischte Übergabe nach Art aufteilen und die Reihenfolge halten.

**Ergebnis nach diesem Nachtrag:** BUG-1, BUG-2, BUG-4 behoben. BUG-3 (Medium) bleibt Open. Der Live-Test mit Timur steht weiter aus. Status bleibt In Review.

---

## Abnahmekriterien

- [x] **AC-1** Umwandeln und „wandelt um“ — `TranscriptionQueue.swift:85-94, 198-205, 308`, `DictationActivity.swift:28-31`; Tests `recordingIsConvertedAndHandedOn`, `activityCombinesRecordingAndTranscribing`. Symbol live: [!] NOT VERIFIED.
- [x] **AC-2** Ab Werk „Schnell“ und „Deutsch“, Auswahl vollständig — `Transcription.swift:54, 64-70, 86, 97-104, 125-133`, Gruppe in `TranscriptionSettingsGroup.swift:14-26`, eingehängt `AppEnvironment.swift:142-150`; Tests `freshInstallUsesFastAndGerman`, `choicesAndLabels`. Darstellung: [!] NOT VERIFIED.
- [x] **AC-3** Zwischenablage mit Hinweis — `ClipboardDelivery.swift:23-30`; Test `liveTextGoesToClipboardWithNotice`. Aber BUG-4. Live: [!] NOT VERIFIED.
- [x] **AC-4** Wahl gilt ab der nächsten Aufnahme — `TranscriptionQueue.swift:117-121`, `TranscriptionJob.swift:54-56`; Test `settingsFixedAtArrival`.
- [!] **AC-5** unter 3 s für Diktate bis 30 s — Code: ein Teil, FLAC, kein Warten vor dem Hochladen. Messung: NOT VERIFIED (echtes Netz nötig).
- [!] **AC-6** 10 Minuten unter 1 Minute — Code: Teile von etwa 5 Minuten, höchstens 3 gleichzeitig (`TranscriptionQueue.swift:323-339`); Tests `atMostThreeRequestsAtOnce`, `tenMinutesBecomeTwoPieces`. Messung: NOT VERIFIED.
- [x] **AC-7** Teile ohne Lücke und Überlappung, in Reihenfolge — `AudioSplitter.swift:199-213`, `TranscriptFilter.swift:57-66`; Tests `cutsLandInsideTheQuietestStretch`, `piecesCoverTheRecordingWithoutGapOrOverlap`, `joinsPiecesInOrder`. Wortübergänge mit echter Sprache: [!] NOT VERIFIED.
- [ ] **AC-8** Reihenfolge — reine Live-Diktate bestanden (Test `textsLeaveInSpokenOrder`). **BUG-1**: Mischfall nachgeholt und live. **BUG-4**: mehrere Texte im selben Schritt überschreiben sich in der Zwischenablage.
- [x] **AC-9** Gescheitertes hält nicht auf — `TranscriptionQueue.swift:274-275`; Test `failedDictationDoesNotBlockAndComesLater`.
- [x] **AC-10** Zwei stille Versuche — `Transcription.swift:23`, `TranscriptionQueue.swift:222-228`; Test `twoSilentRetries`.
- [x] **AC-11** Hinweis, Problem, Aufnahme bleibt — `TranscriptionTexts.swift:10-14`, `TranscriptionQueue.swift:236, 250-253, 309-318`; Tests `failedDictationDoesNotBlockAndComesLater`, `noInternetNotice`. Symbol „Problem“ live: [!] NOT VERIFIED.
- [x] **AC-12** Kein Schlüssel — `TranscriptionQueue.swift:202, 239-242`, `AppEnvironment.swift:92, 160`; Test `missingKey`. Öffnen der Einstellungen live: [!] NOT VERIFIED. Siehe BUG-2 (EC-5).
- [x] **AC-13** Schlüssel abgelehnt — `TranscriptionQueue.swift:210-211, 243-247`, `AppEnvironment.swift:91`, `GroqKeyModel.swift:226-229`; Test `rejectedKey`. Echte Neuprüfung: [!] NOT VERIFIED.
- [x] **AC-14** Groq-Grenze — `TranscriptionQueue.swift:214-221`, `TranscriptionTexts.swift:33-38`; Tests `groqLimit`, `limitTextRoundsUp`. Randfall ohne Wartezeit: BUG-7.
- [x] **AC-15** Nur erfundener Satz → nichts — `TranscriptFilter.swift:73-76`, `TranscriptionQueue.swift:182-186`; Tests `wholeInventedPhraseBecomesEmpty` (12 Fälle), `nothingRecognized`.
- [ ] **AC-16** Untertitel-Sätze überall weg, echtes „Vielen Dank.“ bleibt — beides bestanden (Tests `removesSubtitleSentencesAnywhere`, `longerTextEndingWithThanksStays`). **BUG-3**: echte Sätze mit „Untertitel“ und „Funk“, „ZDF“ oder „Amara“ werden gelöscht.
- [!] **AC-17** kein erfundenes „Ich“, kein angehängter Satz bei 20 echten Diktaten — Code: kein Hinweistext an Groq, Temperatur 0, Abschnittsfilter (`GroqTranscriber.swift:66-69`, `TranscriptFilter.swift:45-52`). NOT VERIFIED (Live-Test).
- [!] **AC-18** mindestens 18 von 20 ohne sinnentstellenden Fehler — NOT VERIFIED (Lesung durch Timur).
- [x] **AC-19** Letzte 50 bleiben — `RecordingList.swift:151-160, 228-246`; Tests `fiftyFirstConvertedPrunesOldest`, `openEntriesAreNeverPruned`.
- [ ] **AC-20** Nachholen beim Start — nachgeholte allein bestanden (`AppEnvironment.swift:77, 172-173`, `TranscriptionQueue.swift:279-292`; Tests `recoveredAreCombined`, `openRecordingsAreRecoveredOnce`). **BUG-1** im Zusammenspiel mit einem Live-Diktat.
- [ ] **AC-21** Protokoll ohne Inhalte — keine Inhalte möglich (Typ-Sperre `LogMessage.swift:17-80`; 6.341 Zeilen Testprotokoll ohne Text, Schlüssel oder Dateinamen). **BUG-6**: Zeilen zu Start, Fehler und Wiederholung ohne die verlangten Felder.

## Grenzfälle

- [x] **EC-1** Stiller Mittelteil — mit Groqs Werten bestanden (Tests `silentMiddlePieceAddsNothing`, `silentMiddlePieceIsKept`). **BUG-5** ohne diese Werte. Echte Groq-Werte: [!] NOT VERIFIED.
- [x] **EC-2** Doppeltes „Erneut versuchen“ — Garantie im Code: alles auf dem Haupt-Thread (`TranscriptionQueue.swift:67`), nur `failed` wird angefasst und im selben Schritt `converting` (`:108, :129`), `handedOn` vor der Übergabe (`:299-301`); Test `doubleRetryActsOnce`.
- [x] **EC-3** Nur fehlende Teile neu — `TranscriptionQueue.swift:154, 162, 167-170`; Test `retrySendsOnlyMissingPieces`.
- [x] **EC-4** Kaputte Datei — `TranscriptionQueue.swift:139-144`, `AudioSplitter.swift:165-185`; Tests `damagedRecording`, `damagedFileIsUnreadable`.
- [ ] **EC-5** Schlüssel entfernt während der Umwandlung — **BUG-2**.
- [x] **EC-6** Nichts doppelt nach Neustart — Garantie im Code: `markConverted` speichert sofort im selben Schritt wie die Übergabe (`RecordingList.swift:151-160, 216-223`, `TranscriptionQueue.swift:281-292`); nur offene werden nachgeholt (`TranscriptionRecovery.swift:17-20`); Tests `openRecordingsAreRecoveredOnce`, `nothingOpenDoesNothing`.
- [x] **EC-7** Weiterdiktieren bei wartenden Fehlern — `TranscriptionQueue.swift:274-275`; Test `failedDictationDoesNotBlockAndComesLater`.

## Sicherheit

**19 Prüfungen belegt (16 bestanden, 3 Funde Low), 9 NOT VERIFIED (4 ohne passende Oberfläche).**

- [x] SEC-01 Schlüssel nur aus dem Schlüsselbund, nur in der Kopfzeile `Authorization`, nie in Adresse, Inhalt oder Dateiname — `AppEnvironment.swift:81-90`, `GroqTranscriber.swift:60-62`; Test `keyOnlyInAuthorizationHeaderAndFileNameNeverSent`.
- [x] SEC-01 Schlüssel und Inhalte nie im Protokoll — Typ-Sperre `LogMessage.swift:17-80`; `grep` nach anderen Ausgabewegen in Transcription: 0.
- [x] SEC-01 keine Geheimnisse im Branch-Verlauf (`git log -p main..HEAD`, Muster für echte Schlüssel: 0) und im Debug-Programm (`strings`: 0).
- [x] Was an Groq geht: Modell, Sprache, Temperatur, Format, Ton unter neutralem Namen `piece.flac`; kein Hinweistext, kein Dateiname — `GroqTranscriber.swift:56-97`; Tests `noHintTextIsSent`, `requestCarriesModelLanguageTemperatureAndFormat`.
- [x] Übertragung nur über feste `https`-Adresse, keine Ausnahmen für unsichere Verbindungen.
- [x] SEC-07 Groq-Antwort als fremde Eingabe: Größe, Typen, 20.000 Zeichen, NaN, Unendlich, kaputtes JSON — `GroqTranscriber.swift:166-208`; Test `brokenJSONIsUnusable`. Funde: BUG-9, BUG-10.
- [x] SEC-07 Grenzen für Wiederholungen und Kosten: 2 stille Versuche, höchstens 120 s Warten, 3 Anfragen gleichzeitig, Zeitlimit je Teil.
- [x] SEC-02 Pfade aus der gespeicherten Liste: kein `/`, `\`, `..`, NUL, führender Punkt; Löschen nur im eigenen Ordner — `RecordingList.swift:47-50`, `RecordingStorage.swift:39-54`; Test `invalidEntriesAreRejected`. Fund: BUG-11 (Dauerwert).
- [x] SEC-03 lokale Dateien nur über Ordner mit Rechten `drwx------` erreichbar; Teil-Dateien in eigenem UUID-Ordner im privaten Temp-Ordner.
- [x] Fehlermeldungen sind feste Texte ohne Pfade, Codes oder Schlüssel — `TranscriptionTexts.swift:4-43`.
- [x] Zwischenablage nur als reiner Text — `ClipboardDelivery.swift:41-45`.
- [x] Keine neuen Berechtigungen, keine fremden Pakete — `git diff` über Berechtigungen, `Info.plist`, Projektdatei, `Package.swift`.
- [x] Kein Diktat-Text wird gespeichert — Kodierschlüssel `RecordingList.swift:8-30, 57-59`.
- [!] Anmeldung, Zugriff über Nutzergrenzen, Brute Force, Formulare, HTTP-Kopfzeilen, Injection in HTML/SQL/Shell — nicht anwendbar (keine Konten, kein Server, keine Formulare, keine Datenbank).
- [!] Echte Anfrage an Groq, Protokoll der laufenden App, Zwischenablage und Aufräumen zur Laufzeit — no way to run and probe this project was recorded.
- [!] Ob `URLSession` Antworten mit Diktat-Text im Festplatten-Cache ablegt — `Cache.db` derzeit leer, aber kein echter Lauf; no way to run and probe this project was recorded.
- [!] Release-Programm mit PROJ-6 — noch keins gebaut (PROJ-14).

## Regression

- [x] PROJ-1 AC-2 Symbol-Vorrang — `MenuBarStatus.swift:10-16` unverändert, `activity` jetzt berechnet; Tests `statusPriority`, `activityCombinesRecordingAndTranscribing`.
- [x] PROJ-1 AC-20 Rückfrage beim Beenden — `QuitPolicy.swift:15`; Test `quitDecision` (`.transcribing` → nachfragen). Text veraltet: BUG-12.
- [x] PROJ-2 AC-4 Hinweise schließen sich nicht fälschlich — `DictationActivity.swift:29`, `AppEnvironment.swift:233-240`.
- [x] PROJ-3 unberührt; Probe-Aufnahmen erreichen die Liste nie (`RecordingController.swift:391-392`).
- [x] PROJ-4 Schlüssel-Zustand nur über `setStatus`; Neuprüfung über den bestehenden Weg — `GroqKeyModel.swift:208-240, 290`; `GroqKeyModelTests` grün.
- [x] PROJ-5 Aufräumen mit Ausnahmeliste, alte Signatur unverändert — `RecordingStorage.swift:84-108`; Tests `leftoversAreRemovedAndCounted`, `leftoversKeepNamedFiles`.
- [x] PROJ-5 Start-Reihenfolge Liste → Aufräumen → Nachholen → Kürzel — `AppEnvironment.swift:77, 172-174` (Inspektion, die App hat keine Tests).
- [x] PROJ-5 Übergabe ersetzt, verworfene Aufnahmen kommen nie in die Liste — `AppEnvironment.swift:110`, `RecordingController.swift:371-456`.
- [x] PROJ-5 AC-7, AC-12, AC-16 bis AC-18 — Bereich „Aufnahme“ unverändert, „Umwandlung“ angehängt (`RecordingSettingsPane.swift:30-71`); Suites grün.
- [x] Kein Feature ist Deployed; keine E2E-Suite vorhanden.
- [!] Laufzeit aller Nachbarn (Symbol, Rückfrage, Start-Reihenfolge, Darstellung „Aufnahme“) — no way to run and probe this project was recorded.

## Gefundene Fehler

### BUG-1: Live-Text überholt einen früher gesprochenen nachgeholten Text und geht in der Zwischenablage verloren
- **Schwere:** High
- **Status:** Fixed (Nachprüfung 09.11., ac30c7f)
- **Klasse:** Übergabe in zwei Phasen (sofort in der Schleife, gesammelt danach) bricht die Reihenfolge.
- **Suche:** `grep -rn "delivery.deliver(" Packages/InnoWhisperKit/Sources/Transcription` → 2 (`TranscriptionQueue.swift:285, 292`).
- **Ablauf:** Beim Start wird ein offenes Diktat nachgeholt. Der Nutzer diktiert sofort, sein kurzes Live-Diktat ist zuerst fertig und wartet richtig. Wird das nachgeholte fertig, geht im selben Schritt zuerst das Live-Diktat raus, danach das nachgeholte. Gegenprobe: `["live:Live zwei.", "recovered:Nachgeholt eins."]`. In der Zwischenablage bleibt nur der nachgeholte Text; der Live-Text ist für den Nutzer weg (die Aufnahme bleibt gespeichert, zurückholen geht erst mit PROJ-10).
- **Verletzt:** AC-8, AC-20, Garantie „Reihenfolge“ in `design.md`.

### BUG-2: Ein entfernter Schlüssel geht für wartende Teile noch an Groq
- **Schwere:** Medium
- **Status:** Fixed (Nachprüfung 09.11., ac30c7f)
- **Klasse:** Zugangsdaten werden vor einem Wartepunkt gelesen und danach benutzt.
- **Suche:** `grep -rn -A1 "readKey()" Packages/InnoWhisperKit/Sources/Transcription | grep -c await` → 1 (`TranscriptionQueue.swift:202-205`).
- **Ablauf:** Zwei Diktate mit je 2 Teilen, 3 Plätze. Der Nutzer entfernt den Schlüssel, während 3 Teile laufen. Das 4. Teil startet danach mit dem alten Schlüssel; beide Diktate werden übergeben, kein Hinweis aus AC-12.
- **Verletzt:** EC-5; berührt SEC-01 (ein entfernter Schlüssel verlässt den Mac noch).

### BUG-3: Echte Sätze mit „Untertitel“ werden als Untertitel-Satz gelöscht
- **Schwere:** Medium
- **Status:** Fixed (Nachprüfung 3, 09.11., d709113; Rest über Abschnitts- und Satzgrenzen siehe BUG-20)
- **Klasse:** Muster für erfundene Sätze ist zu weit und trifft gesprochenen Inhalt.
- **Suche:** `grep -nE 'zdf|funk|"amara"' Packages/InnoWhisperKit/Sources/Transcription/Text/TranscriptFilter.swift` → 2 (`:131, :133`).
- **Ablauf:** „Bitte prüfe die Untertitel für den Funk-Spot.“, „Die Untertitel für die ZDF-Doku sind fertig.“, „Ich habe den Funk-Untertitel geändert.“ werden zu leerem Text. Bei einem Ein-Satz-Diktat folgt „Nichts erkannt“ und die Aufnahme wird gelöscht.
- **Verletzt:** AC-16 (nur Untertitel-Sätze entfernen), Pflichtpunkt „nichts erfinden“ in die andere Richtung: echter Text verschwindet.

### BUG-4: Mehrere Live-Texte im selben Schritt überschreiben sich in der Zwischenablage
- **Schwere:** Medium (gilt bis PROJ-7)
- **Status:** Fixed (Nachprüfung 09.11., ac30c7f)
- **Klasse:** Ein Ziel mit nur einem Platz bekommt mehrere Texte pro Schritt.
- **Suche:** `grep -rn "writeToPasteboard(text)" Packages/InnoWhisperKit/Sources/Transcription` → 1, zusammen mit der Suche aus BUG-1.
- **Ablauf:** Genau der Fall aus AC-8: Das zweite Diktat ist zuerst fertig, das erste kommt nach. Beide gehen direkt hintereinander raus; übrig bleibt nur das zweite, zweimal erscheint „Text in der Zwischenablage.“
- **Verletzt:** AC-3, AC-8 (bis PROJ-7 einfügt).

### BUG-5: Erfundener Satz aus einem stillen Mittelteil bleibt, wenn Groqs Werte fehlen oder knapp sind
- **Schwere:** Low
- **Status:** Deferred (Entscheidung Timur, 09.11.)
- **Klasse:** Prüfung auf erfundene Sätze nur über das Gesamtergebnis, nicht je Teil.
- **Suche:** `grep -rn "normalisedInventedPhrases.contains" Packages/InnoWhisperKit/Sources/Transcription` → 1.
- **Ablauf:** `[Anfang.] [Vielen Dank.] [Ende.]` ohne Werte → „Anfang. Vielen Dank. Ende.“
- **Verletzt:** EC-1.

### BUG-6: Protokollzeilen zu Start, Fehler und Wiederholung ohne die verlangten Felder
- **Schwere:** Low
- **Status:** Deferred (Entscheidung Timur, 09.11.)
- **Klasse:** Ereignis-Zeilen ohne festen Feldsatz.
- **Suche:** `grep -n 'not converted:\|Retry requested\|splitting failed' Packages/InnoWhisperKit/Sources/Transcription/Queue/TranscriptionQueue.swift` → 3.
- **Verletzt:** AC-21 (Modell, Sprache, Länge, Teile, Dauer fehlen dort; keine eigene Startzeile).

### BUG-7: Grenz-Antwort ohne Wartezeit wird als gewöhnlicher Fehler gemeldet
- **Schwere:** Low
- **Status:** Deferred (Entscheidung Timur, 09.11.)
- **Klasse:** Grenz-Antwort ohne Wartezeit hat keine eigene Behandlung.
- **Suche:** `grep -rn "rateLimited(let wait?)" Packages/InnoWhisperKit/Sources/Transcription` → 1.
- **Ablauf:** 429 ohne verwertbares `retry-after` → zwei stille Versuche, dann „Umwandlung fehlgeschlagen …“ statt „Groq-Grenze erreicht …“.

### BUG-8: Von der Liste abgelehnte Aufnahme verschwindet ohne Hinweis
- **Schwere:** Low
- **Status:** Deferred (Entscheidung Timur, 09.11.)
- **Klasse:** Stilles Verwerfen ohne Hinweis an den Nutzer.
- **Suche:** `grep -n "list.add(recording)" -A4 Packages/InnoWhisperKit/Sources/Transcription/Queue/TranscriptionQueue.swift | grep -c notify` → 0.
- **Ablauf:** Nur bei einem Programmfehler (Datei außerhalb des Ordners); die Datei wird beim nächsten Start als Rest gelöscht.

### BUG-9: Unsichtbare Richtungs- und Formatzeichen aus der Groq-Antwort bleiben im Text
- **Schwere:** Low
- **Status:** Deferred (Entscheidung Timur, 09.11.)
- **Klasse:** Bereinigung von Modell-Ausgaben nur nach Kategorie Cc; Cf, Zl, Zp bleiben.
- **Suche:** `grep -rn "generalCategory" Packages/InnoWhisperKit/Sources` → 1 (`GroqTranscriber.swift:214`).
- **Ablauf:** `"Betrag \u{202E}0001 €"` erscheint in der Zwischenablage mit umgedrehter Zahl. SEC-07.

### BUG-10: Größengrenze der Groq-Antwort greift erst nach dem vollständigen Laden
- **Schwere:** Low
- **Status:** Deferred (Entscheidung Timur, 09.11.)
- **Klasse:** Größengrenze für Antworten wird erst nach vollständigem Puffern geprüft.
- **Suche:** `grep -rn "URLSession.shared" Packages/InnoWhisperKit/Sources App` → 2 (`GroqTranscriber.swift:22`, `GroqAccess/KeyValidator.swift:41`).
- **Ablauf:** Ein fehlerhafter Gegenüber kann innerhalb des Zeitlimits viel Speicher füllen. SEC-07.

### BUG-11: Unsinnig große gespeicherte Dauer lässt die App bei jedem Start abstürzen
- **Schwere:** Low
- **Status:** Deferred (Entscheidung Timur, 09.11.)
- **Klasse:** Gespeicherte Zahl wird nicht nach oben begrenzt, bevor sie in eine Ganzzahl umgewandelt wird.
- **Suche:** `grep -rnE 'Int(64)?\(\(?[^)]*(\* ?[0-9]|rounded)' Packages/InnoWhisperKit/Sources` → 2 (`TranscriptionQueue.swift:102`; `MicrophoneCapture.swift:269` aus PROJ-5).
- **Ablauf:** Eintrag mit Stand `open` und Dauer `1e16` → Absturz in `receiveRecovered` bei jedem Start. Nur durch einen Prozess desselben Nutzers erreichbar. SEC-02.

### BUG-12: Rückfrage beim Beenden sagt „geht es verloren“, obwohl nachgeholt wird
- **Schwere:** Low
- **Status:** Deferred (Entscheidung Timur, 09.11.; braucht `/refine PROJ-1`, steht als offene Frage in `spec.md`)
- **Klasse:** Nutzertext widerspricht dem neuen Verhalten eines anderen Features.
- **Suche:** `grep -rn "geht es verloren" Packages/InnoWhisperKit/Sources App` → 1.

### BUG-13: Doku anderer Features nach PROJ-6 nicht nachgezogen
- **Schwere:** Low
- **Status:** Deferred (Entscheidung Timur, 09.11.)
- **Klasse:** Doku-Aussagen anderer Features nach einer Querschnitts-Änderung nicht nachgezogen.
- **Suche:** `grep -n "| Umwandlung |" docs/app-shell.md` (1) + `grep -n "is no recovery" Packages/InnoWhisperKit/Sources/Recording/Session/RecordingStorage.swift` (1) + `grep -n "Wiederherstellung gibt es nicht" features/PROJ-5-aufnahme-tastenkuerzel/design.md` (1) → 3.

### BUG-14: Die Aufnahme-Liste wird schon vor der Einzelinstanz-Prüfung geladen und gespeichert
- **Schwere:** Low
- **Status:** Deferred (Entscheidung Timur, 09.11.)
- **Klasse:** Dauerhafte Seiteneffekte im Aufbau der App vor der Einzelinstanz-Prüfung.
- **Suche:** `grep -rnE "^\s+(load|loadStoredKey|loadStored|restore)\(\)\s*$" Packages/InnoWhisperKit/Sources` → 2 (schreibend nur `RecordingList.swift:103`).
- **Ablauf:** Eine zweite gestartete Instanz kann die Liste der laufenden überschreiben; sehr kleines Zeitfenster, Folge: ein Diktat geht verloren.

### BUG-15: Unit-Tests mit Wanduhr-Zeitgrenze werden unter Last zufällig rot
- **Schwere:** Low
- **Status:** Deferred (Entscheidung Timur, 09.11.; zugleich `docs/tech-debt.md` TD-1)
- **Klasse:** Wanduhr-Zeitgrenze in einem Unit-Test.
- **Suche:** `grep -rnE "\.duration < \.seconds\(|ContinuousClock\.now - started < " Packages/InnoWhisperKit/Tests` → 2 (`KeyValidatorTests.swift:54`, `GroqTranscriberTests.swift:243`).

### BUG-16: Abspann-Zeilen ohne eigenen Satzanfang bleiben im Text
- **Schwere:** Low
- **Status:** Fixed (Nachprüfung 3, 09.11., d709113; bewusst nicht entfernte Fälle siehe BUG-21)
- **Klasse:** Erkennung erfundener Sätze hängt an Satzgrenze und Satzanfang statt am Wortlaut des Abspanns.
- **Suche:** `grep -n 'hasPrefix("untertitel")' Packages/InnoWhisperKit/Sources/Transcription/Text/TranscriptFilter.swift` → 1 (`:135`).
- **Ablauf:** „„Untertitel im Auftrag des ZDF, 2020““, „(Untertitel im Auftrag des ZDF für funk, 2017)“, „- Untertitel …“, „Gut, Untertitel im Auftrag des ZDF. Weiter.“ und ein Abspann direkt an einem Abschnitt ohne Schlusspunkt („Bis morgen dann Untertitel im Auftrag des ZDF für funk, 2017“) bleiben stehen. Vor ac30c7f wurden sie entfernt.
- **Verletzt:** AC-16 („egal wo er steht“), Pflichtpunkt 6.

### BUG-17: „Ältere Diktate zuerst“ gilt nur, solange Anfragen warten
- **Schwere:** Low
- **Status:** Deferred (neuer Befund der Nachprüfung)
- **Klasse:** Vorrang nur unter Wartenden, nicht bei freien Plätzen.
- **Suche:** `grep -n "activeRequests < TranscriptionInfo.maximumParallelRequests" Packages/InnoWhisperKit/Sources/Transcription/Queue/TranscriptionQueue.swift` → 1.
- **Ablauf:** Ist das Aufteilen eines späteren Diktats zuerst fertig, belegt es alle drei Plätze, das frühere wartet. Die Reihenfolge der Übergabe bleibt richtig (AC-8); nur das frühere Diktat kommt etwas später.

### BUG-18: Unbekannter Wortlaut vor „Amara.org-Community“ bleibt als Rest stehen
- **Schwere:** Low
- **Status:** Fixed (Nachprüfung 3, 09.11., d709113: Abspann wird ganz oder gar nicht entfernt)
- **Klasse:** Abspann wird nur zum Teil entfernt, der Rest der Zeile bleibt.
- **Suche:** `grep -n 'subtitles\\s+by\\s+the\\s+)?amara' Packages/InnoWhisperKit/Sources/Transcription/Text/TranscriptFilter.swift` → 1.
- **Ablauf:** „Untertitelung aufgrund der Amara.org-Community“ → «Untertitelung aufgrund der»; ein Diktat nur aus so einer Zeile ergibt Rest-Text statt „Nichts erkannt“ (AC-15).

### BUG-19: Neues Filter-Muster hängt bei langen Leerraum-Läufen in der Groq-Antwort
- **Schwere:** Medium
- **Status:** Fixed (Nachprüfung 3, 09.11., d709113: 20.000 Umbrüche 0,04 s statt 34,5 s)
- **Klasse:** Unverankerter regulärer Ausdruck mit freiem Leerraum-Quantor auf ungeprüfter Modell-Ausgabe.
- **Suche:** `grep -rnE '\\s\*' Packages/InnoWhisperKit/Sources App` → 4 (`TranscriptFilter.swift:107, 109, 111, 112`; kritisch `:107`).
- **Ablauf:** 20.000 Zeilenumbrüche, geschützte Leerzeichen oder U+2028 in einem Teil → 30 bis 35 s auf dem Haupt-Thread, die App hängt (quadratisches Wachstum). Alter Stand: 0,02 s. Normale Diktate: unter 0,01 s. SEC-02, SEC-07.

### BUG-20: Ende eines gesprochenen Satzes fällt weg, wenn Groq genau vor einem Abspann-Wortlaut trennt
- **Schwere:** Low
- **Status:** Deferred (neuer Befund der dritten Nachprüfung; Rest der BUG-3-Klasse)
- **Klasse:** Abspann-Erkennung verlässt sich auf Abschnitts- und Satzgrenzen als Satzanfang und trifft so das Ende gesprochener Sätze.
- **Suche:** `grep -nE 'removeAll\(where: isCreditLine\)|closingPunctuation: Set' Packages/InnoWhisperKit/Sources/Transcription/Text/TranscriptFilter.swift` → 2.
- **Ablauf:** Abschnitte `["Ich danke der", "Amara.org-Community"]` → «Ich danke der»; „Die Liste: Ton; Untertitel im Auftrag des ZDF; Schnitt.“ → «Die Liste: Ton; Schnitt.». Braucht den vollständigen Abspann-Wortlaut und eine Groq-Abschnittsgrenze oder „;“, „““, „)“ direkt davor; wie oft Groq so trennt, ist ohne echte Antworten offen.

### BUG-21: Abspann ohne eigene Satzgrenze mitten im Text bleibt stehen
- **Schwere:** Low
- **Status:** Deferred (bewusste Entscheidung „Einfacher Weg“ vom 09.11.; weicht von AC-16 „egal wo er steht“ ab, braucht `/refine PROJ-6` oder bleibt zurückgestellt)
- **Klasse:** Erkennung nur über ganze Sätze und Abschnitte.
- **Suche:** none (bewusste Grenze, in `design.md` Bau-Notizen beschrieben).
- **Ablauf:** „Gut, Untertitel im Auftrag des ZDF. Weiter.“, „Bis morgen dann Untertitel im Auftrag des ZDF für funk, 2017“ im selben Abschnitt, zwei Abspanne ohne Trennung, Abspann in einfachen Anführungszeichen ('…'), Abspann zwischen zwei Gedankenstrichen, geschützter Bindestrich U+2011 in „Amara.org‑Community“.

### BUG-22: Nach dem Entfernen eines Abspanns vor einem Zeilenumbruch kleben Wörter zusammen
- **Schwere:** Low
- **Status:** Deferred (neuer Befund der dritten Nachprüfung)
- **Klasse:** Beim Entfernen eines Teilstücks fällt das Trennzeichen weg, das der Nachbar braucht.
- **Suche:** `grep -nE 'kept \+= sentence|character\.isNewline' Packages/InnoWhisperKit/Sources/Transcription/Text/TranscriptFilter.swift` → 2.
- **Ablauf:** `"Gut. Untertitel im Auftrag des ZDF\nWeiter."` → «Gut.Weiter.».

### BUG-23: „Untertitel: ZDF“ ohne Zusatz wird entfernt, obwohl der Entwurf einen Zusatz verlangt
- **Schwere:** Low
- **Status:** Deferred (neuer Befund der dritten Nachprüfung)
- **Klasse:** Wortlaut-Muster ist breiter als die Regel im Entwurf.
- **Suche:** `grep -cE '\?: \?zdf' Packages/InnoWhisperKit/Sources/Transcription/Text/TranscriptFilter.swift` → 1.
- **Ablauf:** „Ton: WDR. Untertitel: ZDF. Schnitt: intern.“ → «Ton: WDR. Schnitt: intern.»

## Nicht geprüft in diesem Lauf

- [!] AC-5, AC-6 Tempo mit echtem Netz — no way to run and probe this project was recorded; Live-Test mit Timur.
- [!] AC-17, AC-18 20 echte Diktate auf zwei Macs, Lesung durch Timur — Live-Test.
- [!] Liefert Groq `no_speech_prob` und `avg_logprob` bei beiden Modellen (offene Frage in `design.md`) — Groq-Aufruf hier nicht erlaubt; die App schreibt es ins Protokoll („segments with values N of M“).
- [!] Alle sichtbaren Teile: Symbol „wandelt um“ und „Problem“, Hinweise, Zwischenablage, Einstellungsgruppe „Umwandlung“, Öffnen der Schlüssel-Einstellungen — no way to run and probe this project was recorded.
- [!] AC-13 Ergebnis der echten Neuprüfung des Schlüssels, EC-1 mit echten Groq-Werten, Wortübergänge an den Schnitten mit echter Sprache.
- [!] Festplatten-Cache von `URLSession`, Release-Programm mit PROJ-6.

## Weitere Hinweise (nicht als Fehler gezählt)

- Die Satzliste kennt den häufigen deutschen Whisper-Satz „Untertitel von Stephanie Geiges“ nicht, ebenso keine Folge aus zwei erfundenen Sätzen („Vielen Dank. Tschüss.“). Wichtig für den Live-Test zu AC-17.
- Ein Lesefehler im Schlüsselbund erscheint als „Kein Groq-Zugangsschlüssel eingetragen.“, obwohl ein Schlüssel existiert.
- Ein Lesefehler mitten in einer Aufnahme zählt als „beschädigt“; die Aufnahme wird endgültig gelöscht statt neu versucht.
- Nachgeholte Diktate starten auch, wenn danach die Einführung offen ist, und überschreiben dabei die Zwischenablage.
- Eine unlesbare Aufnahme-Liste zählt als leer; danach löscht das Aufräumen auch die Dateien offener Diktate (so im Entwurf, aber Datenverlust bei beschädigten Einstellungen).
- In der Gruppe „Umwandlung“ ist das Modell ein Segment-Schalter, die Sprache ein Aufklappmenü, wie Modus und Mikrofon in den Gruppen darüber.
- Die Tests schreiben in das echte Protokoll-Subsystem `com.innosolv.InnoWhisper`.
- Bis zu 50 Aufnahmen mit Personendaten liegen dauerhaft im Ordner und damit auch in Time-Machine-Sicherungen (so in AC-19; Hinweis aus ADR-006 gilt weiter).

## Neue Tests (Schritt 6)

Keine. Die reine Logik (Einstellungen, Aufteiler, Groq-Anschluss, Filter, Liste, Übergabe, Warteschlange, Nachholen) ist durch die beim Bau geschriebenen Tests abgedeckt, die alle eine Rot-Probe hatten. Die Fehler liegen im Zusammenspiel; ihre Tests schreibt `/build` zusammen mit der Korrektur, rot zuerst.

## E2E-Tests

Nicht ausgeführt (native Menüleisten-App, kein Browser-Ablauf).

## Ergebnis

**NICHT BEREIT.** Ein Fehler der Stufe High (BUG-1) ist Open. Dazu drei Medium (BUG-2, BUG-3, BUG-4) und elf Low (BUG-5 bis BUG-15). Außerdem ist kein Laufzeit-Kriterium ausgeführt; der Live-Test mit Timur steht aus. Status bleibt In Review.

**Entscheidung Timur, 09.11.2026:** „Schwer + 3 mittlere“. BUG-1 bis BUG-4 werden jetzt behoben (Open), BUG-5 bis BUG-15 kommen später gesammelt (Deferred). Der Live-Test folgt nach der Korrektur zusammen mit der Nachprüfung.
