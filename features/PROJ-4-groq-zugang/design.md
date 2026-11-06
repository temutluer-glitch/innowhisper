# PROJ-4 — Technischer Entwurf

> Der technische Entwurf (das WIE) für den Groq-Zugang. Zwei Leser: Timur (gibt frei) und `/build` (baut danach). Kein Code, aber so genau, dass niemand raten muss.
> Owner: `/architecture`. Der Vertrag (WAS) steht in `spec.md`, die Aufgabenliste in `tasks.md`.

## Komponenten

```
Einführung (Rahmen aus PROJ-3)
+-- Schritt „Zugangsschlüssel“ (Reihenfolge 10, Kennung „groq-key“)
    +-- Erklärsatz (AC-1)
    +-- [nur wenn die alte App einen Schlüssel hat] Übernahme-Hinweis + Knopf „Schlüssel übernehmen“ (AC-7 bis AC-9)
    +-- Schlüsselfeld (verdeckt) + Knopf „Prüfen“ mit Fortschrittsanzeige (AC-4, EC-1 bis EC-3)
    +-- Ergebniszeile: grünes Häkchen / Ablehnung / „nicht erreichbar“ (AC-4 bis AC-6, AC-10)
    +-- Hilfe in drei Schritten + Link zur Groq-Seite (AC-3)

Einstellungsfenster → Bereich „Zugang & Erlaubnisse“ (Rahmen aus PROJ-1)
+-- Problem-Hinweis oben (kommt aus dem Rahmen, AC-14, AC-15)
+-- Gruppe „Groq-Schlüssel“ (neu, oben)
|   +-- Stand + „•••• 7Fq2“ (AC-11)
|   +-- Knöpfe „Prüfen“, „Ändern“, „Entfernen“ in gleicher Größe (AC-11 bis AC-13)
|   +-- beim Ändern: dasselbe Schlüsselfeld wie in der Einführung
|   +-- Rückfrage vor „Entfernen“ (AC-13)
+-- Gruppe „Erlaubnisse“ (aus PROJ-3, unverändert im Inhalt)

Menüleisten-Fenster (Rahmen aus PROJ-1)
+-- Problem „Groq-Schlüssel ungültig.“ / „Kein Groq-Schlüssel.“ mit eigenem Knopf (AC-14, AC-15)
```

Schlüsselfeld und Ergebniszeile sind ein gemeinsamer Baustein, den Einführung und Einstellungen beide benutzen, damit Verhalten und Texte überall gleich sind.

## Code-Aufbau

Ein neues Modul `GroqAccess` im Paket `Packages/InnoWhisperKit` (ADR-008), gleich gebaut wie `Permissions` aus PROJ-3.

| Modul / Pfad | Aufgabe und Schnittstelle | Darf benutzen |
| --- | --- | --- |
| `Sources/GroqAccess/GroqAccess.swift` | Modul-Kopf: feste Werte (Groq-Adresse für die Prüfung, Zeitgrenze 15 s, Schlüsselbund-Namen, Kennung und Reihenfolge des Schritts) | — |
| `Sources/GroqAccess/KeyStore.swift` | Schlüssel im Schlüsselbund lesen, speichern, löschen; Schnittstelle mit echtem Anschluss und Attrappe für Tests | Security (System) |
| `Sources/GroqAccess/LegacyKeyReader.swift` | Prüft, ob die alte App einen Schlüssel hat (ohne ihn zu lesen), und liest ihn nur auf Knopfdruck | Security (System) |
| `Sources/GroqAccess/KeyValidator.swift` | Fragt Groq, ob ein Schlüssel gilt; liefert genau eines von drei Ergebnissen (gilt, abgelehnt, nicht erreichbar) samt Statuscode und Dauer; Netzwerkzugang austauschbar für Tests | Foundation |
| `Sources/GroqAccess/GroqKeyModel.swift` | Der Zustand des Zugangs für die ganze App: Stand, letzte 4 Zeichen, „prüft gerade“; Handlungen Prüfen, Übernehmen, Ändern, Entfernen, Prüfen beim Start; meldet und zieht Probleme zurück; protokolliert | AppShell (`ProblemCenter`, `SettingsSection`), Diagnostics, Network (System) |
| `Sources/GroqAccess/KeyEntryView.swift` | Gemeinsamer Baustein: verdecktes Feld, „Prüfen“, Ergebniszeile | SwiftUI |
| `Sources/GroqAccess/KeyStep.swift` | Baut den Einführungs-Schritt nach dem Schritt-Vertrag aus PROJ-3 (Kennung „groq-key“, Reihenfolge 10, erledigt sich automatisch, wenn ein Schlüssel da ist) | Onboarding |
| `Sources/GroqAccess/KeySettingsSection.swift` | Gruppe „Groq-Schlüssel“ für den Bereich „Zugang & Erlaubnisse“ | SwiftUI |
| `Tests/GroqAccessTests/…` | Tests für Prüfung, Modell, Schritt und Speicher (mit Attrappen, ohne echtes Netz und ohne echten Schlüsselbund) | GroqAccess |
| `App/AppEnvironment.swift` | Erzeugt `GroqKeyModel`, setzt den Schritt vor die Erlaubnis-Schritte, baut den Bereich „Zugang & Erlaubnisse“ aus beiden Gruppen zusammen, startet die Prüfung beim Start | alle Module |
| `Sources/Permissions/AccessPane.swift` | Wird so umgebaut, dass er nur noch die Gruppe „Erlaubnisse“ liefert; das Formular drumherum baut die App | — |
| `Sources/Diagnostics/LogFile.swift` | Neuer Protokoll-Bereich `groq` | — |

