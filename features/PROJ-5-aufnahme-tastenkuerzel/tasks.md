# PROJ-5 Aufgaben

> Erstellt von `/tasks` aus `spec.md` + `design.md`. Geordneter, nachverfolgbarer Bauplan.
> `[P]` = parallel möglich: die Dateien der Aufgabe überschneiden sich mit keiner anderen `[P]`-Aufgabe derselben Stufe.
> Stufen laufen **nacheinander** (jede ist eine Schranke). Jede Aufgabe nennt die AC/EC-IDs aus `spec.md`, die sie erfüllt (AC → Aufgabe → Test).
> Owner: `/tasks` legt die Datei an; `/build` hakt ab. Keine `[user]`-Aufgaben (der Entwurf nennt keine Einstellung in einem Dashboard).
> Abkürzungen: `Kit/` = `Packages/InnoWhisperKit/`, `RC/` = `Kit/Sources/Recording/`, `RCT/` = `Kit/Tests/RecordingTests/`.

## Stufe 1 — Grundgerüst

- [x] T1  Modul `Recording` (hängt von `AppShell`, `Diagnostics`, `Notices`, `Onboarding`, `Permissions` ab) samt Testziel anlegen und ins Xcode-Projekt einhängen; Modul-Kopf mit festen Werten (Wartezeit 0,25 s, Mindestdauer 0,5 s, Sprachanteil 5 % bei −35 dB, kein Ton nach 1 s, Esc-Grenze 30 s und 3 s, Speichergrenze 200 MB, Prüftakt 10 s und 0,5 s, Ordner `Recordings`, Schritt-Kennung „shortcut“, Reihenfolge 60, Einstellungs-Schlüssel `recording.shortcut`, `recording.mode`, `recording.microphoneID`); Protokoll-Bereich `recording`; erster Test  · files: Kit/Package.swift, RC/Recording.swift, RCT/SmokeTests.swift, Kit/Sources/Diagnostics/LogFile.swift, InnoWhisper.xcodeproj/project.pbxproj  · → AC-21

## Stufe 2 — Regeln ohne Mac-Technik

- [x] T2 [P]  Kürzel-Datenmodell (Zusatztaste allein oder Kombination, Modus Halten/Ein-aus), Werkszustand rechte ⌘ + Halten, Prüfung erlaubter Eingaben (mindestens eine Zusatztaste, kein Esc als Haupttaste), Speichern und Laden mit Rückfall auf den Werkszustand bei unlesbarem Wert, Tastennamen für die Anzeige  · files: RC/Hotkey/Shortcut.swift, RC/Hotkey/ShortcutStore.swift, RCT/ShortcutTests.swift  · → AC-1, AC-16, AC-17
- [x] T3 [P]  Tasten-Entscheidungslogik ohne macOS: aus Tastenereignissen und Uhr wird „Aufnahme vorbereiten / öffnen / beenden / still verwerfen / Esc“; Wartezeit 0,25 s bei Zusatztaste allein, zweite Taste verwirft, Antippen im Ein/aus-Modus, Abgleich mit dem echten Tastenzustand (verlorenes Loslassen)  · files: RC/Hotkey/KeyInterpreter.swift, RCT/KeyInterpreterTests.swift  · → AC-2, AC-3, AC-10, EC-1, EC-5
- [x] T4 [P]  Aufnahme-Regeln ohne macOS: Verwerfen (unter 0,5 s still, Sprachanteil unter 5 % mit Hinweis), Esc-Regel (bis 30 s sofort, danach zweites Esc innerhalb 3 s), „kein Ton“ nach 1 s (Pakete nur aus Nullen zählen nicht), Speichergrenze 200 MB; dazu die festen Hinweistexte  · files: RC/Session/RecordingRules.swift, RC/Session/RecordingTexts.swift, RCT/RecordingRulesTests.swift  · → AC-8, AC-9, AC-10, AC-11, AC-14, EC-4
- [x] T5 [P]  Hinweis mit Knopf (kleine Ergänzung PROJ-2): optionaler Titel plus Handlung; Klick löst die Handlung aus und schließt den Hinweis; Hinweise ohne Knopf bleiben unverändert  · files: Kit/Sources/Notices/Notice.swift, Kit/Sources/Notices/NoticeView.swift, Kit/Sources/Notices/NoticeCenter.swift, Kit/Tests/NoticesTests/NoticeActionTests.swift  · → AC-15

