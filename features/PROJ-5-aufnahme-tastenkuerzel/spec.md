# PROJ-5: Aufnahme per Tastenkürzel

## Dependencies
- Benötigt: PROJ-1 (App-Rahmen & Einstellungen): Zustand „nimmt auf“ am Menüleisten-Symbol, neuer Einstellungsbereich, Rückfrage beim Beenden während einer Aufnahme (PROJ-1 AC-20)
- Benötigt: PROJ-2 (Hinweise & Fehlerprotokoll): Hinweise, Start- und Endton, Protokoll ohne Inhalte
- Benötigt: PROJ-3 (Erlaubnisse & Einführung): Mikrofon-Erlaubnis; fügt den Schritt „Tastenkürzel“ in die Einführung ein; erfüllt die Zusage aus PROJ-3, beim Drücken des Kürzels auf eine fehlende Erlaubnis hinzuweisen
- Wird genutzt von: PROJ-6 (Umwandlung in Text) bekommt jede fertige Aufnahme; PROJ-8 (Sprechblase) zeigt den Pegel während der Aufnahme; PROJ-12 (Mehrere Tastenkürzel) baut auf dem einen Kürzel auf

## User Stories
- Als Mitarbeiter von InnoSolv möchte ich die rechte ⌘-Taste halten, sprechen und loslassen, damit ich ohne Fenster und ohne Maus diktieren kann.
- Als Mitarbeiter möchte ich sofort hören und sehen, dass die Aufnahme wirklich läuft, damit ich nie ins Leere spreche.
- Als Mitarbeiter, der lange E-Mails diktiert, möchte ich auch 10 Minuten und mehr am Stück sprechen können, ohne dass etwas verloren geht.
- Als Mitarbeiter mit Headset möchte ich mein Mikrofon fest wählen können und trotzdem diktieren, wenn das Headset einmal nicht angesteckt ist.
- Als Mitarbeiter möchte ich eine Aufnahme mit Esc abbrechen, aber nicht aus Versehen ein langes Diktat verlieren.
- Als neuer Nutzer möchte ich in der Einrichtung das Kürzel einmal ausprobieren, damit ich weiß, dass Mikrofon und Kürzel funktionieren.
- Als Nutzer möchte ich Kürzel und Modus (halten oder ein/aus) in den Einstellungen ändern können.

## Out of Scope
- Umwandlung der Aufnahme in Text, Reihenfolge beim Einfügen mehrerer Diktate: PROJ-6 und PROJ-7
- Sprechblase mit Tonwelle am Eingabefeld: PROJ-8 (PROJ-5 liefert nur den Pegel)
- Mehrere Kürzel mit je eigener KI-Vorlage, Fn-Taste: PROJ-12. Ausnahme: Einzelne Zusatztasten wie die rechte ⌘-Taste kommen schon hier, weil sie das Kürzel ab Werk sind (Entscheidung 07.11.)
- Aufbewahren der Aufnahme nach der Umwandlung, „noch einmal umwandeln“: PROJ-10
- Schnellwahl des Mikrofons im Menüleisten-Fenster: PROJ-13
- Übernahme des Kürzels aus der alten App
- Obergrenze für die Aufnahmedauer (Entscheidung 07.11.)

## Acceptance Criteria

### Aufnahme starten und beenden
- [ ] **AC-1** — Angenommen InnoWhisper ist frisch installiert und die Einführung ist fertig, wenn der Nutzer in den Einstellungen nachsieht, dann ist das Kürzel die rechte ⌘-Taste allein im Modus „Halten“.
- [ ] **AC-2** — Angenommen der Modus ist „Halten“, wenn der Nutzer die rechte ⌘-Taste drückt und hält, dann startet die Aufnahme, und wenn er sie loslässt, dann endet die Aufnahme und wird zur Umwandlung weitergegeben.
- [ ] **AC-3** — Angenommen der Modus ist „Ein/aus“, wenn der Nutzer das Kürzel einmal antippt, dann startet die Aufnahme, und wenn er es noch einmal antippt, dann endet sie und wird weitergegeben.
- [ ] **AC-4** — Angenommen eine Aufnahme startet, wenn das Mikrofon tatsächlich Ton liefert, dann spielt erst in diesem Moment der Startton (sofern Töne an sind) und das Menüleisten-Symbol zeigt „nimmt auf“; das passiert innerhalb von 1 Sekunde nach dem Drücken.
- [ ] **AC-5** — Angenommen eine Aufnahme endet normal, wenn sie weitergegeben wird, dann spielt der Endton (sofern Töne an sind) und das Symbol verlässt „nimmt auf“.
- [ ] **AC-6** — Angenommen der Nutzer spricht 10 Minuten am Stück, wenn er die Aufnahme beendet, dann wird die gesamte Aufnahme ohne Lücke weitergegeben; eine Obergrenze für die Dauer gibt es nicht.
- [ ] **AC-7** — Angenommen ein früheres Diktat wird noch umgewandelt, wenn der Nutzer das Kürzel drückt, dann startet die neue Aufnahme sofort; jede Aufnahme wird in der Reihenfolge weitergegeben, in der sie gesprochen wurde.

