# PROJ-5 — Technischer Entwurf

> Grundlage: `spec.md` (AC-1 bis AC-21, EC-1 bis EC-8). Plattform: native Mac-App (`.ai-eng-kit` → `platform: desktop`), kein Backend (ADR-002), keine passende Stack-Mappe unter `docs/stacks/`. Gebaut wird nach den Mustern der vorhandenen Module (`Permissions`, `GroqAccess`).
> Entfallen, weil die Plattform sie nicht hat: Server-Zugriffsregeln, HTTP-Routen, Formulare, Bremsen für Anmeldungen (es wird keine Zugangsprüfung gemacht). Bestehen bleibt: Eingaben prüfen (Kürzel, Mikrofon-Kennung), Tests je Verhalten, keine Inhalte im Protokoll.

## Komponenten

```
InnoWhisper (Menüleisten-App)
+-- Kürzel-Wächter (neu, Modul Recording)
|   +-- hört global auf Tasten: rechte ⌘ allein, Kombinationen, Esc
|   +-- meldet: "Kürzel gedrückt", "losgelassen", "andere Taste dazu", "Esc"
+-- Aufnahme-Steuerung (neu)
|   +-- ein Ablauf: bereit → wartet (Halten < 0,25 s) → startet → nimmt auf → endet → bereit
|   +-- Startton/Endton (PROJ-2), Zustand "nimmt auf" an der Menüleiste (PROJ-1)
|   +-- Hinweise (PROJ-2): abgebrochen, verworfen, kein Ton, Mikrofon fehlt …
+-- Mikrofon-Aufnehmer (neu)
|   +-- öffnet das gewählte oder das Systemmikrofon
|   +-- schreibt den Ton in eine Datei, misst laufend den Pegel
+-- Ablage der fertigen Aufnahmen (neu)
|   +-- übergibt jede fertige Aufnahme in Sprech-Reihenfolge an die Umwandlung (PROJ-6)
|   +-- bis PROJ-6 da ist: Platzhalter, der nur die letzte Aufnahme behält
+-- Einstellungsbereich "Aufnahme" (bisher "Tastenkürzel", Kennung hotkeys)
|   +-- Gruppe "Tastenkürzel": Kürzel-Feld zum Aufnehmen einer Taste, Modus Halten / Ein/aus
|   +-- Gruppe "Mikrofon": Auswahl Systemmikrofon oder ein angeschlossenes Mikrofon
+-- Einführungsschritt "Tastenkürzel" (Reihenfolge 60)
    +-- Text "Halte die rechte ⌘-Taste und sprich.", Mikrofonwahl, Pegelanzeige
    +-- Probe-Aufnahme, "Weiter" erst nach gelungener Probe
```

## Code-Aufbau

| Modul / Pfad | Aufgabe und Schnittstelle | Darf benutzen |
| --- | --- | --- |
| `Sources/Recording/` (neues Modul) | **Aufnahme.** Kürzel-Wächter, Aufnahme-Steuerung, Mikrofon-Aufnehmer, Ablage, Einstellungsbereich, Einführungsschritt. Bietet: `start()`, Zustand der Aufnahme, aktueller Pegel (für PROJ-8), Schnittstelle „fertige Aufnahme abnehmen“ (für PROJ-6), Einstellungsansicht, Einführungsschritt | `AppShell`, `Diagnostics`, `Notices`, `Onboarding`, `Permissions`; Apple: AVFoundation, CoreAudio, CoreGraphics (Ereignisse), AppKit, Carbon (nur Tastennamen und Belegt-Prüfung) |
| `Sources/Recording/Hotkey/` | Kürzel-Beschreibung (Datenmodell unten), Kürzel-Wächter über einen Ereignis-Abgriff von macOS, reine Entscheidungslogik „was bedeutet dieser Tastendruck“ (ohne macOS, testbar), Belegt-Prüfung | wie oben |
| `Sources/Recording/Capture/` | Mikrofon-Aufnehmer (öffnet Gerät, schreibt Datei, misst Pegel und Sprachanteil), Mikrofonliste, Speicherplatz-Prüfung. Hinter einer Schnittstelle, damit Tests eine Attrappe nehmen | wie oben |
| `Sources/Recording/Session/` | Aufnahme-Steuerung als Zustandsautomat mit Generationszähler, Regeln für Verwerfen und Esc (rein, testbar), Ablage mit laufender Nummer | wie oben |
| `Sources/Recording/UI/` | Einstellungsbereich „Aufnahme“, Kürzel-Feld, Mikrofonwahl, Einführungsschritt mit Pegel | wie oben |
| `Sources/Notices/Notice.swift`, `NoticeView.swift`, `NoticeCenter.swift` | **Kleine Ergänzung an PROJ-2:** Ein Hinweis kann einen Knopf mit Titel und Handlung tragen (für AC-15 „Jetzt erlauben“). Hinweise ohne Knopf verhalten sich unverändert | wie bisher |
| `Sources/AppShell/Settings/SettingsSection.swift` | **Kleine Ergänzung an PROJ-1:** Anzeigename des Bereichs `hotkeys` wird „Aufnahme“ (Symbol bleibt). Kennung und Reihenfolge bleiben | wie bisher |
| `Sources/Diagnostics/LogFile.swift` | Neuer Protokoll-Bereich `recording` | wie bisher |
| `App/AppEnvironment.swift` | Erzeugt das Aufnahme-Modul, meldet Bereich und Schritt an, verbindet Aktivität (Menüleiste, Rückfrage beim Beenden), Erlaubnis-Wächter, Hinweise und Töne | alle Module |
| `Tests/RecordingTests/` | Tests mit Swift Testing; Tasten, Mikrofon und Uhr über Attrappen | `Recording` |