## Stufe 3 — Anschluss an den Mac

- [x] T6 [P]  Kürzel-Wächter über den Ereignis-Abgriff von macOS: Zusatztasten und Tasten an die Entscheidungslogik, Haupttaste einer Kombination und Esc während einer Aufnahme abfangen, abgeschalteten Abgriff sofort wieder einschalten und protokollieren, echten Tastenzustand nachfragen, Pause während das Kürzel-Feld aufnimmt; Attrappe für Tests  · files: RC/Hotkey/HotkeyMonitor.swift, RCT/HotkeyMonitorTests.swift  · → AC-2, AC-3, AC-8, EC-1, EC-5
- [x] T7 [P]  Mikrofon-Aufnehmer: Gerät öffnen (gewählt oder System, Rückfall mit Namen beider Geräte), Tonpakete als CAF 16 kHz Mono schreiben, Pegel und Sprachanteil messen, „Ton fließt“ melden, Trennen des Geräts melden; Mikrofonliste mit Aktualisierung bei An- und Abstecken; Schnittstelle plus Attrappe  · files: RC/Capture/MicrophoneCapture.swift, RC/Capture/AudioFileWriter.swift, RC/Capture/MicrophoneList.swift, RCT/AudioFileWriterTests.swift  · → AC-4, AC-6, AC-12, AC-13, AC-14, EC-2, EC-7
- [x] T8 [P]  Belegt-Prüfung: Kürzel von macOS aus der Systemkürzel-Datei lesen, Probe-Anmeldung über Carbon; Zusatztaste allein wird nicht geprüft  · files: RC/Hotkey/ShortcutAvailability.swift, RCT/ShortcutAvailabilityTests.swift  · → AC-18
- [x] T9 [P]  Ablage fertiger Aufnahmen: laufende Nummer, Weitergabe in Sprech-Reihenfolge über eine Schnittstelle für PROJ-6, Platzhalter-Abnehmer behält nur die letzte Aufnahme, Löschen abgebrochener und verworfener Dateien, Reste nach einem Absturz beim Start löschen und zählen  · files: RC/Session/RecordingQueue.swift, RC/Session/RecordingStorage.swift, RCT/RecordingQueueTests.swift  · → AC-6, AC-7, AC-8, AC-11

## Stufe 4 — Steuerung

- [x] T10  Aufnahme-Steuerung als Zustandsautomat (bereit → wartet → startet → nimmt auf → endet) mit Generationszähler: Erlaubnis-Prüfung mit Hinweis-Knopf, Startton erst bei fließendem Ton, Zustand „nimmt auf“ an der Menüleiste, Endton, Abbruch, Verwerfen, Weitergabe an die Ablage, Rückfall auf das Systemmikrofon mit Hinweis, Unterbrechungen (Gerät getrennt, Ruhezustand, Bildschirmsperre, Speicher) mit Hinweis, nur Probe-Aufnahmen solange die Einführung offen ist, höchstens eine Aufnahme; Protokoll ohne Inhalte  · files: RC/Session/RecordingController.swift, RC/Session/InterruptionWatcher.swift, RCT/RecordingControllerTests.swift  · → AC-2, AC-3, AC-4, AC-5, AC-7, AC-8, AC-9, AC-11, AC-13, AC-14, AC-15, AC-21, EC-2, EC-3, EC-4, EC-6, EC-8

