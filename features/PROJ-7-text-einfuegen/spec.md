# PROJ-7: Text einfügen

## Dependencies
- Benötigt: PROJ-1 (App-Rahmen & Einstellungen): Bereich „Allgemein“ im Einstellungsfenster
- Benötigt: PROJ-2 (Hinweise & Fehlerprotokoll): Hinweise mit Knopf, Protokoll ohne Inhalte
- Benötigt: PROJ-3 (Erlaubnisse & Einführung): Erlaubnis „Bedienungshilfen“; fügt den Schritt „Probe-Diktat“ in die Einführung ein
- Benötigt: PROJ-5 (Aufnahme per Tastenkürzel): Beginn einer Aufnahme (dort wird das Ziel gemerkt)
- Benötigt: PROJ-6 (Umwandlung in Text): liefert die fertigen Texte; ersetzt den Übergang „Text in der Zwischenablage“ (PROJ-6 AC-3) für gerade gesprochene Diktate
- Wird genutzt von: PROJ-8 (Sprechblase) zeigt am selben Eingabefeld an; PROJ-13 (Schnellzugriff) kann das letzte Diktat erneut einfügen

## User Stories
- Als Mitarbeiter von InnoSolv möchte ich, dass mein Diktat direkt dort erscheint, wo ich gerade schreibe, ohne dass ich ⌘V drücken muss.
- Als Mitarbeiter, der vorher etwas kopiert hat (z. B. eine Telefonnummer), möchte ich, dass meine Zwischenablage nach dem Diktat wieder so ist wie vorher.
- Als Mitarbeiter, der während der Umwandlung schon weiterklickt, möchte ich, dass der Text trotzdem in der Mail landet, in der ich angefangen habe.
- Als Mitarbeiter möchte ich, dass ein Diktat nie verloren geht, auch wenn das Einfügen nicht klappt.
- Als Nutzer, der lieber selbst einfügt, möchte ich in den Einstellungen „Nur in die Zwischenablage“ wählen können.
- Als neuer Nutzer möchte ich in der Einführung einmal ausprobieren, dass ein Diktat bis zum fertigen Text funktioniert.

## Out of Scope
- Sprechblase mit Tonwelle am Eingabefeld: PROJ-8
- Verlauf mit „noch einmal einfügen“: PROJ-10; Schnellzugriff auf das letzte Diktat: PROJ-13
- Automatisches Leerzeichen oder Großschreibung passend zum Text, der schon im Feld steht
- Rückgängig machen eines eingefügten Diktats durch InnoWhisper (⌘Z im Programm selbst bleibt möglich)
- Einfügen nachgeholter Diktate (PROJ-6 AC-20): sie kommen weiter nur in die Zwischenablage
- Einfügen in Passwortfelder (siehe EC-1)

## Acceptance Criteria

### Einfügen
- [ ] **AC-1** — Angenommen InnoWhisper ist frisch installiert, wenn der Nutzer den Bereich „Allgemein“ der Einstellungen öffnet, dann steht „Ausgabe“ auf „In das Eingabefeld einfügen“; wählbar ist außerdem „Nur in die Zwischenablage“.
- [ ] **AC-2** — Angenommen ein Eingabefeld war beim Start der Aufnahme aktiv, wenn der Text fertig ist, dann erscheint er an der Schreibmarke dieses Felds, und der Nutzer muss nichts drücken.
- [ ] **AC-3** — Angenommen der Nutzer hat während der Umwandlung in ein anderes Programm gewechselt, wenn der Text fertig ist, dann holt InnoWhisper das Programm, in dem die Aufnahme begann, nach vorn und fügt den Text in das Feld ein, in dem die Aufnahme begann.
- [ ] **AC-4** — Angenommen der Text wurde eingefügt, wenn das Einfügen fertig ist, dann erscheint kein Hinweis.
- [ ] **AC-5** — Angenommen der Text ist fertig, wenn er eingefügt wird, dann ist er innerhalb von 1 Sekunde im Feld.