### Abbrechen und Verwerfen
- [ ] **AC-8** — Angenommen eine Aufnahme läuft seit höchstens 30 Sekunden, wenn der Nutzer Esc drückt, dann wird sie sofort beendet und weggeworfen, nichts wird umgewandelt, und es erscheint „Aufnahme abgebrochen.“
- [ ] **AC-9** — Angenommen eine Aufnahme läuft länger als 30 Sekunden, wenn der Nutzer Esc drückt, dann läuft sie weiter und es erscheint „Nochmal Esc drücken zum Abbrechen.“; drückt er innerhalb von 3 Sekunden erneut Esc, dann wird sie wie in AC-8 abgebrochen, sonst läuft sie einfach weiter.
- [ ] **AC-10** — Angenommen der Nutzer hat das Kürzel kürzer als eine halbe Sekunde gedrückt, wenn er loslässt, dann wird die Aufnahme ohne Hinweis verworfen.
- [ ] **AC-11** — Angenommen eine Aufnahme ist länger als eine halbe Sekunde, aber es wurde nichts gesprochen, wenn sie endet, dann wird sie verworfen, nichts wird umgewandelt, und es erscheint „Nichts gehört, Aufnahme verworfen.“

### Mikrofon
- [ ] **AC-12** — Angenommen der Nutzer öffnet die Einstellungen, wenn er den Bereich „Aufnahme“ ansieht, dann kann er das Mikrofon wählen: „Systemmikrofon“ (ab Werk, folgt der Einstellung von macOS) oder eines der angeschlossenen Mikrofone mit seinem Namen.
- [ ] **AC-13** — Angenommen ein bestimmtes Mikrofon ist gewählt, aber nicht angeschlossen, wenn der Nutzer das Kürzel drückt, dann nimmt InnoWhisper mit dem Systemmikrofon auf und zeigt „‹Name› nicht gefunden, nehme ‹Name des Systemmikrofons›.“; die Wahl bleibt gespeichert und gilt wieder, sobald das Mikrofon zurück ist.
- [ ] **AC-14** — Angenommen der Nutzer drückt das Kürzel, wenn das Mikrofon 1 Sekunde lang keinen Ton liefert, dann bricht InnoWhisper ab, spielt keinen Startton und zeigt „Das Mikrofon liefert keinen Ton. Prüfe, ob es angeschlossen ist.“
- [ ] **AC-15** — Angenommen die Mikrofon-Erlaubnis fehlt, wenn der Nutzer das Kürzel drückt, dann startet keine Aufnahme und es erscheint „Mikrofon nicht erlaubt.“ mit dem Knopf „Jetzt erlauben“, der wie in PROJ-3 zur Erlaubnis führt.

### Einstellungen
- [ ] **AC-16** — Angenommen der Nutzer öffnet den Bereich „Aufnahme“, wenn er auf das Feld „Tastenkürzel“ klickt und eine neue Taste oder Tastenkombination drückt, dann gilt sie sofort; möglich sind eine Kombination mit mindestens einer der Tasten ⌘, ⌥, ⌃ oder ⇧ oder eine einzelne rechte oder linke ⌘-, ⌥-, ⌃- oder ⇧-Taste.
- [ ] **AC-17** — Angenommen der Nutzer öffnet den Bereich „Aufnahme“, wenn er den Modus zwischen „Halten“ und „Ein/aus“ umstellt, dann gilt der neue Modus ab der nächsten Aufnahme.
- [ ] **AC-18** — Angenommen der Nutzer wählt ein Kürzel, das macOS oder ein anderes Programm schon belegt, wenn er es speichert, dann erscheint „Dieses Kürzel ist schon belegt. Wähle ein anderes.“ und das alte Kürzel bleibt.

