# QA-Ergebnisse PROJ-4: Groq-Zugang

## Nachtrag 2026-11-06: Nachprüfung BUG-1 und BUG-2

**Umfang:** `git diff --stat 30892d1..HEAD`. 30892d1 ist der Commit des Berichts, HEAD ist 7beaf3f. Geänderte Produktionsdateien:
- `Sources/GroqAccess/GroqKeyModel.swift`
- `Sources/GroqAccess/KeySettingsSection.swift`
- `Sources/GroqAccess/KeyStore.swift`

Dazu kommen 2 Testdateien und `design.md`. Geteilter Code ist nicht betroffen. Deshalb gab es einen unabhängigen `qa-engineer`-Prüfer mit allen drei Bereichen.

**Prüfläufe:**
- Testlauf einmal vor dem Prüfer: 157 Tests in 23 Suites bestanden (`scratchpad/qa-proj4-suite-2.log`).
- Lint der geänderten Dateien: Exit 0.
- `commands.build`: BUILD SUCCEEDED (Owner, Stand 7beaf3f).

**Ergebnisse:**
- [x] **BUG-1 behoben.** Die Suche `grep -n "await checker.check" …/GroqAccess/*.swift` liefert 2 Treffer (`GroqKeyModel.swift:223, :259`). Auf beide folgt `guard removals == removalsBefore else { return discardResult() }` (`:226, :262`). Der Zähler steigt nur nach einer gelungenen Löschung (`:198`). „Entfernen“ ist während einer Prüfung gesperrt (`KeySettingsSection.swift:31-32`).
  - Test: `removeDuringARunningCheckLeavesNoKey`.
  - Gegenproben des Prüfers in einer Kopie des Pakets: abgelehnte Prüfung, „Ändern“ mit altem Schlüssel, Prüfung nach Netzrückkehr, gescheiterte Löschung, zweimal Entfernen, neuer Schlüssel nach dem Verwerfen. 8/8 bestanden.
  - Rot-Probe: Ohne die beiden `guard` schlagen die Tests mit der erwarteten Abweichung fehl.
- [x] **BUG-2 behoben, gemessen an der Entscheidung von Timur.** Der Schlüssel bleibt im Login-Schlüsselbund, und nichts verspricht mehr einen Schutz, den macOS nicht einhält.
  - Die alte Suche hat weiter 1 Treffer (`KeyStore.swift`). Das ist so gewollt.
  - Gegensuche nach `ThisDeviceOnly|AfterFirstUnlock|kSecAttrAccessible|nur auf diesem Mac|Entsperrung` in Code, Tests und Doku. Für PROJ-4 bleiben nur Stellen, die die Zusage verneinen (`KeyStoreTests.swift:24`, `design.md:143`). Dazu kommt die erledigte Planzeile T3 in `tasks.md:16`; sie beschreibt den Bau, kein Verhalten.
  - Test: `keyGoesToTheLoginKeychainWithoutICloud` prüft: keine Schutzklasse, kein Data-Protection-Schlüsselbund, keine iCloud-Synchronisierung.
- [x] **AC-13, AC-15** jetzt erfüllt (Belege siehe BUG-1). Das Problem „Kein Groq-Schlüssel.“ mit „Schlüssel eintragen“ erscheint auch nach dem Verwerfen.
- [x] **AC-11, AC-12, AC-18, EC-3, EC-6, EC-8** von der Änderung nicht verschlechtert.
  - `isChecking` wird vor dem Verwerfen zurückgesetzt.
  - Die neue Protokollzeile „Check result discarded: key was removed meanwhile“ ist fester Text.
  - Ohne Entfernung ist der Ablauf unverändert.
- [x] **Sicherheit:**
  - `git diff 30892d1..HEAD | grep -cE 'gsk_[A-Za-z0-9]{20,}'` = 0.
  - SEC-08: Der einzige entfernte Test (`keyStaysOnThisMac`) ist durch den gegenteiligen Test ersetzt. Das ist durch die Entscheidung unter BUG-2 gedeckt und keine Abschwächung.
