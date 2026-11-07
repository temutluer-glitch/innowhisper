# PROJ-6: Umwandlung in Text

## Dependencies
- Benötigt: PROJ-1 (App-Rahmen & Einstellungen): Zustände „wandelt um“ und „Problem“ am Menüleisten-Symbol, Einstellungsbereich „Aufnahme“
- Benötigt: PROJ-2 (Hinweise & Fehlerprotokoll): Hinweise mit Knopf, Protokoll ohne Inhalte
- Benötigt: PROJ-4 (Groq-Zugang): gespeicherter Zugangsschlüssel und sein Prüf-Stand
- Benötigt: PROJ-5 (Aufnahme per Tastenkürzel): liefert jede fertige Aufnahme mit laufender Nummer (Sprech-Reihenfolge)
- Wird genutzt von: PROJ-7 (Text einfügen) bekommt den fertigen Text; PROJ-9 (Wörterbuch & Ersetzungen), PROJ-10 (Verlauf) und PROJ-11 (KI-Nachbearbeitung) bauen auf der Umwandlung auf

## User Stories
- Als Mitarbeiter von InnoSolv möchte ich, dass mein Diktat wenige Sekunden nach dem Loslassen als sauberer deutscher Text da ist, damit ich ohne Tippen weiterarbeiten kann.
- Als Mitarbeiter, der lange E-Mails diktiert, möchte ich, dass auch 10 Minuten und mehr vollständig umgewandelt werden, ohne Fehlermeldung und ohne fehlende Stellen.
- Als Mitarbeiter möchte ich, dass nichts dazuerfunden wird, damit ich den Text nicht jedes Mal nachkontrollieren muss.
- Als Mitarbeiter unterwegs möchte ich, dass ein Diktat ohne Internet nicht verloren geht, sondern nachgeholt werden kann.
- Als Nutzer möchte ich in den Einstellungen zwischen „Genauer“ und „Schnell“ und zwischen den Sprachen wählen können.
- Als Nutzer möchte ich bei einem Problem verständlich erfahren, was los ist und was ich tun kann.

## Out of Scope
- Einfügen ins aktive Eingabefeld und Wiederherstellen der alten Zwischenablage: PROJ-7. Bis dahin landet der Text als Übergang in der Zwischenablage (AC-3).
- Wörterbuch, Ersetzungen und gesprochene Satzzeichen (Pflichtpunkt 5): PROJ-9
- Verlauf mit Kopieren, Löschen und „noch einmal umwandeln“ von Hand: PROJ-10. PROJ-6 hebt die Aufnahmen nur auf (AC-14).
- KI-Nachbearbeitung mit Vorlagen: PROJ-11
- Schnellwahl der Sprache im Menüleisten-Fenster: PROJ-13
- Abbrechen einer laufenden Umwandlung
- Umwandlung ohne Internet direkt auf dem Mac, andere Anbieter als Groq (Produktplan: bewusst nicht dabei)
- Weitere Sprachen außer Deutsch, Englisch und Automatisch

## Acceptance Criteria

### Umwandeln
- [ ] **AC-1** — Angenommen ein gültiger Zugangsschlüssel ist eingetragen und das Internet ist da, wenn eine Aufnahme fertig ist, dann wird sie über Groq in Text umgewandelt, und das Menüleisten-Symbol zeigt „wandelt um“, solange mindestens eine Umwandlung läuft.
- [ ] **AC-2** — Angenommen InnoWhisper ist frisch installiert, wenn der Nutzer den Bereich „Aufnahme“ der Einstellungen öffnet, dann steht das Modell auf „Genauer“ und die Sprache auf „Deutsch“; wählbar sind „Genauer“ und „Schnell“ sowie „Deutsch“, „Englisch“ und „Automatisch“.
- [ ] **AC-3** — Angenommen die Umwandlung hat geklappt, wenn der Text fertig ist, dann wird er weitergegeben; solange es PROJ-7 noch nicht gibt, landet er in der Zwischenablage und es erscheint kurz „Text in der Zwischenablage.“
- [ ] **AC-4** — Angenommen der Nutzer ändert Modell oder Sprache, wenn danach eine Aufnahme fertig wird, dann gilt für sie die neue Wahl; eine schon laufende Umwandlung behält die alte.

