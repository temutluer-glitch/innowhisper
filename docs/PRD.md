# Produktplan (PRD)

## Ziel
InnoWhisper ist eine Mac-App in der Menüleiste: Tastenkürzel drücken, sprechen, und der fertige Text erscheint im Eingabefeld, in dem man gerade arbeitet. Die neue Version ersetzt die alte App (letzter Stand 1.3.2) komplett. Sie kann von Anfang an alles, was die alte konnte, und löst die sechs bekannten Probleme (Pflichtpunkte unten).

## Zielgruppe
Timur und das InnoSolv-Team. Sie diktieren täglich E-Mails, Notizen und Nachrichten in beliebige Programme. Sie brauchen eine Aufnahme, die zuverlässig startet, auch lange Diktate schafft, Kundennamen und Fachbegriffe richtig schreibt und nichts dazuerfindet. Die Nutzer sind keine Techniker: Fehler müssen verständlich erklärt werden, und die Einrichtung muss ohne Hilfe klappen.

## Kernfunktionen (Roadmap)
Die erste Version hat den vollen Umfang der alten App, es gibt keine abgespeckte Vorversion (Entscheidung vom 04.11.2026):
- Tastenkürzel (gedrückt halten oder ein/aus), mehrere Kürzel mit eigener KI-Vorlage, einzelne Tasten wie rechte ⌥ oder Fn
- Modellwahl („schnell“ / „genauer“), Sprachhinweis
- Text direkt einfügen oder nur in die Zwischenablage
- KI-Nachbearbeitung mit Vorlagen (Standard „Ohne KI“)
- Wörterbuch, Textersetzungen, gesprochene Satzzeichen
- Verlauf der letzten 50 Diktate (kopieren, löschen, noch einmal umwandeln)
- Verwerfen stiller Aufnahmen, Abbruch mit Esc
- Sprechblase mit Tonwelle am Eingabefeld
- Menüleisten-Fenster mit letztem Diktat und Schnellwahl von Mikrofon und Sprache
- Hinweise, Töne, Start beim Anmelden, Einführung beim ersten Start, automatische Updates
- Hinweis bei fehlenden Erlaubnissen, Fehlerprotokoll ohne Diktat-Inhalte

Die einzelnen Features, ihr Status und die Bau-Reihenfolge stehen ausschließlich in `features/INDEX.md`.

### Pflichtpunkte (müssen in der ersten Version gelöst sein)
1. Die Aufnahme startet jedes Mal zuverlässig.
2. Lange Aufnahmen funktionieren, Ziel: mindestens 10 Minuten am Stück, auch beim erneuten Versuch.
3. Das aktive Eingabefeld wird auch auf anderen Laptops erkannt; die Sprechblase erscheint dort und nicht neben der Maus.
4. Der Text ergibt Sinn, keine rein nach Klang aufgeschriebenen Wörter.
5. Wörter aus dem Wörterbuch (vor allem Namen) werden richtig geschrieben.
6. Nichts wird erfunden: kein „Ich“ am Anfang, keine angehängten Sätze am Ende.

## Erfolgskriterien
- Alle sechs Pflichtpunkte sind mit echten Aufnahmen auf mindestens zwei verschiedenen Macs nachgewiesen.
- Eine Aufnahme von 10 Minuten wird vollständig in Text umgewandelt.
- Das Team nutzt nur noch InnoWhisper; die alte App ist auf allen Macs entfernt.

## Rahmenbedingungen
- Plattform: echte Mac-App in Swift/SwiftUI, Menüleisten-App. Mindestversion **macOS 26** (Entscheidung vom 04.11.2026, wegen Liquid Glass), siehe `docs/decisions.md` ADR-001.
- Interne Kennung (Bundle-ID): `com.innosolv.InnoWhisper`. Die Erlaubnisse für Mikrofon und Bedienungshilfen müssen nach dem Umzug neu erteilt werden; die alte App aktualisiert sich nicht automatisch auf die neue. ADR-004.
- Kein Backend: alle Daten bleiben lokal auf dem jeweiligen Mac (Einstellungen, Verlauf, Wörterbuch); der Groq-Zugangsschlüssel liegt im Schlüsselbund. ADR-002.
- Externer Dienst: Groq (Spracherkennung Whisper, optionale KI-Nachbearbeitung). Die Aufnahmen gehen dorthin. ADR-003.
- Hosting: öffentliches GitHub-Projekt, Auslieferung über GitHub Releases, Updates über Sparkle, Beglaubigung (Notarisierung) über das aktive Apple-Entwicklerkonto. ADR-005.
- Data region: Daten lokal auf dem Mac; Aufnahmen werden zur Umwandlung an Groq (USA) übertragen.
- Data protection law: keins eingetragen. Bewusste Entscheidung von Timur am 04.11.2026 („internes Tool“). Offener Hinweis: Die Diktate enthalten personenbezogene Daten (Namen von Kunden, Bewerbern, Kollegen) und gehen an einen US-Anbieter; die DSGVO kann auch für interne Tools gelten. Keine Rechtsberatung. ADR-006.
- Qualitätsanspruch: Standard (echte tägliche Nutzer, mit Tests und sauberer Fehlerbehandlung).
- Design system: siehe `docs/design-system.md` (Apples Gestaltungsregeln, SF Symbols, Liquid Glass).
- Name: überall „InnoWhisper“, keine neuen Vorkommen des alten Namens.

## Betriebsbedingungen und Annahmen
Bestätigt:
- Ohne Internet ist keine Umwandlung möglich; die App muss das klar sagen.
- Groq ist der einzige Anbieter für Spracherkennung und KI-Nachbearbeitung.

Annahmen (noch nicht bestätigt, Verantwortlich: Timur):
- Das Team besteht aus wenigen Personen (vermutlich unter 10). Prüfen, wenn mehr Leute dazukommen.
- Die Laptops der Kollegen haben macOS 26 oder bekommen es. Vor dem Umzug klären.
- Die Ursachen der Pflichtpunkte 2, 4, 5 und 6 sind Vermutungen (z. B. Zeitlimit bei der Übertragung, Wörterbuch als Satz im Prompt). Sie werden beim Bau mit echten Aufnahmen geprüft, nicht vorausgesetzt.
- Groq setzt Grenzen für Dateigröße und Anfragen pro Minute. Die genauen Werte für das genutzte Konto sind offen und werden beim Bau der Umwandlung geprüft.

## Bewusst nicht dabei
- Gemeinsames Team-Wörterbuch über einen Server (Weitergabe als Datei ist möglich)
- Windows- und iPhone-Version
- Umwandlung ohne Internet direkt auf dem Mac
- Andere Anbieter als Groq
- Unterstützung für macOS-Versionen vor 26