- [x] **Regression:** Die Änderung berührt nur `GroqAccess`. Die Suites von PROJ-1 bis PROJ-3 sind grün.
- [!] **NOT VERIFIED:** Bedienung in der laufenden App (gesperrtes „Entfernen“ mit Ladeanzeige) und der echte Schlüsselbund mit dem alten Eintrag. Grund: no way to run and probe this project was recorded.
- **Neue Befunde:** keine.
- **Hinweis:** Bei `design.md:143` fehlt die SEC-Kennung (SEC-03). Das ist nur Doku.

Alles Übrige unten gilt unverändert seit dem ersten Lauf vom 06.11. Ausnahmen: die Status von BUG-1 und BUG-2 und die Zeilennummern bei BUG-7.

---

**Geprüft:** 2026-11-06, erste Prüfung (keine Nachprüfung)
**App-Adresse:** hier nicht lauffähig (`probe.kind: none`, native Menüleisten-App). Laufzeitkriterien gelten nur dort als belegt, wo ein Test durch Timur aufgezeichnet ist: Zeilen aus `~/Library/Logs/InnoWhisper/InnoWhisper.log` und dem macOS-Systemprotokoll (securityd, SecurityAgent) mit Uhrzeit, dazu Timurs Sichtprüfung.
**Prüfer:** QA Engineer (KI). Drei unabhängige `qa-engineer`-Prüfer ohne Kenntnis des Baus: Abnahme (Schritt 2), Sicherheit (Schritt 3), Regression (Schritt 4 und 5). Zusammengeführt vom Owner.
**Testlauf:** `swift test --package-path Packages/InnoWhisperKit` einmal vor dem Start der Prüfer: 152 Tests in 22 Suites bestanden, 0 Fehlschläge (`scratchpad/qa-proj4-suite.log`). Nach Schritt 6 kamen 4 Tests dazu, siehe unten.
**Lint:** `swift format lint --strict --recursive App Packages` Exit 0 (Regressions-Prüfer).
**Bau:** `commands.build` → BUILD SUCCEEDED, Exit 0 (`scratchpad/qa-proj4-build.log`, Owner).
**Geprüfter Stand:** Branch `feat/PROJ-4-groq-zugang`, Commit 22baf39. Timurs Test lief am 06.11. zwischen 16:28 und 17:06 mit dem Debug-Bau vom 16:33. Die Übernahme lief noch auf dem Bau davor, der sich nur in der Ausrichtung des Eingabefelds unterscheidet.

> Legende: `[x]` in diesem Lauf belegt (mit Nachweis) · `[ ] BUG` als fehlerhaft belegt · `[!] NOT VERIFIED` nicht prüfbar (mit Grund). „Timur, 06.11.“ = Test durch Timur auf seinem Mac (macOS 26.5.1).

## Abnahmekriterien

