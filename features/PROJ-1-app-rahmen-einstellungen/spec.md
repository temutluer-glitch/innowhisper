# PROJ-1: App-Rahmen & Einstellungen

<!-- This file (spec.md) is the stable CONTRACT — it defines WHAT, not HOW.
     Owner: /write-spec (creates), /refine (updates). During /build this file is READ-ONLY.
     Technical design lives in design.md, QA results in qa-report.md.
     No status or date fields here: the feature's status lives ONLY in features/INDEX.md. -->

## Abhängigkeiten
- Keine. Andere Features liefern Zustände (z. B. „nimmt auf“), Problem-Hinweise und Bereiche, die dieser Rahmen anzeigt.
- Rahmen und Bereiche: `docs/app-shell.md`. Gestaltung: `docs/design-system.md`.

## User Stories
- Als Teammitglied möchte ich InnoWhisper als Symbol in der Menüleiste sehen, damit ich auf einen Blick weiß, ob es bereit ist.
- Als Teammitglied möchte ich alle Einstellungen in einem aufgeräumten Fenster mit klaren Bereichen finden, damit ich nichts suchen muss.
- Als Teammitglied möchte ich, dass InnoWhisper nach einem Neustart von selbst wieder läuft, damit das Tastenkürzel immer funktioniert.
- Als Teammitglied, das von der alten App umzieht, möchte ich gewarnt werden, wenn die alte Version noch läuft, und sie mit einem Klick beenden, damit sich die beiden Apps nicht in die Quere kommen.
- Als Teammitglied möchte ich ein laufendes Diktat nicht aus Versehen durch Beenden verlieren.
- Als Teammitglied mit MacBook möchte ich die Einstellungen auch dann erreichen, wenn das Menüleisten-Symbol hinter der Kamera-Aussparung verschwindet.

## Nicht in diesem Feature
- Inhalte der übrigen Einstellungsbereiche (je eigenes Feature, siehe `docs/app-shell.md`)
- Einführung beim ersten Start und Erlaubnisse (PROJ-3)
- Hinweise, Töne, Fehlerprotokoll (PROJ-2)
- Letztes Diktat und Schnellwahl im Menüleisten-Fenster (PROJ-13)
- Updates, Info-Bereich, Auslieferung, Umzugsanleitung (PROJ-14)
- Löschen der alten App vom Mac (macht der Nutzer selbst, steht in der Umzugsanleitung von PROJ-14)
- Übernahme von Einstellungen oder Wörterbuch aus der alten App (offene Frage, siehe unten)

## Akzeptanzkriterien

### Menüleiste
- [ ] **AC-1** — Angenommen InnoWhisper läuft, wenn der Nutzer auf die Menüleiste schaut, dann sieht er das InnoWhisper-Symbol, und weder im Dock noch im App-Umschalter (⌘-Tab) erscheint die App.
- [ ] **AC-2** — Angenommen die App wechselt zwischen den Zuständen „bereit“, „nimmt auf“, „wandelt um“ und „Problem“, wenn sich der Zustand ändert, dann zeigt das Menüleisten-Symbol innerhalb von 0,5 Sekunden das eigene Symbol dieses Zustands, und VoiceOver liest den Zustand als Text vor.
- [ ] **AC-3** — Angenommen das Menüleisten-Fenster ist geschlossen, wenn der Nutzer auf das Symbol klickt, dann öffnet es sich; wenn er danach daneben klickt oder Esc drückt, dann schließt es sich.
- [ ] **AC-4** — Angenommen das Menüleisten-Fenster ist offen, wenn der Nutzer hineinschaut, dann sieht er immer die Knöpfe „Einstellungen …“ und „InnoWhisper beenden“.

