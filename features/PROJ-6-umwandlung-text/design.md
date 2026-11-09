# PROJ-6 — Technischer Entwurf

> Grundlage: `spec.md` (AC-1 bis AC-21, EC-1 bis EC-7). Plattform: native Mac-App (`.ai-eng-kit` → `platform: desktop`), kein Backend (ADR-002), Groq als einziger Anbieter (ADR-003), keine passende Stack-Mappe unter `docs/stacks/`. Gebaut wird nach den Mustern der vorhandenen Module (`GroqAccess` für den Groq-Aufruf, `Recording` für Ablage und Steuerung).
> Entfallen, weil die Plattform sie nicht hat: Server-Zugriffsregeln, HTTP-Routen, Formulare, Bremsen für Anmeldungen (es wird keine Zugangsprüfung gemacht; der Schlüssel wird nur mitgeschickt). Bestehen bleibt: Antworten von Groq als fremde Eingabe prüfen (SEC-02, SEC-07), Schlüssel nur aus dem Schlüsselbund und nie im Protokoll (SEC-01), Tests je Verhalten mit einer Attrappe statt echter Groq-Aufrufe.

## Komponenten

```
InnoWhisper (Menüleisten-App)
+-- Aufnahme (PROJ-5) ──► übergibt jede fertige Aufnahme
+-- Umwandlungs-Warteschlange (neu, Modul Transcription)
|   +-- nimmt Aufnahmen in Sprech-Reihenfolge an (ersetzt den Platzhalter aus PROJ-5)
|   +-- je Aufnahme ein Auftrag: wartet → wandelt um → fertig / gescheitert → weitergegeben
|   +-- gibt fertige Texte streng in Reihenfolge weiter; gescheiterte halten nicht auf (AC-8, AC-9)
|   +-- Zustand "wandelt um" an der Menüleiste, Problem "nicht umgewandelt" mit "Erneut versuchen"
+-- Aufteiler (neu)
|   +-- liest die Aufnahme-Datei, schneidet sie in Teile von etwa 5 Minuten an leisen Stellen
|   +-- verkleinert jedes Teil verlustfrei (FLAC) für das Hochladen
+-- Groq-Umwandler (neu, Adapter)
|   +-- schickt ein Teil an Groq, mit Modell, Sprache und Schlüssel
|   +-- übersetzt jede Antwort in: Text mit Abschnitten / Schlüssel abgelehnt / Grenze erreicht /
|       kein Internet / vorübergehender Fehler / unbrauchbare Antwort
+-- Textfilter (neu, rein, testbar)
|   +-- wirft Abschnitte weg, die Groq selbst als "wahrscheinlich keine Sprache" markiert
|   +-- verwirft Ergebnisse, die nur aus einem bekannten erfundenen Satz bestehen
|   +-- entfernt Untertitel-Sätze überall
+-- Aufnahme-Liste (neu, gespeichert)
|   +-- merkt sich, welche Aufnahmen noch umzuwandeln sind und welche 50 gelungenen bleiben
|   +-- Grundlage für das Nachholen nach einem Neustart (AC-20)
+-- Übergabe des Textes (neu)
|   +-- bis PROJ-7: Zwischenablage plus Hinweis „Text in der Zwischenablage.“
|   +-- Nachgeholtes: immer Zwischenablage plus „Nachgeholtes Diktat in der Zwischenablage.“
+-- Einstellungsbereich "Aufnahme" (PROJ-5) bekommt die Gruppe "Umwandlung"
    +-- Modell: Schnell (ab Werk) / Genauer
    +-- Sprache: Deutsch (ab Werk) / Englisch / Automatisch
```

## Code-Aufbau

