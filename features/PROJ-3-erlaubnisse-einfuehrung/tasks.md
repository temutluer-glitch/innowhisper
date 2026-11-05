# PROJ-3 Aufgaben

> Erstellt von `/tasks` aus `spec.md` + `design.md`. Geordneter, nachverfolgbarer Bauplan.
> `[P]` = parallel möglich: die Dateien der Aufgabe überschneiden sich mit keiner anderen `[P]`-Aufgabe derselben Stufe.
> Stufen laufen **nacheinander** (jede ist eine Schranke). Jede Aufgabe nennt die AC/EC-IDs aus `spec.md`, die sie erfüllt (AC → Aufgabe → Test).
> Owner: `/tasks` legt die Datei an; `/build` hakt ab; `[user]`-Aufgaben hakt Timur ab.
> Abkürzungen: `Kit/` = `Packages/InnoWhisperKit/`, `Onb/` = `Kit/Sources/Onboarding/`, `Perm/` = `Kit/Sources/Permissions/`, `Shell/` = `Kit/Sources/AppShell/`, `OnbT/` = `Kit/Tests/OnboardingTests/`, `PermT/` = `Kit/Tests/PermissionsTests/`.

## Stufe 1 — Grundgerüst und Unterschrift

- [x] T1 [P]  Module `Onboarding` (hängt von `AppShell`, `Diagnostics` ab) und `Permissions` (hängt von `AppShell`, `Diagnostics`, `Onboarding` ab) samt Testzielen anlegen, Platzhalter-Quellen und je ein erster Test; Protokoll-Bereiche `permissions` und `onboarding`  · files: Kit/Package.swift, Onb/Onboarding.swift, Perm/Permissions.swift, OnbT/SmokeTests.swift, PermT/SmokeTests.swift, Kit/Sources/Diagnostics/LogFile.swift  · → AC-20
- [x] T2 [P]  Entwicklungsbau fest unterschreiben: Debug mit „Developer ID Application“, Team N5QKANW6QY, Hardened Runtime bleibt; Berechtigung „Audio-Eingang“; Mikrofon-Begründungstext „InnoWhisper nimmt deine Stimme auf, um sie in Text umzuwandeln.“; vor dem ersten Bau den Schlüsselbund-Hinweis im Chat ankündigen; danach prüfen, dass zwei Bauten dieselbe Unterschrift-Kennung haben  · files: InnoWhisper.xcodeproj/project.pbxproj, App/InnoWhisper.entitlements, App/Info.plist  · → AC-8, AC-10
- [x] T3 [user]  (entfiel: kein Schlüsselbund-Fenster erschienen, laut Timur 05.11.) Beim ersten Bau im Fenster vom Schlüsselbund („codesign möchte auf … zugreifen“) auf „Immer erlauben“ klicken  · where: Fenster vom Schlüsselbund, erscheint beim Bau nach Ankündigung im Chat  · → AC-8, AC-10

## Stufe 2 — Innere Logik

- [x] T4 [P]  Einführungs-Ablauf: Schritt-Vertrag (Kennung, Protokollname, Reihenfolge, Titel, Inhalt, erfüllt, automatisch erledigt), Fortschritt speichern (`onboarding.completedSteps`, `onboarding.finishedOnce`, unbekannte Kennungen ignorieren, beschädigt = von vorn), Auswahl der Schritte je Durchlauf (erster Start, Fortsetzen, nur neue Schritte, automatisch erledigt), Weiter/Zurück, Weiter-Sperre, Rückprüfung, „Schritt X von Y“; Tests mit eigenem Einstellungs-Speicher  · files: Onb/OnboardingStep.swift, Onb/OnboardingProgressStore.swift, Onb/OnboardingFlow.swift, OnbT/OnboardingFlowTests.swift  · → AC-2, AC-5, AC-7, AC-13, AC-18, AC-19, EC-2
- [x] T5 [P]  Erlaubnis-Abfrage: Arten (Mikrofon, Bedienungshilfen), Stände (erlaubt, noch nie gefragt, abgelehnt; „eingeschränkt“ gilt als abgelehnt, im Protokoll getrennt), Schnittstelle mit Attrappe und echtem macOS-Anschluss, Mikrofon anfragen, Bedienungshilfen bei macOS eintragen, Systemeinstellungen an der richtigen Stelle öffnen mit Rückfall auf die Startseite; Tests  · files: Perm/Permission.swift, Perm/PermissionChecking.swift, Perm/SystemSettingsLinks.swift, PermT/PermissionTests.swift  · → AC-8, AC-9, AC-11
- [x] T6 [P]  Problem kann im Menüleisten-Fenster seinen eigenen Knopf behalten (Standard nein, bestehende Probleme unverändert); Test  · files: Shell/State/ProblemCenter.swift, Shell/MenuBar/MenuBarPanel.swift, Kit/Tests/AppShellTests/ProblemPanelActionTests.swift  · → AC-16

