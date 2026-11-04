# PROJ-2: Hinweise & Fehlerprotokoll

<!-- This file (spec.md) is the stable CONTRACT — it defines WHAT, not HOW.
     Owner: /write-spec (creates), /refine (updates). During /build this file is READ-ONLY.
     Technical design lives in design.md, QA results in qa-report.md.
     No status or date fields here: the feature's status lives ONLY in features/INDEX.md. -->

## Abhängigkeiten
- Benötigt: PROJ-1 (App-Rahmen & Einstellungen) — Bereich „Allgemein“ nimmt die Gruppen „Töne“ und „Fehlerprotokoll“ auf; die Bestätigung zur alten App wird von dort übernommen.
- Nutzt später: PROJ-8 (Sprechblase am Eingabefeld) liefert die Stelle, an der Hinweise erscheinen. Bis dahin gilt der Rückfall „oben mittig“.
- Gestaltung: `docs/design-system.md` (Glas für schwebende Ebenen, Barrierefreiheit).

## User Stories
- Als Teammitglied möchte ich eine kurze Rückmeldung dort sehen, wo ich gerade schreibe, damit ich weiß, ob mein Diktat angekommen ist, ohne den Blick abzuwenden.
- Als Teammitglied möchte ich hören, wann die Aufnahme startet und endet, damit ich sofort merke, wenn sie nicht startet.
- Als Teammitglied möchte ich Töne ausschalten können, wenn ich in einer ruhigen Umgebung arbeite.
- Als Teammitglied möchte ich Fehler so lange sehen, bis ich sie gelesen habe, damit ich sie nicht verpasse.
- Als Timur möchte ich mir von Kollegen ein Fehlerprotokoll schicken lassen, damit ich Probleme auf ihren Macs nachvollziehen kann.
- Als Teammitglied möchte ich sicher sein, dass im Fehlerprotokoll nie steht, was ich diktiert habe.

## Nicht in diesem Feature
- Wann welcher Hinweis mit welchem Text erscheint (legt das jeweilige Feature fest, z. B. PROJ-6 „Nichts erkannt“, PROJ-7 „Text eingefügt“)
- Die Sprechblase selbst und das Erkennen des Eingabefelds (PROJ-8)
- Versand des Protokolls per Mail aus der App (bewusst nicht, siehe Entscheidungen)
- Mitteilungen in der macOS-Mitteilungszentrale
- Protokoll-Einträge anderer Features im Detail (jedes Feature protokolliert seine Abläufe über diesen Baustein)

## Akzeptanzkriterien

### Hinweise
- [ ] **AC-1** — Angenommen ein Feature zeigt einen Hinweis und ein anderes Feature hat eine Stelle am Eingabefeld gemeldet, wenn der Hinweis erscheint, dann steht er als Glas-Kapsel direkt unter dieser Stelle; ist keine Stelle gemeldet, dann steht er oben mittig unter der Menüleiste auf dem Bildschirm, auf dem der Nutzer gerade arbeitet.
- [ ] **AC-2** — Angenommen ein Feature zeigt einen Hinweis der Art Info, Erfolg oder Fehler, wenn er erscheint, dann trägt er das eigene SF-Symbol seiner Art und den übergebenen Text.
- [ ] **AC-3** — Angenommen ein Hinweis der Art Info oder Erfolg ist zu sehen, wenn 2 Sekunden vergangen sind, dann blendet er sich von selbst aus.
- [ ] **AC-4** — Angenommen ein Hinweis der Art Fehler ist zu sehen, wenn der Nutzer ihn anklickt, Esc drückt oder ein neues Diktat startet, dann verschwindet er; vorher verschwindet er nicht von selbst.
- [ ] **AC-5** — Angenommen ein Hinweis ist zu sehen, wenn ein neuer Hinweis gezeigt wird, dann ersetzt der neue den alten; es ist nie mehr als ein Hinweis gleichzeitig zu sehen.
- [ ] **AC-6** — Angenommen der Nutzer schreibt in einem anderen Programm, wenn ein Hinweis erscheint, dann bleibt die Tastatur bei diesem Programm, und der Nutzer kann ohne Klick weitertippen.
- [ ] **AC-7** — Angenommen VoiceOver, „Bewegung reduzieren“ oder „Transparenz reduzieren“ ist eingeschaltet, wenn ein Hinweis erscheint, dann liest VoiceOver ihn vor, er erscheint ohne Animation bzw. als feste Fläche statt Glas.
- [ ] **AC-8** — Angenommen der Nutzer hat die alte App über „Alte Version beenden“ beendet, wenn das gelingt, dann erscheint „Die alte Version wurde beendet.“ als Hinweis der Art Erfolg statt als Fenster mit OK-Knopf.

