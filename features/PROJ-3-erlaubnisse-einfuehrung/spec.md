# PROJ-3: Erlaubnisse & Einführung

<!-- This file (spec.md) is the stable CONTRACT — it defines WHAT, not HOW.
     Owner: /write-spec (creates), /refine (updates). During /build this file is READ-ONLY.
     Technical design lives in design.md, QA results in qa-report.md.
     No status or date fields here: the feature's status lives ONLY in features/INDEX.md. -->

## Abhängigkeiten
- Benötigt: PROJ-1 (App-Rahmen & Einstellungen): Menüleisten-Symbol mit Zustand „Problem“, Problem-Hinweis mit Lösungsknopf, Bereich „Zugang & Erlaubnisse“ im Einstellungsfenster.
- Benötigt: PROJ-2 (Hinweise & Fehlerprotokoll): Protokoll-Einträge zu Erlaubnissen und zur Einführung.
- Wird erweitert von: PROJ-4 (Schritt „Zugangsschlüssel“), PROJ-5 (Schritte „Mikrofon wählen“ und „Tastenkürzel“), PROJ-7 (Schritt „Probe-Diktat“). Diese Features fügen ihre Schritte in die Einführung ein; PROJ-3 baut den Rahmen dafür.
- Nutzt später: PROJ-5 zeigt beim Drücken des Tastenkürzels den Hinweis „Mikrofon nicht erlaubt“ bzw. „Bedienungshilfen nicht erlaubt“, wenn eine Erlaubnis fehlt (siehe AC-15).
- Gestaltung: `docs/design-system.md`.

## User Stories
- Als neues Teammitglied möchte ich beim ersten Start Schritt für Schritt durch die Einrichtung geführt werden, damit ich ohne Hilfe loslegen kann.
- Als Teammitglied möchte ich genau verstehen, warum InnoWhisper Mikrofon und Bedienungshilfen braucht, damit ich die Erlaubnisse ohne Sorge erteile.
- Als Teammitglied möchte ich, dass die App eine erteilte Erlaubnis sofort erkennt, damit ich nichts neu starten muss.
- Als Teammitglied möchte ich, wenn ich „Nicht erlauben“ geklickt habe, mit einem Knopf direkt an die richtige Stelle in den Systemeinstellungen kommen, damit ich es leicht korrigieren kann.
- Als Teammitglied möchte ich sofort sehen, wenn später eine Erlaubnis fehlt, damit ich mich nicht wundere, warum das Diktieren nicht klappt.
- Als Teammitglied möchte ich nach einem Update nur die neuen Einrichtungsschritte sehen, damit ich Erledigtes nicht noch einmal durchklicke.

## Nicht in diesem Feature
- Schritte für Zugangsschlüssel (PROJ-4), Mikrofon-Wahl und Tastenkürzel (PROJ-5) und Probe-Diktat (PROJ-7); sie werden von dort in die Einführung eingefügt.
- Der Hinweis beim Drücken des Tastenkürzels, wenn eine Erlaubnis fehlt (PROJ-5, siehe AC-15).
- Weitere macOS-Erlaubnisse (z. B. Bildschirmaufnahme); InnoWhisper braucht nur Mikrofon und Bedienungshilfen.
- Ein Knopf „Einführung erneut zeigen“ (bewusst nicht, siehe Entscheidungen).
- Die Umzugsanleitung von der alten App fürs Team (PROJ-14).

## Akzeptanzkriterien

