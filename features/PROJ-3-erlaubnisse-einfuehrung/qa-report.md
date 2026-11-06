# QA-Ergebnisse PROJ-3: Erlaubnisse & Einführung

## Nachtrag 2026-11-06: Nachprüfung BUG-8 und BUG-11

**Umfang:** `git diff --stat 8aafe27..HEAD` (8aafe27 = Commit des Berichts vom 05.11., HEAD = 5f19542). Geänderte Produktionsdateien:
- `Packages/InnoWhisperKit/Sources/Permissions/PermissionChecking.swift`
- `Packages/InnoWhisperKit/Sources/Permissions/PermissionMonitor.swift`
Timur hat die beiden zurückgestellten Fehler mittlerer Schwere zum sofortigen Beheben freigegeben („Jetzt beheben“, 05.11.). Ein unabhängiger `qa-engineer`-Prüfer mit allen drei Bereichen; Testlauf 124/124 bestanden, Lint Exit 0, Bau ohne Signatur erfolgreich. Geprüfter Bau: Debug vom 06.11. 08:47:24, entspricht HEAD (`strings` findet „gave no answer, own reading counts“).

- [x] **BUG-11 behoben:** Ohne Antwort gilt wieder die eigene Lesung (`PermissionChecking.swift:85-94`, Test `noOutsideAnswerFallsBackToOwnReading`, Rot-Probe gemacht); Fehlerwege mit einer wörtlichen Codekopie durchgespielt (hängt 5 s → keine Antwort nach 2,13 s, Exit 1 → keine Antwort, Programm fehlt → keine Antwort, 50 parallele Prüfungen → je genau eine Antwort). Prüfung ohne Anlass alle 30 s aufgezeichnet: 17 Prüfungen zwischen 08:48:14 und 08:57:02, Abstand 30,3 bis 32,7 s. Rest siehe BUG-14.
- [x] **BUG-8 behoben für die Prozessstarts:** 20 Mitteilungen in 1 s ergaben genau 2 Prüfprozesse (tccd: PID 15433 um 08:47:41,642, PID 15690 um 08:47:43,773); `Task.detached` 0 Treffer, kein blockierter Thread mehr; Protokoll nur bei Änderung (3 Zeilen bei 23 Prüfungen). Test `burstOfListChangesRunsOneCheckSequence`, Rot-Probe gemacht. Rest siehe BUG-15, BUG-16.
- [x] **AC-15** Schaltertest durch Timur, 06.11.: aus bei macOS 08:54:10,966, erkannt 08:54:11,552 (0,59 s); Warndreieck gesehen.
- [x] **AC-16** ein bei macOS 08:54:20,657, erkannt 08:54:21,238 (0,58 s); Warndreieck verschwand.
- [x] **AC-19, AC-20** Start liest richtig (08:47:26,516 „accessibility granted“); neue Protokollzeilen nur mit Aufzählungswert oder festem Text.
- [x] **Sicherheit:** keine Geheimnisse (`git log -p 8aafe27..HEAD` 0 Treffer); feste Argumentliste ohne Shell; nur Exit 0 mit genau „granted“/„denied“ wird angenommen; Fortsetzung genau einmal unter Sperre; keine abgeschwächten Tests.
- [x] **Regression:** 124/124 inkl. aller Suites von PROJ-1 und PROJ-2; 23 Prüfprozesse ohne Zeile „Second instance“ oder „error“; Erkennung der alten App unverändert (08:55:08,863 erkannt, Timur wählte „beenden“).
- [!] Fehlerweg am laufenden Programm, AC-8/AC-10 mit diesem Bau bei offener Einführung, EC-2 live, EC-3 echter Neustart, Mitteilungsflut live durch den Prüfer — no way to run and probe this project was recorded (die Flut hat der Bauende gemessen, siehe `design.md` → Bau-Notizen)
- Hinweis: Jede Prüfung außerhalb erzeugt in tccd eine Zeile der Stufe „Fehler“ (fehlende Apple-interne Berechtigung), bei 30-s-Takt etwa 2.800 am Tag. Kein Fehler im Produkt, gehört zu BUG-10.

