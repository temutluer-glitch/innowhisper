# PROJ-3 — Technischer Plan: Erlaubnisse & Einführung

> Technischer Plan (das WIE). Zwei Leser: Timur (gibt frei) und `/build` (baut danach). Kein Code, aber genau.
> Owner: `/architecture`. Der Vertrag (WAS) steht in `spec.md`, die Aufgabenliste in `tasks.md`.

Grundlage: ADR-001, ADR-002, ADR-007 (inkl. Debug-Ausnahme), ADR-008. Baut auf PROJ-1 (Modul `AppShell`: Problem-Sammlung, Einstellungsbereiche, Menüleisten-Fenster) und PROJ-2 (Modul `Diagnostics`: Protokoll) auf. Plattform `desktop`, kein Netzwerk, kein Konto. Weggelassen, weil es auf dieser Plattform nichts dazu gibt: Web-Schutzmaßnahmen (Routen, Formulare, Kopfzeilen), Zugriffsregeln einer Datenbank.

## Komponenten

```
Einführungsfenster „InnoWhisper einrichten“ (ohne Schließen-Knopf)      AC-1, AC-2, AC-12, AC-21, AC-22, EC-5
+-- Kopf: „Schritt X von Y“
+-- Schritt „Willkommen“ (Text aus AC-3, Knopf „Los geht's“)            AC-3
+-- Schritt „Mikrofon“                                                  AC-6 … AC-8, AC-10, AC-11, EC-1, EC-3
|   +-- Erklärsatz, Stand („Erlaubt“ mit grünem Häkchen / „Nicht erlaubt“)
|   +-- Knopf „Mikrofon erlauben“ bzw. nach Ablehnung „In den Systemeinstellungen erlauben“
|   +-- nach 10 s ohne Erkennung: Knopf „InnoWhisper neu starten“
+-- Schritt „Bedienungshilfen“ (gleich aufgebaut, Knopf öffnet Systemeinstellungen)   AC-6, AC-7, AC-9, AC-10, EC-3
+-- [später: Schritte aus PROJ-4, PROJ-5, PROJ-7]
+-- Schritt „Fertig“ (Text aus AC-4, Knopf „Fertig“)                    AC-4
+-- Fußleiste: „Zurück“ (ab Schritt 2) · „Weiter“ (gesperrt, solange Pflicht offen)   AC-5, AC-7
Einstellungsfenster → Bereich „Zugang & Erlaubnisse“ (neu angemeldet)    AC-16, AC-17
+-- Problem-Hinweis bei fehlender Erlaubnis (aus PROJ-1)
+-- Gruppe „Erlaubnisse“: Zeile Mikrofon, Zeile Bedienungshilfen, je Stand + „Jetzt erlauben“
Menüleisten-Fenster (aus PROJ-1)                                         AC-15, AC-16
+-- Problem-Hinweis „Mikrofon nicht erlaubt.“ mit „Jetzt erlauben“ (führt direkt in die Systemeinstellungen)
Erlaubnis-Wächter (unsichtbar): prüft regelmäßig, meldet Änderungen      AC-8, AC-10, AC-15, AC-16, AC-20
```

## Code-Aufbau

Zwei neue Module im Paket `Packages/InnoWhisperKit` (ADR-008). Die Einführung ist bewusst ein eigenes Modul ohne Wissen über Erlaubnisse, damit PROJ-4, PROJ-5 und PROJ-7 ihre Schritte einfügen können, ohne `Permissions` zu kennen.