### Einrichtung
- [ ] **AC-19** — Angenommen die Einführung läuft, wenn der Schritt „Tastenkürzel“ erscheint (nach den Erlaubnissen), dann zeigt er das Kürzel („Halte die rechte ⌘-Taste und sprich.“), die Mikrofonwahl aus AC-12 und einen Pegel; „Weiter“ ist erst frei, wenn der Nutzer das Kürzel einmal gehalten und dabei hörbar gesprochen hat.
- [ ] **AC-20** — Angenommen der Nutzer probiert das Kürzel im Schritt „Tastenkürzel“ aus, wenn er loslässt, dann wird die Probe-Aufnahme nicht umgewandelt und nicht eingefügt, und es erscheint „Klappt. Dein Mikrofon funktioniert.“

### Protokoll
- [ ] **AC-21** — Angenommen eine Aufnahme startet, endet, wird abgebrochen oder verworfen, wenn das passiert, dann schreibt das Protokoll den Ablauf mit Dauer, Mikrofon-Art (System oder gewählt) und Grund, nie den Ton oder Text der Aufnahme.

## Edge Cases
- **EC-1** — Angenommen der Nutzer hält die rechte ⌘-Taste, wenn er dabei eine weitere Taste drückt (z. B. ⌘C), dann gilt das als normaler Kurzbefehl: Eine schon gestartete Aufnahme wird ohne Hinweis verworfen, der Kurzbefehl wirkt im Programm wie gewohnt.
- **EC-2** — Angenommen eine Aufnahme läuft, wenn das Mikrofon abgezogen wird, dann endet die Aufnahme, das bis dahin Gesprochene wird weitergegeben und es erscheint „Mikrofon getrennt, Aufnahme beendet.“
- **EC-3** — Angenommen eine Aufnahme läuft, wenn der Mac in den Ruhezustand geht oder der Bildschirm gesperrt wird, dann endet die Aufnahme und das bis dahin Gesprochene wird weitergegeben.
- **EC-4** — Angenommen auf dem Mac sind weniger als 200 MB frei, wenn eine Aufnahme startet oder läuft, dann endet sie, das bis dahin Gesprochene wird weitergegeben und es erscheint „Kein Speicherplatz mehr, Aufnahme beendet.“
- **EC-5** — Angenommen der Modus ist „Halten“, wenn das Loslassen der Taste verloren geht (z. B. weil gerade ein Systemfenster aufging), dann merkt InnoWhisper beim nächsten Tastendruck, dass die Taste nicht mehr gehalten wird, und beendet die Aufnahme normal; eine Aufnahme hängt nie unbemerkt fest.
- **EC-6** — Angenommen die Einführung ist noch nicht fertig, wenn der Nutzer das Kürzel außerhalb des Schritts „Tastenkürzel“ drückt, dann startet keine Aufnahme.
- **EC-7** — Angenommen ein anderes Programm nutzt das Mikrofon gerade (z. B. ein Videocall), wenn der Nutzer das Kürzel drückt, dann nimmt InnoWhisper trotzdem auf, ohne den Call zu stören.
- **EC-8** — Angenommen der Nutzer drückt das Kürzel sehr schnell mehrmals hintereinander, wenn das passiert, dann läuft immer höchstens eine Aufnahme gleichzeitig.

## Technical Requirements (optional)
- Zeitgrenzen: AC-4 (Startton und Symbol innerhalb von 1 Sekunde), AC-14 (Abbruch nach 1 Sekunde ohne Ton), AC-9 (3 Sekunden für das zweite Esc).
- Länge: AC-6 mit einer echten Aufnahme von 10 Minuten nachweisen (Pflichtpunkt 2, auf zwei Macs).
- Zuverlässigkeit: AC-4 und AC-14 erfüllen Pflichtpunkt 1. Eine Aufnahme startet entweder hörbar oder mit Meldung, nie still.
- Personenbezogene Daten: Aufnahmen enthalten die Stimme und oft Namen. Sie liegen nur lokal auf dem Mac, bis PROJ-6 sie umwandelt. Wie lange sie danach bleiben, regelt PROJ-10. Ein Datenschutzrecht ist für das Projekt bewusst nicht eingetragen (ADR-006). Deshalb wurde `/dsgvo` nicht ausgeführt; der offene Hinweis aus dem Produktplan gilt weiter.