### Einführungsschritt „Zugangsschlüssel“
- [x] **AC-1** Schritt mit Reihenfolge 10 vor Mikrofon (30) und Bedienungshilfen (40): `GroqAccess.swift:20-21`, `PermissionSteps.swift:10,15`. `SecureField` und „Prüfen“: `KeyEntryView.swift:30-48`. Erklärsatz wortgleich: Test `textsMatchTheSpec`. Timur, 06.11.: Schritt erschien als zweite Seite (Protokoll 16:28:55 „Onboarding welcome completed“, danach Schlüssel-Schritt).
- [x] **AC-2** „Weiter“ gesperrt ohne nutzbaren Schlüssel, kein Überspringen: `OnboardingFlow.swift:100-103`, `GroqKeyModel.swift:123`; Test `weiterIsFreeOnlyWithAWorkingOrUncheckedKey`.
- [x] **AC-3** Hilfetext wortgleich, Link auf `https://console.groq.com/keys`: `KeyEntryView.swift:7-12`; Test `textsMatchTheSpec` (nur der Host des Links). Ob der Browser aufgeht: siehe Nicht geprüft.
- [x] **AC-4** Drei Ergebnisse, Zuordnung 200/429 → gilt, 401/403 → abgelehnt, sonst nicht erreichbar, Grenze 15 s: `KeyValidator.swift:59-84`; Tests `groqAnswersMapToTheThreeResults`, `hangingAnswerStopsAtTheTimeLimit`, neu `resultMessagesMatchTheSpec`, `onlyWorksCountsAsSuccess`. Timur, 06.11.: echtes Groq 401 in 194 ms (16:30:17), 200 in 199 bis 411 ms.
- [x] **AC-5** Gültiger Schlüssel wird gespeichert, „Weiter“ frei: `GroqKeyModel.swift:256, 263-275`; Test `trimmedKeyIsCheckedAndStoredWhenGroqAccepts`. Timur, 06.11.: 16:31:02 „Key check: valid, status 200“, „Key saved as valid“, 16:31:03 „Onboarding step completed: groq-key“.
- [x] **AC-6** Abgelehnter Schlüssel wird nicht gespeichert, Feld behält den Inhalt: `GroqKeyModel.swift:258`, `KeyEntryView.swift:59`; Test `rejectedKeyIsNotStoredAndTheOldOneStays`. Timur, 06.11.: Ablehnungstext gesehen (16:30:17, 401).
- [x] **AC-7** Hinweis wortgleich, Knopf über dem Feld, Feld bleibt: `KeyEntryView.swift:13-16`, `KeyStep.swift:25-36`; neu `hintAndQuestionMatchTheSpec`. Timur, 06.11.: Hinweis und Knopf gesehen.
- [x] **AC-8** Übernahme liest nur, speichert im eigenen Eintrag, prüft: `GroqKeyModel.swift:166-183`; `LegacyKeyReader.swift` ohne schreibende `SecItem`-Aufrufe (0 Treffer). Systemprotokoll 16:28:50 bis 16:29:06: InnoWhisper ruft beim alten Eintrag nur `SecItemCopyMatching` auf. Genau ein macOS-Schlüsselbund-Fenster mit Passwort (securityd 16:28:58,824 „displaying keychain prompt“, einziger Treffer seit 15:00), danach 16:29:03,9 „Key taken over from old app“, 200 in 280 ms.
- [x] **AC-9** Gescheiterte Übernahme: Text wortgleich (neu `resultMessagesMatchTheSpec`), Feld bleibt; Test `failedTakeoverLeavesTheFieldAsTheWay`. Ein echtes Ablehnen des macOS-Fensters: siehe Nicht geprüft.
- [x] **AC-10** Ohne Antwort als „noch nicht geprüft“ gespeichert, Nachprüfen bei Netzrückkehr und beim Start: `GroqKeyModel.swift:126-137, 237-240, 257`; Tests `noAnswerStoresTheKeyAsNotYetChecked`, `networkReturnChecksOnlyAKeyThatWasNotChecked`. Live ohne Netz: siehe Nicht geprüft.

### Einstellungen
- [x] **AC-11** Stand, letzte 4 Zeichen, drei gleich große Knöpfe: `KeySettingsSection.swift:15-37`, `KeyEntryView.swift:96-101`; neu `statusTitlesMatchTheSpec`. Timur, 06.11.: Bildschirmfoto mit „Schlüssel funktioniert •••• bgsZ“ und „Prüfen / Abbrechen / Entfernen“ gleich groß. Hinweis: Beim Stand „Kein Schlüssel“ steht statt der drei Knöpfe das Eingabefeld (`KeySettingsSection.swift:21-22`); ohne Schlüssel gibt es nichts zu prüfen oder zu entfernen.
- [x] **AC-12** „Ändern“ ersetzt den Schlüssel an Ort und Stelle, bei Ablehnung bleibt der alte: `KeyStore.swift:64`; Test `rejectedKeyIsNotStoredAndTheOldOneStays`. Timur, 06.11.: 16:31:56 und 16:32:32 neuer Schlüssel gespeichert, 200.
- [ ] **AC-13** BUG-1. Der Normalweg funktioniert: Rückfrage wortgleich (neu `hintAndQuestionMatchTheSpec`), Test `removeDeletesTheKeyAndReportsItMissing`, Timur 06.11. 17:06:19 „Key removed“ mit Warndreieck. „Entfernen“ während einer laufenden Prüfung hinterlässt aber „Schlüssel funktioniert“ ohne Schlüssel.

