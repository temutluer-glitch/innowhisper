# PROJ-1 — Technischer Plan: App-Rahmen & Einstellungen

> Technischer Plan (das WIE). Zwei Leser: Timur (gibt frei) und `/build` (baut danach). Kein Code, aber genau.
> Owner: `/architecture`. Der Vertrag (WAS) steht in `spec.md`, die Aufgabenliste in `tasks.md`.

Grundlage: ADR-001 (Swift/SwiftUI, macOS 26), ADR-002 (alles lokal), ADR-007 (Hardened Runtime ohne App Sandbox), ADR-008 (Projektaufbau, Tests, Formatierung). Es gibt noch keinen Code; PROJ-1 legt das Xcode-Projekt an. Geprüft gegen das installierte SDK `MacOSX26.4.sdk` (Xcode 26.4.1, Swift 6.3.1): `glassEffect`, `GlassEffectContainer`, Knopfstile `glass` und `glassProminent` sind vorhanden.

## Komponenten

```
InnoWhisper (Menüleisten-App, kein Dock-Symbol)
+-- Menüleisten-Symbol                      AC-1, AC-2
|   +-- Zustands-Symbol (bereit / nimmt auf / wandelt um / Problem) mit VoiceOver-Text
+-- Menüleisten-Fenster (Glas)              AC-3, AC-4, AC-18, AC-21, AC-22
|   +-- Problem-Hinweise (z. B. „alte Version läuft“) mit Lösungsknopf
|   +-- Inhaltsfläche für PROJ-13 (leer in PROJ-1)
|   +-- Knopfleiste: „Einstellungen …“ (⌘,) · „InnoWhisper beenden“ (⌘Q)
+-- Einstellungsfenster (genau eins)        AC-5 bis AC-12, EC-6
|   +-- Seitenleiste: angemeldete Bereiche in fester Reihenfolge
|   +-- Inhalt: gewählter Bereich
|       +-- Problem-Hinweis-Leiste oben (falls Problem für diesen Bereich)
|       +-- Bereich „Allgemein“
|           +-- Gruppe „System“: Schalter „Start beim Anmelden“ (+ Hinweis bei EC-4)
|           +-- Platz für Gruppen späterer Features (Töne PROJ-2, Ausgabe PROJ-7)
+-- Meldungen (System-Dialoge)
    +-- „Die alte Version läuft noch …“     AC-16, AC-17, EC-2, EC-3
    +-- „Ein Diktat läuft noch …“           AC-20
```

Es gibt keine Bildschirme für unfertige Bereiche: Ein Bereich erscheint nur, wenn sein Feature ihn anmeldet (AC-8).

## Code-Aufbau

Ein Xcode-Projekt mit dünnem App-Ziel plus ein lokales Swift-Paket für Logik und Oberflächen (ADR-008). Jedes spätere Feature bekommt ein eigenes Modul im Paket; das App-Ziel setzt alles zusammen.

| Modul / Pfad | Aufgabe und Schnittstelle | Darf benutzen |
| --- | --- | --- |
| `InnoWhisper.xcodeproj` | App-Ziel „InnoWhisper“, Ordner `App/` als synchronisierter Ordner (neue Dateien brauchen keine Projektänderung) | lokales Paket `InnoWhisperKit` |
| `App/InnoWhisperApp.swift` | Einstiegspunkt und Zusammensetzung: Menüleisten-Szene, Einstellungs-Fensterszene, meldet die Bereiche der Features an | `AppShell` (später alle Feature-Module) |
| `App/AppDelegate.swift` | Hört auf System-Ereignisse: Start, erneutes Öffnen (AC-6), Beenden (AC-19, AC-20), Herunterfahren (EC-5); leitet an `AppShell` weiter | `AppShell` |
| `App/Info.plist`, `App/InnoWhisper.entitlements`, `App/Assets.xcassets` | Kennung, nur Menüleiste, Mindestversion, App-Symbol, Berechtigungen | — |
| `Packages/InnoWhisperKit/Sources/AppShell/State/` | **Zustand der App**: Diktat-Tätigkeit, Problem-Sammlung, daraus das Menüleisten-Symbol | nur Apple-Frameworks |
| `Packages/InnoWhisperKit/Sources/AppShell/Settings/` | **Einstellungsrahmen**: Bereichsliste, Anmelden von Bereichen und Allgemein-Gruppen, Seitenleiste, Fensterlogik, Bereich „Allgemein“ | `State` |
| `Packages/InnoWhisperKit/Sources/AppShell/MenuBar/` | Menüleisten-Symbol und Menüleisten-Fenster mit Platz für PROJ-13 | `State`, `Settings` |
| `Packages/InnoWhisperKit/Sources/AppShell/System/` | Anschluss an macOS: Start beim Anmelden, laufende Apps (alte Version, zweite Instanz), Beenden-Regel, Fenster-Lage; jeweils hinter einer kleinen Schnittstelle, damit Tests eine Attrappe einsetzen | `State` |
| `Packages/InnoWhisperKit/Tests/AppShellTests/` | Tests mit Swift Testing gegen Attrappen der System-Schnittstellen | `AppShell` |