Erlaubte Richtung: `GroqAccess` kennt `AppShell`, `Diagnostics` und `Onboarding`, aber nicht `Permissions`. Die beiden Gruppen im Bereich „Zugang & Erlaubnisse“ setzt nur die App zusammen; so muss weder das eine Modul das andere kennen noch der Rahmen aus PROJ-1 geändert werden.

## Footprint

- **Code und Tests:** neues Modul `Packages/InnoWhisperKit/Sources/GroqAccess/` (8 Dateien), `Tests/GroqAccessTests/`; Eintrag in `Package.swift`; Änderungen in `App/AppEnvironment.swift`, `Sources/Permissions/AccessPane.swift`, `Sources/Diagnostics/LogFile.swift`
- **Tabellen und Zugriffsregeln:** keine Datenbank. Schlüsselbund-Eintrag und ein Wert in den Einstellungen, siehe Datenmodell
- **Umgebungsvariablen:** keine
- **Pakete:** keine neuen; nur Systembausteine (Security, Network)
- **Anschlusspunkte:** Einführungs-Schritt „groq-key“ (PROJ-3), Bereich „Zugang & Erlaubnisse“ (PROJ-1), `ProblemCenter` (PROJ-1), Protokoll (PROJ-2), externe Adresse `https://api.groq.com/openai/v1/models` (nur zum Prüfen)

## Qualität und Fehlerverhalten

| AC/EC | Bedingung und Grenze | Wie es gehalten wird | Geplanter Nachweis |
| --- | --- | --- | --- |
| AC-4, EC-5 | Ergebnis innerhalb von 15 s, auch bei hängender Verbindung | Feste Zeitgrenze 15 s für die Anfrage; danach Ergebnis „nicht erreichbar“ | Test mit Attrappe, die nie antwortet; Live-Prüfung mit echtem Schlüssel und ohne Netz |
| AC-10 | „Noch nicht geprüft“ wird von selbst nachgeprüft, spätestens beim nächsten Start | Prüfung beim Start; dazu Beobachtung der Netzverbindung: wird sie wieder verfügbar und der Stand ist „noch nicht geprüft“, wird einmal geprüft | Test mit Attrappen; Live: WLAN aus, speichern, WLAN an, Protokoll |
| AC-14 | Ungültiger Schlüssel ist nach dem Start sichtbar | Prüfung beim Start nach abgeschlossener Einführung; Ablehnung meldet das Problem | Test; Live mit absichtlich falschem Schlüssel |
| AC-16 | Problem verschwindet sofort nach gültigem Schlüssel | Modell zieht das Problem im selben Schritt zurück, in dem es „gilt“ speichert | Test |
| AC-17, AC-18 | Schlüssel nie im Protokoll, in Einstellungen, Hinweisen | Schlüssel nur im Schlüsselbund; das Protokoll nimmt technisch nur feste Texte und Zahlen an (PROJ-2), der Schlüssel ist ein freier Text und kann dort gar nicht hinein | Suche im Protokoll und in der Einstellungsdatei nach dem Testschlüssel; `strings` über die App |
| EC-3 | Keine gehäuften Prüfungen | Modell nimmt keine zweite Prüfung an, solange eine läuft; Knopf gesperrt | Test: zwei Klicks, eine Anfrage |