### Zwischenablage
- [ ] **AC-6** — Angenommen in der Zwischenablage lag vorher etwas (Text, Bild oder Datei), wenn das Diktat eingefügt wurde, dann liegt danach wieder genau dieser Inhalt in der Zwischenablage und nicht das Diktat.
- [ ] **AC-7** — Angenommen der Nutzer kopiert selbst etwas Neues, während InnoWhisper einfügt, wenn InnoWhisper die alte Zwischenablage zurückholen würde, dann lässt es das Neue in Ruhe.
- [ ] **AC-8** — Angenommen InnoWhisper legt ein Diktat in die Zwischenablage (zum Einfügen oder als Ersatz), wenn ein Programm einen Zwischenablage-Verlauf führt, dann ist das Diktat als vertraulich markiert, damit es dort nicht gespeichert wird.
- [ ] **AC-9** — Angenommen „Ausgabe“ steht auf „Nur in die Zwischenablage“, wenn der Text fertig ist, dann liegt er in der Zwischenablage und es erscheint kurz „Text in der Zwischenablage.“; es wird nichts eingefügt.

### Wenn Einfügen nicht geht
- [ ] **AC-10** — Angenommen beim Start der Aufnahme war kein Eingabefeld aktiv, oder das Einfügen klappt nicht, oder das Programm ist inzwischen geschlossen, wenn der Text fertig ist, dann liegt er in der Zwischenablage und es erscheint „Kein Eingabefeld gefunden, Text in der Zwischenablage.“; der Text geht nie verloren.
- [ ] **AC-11** — Angenommen die Erlaubnis „Bedienungshilfen“ fehlt, wenn der Text fertig ist, dann liegt er in der Zwischenablage und es erscheint „Bedienungshilfen nicht erlaubt, Text in der Zwischenablage.“ mit dem Knopf „Jetzt erlauben“.

### Mehrere Diktate
- [ ] **AC-12** — Angenommen zwei oder mehr gerade gesprochene Diktate sind gleichzeitig fertig und begannen im selben Feld, wenn sie eingefügt werden, dann stehen sie dort in Sprech-Reihenfolge, getrennt durch ein Leerzeichen.
- [ ] **AC-13** — Angenommen gleichzeitig fertige Diktate begannen in verschiedenen Feldern, wenn sie eingefügt werden, dann kommt jedes in sein eigenes Feld, in Sprech-Reihenfolge.
- [ ] **AC-14** — Angenommen ein nachgeholtes Diktat (PROJ-6 AC-20) ist fertig, wenn es übergeben wird, dann kommt es wie bisher nur in die Zwischenablage mit „Nachgeholtes Diktat in der Zwischenablage.“; gerade gesprochene Diktate desselben Schritts werden davon getrennt eingefügt.

### Einführung
- [ ] **AC-15** — Angenommen die Einführung läuft, wenn der Schritt „Tastenkürzel“ abgeschlossen ist, dann folgt als letzter Schritt „Probe-Diktat“ mit einem Testfeld und dem Satz „Halte die rechte ⌘-Taste und sag einen Satz.“ (passend zum gewählten Kürzel und Modus).
- [ ] **AC-16** — Angenommen der Schritt „Probe-Diktat“ ist offen, wenn der Nutzer diktiert, dann erscheint der fertige Text im Testfeld und „Fertig“ wird frei; „Überspringen“ ist jederzeit möglich; der Probetext wird nirgends gespeichert.
- [ ] **AC-17** — Angenommen die Umwandlung im Schritt „Probe-Diktat“ scheitert (kein Internet, Schlüssel fehlt oder ungültig), wenn das passiert, dann zeigt der Schritt den Hinweis aus PROJ-6 und der Nutzer kann es erneut versuchen oder überspringen.

### Protokoll
- [ ] **AC-18** — Angenommen ein Text wird eingefügt oder ersatzweise in die Zwischenablage gelegt, wenn das passiert, dann schreibt das Protokoll Art (eingefügt / Zwischenablage), Grund, Kennung des Zielprogramms und Dauer, nie den Text und nie den Inhalt der Zwischenablage.