Abhängigkeitsrichtung: Feature-Module dürfen `AppShell` benutzen (Zustand melden, Probleme melden, Bereich anmelden). `AppShell` kennt keine Feature-Module. Nur das App-Ziel kennt alle.

### Was andere Features vom Rahmen bekommen
- **Diktat-Tätigkeit melden**: einer von drei Werten `ruhend`, `nimmtAuf`, `wandeltUm` (PROJ-5 und PROJ-6 setzen ihn).
- **Problem melden / zurückziehen**: über eine feste Kennung; doppeltes Melden derselben Kennung ersetzt den alten Eintrag, Zurückziehen einer unbekannten Kennung tut nichts.
- **Bereich anmelden**: Bereichskennung plus Inhalt.
- **Gruppe in „Allgemein“ anmelden**: Titel, Reihenfolge, Inhalt.
- **Einstellungen öffnen**, optional direkt in einem Bereich (für Problem-Hinweise, AC-11).

## Footprint

- Code und Tests: `InnoWhisper.xcodeproj`, `App/`, `Packages/InnoWhisperKit/` (Modul `AppShell`, Tests `AppShellTests`), `.swift-format`, Ergänzungen in `.gitignore` (Bau-Ordner `build/`, `.build/`, `DerivedData/`)
- Datenbank, Tabellen, Zugriffsregeln: keine (nur lokale Einstellungen, siehe Datenmodell)
- Umgebungsvariablen: keine
- Pakete: keine fremden Pakete
- Anschlusspunkte: Menüleisten-Szene, Einstellungs-Fensterszene mit Kennung `settings`, App-Delegate (Start, erneutes Öffnen, Beenden), System-Mitteilung `com.innosolv.InnoWhisper.openSettings` (zweite Instanz an erste), macOS-Anmeldeobjekte, Liste laufender Apps

## Zustände und Regeln

### Menüleisten-Symbol (AC-2)
Das Symbol ergibt sich aus Diktat-Tätigkeit und Problem-Sammlung, mit fester Vorrangfolge:

| Vorrang | Bedingung | SF Symbol | VoiceOver-Text |
| --- | --- | --- | --- |
| 1 | Tätigkeit `nimmtAuf` | `mic.fill` | „InnoWhisper nimmt auf“ |
| 2 | Tätigkeit `wandeltUm` | `waveform` | „InnoWhisper wandelt um“ |
| 3 | mindestens ein Problem gemeldet | `exclamationmark.triangle` | „InnoWhisper: Problem, Details im Menü“ |
| 4 | sonst | `mic` | „InnoWhisper bereit“ |

Eine laufende Aufnahme verdeckt ein Problem bewusst; nach der Aufnahme erscheint das Problem-Symbol wieder. Das Symbol ist direkt an den Zustand gebunden (keine Abfrage im Takt), deshalb wechselt es sofort.

### Problem-Eintrag
- Kennung: Text, Pflicht, eindeutig (z. B. `legacyAppRunning`, `autostartUnavailable`)
- Bereich: einer der Bereiche unten oder keiner (dann nur im Menüleisten-Fenster)
- Meldungstext: Text, Pflicht, ein verständlicher Satz ohne Fehlercode
- Knopftext und Handlung: Pflicht (z. B. „Alte Version beenden“, „Einstellungen öffnen“)
- Lebensdauer: nur im Speicher, bis das meldende Feature es zurückzieht oder die App endet

