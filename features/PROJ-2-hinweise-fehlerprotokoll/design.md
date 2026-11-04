# PROJ-2 — Technischer Plan: Hinweise & Fehlerprotokoll

> Technischer Plan (das WIE). Zwei Leser: Timur (gibt frei) und `/build` (baut danach). Kein Code, aber genau.
> Owner: `/architecture`. Der Vertrag (WAS) steht in `spec.md`, die Aufgabenliste in `tasks.md`.

Grundlage: ADR-001, ADR-002, ADR-007, ADR-008. Baut auf PROJ-1 auf (Modul `AppShell`: Zustand, Problem-Sammlung, Einstellungsbereiche mit Allgemein-Gruppen). Plattform `desktop`, kein Netzwerk, kein Konto.

## Komponenten

```
Hinweis-Kapsel (schwebendes Fenster, nimmt nie den Fokus)      AC-1 … AC-7, EC-1, EC-2
+-- Symbol der Art (Info / Erfolg / Fehler) + Text
+-- Klick schließt einen Fehler-Hinweis
Töne                                                           AC-9, EC-5
+-- Startklang, Endklang (macOS-Klänge)
Fehlerprotokoll (Datei auf dem Mac)                            AC-11 … AC-13, EC-3
Einstellungsfenster → Bereich „Allgemein“ (aus PROJ-1)
+-- Gruppe „Töne“: Schalter „Töne bei Start und Ende“          AC-10
+-- Gruppe „Fehlerprotokoll“: Knopf „Fehlerprotokoll zeigen“   AC-14, EC-3, EC-4
```

## Code-Aufbau

Zwei neue Module im Paket `Packages/InnoWhisperKit` (ADR-008):

| Modul / Pfad | Aufgabe und Schnittstelle | Darf benutzen |
| --- | --- | --- |
| `Sources/Diagnostics/` | **Fehlerprotokoll**, unterste Schicht ohne eigene Abhängigkeiten. Bietet: einen Eintrag schreiben (Bereich + Meldung), Datei-Ort erfragen, „verfügbar ja/nein“, Datei anlegen falls fehlend. Meldungen können nur aus festen Texten und sicheren Werten bestehen (siehe Protokoll-Meldung) | nur Apple-Frameworks |
| `Sources/Notices/` | **Hinweise und Töne**: Hinweis zeigen/schließen, Platzierung, schwebendes Fenster, Startklang/Endklang, die zwei Allgemein-Gruppen | `AppShell`, `Diagnostics` |
| `Tests/DiagnosticsTests/`, `Tests/NoticesTests/` | Tests mit Swift Testing | jeweiliges Modul |
| `App/AppEnvironment.swift` | Zusammensetzen: Hinweis-Zentrale erzeugen, Allgemein-Gruppen anmelden, Beginn einer Aufnahme an die Hinweis-Zentrale melden, Bestätigung zur alten App als Hinweis | alle Module |
| `App/LegacyAlerts.swift` | „alte Version beendet“ wird nicht mehr als Fenster gezeigt (AC-8) | `AppShell`, `Notices` |

`Diagnostics` ist eine Grundlagen-Schicht: Auch `AppShell` (PROJ-1) darf sie benutzen. Alle bisherigen Protokollaufrufe von PROJ-1 (`AppShellLog`, `launchLog`, 9 Stellen) laufen künftig darüber, damit sie im Fehlerprotokoll landen. Das ändert das Verhalten von PROJ-1 nicht, nur das Ziel der Protokolleinträge.

### Was andere Features bekommen
- **Hinweis zeigen**: Art (Info, Erfolg, Fehler) und Text.
- **Hinweis-Stelle melden** (für PROJ-8): ein Rechteck in Bildschirmkoordinaten, unter dem der Hinweis erscheinen soll, oder „keine Stelle“.
- **Startklang / Endklang spielen** (für PROJ-5).
- **Protokoll schreiben**: über `Diagnostics`, nur mit sicheren Werten.

## Footprint