### Hinweise und Prüfung beim Start
- [x] **AC-14** Prüfung beim Start, bei Ablehnung „ungültig“ und Problem mit „Schlüssel ändern“: `App/AppEnvironment.swift:86-87`, `GroqKeyModel.swift:126-128, 223, 318-334`; Tests `storedKeyRefusedAtStartBecomesInvalidAndIsReported`, `problemButtonOpensTheKeySettingsWithTheFieldOpen`. Timur, 06.11.: Prüfung beim Start 16:33:15, „Key at start: valid“, 200 in 243 ms. Der Fall „401 beim Start“: siehe Nicht geprüft.
- [ ] **AC-15** Gilt im Normalfall (Test `missingKeyIsReportedOnlyAfterTheOnboarding`; Timur, 06.11.: Warndreieck und „Kein Groq-Schlüssel.“ nach dem Entfernen). Verletzt im Fall von BUG-1, weil die Meldung dann ausbleibt.
- [x] **AC-16** Problem verschwindet sofort bei gültigem Schlüssel: `GroqKeyModel.swift:277-289`; Test `validKeyWithdrawsTheProblemAtOnce`. Timur, 06.11.: nach dem erneuten Eintragen (16:31:56) „missing -> valid“.

### Speicherung und Protokoll
- [x] **AC-17** Schlüssel nur im Schlüsselbund. In diesem Lauf gezählt: `gsk_` 0-mal in `InnoWhisper.log` und `debug.log`, 0-mal in `com.innosolv.InnoWhisper.plist`, 0-mal im Systemprotokoll eines Tages (1519 und 6452 Zeilen), 0-mal in URL-Cache und HTTPStorages, keine Absturzberichte. Einziges `defaults.set` schreibt den Stand (`GroqKeyModel.swift:286`). Kein `NSPasteboard`. Wo genau im Schlüsselbund er liegt: BUG-2.
- [ ] **AC-18** BUG-3. Keine Teile des Schlüssels im Protokoll (`LogMessage.swift:17-77` lässt keinen freien Text zu, Test `compilerRejectsFreeText`, alle 15 `Log.write` in `GroqKeyModel.swift` geprüft). Die von der AC genannte Zeile „Prüfung gestartet“ fehlt aber.

## Grenzfälle

- [x] **EC-1** Leerzeichen und Zeilenumbrüche am Rand werden entfernt: `GroqKeyModel.swift:340-343`; Test `trimmedKeyIsCheckedAndStoredWhenGroqAccepts`.
- [x] **EC-2** Leeres Feld: „Prüfen“ gesperrt: `GroqKeyModel.swift:140-142`, `KeyEntryView.swift:47`; Test `emptyOrMalformedInputIsNeverSentToGroq`.
- [x] **EC-3** Nur eine Prüfung gleichzeitig. Sperre ohne `await` zwischen Prüfen und Setzen auf dem Main Actor: `GroqKeyModel.swift:151, 167, 205, 217, 251`. Test `onlyOneCheckRunsAtATime`.
- [x] **EC-4** 429 gilt als funktionierend: `KeyValidator.swift:61`; Test `groqAnswersMapToTheThreeResults`.
- [x] **EC-5** Andere Codes, keine Antwort und Zeitgrenze ergeben „nicht erreichbar“: `KeyValidator.swift:63`; Tests `groqAnswersMapToTheThreeResults`, `hangingAnswerStopsAtTheTimeLimit`, `noNetworkCountsAsNotReachable`.
- [x] **EC-6** Gespeicherter Schlüssel abgelehnt: Stand „ungültig“, Schlüssel bleibt: `GroqKeyModel.swift:223`; Test `storedKeyRefusedAtStartBecomesInvalidAndIsReported`.
- [x] **EC-7** Abbruch mitten in der Einführung, Schritt gilt mit gespeichertem Schlüssel als erledigt: `KeyStep.swift:10-11`; Test `storedKeySatisfiesTheStep`.
- [x] **EC-8** Speichern verweigert: Text wortgleich (neu `resultMessagesMatchTheSpec`), Protokoll nur mit Fehlercode (`GroqKeyModel.swift:264-269`); Test `refusedSaveShowsAMessageAndKeepsTheState`. Echter gesperrter Schlüsselbund: siehe Nicht geprüft.
- [x] **EC-9** Hinweis nur, wenn kein eigener Schlüssel da ist und die alte App einen hat. Die Prüfung liest nur Merkmale: `LegacyKeyReader.swift:36-38`; Test `oldEntryIsLookedUpWithoutReadingTheKey`. Timur, 06.11.: kein macOS-Fenster beim Öffnen des Schritts (16:28:55), erst beim Klick (16:28:58,8).

