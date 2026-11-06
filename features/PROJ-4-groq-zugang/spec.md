# PROJ-4: Groq-Zugang

## Dependencies
- Benötigt: PROJ-1 (App-Rahmen & Einstellungen) — Bereich „Zugang & Erlaubnisse“ und Problem-Anzeige an der Menüleiste
- Benötigt: PROJ-2 (Hinweise & Fehlerprotokoll) — Protokoll ohne Inhalte
- Benötigt: PROJ-3 (Erlaubnisse & Einführung) — fügt den Schritt „Zugangsschlüssel“ in die Einführung ein (Reihenfolge 10, vor dem Mikrofon)
- Wird genutzt von: PROJ-6 (Umwandlung in Text) und PROJ-11 (KI-Nachbearbeitung), die den gespeicherten Schlüssel verwenden

## User Stories
- Als Mitarbeiter von InnoSolv möchte ich beim ersten Start meinen Groq-Schlüssel einfügen und sofort sehen, ob er funktioniert, damit das Diktieren danach ohne Hilfe klappt.
- Als Mitarbeiter, der die alte App schon nutzt, möchte ich meinen dort gespeicherten Schlüssel übernehmen, damit ich ihn nicht suchen muss.
- Als Mitarbeiter ohne Groq-Konto möchte ich in der Einrichtung lesen, wo ich einen Schlüssel bekomme, damit ich nicht nachfragen muss.
- Als Nutzer möchte ich meinen Schlüssel später in den Einstellungen ändern, prüfen oder entfernen können, damit ich bei einem neuen Schlüssel nicht alles neu einrichten muss.
- Als Nutzer möchte ich gewarnt werden, wenn mein Schlüssel nicht mehr gilt, damit ich es nicht erst beim nächsten Diktat merke.
- Als Nutzer möchte ich, dass mein Schlüssel nur im Schlüsselbund liegt und nirgends sonst auftaucht, damit ihn niemand mitlesen kann.

## Out of Scope
- Ein gemeinsamer Firmenschlüssel, der in der App steckt oder an alle verteilt wird — ein Schlüssel in der App lässt sich auslesen (Entscheidung 06.11.)
- Andere Anbieter als Groq (ADR-003, bestätigt am 06.11.)
- Wahl des Modells und der Sprache — PROJ-6
- Verwendung des Schlüssels zum Umwandeln und für die KI — PROJ-6, PROJ-11
- Anlegen eines Groq-Kontos oder Erzeugen eines Schlüssels aus der App heraus — das macht jeder Mitarbeiter selbst auf der Groq-Seite
- Anzeige von Verbrauch, Kosten oder Kontingent bei Groq
- Mehrere Schlüssel pro Nutzer
- Übernahme anderer Einstellungen aus der alten App (Wörterbuch, Tastenkürzel, Vorlagen) — gehört zu den jeweiligen Features

## Acceptance Criteria

### Schritt „Zugangsschlüssel“ in der Einführung
- [ ] **AC-1** — Angenommen InnoWhisper hat noch keinen Schlüssel, wenn die Einführung läuft, dann kommt nach „Willkommen“ der Schritt „Zugangsschlüssel“ mit einem Eingabefeld, das die Eingabe verdeckt, einem Knopf „Prüfen“ und dem Erklärsatz „InnoWhisper braucht deinen Groq-Schlüssel, um deine Aufnahmen in Text umzuwandeln.“
- [ ] **AC-2** — Angenommen der Schritt „Zugangsschlüssel“ ist offen, wenn noch kein gültiger oder als „noch nicht geprüft“ gespeicherter Schlüssel vorliegt, dann ist „Weiter“ gesperrt; ein Überspringen gibt es nicht.
- [ ] **AC-3** — Angenommen der Schritt „Zugangsschlüssel“ ist offen, wenn der Nutzer ihn ansieht, dann steht dort die Hilfe „So bekommst du deinen Schlüssel: 1. Melde dich auf console.groq.com an oder lege ein Konto an. 2. Klicke links auf „API Keys“ und dann auf „Create API Key“. 3. Kopiere den Schlüssel und füge ihn hier ein.“ mit einem Link, der die Groq-Seite für Schlüssel im Browser öffnet.
- [ ] **AC-4** — Angenommen der Nutzer hat einen Schlüssel eingefügt, wenn er auf „Prüfen“ klickt, dann fragt InnoWhisper bei Groq nach und zeigt innerhalb von 15 Sekunden eines von drei Ergebnissen: „Schlüssel funktioniert.“ mit grünem Häkchen, „Groq lehnt diesen Schlüssel ab. Prüfe, ob du ihn vollständig kopiert hast.“ oder „Groq ist gerade nicht erreichbar. Der Schlüssel wird gespeichert und später geprüft.“
- [ ] **AC-5** — Angenommen Groq hat den Schlüssel bestätigt, wenn das Ergebnis erscheint, dann ist der Schlüssel im Schlüsselbund gespeichert und „Weiter“ ist frei.
- [ ] **AC-6** — Angenommen Groq lehnt den Schlüssel ab, wenn das Ergebnis erscheint, dann wird nichts gespeichert, das Feld behält den Inhalt zum Korrigieren und „Weiter“ bleibt gesperrt.