## Stufe 3 — Wächter und Fenster

- [x] T7 [P]  Erlaubnis-Wächter: Prüfen jede 1 s bei offener Einführung, sonst alle 3 s, sofort beim Zurückkommen und bei Änderung der Bedienungshilfen-Liste; Protokoll-Eintrag bei jeder Änderung; Probleme `permission.microphone` / `permission.accessibility` nur nach abgeschlossener und nicht offener Einführung melden bzw. zurückziehen; 10-Sekunden-Zeitgeber fürs Neustart-Angebot; Tests mit Attrappe und simulierter Zeit  · files: Perm/PermissionMonitor.swift, PermT/PermissionMonitorTests.swift  · → AC-8, AC-10, AC-15, AC-16, AC-20, EC-3
- [x] T8 [P]  Einführungsfenster: Titel „InnoWhisper einrichten“, 520 × 440, ohne Schließen/Minimieren/Vollbild, Esc und ⌘W wirkungslos, mittig auf dem Bildschirm mit dem Mauszeiger, nach vorne holen; Rahmenansicht mit „Schritt X von Y“, Fußleiste „Zurück“/„Weiter“ in gleicher Größe, Schritte „Willkommen“ und „Fertig“ mit den Texten aus AC-3/AC-4; VoiceOver und Tastatur  · files: Onb/OnboardingWindowController.swift, Onb/OnboardingView.swift, Onb/WelcomeAndDoneViews.swift  · → AC-1, AC-2, AC-3, AC-4, AC-5, AC-12, AC-21, AC-22, EC-5

## Stufe 4 — Erlaubnis-Oberflächen

- [x] T9 [P]  Erlaubnis-Schritte „Mikrofon“ (Reihenfolge 30) und „Bedienungshilfen“ (40): Erklärsatz, Stand mit grünem Häkchen, Knöpfe je Stand, Satz „Schalte dort InnoWhisper ein.“, Neustart-Knopf und Neustart (macOS öffnet die App nach 1 s wieder), VoiceOver-Ansage „Erlaubt“  · files: Perm/PermissionSteps.swift, Perm/PermissionStepView.swift, Perm/AppRelauncher.swift  · → AC-6, AC-7, AC-8, AC-9, AC-10, AC-11, AC-21, AC-22, EC-1, EC-3
- [x] T10 [P]  Bereich „Zugang & Erlaubnisse“ mit Gruppe „Erlaubnisse“: je Zeile Stand und „Jetzt erlauben“; der Problem-Hinweis kommt aus dem Rahmen  · files: Perm/AccessPane.swift  · → AC-16, AC-17, AC-22

## Stufe 5 — Zusammensetzen und echt prüfen

- [x] T11  App verdrahten: Wächter und Einführung erzeugen, Schritte und Bereich anmelden; ein Weg zum Öffnen der Einstellungen (offene Einführung kommt stattdessen nach vorne) für Menüleisten-Fenster, erneutes Öffnen und Zweitstart; Einführung beim Start zeigen, falls nötig; Prüfung auf die alte App erst nach der Einführung  · files: App/AppEnvironment.swift, App/AppDelegate.swift, App/InnoWhisperApp.swift  · → AC-1, AC-13, AC-14, AC-15, EC-4
- [x] T12  Am laufenden Programm prüfen, erst selbst messen (Protokoll, Erlaubnisse für die App zurücksetzen, Fortschritt löschen), dann Timur: erster Start, Mikrofon erlauben und ablehnen, Bedienungshilfen, mittendrin beenden, „Einstellungen …“ während der Einführung, Erlaubnis nachher entziehen und wieder erteilen; Ergebnisse und die zwei Mess-Fragen aus `design.md` in den Bau-Notizen festhalten  · files: features/PROJ-3-erlaubnisse-einfuehrung/design.md  · → AC-1, AC-8, AC-10, AC-11, AC-12, AC-13, AC-14, AC-15, AC-16, EC-3, EC-4

## Parallelisierung

- **Stufen sind Schranken.** Eine Stufe beginnt erst, wenn die vorige zusammengeführt und gegen ihre AC-IDs geprüft ist.
- **`[P]` verlangt getrennte Dateien.** Geprüft: Keine zwei `[P]`-Aufgaben einer Stufe nennen dieselbe Datei.
- **`[user]`-Aufgabe T3** zählt: Ohne den Klick lässt sich der Entwicklungsbau nicht fest unterschreiben.
- **Bekannte Lücke:** Der Hinweis beim Drücken des Tastenkürzels ohne Erlaubnis kommt erst mit PROJ-5.
