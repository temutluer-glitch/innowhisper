# PROJ-4 Aufgaben

> Erstellt von `/tasks` aus `spec.md` + `design.md`. Geordneter, nachverfolgbarer Bauplan.
> `[P]` = parallel möglich: die Dateien der Aufgabe überschneiden sich mit keiner anderen `[P]`-Aufgabe derselben Stufe.
> Stufen laufen **nacheinander** (jede ist eine Schranke). Jede Aufgabe nennt die AC/EC-IDs aus `spec.md`, die sie erfüllt (AC → Aufgabe → Test).
> Owner: `/tasks` legt die Datei an; `/build` hakt ab.
> Abkürzungen: `Kit/` = `Packages/InnoWhisperKit/`, `GA/` = `Kit/Sources/GroqAccess/`, `GAT/` = `Kit/Tests/GroqAccessTests/`.

## Stufe 1 — Grundgerüst

- [x] T1  Modul `GroqAccess` (hängt von `AppShell`, `Diagnostics`, `Onboarding` ab) samt Testziel anlegen; Modul-Kopf mit festen Werten (Prüfadresse, Zeitgrenze 15 s, Schlüsselbund-Namen neu und alt, Schritt-Kennung „groq-key“, Reihenfolge 10, Einstellungs-Schlüssel „groqKey.status“); Protokoll-Bereich `groq`; erster Test  · files: Kit/Package.swift, GA/GroqAccess.swift, GAT/SmokeTests.swift, Kit/Sources/Diagnostics/LogFile.swift  · → AC-17, AC-18

## Stufe 2 — Anschlüsse nach außen

- [ ] T2 [P]  Prüfung bei Groq: Anfrage an die Modell-Liste mit Zeitgrenze 15 s; Ergebnis gilt (200, 429), abgelehnt (401, 403), nicht erreichbar (alles andere, Zeitüberschreitung, kein Netz) samt Statuscode und Dauer; Netzwerkzugang austauschbar; Tests für jeden Fall  · files: GA/KeyValidator.swift, GAT/KeyValidatorTests.swift  · → AC-4, EC-4, EC-5
- [ ] T3 [P]  Schlüsselbund: eigener Eintrag lesen, speichern (nur dieser Mac, nach erster Entsperrung), löschen, mit Fehlercode bei Verweigerung; alter Eintrag: Existenz feststellen ohne Lesen, Lesen nur auf Aufruf, nie verändern; Schnittstellen mit Attrappen; Tests  · files: GA/KeyStore.swift, GA/LegacyKeyReader.swift, GAT/KeyStoreTests.swift  · → AC-5, AC-8, AC-13, AC-17, EC-8, EC-9

## Stufe 3 — Zustand

- [ ] T4  Modell des Zugangs: Stand (gilt, noch nicht geprüft, ungültig, kein Schlüssel) mit Speicherung in „groqKey.status“; letzte 4 Zeichen; Eingabe säubern und auf Form prüfen; nur eine Prüfung zur Zeit; Prüfen, Übernehmen, Ändern (alter bleibt bei Ablehnung), Entfernen; Prüfung beim Start; Nachprüfen, wenn das Netz wiederkommt; Probleme „groq.key“ nur nach abgeschlossener, nicht offener Einführung melden und sofort zurückziehen; Protokoll ohne Schlüssel; Tests mit Attrappen  · files: GA/GroqKeyModel.swift, GAT/GroqKeyModelTests.swift  · → AC-2, AC-5, AC-6, AC-8, AC-9, AC-10, AC-12, AC-13, AC-14, AC-15, AC-16, AC-18, EC-1, EC-2, EC-3, EC-6, EC-8

## Stufe 4 — Oberflächen

- [ ] T5 [P]  Gemeinsamer Baustein (verdecktes Feld, „Prüfen“ mit Fortschritt, Ergebniszeile mit den Texten aus AC-4) und Einführungs-Schritt „Zugangsschlüssel“ (Erklärsatz, Übernahme-Hinweis und Knopf nur bei altem Schlüssel, Hilfe in drei Schritten mit Link, Weiter-Sperre, erledigt sich automatisch); VoiceOver-Beschriftungen; Test des Schritt-Vertrags  · files: GA/KeyEntryView.swift, GA/KeyStep.swift, GAT/KeyStepTests.swift  · → AC-1, AC-2, AC-3, AC-4, AC-6, AC-7, AC-9, EC-2, EC-3, EC-7, EC-9
- [ ] T6 [P]  Gruppe „Groq-Schlüssel“ in den Einstellungen (Stand, „•••• “ plus letzte 4 Zeichen, „Prüfen“, „Ändern“, „Entfernen“ in gleicher Größe, Rückfrage vor dem Entfernen, Ändern klappt den Baustein auf); `AccessPane` liefert nur noch die Gruppe „Erlaubnisse“  · files: GA/KeySettingsSection.swift, Kit/Sources/Permissions/AccessPane.swift  · → AC-11, AC-12, AC-13

## Stufe 5 — Zusammensetzen und echt prüfen

- [ ] T7  App verdrahten: Modell erzeugen, Schritt vor die Erlaubnis-Schritte setzen, Bereich „Zugang & Erlaubnisse“ aus beiden Gruppen zusammensetzen (Groq-Schlüssel oben), Problem-Knopf öffnet die Einstellungen an diesem Bereich mit aufgeklapptem „Ändern“, Prüfung beim Start und Netz-Beobachtung starten, Einführungs-Zustand an das Modell melden  · files: App/AppEnvironment.swift  · → AC-1, AC-14, AC-15, EC-7
- [ ] T8  Am laufenden Programm prüfen, erst selbst messen, dann Timur: Einführung mit Übernahme aus der alten App (wie sieht die macOS-Frage aus, kommt schon beim Nachschauen eine?), Einfügen eines falschen und eines richtigen Schlüssels, ohne Internet speichern und Nachprüfen beim Wiederverbinden, Ändern und Entfernen, Warnung bei ungültigem Schlüssel nach Neustart, Suche nach dem Schlüssel in Protokoll und Einstellungsdatei; Ergebnisse und beide offenen Fragen in den Bau-Notizen festhalten  · files: features/PROJ-4-groq-zugang/design.md  · → AC-4, AC-7, AC-8, AC-9, AC-10, AC-11, AC-12, AC-13, AC-14, AC-15, AC-16, AC-17, AC-18, EC-5, EC-8

## Parallelisierung

- **Stufen sind Schranken.** Eine Stufe beginnt erst, wenn die vorige zusammengeführt und gegen ihre AC-IDs geprüft ist.
- **`[P]` verlangt getrennte Dateien.** Geprüft: T2 und T3 sowie T5 und T6 teilen keine Datei.
- **Keine `[user]`-Aufgaben:** Der Entwurf braucht keine Einstellung in einem fremden Dashboard. Für den Live-Test braucht Timur seinen Groq-Schlüssel, den er schon hat.
- **Bekannte Berührung eines freigegebenen Features:** T6 ändert `AccessPane.swift` aus PROJ-3 (nur der äußere Rahmen wandert in die App); die PROJ-3-Tests laufen dabei mit.