### Einstellungsfenster
- [ ] **AC-5** — Angenommen das Einstellungsfenster ist geschlossen, wenn der Nutzer „Einstellungen …“ klickt oder bei offenem Menüleisten-Fenster ⌘, drückt, dann öffnet sich das Einstellungsfenster; ist es bereits offen, dann kommt es nach vorne, und es gibt nie zwei Einstellungsfenster.
- [ ] **AC-6** — Angenommen InnoWhisper läuft bereits, wenn der Nutzer die App erneut über den Programme-Ordner oder Spotlight öffnet, dann öffnet sich das Einstellungsfenster.
- [ ] **AC-7** — Angenommen das Einstellungsfenster ist offen, wenn der Nutzer links in der Seitenleiste einen Bereich anklickt, dann zeigt der rechte Teil diesen Bereich; die Seitenleiste zeigt jeden Bereich mit SF-Symbol und Namen in der Reihenfolge aus `docs/app-shell.md`.
- [ ] **AC-8** — Angenommen das Feature eines Bereichs ist noch nicht gebaut, wenn der Nutzer das Einstellungsfenster öffnet, dann erscheint dieser Bereich nicht in der Seitenleiste; PROJ-1 liefert den Bereich „Allgemein“.
- [ ] **AC-9** — Angenommen der Nutzer hat zuletzt einen bestimmten Bereich benutzt, wenn er das Einstellungsfenster erneut öffnet, dann zeigt es diesen Bereich; beim allerersten Öffnen zeigt es „Allgemein“.
- [ ] **AC-10** — Angenommen ein Feature meldet ein Problem für einen Bereich (z. B. fehlende Erlaubnis), wenn der Nutzer diesen Bereich ansieht, dann steht oben ein Hinweis mit Warnsymbol, einem verständlichen Satz und einem Lösungsknopf; ist das Problem gelöst, dann verschwindet der Hinweis ohne Neustart.
- [ ] **AC-11** — Angenommen ein Problem-Hinweis wird an anderer Stelle angezeigt (z. B. im Menüleisten-Fenster), wenn der Nutzer dessen Knopf zum Öffnen der Einstellungen klickt, dann öffnet sich das Einstellungsfenster direkt im betroffenen Bereich.
- [ ] **AC-12** — Angenommen der Nutzer ändert Größe oder Position des Einstellungsfensters, wenn er es schließt und wieder öffnet (auch nach Neustart der App), dann hat es dieselbe Größe und Position; kleiner als die festgelegte Mindestgröße lässt es sich nicht ziehen.

### Start beim Anmelden
- [ ] **AC-13** — Angenommen InnoWhisper wurde zum ersten Mal gestartet, wenn der Nutzer den Bereich „Allgemein“ öffnet, dann ist „Start beim Anmelden“ eingeschaltet, und nach dem nächsten Anmelden am Mac startet InnoWhisper von selbst.
- [ ] **AC-14** — Angenommen „Start beim Anmelden“ ist eingeschaltet, wenn der Nutzer den Schalter ausschaltet und sich neu am Mac anmeldet, dann startet InnoWhisper nicht von selbst.
- [ ] **AC-15** — Angenommen der Nutzer hat den automatischen Start in den macOS-Systemeinstellungen geändert, wenn er danach den Bereich „Allgemein“ öffnet, dann zeigt der Schalter den tatsächlichen Stand aus macOS.

### Alte App
- [ ] **AC-16** — Angenommen die alte App läuft, wenn InnoWhisper startet, dann erscheint die Meldung „Die alte Version läuft noch und stört das Diktieren.“ mit den Knöpfen „Alte Version beenden“ und „Später“.
- [ ] **AC-17** — Angenommen die Meldung aus AC-16 ist zu sehen, wenn der Nutzer „Alte Version beenden“ klickt, dann wird die alte App beendet, und eine kurze Bestätigung erscheint.
- [ ] **AC-18** — Angenommen der Nutzer hat „Später“ gewählt, solange die alte App läuft, dann zeigt das Menüleisten-Symbol den Zustand „Problem“, und im Menüleisten-Fenster steht ein Hinweis mit dem Knopf „Alte Version beenden“; sobald die alte App nicht mehr läuft, verschwinden beide.

### Beenden
- [ ] **AC-19** — Angenommen es läuft kein Diktat, wenn der Nutzer „InnoWhisper beenden“ klickt oder ⌘Q drückt, dann beendet sich die App sofort ohne Rückfrage.
- [ ] **AC-20** — Angenommen eine Aufnahme oder Umwandlung läuft, wenn der Nutzer „InnoWhisper beenden“ klickt oder ⌘Q drückt, dann erscheint die Rückfrage „Ein Diktat läuft noch. Wenn du jetzt beendest, geht es verloren. Trotzdem beenden?“; „Abbrechen“ lässt das Diktat weiterlaufen, „Beenden“ beendet die App.

### Aussehen und Bedienbarkeit
- [ ] **AC-21** — Angenommen der Mac ist im Hell- oder Dunkelmodus, wenn der Nutzer Menüleisten-Fenster und Einstellungsfenster ansieht, dann folgen beide `docs/design-system.md`: Liquid Glass im Menüleisten-Fenster, alle Knöpfe einer Fläche in derselben Größe, Text gut lesbar in beiden Modi.
- [ ] **AC-22** — Angenommen „Transparenz reduzieren“ ist in macOS eingeschaltet, wenn der Nutzer das Menüleisten-Fenster öffnet, dann erscheint statt Glas eine feste Fläche.
- [ ] **AC-23** — Angenommen der Nutzer bedient den Mac nur per Tastatur oder mit VoiceOver, wenn er Menüleisten-Fenster und Einstellungsfenster benutzt, dann ist jedes Bedienelement erreichbar, hat einen sichtbaren Fokus und eine Beschriftung, die VoiceOver vorliest.