Alles Übrige unten gilt unverändert seit dem 05.11.

---


**Geprüft:** 2026-11-05 (zweite Nachprüfung, nach der Korrektur von BUG-7 und dem Rest von BUG-1)
**App-Adresse:** nicht hier lauffähig (`probe.kind: none`, native Menüleisten-App). Laufzeitkriterien gelten nur dort als belegt, wo ein Test durch Timur aufgezeichnet ist: Protokollzeilen der App neben Zeitstempeln von macOS (tccd), dazu Timurs Sichtprüfung.
**Prüfer:** QA Engineer (KI). Ein unabhängiger `qa-engineer`-Prüfer mit allen drei Bereichen (Abnahme, Sicherheit, Regression) ohne Kenntnis des Baus; zusammengeführt vom Owner, dazu Tests durch Timur mit dem fertigen Bau.
**Umfang:** Nachprüfung in der Breite der Korrektur. Grundlage `git diff --stat d573a64..HEAD` (d573a64 = Commit des vorigen Berichts, HEAD = fcd5b6c). Geänderte Produktionsdateien:
- `App/InnoWhisperApp.swift`
- `Packages/InnoWhisperKit/Sources/Permissions/PermissionChecking.swift`
- `Packages/InnoWhisperKit/Sources/Permissions/PermissionMonitor.swift`
**Testlauf:** `swift test --package-path Packages/InnoWhisperKit` einmal durch den Prüfer: 121 Tests in 18 Suites bestanden, 0 Fehlschläge. Lint Exit 0. Bau ohne Signatur: BUILD SUCCEEDED, keine Compiler-Warnung.
**Geprüfter Bau:** Debug-Bau vom 05.11. 17:31:34, entspricht fcd5b6c (Quelldateien zuletzt 17:31:30, `git status` sauber, `strings` findet `--check-accessibility`). Prozesse 85970 (Start 17:32:04) und 94552 (Start 17:44:30) sowie der Neustart 17:52:29.

> Legende: `[x]` in diesem Lauf belegt (mit Nachweis) · `[ ] BUG` als fehlerhaft belegt · `[!] NOT VERIFIED` nicht prüfbar (mit Grund) · „übernommen“ = unverändert seit dem vorigen Bericht (05.11.), in diesem Lauf nicht neu geprüft, weil der Diff die Dateien nicht berührt. „Timur, 05.11.“ = Test durch Timur auf seinem Mac (macOS 26.5.1, dunkles und helles Erscheinungsbild).

## Abnahmekriterien

### Ablauf der Einführung
- [x] **AC-1** Neuer Einstieg ruft zuerst die Prüfung, dann die App (`App/InnoWhisperApp.swift:8-14`); Starts 17:32:04 und 17:44:30 mit „Launch checks passed“ und „Onboarding window shown, page 1 of 4, closable false“
- AC-2, AC-3, AC-4, AC-5, AC-6 — übernommen (Diff berührt Einführung und Texte nicht)
- [x] **AC-7** Sperre nicht im Diff; „Weiter“ wurde nach der Erlaubnis frei: „Onboarding step completed: microphone“ 17:39:48,671, „accessibility“ 17:40:52,376 (Timur, 05.11.)

### Erlaubnisse in der Einführung
- [x] **AC-8** Mikrofon: Anfrage 17:39:39,866, macOS speichert 17:39:45,406, App erkennt 17:39:45,405 (Grenze 2 s ab Antwort); Anfrage und Lesung über dieselbe Schnittstelle (`PermissionChecking.swift:40,137`); grünes Häkchen gesehen, Timur, 05.11.
- [x] **AC-9** Eintrag in die Liste über den Dock-Aufruf (`PermissionChecking.swift:144-148`), „System Settings opened at accessibility“ 17:40:23,559; InnoWhisper stand in der Liste, Timur, 05.11.
- [x] **AC-10** Bedienungshilfen in der Einführung: macOS 17:40:36,774, App 17:40:36,772; Häkchen blieb beim Wechsel zwischen den Fenstern stabil (keine weitere Zeile „Permission changed“ bis 17:42:41), Timur, 05.11.
- [x] **AC-11** „Nicht erlauben“ geklickt: 17:52:12,252 Anfrage, 17:52:14,031 „microphone notDetermined -> denied“; Hinweis und Knopf „In den Systemeinstellungen erlauben“ gesehen, Knopf öffnet die Seite Mikrofon (17:52:42,056), Einschalten erkannt 17:52:47,525; Timur, 05.11.