### Bereiche des Einstellungsfensters (AC-7, AC-8, AC-9)
Feste Liste aller acht Bereiche mit stabiler Kennung, Reihenfolge laut `docs/app-shell.md`. Die Seitenleiste zeigt nur angemeldete.

| Reihenfolge | Kennung | Name | SF Symbol | Feature |
| --- | --- | --- | --- | --- |
| 1 | `general` | Allgemein | `gearshape` | PROJ-1 |
| 2 | `access` | Zugang & Erlaubnisse | `key` | PROJ-4, PROJ-3 |
| 3 | `hotkeys` | Tastenkürzel | `keyboard` | PROJ-5, PROJ-12 |
| 4 | `transcription` | Umwandlung | `text.bubble` | PROJ-6 |
| 5 | `prompts` | KI-Vorlagen | `sparkles` | PROJ-11 |
| 6 | `vocabulary` | Wörterbuch | `character.book.closed` | PROJ-9 |
| 7 | `history` | Verlauf | `clock.arrow.circlepath` | PROJ-10 |
| 8 | `about` | Info & Updates | `info.circle` | PROJ-14 |

Beim Öffnen wird der gespeicherte letzte Bereich gezeigt; ist er nicht (mehr) angemeldet oder fehlt er, dann „Allgemein“.

### Einstellungsfenster
- Genau ein Fenster (Fensterszene mit fester Kennung). Öffnen holt die App nach vorne und das Fenster vor alle anderen (AC-5).
- Standardgröße 760 × 520 pt, Mindestgröße 680 × 460 pt, Höchstbreite 760 pt (breiter bleibt der Formular-Inhalt sonst mittig stehen; nur die Höhe wächst weiter, wie bei den Systemeinstellungen); Größe und Lage speichert macOS über einen festen Fensternamen (AC-12).
- Liegt das Fenster beim Öffnen nicht mindestens zu 80 % auf einem angeschlossenen Bildschirm, wird es mittig auf den Hauptbildschirm gesetzt (EC-6).
- Problem-Hinweis-Leiste: zeigt alle Probleme dieses Bereichs untereinander; verschwindet von selbst, wenn sie zurückgezogen werden (AC-10).

### Start beim Anmelden (AC-13 bis AC-15, EC-4)
- Beim allerersten Start: Anmeldung als Anmeldeobjekt bei macOS versuchen, danach den Merker „Erststart erledigt“ setzen, auch wenn es scheitert. So schaltet die App einen bewusst ausgeschalteten Autostart nie wieder ein.
- Der Schalter liest immer den Stand von macOS, beim Öffnen des Bereichs und wenn die App wieder nach vorne kommt (AC-15). Es gibt keine eigene Kopie des Stands.
- macOS meldet einen von vier Ständen; die App zeigt:

| macOS-Stand | Schalter | Hinweis |
| --- | --- | --- |
| eingeschaltet | an | keiner |
| nicht angemeldet | aus | keiner |
| wartet auf Erlaubnis | aus | „macOS muss den automatischen Start noch erlauben.“ Knopf „Anmeldeobjekte öffnen“ öffnet die passende Stelle der Systemeinstellungen |
| nicht gefunden / Anmeldung scheitert | aus | Liegt die App nicht in `/Programme` oder `~/Programme`: „Verschiebe InnoWhisper in den Ordner Programme, dann klappt der automatische Start.“ Sonst: „macOS hat den automatischen Start abgelehnt. Bitte schalte ihn später erneut ein.“ |

Der Hinweis wird als Problem `autostartUnavailable` im Bereich `general` gemeldet und zurückgezogen, sobald der Stand „eingeschaltet“ ist oder der Nutzer den Schalter bewusst auf aus lässt. Das bewusste Aus wird als Absicht gespeichert und gilt für alle Stände, auch „wartet auf Erlaubnis“ und „nicht gefunden“.

