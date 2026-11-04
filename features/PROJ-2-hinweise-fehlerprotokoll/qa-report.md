# QA-Ergebnisse PROJ-2: Hinweise & Fehlerprotokoll

**Geprüft:** 2026-11-04
**App-Adresse:** nicht hier lauffähig (`probe.kind: none`, native Menüleisten-App). Laufzeitkriterien sind `[!] NOT VERIFIED`, bis ein Test durch Timur aufgezeichnet ist.
**Prüfer:** QA Engineer (KI), drei unabhängige `qa-engineer`-Prüfer (Abnahme, Sicherheit, Regression) ohne Kenntnis des Baus; zusammengeführt vom Owner.
**Umfang:** vollständig (erster Lauf)
**Testlauf:** `swift test --package-path Packages/InnoWhisperKit` einmal vor der Aufteilung: 68 Tests in 12 Suites bestanden.

> Legende: `[x]` in diesem Lauf belegt (mit Nachweis) · `[ ] BUG` als fehlerhaft belegt · `[!] NOT VERIFIED` nicht prüfbar (mit Grund). „Logik“ = durch Test oder Quelltext belegt, nicht am laufenden Programm beobachtet.

## Abnahmekriterien

### Hinweise
- [x] **AC-1** Logik: unter gemeldeter Stelle (8 pt), sonst darüber, am Rand gehalten; ohne Stelle oben mittig (12 pt) auf dem Bildschirm mit dem Mauszeiger — `Sources/Notices/NoticePlacement.swift:18-30`; Glas `NoticeView.swift:52`; Tests `belowAnchor`, `aboveWhenNoRoomBelow`, `clampedAtScreenEdge`, `topCentreOnMouseScreen`
- [x] **AC-2** Logik: eigenes SF-Symbol je Art, Text auf 120 Zeichen gekürzt — `Notice.swift:10-16, 42-43`; Tests `showsKindAndText`, `longTextIsShortened`
- [x] **AC-3** Logik: Info/Erfolg nach 2 s weg — `Notices.swift:4`, `NoticeCenter.swift:28-35`; Test `closesAfterTwoSeconds`; Gegenprobe mit echter Uhr (2,5 s da, 3,3 s weg)
- [x] **AC-4** Logik für Klick und neue Aufnahme — `NoticePanel.swift:48-50`, `AppEnvironment.swift:62-69`, `NoticeCenter.swift:46-55`; Tests `errorStaysUntilDismissed`, `dictationStartKeepsNonErrors`
  - [!] Esc aus anderen Programmen — braucht die Erlaubnis „Bedienungshilfen“ (PROJ-3); Klick auf die Kapsel zur Laufzeit — no way to run and probe this project was recorded; kein Feature erzeugt bisher einen Fehler-Hinweis
- [x] **AC-5** Garantie im Code: alter Zeitgeber wird abgebrochen und schließt nur seine eigene Kennung — `NoticeCenter.swift:24, 31-40`; Test `replacedTimerDoesNotCloseNewNotice`; Gegenproben mit echter Zeit und veralteter Kennung
- [x] **AC-6** Logik: Fenster kann nie aktiv werden — `NoticePanel.swift:7-10, 63, 95`
  - [!] Weitertippen während eines Hinweises — no way to run and probe this project was recorded
- [x] **AC-7** Logik: VoiceOver-Ansage, ohne Animation, feste Fläche — `NoticePanel.swift:62-69, 78-79, 115-123`, `NoticeView.swift:23-28, 45-53`
  - [!] tatsächliche Ausgabe und Darstellung — no way to run and probe this project was recorded
- [x] **AC-8** Logik: Erfolgs-Hinweis statt OK-Fenster — `App/AppEnvironment.swift:38`, Aufruf nur bei Erfolg `LegacyAppGuard.swift:127-131, 141-145`; OK-Fenster aus `App/LegacyAlerts.swift` entfernt

### Töne
- [x] **AC-9** Logik: Tink/Pop, 0,4, kein Fehlerton — `SoundPlayer.swift:6-8, 46, 63-72`; Dateien in `/System/Library/Sounds` vorhanden; Test `playsStartAndEnd`
  - [!] hörbar am Programm — noch kein Aufrufer (Aufnahme kommt mit PROJ-5)