## Footprint

- **Code und Tests:** `Packages/InnoWhisperKit/Sources/Recording/` (neu), `Tests/RecordingTests/` (neu); kleine Ergänzungen in `Notices`, `AppShell/Settings/SettingsSection.swift`, `Diagnostics/LogFile.swift`, `App/AppEnvironment.swift`, `Package.swift`, `project.pbxproj`
- **Gespeicherte Daten:** Einstellungen in UserDefaults (siehe Datenmodell); Aufnahme-Dateien unter `~/Library/Application Support/InnoWhisper/Recordings/`
- **Umgebungsvariablen:** keine
- **Pakete:** keine neuen (nur Apple-Frameworks)
- **Andockstellen:** Menüleisten-Zustand (`ActivityCenter`), Rückfrage beim Beenden (PROJ-1 AC-20, liest `ActivityCenter`), Einstellungsbereich `hotkeys`, Einführungsschritt Reihenfolge 60, Hinweise und Töne (PROJ-2), Erlaubnis-Wächter (PROJ-3); externe Dienste: keine
- **Erlaubnisse von macOS:** Mikrofon und Bedienungshilfen, beide schon über PROJ-3 erteilt; keine neue

## Qualität und Fehlerverhalten

| AC/EC | Bedingung und messbare Grenze | Mechanismus | Geplanter Nachweis |
| --- | --- | --- | --- |
| AC-4 | Startton und Zustand „nimmt auf“ spätestens 1 s nach dem Druck, erst wenn Ton ankommt | Startton erst beim ersten Tonpaket mit echten Werten; Zeitstempel Druck → erstes Tonpaket im Protokoll | Test mit Attrappe (Reihenfolge der Ereignisse); live: Protokollzeilen „pressed“ und „audio flowing“ auf zwei Macs |
| AC-14 | Ohne Ton nach 1 s Abbruch mit Meldung | Wächter-Uhr ab Öffnen des Mikrofons; Tonpakete nur aus Nullen zählen nicht als Ton | Test mit Attrappe (keine Pakete, nur Nullen); live: Mikrofon in macOS stummschalten |
| AC-6 | 10 Minuten und länger ohne Lücke | Ton wird fortlaufend in eine Datei geschrieben, die auch bei Abbruch lesbar bleibt; keine Höchstdauer | live: 10-Minuten-Aufnahme, Dauer der Datei mit der gesprochenen Zeit vergleichen (Abweichung unter 1 s) |
| AC-9 | Zweites Esc innerhalb von 3 s | reine Regel mit Uhr-Attrappe | Test |
| AC-10, AC-11 | Unter 0,5 s still verwerfen; Sprachanteil unter 5 % verwerfen mit Hinweis | reine Regel, Pegelmessung je Tonpaket | Test mit festen Pegelfolgen; live: Taste halten ohne Sprechen |
| EC-1 | ⌘C mit der rechten ⌘ startet kein Diktat, Mikrofon geht nicht an | Mikrofon öffnet erst, wenn die rechte ⌘ 0,25 s allein gehalten wurde; jede andere Taste davor oder danach verwirft | Test der Entscheidungslogik; live: zehnmal ⌘C/⌘V, kein Startton, keine orange Mikrofonanzeige von macOS |
| EC-5 | Verlorenes Loslassen hängt nie | Bei jedem Tastenereignis und alle 0,5 s während der Aufnahme wird der echte Tastenzustand bei macOS nachgefragt | Test mit Attrappe |
| EC-8 | Höchstens eine Aufnahme | ein Zustandsautomat auf dem Hauptthread, Start nur aus „bereit“; Generationszähler verwirft späte Rückmeldungen einer alten Aufnahme | Test (schnelle Druckfolge, späte Rückmeldung) |
| Pflichtpunkt 1 | Aufnahme startet hörbar oder mit Meldung, nie still | AC-4 und AC-14 zusammen; dazu: schaltet macOS den Tastenabgriff ab (zu langsam, Bedienungshilfen entzogen), wird er sofort neu eingeschaltet und das protokolliert | Test des Neustarts mit Attrappe; Protokoll |