### Alte App (AC-16 bis AC-18, EC-2, EC-3)
- Erkennung an der Kennung `com.innosolv.WhisperDictation` in der Liste laufender Apps: beim Start und bei jeder neu gestarteten App (EC-2); beim Beenden einer App wird erneut geprüft.
- Meldung als System-Dialog mit „Alte Version beenden“ (Hauptknopf) und „Später“.
- „Alte Version beenden“: zuerst normal beenden lassen; läuft sie nach 2 Sekunden noch, sofort beenden; läuft sie nach insgesamt 5 Sekunden noch, erscheint die Anleitung aus EC-3. Sie nennt die alte App so, wie die Aktivitätsanzeige sie zeigt („InnoWhisper“), und ihre Nummer (PID), weil die neue App denselben Namen trägt; den internen Programmnamen nennt sie nie (QA BUG-2). Erfolg: kurze Bestätigung „Die alte Version wurde beendet.“ (vorläufig als kurzer Text im Menüleisten-Fenster, später über die Hinweise aus PROJ-2).
- „Später“ oder Scheitern: Problem `legacyAppRunning` ohne Bereich, mit Knopf „Alte Version beenden“; wird zurückgezogen, sobald keine alte App mehr läuft (AC-18).
- Gibt es mehrere laufende Exemplare der alten App, gilt alles für alle.

### Nur eine InnoWhisper (EC-1, AC-6)
- Startet InnoWhisper und läuft schon ein anderes Exemplar mit derselben Kennung, schickt das neue eine System-Mitteilung „Einstellungen öffnen“ an das laufende und beendet sich sofort, ohne Symbol zu zeigen.
- Das laufende Exemplar nimmt nur genau diese Mitteilung an, ohne mitgeschickte Daten, und öffnet sein Einstellungsfenster.
- Öffnet der Nutzer die laufende App erneut (Finder, Spotlight), meldet macOS das als „erneut geöffnet“ und das Einstellungsfenster geht auf (AC-6).

### Beenden (AC-19, AC-20, EC-5)
- Beenden-Wunsch (Knopf oder ⌘Q): Tätigkeit `ruhend` → sofort beenden. Tätigkeit `nimmtAuf` oder `wandeltUm` → Dialog mit dem Text aus AC-20, Knöpfe „Abbrechen“ (Standard) und „Beenden“ (destruktiv).
- Hat macOS angekündigt, dass der Mac herunterfährt, neu startet oder der Nutzer sich abmeldet, wird ohne Dialog beendet (EC-5).

### Aussehen (AC-21 bis AC-23)
- Menüleisten-Fenster: Knopfleiste in einem Glas-Container, Hauptknopf im prominenten Glasstil, übrige im normalen Glasstil, alle in Standardgröße. Ist „Transparenz reduzieren“ eingeschaltet, nutzt die App feste System-Flächen statt Glas (eigene Prüfung des Bedienungshilfen-Schalters, nicht darauf verlassen, dass das System es übernimmt).
- Einstellungsfenster: gruppierte Formulare wie die Systemeinstellungen, kein Glas hinter Text.
- Alle Knöpfe haben Beschriftungen für VoiceOver; Tastatur-Fokus bleibt sichtbar; ⌘, und ⌘Q funktionieren im Menüleisten-Fenster.

## Qualität und Fehlerverhalten

| AC/EC | Bedingung und Grenze | Was es sicherstellt | Geplanter Nachweis |
| --- | --- | --- | --- |
| AC-2 | Zustandswechsel sichtbar ≤ 0,5 s | Symbol direkt an Zustand gebunden | Test der Zuordnung Zustand → Symbol/Text; Sichtprüfung im laufenden Programm |
| EC-3 | Alte App nach 5 s nicht beendet | Zweistufiges Beenden mit Zeitgrenze | Test mit Attrappe, die nicht reagiert (Zeit simuliert) |
| EC-4 | macOS lehnt Autostart ab | Alle vier macOS-Stände abgebildet | Test je Stand mit Attrappe |
| EC-1 | Zweites Exemplar | Mitteilung + Selbstbeenden | Test der Entscheidungslogik; Sichtprüfung durch Doppelstart |
| EC-6 | Fenster außerhalb aller Bildschirme | 80-%-Regel | Test der Lageberechnung mit erfundenen Bildschirmmaßen |