- [x] **AC-10** Logik: Standard an, gespeichert, aus = still — `SoundPlayer.swift:54, 60, 67`, Gruppe `AppEnvironment.swift:49-50`; Test `switchIsOnByDefaultAndPersists`

### Fehlerprotokoll
- [x] **AC-11** Logik: Zeile mit Zeitpunkt (Ortszeit) und Bereich, Datei und Apples Protokoll — `LogFile.swift:129-140`, `Log.swift:19-28`; Tests `writesOneLinePerEntry`, `writesIntoConfiguredFile`; echte Datei `~/Library/Logs/InnoWhisper/InnoWhisper.log` (14 Zeilen, früherer Lauf) gelesen
  - [!] Einträge zu Erlaubnissen, Tastenkürzeln, Aufnahme — Features PROJ-3/4/5 fehlen noch
- [ ] **AC-12** BUG (BUG-1): Der Übersetzer lehnt freien Text in der gewöhnlichen Form ab (Test `compilerRejectsFreeText`), heute protokolliert kein Aufruf Inhalte (alle 13 Aufrufe geprüft, echte Datei sauber). Es gibt aber drei Wege, auf denen ein späteres Feature doch freien Text protokollieren könnte.
- [ ] **AC-13** BUG (BUG-2): Einträge älter als 7 Tage werden nur beim Start entfernt, nicht beim Schreiben. Kürzen nach Größe und beim Start belegt (Tests `dropsEntriesOlderThanSevenDays`, `trimsBySize`).
- [x] **AC-14** Logik: Knopf legt Datei an und markiert sie im Finder — `LogSettingsGroup.swift:16-27`, Gruppe `AppEnvironment.swift:51-52`
  - [!] Finder-Öffnung in diesem Lauf — no way to run and probe this project was recorded

## Sonderfälle
- [ ] **EC-1** BUG (BUG-4): Bildschirm des aktiven Eingabefelds wird nicht berücksichtigt, nur der Mauszeiger. Mauszeiger-Teil belegt (Test `topCentreOnMouseScreen`).
- [x] **EC-2** Logik: Ebene `.statusBar`, alle Schreibtische, Vollbild — `NoticePanel.swift:99-105`
  - [!] sichtbar über Vollbild — no way to run and probe this project was recorded
- [x] **EC-3** Logik: Schreibfehler → „nicht verfügbar“, Knopf ausgegraut — `LogFile.swift:86, 93, 107, 123`, `LogSettingsGroup.swift:16, 23, 28`; Test `unwritableDirectoryIsUnavailable`
- [ ] **EC-4** BUG (BUG-3): Wird die Datei während des Laufs gelöscht, schaltet der nächste Eintrag das Protokoll bis zum Neustart ab; der Knopf legt dann keine neue Datei an.
- [x] **EC-5** Logik: ein Abspieler, stoppt vor jedem Klang — `SoundPlayer.swift:68`; Test `stopsPreviousSound`

## Sicherheit

Plattform `desktop`, keine Konten, kein HTTP, kein Modell. Angewandt: SEC-01, SEC-02, SEC-08, SEC-03 (lokaler Dateischutz). Entfallen: SEC-04 bis SEC-07.

- [x] Keine Geheimnisse im Programm (`strings -a` nach Schlüsselmustern → 0) und in der Git-Historie dieses Zweigs (`git log -p main..HEAD` → 0); Berechtigungen unverändert (nur `get-task-allow` in Debug, ADR-007)
- [x] Protokoll heute ohne Inhalte: alle `Log.write`-Aufrufe geprüft, alle `LogValue`-Typen sind Aufzählungen ohne Begleitwerte, kein Umweg an `Log` vorbei (`grep Logger(|os_log|NSLog|print(` → nur `Log.swift`)
- [ ] BUG (BUG-1): drei Hintertüren in der Protokoll-Meldung (SEC-01, SEC-02)
- [x] Dateirechte: Datei 0644 in `~/Library/Logs` (Ordner 0700 darüber) — andere Nutzer kommen nicht heran
- [ ] BUG (BUG-5): Protokolldatei folgt Verknüpfungen (Symlinks)
- [ ] BUG (BUG-6): nur Zeilenumbrüche werden neutralisiert, Wagenrücklauf nicht
- [x] Hinweis-Text nie im Protokoll, nur die Art — `NoticePanel.swift:71-73`
- [x] Esc-Beobachtung wertet nur Esc aus, speichert und protokolliert nichts, gibt die Taste weiter, läuft nur bei sichtbarem Fehler-Hinweis — `EscapeMonitor.swift:18-35`, `NoticePanel.swift:40, 44`
- [ ] BUG (BUG-7): Esc-Beobachtung kann sich doppelt anmelden
- [x] Töne nur aus festem Namen, keine Eingabe von außen — `SoundPlayer.swift:6-8, 29`
- [!] Anmeldung, Brute Force, Konten, HTTP, Header — nicht anwendbar (keine Konten, kein HTTP)
- [!] Fokus, Esc, Vollbild zur Laufzeit; Unterschieben eines Klangs über `~/Library/Sounds` — nicht ausgeführt