### Übernahme aus der alten App
- [ ] **AC-7** — Angenommen auf dem Mac liegt ein Schlüssel der alten App, wenn der Schritt „Zugangsschlüssel“ erscheint, dann zeigt er statt des leeren Felds den Hinweis „Du hast InnoWhisper schon benutzt. Wir übernehmen deinen Schlüssel von dort. Gleich fragt macOS nach deinem Mac-Passwort; das kommt von InnoWhisper.“ und den Knopf „Schlüssel übernehmen“; das Feld zum Einfügen bleibt als zweiter Weg darunter erreichbar.
- [ ] **AC-8** — Angenommen der Nutzer klickt „Schlüssel übernehmen“, wenn macOS die Freigabe erteilt, dann liest InnoWhisper den Schlüssel, prüft ihn wie in AC-4 und speichert ihn im eigenen Eintrag des Schlüsselbunds; der Eintrag der alten App bleibt unverändert.
- [ ] **AC-9** — Angenommen der Nutzer klickt „Schlüssel übernehmen“, wenn er die macOS-Frage ablehnt oder die Übernahme scheitert, dann erscheint „Übernahme hat nicht geklappt. Füge deinen Schlüssel einfach unten ein.“ und der Schritt funktioniert mit dem Feld weiter wie in AC-4.

### Ohne Internet
- [ ] **AC-10** — Angenommen Groq ist beim Prüfen nicht erreichbar, wenn das Ergebnis erscheint, dann wird der Schlüssel gespeichert und als „noch nicht geprüft“ markiert, „Weiter“ ist frei und InnoWhisper prüft ihn von selbst, sobald Groq wieder erreichbar ist (spätestens beim nächsten Start).

### Einstellungen
- [ ] **AC-11** — Angenommen der Nutzer öffnet den Bereich „Zugang & Erlaubnisse“, wenn er die Gruppe „Groq-Schlüssel“ ansieht, dann steht dort der Stand („Schlüssel funktioniert“, „Noch nicht geprüft“, „Ungültig“ oder „Kein Schlüssel“), vom gespeicherten Schlüssel nur die letzten 4 Zeichen (z. B. „•••• 7Fq2“) und die Knöpfe „Prüfen“, „Ändern“ und „Entfernen“ in gleicher Größe.
- [ ] **AC-12** — Angenommen der Nutzer klickt „Ändern“, wenn er einen neuen Schlüssel einfügt und „Prüfen“ klickt, dann gilt dasselbe wie AC-4 bis AC-6 und AC-10; erst wenn der neue Schlüssel bestätigt oder als „noch nicht geprüft“ gespeichert ist, ersetzt er den alten; bei Ablehnung bleibt der alte erhalten.
- [ ] **AC-13** — Angenommen der Nutzer klickt „Entfernen“, wenn er die Rückfrage „Schlüssel wirklich entfernen? Ohne Schlüssel kann InnoWhisper nicht diktieren.“ bestätigt, dann ist der Schlüssel aus dem Schlüsselbund gelöscht und der Stand heißt „Kein Schlüssel“.

### Warnung bei fehlendem oder ungültigem Schlüssel
- [ ] **AC-14** — Angenommen die Einführung ist abgeschlossen, wenn InnoWhisper startet, dann prüft es den gespeicherten Schlüssel einmal bei Groq; lehnt Groq ihn ab, zeigt das Menüleisten-Symbol den Zustand „Problem“ und das Menüleisten-Fenster sowie der Bereich „Zugang & Erlaubnisse“ den Hinweis „Groq-Schlüssel ungültig.“ mit dem Knopf „Schlüssel ändern“, der direkt zur Gruppe „Groq-Schlüssel“ führt.
- [ ] **AC-15** — Angenommen die Einführung ist abgeschlossen, wenn kein Schlüssel gespeichert ist (z. B. nach „Entfernen“), dann erscheint dasselbe Problem mit dem Text „Kein Groq-Schlüssel.“ und dem Knopf „Schlüssel eintragen“.
- [ ] **AC-16** — Angenommen ein Problem zum Schlüssel wird angezeigt, wenn ein gültiger Schlüssel gespeichert wird, dann verschwinden Hinweis und Warnzeichen sofort, ohne Neustart.

### Schutz des Schlüssels und Protokoll
- [ ] **AC-17** — Angenommen ein Schlüssel ist gespeichert, wenn InnoWhisper ihn ablegt, dann liegt er nur im Schlüsselbund des Nutzers, nie in den Einstellungen, im Protokoll, in Hinweisen, in der Zwischenablage oder in Absturzberichten; angezeigt werden höchstens die letzten 4 Zeichen.
- [ ] **AC-18** — Angenommen eine Prüfung läuft, wenn sie ein Ergebnis hat, dann schreibt das Protokoll nur den Ablauf (Prüfung gestartet, Ergebnis gültig, abgelehnt oder nicht erreichbar, Dauer, Statuscode von Groq), nie den Schlüssel oder Teile davon.