Fehler an den Schnittstellen:

| Art | Verhalten |
| --- | --- |
| Erwartete Ablehnung (macOS verweigert Autostart, alte App reagiert nicht) | Fester Zustand mit verständlichem Satz und Lösungsweg (Tabellen oben); keine technische Meldung an den Nutzer |
| Unerwarteter Fehler | Ein Protokolleintrag über Apples Protokoll-System (Kennung `com.innosolv.InnoWhisper`, Bereich `appshell`), ohne persönliche Inhalte; die App läuft weiter. PROJ-2 übernimmt später das zentrale Fehlerprotokoll |

## Datenmodell

Passt zum Ding „Einstellungen“ in `docs/data-model.md`; die Übersicht muss nicht geändert werden. Gespeichert in den Benutzereinstellungen von macOS unter der Kennung `com.innosolv.InnoWhisper`, nur auf diesem Mac, nur für den angemeldeten Nutzer.

- Letzter Bereich: Text, einer der acht Kennungen aus der Bereichstabelle, Standard `general`; ungültige Werte werden wie `general` behandelt
- Erststart erledigt: Ja/Nein, Standard Nein
- Bewusst ausgeschaltet: Ja/Nein, Standard Nein. Absicht des Nutzers, nicht der macOS-Stand: Solange Ja, zeigt die App keinen Autostart-Hinweis; zurück auf Nein, sobald macOS „eingeschaltet“ meldet (QA BUG-3)
- Lage und Größe des Einstellungsfensters: verwaltet von macOS über den festen Fensternamen `InnoWhisperSettings`
- Der Stand „Start beim Anmelden“ wird nicht selbst gespeichert, macOS hält ihn
- Probleme und Diktat-Tätigkeit: nur im Speicher, nicht dauerhaft
- Aufbewahrung: bis die App gelöscht wird; keine personenbezogenen Daten

## Bewusst weggelassene Sicherheits-Prüfpunkte

Plattform `desktop`, keine Konten, kein Server, kein Netzwerk in PROJ-1. Es gelten SEC-01 (keine Geheimnisse, hier keine vorhanden), SEC-02 (die einzige Eingabe von außen ist die Mitteilung einer zweiten Instanz: nur der feste Name zählt, Inhalte werden ignoriert) und SEC-08. Entfallen: SEC-03 und SEC-04 (keine Konten, keine Anmeldung), SEC-05 und SEC-06 (kein HTTP), SEC-07 (kein KI-Modell in PROJ-1).

## Abhängigkeiten

- Keine fremden Pakete. Genutzt werden nur Apple-Frameworks: SwiftUI, AppKit (Fenster, laufende Apps, Dialoge), ServiceManagement (Start beim Anmelden), OSLog (Protokoll).

## Einstellungen, die der Nutzer macht

Keine. (Signieren für die Auslieferung kommt in PROJ-14; für PROJ-1 reicht lokales Signieren ohne Apple-Konto.)

## Technische Entscheidungen