### Fenster, Beenden, Einstellungen
- [x] **AC-12** Esc und ⌘W ohne Wirkung, Timur, 05.11. (Durchgang ab 17:32)
- [x] **AC-13** ⌘Q mitten in der Einführung im Schritt Mikrofon, Neustart 17:52:29 „Onboarding window shown, page 2 of 4“, Fortsetzen am Mikrofon-Schritt; Timur, 05.11.
- AC-14 — übernommen
  - [!] mit dem neuen Einstieg nicht gezielt getestet; Code-Pfad in `AppDelegate.swift` unverändert, Prüfkind endet vor `applicationDidFinishLaunching` (14 Kind-Starts, 0 Zeilen „Second instance detected“)

### Später entzogene Erlaubnis
- [x] **AC-15** Einführung fertig 17:40:57; drei Entzüge im Hintergrund, erkannt 0,57 s / 0,55 s / 0,57 s nach macOS (17:42:40,644 → 17:42:41,212; 17:42:59,922 → 17:43:00,471; 17:43:08,368 → 17:43:08,941); keine erneute Einführung; Warndreieck gesehen, Timur, 05.11. Einschränkung siehe BUG-11.
- [x] **AC-16** drei Wiedererteilungen erkannt 0,58 s / 0,54 s / 0,56 s (17:42:54,059 → 54,634; 17:43:04,844 → 05,388; 17:43:11,357 → 11,919); Warndreieck verschwand, Timur, 05.11.; Tests `problemDisappearsWhenPermissionComesBack`, `listChangeTriggersAFreshAccessibilityCheck`
- [x] **AC-17** Stände aus `state(of:)`, Ansicht nicht im Diff; Darstellung übernommen

### Wachsende Einführung, Protokoll, Bedienbarkeit
- AC-18, AC-21 — übernommen
- [x] **AC-19** Start ohne Prüfung außerhalb liest richtig (17:44:30,761 „accessibility granted“ passt zur letzten Erteilung 17:43:11)
- [x] **AC-20** Zeilen „Permission changed“ wie oben; neue Zeile „Accessibility checked outside the app: <Stand>, took <Dauer>“ nur mit Aufzählungswert und Dauer (`PermissionChecking.swift:77,79`)
- [x] **AC-22** Dunkel: Bildschirmfotos von Timur (Einführung Schritt 3), Hell: Sichtprüfung Timur, 05.11. 17:54 („alles klappt“)

## Grenzfälle
- [x] **EC-1** Start 17:31:45 beide „granted“; Test `alreadyGrantedStepsAreShownOnFirstStart`
- [x] **EC-2** Test `revokedEarlierPermissionJumpsBack` (Logik)
  - [!] live — no way to run and probe this project was recorded
- [x] **EC-3** Test `restartIsOfferedTenSecondsAfterReturningWithoutGrant`; Neustart-Weg nicht im Diff
  - [!] echter Neustart — no way to run and probe this project was recorded
- EC-4, EC-5 — übernommen

## Sicherheitsprüfung

Angewendet nach `docs/kit/guides/security.md`: SEC-01, SEC-02, SEC-08 (SEC-03 bis SEC-07 entfallen: kein Konto, kein HTTP, keine KI).

