# PROJ-6 Aufgaben

> Erstellt von `/tasks` aus `spec.md` + `design.md`. Geordneter, nachverfolgbarer Bauplan.
> `[P]` = parallel möglich: die Dateien der Aufgabe überschneiden sich mit keiner anderen `[P]`-Aufgabe derselben Stufe.
> Stufen laufen **nacheinander** (jede ist eine Schranke). Jede Aufgabe nennt die AC/EC-IDs aus `spec.md`, die sie erfüllt (AC → Aufgabe → Test).
> Owner: `/tasks` legt die Datei an; `/build` hakt ab. Keine `[user]`-Aufgaben (der Entwurf nennt keine Einstellung bei einem Anbieter).
> Live-Nachweise (AC-5, AC-6, AC-17, AC-18 mit echten Aufnahmen auf zwei Macs) gehören zu `/qa`, Prüfplan in `design.md`.
> Abkürzungen: `Kit/` = `Packages/InnoWhisperKit/`, `TR/` = `Kit/Sources/Transcription/`, `TRT/` = `Kit/Tests/TranscriptionTests/`, `RC/` = `Kit/Sources/Recording/`, `RCT/` = `Kit/Tests/RecordingTests/`.

## Stufe 1 — Grundlagen

- [x] T1 [P]  Modul `Transcription` (hängt von `AppShell`, `Diagnostics`, `Notices`, `Recording` ab) samt Testziel anlegen und ins Xcode-Projekt einhängen; Modul-Kopf mit festen Werten (Teil-Länge 5 min, Suchfenster ±20 s, leisestes Stück 0,5 s, höchstens 3 Anfragen, Zeitlimit 20 s + 10 s je Minute, stille Versuche nach 1 s und 3 s, Grenze-Wartezeit bis 120 s, höchstens 50 umgewandelte, 20 000 Zeichen je Teil, Filter-Werte 0,6 und −1,0, Groq-Adresse); Einstellungen `transcription.model` (`fast` ab Werk, `accurate`) und `transcription.language` (`de` ab Werk, `en`, `auto`) mit Rückfall bei unbekanntem Wert; alle Hinweistexte; Protokoll-Bereich `transcription`  · files: Kit/Package.swift, TR/Transcription.swift, TR/TranscriptionTexts.swift, Kit/Sources/Diagnostics/LogFile.swift, InnoWhisper.xcodeproj/project.pbxproj, TRT/TranscriptionSettingsTests.swift  · → AC-2, AC-4, AC-21
- [x] T2 [P]  `ActivityCenter` mit zwei getrennten Tatsachen „nimmt auf“ und „wandelt um“, angezeigt: nimmt auf vor wandelt um vor bereit; Aufnahme-Steuerung setzt nur noch „nimmt auf“  · files: Kit/Sources/AppShell/State/DictationActivity.swift, Kit/Tests/AppShellTests/StateTests.swift, RC/Session/RecordingController.swift, RCT/RecordingControllerTests.swift  · → AC-1
- [x] T3 [P]  Aufräumen beim Start mit Ausnahmeliste: `removeLeftovers` löscht keine Datei, deren Name auf der übergebenen Liste steht  · files: RC/Session/RecordingStorage.swift, RCT/RecordingQueueTests.swift  · → AC-20, EC-6

## Stufe 2 — Bausteine