Erwartete Fehler und was der Nutzer sieht:
- Mikrofon-Erlaubnis fehlt → Hinweis „Mikrofon nicht erlaubt.“ mit Knopf „Jetzt erlauben“ (AC-15).
- Gewähltes Mikrofon fehlt → Systemmikrofon plus Hinweis (AC-13).
- Mikrofon liefert keinen Ton → Abbruch plus Hinweis (AC-14).
- Mikrofon getrennt, Ruhezustand, Bildschirm gesperrt, Speicher voll → Aufnahme endet, Gesprochenes wird weitergegeben (EC-2 bis EC-4).
- Datei lässt sich nicht anlegen oder schreiben → Hinweis „Aufnahme fehlgeschlagen. Bitte versuche es noch einmal.“, Protokoll mit Fehlercode. Gesprochenes bis dahin wird weitergegeben, wenn die Datei lesbar ist.

Unerwartete Fehler (Absturz während der Aufnahme): Die Datei bleibt liegen. Beim nächsten Start werden solche Reste gelöscht und gezählt ins Protokoll geschrieben; eine Wiederherstellung gibt es nicht (nicht in der Spec).

## Datenmodell

**Tastenkürzel** (eins pro Nutzer in PROJ-5; PROJ-12 macht daraus eine Liste)
- Art: eine von „Zusatztaste allein“ oder „Kombination“
- Bei „Zusatztaste allein“: welche Taste, eine von rechte ⌘, linke ⌘, rechte ⌥, linke ⌥, rechte ⌃, linke ⌃, rechte ⇧, linke ⇧
- Bei „Kombination“: Tastennummer der Haupttaste (ganze Zahl) und die gedrückten Zusatztasten (mindestens eine von ⌘, ⌥, ⌃, ⇧); Esc ist als Haupttaste nicht erlaubt, weil es den Abbruch auslöst
- Modus: einer von „Halten“, „Ein/aus“
- Ab Werk: Zusatztaste allein, rechte ⌘, Modus „Halten“
- Gespeichert in UserDefaults unter `recording.shortcut` (Art, Taste bzw. Tastennummer und Zusatztasten) und `recording.mode`. Ein unlesbarer oder unerlaubter gespeicherter Wert fällt auf den Werkszustand zurück und wird protokolliert.

**Mikrofonwahl**
- Kennung des Geräts (Text, die feste Gerätekennung von macOS) oder leer für „Systemmikrofon“
- Anzeigename wird nicht gespeichert, sondern beim Anzeigen von macOS geholt
- Ab Werk leer (Systemmikrofon)
- Gespeichert in UserDefaults unter `recording.microphoneID`

**Aufnahme** (Datei, keine Einstellung)
- Laufende Nummer (ganze Zahl, wächst mit jeder Aufnahme seit dem Start der App, bestimmt die Reihenfolge der Weitergabe)
- Datei: 16 kHz, Mono, 16 bit, im Format CAF, Name aus einer zufälligen Kennung; Ordner `~/Library/Application Support/InnoWhisper/Recordings/`
- Dauer (Sekunden), Art des Mikrofons (System oder gewählt), Startzeit
- Gehört dem Nutzer des Macs, liegt nur lokal
- **Aufbewahrt:** Abgebrochene, verworfene und Probe-Aufnahmen werden sofort gelöscht. Fertige Aufnahmen gehen an die Umwandlung. Bis PROJ-6 gebaut ist, behält der Platzhalter nur die jeweils letzte fertige Aufnahme und löscht die vorige. Wie lange Aufnahmen nach der Umwandlung bleiben, regelt PROJ-10. Reste nach einem Absturz werden beim nächsten Start gelöscht.
- Protokolliert werden nur Nummer, Dauer, Art des Mikrofons, Ergebnis und Grund, nie Ton oder Text.