## Regression (PROJ-1)

- [x] Testlauf 68/68, alle 6 PROJ-1-Suiten grün, PROJ-1-Tests seit Freigabe unverändert (`git diff --stat 8b1b93b..HEAD -- Packages/InnoWhisperKit/Tests/AppShellTests` → leer)
- [x] Stilprüfung und Bau ohne Meldung; Debug-Bau mit Hardened Runtime, ohne Debug-Bibliothek (`codesign -dv`, `ls Contents/MacOS`)
- [x] PROJ-1-Kriterien in geänderten Dateien per Logik intakt: EC-1, AC-6, AC-7 bis AC-9, AC-13 bis AC-20, EC-2 bis EC-5 (Belege im Prüferbericht, u. a. `AppDelegate.swift:14-44`, `LegacyAlerts.swift:8-27`)
- [x] Alle 10 alten Protokollaufrufe auf `Log.write` umgestellt (`git grep` vorher 10, jetzt 0 alte)
- [x] `docs/app-shell.md` und `docs/data-model.md` passen zum Code
- [ ] BUG (BUG-12): Plan von PROJ-1 nennt noch die gelöschte Datei `AppShellLog.swift` und das alte OK-Fenster
- [!] ausgelieferte Features — keine vorhanden

## Unit-Tests

Keine zusätzlichen Unit-Tests in diesem Lauf; die gefundenen Lücken sind Fehler im Code, `/build` schreibt je Fehlerart einen zuerst roten Test.

## E2E-Tests
- Status: **nicht gelaufen** (für eine Menüleisten-App nicht vorgesehen)

## In diesem Lauf nicht geprüft
- [!] Alle Laufzeit- und Sichtprüfungen — no way to run and probe this project was recorded (`probe.kind: none`). Timur hat während `/build` (T11, 04.11.2026) bestätigt: Hinweis „Die alte Version wurde beendet.“ oben mittig, Glas, nach 2 s weg; Gruppen „Töne“ und „Fehlerprotokoll“; Knopf markiert die Datei im Finder. Das war vor diesem Prüflauf und ist hier nicht als bestanden gezählt.
- [!] Töne hörbar, Esc in fremden Programmen, Einträge zu Erlaubnissen/Tastenkürzeln/Aufnahme — Features PROJ-3/4/5 fehlen

## Gefundene Fehler

#### BUG-1: Protokoll-Meldung hat drei Wege für freien Text
- **Schwere:** Medium
- **Status:** Open (Vorschlag)
- **Fehlerart:** Die sichere Meldungsart hat freie Textkanäle: Programmkennung wird nach Form statt gegen eine Liste geprüft, Fehlerbereich wird wörtlich übernommen, `LogValue` ist offen für jeden Typ.
- **Kontrolle / AC:** SEC-01, SEC-02; AC-12
- **Sweep:** `grep -rnE 'appendInterpolation\((bundleID|error):|\\\((bundleID|error):|extension [A-Za-z.]+ *: *(@retroactive )?LogValue|String\(describing: self\)' Packages/InnoWhisperKit/Sources App --include='*.swift'` — 6 Treffer
- **Nachstellen:** `"\(bundleID: "max.mustermann")"` → „max.mustermann“ im Protokoll; `"\(error: NSError(domain: diktat, code: 7))"` → Diktat im Protokoll; `extension String: @retroactive LogValue` baut fehlerfrei. Verschärfend: Bei `"\(diktat)"` schlägt der Übersetzer selbst `bundleID:` als Korrektur vor.

