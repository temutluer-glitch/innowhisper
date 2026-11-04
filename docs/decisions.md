# Projektweite Entscheidungen

> Entscheidungen, die mehrere Features betreffen. Feature-eigene Entscheidungen stehen im jeweiligen `design.md`.

## ADR-001 Echte Mac-App in Swift/SwiftUI, nur macOS 26
- **Status:** Accepted · **Datum:** 2026-11-04 · **Betrifft:** alle Features
- **Kontext:** Neuaufbau der Menüleisten-App. Gewünscht ist der aktuelle Apple-Look mit Liquid Glass; Kern der App ist der Zugriff auf Mikrofon, globale Tastenkürzel und das aktive Eingabefeld (Bedienungshilfen).
- **Entscheidung:** Swift mit SwiftUI (Menüleiste über `MenuBarExtra`), Mindestversion macOS 26, Bau mit Xcode 26.
- **Alternativen:** Web-Technik als Mac-App verpackt (abgelehnt: schwerfälliger, schlechterer Zugriff auf Eingabefelder und Tastenkürzel). macOS 14 mit Ersatz-Look für ältere Systeme (abgelehnt von Timur: einfacher und überall voller Look gewünscht).
- **Folgen:** Macs mit älterem System müssen vor der Installation auf macOS 26 aktualisiert werden. Tragende Entscheidung: Eine spätere Absenkung der Mindestversion kostet Umbau aller Liquid-Glass-Stellen.

## ADR-002 Kein Backend, alle Daten lokal
- **Status:** Accepted · **Datum:** 2026-11-04 · **Betrifft:** alle Features mit gespeicherten Daten
- **Entscheidung:** Einstellungen, Verlauf und Wörterbuch liegen nur auf dem jeweiligen Mac; der Zugangsschlüssel liegt im Schlüsselbund.
- **Alternativen:** Server für ein gemeinsames Team-Wörterbuch (abgelehnt: Aufwand, Kosten, Fehlerquelle, mehr Datenschutzthemen; vorerst reicht Weitergabe als Datei).
- **Folgen:** Kein Abgleich zwischen Macs. Ein Team-Wörterbuch kann später als eigenes Feature kommen.

## ADR-003 Groq als einziger Anbieter für Spracherkennung und KI
- **Status:** Accepted · **Datum:** 2026-11-04 · **Betrifft:** Umwandlung, KI-Nachbearbeitung, Zugang
- **Entscheidung:** Spracherkennung über Groq Whisper, optionale Nachbearbeitung über ein Groq-Sprachmodell. Jeder Nutzer trägt seinen eigenen Zugangsschlüssel ein.
- **Alternativen:** Umwandlung lokal auf dem Mac, andere Anbieter (beide bewusst nicht in dieser Version).
- **Folgen:** Abhängigkeit von Groq (Verfügbarkeit, Grenzen, Preise). Ohne Internet keine Umwandlung. Unsicherheit: genaue Grenzen des Kontos, beim Bau prüfen.

## ADR-004 Neue Kennung com.innosolv.InnoWhisper
- **Status:** Accepted · **Datum:** 2026-11-04 · **Betrifft:** Erlaubnisse, Updates, Auslieferung
- **Entscheidung:** Neue Bundle-ID statt der alten.
- **Alternativen:** Alte Kennung behalten (Erlaubnisse und automatisches Update blieben erhalten, der alte Name bliebe intern bestehen).
- **Folgen:** Jeder im Team installiert einmal von Hand, erteilt Mikrofon und Bedienungshilfen neu und entfernt die alte App. Dafür kommt eine kurze Umzugsanleitung.

## ADR-005 Öffentliches GitHub-Projekt, Updates über Sparkle
- **Status:** Accepted · **Datum:** 2026-11-04 · **Betrifft:** Updates & Auslieferung
- **Entscheidung:** Öffentliches GitHub-Projekt; Versionen als GitHub Releases; Sparkle liest die Update-Liste direkt von dort; Beglaubigung über das aktive Apple-Entwicklerkonto.
- **Alternativen:** Privates Projekt mit zweitem öffentlichen Ablageort (abgelehnt: mehr Aufwand, zusätzliche Fehlerquelle).
- **Folgen:** Der Code ist öffentlich einsehbar; er darf keine Geheimnisse enthalten. Vor jeder Version prüfen, ob neue Apple-Bedingungen bestätigt werden müssen (sonst lehnt Apple die Beglaubigung ab).