### Einführung: Ablauf
- [ ] **AC-1** — Angenommen InnoWhisper wird auf diesem Mac zum ersten Mal gestartet, wenn die App startet, dann öffnet sich die Einführung als eigenes Fenster in der Bildschirmmitte, vor allen anderen Fenstern, mit den Schritten in dieser Reihenfolge: Willkommen, Mikrofon, Bedienungshilfen, Fertig.
- [ ] **AC-2** — Angenommen die Einführung ist offen, wenn der Nutzer hineinschaut, dann sieht er, bei welchem Schritt er ist und wie viele es gibt (z. B. „Schritt 2 von 4“).
- [ ] **AC-3** — Angenommen der Nutzer ist im Schritt „Willkommen“, wenn er ihn ansieht, dann steht dort: „Willkommen bei InnoWhisper. Tastenkürzel drücken, sprechen, und dein Text erscheint dort, wo du gerade schreibst. Damit das klappt, braucht InnoWhisper zwei Erlaubnisse von dir.“ mit dem Knopf „Los geht's“.
- [ ] **AC-4** — Angenommen der Nutzer ist im Schritt „Fertig“, wenn er ihn ansieht, dann steht dort: „Alles bereit. Du findest InnoWhisper ab jetzt oben rechts in der Menüleiste.“ mit dem Knopf „Fertig“; ein Klick darauf schließt die Einführung endgültig.
- [ ] **AC-5** — Angenommen der Nutzer ist in einem Schritt nach „Willkommen“, wenn er „Zurück“ klickt, dann sieht er den vorigen Schritt; bereits erteilte Erlaubnisse bleiben dabei erteilt.

### Einführung: Erlaubnis-Schritte
- [ ] **AC-6** — Angenommen der Nutzer ist im Schritt „Mikrofon“ oder „Bedienungshilfen“, wenn er ihn ansieht, dann erklärt ein kurzer Satz, wofür InnoWhisper diese Erlaubnis braucht (Mikrofon: um deine Stimme aufzunehmen; Bedienungshilfen: um das Eingabefeld zu finden und den Text dort einzufügen), und ein Knopf startet das Erlauben.
- [ ] **AC-7** — Angenommen die Erlaubnis dieses Schritts fehlt, wenn der Nutzer den Schritt ansieht, dann ist „Weiter“ gesperrt; der Schritt lässt sich nicht überspringen.
- [ ] **AC-8** — Angenommen der Nutzer ist im Schritt „Mikrofon“ und wurde noch nie gefragt, wenn er „Mikrofon erlauben“ klickt, dann erscheint die macOS-Abfrage; klickt er dort „Erlauben“, dann zeigt der Schritt innerhalb von 2 Sekunden ein grünes Häkchen mit „Erlaubt“, und „Weiter“ wird frei.
- [ ] **AC-9** — Angenommen der Nutzer ist im Schritt „Bedienungshilfen“, wenn er „In den Systemeinstellungen erlauben“ klickt, dann öffnen sich die macOS-Systemeinstellungen genau bei „Datenschutz & Sicherheit → Bedienungshilfen“, und ein Satz im Schritt sagt, was dort zu tun ist (InnoWhisper einschalten).
- [ ] **AC-10** — Angenommen der Nutzer hat eine Erlaubnis in den Systemeinstellungen eingeschaltet, wenn er zur Einführung zurückkehrt, dann zeigt der Schritt innerhalb von 2 Sekunden „Erlaubt“, und „Weiter“ wird frei, ohne dass die App neu gestartet werden muss.
- [ ] **AC-11** — Angenommen der Nutzer hat in der macOS-Abfrage zum Mikrofon „Nicht erlauben“ geklickt, wenn er den Schritt danach ansieht, dann erklärt ein Satz, dass die Erlaubnis jetzt nur noch in den Systemeinstellungen erteilt werden kann, und der Knopf „In den Systemeinstellungen erlauben“ öffnet „Datenschutz & Sicherheit → Mikrofon“.

### Einführung: Fenster
- [ ] **AC-12** — Angenommen die Einführung ist offen und noch nicht fertig, wenn der Nutzer das Fenster ansieht, dann hat es keinen Knopf zum Schließen, und Esc oder ⌘W schließen es nicht; andere Programme und die Systemeinstellungen bleiben dabei normal bedienbar.
- [ ] **AC-13** — Angenommen die Einführung ist noch nicht fertig, wenn der Nutzer InnoWhisper beendet (Menüleiste „InnoWhisper beenden“ oder ⌘Q) und wieder startet, dann öffnet sich die Einführung beim ersten noch nicht erledigten Schritt.
- [ ] **AC-14** — Angenommen die Einführung ist noch nicht fertig, wenn der Nutzer im Menüleisten-Fenster „Einstellungen …“ klickt oder InnoWhisper erneut über den Programme-Ordner oder Spotlight öffnet, dann kommt die Einführung nach vorne, und das Einstellungsfenster öffnet sich nicht; „InnoWhisper beenden“ funktioniert wie gewohnt.