## Stufe 5 — Oberfläche

- [x] T11 [P]  Einstellungsbereich „Aufnahme“: Gruppe „Tastenkürzel“ mit Kürzel-Feld (nimmt eine Taste auf, Esc bricht ab, Belegt-Meldung) und Modus-Wahl, Gruppe „Mikrofon“ mit Auswahl; Anzeigename des Bereichs `hotkeys` wird „Aufnahme“; Knöpfe und Felder einheitlich nach dem Muster von „Zugang & Erlaubnisse“  · files: RC/UI/RecordingSettingsPane.swift, RC/UI/ShortcutField.swift, RC/UI/MicrophonePicker.swift, Kit/Sources/AppShell/Settings/SettingsSection.swift  · → AC-12, AC-16, AC-17, AC-18
- [x] T12  Einführungsschritt „Tastenkürzel“ (Reihenfolge 60, nicht automatisch erledigt): Text „Halte die rechte ⌘-Taste und sprich.“ (passend zum gespeicherten Kürzel), Mikrofonwahl aus T11, Pegelanzeige, Probe-Aufnahme, „Weiter“ erst nach gelungener Probe, Meldung „Klappt. Dein Mikrofon funktioniert.“; passt in die Fensterhöhe der Einführung (Test wie in PROJ-4)  · files: RC/UI/ShortcutStep.swift, RC/UI/LevelMeter.swift, RCT/ShortcutStepTests.swift  · → AC-19, AC-20, EC-6

## Stufe 6 — Zusammenstecken und Live-Prüfung

- [x] T13  App verdrahten: Aufnahme-Modul erzeugen und starten, Bereich „Aufnahme“ und Schritt anmelden, Aktivität (Menüleiste, Rückfrage beim Beenden), Erlaubnis-Wächter, Hinweise und Töne verbinden, Pegel für PROJ-8 bereitstellen  · files: App/AppEnvironment.swift  · → AC-1, AC-4, AC-5, AC-15, AC-19
- [x] T14  Am laufenden Programm prüfen, erst selbst messen (Protokoll), dann Timur: Startton-Zeit, 10-Minuten-Aufnahme (Dauer der Datei), zehnmal ⌘C/⌘V ohne Startton und ohne orange Mikrofonanzeige, Esc vor und nach 30 s, stille Aufnahme, Mikrofon abstecken, Ruhezustand, Mikrofon stummschalten (kein Ton), fehlendes Wunschmikrofon, Kürzel ändern und belegtes Kürzel, Einführungsschritt mit Probe, Aufnahme während eines Videocalls; Ergebnisse in die Bau-Notizen  · files: features/PROJ-5-aufnahme-tastenkuerzel/design.md  · → AC-4, AC-6, AC-8, AC-9, AC-11, AC-13, AC-14, AC-16, AC-18, AC-19, EC-1, EC-2, EC-3, EC-7

## Parallelisierung

- **Stufen sind Schranken.** Eine Stufe startet erst, wenn die vorige eingebaut und gegen ihre AC-IDs geprüft ist: Regeln (2) → Anschluss an den Mac (3) → Steuerung (4) → Oberfläche (5) → Verdrahtung (6).
- **`[P]` heißt: keine gemeinsamen Dateien.** Stufe 2: T2–T5 sind überschneidungsfrei. Stufe 3: T6–T9 sind überschneidungsfrei. Stufe 5: T12 nutzt die Mikrofonwahl aus T11 und läuft deshalb danach.
- **Abdeckung:** Jede AC-1 bis AC-21 und jede EC-1 bis EC-8 steht bei mindestens einer Aufgabe.
- Während `/build` läuft jede `[P]`-Aufgabe einer Stufe in einem eigenen Unterprozess mit eigenem Arbeitsstand (höchstens drei gleichzeitig); der Hauptprozess baut zusammen, prüft und hakt ab.