- [x] Keine Geheimnisse in git (SEC-01): `git log -p d573a64..HEAD | grep -nE "gsk_|sk-[A-Za-z0-9]{10}|api_key|PRIVATE KEY|ghp_|github_pat_|AKIA|password *=|secret *=|token *="` — 0 Treffer; `strings` über den Bau — 0 Treffer
- [x] Protokoll ohne Inhalte: neue Zeilen nur mit Stand und Dauer; Prüfkinder schreiben nichts (14 Kind-Starts ohne „App started“)
- [x] Startargument (SEC-02): `--check-accessibility` liest nur, gibt „granted“/„denied“ aus und beendet sich vor der App (`PermissionChecking.swift:107-111`)
- [x] Auswertung der Antwort: exakter Vergleich, sonst keine Antwort; stderr nach `/dev/null`; Zeitgrenze 2 s mit `terminate()` (`:91-102`); gemessen 43 bis 73 ms
- [x] Keine abgeschwächten Prüfungen (SEC-08): keine entfernte Testzeile, keine abgeschalteten Tests, `.swift-format`, Package.swift, Projekt, Info.plist und Entitlements unverändert
- [ ] BUG-8 (verschärft, Medium): Prüfung von außen beliebig oft auslösbar, jetzt mit zwei Prozessstarts je Mitteilung
- [ ] BUG-13 (Low): Prüfkind wird ohne Signaturprüfung gestartet
- [!] Release-Bau und Entitlements — nicht gebaut, braucht den Schlüsselbund

## Regression (PROJ-1, PROJ-2)
- [x] Testlauf 121/121, darunter alle Suites von PROJ-1 (SingleInstanceAndQuit, LoginItemController, LegacyAppGuard, State, SettingsRegistry) und PROJ-2 (Log, LogFile, LogMessage, Notice*)
- [x] Start über den neuen Einstieg: „Launch checks passed“ und „Login item status: enabled“ bei allen Starts; nur eine Instanz (0 Zeilen „Second instance detected“ bei 14 Kind-Starts)
- [x] Prüfung auf die alte App unbeeinflusst (keine Meldung während der Kind-Starts)
- [!] Laufzeit von Menüleiste, Einstellungsfenster, Hinweisen und Tönen — no way to run and probe this project was recorded; kein Feature „Deployed“

## QA-Tests (Schritt 6)
- Keine neuen Tests in diesem Lauf. Die neuen Tests aus dem Bau (`accessibilityFollowsTheDocksAnswer`, `listChangeTriggersAFreshAccessibilityCheck`) sind mit Rot-Probe angelegt. Ungetestet bleibt der echte Prozessstart samt Fehlerweg (siehe BUG-11); er ist nur am laufenden Programm prüfbar.

## E2E-Tests
- Status: **nicht gelaufen** (`/e2e-tests` für kritische Abläufe; für diese native App gibt es noch keinen E2E-Stack)

## Nicht geprüft in diesem Lauf
- [!] AC-14 mit dem neuen Einstieg, EC-2 live, EC-3 echter Neustart, EC-5 zweiter Bildschirm, AC-21 Tastatur/VoiceOver — no way to run and probe this project was recorded
- [!] Fehlerweg der Prüfung außerhalb (Zeitüberschreitung, Start scheitert) am laufenden Programm — siehe BUG-11
- [!] Flut von Mitteilungen (BUG-8), ausgetauschtes Programm (BUG-13), Fehlercodes des Docks beim Neustart des Docks (BUG-12) — nicht ausgeführt
- [!] Mikrofon „eingeschränkt“ an einem von der IT verwalteten Mac — kein solcher Mac verfügbar
- [!] Release-Bau — braucht den Schlüsselbund

## Gefundene Fehler

### BUG-1: Entzogene Erlaubnis wird im Hintergrund nicht bemerkt
- **Schweregrad:** High
- **Status:** Fixed (in diesem Lauf bestätigt)
- **Fehlerart (Class):** Regelmäßige Arbeit im Hintergrund ohne Schutz gegen App Nap; Erlaubnis-Abfragen, die macOS im laufenden Prozess veraltet hält
- **Kriterium:** AC-15, AC-16
- **Sweep:** `grep -rn "beginActivity\|NSAppSleepDisabled\|NSProcessInfo.*activity" App Packages` — 1 Treffer (`PermissionMonitor.swift:78`); `grep -rn "kAXFocusedApplicationAttribute" Packages/InnoWhisperKit/Sources App` — 0 Treffer
- **Beleg:** Mikrofon im Hintergrund 1,03 s / 1,99 s (Bericht vom Nachmittag), Bedienungshilfen 6 von 6 Wechseln in 0,54 bis 0,58 s (siehe AC-15, AC-16). Restrisiko im Fehlerweg siehe BUG-11.