**Fehler an den Schnittstellen:**
- **Groq antwortet:** 200 und 429 → gilt (EC-4); 401 und 403 → abgelehnt; jeder andere Code, keine Antwort, Zeitgrenze, kein Netz → nicht erreichbar (EC-5). Protokolliert werden Ergebnis, Statuscode und Dauer, nie der Schlüssel (AC-18).
- **Schlüsselbund verweigert das Speichern:** Meldung aus EC-8, Protokoll mit Fehlercode; der Stand bleibt wie vorher. Kein automatischer Neuversuch, der Nutzer klickt erneut.
- **Übernahme aus der alten App scheitert** (abgelehnt, abgebrochen, kein Eintrag): Meldung aus AC-9, das Feld bleibt nutzbar, Protokoll mit Fehlercode.
- **Unerwarteter Fehler:** wird wie „nicht erreichbar“ behandelt und mit Fehlerart protokolliert; nie Absturz, nie ein roher Code für den Nutzer.

## Datenmodell

```
Groq-Schlüssel (höchstens einer pro Nutzer)
- Wert: Text, nach dem Entfernen von Leerzeichen und Zeilenumbrüchen am Rand
  (EC-1), 1 bis 200 Zeichen, nur sichtbare Zeichen ohne Leerzeichen; sonst
  wird gar nicht erst geprüft, sondern sofort „Groq lehnt diesen Schlüssel ab …“
  gezeigt
- Gespeichert im Schlüsselbund des Nutzers:
  Dienst „com.innosolv.InnoWhisper“, Konto „groq-api-key“,
  lesbar nur auf diesem Mac und erst nach der ersten Entsperrung nach dem Start
- Wird nie in Einstellungen, Protokoll oder Zwischenablage geschrieben

Prüf-Stand des Schlüssels
- Einer von: „gilt“, „noch nicht geprüft“, „ungültig“
- „Kein Schlüssel“ ist kein gespeicherter Wert, sondern ergibt sich, wenn im
  Schlüsselbund nichts liegt
- Gespeichert in den Einstellungen unter „groqKey.status“; fehlt der Wert oder
  ist er unbekannt, gilt „noch nicht geprüft“ (beim nächsten Start wird geprüft)

Anzeige
- Letzte 4 Zeichen werden beim Start aus dem Schlüsselbund gelesen und nur im
  Speicher gehalten

Zugriff: nur der angemeldete Nutzer dieses Macs; nichts wird abgeglichen.
Aufbewahrung: bis der Nutzer „Entfernen“ klickt oder einen neuen Schlüssel speichert.
```

**Schlüssel der alten App (nur lesen):** Schlüsselbund, Dienst „com.innosolv.WhisperDictation“, Konto „groq_api_key“ (Quelle: `KeychainStore.swift` im alten Repo). Ob er existiert, wird ohne Lesen des Werts festgestellt, damit dabei keine macOS-Frage erscheint; gelesen wird erst nach Klick auf „Schlüssel übernehmen“. Der Eintrag der alten App wird nie verändert (AC-8).

## Abläufe

**Prüfen (Einführung, „Ändern“ in den Einstellungen):**
1. Eingabe säubern (EC-1) und auf Form prüfen (siehe Datenmodell); leer → Knopf gesperrt (EC-2).
2. Läuft schon eine Prüfung → nichts tun (EC-3).
3. Groq fragen, höchstens 15 s.
4. Gilt → speichern, Stand „gilt“, Problem zurückziehen (AC-5, AC-16). Nicht erreichbar → speichern, Stand „noch nicht geprüft“ (AC-10). Abgelehnt → nichts speichern, alter Schlüssel bleibt (AC-6, AC-12).