## Sicherheit

Grundlage `docs/kit/guides/security.md`. Geprüft: SEC-01, SEC-02, SEC-03 (lokaler Speicher), SEC-08. Entfallen, weil es keine passende Oberfläche gibt: SEC-04 (keine eigene Anmeldung, der Groq-Schlüssel ist ein Anbieter-Schlüssel), SEC-05/06 (kein HTTP-Server, kein Web-Formular), SEC-07 (kein KI-Aufruf in diesem Feature).

- [x] **Schlüssel nicht im Protokoll** (SEC-01): Zählungen siehe AC-17; auch 0-mal `Bearer` im Systemprotokoll.
- [x] **Keine Geheimnisse im Repo oder Programm** (SEC-01): `git log -p --all | grep -cE 'gsk_[A-Za-z0-9]{20,}'` = 0; keine `.env`/`.p12`/`.pem` getrackt; `strings` auf das gebaute Programm findet nur den Platzhalter `gsk_…`.
- [x] **Übertragung**: feste HTTPS-Adresse (`GroqAccess.swift:8`), kein ATS-Ausnahmeeintrag in der gebauten `Info.plist`, 0-mal `http://`, keine eigene Zertifikatsprüfung. Schlüssel nur im Header `Authorization` (Test `keyGoesOnlyIntoTheAuthorizationHeader`). Es geht nur ein `GET` ohne Inhalt an Groq, die Antwort wird außer dem Statuscode verworfen.
- [x] **Eingabeprüfung** (SEC-02): nur 1 bis 200 Zeichen im Bereich 0x21 bis 0x7E, also keine Zeilenumbrüche und keine Header-Einschleusung (`GroqKeyModel.swift:346-349`), geprüft vor jedem Senden; Test `emptyOrMalformedInputIsNeverSentToGroq`.
- [x] **Eintrag der alten App unverändert** (AC-8): siehe dort. Dass dessen Zeitstempel 16:30:59 lautet, liegt an der alten App selbst (WhisperDictation, PID 10279: `SecItemDelete` und `SecItemAdd` laut Systemprotokoll).
- [x] **Keine iCloud-Synchronisierung**: `kSecAttrSynchronizable` nicht gesetzt (`KeyStore.swift:35-49`).
- [x] **Fehlermeldungen verraten nichts**: nur feste Texte (`GroqKeyModel.swift:57-66`), im Protokoll nur OSStatus-Zahlen.
- [x] **Keine abgeschwächten Prüfungen** (SEC-08): `git diff 5c18f76^..HEAD` über Format-Regeln, `Package.swift` und Xcode-Projekt bringt nur neue Einträge für GroqAccess; kein abgeschalteter Test.
- [ ] **Ablage im Schlüsselbund**: BUG-2.
- [!] Zugriffsschutz des eigenen Eintrags gegen fremde Apps: Die Prüfung würde ein macOS-Passwortfenster auslösen, das war ausgeschlossen.
- [!] Mitschnitt einer echten Anfrage, Weiterleitung mit `Authorization`-Header: no way to run and probe this project was recorded.

**Sicherheit gesamt:** 9 Prüfungen belegt, davon 1 Befund (BUG-2); 2 NOT VERIFIED; 4 Kontrollen entfallen mangels Oberfläche.

## Regression

- [x] Testlauf 152/152, darunter alle Suites von PROJ-1 bis PROJ-3. Testdateien von PROJ-1 bis PROJ-3 hat PROJ-4 nicht verändert (`git diff ae3e44a..HEAD`).
- [x] PROJ-3 Einführung: Reihenfolge, „Schritt X von Y“, Sperre von „Weiter“, Fortsetzen und neue Schritte nach einem Update halten (`OnboardingFlow.swift:29-49, 94-103`; Tests `afterUpdateOnlyNewOpenStepsAndDoneAreShown`, `newSatisfiedStepCompletesAutomatically`). Die Problem-Kennungen sind getrennt (`permission.*` und `groq.key`, `ProblemCenter.swift:55-66`). Timur, 06.11.: Einführung bis „Fertig“ durchlaufen (16:31:20).
- [x] PROJ-3 Gruppe „Erlaubnisse“: unverändert, nur das Formular baut jetzt die App (`AccessPane.swift:14-31`, `App/AppEnvironment.swift:67-74`). Timur, 06.11.: Bildschirmfoto zeigt beide Gruppen mit „Erlaubt“.
- [x] PROJ-1 Rahmen: Bereich `.access` genau einmal registriert, Hinweise eines Bereichs stehen untereinander (`SettingsWindowView.swift:36-42`), Zustand „Problem“ über dieselbe ProblemCenter (Test `StateTests.statusPriority`).
- [x] PROJ-2 Protokoll: nur `LogCategory.groq` neu (`LogFile.swift:16`); Aufbewahrung unverändert; keine freien Texte (siehe AC-18).
- [!] Ob der Knopf „Schlüssel eintragen“ im Menüleisten-Fenster dieses Fenster schließt, bevor sich die Einstellungen öffnen (PROJ-1 AC-11, `keepsOwnActionInPanel: true` in `GroqKeyModel.swift:333`): no way to run and probe this project was recorded; Timur hat den Knopf nicht ausprobiert.