| Modul / Pfad | Aufgabe und Schnittstelle | Darf benutzen |
| --- | --- | --- |
| `Sources/Transcription/` (neues Modul) | **Umwandlung.** Bietet: die Warteschlange als Empfänger fertiger Aufnahmen (`RecordingConsumer` aus PROJ-5), `start()` (Nachholen beim Start), „alle gescheiterten erneut versuchen“, die Einstellungsgruppe „Umwandlung“. Bekommt von der App: Schlüssel lesen, „Schlüssel wurde abgelehnt“ melden, Schlüssel-Einstellungen öffnen, Hinweise, Probleme, Aktivität | `AppShell`, `Diagnostics`, `Notices`, `Recording`; Apple: Foundation (URLSession), AVFoundation/AudioToolbox (Lesen, Schneiden, FLAC), AppKit (Zwischenablage), SwiftUI |
| `Sources/Transcription/Queue/` | Warteschlange mit Aufträgen und ihrem Zustand (rein bis auf die Uhr, testbar), Aufnahme-Liste (gespeichert) | wie oben |
| `Sources/Transcription/Audio/` | Aufteiler: Datei lesen, leise Schnittstellen finden, Teile als FLAC schreiben, Teil-Dateien wieder löschen | wie oben |
| `Sources/Transcription/Groq/` | Schnittstelle „ein Teil umwandeln“ plus der echte Groq-Adapter (Anfrage bauen, Antwort prüfen und übersetzen). Tests nehmen eine Attrappe | wie oben |
| `Sources/Transcription/Text/` | Textfilter (rein, testbar), Zusammensetzen der Teile | wie oben |
| `Sources/Transcription/Delivery/` | Übergabe an die Zwischenablage mit Hinweis; Schnittstelle, die PROJ-7 später für Live-Diktate ersetzt | wie oben |
| `Sources/Transcription/UI/` | Einstellungsgruppe „Umwandlung“ mit zwei Auswahlfeldern, gleiche Bausteine und Größen wie die Gruppen „Tastenkürzel“ und „Mikrofon“ daneben | wie oben |
| `Sources/AppShell/State/DictationActivity.swift` | **Kleine Ergänzung an PROJ-1:** `ActivityCenter` hält zwei getrennte Tatsachen, „nimmt auf“ (setzt die Aufnahme) und „wandelt um“ (setzt die Umwandlung). Angezeigt wird: nimmt auf vor wandelt um vor bereit. Bisher konnte das Ende einer Aufnahme „bereit“ setzen, während noch umgewandelt wurde | wie bisher |
| `Sources/Recording/Session/RecordingController.swift` | Setzt nur noch die Tatsache „nimmt auf“ (zwei Stellen) | wie bisher |
| `Sources/Recording/Session/RecordingStorage.swift` | `removeLeftovers` bekommt eine Liste von Dateinamen, die beim Start **nicht** gelöscht werden (noch umzuwandeln oder unter den letzten 50) | wie bisher |
| `Sources/Diagnostics/LogFile.swift` | Neuer Protokoll-Bereich `transcription` | wie bisher |
| `App/AppEnvironment.swift` | Erzeugt die Umwandlung, setzt sie als Empfänger in die Aufnahme-Ablage, liest beim Start die Aufnahme-Liste vor `removeLeftovers`, verbindet Schlüssel (GroqAccess), Hinweise, Probleme, Aktivität; der Bereich „Aufnahme“ zeigt die Gruppen aus Recording und darunter „Umwandlung“ | alle Module |
| `Tests/TranscriptionTests/` | Tests mit Swift Testing; Groq, Uhr und Zwischenablage über Attrappen, Aufteiler mit echten kleinen Test-Dateien | `Transcription` |

Der Platzhalter `PlaceholderConsumer` aus PROJ-5 bleibt für die Tests von Recording bestehen, die App nutzt ihn nicht mehr.

## Footprint

- **Code und Tests:** `Packages/InnoWhisperKit/Sources/Transcription/` (neu), `Tests/TranscriptionTests/` (neu); kleine Ergänzungen in `AppShell/State/DictationActivity.swift`, `Recording/Session/RecordingController.swift`, `Recording/Session/RecordingStorage.swift`, `Diagnostics/LogFile.swift`, `App/AppEnvironment.swift`, `Package.swift`, dazu die betroffenen bestehenden Tests
- **Gespeicherte Daten:** Einstellungen `transcription.model`, `transcription.language` und die Aufnahme-Liste `transcription.recordings` in UserDefaults; Aufnahme-Dateien bleiben im Ordner aus PROJ-5; Teil-Dateien kurzzeitig im temporären Ordner des Systems. **Kein Text wird gespeichert.**
- **Umgebungsvariablen:** keine
- **Pakete:** keine neuen (nur Apple-Frameworks)
- **Andockstellen:** Empfänger der Aufnahme-Ablage (`RecordingQueue.consumer`), Menüleisten-Zustand (`ActivityCenter`), Problem-Liste (`ProblemCenter`), Hinweise mit Knopf (PROJ-2), Schlüsselbund und Schlüssel-Zustand (PROJ-4), Einstellungsbereich „Aufnahme“; externer Dienst: Groq `https://api.groq.com/openai/v1/audio/transcriptions`
- **Erlaubnisse von macOS:** keine neue (Netzwerk und Zwischenablage brauchen ohne App Sandbox keine, ADR-007)