## Sonderfälle
- [ ] **EC-1** — Angenommen InnoWhisper läuft, wenn der Nutzer es ein zweites Mal startet (auch aus einem anderen Ordner), dann läuft weiterhin nur eine InnoWhisper-App, und die laufende öffnet ihr Einstellungsfenster.
- [ ] **EC-2** — Angenommen InnoWhisper läuft bereits, wenn danach die alte App gestartet wird, dann erscheint dieselbe Meldung wie in AC-16.
- [ ] **EC-3** — Angenommen der Nutzer klickt „Alte Version beenden“, wenn sich die alte App innerhalb von 5 Sekunden nicht beenden lässt, dann erklärt eine Meldung in einfachen Schritten, wie der Nutzer sie selbst beendet.
- [ ] **EC-4** — Angenommen macOS lässt „Start beim Anmelden“ nicht zu (z. B. weil die App nicht im Programme-Ordner liegt), wenn der Schalter eingeschaltet wird oder beim ersten Start eingeschaltet werden soll, dann steht der Schalter auf aus, und ein Hinweis nennt Grund und Lösung.
- [ ] **EC-5** — Angenommen ein Diktat läuft, wenn der Mac heruntergefahren, neu gestartet oder der Nutzer abgemeldet wird, dann hält InnoWhisper das nicht mit einer Rückfrage auf; das Diktat geht verloren.
- [ ] **EC-6** — Angenommen das Einstellungsfenster lag zuletzt auf einem Bildschirm, der nicht mehr angeschlossen ist, wenn der Nutzer es öffnet, dann erscheint es vollständig sichtbar auf dem Hauptbildschirm.

## Technische Anforderungen
- Plattform: macOS 26 oder neuer (ADR-001).
- Zeitgrenze: AC-2 (Zustandswechsel des Symbols innerhalb von 0,5 Sekunden).
- Die alte App wird an ihrer Kennung `com.innosolv.WhisperDictation` erkannt (Kennung der alten App, nur zum Erkennen, nicht zur Übernahme).
- Personenbezogene Daten: dieses Feature speichert keine, nur Einstellungen (Bereich, Fenstergröße, Start beim Anmelden).

## Offene Fragen
- [ ] Sollen Einstellungen und Wörterbuch aus der alten App übernommen werden? Klären bei PROJ-9 (Wörterbuch) bzw. PROJ-14 (Auslieferung).
- [ ] Löst das normale Beenden der alten App eine macOS-Rückfrage aus? Beim Bau prüfen (siehe `design.md`).
- [ ] Schließt Esc das Menüleisten-Fenster von selbst? Beim Bau prüfen (AC-3 gilt so oder so).

## Entscheidungsprotokoll

### Produktentscheidungen
| Entscheidung | Begründung | Datum |
|--------------|------------|-------|
| Kein Dock-Symbol, nur Menüleiste | Wie bisher; Diktier-Werkzeug soll im Hintergrund bleiben | 2026-11-04 |
| Läuft die alte App, wird angeboten, sie per Knopf zu beenden | Zwei Apps auf demselben Tastenkürzel können wie „Aufnahme startet nicht“ aussehen (Pflichtpunkt 1); Knopf ist für Nicht-Techniker am einfachsten | 2026-11-04 |
| „Start beim Anmelden“ ist von Anfang an eingeschaltet | In der alten App war es aus; nach Neustart fehlte die App und das wirkte wie ein Fehler | 2026-11-04 |
| Rückfrage beim Beenden nur, wenn ein Diktat läuft | Lange Diktate sollen nicht versehentlich verloren gehen; sonst keine unnötige Rückfrage | 2026-11-04 |
| ⌘, öffnet die Einstellungen | macOS-Standard | 2026-11-04 |
| Bereiche erscheinen erst, wenn ihr Feature gebaut ist | Keine leeren Platzhalter-Seiten in der App | 2026-11-04 |
| Beim Herunterfahren keine Rückfrage | Die App darf das Herunterfahren nicht blockieren; Datenverlust in diesem seltenen Fall akzeptiert | 2026-11-04 |
| Erneutes Öffnen der App öffnet die Einstellungen | Notausgang, wenn das Symbol hinter der Kamera-Aussparung verschwindet | 2026-11-04 |