- Code und Tests: `Packages/InnoWhisperKit/Sources/Diagnostics/`, `Sources/Notices/`, `Tests/DiagnosticsTests/`, `Tests/NoticesTests/`, Änderung `Package.swift` (zwei Module, `AppShell` hängt von `Diagnostics` ab), Änderungen in `App/AppEnvironment.swift`, `App/LegacyAlerts.swift`, `App/AppDelegate.swift` und an den 9 Protokollstellen in `AppShell`
- Datenbank, Tabellen, Zugriffsregeln: keine
- Umgebungsvariablen: keine
- Pakete: keine fremden Pakete
- Anschlusspunkte: Allgemein-Gruppen über `SettingsRegistry` (PROJ-1), Diktat-Tätigkeit aus `ActivityCenter` (PROJ-1), Datei `~/Library/Logs/InnoWhisper/InnoWhisper.log`, macOS-Klänge aus `/System/Library/Sounds`

## Hinweise

### Hinweis
- Art: genau eine von Info, Erfolg, Fehler
- Text: Pflicht, eine Zeile, höchstens 120 Zeichen; Längeres wird mit „…“ gekürzt
- Symbol je Art (SF Symbols): Info `info.circle.fill`, Erfolg `checkmark.circle.fill` (System-Grün), Fehler `exclamationmark.triangle.fill` (System-Orange)
- Lebensdauer: nur im Speicher

### Verhalten
- Es gibt höchstens einen sichtbaren Hinweis. Ein neuer ersetzt den alten sofort (AC-5).
- Info und Erfolg schließen sich nach 2,0 Sekunden (AC-3). Der Zeitgeber gehört genau zu dem Hinweis, für den er gestartet wurde: Läuft der Zeitgeber eines ersetzten Hinweises ab, schließt er den neuen **nicht** (siehe Entscheidungen).
- Fehler schließen sich nur durch: Klick auf die Kapsel, Esc, oder den Beginn einer Aufnahme (Diktat-Tätigkeit wechselt auf „nimmt auf“) (AC-4).
- Esc wird über eine passive, app-übergreifende Tastenbeobachtung erkannt, die nur läuft, solange ein Fehler-Hinweis sichtbar ist. macOS liefert sie erst, wenn InnoWhisper die Erlaubnis „Bedienungshilfen“ hat (PROJ-3). Vorher schließen Klick und neue Aufnahme den Fehler. Die Taste wird nicht abgefangen: Das Programm, in dem der Nutzer schreibt, bekommt sein Esc trotzdem.
- Jeder Hinweis wird zusätzlich für VoiceOver angesagt (Ansage mit hoher Priorität) (AC-7).
- Ins Protokoll kommt nur die Art eines gezeigten Hinweises, nie sein Text.

### Platzierung (AC-1, EC-1, EC-2)
- Ist eine Stelle gemeldet: Kapsel waagerecht mittig unter dieser Stelle, 8 pt Abstand. Ragt sie über den Bildschirmrand, wird sie in den sichtbaren Bereich dieses Bildschirms geschoben. Passt sie unten nicht hin, erscheint sie über der Stelle.
- Ohne Stelle: oben mittig im sichtbaren Bereich (unter der Menüleiste), 12 pt Abstand, auf dem Bildschirm mit dem Mauszeiger. Den Bildschirm des Eingabefelds kennt erst PROJ-8; bis dahin gilt der Mauszeiger.
- Das Fenster ist ein randloses Schwebefenster, das nie aktiv wird und nie den Tastaturfokus bekommt (AC-6), über allen normalen Fenstern und über Vollbild-Programmen liegt (EC-2) und auf allen Schreibtischen (Spaces) erscheint.

### Aussehen
- Kapsel mit Liquid Glass, Symbol und Text, Höhe passend zum Text (eine Zeile `.callout`), Innenabstand 12 pt waagerecht, 8 pt senkrecht.
- „Transparenz reduzieren“: feste Fläche in der System-Fensterfarbe statt Glas.
- „Bewegung reduzieren“: erscheint und verschwindet ohne Animation; sonst kurzes Einblenden (0,2 s).