### BUG-2: Falscher Hinweis bei gesperrtem Mikrofon
- **Schweregrad:** Low
- **Status:** Deferred
- **Fehlerart:** Text und Knopf fassen Zustände mit unterschiedlicher Ursache zusammen
- **Kriterium:** AC-11 (Randfall „eingeschränkt“)
- **Sweep:** `grep -n "return \"In den Systemeinstellungen erlauben\"" Packages/InnoWhisperKit/Sources/Permissions/PermissionSteps.swift` — 1 Treffer
- **Stand:** Text behoben; der Knopf heißt bei „eingeschränkt“ weiter „In den Systemeinstellungen erlauben“. Vom Diff nicht berührt.

### BUG-3: Abweichungen vom Design-System
- **Schweregrad:** Low
- **Status:** Deferred
- **Fehlerart:** Gestaltungsvorgaben aus `docs/design-system.md` in neuen Ansichten nicht übernommen
- **Kriterium:** AC-22
- **Sweep:** `grep -rn "buttonStyle(" Packages/InnoWhisperKit/Sources/Onboarding Packages/InnoWhisperKit/Sources/Permissions` — 6 Treffer
- **Stand:** Symbole behoben; gemischte Knopfstile (`.bordered` neben Glas) offen, Entscheidung bei Timur. Vom Diff nicht berührt.

### BUG-4: „Jetzt erlauben“ doppelt im Bereich „Zugang & Erlaubnisse“
- **Schweregrad:** Low
- **Status:** Deferred
- **Fehlerart:** Gleiche Handlung an zwei Stellen derselben Fläche
- **Kriterium:** AC-16, AC-17
- **Sweep:** `grep -rn "Jetzt erlauben" Packages/InnoWhisperKit/Sources` — 3 Treffer
- **Stand:** AC-16 und AC-17 verlangen beide den Knopf; Änderung braucht `/refine PROJ-3`. Vom Diff nicht berührt.

### BUG-5: PROJ-1 AC-16 ohne Ausnahme-Vermerk
- **Schweregrad:** Low
- **Status:** Fixed (bestätigt im vorigen Lauf)

### BUG-6: SEC-08-Eintrag zur Debug-Ausnahme unvollständig
- **Schweregrad:** Low
- **Status:** Fixed (bestätigt im vorigen Lauf)

### BUG-7: Mikrofon in der Einführung erlaubt, App erkennt es nicht
- **Schweregrad:** High
- **Status:** Fixed (in diesem Lauf bestätigt)
- **Fehlerart (Class):** Erlaubnis über eine Schnittstelle angefragt und über eine andere gelesen
- **Kriterium:** AC-8
- **Sweep:** `grep -rn "requestAccess(for: .audio)\|requestRecordPermission" Packages/InnoWhisperKit/Sources App` — 1 Treffer (`PermissionChecking.swift:137`, `AVAudioApplication`)
- **Beleg:** siehe AC-8 (0 s nach macOS) und AC-11 (Ablehnen und späteres Einschalten erkannt)

### BUG-8: Prüfung von außen beliebig oft auslösbar
- **Schweregrad:** Medium (vorher Low; durch den Diff verschärft)
- **Status:** Fixed (bestätigt 06.11., siehe Nachtrag oben; Rest in BUG-15 und BUG-16)
- **Fehlerart (Class):** Von außen auslösbare Arbeit ohne Bündelung oder Drosselung am Eingang (SEC-02)
- **Sweep:** `grep -rn "suspensionBehavior: .deliverImmediately" App Packages` — 1 Treffer (`PermissionMonitor.swift:211`); `grep -rn "Task.detached" App Packages/InnoWhisperKit/Sources` — 1 Treffer (`PermissionChecking.swift:73`)
- **Nachstellen (nicht ausgeführt):** Jeder Prozess der Sitzung kann `com.apple.accessibility.api` senden; jede Zustellung startet jetzt zwei Kopien von InnoWhisper (nach 0,5 s und 2 s), jede hält bis zu 2 s einen Thread und schreibt eine Protokollzeile. Folge: Rechenlast und Protokoll-Verdrängung, kein falscher Stand, kein Datenabfluss.

