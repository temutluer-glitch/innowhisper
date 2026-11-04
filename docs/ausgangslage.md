# Ausgangslage: Neuaufbau InnoWhisper

Stand: 04.11.2026. Diese Datei ist das Briefing für `/init`. Sie hält fest, warum neu gebaut wird und was der Neuaufbau auf jeden Fall lösen muss.

## Was InnoWhisper ist

Ein Mac-Programm in der Menüleiste: Per Tastenkürzel diktieren, die Sprache wird in Text umgewandelt und in das gerade aktive Eingabefeld eines beliebigen Programms eingefügt. Genutzt von Timur und dem InnoSolv-Team.

Der alte Stand (Version 1.3.0) liegt in `../WhisperDictation/`, GitHub-Repo `temutluer-glitch/whisperdictation` (öffentlich). Er dient nur als Nachschlagewerk.

## Warum neu gebaut wird

Das Programm ist zu fehleranfällig. Timurs Worte: „Es ist relativ buggy, es passieren viele Fehler.“ Es soll mit dem AI Engineering Kit sauber und nachvollziehbar neu aufgebaut werden.

## Pflichtpunkte aus dem Alltag (von Timur am 04.11.2026 genannt)

1. **Aufnahme startet nicht.** Taste gedrückt, aber die Spracherkennung beginnt nicht.
2. **Lange Aufnahmen gehen verloren.** Nach etwa zwei Minuten Sprechen kommt eine Fehlermeldung. Die Aufnahme lässt sich danach nicht erneut umwandeln, jeder weitere Versuch endet ebenfalls mit einer Fehlermeldung.
3. **Eingabefeld wird auf anderen Geräten nicht erkannt.** Auf einem anderen Laptop findet das Programm das aktive Eingabefeld nicht, die Sprechblase erscheint irgendwo neben der Maus.

## Vorgaben

- **Name:** überall InnoWhisper (Ordner, neues GitHub-Repo, Programmname, Dateinamen). Im alten Repo steht an einigen Stellen noch „WhisperDictation“, das soll im Neuaufbau nicht mehr vorkommen.
- **Neues GitHub-Repo** wird angelegt, sobald der Bauplan steht.

## Offen, im Startgespräch zu klären

- **Interne Kennung (Bundle-ID):** Die alte App heißt intern `com.innosolv.WhisperDictation`. Eine neue Kennung passt zur Namensvorgabe, hat aber Folgen: Mikrofon und Bedienungshilfen müssen einmal neu erlaubt werden, und die alte App bekommt die neue nicht automatisch als Update (Sparkle). Entscheidung und Übergangsweg für das Team festlegen.
- Weitere Wünsche und Ärgernisse über die drei Pflichtpunkte hinaus.

## Gelernte Lektionen aus dem alten Stand (zum Nachlesen, nicht blind übernehmen)

- Menüleiste: SwiftUI `MenuBarExtra` behalten. Ein eigenes `NSStatusItem` mit `NSPopover` kann das native Einstellungsfenster nicht öffnen.
- Signieren: Bei eingebetteten Frameworks wie Sparkle braucht es `--deep` beim Signieren und das Entitlement `com.apple.security.cs.disable-library-validation`, sonst startet die App nicht (bei selbst signierten Builds).
- Gleichbleibende Signatur zwischen Versionen ist nötig, damit macOS die Erlaubnisse für Mikrofon und Bedienungshilfen behält.
- DMG-Bau: `create-dmg` hängt in nicht interaktiven Sitzungen, Ausweg war `hdiutil`.
- Notarisierung scheitert mit 403, wenn die Apple-Developer-Vereinbarung abgelaufen ist.