## Edge Cases
- **EC-1** — Angenommen beim Start der Aufnahme war ein Passwortfeld aktiv, wenn der Text fertig ist, dann wird nichts eingefügt; der Text liegt in der Zwischenablage und es erscheint „In Passwortfelder fügt InnoWhisper nicht ein. Text in der Zwischenablage.“
- **EC-2** — Angenommen der Nutzer tippt im Zielfeld weiter, während der Text umgewandelt wird, wenn der Text fertig ist, dann erscheint er an der dann aktuellen Schreibmarke dieses Felds.
- **EC-3** — Angenommen das Feld, in dem die Aufnahme begann, gibt es nicht mehr (Fenster geschlossen), das Programm läuft aber noch, wenn der Text fertig ist, dann gilt AC-10.
- **EC-4** — Angenommen die Aufnahme begann in einem Fenster von InnoWhisper selbst (außer dem Testfeld der Einführung), wenn der Text fertig ist, dann gilt AC-10.
- **EC-5** — Angenommen die Zwischenablage war vorher leer, wenn das Diktat eingefügt wurde, dann ist sie danach wieder leer.

## Technical Requirements (optional)
- Zeitgrenze: AC-5 (Text spätestens 1 Sekunde nach dem Fertigwerden im Feld). Nachweis mit echten Diktaten in mindestens drei verschiedenen Programmen (z. B. Mail, Notizen, Browser).
- Pflichtpunkt 3 (Eingabefeld wird auch auf anderen Laptops erkannt): AC-2, AC-3 und AC-10 werden auf mindestens zwei verschiedenen Macs nachgewiesen; die Sprechblase dazu folgt in PROJ-8.
- Personenbezogene Daten: Diktate laufen kurz durch die Zwischenablage und werden dort als vertraulich markiert (AC-8); InnoWhisper speichert sie in diesem Feature nicht. Ein Datenschutzrecht ist für das Projekt bewusst nicht eingetragen (ADR-006), deshalb wurde `/dsgvo` nicht ausgeführt.
- Keine Anmeldung und keine Zugangsprüfung in diesem Feature.

## Open Questions
- [ ] Ob macOS das Erkennen und erneute Anwählen des ursprünglichen Felds in allen Programmen zulässt (z. B. Browser, Electron-Programme wie Slack), klärt `/architecture`; wo es nicht geht, gilt AC-10.

## Decision Log

### Product Decisions
| Decision | Rationale | Date |
|----------|-----------|------|
| Text kommt in das Feld, in dem die Aufnahme begann, auch wenn der Nutzer inzwischen woanders ist | Wunsch Timur; so war es auch in der alten App; das Diktat gehört zu dem Text, an dem man gerade schrieb | 2026-11-21 |
| Kein Feld oder Einfügen klappt nicht: Zwischenablage plus Hinweis | Ein Diktat darf nie verloren gehen | 2026-11-21 |
| Alte Zwischenablage wird zurückgeholt, Diktat als vertraulich markiert | Wunsch Timur; vorher Kopiertes bleibt erhalten, Diktate landen nicht in Zwischenablage-Verläufen | 2026-11-21 |
| Kein Hinweis nach erfolgreichem Einfügen | Der Text im Feld ist Rückmeldung genug; Hinweise nur bei Problemen | 2026-11-21 |
| Probe-Diktat als letzter Schritt der Einführung, überspringbar | Neue Nutzer sehen einmal den ganzen Weg bis zum Text; Überspringen, weil es Internet und Schlüssel braucht | 2026-11-21 |
| Gleichzeitig fertige Diktate im selben Feld mit Leerzeichen getrennt | Wunsch Timur; ergibt fortlaufenden Text | 2026-11-21 |
| Nie in Passwortfelder einfügen | Schutz vor versehentlichem Diktat eines Passworts in ein fremdes Feld; macOS schützt diese Felder ohnehin | 2026-11-21 |
| Zeitgrenze 1 Sekunde bis zum Text im Feld (AC-5) und nie in Passwortfelder (EC-1) | Vorschlag aus dem Entwurf, von Timur am 21.11. bestätigt | 2026-11-21 |
| Ausgabe-Einstellung im Bereich „Allgemein“ | So in der App-Übersicht vorgesehen (`docs/app-shell.md`) | 2026-11-21 |