### Tempo und lange Aufnahmen
- [ ] **AC-5** — Angenommen normales Internet, wenn ein Diktat von bis zu 30 Sekunden endet, dann ist der Text in weniger als 3 Sekunden nach dem Loslassen fertig.
- [ ] **AC-6** — Angenommen der Nutzer hat 10 Minuten am Stück gesprochen, wenn die Aufnahme endet, dann ist der vollständige Text in weniger als 1 Minute fertig, ohne Fehlermeldung.
- [ ] **AC-7** — Angenommen eine Aufnahme ist zu lang für ein einziges Hochladen zu Groq, wenn sie umgewandelt wird, dann wird sie in Teilen umgewandelt und zu einem Text zusammengesetzt, in der richtigen Reihenfolge, ohne fehlende und ohne doppelte Wörter an den Übergängen; eine Obergrenze für die Länge gibt es nicht.

### Reihenfolge
- [ ] **AC-8** — Angenommen zwei Diktate wurden kurz nacheinander gesprochen, wenn das zweite früher fertig umgewandelt ist als das erste, dann wartet es und wird erst nach dem ersten weitergegeben.
- [ ] **AC-9** — Angenommen das erste von zwei Diktaten ist endgültig gescheitert (AC-11), wenn das zweite fertig ist, dann wird das zweite sofort weitergegeben; das erste bleibt über „Erneut versuchen“ erhalten und wird weitergegeben, sobald es klappt.

### Fehler
- [ ] **AC-10** — Angenommen eine Umwandlung scheitert (kein Internet, Groq antwortet nicht oder mit einem Fehler), wenn das passiert, dann versucht InnoWhisper es still noch zweimal, bevor es dem Nutzer etwas meldet.
- [ ] **AC-11** — Angenommen auch die zwei stillen Versuche sind gescheitert, wenn das feststeht, dann erscheint „Umwandlung fehlgeschlagen. Die Aufnahme ist gespeichert.“ (ohne Internet: „Keine Internetverbindung. Die Aufnahme ist gespeichert.“) mit dem Knopf „Erneut versuchen“, das Menüleisten-Symbol zeigt „Problem“, und die Aufnahme bleibt erhalten, bis sie umgewandelt ist.
- [ ] **AC-12** — Angenommen kein Zugangsschlüssel ist eingetragen, wenn eine Aufnahme fertig ist, dann erscheint „Kein Groq-Zugangsschlüssel eingetragen.“ mit dem Knopf „Schlüssel eintragen“, der den Bereich „Zugang & Erlaubnisse“ öffnet; die Aufnahme bleibt erhalten und lässt sich danach mit „Erneut versuchen“ umwandeln.
- [ ] **AC-13** — Angenommen Groq lehnt den Zugangsschlüssel ab, wenn das bei einer Umwandlung passiert, dann wird der Schlüssel als „ungültig“ markiert (PROJ-4), es erscheint „Groq lehnt den Zugangsschlüssel ab.“ mit dem Knopf „Schlüssel prüfen“, und die Aufnahme bleibt erhalten.
- [ ] **AC-14** — Angenommen Groq meldet, dass die Grenze des Kontos erreicht ist, wenn das passiert, dann wartet InnoWhisper die von Groq genannte Zeit und versucht es selbst noch einmal; dauert die Wartezeit länger als 2 Minuten, erscheint „Groq-Grenze erreicht. Versuche es in X Minuten erneut.“ mit „Erneut versuchen“, und die Aufnahme bleibt erhalten.

### Nichts erfinden
- [ ] **AC-15** — Angenommen das Ergebnis besteht nur aus einem bekannten erfundenen Satz (z. B. „Vielen Dank.“, „Tschüss.“, „Thanks for watching“, „Untertitel im Auftrag des ZDF“), wenn die Umwandlung fertig ist, dann wird nichts weitergegeben, es erscheint „Nichts erkannt, kein Text eingefügt.“, und die Aufnahme wird gelöscht.
- [ ] **AC-16** — Angenommen das Ergebnis enthält einen Untertitel-Satz (z. B. „Untertitel der Amara.org-Community“, „Untertitelung des ZDF für funk“), wenn die Umwandlung fertig ist, dann wird dieser Satz entfernt, egal wo er steht; ein gesprochenes „Vielen Dank.“ am Ende eines längeren Diktats bleibt stehen.
- [ ] **AC-17** — Angenommen 20 echte Diktate auf Deutsch, davon mindestens 5 mit Stille am Ende und mindestens 3 länger als 2 Minuten, auf zwei verschiedenen Macs, wenn sie umgewandelt werden, dann beginnt keines mit einem nicht gesprochenen „Ich“ und an keines ist ein nicht gesprochener Satz angehängt (Pflichtpunkt 6).
- [ ] **AC-18** — Angenommen dieselben 20 echten Diktate, wenn Timur die Texte liest, dann sind mindestens 18 ohne sinnentstellenden Fehler, also ohne Wörter, die nur nach Klang aufgeschrieben wurden und den Sinn verändern (Pflichtpunkt 4).