## Qualität und Fehlerverhalten

| AC/EC | Bedingung und messbare Grenze | Mechanismus | Geplanter Nachweis |
| --- | --- | --- | --- |
| AC-5 | Diktat bis 30 s: Text unter 3 s nach dem Loslassen | Ein Teil, FLAC (rund 0,5 MB), Modell „Schnell“, Sprache fest; keine Wartezeit vor dem Hochladen | Protokoll misst „Aufnahme übergeben“ bis „Text weitergegeben“; live 10 kurze Diktate auf zwei Macs, alle unter 3 s |
| AC-6 | 10 Minuten: Text unter 1 Minute | Zwei Teile à etwa 5 Minuten, gleichzeitig hochgeladen (höchstens 3 Anfragen auf einmal) | Live-Aufnahme 10 Minuten auf zwei Macs, Dauer aus dem Protokoll |
| AC-7 | Keine fehlenden, keine doppelten Wörter an Übergängen | Schnitt nur an leisen Stellen (Suchfenster ±20 s um jede 5-Minuten-Marke, leisestes 0,5-s-Stück), keine Überlappung; Teile werden in ihrer Reihenfolge zusammengesetzt | Test mit Attrappe (Reihenfolge, Zusammensetzen); Test mit erzeugter Datei (Schnitt liegt im leisesten Stück, Summe der Teile = ganze Länge); live 10-Minuten-Aufnahme gelesen |
| AC-10, AC-11 | Zweimal still neu, dann Hinweis | Je Teil: vorübergehender Fehler oder kein Internet → nach 1 s und nach 3 s noch einmal; danach Auftrag „gescheitert“ | Test mit Attrappe: Fehler-Fehler-Erfolg = kein Hinweis; dreimal Fehler = Hinweis, Problem, Datei bleibt |
| AC-14 | Grenze erreicht: bis 2 min selbst warten | Antwort 429: Wartezeit aus Groqs Angabe `retry-after`; bis 120 s warten und erneut versuchen (zählt nicht als stiller Versuch), länger → Hinweis mit Minuten | Test mit Attrappe (30 s → wartet und klappt; 300 s → Hinweis „5 Minuten“) |
| AC-15 bis AC-17 | Nichts erfinden | Groq liefert je Abschnitt eine Schätzung „keine Sprache“; Abschnitte mit „keine Sprache“ über 0,6 **und** geringer Sicherheit (mittlere Wortwahrscheinlichkeit unter −1,0) fallen weg; danach Satzliste und Untertitel-Muster; kein Hinweistext an Groq (kein „prompt“), Temperatur 0 | Tests des Filters mit festen Beispielen; AC-17 und AC-18 live mit 20 Diktaten (Prüfplan unten) |
| AC-20 | Nachholen nach Neustart | Aufnahme-Liste in UserDefaults; Start liest sie vor dem Aufräumen der Aufnahme-Dateien | Test: Liste mit zwei offenen Einträgen → beide umgewandelt, ein Text mit Leerzeile, Hinweis „Nachgeholtes …“ |
| EC-4 | Kaputte Datei | Aufteiler meldet „nicht lesbar“ → Hinweis, Datei und Eintrag weg, Auftrag gilt als erledigt ohne Text | Test mit einer Datei aus Zufallsbytes |

**Fehlerarten an der Groq-Schnittstelle** (der Adapter übersetzt, nichts Rohes gelangt nach oben):