## Töne (AC-9, AC-10, EC-5)
- Startklang `Tink`, Endklang `Pop`, beide aus `/System/Library/Sounds`, Lautstärke 0,4.
- Es gibt einen einzigen Abspieler. Vor jedem Klang stoppt er den noch laufenden (EC-5).
- Ist der Schalter aus, spielt nichts. Fehler haben keinen Klang.
- Fehlt ein Klang auf dem System (nicht erwartet), bleibt es still, und es entsteht ein Protokolleintrag.

## Fehlerprotokoll (AC-11 bis AC-14, EC-3, EC-4)

### Ort und Format
- Datei `~/Library/Logs/InnoWhisper/InnoWhisper.log`, Ordner wird bei Bedarf angelegt.
- Eine Zeile je Eintrag: Zeitpunkt (ISO 8601 mit Millisekunden, Ortszeit mit Abweichung), Bereich in eckigen Klammern, Meldung.
- Bereiche: `app`, `appshell`, `notices`, später je Feature ein eigener.
- Jeder Eintrag geht zusätzlich in Apples Protokoll (Kennung `com.innosolv.InnoWhisper`).

### Protokoll-Meldung: nie Diktat-Inhalte (AC-12)
Eine Meldung lässt sich nur bauen aus:
- festem Text, der im Programm steht,
- Zahlen, Wahr/Falsch, Dauern,
- Werten aus festen Aufzählungen (z. B. Autostart-Stand, Art eines Hinweises); ein solcher Wert beschreibt sich nur mit festem Text aus dem Programm, nie mit gespeichertem Text,
- Programmkennungen, aber nur von Programmen, die auf diesem Mac installiert sind (sonst `<unknown-app>`),
- Fehlern, von denen nur Bereich und Nummer übernommen werden, nie der Fehlertext; nur System-Fehlerbereiche (enden auf `ErrorDomain` oder beginnen mit `com.apple.`), sonst `<domain>`. Eigene Fehler späterer Features werden deshalb als eigener Aufzählungswert protokolliert.

Freier Text (eine Zeichenkette aus Variablen) lässt sich in eine Meldung **nicht** einsetzen. Der Übersetzer lehnt das ab. So kann kein Feature versehentlich diktierten Text, Zwischenablage oder den Zugangsschlüssel protokollieren.

### Aufbewahrung (AC-13)
- Beim Start und beim Schreiben, sobald der älteste Eintrag älter als 7 Tage ist oder die Datei 10 MB überschreitet: Einträge älter als 7 Tage entfernen; ist die Datei danach noch über 10 MB, die ältesten entfernen, bis sie unter 8 MB liegt (Puffer, damit nicht bei jedem Eintrag neu geschrieben wird).
- Schreiben geschieht nacheinander in einer eigenen Warteschlange, nie auf dem Hauptablauf.

### Nicht schreibbar (EC-3)
- Schlägt das Anlegen oder Schreiben fehl, merkt sich das Protokoll „nicht verfügbar“ und versucht es beim nächsten Eintrag erneut (eine gelöschte Datei wird dabei neu angelegt). Kein Hinweis an den Nutzer, Apples Protokoll erhält weiter alles.

### Knopf (AC-14, EC-4)
- „Fehlerprotokoll zeigen“: legt die Datei an, falls sie fehlt (leer), und markiert sie im Finder.
- Ist das Protokoll nicht verfügbar: Knopf ausgegraut mit dem Text „Fehlerprotokoll nicht verfügbar“.

## Einstellungen in „Allgemein“
| Gruppe | Reihenfolge | Inhalt |
| --- | --- | --- |
| System (PROJ-1) | 10 | Start beim Anmelden |
| Töne | 20 | Schalter „Töne bei Start und Ende“ |
| Fehlerprotokoll | 90 | Erklärsatz „Enthält nur technische Abläufe, nie diktierten Text.“ und Knopf „Fehlerprotokoll zeigen“ |

## Qualität und Fehlerverhalten