#### BUG-2: 7-Tage-Grenze gilt nur beim Start
- **Schwere:** Medium
- **Status:** Open (Vorschlag)
- **Fehlerart:** Aufbewahrungsregel nur an einer von zwei verlangten Stellen angewendet (Spec: „startet oder schreibt“).
- **Kontrolle / AC:** AC-13
- **Sweep:** `grep -n "trim()" Packages/InnoWhisperKit/Sources/Diagnostics/LogFile.swift` — 3 Treffer, kein Altersauslöser beim Schreiben
- **Nachstellen:** Eintrag schreiben, Uhr 9 Tage weiter, weiteren Eintrag ohne Neustart → 9 Tage alter Eintrag bleibt. Eine App mit Autostart läuft oft länger als 7 Tage.

#### BUG-3: Gelöschte Protokolldatei schaltet das Protokoll bis zum Neustart ab
- **Schwere:** Medium
- **Status:** Open (Vorschlag)
- **Fehlerart:** Ein einzelner Schreibfehler setzt „nicht verfügbar“ dauerhaft, statt die Datei neu anzulegen.
- **Kontrolle / AC:** EC-4, EC-3
- **Sweep:** `grep -rn "available = false" Packages/InnoWhisperKit/Sources/Diagnostics` — 4 Treffer
- **Nachstellen:** Datei löschen, ein Eintrag (z. B. Einstellungen öffnen) → Knopf „nicht verfügbar“, keine weiteren Einträge bis zum Neustart.

#### BUG-4: Bildschirm des aktiven Eingabefelds wird nicht berücksichtigt
- **Schwere:** Medium
- **Status:** Deferred (Vorschlag: wird mit PROJ-8 gelöst, das das Eingabefeld erkennt)
- **Fehlerart:** Vertrag (EC-1) und Plan widersprechen sich; der Plan verschiebt den ersten Zweig auf PROJ-8.
- **Kontrolle / AC:** EC-1
- **Sweep:** none
- **Nachstellen:** Eingabefeld auf Bildschirm A, Maus auf B, Hinweis ohne Stelle → erscheint auf B.

#### BUG-5: Protokolldatei folgt Verknüpfungen
- **Schwere:** Low · **Status:** Deferred (Vorschlag)
- **Fehlerart:** Datei-Zugriff am festen Pfad ohne Schutz vor Verknüpfungen, ohne Lesegrenze.
- **Kontrolle / AC:** SEC-02, SEC-03
- **Sweep:** `grep -rnE 'FileHandle\(forWritingTo|Data\(contentsOf|\.write\(to:|createFile\(atPath' Packages/InnoWhisperKit/Sources App --include='*.swift'` — 4 Treffer
- **Nachstellen:** `InnoWhisper.log` durch Verknüpfung auf fremde Datei ersetzen → InnoWhisper schreibt in die fremde Datei bzw. kopiert deren Inhalt beim Kürzen ins Protokoll. Nur durch einen Prozess desselben Nutzers möglich.

#### BUG-6: Wagenrücklauf wird im Protokoll nicht neutralisiert
- **Schwere:** Low · **Status:** Deferred (Vorschlag)
- **Fehlerart:** Steuerzeichen-Neutralisierung unvollständig (nur Zeilenumbruch).
- **Kontrolle / AC:** SEC-02
- **Sweep:** `grep -rnF 'replacingOccurrences(of: "\n"' Packages/InnoWhisperKit/Sources App --include='*.swift'` — 2 Treffer, betroffen `LogFile.swift:135`
- **Nachstellen:** Nur über die Wege aus BUG-1 erreichbar.

#### BUG-7: Esc-Beobachtung kann sich doppelt anmelden
- **Schwere:** Low · **Status:** Deferred (Vorschlag)
- **Fehlerart:** Doppelanmeldung beim Ereignis-Beobachter (Sperre prüft nur den globalen Teil).
- **Kontrolle / AC:** AC-4
- **Sweep:** `grep -rn "addGlobalMonitorForEvents\|addLocalMonitorForEvents" Packages App --include='*.swift'` — 2 Treffer in `EscapeMonitor.swift`
- **Nachstellen:** Liefert die globale Anmeldung nichts (keine Erlaubnis), legt jeder weitere Fehler-Hinweis einen zusätzlichen lokalen Beobachter an.