### BUG-9: Vermerk zur verzögerten Prüfung auf die alte App enger als das Verhalten
- **Schweregrad:** Low
- **Status:** Deferred
- **Fehlerart (Class):** Vermerk an einem freigegebenen Nachbar-Feature fasst den Geltungsbereich enger als der Code
- **Sweep:** `grep -n "Beim ersten Start, solange" features/PROJ-1-app-rahmen-einstellungen/spec.md` — 1 Treffer
- **Stand:** vom Diff nicht berührt

### BUG-10: App Nap für den ganzen Prozess dauerhaft aus
- **Schweregrad:** Low
- **Status:** Deferred
- **Fehlerart (Class):** Energiespar-Ausnahme ohne Ende und für mehr als die nötige Arbeit
- **Sweep:** `grep -rn "endActivity" Packages/InnoWhisperKit/Sources App` — 0 Treffer

### BUG-11: Nach der ersten Prüfung außerhalb liest die App die Bedienungshilfen nicht mehr selbst
- **Schweregrad:** Medium
- **Status:** Fixed (bestätigt 06.11., siehe Nachtrag oben; Rest in BUG-14)
- **Fehlerart (Class):** Zwischengespeicherte Antwort einer Hilfsprüfung ohne Verfall verdrängt die laufende Abfrage; der Rückfallweg ist tot
- **Kriterium:** AC-15, AC-16 (Fehlerweg); widerspricht `design.md` → Bau-Notizen („Ohne Antwort binnen 2 s bleibt die eigene Lesung“)
- **Sweep:** `grep -rnE "private var [A-Za-z]+: PermissionState\?" Packages/InnoWhisperKit/Sources` — 1 Treffer (`PermissionChecking.swift:30`)
- **Nachstellen (nicht ausgeführt, probe none):** Bedienungshilfen einmal umschalten (Antwort wird gespeichert). Danach scheitert die Prüfung außerhalb (Zeitüberschreitung bei voller Last oder Programmdatei nicht startbar), und die Erlaubnis wird entzogen: Die App bleibt bei „erlaubt“ bis zum nächsten Wechsel oder Neustart. Ebenso, falls die Mitteilung einmal ausbleibt: Die 3-s-Abfrage liest nur noch den gespeicherten Wert.

### BUG-12: Unbekannte Antworten des Docks gelten als „erlaubt“
- **Schweregrad:** Low
- **Status:** Deferred (Vorschlag)
- **Fehlerart (Class):** Unbekannte Fehlercodes werden auf „erlaubt“ abgebildet (fail-open)
- **Sweep:** `grep -n "default: return .granted" Packages/InnoWhisperKit/Sources/Permissions/PermissionChecking.swift` — 1 Treffer
- **Nachstellen (nicht ausgeführt):** Ein anderer Fehlercode als „API disabled“ oder „cannot complete“ (z. B. während das Dock neu startet) ergibt „erlaubt“, auch wenn `AXIsProcessTrusted()` „nein“ sagt (`PermissionChecking.swift:116-121`).

### BUG-13: Prüfkind wird ohne Signaturprüfung gestartet
- **Schweregrad:** Low
- **Status:** Deferred (Vorschlag)
- **Fehlerart (Class):** Hilfsprozess wird ohne Prüfung der Identität aus einem veränderbaren Pfad gestartet
- **Sweep:** `grep -rnE "Process\(\)|posix_spawn|NSTask|executableURL" App Packages/InnoWhisperKit/Sources` — 5 Treffer in 2 Dateien (`AppRelauncher.swift` startet über `open`, anderer Fall)
- **Nachstellen (nicht ausgeführt):** `runCheck` startet, was unter `Bundle.main.executableURL` liegt; tccd führt das Kind unter der Verantwortung der laufenden App (aufgezeichnet 17:42:41,185). Ob ein ausgetauschtes Programm die Erlaubnisse erbt, ist nicht belegt. Voraussetzung: Schreibzugriff auf das App-Bundle bei laufender App; unter `/Applications` schützt „App-Verwaltung“.