### Aufbewahren und nachholen
- [ ] **AC-19** — Angenommen eine Umwandlung hat geklappt, wenn es danach mehr als 50 gelungene Aufnahmen gibt, dann wird die älteste gelöscht; die letzten 50 bleiben erhalten.
- [ ] **AC-20** — Angenommen beim Beenden von InnoWhisper waren Aufnahmen noch nicht umgewandelt, wenn InnoWhisper das nächste Mal startet, dann wandelt es sie selbst in der Sprech-Reihenfolge um und legt den Text in die Zwischenablage, mit dem Hinweis „Nachgeholtes Diktat in der Zwischenablage.“; mehrere werden in der Reihenfolge zu einem Text mit je einer Leerzeile dazwischen zusammengefasst; ins gerade offene Eingabefeld wird nichts eingefügt.

### Protokoll
- [ ] **AC-21** — Angenommen eine Umwandlung startet, gelingt, scheitert oder wird wiederholt, wenn das passiert, dann schreibt das Protokoll Modell, Sprache, Länge der Aufnahme, Anzahl der Teile, Dauer und Fehlerart, nie den Ton oder den Text.

## Edge Cases
- **EC-1** — Angenommen in der Mitte einer langen Aufnahme ist ein Teil völlig still, wenn umgewandelt wird, dann liefert dieser Teil keinen Text, die übrigen Teile werden normal zusammengesetzt, und für den stillen Teil wird kein erfundener Satz eingefügt.
- **EC-2** — Angenommen der Nutzer klickt „Erneut versuchen“, während InnoWhisper es gerade selbst noch einmal versucht (oder klickt zweimal), wenn beide Versuche laufen würden, dann wird die Aufnahme nur einmal umgewandelt und der Text nur einmal weitergegeben.
- **EC-3** — Angenommen eine Umwandlung ist bei einigen Teilen fertig und scheitert bei einem Teil, wenn der Nutzer später „Erneut versuchen“ klickt, dann kommt am Ende der vollständige Text, nie ein Text mit Lücke.
- **EC-4** — Angenommen die Aufnahme-Datei ist beschädigt oder lässt sich nicht lesen, wenn sie umgewandelt werden soll, dann erscheint „Aufnahme beschädigt, kann nicht umgewandelt werden.“, die Datei wird gelöscht, und die folgenden Diktate werden normal weitergegeben.
- **EC-5** — Angenommen der Nutzer entfernt den Zugangsschlüssel, während eine Umwandlung läuft, wenn das passiert, dann gilt AC-12 für alle Aufnahmen, die noch nicht fertig sind.
- **EC-6** — Angenommen InnoWhisper wird beendet, während eine Umwandlung läuft, wenn es neu startet, dann gilt AC-20; es wird nichts doppelt weitergegeben, was vor dem Beenden schon fertig war.
- **EC-7** — Angenommen der Nutzer diktiert weiter, während frühere Diktate wegen eines Fehlers warten, wenn neue Aufnahmen fertig werden, dann werden sie normal umgewandelt und weitergegeben (AC-9); die wartenden bleiben über „Erneut versuchen“ erhalten.

## Technical Requirements (optional)
- Zeitgrenzen: AC-5 (unter 3 Sekunden bis 30 Sekunden Diktat), AC-6 (unter 1 Minute für 10 Minuten), AC-14 (bis 2 Minuten selbst warten). Nachweis mit echten Aufnahmen bei normalem Internet.
- Länge: AC-6 und AC-7 erfüllen Pflichtpunkt 2 zusammen mit PROJ-5 AC-6. Nachweis mit einer echten Aufnahme von 10 Minuten auf zwei Macs, auch beim erneuten Versuch.
- Qualität: AC-17 und AC-18 sind die Nachweise für Pflichtpunkt 6 und 4. Die Ursachen („Ich“ am Anfang, angehängte Sätze, Klang-Wörter) sind Vermutungen und werden beim Bau mit echten Aufnahmen geprüft (Produktplan).
- Groq-Grenzen (Dateigröße pro Hochladen, Ton-Sekunden pro Stunde und Tag, Anfragen pro Minute) für das genutzte Konto prüft `/architecture`.
- Personenbezogene Daten: Diktate enthalten oft Namen von Kunden, Bewerbern und Kollegen und gehen zur Umwandlung an Groq in den USA. Ein Datenschutzrecht ist für das Projekt bewusst nicht eingetragen (ADR-006). Deshalb wurde `/dsgvo` nicht ausgeführt; der offene Hinweis aus dem Produktplan gilt weiter. Aus demselben Grund (kein Recht eingetragen) wurde die KI-Verordnung nicht geprüft.