| Modul / Pfad | Aufgabe und Schnittstelle | Darf benutzen |
| --- | --- | --- |
| `Sources/Onboarding/` | **Einführungs-Rahmen.** Nimmt Schritte entgegen (siehe „Schritt-Vertrag“), entscheidet, welche Schritte dieser Durchlauf zeigt, merkt sich den Fortschritt, zeigt das Fenster. Bietet: Schritt anmelden, „Einführung nötig?“, Einführung zeigen, „Einführung offen?“, Einführung nach vorne holen, Meldung „Einführung beendet“ | `AppShell`, `Diagnostics` |
| `Sources/Permissions/` | **Erlaubnisse.** Liest den Stand von Mikrofon und Bedienungshilfen, fragt das Mikrofon an, öffnet die richtige Stelle der Systemeinstellungen, prüft regelmäßig, meldet Probleme, liefert die zwei Erlaubnis-Schritte und den Bereich „Zugang & Erlaubnisse“ | `AppShell`, `Diagnostics`, `Onboarding`; Apple: AVFoundation, ApplicationServices |
| `Sources/AppShell/State/ProblemCenter.swift`, `Sources/AppShell/MenuBar/MenuBarPanel.swift` | **Kleine Ergänzung:** Ein Problem kann sagen „im Menüleisten-Fenster meinen eigenen Knopf behalten“ (Standard: nein). Das Menüleisten-Fenster ersetzt den Knopf dann nicht durch „Einstellungen öffnen“. Bestehende Probleme verhalten sich unverändert | wie bisher |
| `Sources/Diagnostics/LogFile.swift` | Zwei neue Protokoll-Bereiche: `permissions`, `onboarding` | wie bisher |
| `App/AppEnvironment.swift` | Erzeugt Wächter und Einführung, meldet Schritte und Bereich an. **Ein** Weg zum Öffnen der Einstellungen für alle Aufrufer: ist die Einführung offen, kommt sie nach vorne, sonst öffnet sich das Einstellungsfenster (AC-14) | alle Module |
| `App/AppDelegate.swift` | Beim Start: Einführung zeigen, falls nötig; die Prüfung auf die alte App startet erst, wenn die Einführung beendet ist (EC-4). Erneutes Öffnen und Zweitstart laufen über den Weg aus `AppEnvironment` | alle Module |
| `App/InnoWhisperApp.swift` | „Einstellungen …“ im Menüleisten-Fenster läuft über denselben Weg | alle Module |
| `App/Info.plist`, `App/InnoWhisper.entitlements`, `InnoWhisper.xcodeproj/project.pbxproj` | Mikrofon-Begründungstext, Mikrofon-Berechtigung der Hardened Runtime, feste Unterschrift für den Entwicklungsbau (siehe Technische Entscheidungen) | — |
| `Tests/OnboardingTests/`, `Tests/PermissionsTests/`, `Tests/AppShellTests/` | Tests mit Swift Testing; Erlaubnisse über eine Attrappe statt echter macOS-Abfrage | jeweiliges Modul |

### Schritt-Vertrag (für PROJ-3 und spätere Features)

Jeder Einführungs-Schritt, den ein Feature anmeldet, hat:
- **Kennung:** fester Text, eindeutig, ändert sich nie (PROJ-3: `microphone`, `accessibility`). Wird gespeichert.
- **Protokollname:** fester Text für das Protokoll (nur feste Texte, PROJ-2 AC-12).
- **Reihenfolge:** Zahl, kleinere zuerst. Vergeben: Mikrofon 30, Bedienungshilfen 40. Vorgemerkt: Zugangsschlüssel 10 (PROJ-4), Mikrofon wählen 50 und Tastenkürzel 60 (PROJ-5), Probe-Diktat 70 (PROJ-7).
- **Titel und Inhalt:** Überschrift und Ansicht des Schritts.
- **Erfüllt ja/nein:** beobachtbarer Stand; solange „nein“, ist „Weiter“ gesperrt (AC-7).
- **Gilt automatisch als erledigt, wenn erfüllt:** ja/nein. Für Erlaubnis-Schritte „ja“ (AC-19).

„Willkommen“ und „Fertig“ gehören fest zum Rahmen und werden nicht angemeldet.

### Welche Schritte ein Durchlauf zeigt