## Open Questions
- [ ] Erreicht ein Esc während der Aufnahme auch das Programm im Vordergrund (z. B. schließt es dort ein Fenster)? Ob InnoWhisper das Esc abfangen kann, klärt `/architecture`. Gewünscht ist, dass es nur die Aufnahme abbricht.
- [ ] Ohne Bedienungshilfen-Erlaubnis kann macOS das Kürzel womöglich gar nicht an InnoWhisper melden. Dann lässt sich auch kein Hinweis beim Drücken zeigen, wie ihn PROJ-3 zusagt. `/architecture` klärt das; PROJ-3 meldet die fehlende Erlaubnis ohnehin an der Menüleiste.
- [ ] Wie AC-18 „schon belegt“ zuverlässig erkennt, hängt davon ab, was macOS verrät. Das klärt `/architecture`; im Zweifel werden nur die bekannten Kürzel von macOS geprüft.
- [ ] Die Reihenfolge aus AC-7 setzt erst PROJ-6 und PROJ-7 sichtbar um. PROJ-5 liefert die Aufnahmen nur in der richtigen Reihenfolge ab.

## Decision Log

### Product Decisions
| Decision | Rationale | Date |
|----------|-----------|------|
| Kürzel ab Werk: rechte ⌘-Taste allein, Modus „Halten“ | Wunsch Timur; die rechte ⌘ ist mit dem Daumen gut erreichbar und wird selten allein gedrückt | 2026-11-07 |
| Einzelne Zusatztasten (rechte/linke ⌘, ⌥, ⌃, ⇧) schon in PROJ-5 statt erst in PROJ-12 | Sonst wäre das gewünschte Kürzel ab Werk nicht möglich; PROJ-12 behält mehrere Kürzel, Vorlagen pro Kürzel und die Fn-Taste | 2026-11-07 |
| Weitere Taste während des Haltens = normaler Kurzbefehl, Aufnahme wird still verworfen | ⌘C, ⌘V usw. mit der rechten ⌘ dürfen kein Diktat auslösen | 2026-11-07 |
| Keine Obergrenze für die Aufnahmedauer | Wunsch Timur; lange Diktate sollen nie abgeschnitten werden | 2026-11-07 |
| Esc bricht sofort ab, nach 30 Sekunden erst beim zweiten Esc | Schützt lange Diktate vor einem versehentlichen Esc, wie in der alten App | 2026-11-07 |
| Mikrofon wählbar, bei Fehlen Systemmikrofon mit Hinweis | Diktieren klappt immer; der Hinweis erklärt, warum die Qualität anders ist | 2026-11-07 |
| Startton erst, wenn das Mikrofon wirklich Ton liefert; nach 1 Sekunde ohne Ton Abbruch mit Meldung | Pflichtpunkt 1: Eine nicht gestartete Aufnahme darf nie unbemerkt bleiben | 2026-11-07 |
| Kurzes Antippen (unter 0,5 s) still verwerfen, stille längere Aufnahme mit Hinweis verwerfen | Antippen ist kein Diktat; bei längerer Stille soll man wissen, warum kein Text kommt (Pflichtpunkt 6) | 2026-11-07 |
| Neue Aufnahme darf starten, während die vorige noch umgewandelt wird | Kein Warten zwischen zwei Diktaten; die Reihenfolge bleibt erhalten | 2026-11-07 |
| Einführungsschritt „Tastenkürzel“ mit Pflicht-Probe | Jeder merkt beim Einrichten, ob Kürzel und Mikrofon funktionieren | 2026-11-07 |
| Eigener Einstellungsbereich „Aufnahme“ für Kürzel, Modus und Mikrofon | Gehört nicht zu „Allgemein“ oder „Zugang & Erlaubnisse“; PROJ-6 und PROJ-12 können später dort ergänzen | 2026-11-07 |