- [ ] T4 [P]  Aufteiler: CAF lesen, bis 5:30 ein Teil, sonst Schnitte an der leisesten 0,5-s-Stelle im Fenster ±20 s um jede 5-Minuten-Marke, ohne Überlappung; Teile als FLAC in einen eigenen temporären Unterordner, Aufräumen der Teile; kaputte Datei als eigene Fehlerart. Zuerst prüfen, ob FLAC-Schreiben klappt; sonst WAV mit 4-Minuten-Teilen und Notiz in `design.md`  · files: TR/Audio/AudioSplitter.swift, TRT/AudioSplitterTests.swift  · → AC-6, AC-7, EC-1, EC-4
- [ ] T5 [P]  Groq-Anschluss: Schnittstelle „ein Teil umwandeln“ mit Ergebnis (Abschnitte mit Text, „keine Sprache“-Wert, Wortwahrscheinlichkeit) oder Fehlerart (Schlüssel abgelehnt, Grenze mit Wartezeit, kein Internet, vorübergehend, eigener Fehler, unbrauchbar); echter Adapter mit mehrteiliger Anfrage (Datei, Modell, Sprache außer „auto“, Temperatur 0, Antwortformat mit Abschnitten, kein Hinweistext), Zeitlimit je Teilänge, Antwort prüfen (Form, höchstens 20 000 Zeichen, Steuerzeichen weg); Attrappe für Tests; Protokoll ohne Text und Schlüssel  · files: TR/Groq/Transcribing.swift, TR/Groq/GroqTranscriber.swift, TRT/GroqTranscriberTests.swift  · → AC-5, AC-10, AC-12, AC-13, AC-14, AC-17, AC-18, AC-21
- [ ] T6 [P]  Textfilter und Zusammensetzen: Abschnitte mit „keine Sprache“ über 0,6 und Wortwahrscheinlichkeit unter −1,0 weg; ganzes Ergebnis nur ein bekannter erfundener Satz → leer; Untertitel-Sätze überall entfernen; Teile in Reihenfolge mit Leerzeichen verbinden, Ränder bereinigen  · files: TR/Text/TranscriptFilter.swift, TRT/TranscriptFilterTests.swift  · → AC-7, AC-15, AC-16, AC-17, EC-1
- [ ] T7 [P]  Aufnahme-Liste in UserDefaults: Eintrag (Dateiname, gesprochen ab, Dauer, Stand offen/umgewandelt, umgewandelt am), anlegen, umstellen, löschen, höchstens 50 umgewandelte (älteste samt Datei weg), offene nie automatisch; Einträge ohne Datei fallen beim Laden weg; Liste der zu behaltenden Dateinamen; unlesbare Liste → leer mit Protokoll  · files: TR/Queue/RecordingList.swift, TRT/RecordingListTests.swift  · → AC-19, AC-20, EC-6
- [ ] T8 [P]  Übergabe des Textes: Schnittstelle für Live- und nachgeholte Texte (PROJ-7 ersetzt später nur Live); Zwischenablage plus Hinweis „Text in der Zwischenablage.“ bzw. „Nachgeholtes Diktat in der Zwischenablage.“; Zwischenablage über Attrappe testbar  · files: TR/Delivery/TextDelivery.swift, TR/Delivery/ClipboardDelivery.swift, TRT/ClipboardDeliveryTests.swift  · → AC-3, AC-20
- [ ] T9 [P]  Einstellungsgruppe „Umwandlung“: Auswahl Modell (Schnell / Genauer) und Sprache (Deutsch / Englisch / Automatisch), gleiche Bausteine und Größen wie die Gruppen „Tastenkürzel“ und „Mikrofon“  · files: TR/UI/TranscriptionSettingsGroup.swift  · → AC-2, AC-4

## Stufe 3 — Warteschlange

- [ ] T10  Warteschlange als Empfänger fertiger Aufnahmen: Auftrag je Aufnahme mit Zustand (wartet, wandelt um, fertig, gescheitert, weitergegeben) und festgehaltenem Modell/Sprache; Eintrag in der Aufnahme-Liste; höchstens 3 Anfragen, ältere zuerst; stille Versuche (1 s, 3 s), Grenze bis 120 s selbst abwarten; fertige Teile im Speicher, „Erneut versuchen“ nur für fehlende Teile und nur bei `gescheitert`; Weitergeben streng von vorn, gescheiterte überspringen; „Nichts erkannt“ und kaputte Datei; Hinweise mit Knopf, Problem `transcriptionFailed`, „wandelt um“ an der Menüleiste; Schlüssel fehlt / abgelehnt über Funktionen der App; Protokoll ohne Inhalte  · files: TR/Queue/TranscriptionJob.swift, TR/Queue/TranscriptionQueue.swift, TRT/TranscriptionQueueTests.swift  · → AC-1, AC-3, AC-4, AC-6, AC-8, AC-9, AC-10, AC-11, AC-12, AC-13, AC-14, AC-15, AC-19, AC-21, EC-2, EC-3, EC-4, EC-5, EC-7