### BUG-14: Ohne Mitteilung wird eine Änderung erst nach bis zu 33 s erkannt
- **Schweregrad:** Low
- **Status:** Deferred
- **Fehlerart (Class):** Die gespeicherte Antwort einer Hilfsprüfung verdrängt die eigene Lesung bis zur nächsten Hilfsprüfung, statt dass eine abweichende eigene Lesung eine Prüfung auslöst
- **Kriterium:** AC-15, AC-16 (nur wenn macOS die Mitteilung nicht schickt; in 8 von 8 aufgezeichneten Wechseln kam sie)
- **Sweep:** `grep -rn "checkedOutside ?? " Packages/InnoWhisperKit/Sources` — 1 Treffer
- **Nachstellen (nicht ausgeführt):** Wechsel ohne Mitteilung → erst die nächste 30-s-Prüfung erkennt ihn (aufgezeichnete Abstände bis 32,7 s).

### BUG-15: Jede Mitteilung löst sofort eine volle Abfrage im Haupt-Thread aus
- **Schweregrad:** Low
- **Status:** Deferred
- **Fehlerart (Class):** Von außen auslösbare Arbeit ohne Bündelung am Eingang (SEC-02), Rest von BUG-8
- **Sweep:** `grep -rn -A1 "func accessibilityListChanged()" Packages/InnoWhisperKit/Sources | grep -c "refresh()"` — 1
- **Nachstellen (nicht ausgeführt):** Flut von Mitteilungen → je Mitteilung eine Mikrofon-Abfrage und, ohne gespeicherte Antwort, ein Dock-Aufruf mit bis zu 0,5 s Wartezeit im Haupt-Thread. Kein falscher Stand.

### BUG-16: Dauernde Mitteilungsfolge verhindert die Prüfung nach einer Änderung
- **Schweregrad:** Low
- **Status:** Deferred
- **Fehlerart (Class):** Bündelung ohne Höchstwartezeit
- **Sweep:** `grep -rn "listChangeTask?.cancel()" Packages/InnoWhisperKit/Sources` — 1 Treffer
- **Nachstellen (aus dem Code, nicht ausgeführt):** Mitteilungen dauerhaft im Abstand unter 0,5 s → die Folge wird immer wieder ersetzt; dann greift nur die 30-s-Prüfung.

## Zusammenfassung
- **Abnahmekriterien:** 22/22 belegt oder übernommen; im Diff belegt AC-1, AC-7 bis AC-13, AC-15 bis AC-17, AC-19, AC-20, AC-22, davon live durch Timur AC-7, AC-8, AC-9, AC-10, AC-11, AC-12, AC-13, AC-15, AC-16, AC-22
- **Grenzfälle:** 5/5 belegt oder übernommen; EC-2 und EC-3 live nicht geprüft
- **Fehler:** 16 (0 kritisch, 2 hoch, 2 mittel, 12 niedrig) — Fixed: BUG-1, BUG-5, BUG-6, BUG-7, BUG-8, BUG-11; Deferred: BUG-2, BUG-3, BUG-4, BUG-9, BUG-10, BUG-12, BUG-13, BUG-14, BUG-15, BUG-16; Open: keiner (Stand 06.11.)
- **Sicherheit:** 5 Prüfungen belegt, 1 NOT VERIFIED (Release-Bau), 2 Funde (BUG-8, BUG-13)
- **Produktionsreif:** JA — keine offenen kritischen oder hohen Fehler; die nicht geprüften Punkte stehen oben unter „Nicht geprüft in diesem Lauf“
- **Empfehlung:** Die zurückgestellten Fehler (alle niedrig) später gesammelt mit `/build PROJ-3 deferred` beheben