### Töne
- [ ] **AC-9** — Angenommen Töne sind eingeschaltet, wenn eine Aufnahme startet bzw. endet, dann spielt ein kurzer, leiser Klang für den Start und ein anderer für das Ende; bei Fehlern spielt kein zusätzlicher Ton.
- [ ] **AC-10** — Angenommen InnoWhisper wurde gerade installiert, wenn der Nutzer „Allgemein“ öffnet, dann ist der Schalter „Töne bei Start und Ende“ eingeschaltet; schaltet er ihn aus, dann spielen keine Töne mehr, auch nicht nach einem Neustart der App.

### Fehlerprotokoll
- [ ] **AC-11** — Angenommen InnoWhisper läuft, wenn technische Abläufe passieren (Start, Erlaubnisse, Tastenkürzel, Aufnahme gestartet/gestoppt, Fehler mit Ursache), dann schreibt die App je einen Eintrag mit Zeitpunkt in eine Protokolldatei auf dem Mac.
- [ ] **AC-12** — Angenommen ein Feature schreibt ins Protokoll, wenn die Datei gelesen wird, dann enthält sie nie diktierten oder umgewandelten Text, nie Inhalte der Zwischenablage und nie den Groq-Zugangsschlüssel.
- [ ] **AC-13** — Angenommen das Protokoll enthält Einträge, die älter als 7 Tage sind, oder wird größer als 10 MB, wenn die App startet oder schreibt, dann werden die ältesten Einträge entfernt, bis beides wieder eingehalten ist.
- [ ] **AC-14** — Angenommen der Nutzer ist im Bereich „Allgemein“, wenn er in der Gruppe „Fehlerprotokoll“ auf „Fehlerprotokoll zeigen“ klickt, dann öffnet sich der Finder mit der markierten Protokolldatei.

## Sonderfälle
- [ ] **EC-1** — Angenommen mehrere Bildschirme sind angeschlossen, wenn ein Hinweis ohne gemeldete Stelle erscheint, dann erscheint er auf dem Bildschirm mit dem aktiven Eingabefeld, sonst auf dem Bildschirm mit dem Mauszeiger.
- [ ] **EC-2** — Angenommen ein Programm läuft im Vollbild, wenn ein Hinweis erscheint, dann ist er über diesem Programm sichtbar.
- [ ] **EC-3** — Angenommen die Protokolldatei lässt sich nicht schreiben (z. B. Festplatte voll), wenn die App protokollieren will, dann läuft sie ohne Fehlermeldung an den Nutzer weiter, und der Knopf in „Allgemein“ zeigt „Fehlerprotokoll nicht verfügbar“.
- [ ] **EC-4** — Angenommen es gibt noch keine Protokolldatei, wenn der Nutzer „Fehlerprotokoll zeigen“ klickt, dann wird eine leere Datei angelegt und im Finder markiert.
- [ ] **EC-5** — Angenommen ein Ton spielt noch, wenn der nächste Ton fällig ist, dann bricht der alte ab und der neue spielt.

## Technische Anforderungen
- Plattform: macOS 26 oder neuer (ADR-001).
- Zeitgrenze: AC-3 (2 Sekunden Anzeigedauer).
- Personenbezogene Daten: Das Protokoll enthält keine Diktat-Inhalte (AC-12); technische Angaben wie Programmkennungen und Zeitpunkte bleiben nur auf dem Mac. Datenschutzrecht laut Projekt: keins eingetragen (ADR-006), daher keine `/dsgvo`-Prüfung.

## Offene Fragen
- (keine)

## Entscheidungsprotokoll

### Produktentscheidungen
| Entscheidung | Begründung | Datum |
|--------------|------------|-------|
| Hinweise am Eingabefeld, sonst oben mittig | Dort schaut der Nutzer ohnehin hin; wie in der alten App | 2026-11-04 |
| Info und Erfolg 2 Sekunden, Fehler bis zum Wegklicken | Erfolg soll nicht stören, Fehler darf nicht verpasst werden | 2026-11-04 |
| Immer nur ein Hinweis | Kein Stapel, der das Eingabefeld verdeckt | 2026-11-04 |
| Töne ab Installation an, kein Fehlerton | Fehlender Startton zeigt sofort, dass die Aufnahme nicht läuft (Pflichtpunkt 1); Fehler sind schon sichtbar | 2026-11-04 |
| Fehlerprotokoll über „Im Finder zeigen“ | Funktioniert auf jedem Mac, unabhängig vom Mailprogramm | 2026-11-04 |
| Protokoll 7 Tage, höchstens 10 MB | Reicht für die Fehlersuche, bleibt klein | 2026-11-04 |
| Bestätigung zur alten App als Hinweis | Ersetzt das Übergangsfenster aus PROJ-1 (siehe dort `design.md`) | 2026-11-04 |