**Übernehmen (Einführung):** Knopf → Schlüssel der alten App lesen (macOS fragt) → weiter wie „Prüfen“ ab Schritt 3. Scheitert das Lesen → Meldung AC-9.

**Beim Start (nach abgeschlossener Einführung):** Kein Schlüssel → Problem „Kein Groq-Schlüssel.“ (AC-15). Sonst einmal prüfen: abgelehnt → Stand „ungültig“, Problem „Groq-Schlüssel ungültig.“ (AC-14, EC-6); nicht erreichbar → Stand bleibt, kein Problem, später erneut (AC-10).

**Entfernen:** Rückfrage → Schlüsselbund-Eintrag löschen → Problem „Kein Groq-Schlüssel.“ (AC-13, AC-15).

**Probleme:** Kennung „groq.key“, Bereich „Zugang & Erlaubnisse“, behält im Menüleisten-Fenster den eigenen Knopf („Schlüssel ändern“ bzw. „Schlüssel eintragen“), der die Einstellungen an diesem Bereich öffnet und dort gleich „Ändern“ aufklappt. Probleme werden nur gemeldet, wenn die Einführung abgeschlossen und nicht offen ist, wie bei PROJ-3.

**Einführungs-Schritt:** gilt als erfüllt bei Stand „gilt“ oder „noch nicht geprüft“; erledigt sich automatisch, wenn schon ein Schlüssel gespeichert ist (EC-7, PROJ-3 AC-19).

## Abhängigkeiten

- Keine neuen Pakete. Systembausteine: Security (Schlüsselbund), Network (Netzverbindung beobachten), URLSession (Anfrage an Groq).

## Einstellungen, die der Nutzer macht

Keine in einem Dashboard. Jeder Mitarbeiter legt sich selbst ein Groq-Konto und einen Schlüssel an (Produktentscheidung vom 06.11.); das ist keine Einstellung der App.

## Technische Entscheidungen

| Entscheidung | Begründung | Alternative | Nachteil | Datum |
| --- | --- | --- | --- | --- |
| Eigenes Modul `GroqAccess` | Wie `Permissions`; PROJ-6 und PROJ-11 brauchen später nur das Modell, nicht die Ansichten | Alles in `AppShell` | Ein Modul mehr im Paket | 2026-11-06 |
| Bereich „Zugang & Erlaubnisse“ wird in der App aus zwei Gruppen zusammengesetzt | Kein Umbau des Rahmens aus PROJ-1 nötig, die Module kennen sich nicht | Neue „Gruppen“-Schnittstelle für jeden Bereich im Rahmen (wäre ein `/refine PROJ-1`) | `AccessPane` aus PROJ-3 liefert künftig nur noch seine Gruppe; kleine Änderung an einem freigegebenen Feature | 2026-11-06 |
| Prüfung über `GET /openai/v1/models` | Leichteste Anfrage, kostet nichts, bewährt in der alten App (`GroqKeyValidator.swift`) | Probe-Umwandlung mit kurzer Stille | Bestätigt nur, dass der Schlüssel gilt, nicht dass das Konto Guthaben hat | 2026-11-06 |
| 429 gilt als „gilt“ | Groq hat den Schlüssel erkannt, nur zu viele Anfragen | Als „nicht erreichbar“ werten | Ein gesperrtes Konto mit 429 würde als gültig gelten; die Umwandlung meldet das dann selbst (PROJ-6) | 2026-11-06 |
| Schlüsselbund nur auf diesem Mac, nach erster Entsperrung lesbar | Schlüssel wandert nicht über iCloud auf andere Geräte; Prüfung beim Start klappt auch vor dem ersten Entsperren nicht, das ist in Ordnung | Synchronisierender Schlüsselbund | Auf einem neuen Mac muss der Schlüssel neu eingefügt werden | 2026-11-06 |
| Existenz des alten Schlüssels prüfen, ohne ihn zu lesen | Sonst käme die macOS-Frage schon beim Öffnen des Schritts statt nach dem angekündigten Klick (globale Regel 52) | Sofort lesen | Wenn die Existenzprüfung selbst eine Frage auslöst, muss der Hinweis davor kommen; wird beim Bau gemessen (siehe offene Fragen) | 2026-11-06 |
| Netzverbindung beobachten statt regelmäßig prüfen | Prüft nur dann, wenn ein „noch nicht geprüft“-Schlüssel wieder erreichbar wird; keine Daueranfragen | Prüfung alle paar Minuten | Wechselt das Netz, ohne dass macOS es meldet, kommt die Prüfung erst beim nächsten Start | 2026-11-06 |
| Kein Anmelde-Schutz gegen Raten | InnoWhisper hat keine eigenen Konten; geprüft wird nur gegen Groq, das selbst begrenzt. SEC-04 entfällt; EC-3 verhindert gehäufte Anfragen aus der App | Eigene Sperre nach N Fehlversuchen | — | 2026-11-06 |
| Bezug: ADR-002 (kein Backend), ADR-003 (Groq, bestätigt 06.11.), ADR-007 (keine App-Sandbox: Lesen des alten Schlüsselbund-Eintrags ist möglich) | — | — | — | 2026-11-06 |