| Entscheidung | Begründung | Alternative | Nachteil | Datum |
| --- | --- | --- | --- | --- |
| Projektaufbau, Tests, Formatierung siehe ADR-008 | Gilt für alle Features | — | — | 2026-11-04 |
| Logik und Oberflächen im lokalen Paket, App-Ziel nur Zusammensetzung | Tests laufen schnell ohne App-Start; Features bleiben getrennt | alles im App-Ziel | ein zusätzlicher Ordner | 2026-11-04 |
| Bereiche und Allgemein-Gruppen werden angemeldet statt fest eingebaut | AC-8 ergibt sich von selbst; `AppShell` muss Feature-Module nicht kennen | Rahmen kennt alle Bereiche fest | Reihenfolge braucht eine feste Liste in `AppShell` | 2026-11-04 |
| Alle acht Bereichskennungen stehen von Anfang an fest | Problem-Hinweise können auf Bereiche zeigen, auch bevor diese gebaut sind; eine Reihenfolge an einer Stelle | jedes Feature bringt eigene Kennung und Position | Liste muss bei neuen Bereichen per `/refine PROJ-1` erweitert werden | 2026-11-04 |
| Eigenes Fenster statt der eingebauten Einstellungs-Szene von SwiftUI | Bei Apps ohne Dock-Symbol kommt die eingebaute Szene laut Erfahrung mit der alten App nicht zuverlässig nach vorne; ein eigenes Fenster mit fester Kennung ist sicher nur einmal da | eingebaute Einstellungs-Szene | ⌘, muss selbst belegt werden | 2026-11-04 |
| Start beim Anmelden: macOS ist die einzige Wahrheit, plus Merker „Erststart erledigt“ | AC-15 verlangt den echten Stand; Merker verhindert, dass ein bewusstes Aus überschrieben wird | eigener gespeicherter Schalter (alte App) | keiner nennenswert | 2026-11-04 |
| Alte App: erst normal beenden, nach 2 s sofort beenden, nach 5 s Anleitung | Normales Beenden lässt die alte App ihre Daten sichern; die Grenze verhindert Hängen | nur normal beenden | Vermutung: normales Beenden einer fremden App könnte bei Hardened Runtime eine macOS-Rückfrage zur Steuerung anderer Apps auslösen. Beim Bau prüfen; tritt sie auf, direkt „sofort beenden“ nutzen | 2026-11-04 |
| Zweite Instanz über System-Mitteilung ohne Inhalt | Einfach, ohne Netzwerk, nimmt keine fremden Daten an | Verbindung zwischen Prozessen | keiner nennenswert | 2026-11-04 |
| Glas-Ersatz bei „Transparenz reduzieren“ selbst prüfen | Prüfbar und unabhängig davon, ob das System es automatisch macht | sich auf das System verlassen | eine Verzweigung pro Glas-Fläche | 2026-11-04 |
| Lokales Signieren ohne Apple-Konto in PROJ-1 | PROJ-1 braucht keine Erlaubnisse, die an der Signatur hängen | sofort mit Entwickler-Zertifikat | Ab PROJ-3 (Mikrofon, Bedienungshilfen) muss die Signatur stabil sein, sonst gehen Erlaubnisse nach jedem Bau verloren; dann Umstellung auf das Entwickler-Zertifikat | 2026-11-04 |
| App-Symbol vorläufig | Finale Gestaltung gehört zur Auslieferung | sofort final | wird in PROJ-14 ersetzt | 2026-11-04 |

## Offene Fragen

- [ ] Löst das normale Beenden der alten App eine macOS-Rückfrage aus? Beim Bau prüfen (siehe Entscheidung oben).
- [ ] Schließt Esc das Menüleisten-Fenster von selbst, oder braucht es eine eigene Tastenbelegung? Beim Bau prüfen; AC-3 verlangt es so oder so.

## Umsetzungsnotizen (`/build`, 2026-11-04)

Abweichungen und Funde beim Bau. Verhalten laut `spec.md` unverändert.