| Antwort von Groq / System | Bedeutung | Verhalten |
| --- | --- | --- |
| 200 mit gültigem Inhalt | Erfolg | Abschnitte an den Filter |
| 200 mit unbrauchbarem Inhalt (kein JSON, Text fehlt, Text über 20 000 Zeichen je Teil) | unbrauchbare Antwort | wie vorübergehender Fehler (zählt als Versuch) |
| 401, 403 | Schlüssel abgelehnt | kein weiterer Versuch; AC-13 |
| 429 | Grenze erreicht | AC-14 |
| keine Verbindung (kein Netz, Netz verloren, Name nicht auflösbar) | kein Internet | stille Versuche; Hinweis mit „Keine Internetverbindung …“ |
| Zeitüberschreitung, 5xx, sonstiger Netzfehler | vorübergehender Fehler | stille Versuche; Hinweis „Umwandlung fehlgeschlagen …“ |
| 400, 413, 415, andere 4xx | Fehler im eigenen Aufruf (Programmfehler) | kein stiller Versuch, Hinweis „Umwandlung fehlgeschlagen …“, Protokoll mit Status als Fehler |
| kein Schlüssel im Schlüsselbund | Schlüssel fehlt | gar nicht erst hochladen; AC-12 |

**Zeitlimit je Teil:** 20 Sekunden plus 10 Sekunden je Minute Ton (5-Minuten-Teil: 70 s). Die alte App hatte feste 30 Sekunden für die ganze Aufnahme; das ist die vermutete Ursache von Pflichtpunkt 2.

## Datenmodell

**Einstellungen (UserDefaults):**
- `transcription.model` — Text, eins von `fast` (ab Werk) oder `accurate`. Im Adapter übersetzt: `fast` → `whisper-large-v3-turbo`, `accurate` → `whisper-large-v3`. Unbekannter Wert → `fast`.
- `transcription.language` — Text, eins von `de` (ab Werk), `en` oder `auto`. `auto` schickt keine Sprache mit. Unbekannter Wert → `de`.
- Eine Änderung gilt ab der nächsten Aufnahme, die fertig wird; jeder Auftrag merkt sich beim Eintreffen Modell und Sprache (AC-4).

**Aufnahme-Liste (UserDefaults `transcription.recordings`, Liste, höchstens 50 umgewandelte plus alle offenen):**
Je Eintrag:
- Dateiname — Text, der Name der CAF-Datei im Aufnahme-Ordner (UUID plus `.caf`), Pflicht, eindeutig
- Gesprochen ab — Zeitpunkt (Start der Aufnahme), Pflicht; bestimmt die Reihenfolge über Neustarts hinweg
- Dauer — Sekunden als Kommazahl, Pflicht, größer 0
- Stand — eins von `offen` (noch nicht umgewandelt oder gescheitert) oder `umgewandelt`
- Umgewandelt am — Zeitpunkt, nur bei `umgewandelt`

Regeln:
- Ein Eintrag entsteht, sobald die Aufnahme bei der Umwandlung ankommt (Stand `offen`).
- Nach Erfolg wird er `umgewandelt`. Gibt es danach mehr als 50 `umgewandelt`, werden die ältesten (nach „Umgewandelt am“) samt Datei gelöscht (AC-19). `offen` zählt nie mit und wird nie automatisch gelöscht.
- Bei „Nichts erkannt“ (AC-15) und bei kaputter Datei (EC-4) werden Eintrag und Datei gelöscht.
- Beim Start: Einträge, deren Datei fehlt, fallen weg; Dateien im Ordner ohne Eintrag sind Reste eines Absturzes und werden wie bisher gelöscht (PROJ-5).
- Gespeichert wird **kein Text** und kein Modell. Der Verlauf (PROJ-10) übernimmt später diese Liste und ergänzt den Text.
- Zugriff: nur InnoWhisper auf diesem Mac, Rechte des angemeldeten Nutzers (ADR-007). Aufbewahrung: die letzten 50 gelungenen, offene bis sie umgewandelt sind.

**Aufträge (nur im Speicher, nie gespeichert):**
- Reihenfolge-Nummer (aus PROJ-5, je App-Start) bzw. beim Nachholen die Reihenfolge nach „Gesprochen ab“
- Zustand — eins von: `wartet`, `wandelt um`, `fertig` (Text liegt bereit), `gescheitert` (Fehlerart), `weitergegeben` (mit oder ohne Text)
- Erlaubte Wechsel: wartet → wandelt um → fertig → weitergegeben; wandelt um → gescheitert → (Erneut versuchen) wandelt um; wandelt um → weitergegeben ohne Text (Nichts erkannt, kaputte Datei). Nie zurück aus `weitergegeben`.
- Fertige Teile eines Auftrags bleiben im Speicher, bis alle Teile da sind; „Erneut versuchen“ wandelt nur die fehlenden Teile um (EC-3).
- Modell und Sprache des Auftrags (beim Eintreffen festgehalten)
- Ob es ein nachgeholter Auftrag ist (bestimmt die Übergabe: immer Zwischenablage, AC-20)