## Open Questions
- [ ] PROJ-1 AC-20 sagt beim Beenden während einer Umwandlung „… geht es verloren“. Mit AC-20 dieser Spec wird es beim nächsten Start nachgeholt. Der Text der Rückfrage gehört per `/refine PROJ-1` angepasst.
- [ ] PROJ-5 löscht beim Start übrig gebliebene Aufnahme-Dateien. Für AC-20 müssen noch nicht umgewandelte Aufnahmen davon ausgenommen sein; wie, klärt `/architecture`.
- [ ] Welche Groq-Grenzen das genutzte Konto hat, ist offen (Produktplan). Davon hängt ab, wie oft AC-14 im Alltag vorkommt.

## Decision Log

### Product Decisions
| Decision | Rationale | Date |
|----------|-----------|------|
| Modell ab Werk „Genauer“ (whisper-large-v3), „Schnell“ wählbar | Pflichtpunkt 4: sauberere deutsche Sätze; Mehrkosten (rund 11 statt 4 Cent pro Stunde Sprache) sind fürs Team unerheblich | 2026-11-07 |
| Sprache ab Werk „Deutsch“, wählbar „Englisch“ und „Automatisch“ | Feste Sprache senkt erfundene englische Sätze; das Team diktiert fast nur Deutsch | 2026-11-07 |
| Bei Fehlern zweimal still neu versuchen, dann Hinweis mit „Erneut versuchen“, Aufnahme bleibt | Kurze Aussetzer stören nicht; nichts geht verloren (Pflichtpunkt 2) | 2026-11-07 |
| Ein endgültig gescheitertes Diktat hält spätere nicht auf | Weiterarbeiten geht vor strenger Reihenfolge; das gescheiterte kommt nach | 2026-11-07 |
| Erfundenes nur entfernen, wenn es das ganze Ergebnis ist; Untertitel-Sätze überall | Ein echt gesprochenes „Vielen Dank.“ am Ende einer Mail darf nicht verschwinden | 2026-11-07 |
| Bis PROJ-7 kommt der Text in die Zwischenablage | Die Umwandlung soll schon vor dem Einfügen ausprobierbar sein | 2026-11-07 |
| Die letzten 50 gelungenen Aufnahmen bleiben erhalten | Passt zum späteren Verlauf (PROJ-10) mit 50 Diktaten und „noch einmal umwandeln“ | 2026-11-07 |
| Nicht umgewandelte Aufnahmen beim nächsten Start selbst nachholen, nur in die Zwischenablage | Nichts geht verloren; ins Feld einfügen wäre falsch, weil der Nutzer dort längst etwas anderes tut | 2026-11-07 |
| Mehrere nachgeholte Diktate als ein Text mit Leerzeilen | Die Zwischenablage fasst nur einen Text; so geht keines verloren | 2026-11-07 |
| Tempo: unter 3 Sekunden für kurze, unter 1 Minute für 10-Minuten-Diktate | Wunsch Timur | 2026-11-07 |
| Modell und Sprache im Einstellungsbereich „Aufnahme“ | Der Bereich ist dafür vorgesehen (PROJ-5); kein eigener Bereich für zwei Auswahlfelder | 2026-11-07 |
| Qualitätsnachweis mit 20 echten Diktaten auf zwei Macs, mindestens 18 ohne sinnentstellenden Fehler (AC-17, AC-18) | Pflichtpunkte 4 und 6 lassen sich nur mit echten Aufnahmen belegen; von Timur am 07.11. bestätigt | 2026-11-07 |
| Kein Abbrechen einer laufenden Umwandlung | Umwandeln dauert nur Sekunden; Abbrechen ist über Esc während der Aufnahme möglich (PROJ-5) | 2026-11-07 |