## Edge Cases
- **EC-1** — Angenommen der Nutzer fügt den Schlüssel mit Leerzeichen oder Zeilenumbruch am Anfang oder Ende ein, wenn er „Prüfen“ klickt, dann werden diese vor dem Prüfen entfernt.
- **EC-2** — Angenommen das Feld ist leer, wenn der Nutzer auf „Prüfen“ klicken will, dann ist der Knopf gesperrt.
- **EC-3** — Angenommen eine Prüfung läuft, wenn der Nutzer erneut auf „Prüfen“ klickt, dann passiert nichts: Der Knopf ist bis zum Ergebnis gesperrt und zeigt, dass gerade geprüft wird. So kann niemand Groq mit Anfragen überhäufen.
- **EC-4** — Angenommen Groq meldet „zu viele Anfragen“, wenn die Prüfung antwortet, dann gilt der Schlüssel als funktionierend (Groq hat ihn erkannt).
- **EC-5** — Angenommen Groq antwortet mit einem Serverfehler oder gar nicht innerhalb von 15 Sekunden, wenn das Ergebnis erscheint, dann gilt dasselbe wie AC-10 („noch nicht geprüft“), nicht „abgelehnt“.
- **EC-6** — Angenommen ein Schlüssel ist als „noch nicht geprüft“ gespeichert, wenn die spätere Prüfung ihn ablehnt, dann wird er nicht gelöscht, sondern zeigt den Stand „Ungültig“ mit dem Problem aus AC-14.
- **EC-7** — Angenommen die Einführung wurde mitten im Schritt „Zugangsschlüssel“ beendet, wenn InnoWhisper wieder startet, dann geht es an diesem Schritt weiter (PROJ-3 AC-13); ein schon gespeicherter Schlüssel erledigt den Schritt automatisch.
- **EC-8** — Angenommen der Schlüsselbund ist gesperrt oder verweigert das Speichern, wenn InnoWhisper den Schlüssel ablegen will, dann erscheint „Der Schlüssel konnte nicht gespeichert werden. Bitte versuche es noch einmal.“ und das Protokoll vermerkt den Fehlercode, nicht den Schlüssel.
- **EC-9** — Angenommen die alte App hat keinen Schlüssel gespeichert oder ist nicht installiert, wenn der Schritt erscheint, dann fehlt der Hinweis aus AC-7 und es gibt nur das Feld.

## Technical Requirements (optional)
- Zeitgrenze: AC-4, EC-5 (Prüfung höchstens 15 Sekunden).
- Sicherheit: AC-17, AC-18 (Geheimnis nur im Schlüsselbund, nie im Protokoll; SEC-01). EC-3 verhindert gehäufte Prüfungen.
- Kein Anmeldeweg: Der Schlüssel wird nur gegen Groq geprüft, InnoWhisper hat keine eigenen Konten. Ein Schutz gegen massenhaftes Raten ist deshalb nicht nötig; EC-3 begrenzt die Anfragen pro Klick.
- Personenbezogene Daten: keine. Der Schlüssel ist ein Geheimnis, aber keine Angabe über eine Person; InnoWhisper speichert weder Name noch E-Mail des Groq-Kontos.

## Open Questions
- [ ] Ob macOS beim Lesen des Schlüssels der alten App wirklich nach dem Mac-Passwort fragt (oder gar nicht, oder nur mit „Erlauben“), wird beim Bau gemessen; der Hinweistext in AC-7 wird dann an das tatsächliche Fenster angepasst.

## Decision Log

### Product Decisions
| Decision | Rationale | Date |
|----------|-----------|------|
| Bei Groq bleiben, kein Wechsel zu OpenAI | Vergleich mit 15 echten Diktaten: OpenAI nicht genauer, aber etwa 7-mal teurer (ADR-003, Nachtrag) | 2026-11-06 |
| Jeder Mitarbeiter hat ein eigenes Groq-Konto und trägt seinen Schlüssel selbst ein | Ein gemeinsamer Schlüssel in der App lässt sich auslesen; so lässt sich jeder Schlüssel einzeln sperren (Timur) | 2026-11-06 |
| Schlüssel ist Pflicht in der Einführung, kein Überspringen | Ohne Schlüssel kann InnoWhisper nichts umwandeln (Timur) | 2026-11-06 |
| Schlüssel der alten App wird übernommen, mit angekündigter macOS-Frage | Nutzer müssen ihren Schlüssel nicht suchen; die Ankündigung verhindert, dass das Passwort-Fenster wie Schadsoftware wirkt (Timur, globale Regel 52) | 2026-11-06 |
| Ohne Internet: speichern als „noch nicht geprüft“, später von selbst prüfen | Einrichtung soll nicht an einer fehlenden Verbindung scheitern (Timur) | 2026-11-06 |
| Prüfung bei jedem Start, ungültiger Schlüssel als Problem an der Menüleiste | Nutzer sollen es nicht erst beim nächsten Diktat merken; gleiche Form wie fehlende Erlaubnisse (Timur) | 2026-11-06 |
| Anzeige nur der letzten 4 Zeichen | Man erkennt, welcher Schlüssel drin ist, ohne dass er mitgelesen werden kann | 2026-11-06 |