### Erlaubnisse nach der Einführung
- [ ] **AC-15** — Angenommen die Einführung ist fertig, wenn Mikrofon oder Bedienungshilfen danach entzogen werden (z. B. in den Systemeinstellungen), dann zeigt das Menüleisten-Symbol innerhalb von 5 Sekunden den Zustand „Problem“, und die Einführung erscheint nicht erneut; die Erlaubnis bleibt als Problem gemeldet, bis sie wieder erteilt ist.
- [ ] **AC-16** — Angenommen eine Erlaubnis fehlt, wenn der Nutzer das Menüleisten-Fenster oder den Bereich „Zugang & Erlaubnisse“ ansieht, dann steht dort ein Problem-Hinweis („Mikrofon nicht erlaubt.“ bzw. „Bedienungshilfen nicht erlaubt.“) mit dem Knopf „Jetzt erlauben“, der direkt an die richtige Stelle der Systemeinstellungen führt; ist die Erlaubnis wieder da, verschwinden Hinweis und Warnzeichen innerhalb von 5 Sekunden ohne Neustart.
- [ ] **AC-17** — Angenommen der Nutzer öffnet den Bereich „Zugang & Erlaubnisse“, wenn er ihn ansieht, dann zeigt eine Gruppe „Erlaubnisse“ für Mikrofon und Bedienungshilfen je den Stand („Erlaubt“ mit grünem Häkchen oder „Nicht erlaubt“ mit dem Knopf „Jetzt erlauben“).

### Neue Schritte nach einem Update
- [ ] **AC-18** — Angenommen der Nutzer hat die Einführung abgeschlossen, wenn eine neuere Version von InnoWhisper einen neuen Einführungs-Schritt mitbringt, dann öffnet sich beim nächsten Start die Einführung nur mit den neuen, noch nicht erledigten Schritten und dem Schritt „Fertig“; bereits erledigte Schritte erscheinen nicht noch einmal.
- [ ] **AC-19** — Angenommen ein neuer Erlaubnis-Schritt aus AC-18 ist schon erfüllt (die Erlaubnis ist bereits da), wenn die App startet, dann gilt er als erledigt, und die Einführung öffnet sich seinetwegen nicht.

### Protokoll und Bedienung
- [ ] **AC-20** — Angenommen InnoWhisper läuft, wenn sich der Stand einer Erlaubnis ändert oder ein Einführungs-Schritt erledigt wird, dann steht ein Eintrag mit Erlaubnis bzw. Schritt und neuem Stand im Fehlerprotokoll (PROJ-2).
- [ ] **AC-21** — Angenommen der Nutzer bedient den Mac nur per Tastatur oder mit VoiceOver, wenn er die Einführung benutzt, dann ist jedes Bedienelement erreichbar, hat einen sichtbaren Fokus und eine Beschriftung, die VoiceOver vorliest; der Stand „Erlaubt“ wird angesagt, sobald er sich ändert.
- [ ] **AC-22** — Angenommen der Mac ist im Hell- oder Dunkelmodus, wenn der Nutzer die Einführung ansieht, dann folgt sie `docs/design-system.md` (SF-Symbole, alle Knöpfe eines Schritts in derselben Größe, Text gut lesbar in beiden Modi).

## Sonderfälle
- [ ] **EC-1** — Angenommen beide Erlaubnisse sind beim ersten Start schon erteilt (z. B. nach einer Neuinstallation), wenn die Einführung erscheint, dann zeigen beide Erlaubnis-Schritte sofort „Erlaubt“, und „Weiter“ ist frei.
- [ ] **EC-2** — Angenommen der Nutzer entzieht während der Einführung eine Erlaubnis, die er in einem früheren Schritt schon erteilt hatte, wenn er zum nächsten Schritt geht oder „Fertig“ klickt, dann springt die Einführung zurück zu diesem Erlaubnis-Schritt.
- [ ] **EC-3** — Angenommen der Nutzer hat eine Erlaubnis in den Systemeinstellungen erteilt, wenn die App sie nach 10 Sekunden noch immer nicht erkennt, dann bietet der Schritt den Knopf „InnoWhisper neu starten“ an; nach dem Neustart geht die Einführung am selben Schritt weiter.
- [ ] **EC-4** — Angenommen die alte App läuft beim ersten Start, wenn die Einführung erscheint, dann erscheint die Meldung zur alten App (PROJ-1, AC-16) erst nach der Einführung, damit nicht zwei Fenster gleichzeitig um Aufmerksamkeit kämpfen.
- [ ] **EC-5** — Angenommen mehrere Bildschirme sind angeschlossen, wenn die Einführung erscheint, dann erscheint sie auf dem Bildschirm mit dem Mauszeiger.