**Was nicht gespeichert wird:** Pegelverläufe, Gerätenamen, Tastenfolgen außerhalb des Kürzels.

## Abläufe

**Halten (rechte ⌘ allein):**
1. Rechte ⌘ geht runter, keine andere Taste gedrückt → Zustand „wartet“, Uhr läuft.
2. Andere Taste innerhalb der Wartezeit oder Loslassen vor 0,25 s → zurück zu „bereit“, nichts passiert (EC-1, AC-10).
3. Nach 0,25 s allein gehalten → Mikrofon öffnet („startet“), Ton fließt in die Datei.
4. Erstes Tonpaket mit echten Werten → Startton, Zustand „nimmt auf“, Fehler-Hinweis verschwindet (PROJ-2). Kommt 1 s lang nichts → Abbruch, Hinweis (AC-14).
5. Loslassen → Endton, Datei schließen, Regeln prüfen: Gesamtdauer unter 0,5 s → still verwerfen; Sprachanteil unter 5 % → verwerfen mit Hinweis; sonst an die Ablage mit nächster Nummer.
6. Wird während „nimmt auf“ eine andere Taste gedrückt → still verwerfen (EC-1; das Programm bekommt den Kurzbefehl).

**Kombination im Modus Halten** (z. B. ⌥ Leertaste): Mikrofon öffnet sofort beim Druck (eine Kombination ist eindeutig). Die Haupttaste wird abgefangen und erreicht das Programm nicht. Loslassen der Haupttaste oder einer der Zusatztasten beendet.

**Ein/aus:** Erster Druck (bei Zusatztaste allein: Antippen ohne andere Taste, kürzer als 0,5 s) startet sofort, zweiter beendet. Andere Tasten während der Aufnahme beenden nichts.

**Esc während „startet“ oder „nimmt auf“:** Esc wird abgefangen und erreicht das Programm nicht. Aufnahme jünger oder gleich 30 s → abbrechen und Datei löschen, Hinweis „Aufnahme abgebrochen.“ Älter → Hinweis „Nochmal Esc drücken zum Abbrechen.“, zweites Esc innerhalb von 3 s bricht ab. Außerhalb einer Aufnahme wird Esc nicht angefasst.

**Neue Aufnahme während einer Umwandlung (AC-7):** Die Steuerung kennt nur ihre eigene Aufnahme; die Ablage reiht fertige Aufnahmen nach Nummer. PROJ-6 nimmt sie in dieser Reihenfolge ab. Die Menüleiste zeigt „nimmt auf“ vor „wandelt um“.

**Mikrofon wählen (AC-12, AC-13):** Beim Start wird das gewählte Gerät gesucht. Fehlt es → Systemmikrofon, Hinweis mit beiden Namen, Wahl bleibt gespeichert. Die Liste in den Einstellungen aktualisiert sich, wenn Geräte an- oder abgesteckt werden.

**Mikrofon-Erlaubnis fehlt (AC-15):** Vor dem Öffnen fragt die Steuerung den Erlaubnis-Wächter (PROJ-3). Fehlt sie → keine Aufnahme, Hinweis mit Knopf „Jetzt erlauben“, der dieselbe Handlung wie in PROJ-3 auslöst.

**Unterbrechungen (EC-2 bis EC-4):** Mikrofon getrennt, Ruhezustand, Bildschirm gesperrt, freier Speicher unter 200 MB (Prüfung beim Start und alle 10 s) → normal beenden wie Loslassen, aber ohne Stille-Regel für die Mindestdauer; Hinweis nach Grund.

**Einführungsschritt (AC-19, AC-20):** Schritt-Kennung `shortcut`, Reihenfolge 60, gilt nicht automatisch als erledigt. Solange er offen ist, nimmt das Kürzel nur Probe-Aufnahmen auf (sonst nimmt es während der Einführung nichts auf, EC-6). Eine Probe gilt als gelungen, wenn sie die Regeln aus Schritt 5 besteht. Dann erscheint „Klappt. Dein Mikrofon funktioniert.“, „Weiter“ wird frei, die Datei wird gelöscht. Die Pegelanzeige zeigt den gemessenen Pegel live.