- **Einstellungsfenster** wird von AppKit verwaltet (ein `NSWindow` mit SwiftUI-Inhalt) statt als SwiftUI-Fensterszene. Grund: Es muss auch aus dem App-Delegate geöffnet werden (erneutes Öffnen, zweite Instanz), wo es keine SwiftUI-Umgebung gibt. Genau ein Fenster bleibt garantiert.
- **Bestätigung „Die alte Version wurde beendet.“** erscheint als kleines System-Fenster mit OK statt als Text im Menüleisten-Fenster, weil dieses beim Beenden meist geschlossen ist. Ersatz durch kurze Hinweise mit PROJ-2.
- **Alte App** wird an zwei Kennungen erkannt: `com.innosolv.WhisperDictation` und `com.innosolv.WhisperDictation.beta`. Beide sind auf Team-Macs als „InnoWhisper“ bzw. „InnoWhisper Beta“ in `/Programme` installiert.
- **Esc im Menüleisten-Fenster:** Apples Schließen-Funktionen (`dismiss`, `onExitCommand`) wirken bei `MenuBarExtra`-Fenstern nicht (Live-Test). Eine Tastenbeobachtung, die nur für das Fenster des Menüleisten-Fensters gilt, schließt es (`MenuBar/PanelWindowCloser.swift`). Offene Frage aus dem Plan damit beantwortet.
- **Normales Beenden der alten App** löst keine macOS-Rückfrage aus (Live-Test: alte App 8 s nach Start sauber beendet). Offene Frage aus dem Plan damit beantwortet.
- **Zusätzliche Dateien:** `App/AppEnvironment.swift` (Zusammensetzung), `App/LegacyAlerts.swift` (System-Dialoge), `Sources/AppShell/System/AppShellLog.swift` (Protokoll). Protokolleinträge auf Stufe „notice“ für Startprüfung, alte App, Autostart-Stand und Öffnen der Einstellungen; nie Diktat-Inhalte.
- **Bau-Ausgabe** liegt in `~/Library/Developer/Xcode/DerivedData/InnoWhisper`. Im Schreibtisch-Ordner lehnt `codesign` das App-Paket wegen erweiterter Dateiattribute ab („resource fork, Finder information, or similar detritus not allowed“).
- **Für PROJ-14 vormerken:** (1) Die lokale Signatur ohne Zertifikat setzt die Hardened Runtime nicht (Signatur-Flags nur `adhoc`); bei der Release-Signatur prüfen, dass `runtime` gesetzt ist. (2) Die alte App liegt als `/Applications/InnoWhisper.app` vor; die neue App hat denselben Dateinamen. Die Umzugsanleitung muss das Ersetzen bzw. vorherige Löschen regeln.

### Live-Prüfung (T13)
| Prüfung | Ergebnis |
| --- | --- |
| Meldung alte App beim Start, „Alte Version beenden“ (AC-16, AC-17) | bestanden (Protokoll + Timur) |
| Erneutes Öffnen zeigt Einstellungen (AC-6) | bestanden (Protokoll) |
| Zweites Exemplar aus anderem Ordner (EC-1) | bestanden (Protokoll, nur ein Prozess) |
| Start beim Anmelden ein beim Erststart, aus bleibt aus (AC-13, AC-14) | bestanden (Protokoll + Timur) |
| Menüleisten-Fenster, Glas-Knöpfe gleich groß, Einstellungen mit „Allgemein“ (AC-4, AC-5, AC-7, AC-21) | bestanden (Timur, Sichtprüfung) |
| Esc schließt Menüleisten-Fenster (AC-3) | nach Fix bestanden (Timur) |
| Dunkelmodus, „Transparenz reduzieren“, VoiceOver, nur Tastatur, zweiter Bildschirm (AC-22, AC-23, EC-6) | nicht live geprüft; Bildschirmfoto-Werkzeug erfasst Menüleisten-Apps nicht. Für `/qa` |
| Rückfrage beim Beenden während Diktat (AC-20) | nur Logik-Test; live erst prüfbar, wenn PROJ-5 Aufnahmen liefert |
| Alte App startet, während InnoWhisper läuft (EC-2) | nur Logik-Test |

### Korrekturen nach `/qa` (2026-11-04)
- **BUG-1:** Erkennung laufender Apps über die Beobachtung der Liste `runningApplications` statt über die Start-/Beenden-Mitteilungen von `NSWorkspace`, die macOS für Menüleisten-Apps nicht schickt (mit Test-App nachgewiesen). Live bestätigt: alte App 5 s nach InnoWhisper gestartet, Meldung erschien.
- **BUG-4:** Hardened Runtime in Debug und Release (`--options=runtime`), in Release keine eingeschleuste Debug-Berechtigung. Debug baut ohne getrennte Debug-Bibliothek (`ENABLE_DEBUG_DYLIB = NO`), weil die Bibliotheksprüfung der Hardened Runtime sie bei lokaler Signatur ablehnt und die App sonst nicht startet. Debug behält `get-task-allow` zum Entwickeln, siehe Ausnahme in ADR-007.
- **Fensterbreite:** Live-Test von Timur: In einem breiteren Fenster stand der Inhalt von „Allgemein“ mittig. Lösung nach Timurs Wahl: Höchstbreite 760 pt.