## Stufe 4 — Nachholen

- [ ] T11  Nachholen beim Start: offene Einträge nach „gesprochen ab“ umwandeln, alle gelungenen zu einem Text mit Leerzeile, Übergabe als nachgeholt; einzeln gescheiterte wie AC-11, später als nachgeholt übergeben; nichts doppelt, was schon umgewandelt war; temporäre Teil-Ordner beim Start löschen  · files: TR/Queue/TranscriptionRecovery.swift, TRT/TranscriptionRecoveryTests.swift  · → AC-20, EC-6

## Stufe 5 — Zusammenstecken

- [ ] T12  App-Verdrahtung: Umwandlung erzeugen und als Empfänger der Aufnahme-Ablage setzen (Platzhalter fällt weg); beim Start Aufnahme-Liste lesen, dann `removeLeftovers` mit Ausnahmeliste, dann Nachholen; Schlüssel aus dem Schlüsselbund lesen, „abgelehnt“ → vorhandene Prüfung des gespeicherten Schlüssels (PROJ-4), Knöpfe „Schlüssel eintragen“/„Schlüssel prüfen“ → Schlüssel-Einstellungen; Probleme, Hinweise, Aktivität; Bereich „Aufnahme“ zeigt unter den Gruppen aus PROJ-5 die Gruppe „Umwandlung“; einmalige Protokollzeile, ob Groqs Antwort die Abschnitts-Werte enthält (ohne Text)  · files: App/AppEnvironment.swift  · → AC-1, AC-2, AC-3, AC-12, AC-13, AC-20

## Abdeckung

AC-1 T2, T10, T12 · AC-2 T1, T9, T12 · AC-3 T8, T10, T12 · AC-4 T1, T9, T10 · AC-5 T5 (live in `/qa`) · AC-6 T4, T10 (live in `/qa`) · AC-7 T4, T6 · AC-8 T10 · AC-9 T10 · AC-10 T5, T10 · AC-11 T10 · AC-12 T5, T10, T12 · AC-13 T5, T10, T12 · AC-14 T5, T10 · AC-15 T6, T10 · AC-16 T6 · AC-17 T5, T6 (live in `/qa`) · AC-18 T5 (live in `/qa`) · AC-19 T7, T10 · AC-20 T3, T7, T8, T11, T12 · AC-21 T1, T5, T10 · EC-1 T4, T6 · EC-2 T10 · EC-3 T10 · EC-4 T4, T10 · EC-5 T10 · EC-6 T3, T7, T11 · EC-7 T10

## Parallelisierung

- Stufen sind Schranken: Eine Stufe beginnt erst, wenn die vorige eingebaut und gegen ihre AC-IDs geprüft ist.
- `[P]` heißt: Dateien überschneiden sich nicht mit anderen `[P]`-Aufgaben derselben Stufe. Stufe 1: drei getrennte Bereiche (neues Modul, AppShell plus Aufnahme-Steuerung, Aufnahme-Ablage). Stufe 2: sechs getrennte Unterordner von `TR/`.
- Höchstens drei Unteragenten gleichzeitig; Stufe 2 läuft in zwei Wellen.
- Jeder Unteragent führt nur die Testdateien seiner Aufgabe aus; der volle Testlauf kommt einmal je Stufe beim Hauptagenten.