**Teil-Dateien:** FLAC, 16 kHz, Mono, im temporären Ordner des Systems, je Auftrag eigener Unterordner; gelöscht, sobald der Auftrag weitergegeben ist oder die App startet.

## Abläufe

**Neue Aufnahme kommt an (AC-1):** Eintrag `offen` in der Aufnahme-Liste → Auftrag `wartet` → Aufteiler → Teile an Groq (höchstens 3 Anfragen gleichzeitig über alle Aufträge, ältere Aufträge zuerst) → Filter → Teile zusammensetzen (Leerzeichen dazwischen, Ränder bereinigt) → Auftrag `fertig`.

**Weitergeben (AC-3, AC-8, AC-9):** Nach jedem Wechsel prüft die Warteschlange von vorn: Der vorderste Auftrag, der nicht `weitergegeben` ist, entscheidet. Ist er `fertig` → weitergeben und weiter prüfen. Ist er `gescheitert` → überspringen (er hält nicht auf), weiter prüfen. Ist er `wartet` oder `wandelt um` → stoppen, alles dahinter wartet. Ein gescheiterter Auftrag, der später klappt, wird dann sofort weitergegeben (AC-9).

**Erneut versuchen:** Knopf im Hinweis und im Problem an der Menüleiste. Wandelt alle Aufträge im Zustand `gescheitert` um (bei fehlendem Schlüssel zuerst prüfen, ob jetzt einer da ist). Aufträge in einem anderen Zustand werden nicht angefasst (EC-2).

**Menüleiste und Problem:** „wandelt um“, solange mindestens ein Auftrag `wartet` oder `wandelt um`. Ein Problem mit der Kennung `transcriptionFailed` („1 Diktat nicht umgewandelt.“ / „N Diktate nicht umgewandelt.“, Knopf „Erneut versuchen“, nur Menüleisten-Fenster), solange mindestens ein Auftrag `gescheitert` ist; es verschwindet mit dem letzten.

**Schlüssel abgelehnt (AC-13):** Hinweis „Groq lehnt den Zugangsschlüssel ab.“ mit „Schlüssel prüfen“ (öffnet die Schlüssel-Einstellungen). Gleichzeitig ruft die App die vorhandene Prüfung des gespeicherten Schlüssels auf (PROJ-4); bestätigt Groq dort die Ablehnung, wird er „ungültig“ und PROJ-4 zeigt sein eigenes Problem. So bleibt PROJ-4 der einzige Ort, der den Schlüssel-Zustand setzt.

**Nachholen beim Start (AC-20, EC-6):** Die App liest die Aufnahme-Liste, räumt den Aufnahme-Ordner auf (ohne die Dateien der Liste), dann wandelt die Umwandlung alle `offen`-Einträge nach „Gesprochen ab“ um. Klappen alle, kommt ein Text (Leerzeile dazwischen) in die Zwischenablage mit „Nachgeholtes Diktat in der Zwischenablage.“ Scheitert einer, gilt AC-11 für ihn; klappt er später, kommt sein Text ebenfalls mit „Nachgeholtes …“ in die Zwischenablage. Was vor dem Beenden schon weitergegeben war, ist `umgewandelt` und wird nicht wiederholt.

**Was an Groq geht:** das Ton-Teil, Modell, Sprache (außer bei „Automatisch“), Temperatur 0, Antwortformat mit Abschnitten, der Schlüssel als Kopfzeile. Kein Hinweistext, kein Name, keine Datei-Kennung.

**Was ins Protokoll geht (AC-21):** Auftrag-Nummer, Modell, Sprache, Dauer der Aufnahme, Anzahl Teile, Zeit bis fertig, Fehlerart, HTTP-Status, Anzahl Versuche, ob Filter etwas entfernt hat (nur ja/nein und Anzahl Abschnitte). Nie Ton, Text, Schlüssel oder Dateiname.

## Abhängigkeiten

Keine neuen Pakete. Apple-Frameworks: Foundation (URLSession, mehrteiliges Hochladen), AVFoundation/AudioToolbox (CAF lesen, FLAC schreiben), AppKit (Zwischenablage), SwiftUI.

## Settings the user makes