| AC/EC | Bedingung und Grenze | Was es sicherstellt | Geplanter Nachweis |
| --- | --- | --- | --- |
| AC-3 | Info/Erfolg nach 2,0 s weg | Zeitgeber je Hinweis | Test mit simulierter Zeit; Sichtprüfung |
| AC-5 | Ersetzter Hinweis darf neuen nicht schließen | Zeitgeber prüft Kennung des Hinweises | Test: zwei Hinweise in 1 s Abstand, zweiter bleibt volle 2 s |
| AC-6 | Fokus bleibt beim anderen Programm | Fenster wird nie aktiv | Sichtprüfung: während Hinweis weitertippen |
| AC-12 | Nie Diktat-Text im Protokoll | Meldungsart lässt keinen freien Text zu | Übersetzer-Test (Beispiel mit freiem Text baut nicht) plus Suche über den Code |
| AC-13 | 7 Tage, ≤ 10 MB | Kürzen beim Start und bei Überschreitung | Test mit erfundenen Zeitpunkten und großer Datei im Testordner |
| EC-5 | Kein doppelter Klang | Ein Abspieler, stoppt vor jedem Klang | Test mit Attrappe |

Fehler an den Schnittstellen:

| Art | Verhalten |
| --- | --- |
| Datei nicht schreibbar | Zustand „nicht verfügbar“, Knopf ausgegraut, App läuft weiter (EC-3) |
| Klang fehlt | still, ein Protokolleintrag |
| Unerwarteter Fehler | ein Eintrag in Apples Protokoll, App läuft weiter |

## Datenmodell

Passt zu „Einstellungen“ und „Protokoll-Eintrag“ in `docs/data-model.md`; dort wird die Aufbewahrung ergänzt.

- Töne an: Ja/Nein, Standard Ja, Benutzereinstellung `sounds.enabled`
- Protokoll-Eintrag: Zeitpunkt, Bereich (fester Name), Meldung (nur sichere Werte, siehe oben); in der Datei; aufbewahrt höchstens 7 Tage und insgesamt höchstens 10 MB; gehört dem Nutzer des Macs
- Hinweise: nur im Speicher, nie gespeichert

## Bewusst weggelassene Sicherheits-Prüfpunkte

Plattform `desktop`, keine Konten, kein Netzwerk, kein Modell. Es gelten SEC-01 (der Zugangsschlüssel kann nicht ins Protokoll, AC-12), SEC-02 (keine Eingaben von außen außer der Esc-Taste, die nur gelesen wird) und SEC-08. Entfallen: SEC-03 bis SEC-07.

## Abhängigkeiten
- Keine fremden Pakete. Apple-Frameworks: SwiftUI, AppKit (Schwebefenster, Klänge, Finder, Tastenbeobachtung), OSLog.

## Einstellungen, die der Nutzer macht
Keine.

## Technische Entscheidungen

| Entscheidung | Begründung | Alternative | Nachteil | Datum |
| --- | --- | --- | --- | --- |
| Zwei Module: `Diagnostics` (Grundlage) und `Notices` | Protokoll braucht jedes Modul, auch `AppShell`; Hinweise brauchen `AppShell` | alles in einem Modul | `AppShell` hängt nun von `Diagnostics` ab | 2026-11-04 |
| Protokoll-Meldung lässt keinen freien Text zu | AC-12 wird vom Übersetzer garantiert statt von Disziplin; verhindert die häufigste Datenpanne in Protokollen | Regel „bitte nichts Sensibles loggen“ | Programmkennungen und Fehlernummern brauchen eigene, erlaubte Formen | 2026-11-04 |
| Zeitgeber gehört zu genau einem Hinweis | Garantie für AC-5: ein alter Zeitgeber schließt nie den neuen Hinweis | ein gemeinsamer Zeitgeber | keiner | 2026-11-04 |
| Schwebefenster, das nie aktiv wird | AC-6: Tastatur bleibt beim Programm des Nutzers; sichtbar über Vollbild (EC-2) | normales Fenster, macOS-Mitteilungen | Mitteilungszentrale wäre nicht am Eingabefeld | 2026-11-04 |
| Esc über passive Tastenbeobachtung, erst mit Bedienungshilfen | Nur so erreicht Esc eine App im Hintergrund; passiv, damit das Programm des Nutzers sein Esc behält | Esc abfangen | Vor PROJ-3 schließt Esc einen Fehler nicht, Klick und neue Aufnahme aber schon | 2026-11-04 |
| Ohne gemeldete Stelle: Bildschirm mit Mauszeiger | Das Eingabefeld kennt erst PROJ-8 | Hauptbildschirm | Bei Maus auf anderem Bildschirm als dem Fenster erscheint der Hinweis dort | 2026-11-04 |
| Klänge `Tink` (Start) und `Pop` (Ende), Lautstärke 0,4 | Leise, kurz, gut unterscheidbar, auf jedem Mac vorhanden | eigene Klangdateien | Kein eigener Klangcharakter | 2026-11-04 |
| Protokoll in `~/Library/Logs/InnoWhisper/` | Üblicher Ort, in der Konsole sichtbar, übersteht Neustarts (anders als `/tmp` bei der alten App) | `/tmp`, App-Support-Ordner | keiner | 2026-11-04 |
| Kürzen auf 8 MB, wenn 10 MB überschritten | Nicht bei jedem Eintrag die ganze Datei neu schreiben | exakt auf 10 MB halten | Datei schwankt zwischen 8 und 10 MB | 2026-11-04 |