## Offene Fragen

- [x] Wie genau sieht die macOS-Frage beim Lesen des alten Schlüssels aus? Gemessen am 06.11.: das Schlüsselbund-Fenster von macOS mit Passwortfeld (securityd „displaying keychain prompt“, SecurityAgent), genau einmal. Der Hinweistext aus AC-7 („Gleich fragt macOS nach deinem Mac-Passwort …“) passt und bleibt.
- [x] Löst schon die Existenzprüfung des alten Eintrags eine macOS-Frage aus? Nein. Der Schritt erschien 16:28:55 ohne Fenster; das Fenster kam erst 16:28:58,8 mit dem Klick auf „Schlüssel übernehmen“.

## Bau-Notizen

Live-Test am 06.11.2026 mit Timur, Testversion aus DerivedData, ausgewertet über `~/Library/Logs/InnoWhisper/InnoWhisper.log` und `/usr/bin/log show` (securityd, SecurityAgent).

- Übernahme aus der alten App (AC-7, AC-8): Schritt zeigte den Hinweis, ein einziges Schlüsselbund-Fenster von macOS mit Passwort kam erst nach dem Klick (16:28:58,8), Übernahme 16:29:03,9, Groq-Prüfung 200 in 280 ms, gespeichert als „gilt“. Der Eintrag der alten App blieb unverändert.
- Falscher Schlüssel (AC-6): Groq antwortete 401 in 194 ms, Ablehnungstext erschien, nichts gespeichert.
- Richtiger Schlüssel per Einfügen (AC-5): 200 in 237 ms, Einführungsschritt danach erledigt, Einführung abgeschlossen.
- Einstellungen (AC-11 bis AC-13): Stand „Schlüssel funktioniert“ mit den letzten 4 Zeichen, „Prüfen“ (200 in 224 bis 411 ms), „Ändern“ mit neuem Schlüssel, „Entfernen“ nach Rückfrage; Timur bestätigte Warndreieck und Problemtext (AC-15).
- Prüfung beim Start (AC-14): nach Neustart „Key at start: valid“, danach Prüfung 200 in 243 ms.
- Schlüssel nirgends im Klartext: 0 Treffer für `gsk_` in beiden Protokolldateien und in `com.innosolv.InnoWhisper.plist` (nur gezählt, keine Werte ausgegeben).
- Korrektur aus dem Test: In den Einstellungen stand das Eingabefeld rechtsbündig neben einer zweiten Beschriftung „Groq-Schlüssel“. Jetzt ohne eigene Beschriftung (die Gruppe heißt schon so), volle Breite, Text links. Von Timur bestätigt.
- Nicht live geprüft, bleibt für `/qa`: Speichern ohne Internet und Nachprüfen beim Wiederverbinden (AC-10, EC-5), Warnung bei ungültigem gespeichertem Schlüssel nach Neustart (AC-14 mit 401), verweigertes Speichern im Schlüsselbund (EC-8). Diese Fälle sind nur durch Tests mit Platzhaltern belegt.
- Nebenbefund außerhalb von PROJ-4: `LegacyAppGuard` (PROJ-1) schreibt „Legacy app running …“ bei jedem Programmstart oder -ende anderer Apps erneut, solange die Frage zur alten Version offen ist (18 gleiche Zeilen um 16:44:26). Nur Protokoll-Rauschen, kein Fehlverhalten; nicht geändert.