**Kürzel ändern (AC-16 bis AC-18):** Klick ins Kürzel-Feld → Feld wartet auf Tasten, der Wächter ist solange stumm. Erlaubte Eingabe → Belegt-Prüfung → speichern und sofort aktiv, sonst Meldung und altes Kürzel bleibt. Esc im Feld bricht die Eingabe ab.

## Abhängigkeiten

- Keine neuen Pakete. Apple-Frameworks: AVFoundation (Mikrofon, Datei), CoreAudio (Systemmikrofon und Geräteänderungen), CoreGraphics-Ereignisabgriff (Tasten), AppKit (Ruhezustand, Sperre), Carbon (Tastennamen, Belegt-Prüfung).

## Einstellungen, die der Nutzer macht

Keine in einem Dashboard. Die Erlaubnisse für Mikrofon und Bedienungshilfen erteilt der Nutzer schon in PROJ-3.

## Technische Entscheidungen

| Entscheidung | Begründung | Alternative | Nachteil | Datum |
| --- | --- | --- | --- | --- |
| Tasten über einen aktiven Ereignis-Abgriff von macOS (CGEventTap) statt über Carbon-Kürzel | Nur so lassen sich eine Zusatztaste allein (rechte ⌘), eine zweite Taste während des Haltens (EC-1) und ein abgefangenes Esc erkennen. Braucht die Bedienungshilfen-Erlaubnis, die PROJ-3 ohnehin verlangt | Carbon `RegisterEventHotKey` wie in der alten App plus passiver Monitor | Ohne Bedienungshilfen funktioniert kein Kürzel; macOS schaltet einen zu langsamen Abgriff ab, deshalb sofortiges Wiedereinschalten plus Protokoll | 2026-11-07 |
| Esc wird nur während einer Aufnahme abgefangen | Beantwortet die offene Frage der Spec: Esc bricht nur die Aufnahme ab und schließt nicht nebenbei ein Fenster im Programm | Esc durchlassen (passiv wie bei den Hinweisen in PROJ-2) | Während einer Aufnahme kann man Esc im Programm nicht nutzen | 2026-11-07 |
| Rechte ⌘ allein: Mikrofon erst nach 0,25 s Halten öffnen | Sonst ginge bei jedem ⌘C kurz das Mikrofon an (orange Anzeige von macOS, Startton). Der Startton sagt ohnehin, ab wann man sprechen soll (AC-4) | Mikrofon sofort beim Druck öffnen | Wer vor dem Startton spricht, verliert die ersten Silben; Kombinationen öffnen sofort | 2026-11-07 |
| Ohne Bedienungshilfen kein Hinweis beim Drücken | macOS meldet die Tasten dann gar nicht an InnoWhisper; PROJ-3 zeigt das fehlende Recht schon an der Menüleiste. Beantwortet die offene Frage der Spec | Zusätzlich Carbon-Kürzel nur für den Hinweis | Die Zusage aus PROJ-3 („Hinweis beim Drücken“) gilt nur für das Mikrofon, nicht für die Bedienungshilfen | 2026-11-07 |
| Mikrofon über AVCaptureSession mit Tonpaket-Ausgabe | Gerät lässt sich je Aufnahme wählen, ohne das Systemmikrofon umzustellen; jedes Tonpaket kommt einzeln an, daraus kommen Pegel, „Ton fließt“ und Sprachanteil; stört laufende Videocalls nicht (EC-7) | AVAudioEngine | Eigenes Schreiben der Datei nötig; AVCaptureSession braucht beim Öffnen etwas Zeit, die AC-4 mit 1 s abdeckt | 2026-11-07 |
| Datei als CAF, 16 kHz, Mono, unkomprimiert | Bleibt auch bei Abbruch oder Absturz lesbar (wichtig ohne Höchstdauer); 16 kHz ist genau das, was Whisper intern nutzt, also kein Qualitätsverlust; rund 1,9 MB pro Minute | m4a (AAC) wie in der alten App | Größere Dateien; das Verkleinern und Aufteilen für Groq übernimmt PROJ-6 | 2026-11-07 |
| Ein Zustandsautomat mit Generationszähler | Garantiert EC-8 und verhindert, dass eine späte Rückmeldung einer alten Aufnahme eine neue überschreibt (dieselbe Fehlerart wie BUG-1 in PROJ-4) | Mehrere Merker | — | 2026-11-07 |
| Echter Tastenzustand wird nachgefragt (bei jedem Ereignis und alle 0,5 s) | Garantiert EC-5: ein verlorenes Loslassen beendet die Aufnahme spätestens nach 0,5 s | Nur auf Ereignisse vertrauen | Kleiner Dauerabruf während einer Aufnahme | 2026-11-07 |
| Stille-Regeln aus der alten App übernommen: Mindestdauer 0,5 s, Sprachanteil 5 % bei Schwelle −35 dB | In der alten App bewährt; Sprachanteil statt Spitzenpegel, weil ein Tastenklick sonst als Sprache zählt | Nur Spitzenpegel | Sehr leise Sprecher könnten verworfen werden; Werte sind feste Größen und lassen sich nachjustieren | 2026-11-07 |
| Belegt-Prüfung: Kürzel von macOS (Datei der Systemkürzel lesen) plus Probe-Anmeldung über Carbon | Erkennt Spotlight, Mission Control und Kürzel anderer Programme, die Carbon nutzen; beantwortet die offene Frage der Spec | Keine Prüfung | Kürzel, die andere Programme anders abfangen, werden nicht erkannt; Zusatztaste allein wird nicht geprüft | 2026-11-07 |
| Hinweis mit Knopf als kleine Ergänzung in PROJ-2 | AC-15 verlangt „Jetzt erlauben“ im Hinweis; ein Knopf ist für spätere Features (z. B. „Erneut versuchen“) ebenfalls nützlich | Nur Text, Lösung über die Menüleiste | Kleine Änderung an einem freigegebenen Modul; Hinweise ohne Knopf bleiben gleich | 2026-11-07 |
| Bereich `hotkeys` heißt sichtbar „Aufnahme“ | Die Spec nennt den Bereich „Aufnahme“, weil auch das Mikrofon dort steht; Kennung bleibt, damit nichts anderes bricht | Neuer Bereich neben „Tastenkürzel“ | Kleine Änderung am Rahmen aus PROJ-1 (nur der Anzeigename) | 2026-11-07 |
| Platzhalter-Ablage bis PROJ-6 behält nur die letzte Aufnahme | Ohne Umwandlung würden sich sonst Dateien sammeln; die letzte reicht zum Nachweis von AC-6 | Alles behalten | Keine Wiederherstellung älterer Aufnahmen vor PROJ-10 | 2026-11-07 |
| Bezug: ADR-002 (kein Backend), ADR-006 (kein Datenschutzrecht eingetragen), ADR-007 (keine App-Sandbox: Ereignis-Abgriff und Systemkürzel-Datei sind ohne Sandbox erreichbar) | — | — | — | 2026-11-07 |