## Offene Fragen
- (keine)

## Umsetzungsnotizen (`/build`, 2026-11-04)

- **Protokoll-Zugang:** `Diagnostics/Log.swift` schreibt in Datei und Apples Protokoll; `AppShellLog` aus PROJ-1 entfällt, alle 9 Stellen laufen darüber. Zustände, die protokolliert werden, erfüllen `LogValue` (Autostart-Stand, Antwort zur alten App, Bereich, Art eines Hinweises, Klang).
- **Zeitangabe** im Protokoll in Ortszeit mit Abweichung (`2026-11-04T14:48:00.112+01:00`); die erste Fassung schrieb UTC und wurde beim Selbsttest korrigiert.
- **Zusätzliche Test-Datei** `DiagnosticsTests/LogTests.swift` für den Protokoll-Zugang.
- **Start-Eintrag:** Build-Nummer und macOS-Version als Zahlen (eine Versions-Zeichenkette ist absichtlich nicht protokollierbar).

### Live-Prüfung (T11)
| Prüfung | Ergebnis |
| --- | --- |
| Protokolldatei unter `~/Library/Logs/InnoWhisper/InnoWhisper.log`, nur technische Zeilen (AC-11, AC-12) | bestanden (selbst gelesen; Suche nach Diktat/Zwischenablage/Schlüssel: 0 Treffer) |
| Hinweis „Die alte Version wurde beendet.“ (AC-8), oben mittig, Glas, nach 2 s weg (AC-1, AC-3) | bestanden (Protokoll „Notice shown: success“ + Timur) |
| Hinweis übernimmt die Tastatur nicht (AC-6) | bestanden (Protokoll „key: false“) |
| Gruppen „Töne“ (an) und „Fehlerprotokoll“ in „Allgemein“, Knopf markiert die Datei im Finder (AC-10, AC-14) | bestanden (Timur) |
| Töne hörbar (AC-9) | nicht live prüfbar vor PROJ-5 (keine Aufnahme), nur Tests |
| Esc schließt Fehler-Hinweis (AC-4) | nicht live geprüft; braucht Bedienungshilfen (PROJ-3) und einen Fehler-Hinweis |

### Korrekturen nach `/qa` (2026-11-04)
- **BUG-1:** Protokoll-Meldung ohne Hintertüren: Programmkennung nur für installierte Programme (Launch Services), Fehlerbereich nur System-Bereiche, und ein Aufzählungswert beschreibt sich nur noch mit festem Text (`StaticString`). Übersetzer-Tests belegen, dass Struktur-Felder, Begleitwerte und `String` abgelehnt werden, auch mit selbst geschriebenem `allCases`.
- **BUG-2:** 7-Tage-Grenze auch beim Schreiben (der älteste Eintrag wird mitgeführt).
- **BUG-3:** Eine gelöschte Protokolldatei wird beim nächsten Eintrag neu angelegt. Live gemessen: Datei während des Laufs gelöscht, beim Öffnen der Einstellungen neu angelegt mit neuen Einträgen.