## Gefundene Fehler

### BUG-1: „Entfernen“ während einer laufenden Prüfung zeigt danach „Schlüssel funktioniert“ ohne Schlüssel
- **Schwere:** Medium
- **Status:** Fixed (Nachprüfung 06.11., 7beaf3f)
- **Klasse:** Zustand wird nach einem `await` ohne erneute Prüfung geschrieben; ein veraltetes Prüfergebnis überschreibt eine spätere Aktion des Nutzers.
- **Suche:** `grep -n "await checker.check" Packages/InnoWhisperKit/Sources/GroqAccess/*.swift` → 2 Treffer (`GroqKeyModel.swift:218` und `:252`).
- **Nachstellen:**
  1. Schlüssel gespeichert, Netz langsam (die Prüfung dauert bis zu 15 s).
  2. In den Einstellungen „Prüfen“ klicken, dann sofort „Entfernen“ und bestätigen („Entfernen“ ist nicht gesperrt, `KeySettingsSection.swift:31`).
  3. Erwartet: „Kein Schlüssel“ und Warndreieck. Tatsächlich: „Schlüssel funktioniert“, keine Warnung, `isUsable` wahr, in den Einstellungen steht „valid“. Erst ein Neustart korrigiert es.
  - Variante: Entfernen während „Ändern“ und „Prüfen“. Der neue Schlüssel wird danach trotzdem gespeichert.
- **Beleg:** Gegenproben des Abnahme-Prüfers in einer Kopie des Pakets (`QAProbeTests.removeDuringRunningCheck`, `QAProbe2Tests.removeDuringChangeCheck`).
- **Betrifft:** AC-13, AC-15.