## ADR-006 Kein Datenschutzrecht eingetragen
- **Status:** Accepted · **Datum:** 2026-11-04 · **Betrifft:** Umwandlung, Verlauf, Fehlerprotokoll
- **Entscheidung:** Timur hat entschieden, kein Datenschutzrecht einzutragen („internes Tool“).
- **Hinweis (offen):** Diktate enthalten personenbezogene Daten und gehen an einen US-Anbieter; die DSGVO kann auch für interne Nutzung gelten. Keine Rechtsberatung; verbindlich klären kann ein Anwalt oder Datenschutzbeauftragter.
- **Folgen:** Es läuft keine `/dsgvo`-Prüfung. Unabhängig davon gelten die Sicherheitsregeln des Projekts: keine Diktat-Inhalte im Fehlerprotokoll, Zugangsschlüssel nur im Schlüsselbund.

## ADR-007 Hardened Runtime ohne App Sandbox
- **Status:** Accepted · **Datum:** 2026-11-04 · **Betrifft:** alle Features, vor allem PROJ-1, PROJ-7, PROJ-8, PROJ-12, PROJ-14
- **Kontext:** InnoWhisper wird außerhalb des App Store verteilt. Es muss Text in fremde Apps einfügen, das aktive Eingabefeld über die Bedienungshilfen lesen, globale Tastenkürzel abfangen und die alte App erkennen und beenden.
- **Entscheidung:** Hardened Runtime eingeschaltet (Voraussetzung für die Beglaubigung durch Apple), App Sandbox ausgeschaltet. Zusätzliche Berechtigungen nur, wenn ein Feature sie nachweislich braucht, und dann im Feature-Plan begründet.
- **Alternativen:** App Sandbox (abgelehnt: blockiert das Steuern und Auslesen anderer Apps über die Bedienungshilfen, das Kern der App ist).
- **Folgen:** Kein App-Store-Vertrieb. Die App hat die Rechte des angemeldeten Nutzers; umso wichtiger, dass sie keine Diktat-Inhalte protokolliert und keine fremden Eingaben annimmt.
- **Ausnahme (2026-11-04, PROJ-1 QA):** Der lokale Entwicklungsbau (Debug) trägt die Berechtigung `get-task-allow`, damit Xcodes Fehlersuche andocken kann. Gilt nur für Debug auf dem Entwickler-Mac; ausgeliefert wird nur Release ohne diese Berechtigung. Prüfanlass: Wer mit PROJ-3 Mikrofon und Bedienungshilfen für den Debug-Bau erlaubt, nimmt in Kauf, dass ein anderer Prozess desselben Nutzers diese Rechte über die Fehlersuche mitbenutzen könnte.

## ADR-008 Projektaufbau: Xcode-Projekt plus lokales Swift-Paket, Swift Testing, swift-format
- **Status:** Accepted · **Datum:** 2026-11-04 · **Betrifft:** alle Features
- **Entscheidung:** Ein Xcode-Projekt `InnoWhisper.xcodeproj` mit synchronisiertem Ordner `App/` (neue Dateien ändern die Projektdatei nicht). Logik und Oberflächen leben im lokalen Paket `Packages/InnoWhisperKit`, ein Modul je Feature, Tests mit Swift Testing (`swift test`). Formatierung und Stilprüfung mit dem in Xcode enthaltenen `swift format`. Keine zusätzlichen Werkzeuge nötig.
- **Alternativen:** XcodeGen wie bei der alten App (abgelehnt: zusätzliches Werkzeug, war versionsempfindlich und brauchte eine eigene Vorlagen-Aufbereitung). Reines Swift-Paket mit selbst gebautem App-Paket per Skript (abgelehnt: Einbetten von Sparkle und Signieren müssten selbst gebaut werden, genau dort lagen früher Fehler).
- **Folgen:** Projekteinstellungen (Kennung, Mindestversion, Berechtigungen) liegen in der Projektdatei und in `App/Info.plist`; Änderungen daran werden im Feature-Plan genannt. Befehle zum Bauen, Testen und Prüfen werden nach dem Anlegen des Projekts mit `/init checks` eingetragen.