#### BUG-8: Ungültige Zeichen in der Datei schalten das Kürzen ab
- **Schwere:** Low · **Status:** Deferred (Vorschlag)
- **Fehlerart:** Dekodierfehler schaltet die Aufbewahrung stillschweigend ab.
- **Kontrolle / AC:** AC-13
- **Sweep:** `grep -n "String(data:" Packages/InnoWhisperKit/Sources/Diagnostics/*.swift` — 1 Treffer
- **Nachstellen:** Datei mit ungültigem UTF-8 → wächst über 10 MB hinaus. Nur durch Fremdschreiben erreichbar.

#### BUG-9: Kürzen beim Start blockiert den Hauptablauf
- **Schwere:** Low · **Status:** Deferred (Vorschlag)
- **Fehlerart:** Synchrone Datei-Ein-/Ausgabe auf dem Hauptablauf (Plan: „nie auf dem Hauptablauf“).
- **Kontrolle / AC:** AC-13 (Plan)
- **Sweep:** `grep -n "queue.sync" Packages/InnoWhisperKit/Sources/Diagnostics/LogFile.swift` — 4 Treffer
- **Nachstellen:** 9,8-MB-Datei → Start blockiert 355 ms (Debug).

#### BUG-10: Mauszeiger in Menüleiste oder Dock eines Zweitbildschirms → Hinweis auf dem Hauptbildschirm
- **Schwere:** Low · **Status:** Deferred (Vorschlag)
- **Fehlerart:** Bildschirmwahl über den sichtbaren Bereich statt über den ganzen Bildschirm.
- **Kontrolle / AC:** EC-1
- **Sweep:** `grep -rn "visibleFrame" Packages/InnoWhisperKit/Sources/Notices` — 2 Treffer

#### BUG-11: Knopf „Fehlerprotokoll“ merkt späteren Ausfall erst beim Klick
- **Schwere:** Low · **Status:** Deferred (Vorschlag)
- **Fehlerart:** Verfügbarkeit wird einmal abgefragt statt beobachtet.
- **Kontrolle / AC:** EC-3
- **Sweep:** `grep -rn "isAvailable" App Packages/InnoWhisperKit/Sources` — 2 Treffer

#### BUG-12: Plan von PROJ-1 nennt gelöschte Datei und altes OK-Fenster
- **Schwere:** Low · **Status:** Deferred (Vorschlag)
- **Fehlerart:** Architektur-Doku eines Nachbar-Features nicht nachgeführt.
- **Kontrolle / AC:** Regression PROJ-1
- **Sweep:** `grep -rn "AppShellLog" features/*/design.md docs` — 3 Treffer, betroffen `PROJ-1…/design.md:214` (dazu `:210` OK-Fenster)

#### BUG-13: Zweites Exemplar kürzt die gemeinsame Protokolldatei
- **Schwere:** Low · **Status:** Deferred (Vorschlag)
- **Fehlerart:** Protokoll wird vor der Prüfung auf ein zweites Exemplar geöffnet.
- **Kontrolle / AC:** AC-11
- **Sweep:** none
- **Nachstellen:** Zweites Exemplar startet → kürzt beim Start, während das erste schreibt; einzelne Zeilen können verloren gehen.

### Weitere Beobachtung (kein Fehler dieses Features)
Im selben Ordner `~/Library/Logs/InnoWhisper/` liegt `debug.log` der **alten** App (3,2 MB, ohne Diktat-Text, aber mit Programmkennungen und Geräte-Kennungen). Ein Kollege könnte statt `InnoWhisper.log` diese Datei schicken. Vormerken für die Umzugsanleitung (PROJ-14).

## Zusammenfassung
- **Abnahmekriterien:** 11 von 14 per Logik belegt, AC-12 und AC-13 fehlerhaft; Sonderfälle: EC-2, EC-3, EC-5 belegt, EC-1 und EC-4 fehlerhaft. Kein Kriterium in diesem Lauf am laufenden Programm beobachtet.
- **Fehler:** 13 (0 Critical, 0 High, 4 Medium, 9 Low) — Vorschlag: Open 3 (BUG-1 bis BUG-3), Deferred 10
- **Sicherheit:** 8 Prüfungen belegt, 4 Befunde (BUG-1, BUG-5 bis BUG-7), 6 NOT VERIFIED (davon 5 nicht anwendbar)
- **Produktionsreif:** NEIN, solange BUG-1 bis BUG-3 offen sind und der aufgezeichnete Test fehlt
- **Empfehlung:** BUG-1 bis BUG-3 mit `/build PROJ-2` beheben, danach Nachprüfung mit kurzem Test durch Timur