Keine Einstellung bei einem Anbieter nötig. Hinweis: Timur kann unter `console.groq.com/settings/limits` die Grenzen seines Kontos nachsehen (Offene Frage in `spec.md`); das ändert den Bau nicht, nur wie oft AC-14 im Alltag vorkommt.

## Prüfplan für AC-17 und AC-18 (live, nach dem Bau)

1. Timur diktiert 20 echte deutsche Diktate mit Modell „Schnell“ auf zwei Macs: mindestens 5 mit Stille am Ende, mindestens 3 länger als 2 Minuten, mit Namen aus dem Alltag.
2. Er liest jeden Text aus der Zwischenablage und notiert: erfundenes „Ich“ am Anfang, angehängter Satz, sinnentstellendes Klang-Wort.
3. Danach 10 der Diktate-Arten noch einmal mit „Genauer“. Ist „Genauer“ dort klar besser (weniger Fehler aus Schritt 2), wird das Modell ab Werk umgestellt (Entscheidung in `spec.md`).
4. Ergebnis kommt in den Prüfbericht. Die Texte selbst werden nirgends gespeichert.

## Technical Decisions

| Decision | Rationale | Alternative considered | Trade-off | Date |
|----------|-----------|------------------------|-----------|------|
| Eigenes Modul `Transcription`, abhängig von `Recording`, nicht von `GroqAccess` | Schlüssel lesen und „abgelehnt“ melden kommen als Funktionen von der App; so bleibt PROJ-4 der einzige Ort für den Schlüssel-Zustand | Direkt `GroqAccess` benutzen | Die App muss drei kleine Funktionen verdrahten | 2026-11-07 |
| Teile von etwa 5 Minuten, geschnitten an der leisesten Stelle im Fenster ±20 s, ohne Überlappung | Groq nimmt sicher 25 MB je Datei an (neuere Seiten nennen 100 MB, für das Konto unbestätigt); 5 Minuten FLAC sind rund 5 MB, weit darunter. Schnitt in einer Pause verhindert halbe und doppelte Wörter (AC-7) | Feste Schnitte mit Überlappung und Abgleich doppelter Wörter | Findet sich im Fenster keine echte Pause (Dauerrede), kann ein Wort halbiert werden; selten, weil Sprechen Atempausen hat | 2026-11-07 |
| FLAC statt WAV fürs Hochladen | Verlustfrei, rund halb so groß, schnelleres Hochladen (AC-5, AC-6); von Groq unterstützt | WAV (keine Umwandlung nötig) | Umwandeln kostet etwas Rechenzeit; klappt FLAC-Schreiben mit Apples Bordmitteln beim Bau nicht, wird WAV mit 4-Minuten-Teilen genommen (wird im ersten Bau-Schritt geprüft) | 2026-11-07 |
| Höchstens 3 Anfragen gleichzeitig | AC-6 braucht Gleichzeitigkeit; Groq erlaubt laut Angaben 20 Anfragen pro Minute | Alles nacheinander | Bei vielen langen Diktaten hintereinander kann die Stunden-Grenze für Ton schneller erreicht werden; dann greift AC-14 | 2026-11-07 |
| Zeitlimit je Teil 20 s plus 10 s je Minute Ton | Lange Teile brauchen länger zum Hochladen; feste 30 s waren vermutlich die Ursache von Pflichtpunkt 2 | Feste 30 s wie in der alten App | Bei totem Netz dauert es bis zu 70 s je Versuch, bis ein langer Teil als gescheitert gilt | 2026-11-07 |
| Erfundenes über Groqs Abschnitts-Werte erkennen (keine Sprache über 0,6 und mittlere Wortwahrscheinlichkeit unter −1,0), danach Satzliste und Untertitel-Muster | Die Abschnitts-Werte fangen angehängte Sätze in Stille ab, egal wie sie lauten (Pflichtpunkt 6); die Satzliste fängt die bekannten Fälle; die Grenzwerte sind die üblichen Werte von Whisper | Nur die Satzliste wie in der alten App | Echte, sehr leise gesprochene Abschnitte könnten wegfallen; wird mit den 20 Diktaten geprüft und die Werte bei Bedarf angepasst | 2026-11-07 |
| Kein Hinweistext („prompt“) an Groq | Der Hinweistext der alten App mit dem Wörterbuch ist die vermutete Ursache für angehängte Begriffe und das „Ich“; das Wörterbuch kommt erst mit PROJ-9 und wird dort neu entschieden | Leeren Satz als Stil-Hinweis mitschicken | Ohne Hinweis schreibt Whisper Satzzeichen und Großschreibung nach eigenem Gefühl | 2026-11-07 |
| Temperatur 0 | Gleiche Aufnahme ergibt möglichst gleichen Text, weniger Raten | Standard von Groq | Keine | 2026-11-07 |
| Groq-Antwort als fremde Eingabe: Form prüfen, Text höchstens 20 000 Zeichen je Teil, Steuerzeichen außer Zeilenumbruch entfernen | SEC-07: Modell-Text ist nicht vertrauenswürdig; 5 Minuten Sprache sind etwa 5 000 Zeichen | Text ungeprüft übernehmen | Ein echter, extrem langer Teil würde als unbrauchbar gelten; praktisch ausgeschlossen | 2026-11-07 |
| Aufnahme-Liste in UserDefaults, ohne Text | Wenige kleine Einträge; überlebt Neustarts; kein Diktat-Inhalt auf der Platte (Datensparsamkeit, ADR-006 Hinweis) | Eigene Datei; Text gleich mitspeichern | PROJ-10 muss den Text später selbst dazulegen | 2026-11-07 |
| `ActivityCenter` hält „nimmt auf“ und „wandelt um“ getrennt | Sonst setzt das Ende einer neuen Aufnahme „bereit“, obwohl eine frühere noch umgewandelt wird (AC-1) | Umwandlung prüft und überschreibt den Zustand selbst | Kleine Änderung an PROJ-1 und PROJ-5 samt deren Tests | 2026-11-07 |
| **Garantie EC-2 und AC-8/AC-9 (Reihenfolge, nichts doppelt):** Alle Zustandswechsel der Aufträge laufen auf dem Haupt-Thread nacheinander; „Erneut versuchen“ greift nur bei `gescheitert` und setzt im selben Schritt `wandelt um`; ein zweiter Klick findet keinen gescheiterten Auftrag mehr. Weitergeben setzt erst `weitergegeben`, dann wird übergeben; aus `weitergegeben` gibt es keinen Weg zurück | Nur so ist ausgeschlossen, dass ein Text doppelt oder in falscher Reihenfolge ankommt | Sperren über mehrere Threads | Lange Arbeit (Hochladen, Schneiden) läuft im Hintergrund und meldet nur ihr Ergebnis an den Haupt-Thread zurück | 2026-11-07 |
| **Garantie EC-6 (nichts doppelt nach Neustart):** Der Eintrag wird `umgewandelt`, im selben Schritt, in dem der Text weitergegeben wird | Wird die App danach beendet, holt der Start nichts nach, was schon übergeben war | Erst nach Bestätigung durch PROJ-7 umstellen | Stürzt die App genau zwischen Übergabe und Speichern ab, kann ein Text fehlen statt doppelt zu kommen | 2026-11-07 |
| Nachgeholte Texte immer in die Zwischenablage, auch nach PROJ-7 | Spec AC-20; ins Feld wäre falsch, der Nutzer tut dort etwas anderes | — | — | 2026-11-07 |