1. **Noch nie abgeschlossen** (erster Start oder abgebrochen): Willkommen, alle angemeldeten Schritte nach Reihenfolge, Fertig. Begonnen wird beim ersten Schritt, der noch nicht als erledigt gespeichert ist (AC-1, AC-13). Erfüllte Erlaubnis-Schritte erscheinen trotzdem, mit „Erlaubt“ (EC-1).
2. **Schon einmal abgeschlossen:** nur angemeldete Schritte, die noch nicht als erledigt gespeichert sind. Davon gelten die schon erfüllten, die „automatisch erledigt“ erlauben, sofort als erledigt (AC-19). Bleibt mindestens einer übrig: diese Schritte plus Fertig, ohne Willkommen (AC-18). Bleibt keiner: keine Einführung.
3. Ein Schritt gilt als erledigt, wenn der Nutzer ihn mit „Weiter“ (bzw. Willkommen mit „Los geht's“) verlässt; das wird sofort gespeichert. „Fertig“ speichert „schon einmal abgeschlossen“ und schließt das Fenster.
4. **Rückprüfung (EC-2):** Bei jedem „Weiter“ und bei „Fertig“ werden alle Pflicht-Schritte dieses Durchlaufs vor dem aktuellen neu geprüft. Ist einer nicht mehr erfüllt, wird er aus „erledigt“ entfernt und die Einführung springt dorthin.
5. Entzogene Erlaubnisse nach dem Abschluss öffnen die Einführung **nicht** (AC-15): der Schritt bleibt als erledigt gespeichert, der Wächter meldet ein Problem.

### Erlaubnis-Wächter

- **Stand je Erlaubnis:** einer von „erlaubt“, „noch nie gefragt“ (nur Mikrofon), „abgelehnt“ (umfasst auch „von der IT gesperrt“; im Protokoll getrennt vermerkt).
- **Prüfen:** jede 1 Sekunde, solange die Einführung offen ist; sonst alle 3 Sekunden. Zusätzlich sofort, wenn InnoWhisper wieder nach vorne kommt und wenn macOS meldet, dass sich die Bedienungshilfen-Liste geändert hat. Die Abfragen sind lokal und kosten praktisch nichts.
- **Änderung erkannt:** Protokoll-Eintrag „Permission changed: Erlaubnis, alter Stand, neuer Stand“ (AC-20). VoiceOver sagt „Erlaubt“ an, wenn sich ein sichtbarer Schritt ändert (AC-21).
- **Probleme melden (AC-15, AC-16):** nur, wenn die Einführung schon einmal abgeschlossen ist und nicht gerade offen. Fehlende Erlaubnis → Problem mit Kennung `permission.microphone` bzw. `permission.accessibility`, Bereich „Zugang & Erlaubnisse“, Satz „Mikrofon nicht erlaubt.“ bzw. „Bedienungshilfen nicht erlaubt.“, Knopf „Jetzt erlauben“, der die passende Stelle der Systemeinstellungen öffnet, und „eigenen Knopf im Menüleisten-Fenster behalten“. Erlaubnis wieder da → Problem zurückziehen. Das Menüleisten-Symbol folgt daraus von selbst (PROJ-1).
- **Mikrofon anfragen (AC-8, AC-11):** Stand „noch nie gefragt“ → Knopf „Mikrofon erlauben“ löst die macOS-Abfrage aus. Stand „abgelehnt“ → macOS fragt nie wieder; der Knopf heißt „In den Systemeinstellungen erlauben“ und öffnet „Datenschutz & Sicherheit → Mikrofon“, darüber der Erklärsatz aus AC-11.
- **Bedienungshilfen (AC-9):** Der Knopf trägt InnoWhisper bei macOS in die Liste ein und öffnet „Datenschutz & Sicherheit → Bedienungshilfen“. Der Schritt zeigt darunter den Satz „Schalte dort InnoWhisper ein.“.
- **Neustart-Angebot (EC-3):** Kommt InnoWhisper nach einem Klick auf einen Systemeinstellungs-Knopf wieder nach vorne und ist die Erlaubnis 10 Sekunden danach immer noch nicht erkannt, erscheint „InnoWhisper neu starten“. Neustart: macOS bekommt den Auftrag, InnoWhisper nach 1 Sekunde wieder zu öffnen, dann beendet sich die App. Der gespeicherte Fortschritt sorgt dafür, dass es am selben Schritt weitergeht.

### Einführungsfenster

- Eigenes Fenster, Titel „InnoWhisper einrichten“, feste Größe 520 × 440 Punkte, ohne Schließen-, Minimieren- und Vollbild-Knopf. Esc und ⌘W tun nichts (AC-12). Normale Fensterebene: Systemeinstellungen und andere Programme können davor liegen.
- Beim Öffnen: mittig auf dem Bildschirm mit dem Mauszeiger (EC-5), App nach vorne holen (AC-1).
- „InnoWhisper beenden“ und ⌘Q funktionieren wie immer (AC-13). Eine Rückfrage gibt es nicht, weil während der Einführung nie ein Diktat läuft.
- Knöpfe einer Fußleiste in derselben Größe; „Weiter“, „Los geht's“ und „Fertig“ sind der Hauptknopf, „Zurück“ der Nebenknopf (`docs/design-system.md`, AC-22). Alle Bedienelemente mit Beschriftung für VoiceOver und Tastatur-Fokus (AC-21).

## Footprint

- Code und Tests: `Packages/InnoWhisperKit/Sources/Onboarding/`, `Sources/Permissions/`, kleine Ergänzungen in `Sources/AppShell/State/ProblemCenter.swift`, `Sources/AppShell/MenuBar/MenuBarPanel.swift`, `Sources/Diagnostics/LogFile.swift`; `Package.swift` (zwei Module, zwei Testziele); `App/AppEnvironment.swift`, `App/AppDelegate.swift`, `App/InnoWhisperApp.swift`; Tests in `Tests/OnboardingTests/`, `Tests/PermissionsTests/`, `Tests/AppShellTests/`.
- Migrationen, Tabellen und Zugriffsregeln: keine (lokale Einstellungen, ADR-002).
- Umgebungsvariablen: keine.
- Pakete: keine neuen; nur Apple-Frameworks (AVFoundation für das Mikrofon, ApplicationServices für die Bedienungshilfen).
- Andockpunkte: Einstellungsbereich `access` (neu angemeldet), Problem-Sammlung, Menüleisten-Fenster, Start-Ablauf im App-Delegate, Weg zum Öffnen der Einstellungen. Externe Dienste: keine. Projektdateien: `Info.plist` (Mikrofon-Begründung), Berechtigungsdatei (Mikrofon), Unterschrift-Einstellungen für Debug.

## Qualität und Fehlerverhalten

| AC/EC | Bedingung und Grenze | Mechanismus | Geplanter Nachweis |
| --- | --- | --- | --- |
| AC-8, AC-10 | Erlaubnis erteilt → in der Einführung binnen 2 s „Erlaubt“ | Prüfung jede Sekunde, solange die Einführung offen ist; sofortige Prüfung beim Zurückkommen | Test mit Attrappe und simulierter Zeit; live: Zeitstempel im Protokoll gegen Klickzeit, dazu Sichtprüfung durch Timur |
| AC-15, AC-16 | Entzug bzw. Wiedererteilung nach der Einführung → Warnzeichen binnen 5 s an bzw. aus | Prüfung alle 3 s plus sofort beim Zurückkommen | Test mit Attrappe; live: Erlaubnis in den Systemeinstellungen aus- und einschalten, Protokoll-Zeitstempel |
| EC-3 | Erlaubnis erteilt, aber nach 10 s nicht erkannt → Neustart-Knopf | Zeitgeber ab Rückkehr nach Systemeinstellungs-Klick | Test mit simulierter Zeit |
| AC-13 | Beenden mitten in der Einführung → Neustart am selben Schritt | Fortschritt wird bei jedem Schritt sofort gespeichert | Test mit eigenem Einstellungs-Speicher; live einmal beenden und neu starten |

Fehlerfälle:
- **Systemeinstellungen lassen sich nicht an der richtigen Stelle öffnen** (Adresse von macOS nicht angenommen): Systemeinstellungen ohne Unterseite öffnen, Protokoll-Eintrag als Fehler. Der Schritt-Text sagt ohnehin, wohin man muss.
- **Mikrofon „von der IT gesperrt“** (macOS meldet „eingeschränkt“): wie „abgelehnt“ behandelt; Protokoll vermerkt den Unterschied, damit Timur es bei der Fehlersuche sieht.
- **Fortschritt nicht lesbar** (beschädigte Einstellung): gilt als „noch nie abgeschlossen“, die Einführung läuft von vorn. Unbekannte gespeicherte Kennungen werden ignoriert.
- Unerwartete Fehler werden protokolliert (nur feste Texte, Fehlerbereich und Nummer, PROJ-2), dem Nutzer nie als Code gezeigt.

## Datenmodell

```
Einführungs-Fortschritt (je Nutzer des Macs, in den lokalen Einstellungen der App):
- Erledigte Schritte: Liste von Schritt-Kennungen (fester Text aus dem Schritt-Vertrag
  oder „welcome“), ohne Doppelte; unbekannte Kennungen werden beim Lesen ignoriert
- Schon einmal abgeschlossen: ja/nein, Standard nein; wird mit „Fertig“ auf ja gesetzt

Gespeichert unter den Schlüsseln „onboarding.completedSteps“ und „onboarding.finishedOnce“.
Erlaubnis-Stände werden NICHT gespeichert, sondern jedes Mal frisch bei macOS abgefragt.
Zugriff: nur InnoWhisper auf diesem Mac. Aufbewahrt, bis die App gelöscht wird; keine
personenbezogenen Daten.
```

`docs/data-model.md` bekommt dafür die Zeile „Einführungs-Fortschritt“.

## Abhängigkeiten

Keine neuen Pakete.

## Einstellungen, die du machst

| Einstellung | Wo | Wann | Wert | Warum | → AC |
| --- | --- | --- | --- | --- | --- |
| Zugriff auf das Entwickler-Zertifikat erlauben | Fenster vom Schlüsselbund beim ersten Bau („codesign möchte auf … zugreifen“), angekündigt vorher im Chat | now | „Immer erlauben“ | Ohne diesen Klick kann der Entwicklungsbau nicht fest unterschrieben werden, und die Erlaubnisse gingen nach jedem Bau verloren | AC-8, AC-10 |
| Mikrofon und Bedienungshilfen für den Entwicklungsbau erteilen | während des Tests in der Einführung | now | erlauben | Nur so lassen sich die Schritte am echten Programm prüfen | AC-8 … AC-11 |

## Technische Entscheidungen

| Entscheidung | Begründung | Alternative | Abwägung | Datum |
| --- | --- | --- | --- | --- |
| Entwicklungsbau wird mit dem vorhandenen Zertifikat „Developer ID Application“ (Team N5QKANW6QY) unterschrieben statt ohne Zertifikat | macOS merkt sich Erlaubnisse an der Unterschrift. Ohne Zertifikat ändert sie sich bei jedem Bau, und Mikrofon und Bedienungshilfen müssten nach jedem Bau neu erteilt werden. Mit dem Zertifikat bleibt sie gleich. Ein „Apple Development“-Zertifikat liegt auf dem Mac nicht; das selbst erstellte Zertifikat der alten App trägt den alten Namen | „Apple Development“-Zertifikat neu über Xcode anlegen (Anmeldung in Xcode nötig) | Beim ersten Bau fragt der Schlüsselbund einmal nach Zugriff. Nur Debug wird umgestellt; die Release-Unterschrift regelt PROJ-14 (mit demselben Zertifikat, dann gelten Erlaubnisse für beide). **Tragend, Umkehrkosten gering** (eine Einstellung im Projekt) | 2026-11-05 |
| Hardened-Runtime-Berechtigung „Audio-Eingang“ und Begründungstext fürs Mikrofon | Ohne beides verweigert macOS das Mikrofon still bzw. stürzt die Abfrage ab | — | keine | 2026-11-05 |
| Erlaubnisse regelmäßig abfragen statt auf Meldungen von macOS zu warten | macOS meldet Mikrofon-Änderungen gar nicht und Bedienungshilfen-Änderungen nicht zuverlässig; die Abfrage ist lokal und billig | Nur auf Meldungen hören | Ein paar Abfragen pro Sekunde während der Einführung; vernachlässigbar | 2026-11-05 |
| Einführung als eigenes Modul mit Schritt-Vertrag; Erlaubnisse als zweites Modul | PROJ-4, PROJ-5, PROJ-7 fügen Schritte ein, ohne den Rahmen anzufassen | Alles in einem Modul | Ein Modul mehr im Paket | 2026-11-05 |
| Umleitung „Einstellungen → Einführung“ an einer Stelle im App-Zusammenbau | Alle drei Wege (Menüleisten-Fenster, erneutes Öffnen, Zweitstart) laufen schon durch `App/`; so bleibt `AppShell` unverändert | Umleitung im Einstellungsfenster-Baustein | Wer künftig die Einstellungen öffnet, muss diesen einen Weg benutzen | 2026-11-05 |
| Problem kann im Menüleisten-Fenster seinen eigenen Knopf behalten | AC-16 verlangt „Jetzt erlauben“ direkt in die Systemeinstellungen; bisher ersetzt das Menüleisten-Fenster solche Knöpfe immer durch „Einstellungen öffnen“ | Problem ohne Bereich melden | Kleine Ergänzung in `AppShell`, Standard unverändert, PROJ-1 AC-11 gilt weiter für alle anderen Probleme | 2026-11-05 |
| Probleme zu Erlaubnissen erst nach abgeschlossener Einführung melden | Während der Einführung zeigt sie selbst den Stand; doppelte Hinweise würden verwirren | Immer melden | Beim allerersten Start zeigt das Symbol kein Warnzeichen, solange die Einführung läuft | 2026-11-05 |
| Prüfung auf die alte App erst nach der Einführung | EC-4: nicht zwei Fenster gleichzeitig | Parallel | Läuft die alte App, erfährt man es erst nach der Einrichtung | 2026-11-05 |

**Sicherheit (ADR-007):** Die App bekommt genau zwei Erlaubnisse, keine weiteren. Debug trägt weiter `get-task-allow` (Ausnahme in ADR-007): Wer Mikrofon und Bedienungshilfen für den Debug-Bau erlaubt, nimmt in Kauf, dass ein anderer Prozess desselben Nutzers sie über die Fehlersuche mitbenutzen könnte. Das gilt nur für Timurs Entwickler-Mac; ausgeliefert wird nur Release. Der private Schlüssel des Zertifikats bleibt im Schlüsselbund; ins Projekt kommt nur der Zertifikatsname und die Team-Kennung (beides nicht geheim).

## Offene Fragen

- [ ] Vermutung, beim Bau messen: Erkennt macOS 26 eine in den Systemeinstellungen erteilte Mikrofon- bzw. Bedienungshilfen-Erlaubnis ohne Neustart? Falls nicht, greift EC-3; das Ergebnis kommt in die Bau-Notizen.
- [ ] Vermutung, beim Bau messen: Welche Kombination aus „bei macOS eintragen“ und „Systemeinstellungen öffnen“ ergibt für die Bedienungshilfen genau ein verständliches Fenster und nicht zwei?
- [ ] Wie PROJ-4 seine Gruppe „Zugangsschlüssel“ in den Bereich „Zugang & Erlaubnisse“ bringt, entscheidet PROJ-4 (der Bereich gehört dann zwei Features).