## Offene Fragen

- Keine neuen. Die offenen Fragen der Spec sind oben beantwortet (Esc, Bedienungshilfen, Belegt-Prüfung); die Reihenfolge beim Einfügen bleibt Sache von PROJ-6 und PROJ-7.

## Bau-Notizen

Live-Test Teil 1 am 07.11.2026 mit Timur (Shure MV6 und Systemmikrofon), ausgewertet über `~/Library/Logs/InnoWhisper/InnoWhisper.log`.

- **Startton (AC-4):** Ton fließt 85 bis 187 ms nach dem Öffnen des Mikrofons (über 20 Aufnahmen), also weit unter 1 s.
- **Einführungsschritt (AC-19, AC-20):** Probe gelungen, Datei gelöscht, Schritt erledigt; der Schritt passt in das 540 Punkte hohe Fenster (Test).
- **Esc (AC-8), Stille (AC-11), ⌘C (EC-1):** wie erwartet. Bei rund 20 schnellen ⌘C/⌘V öffnete das Mikrofon einmal und wurde sofort verworfen (rechte ⌘ länger als 0,25 s vor dem C gehalten).
- **Korrektur 1, zweiter Druck übersehen:** Die Entscheidungslogik merkte sich die rechte ⌘ manchmal als noch gehalten und ignorierte den nächsten Druck. Jetzt zählt jedes echte Drücken, und die gehaltenen Zusatztasten kommen aus den Angaben des Ereignisses selbst. Test `secondPressWorksEvenWhenTheKeyWasStillCountedAsHeld`. Danach sechs Aufnahmen hintereinander ohne Ausfall.
- **Korrektur 2, ⌘ Leertaste im Kürzel-Feld:** macOS öffnet damit Spotlight, bevor InnoWhisper die Leertaste sieht; das Feld speicherte die linke ⌘ allein. Verliert das Einstellungsfenster während der Eingabe die Tastatur, gilt das Kürzel jetzt als belegt (AC-18). Live bestätigt.
- **Korrektur 3, leise Sprache verworfen:** Drei leise gesprochene Aufnahmen erreichten nur etwa −35 dB und fielen unter die feste −35-dB-Grenze. Abweichung vom Entwurf: Sprache wird jetzt gegen das Hintergrundgeräusch derselben Aufnahme gemessen (10-%-Wert der Tonpakete plus 12 dB, höchstens −35 dB, mindestens −65 dB). Gemessen danach: Stille mit Klopfen 2 bis 3 % Sprachanteil bei Hintergrund −83 bis −91 dB (verworfen), Sprache 65 bis 69 % (behalten). Der Abstand zur 5-%-Grenze ist bei Klopfen knapp; bei Bedarf wird die Grenze nachjustiert.
- **Abweichung Datenmodell:** Neben der Kennung des gewählten Mikrofons wird auch sein Name gespeichert (`recording.microphoneName`), weil macOS ein abgestecktes Mikrofon nicht benennen kann und AC-13 den Namen braucht.
- **Protokoll:** Jede Aufnahme schreibt Dauer, Sprachanteil, lautesten Wert und Hintergrund in dB, nie Ton oder Text.
- **Live-Test Teil 2 übersprungen (Entscheidung Timur, 07.11.):** Nicht live geprüft sind die 10-Minuten-Aufnahme (AC-6), Esc nach 30 s (AC-9), Mikrofon abstecken (EC-2), fehlendes Wunschmikrofon (AC-13), Ruhezustand und Bildschirmsperre (EC-3), stummes Mikrofon (AC-14), Aufnahme während eines Videocalls (EC-7) und der Modus „Ein/aus“ (AC-3). Belegt sind sie nur durch Tests mit Attrappen und die Dateitests (10 Minuten ohne Lücke). Die 10-Minuten-Aufnahme soll vor dem Umzug des Teams einmal echt gemacht werden (Pflichtpunkt 2).
- **Korrekturen nach `/qa` (07.11.):**
  - BUG-1: Kürzel-Wächter und Steuerung bleiben jetzt im Gleichschritt. Ein abgelehnter Start und ein Esc ohne Aufnahme setzen den Wächter zurück. Ein neues Kürzel oder ein neuer Modus gilt erst nach der laufenden Aufnahme. Ein Klick ins Kürzel-Feld beendet eine laufende Aufnahme zuerst normal.
  - BUG-2: Eine gelungene Probe wird gespeichert (`recording.probeSucceeded`, Abweichung im Datenmodell), damit „Fertig“ nach einem Neustart nicht zur Probe zurückspringt.
  - BUG-3: ⌘ oder ⇧⌘ mit jeder Taste außer F1 bis F12 und Leertaste gilt als belegt (Standardkürzel der Programme).
  - BUG-10: Ein dunkler Bildschirm beendet keine Aufnahme mehr; nur Ruhezustand, Benutzerwechsel und Bildschirmsperre. Während einer Aufnahme verhindert InnoWhisper, dass Mac und Bildschirm von selbst schlafen gehen.
- **Korrekturen nach der Nachprüfung (07.11.):**
  - BUG-3, zweite Runde: Zusätzlich gelten Apples Kürzel mit ⌥⌘ und ⌃⌘ sowie unveränderte macOS-Kürzel (⌘F5 VoiceOver, ⌥⌘D Dock, ⌃⌘Q Sperren …) als belegt; ⌘ mit F13 bis F19 ist frei.
  - BUG-12: Der Mac bleibt nur wach, solange in den letzten 2 Minuten Sprache zu hören war (Pegel ab etwa −45 dB). Eine vergessene Aufnahme lässt Mac und Bildschirm danach wieder schlafen und sperren; die Sperre beendet die Aufnahme (EC-3).
  - BUG-13: Kürzel- und Modusänderungen gehen über `ShortcutFollower` immer als letzte Wahl an den Wächter; der Abgleich gegen den gerade wirksamen Modus ist weg.