## Technische Anforderungen
- Plattform: macOS 26 oder neuer (ADR-001).
- Zeitgrenzen: AC-8 und AC-10 (Erlaubnis in der Einführung innerhalb von 2 Sekunden erkannt), AC-15 und AC-16 (Problem-Zustand nach Entzug bzw. Wiedererteilung innerhalb von 5 Sekunden), EC-3 (Neustart-Angebot nach 10 Sekunden).
- Personenbezogene Daten: keine. Gespeichert wird nur, welche Schritte erledigt sind. Datenschutzrecht laut Projekt: keins eingetragen (ADR-006), daher keine `/dsgvo`-Prüfung.

## Offene Fragen
- [x] AC-14 ändert für die Dauer der Einführung das Verhalten aus PROJ-1 (AC-5 und AC-6: „Einstellungen …“ bzw. erneutes Öffnen zeigt sonst das Einstellungsfenster). In `/architecture` klären, ob das über einen Andockpunkt im Rahmen geht oder eine kleine Änderung an PROJ-1 (`/refine PROJ-1`) braucht. → Gelöst in `design.md`: eine Stelle im App-Zusammenbau, `AppShell` bleibt unverändert; PROJ-1 bekommt dazu einen Satz.
- [x] `docs/app-shell.md` nennt die Einführung noch „beim ersten Start oder bei fehlender Erlaubnis“; nach der Entscheidung „Warnung + Hinweis“ gilt nur noch „beim ersten Start und bei neuen Schritten“. In `/architecture` anpassen. → Angepasst.

## Entscheidungsprotokoll

### Produktentscheidungen
| Entscheidung | Begründung | Datum |
|--------------|------------|-------|
| Die Einführung wächst mit den Features | PROJ-3 baut Rahmen, Willkommen, Erlaubnisse und Fertig; Schlüssel, Mikrofon-Wahl, Tastenkürzel und Probe-Diktat kommen mit ihren Features dazu | 2026-11-05 |
| Erlaubnis-Schritte lassen sich nicht überspringen | Ohne Mikrofon und Bedienungshilfen funktioniert das Diktieren nicht (Pflichtpunkt 1) | 2026-11-05 |
| Erteilte Erlaubnis wird ohne Neustart erkannt | Ein Neustart ist für Nicht-Techniker eine unnötige Hürde | 2026-11-05 |
| Nach „Nicht erlauben“ führt ein Knopf direkt in die Systemeinstellungen | macOS fragt kein zweites Mal; ohne direkten Weg findet niemand die Stelle | 2026-11-05 |
| Einführungsfenster ist bis zum Ende nicht schließbar; Beenden geht, Neustart setzt am selben Schritt fort | Die Einrichtung soll nicht halb liegen bleiben | 2026-11-05 |
| Später fehlende Erlaubnis: Warnzeichen und Hinweis statt erneuter Einführung | Wer schon eingerichtet ist, soll nicht von einem nicht schließbaren Fenster überrascht werden | 2026-11-05 |
| Nach einem Update nur die neuen Schritte zeigen | Niemand wird allein gelassen, Erledigtes muss nicht erneut durchgeklickt werden | 2026-11-05 |
| Während der Einführung holt „Einstellungen …“ die Einführung nach vorne | Ohne Erlaubnisse lässt sich in den Einstellungen nichts Sinnvolles tun; der Weg bleibt eindeutig | 2026-11-05 |
| Texte für Willkommen und Fertig in der Du-Form wie in AC-3 und AC-4 | Internes Werkzeug fürs Team, kurz und verständlich | 2026-11-05 |
| Kein Knopf „Einführung erneut zeigen“ | Alles, was die Einführung kann, gibt es auch im Bereich „Zugang & Erlaubnisse“ | 2026-11-05 |