### BUG-2: Schlüssel liegt im dateibasierten Login-Schlüsselbund, „nur auf diesem Mac“ gilt nicht
- **Schwere:** Medium
- **Status:** Fixed (Nachprüfung 06.11., 7beaf3f)
- **Klasse:** Schutzklasse im Schlüsselbund gesetzt, ohne den Data-Protection-Schlüsselbund zu wählen; macOS ignoriert das Attribut dann stillschweigend.
- **Suche:** `grep -rl "SecItemAdd" Packages/InnoWhisperKit/Sources App | xargs grep -L "kSecUseDataProtectionKeychain"` → 1 Treffer (`KeyStore.swift`).
- **Beleg:** Systemprotokoll beim Entfernen 17:06:19,226: InnoWhisper schreibt `/Users/timurmutluer/Library/Keychains/login.keychain-db`. `KeyStore.swift:35-49` setzt `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, aber nicht `kSecUseDataProtectionKeychain`. Der Test `keyStaysOnThisMac` prüft nur die Abfrage, nicht den Ort.
- **Folge:** Der Schlüssel zieht mit dem Login-Schlüsselbund über Migrationsassistent oder Time Machine auf einen anderen Mac, verschlüsselt mit dem Login-Passwort. In iCloud landet er nicht. Die Zusage in `design.md` (Technische Entscheidungen, Zeile „Schlüsselbund nur auf diesem Mac“) stimmt nicht.
- **Entscheidung Timur, 06.11.:** Der Schlüssel darf im normalen Login-Schlüsselbund bleiben und beim Umzug auf einen neuen Mac mitziehen. Behoben ist der Fehler, wenn Entwurf, Schlüsselbund-Abfrage und Test nichts mehr versprechen, was macOS nicht einhält.
- **Hinweis:** Der Data-Protection-Schlüsselbund braucht bei Developer ID in der Regel eine Zugriffsgruppe mit Provisioning-Profil. Ob das gebaut oder die Zusage im Entwurf korrigiert wird, ist eine Entscheidung (`/architecture` bzw. PROJ-14), keine reine Code-Korrektur.

### BUG-3: Protokoll vermerkt nicht „Prüfung gestartet“
- **Schwere:** Low
- **Status:** Deferred
- **Klasse:** Ablauf im Protokoll unvollständig.
- **Suche:** `grep -rn "Log.write" Packages/InnoWhisperKit/Sources/GroqAccess | grep -ci "start"` → 3 Treffer, alle zum Programmstart („Key at start“, `GroqKeyModel.swift:295, 302, 305`); für den Beginn einer Prüfung 0.
- **Folge:** Eine hängende Prüfung ist bis zu 15 s im Protokoll unsichtbar. Betrifft AC-18.

### BUG-4: Texte im Einführungsrahmen gehen nur von Erlaubnissen aus
- **Schwere:** Low
- **Status:** Deferred
- **Klasse:** Texte der Einführung, die jeden Schritt als Erlaubnis behandeln.
- **Suche:** `grep -rn "Erst nach der Erlaubnis\|zwei Erlaubnisse" Packages/InnoWhisperKit/Sources/Onboarding` → 2 Treffer.
  - `OnboardingView.swift:73`: VoiceOver sagt beim gesperrten „Weiter“ im Schlüssel-Schritt „Erst nach der Erlaubnis möglich“.
  - `WelcomeAndDoneViews.swift:11`: Der Willkommenstext kündigt „zwei Erlaubnisse“ an, als Nächstes kommt aber der Schlüssel. Dieser Text ist in PROJ-3 AC-3 wörtlich festgelegt, deshalb braucht seine Änderung `/refine PROJ-3`.

### BUG-5: Ergebniszeile bleibt stehen, obwohl sich der Stand geändert hat
- **Schwere:** Low
- **Status:** Deferred
- **Klasse:** Veraltete Ergebniszeile.
- **Suche:** `grep -n "lastResult = " Packages/InnoWhisperKit/Sources/GroqAccess/GroqKeyModel.swift` (Stellen, an denen die Zeile gesetzt oder geleert wird).
- **Nachstellen (aus dem Code abgeleitet):** Schlüssel ohne Netz speichern, die Zeile „… wird gespeichert und später geprüft“ steht. Beim Wiederverbinden lehnt Groq ab. Die Gruppe zeigt „Ungültig“, darunter steht weiter der alte Satz (`KeySettingsSection.swift:40-41`, `checkStored` ohne `showResult` leert `lastResult` nicht, `GroqKeyModel.swift:226`).

### BUG-6: Meldungen passen nicht zur Übernahme aus der alten App
- **Schwere:** Low
- **Status:** Deferred
- **Klasse:** Ergebnistexte, die nur für das Einfügen geschrieben sind.
- **Suche:** none.
- **Belege:**
  - Lehnt Groq den übernommenen Schlüssel ab, steht dort „Prüfe, ob du ihn vollständig kopiert hast.“, obwohl der Nutzer nichts kopiert hat (`GroqKeyModel.swift:182, 258`).
  - „Füge deinen Schlüssel einfach unten ein.“ erscheint als Ergebniszeile unter dem Feld, „unten“ zeigt also ins Leere (`KeyEntryView.swift:50-52`, `KeyStep.swift:36`).
  - Der Wortlaut ist in AC-4 und AC-9 festgelegt. Eine Änderung braucht `/refine PROJ-4`.

### BUG-7: Lesefehler beim Start zeigt „Kein Schlüssel“ ohne neuen Versuch
- **Schwere:** Low
- **Status:** Deferred
- **Klasse:** Fehler beim Lesen wird wie „nichts gespeichert“ behandelt.
- **Suche:** `grep -n "status = .missing" Packages/InnoWhisperKit/Sources/GroqAccess/GroqKeyModel.swift` → 3 Treffer (`:199` nach dem Entfernen und `:307` richtig, `:316` im Fehlerweg; Stand 7beaf3f).
- **Folge:** Scheitert das Lesen beim Start (z. B. Schlüsselbund kurz gesperrt), erscheint „Kein Groq-Schlüssel.“, obwohl einer existiert. Erst ein Neustart lädt neu.

### BUG-8: Prüfanfrage speichert Cookies von Groq dauerhaft
- **Schwere:** Low
- **Status:** Deferred
- **Klasse:** Netzanfrage über die geteilte Sitzung statt über eine flüchtige.
- **Suche:** `grep -rn "URLSession.shared" Packages/InnoWhisperKit/Sources` → 1 Treffer (`KeyValidator.swift:41`).
- **Folge:** Cookies von Groq bzw. Cloudflare liegen unter `~/Library/HTTPStorages/com.innosolv.InnoWhisper*`. Sie enthalten keinen Schlüssel (0 Treffer für `gsk_`, `Bearer`, `Authorization`).

## Nicht geprüft in diesem Lauf

- [!] AC-3: Ob der Link den Browser öffnet. Grund: no way to run and probe this project was recorded.
- [!] AC-9: Echtes Ablehnen des macOS-Fensters bei der Übernahme. Grund: wie oben; Timur hat erlaubt.
- [!] AC-10, EC-5 live: Speichern ohne Internet und Nachprüfen beim Wiederverbinden. Grund: wie oben; nicht im Test durch Timur.
- [!] AC-14 live: Neustart mit einem Schlüssel, den Groq mit 401 ablehnt. Grund: wie oben.
- [!] EC-8 live: echt gesperrter Schlüsselbund. Grund: wie oben.
- [!] PROJ-1 AC-11: Schließt sich das Menüleisten-Fenster beim Knopf „Schlüssel eintragen“? Grund: wie oben.
- [!] Sicherheit: Zugriffsschutz des eigenen Eintrags gegen fremde Apps (würde ein Passwortfenster auslösen), Mitschnitt einer echten Anfrage.

## Weitere Hinweise (keine Fehler dieses Features)

- **Für PROJ-14:**
  - Die Release-Konfiguration ist ad hoc signiert (`CODE_SIGN_IDENTITY = "-"` in `project.pbxproj`, um Zeile 235). Dann passt der Zugriffsschutz des Schlüssels nach jedem Update nicht mehr, und macOS fragt jedes Mal nach dem Passwort.
  - Der Debug-Bau trägt `get-task-allow=true`. ADR-007 sollte deshalb mit Blick auf den Schlüssel im Speicher neu bewertet werden.
- **Hilfetext:** Auf Timurs Mac ist der Zwischenablage-Manager „Paste“ installiert. Er merkt sich den Schlüssel, wenn man ihn auf der Groq-Seite kopiert. Das liegt außerhalb der App; ein Satz im Hilfetext wäre denkbar.
- **Protokoll-Rauschen aus PROJ-1:** Siehe `design.md` → Bau-Notizen (`LegacyAppGuard`).

## Neue Tests (Schritt 6)

- `Tests/GroqAccessTests/KeyTextsQATests.swift` mit 4 Tests. Sie legen den Wortlaut fest, den bisher kein Test sicherte: die vier Stand-Texte (AC-11), die Ergebnistexte (AC-4, AC-9, EC-8), nur „funktioniert“ zählt als Erfolg, den Übernahme-Hinweis (AC-7) und die Rückfrage (AC-13).
- Rot-Probe gemacht: Vier Erwartungen auf einmal verändert, alle 4 Tests schlugen mit der erwarteten Abweichung fehl. Danach zurückgesetzt, 4/4 bestanden (`swift test --filter KeyTextsQATests`).

## E2E-Tests

Nicht ausgeführt (für native Menüleisten-Apps gibt es hier keinen Browser-Ablauf).

## Ergebnis

**NICHT BEREIT.** Es gibt keinen Fehler der Stufe Critical oder High. Timur hat am 06.11. entschieden: BUG-1 und BUG-2 (Medium) werden jetzt behoben (Open). BUG-3 bis BUG-8 (Low) kommen später gesammelt (Deferred). Status bleibt In Review. Nach der Korrektur prüft `/qa` in der Breite der Änderung nach; die offenen Live-Fälle aus „Nicht geprüft“ testet Timur dann mit.