## Open Questions

- [ ] Klappt das Schreiben von FLAC mit Apples Bordmitteln auf macOS 26? Wird im ersten Bau-Schritt geprüft; sonst WAV mit 4-Minuten-Teilen (siehe Entscheidungen).
- [ ] Liefert Groq im Antwortformat mit Abschnitten die Werte „keine Sprache“ und „mittlere Wortwahrscheinlichkeit“ bei beiden Modellen? Wird im Bau mit einer echten Antwort von Timurs Mac geprüft (Antwort ohne Text ins Protokoll: nur ob die Felder da sind). Fehlen sie, bleiben Satzliste und Untertitel-Muster.

## Bau-Notizen

- **FLAC klappt** mit Apples Bordmitteln (`AVAudioFile` mit FLAC, 16 kHz Mono), kein Rückfall auf WAV nötig (T4, 09.11.2026).
- **Schnittmarken:** Jede Marke liegt 5 Minuten nach dem vorigen Schnitt, nicht starr bei 5, 10, 15 Minuten ab Beginn. So bleiben alle Teile zwischen 4:40 und 5:20 lang. Bei gleich leisen Stellen gewinnt die nächste zur Marke; ein ganz stiller Abschnitt wird genau an der Marke geschnitten (EC-1).
- **Nicht lesbares Teil** (Datei fehlt beim Hochladen) zählt beim Groq-Anschluss als eigener Fehler ohne Status: kein stiller Versuch, Hinweis „Umwandlung fehlgeschlagen …“.
- **Leerer Text:** Ein Text nur aus Leerzeichen und Zeilenumbrüchen gilt als leer und wird nicht übergeben; ein Ergebnis, das nach dem Entfernen von Untertitel-Sätzen leer ist, behandelt die Warteschlange wie „Nichts erkannt“ (AC-15).
- **Einstellungsbereich „Aufnahme“:** `RecordingSettingsPane` nimmt weitere Abschnitte im selben Formular auf; die App hängt dort „Umwandlung“ an. Kleine Änderung in `Sources/Recording/UI/RecordingSettingsPane.swift`, die in `tasks.md` T9 nicht aufgeführt war.
- **Tests und iCloud:** Der Schreibtisch wird von iCloud abgeglichen; `swift test` bricht dann mit „was modified during the build“ ab. Abhilfe: Zwischendateien außerhalb des Schreibtischs, `swift test --package-path Packages/InnoWhisperKit --scratch-path "$HOME/Library/Developer/InnoWhisperKit-build"`.
- **Korrekturen nach der ersten Prüfung (09.11.):**
  - BUG-1 und BUG-4: Alles, was in einem Schritt fertig wird, geht zusammen und in Sprech-Reihenfolge in einer einzigen Übergabe raus (`TextDelivering.deliver(_ texts:)`). Die Zwischenablage hat nur Platz für einen Text, deshalb setzt sie mehrere Texte mit einer Leerzeile zusammen; der Hinweis lautet „Nachgeholtes …“, sobald einer davon nachgeholt war. PROJ-7 übernimmt später nur die Live-Texte.
  - BUG-2: Der Schlüssel wird erst gelesen, wenn ein Anfrage-Platz frei ist, also direkt vor dem Senden.
  - BUG-3: Als Untertitel-Satz gilt nur noch ein Satz, der mit „Untertitel…“ beginnt und die Amara.org-Community oder das ZDF als Ersteller nennt („Untertitel im Auftrag des ZDF“, „Untertitelung des ZDF für funk“), sowie jeder Satz mit „Amara.org community“.
  - BUG-3 (zweite Runde) und BUG-16 (Entscheidung Timur, 09.11.: Filter jetzt richtig): Erkannt wird nur noch der vollständige Wortlaut einer Abspann-Zeile (wer die Untertitel gemacht hat: ZDF, auch „für funk“ mit Jahr, oder die Amara.org-Community), und sie muss mit einem Satzzeichen, einem schließenden Anführungszeichen oder dem Textende abschließen. Davor dürfen Anführungszeichen, Klammer, Strich, Komma oder ein Abschnitt ohne Schlusspunkt stehen. Ein gesprochener Satz, der nur Untertitel, funk, ZDF oder Amara.org erwähnt, bleibt stehen.
  - BUG-3 (dritte Runde), BUG-16, BUG-19 (Entscheidung Timur, 09.11.: „Einfacher Weg“): Der Filter schneidet nie mehr etwas aus einem Satz heraus. Entfernt wird nur, was als ganzer Satz oder als ganzer Groq-Abschnitt genau einer Abspann-Zeile entspricht (ZDF mit „im Auftrag“, „für funk“ oder Jahr; Amara.org-Community, auch mit „aufgrund der“ oder „durch die“; englisch „Subtitles by the Amara.org community“). Anführungszeichen, Klammern, ein Strich und Satzzeichen drumherum zählen nicht; Sätze enden zusätzlich an schließenden Anführungszeichen, Klammern, „;“ und an jedem Zeilenumbruch. „Untertitel vom ZDF.“ allein bleibt stehen. Geprüft wird nur auf Zeilen bis 160 Zeichen und ohne regulären Ausdruck über den ganzen Text, deshalb kein Hängen mehr bei langen Leerraum-Läufen. Bewusst nicht entfernt: ein Abspann mitten in einem Satz (z. B. „Gut, Untertitel im Auftrag des ZDF. Weiter.“) und zwei Abspanne ohne Trennung im selben Abschnitt.
