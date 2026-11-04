# Gestaltungsregeln (Design System)

> Verbindlich für jedes Feature. `/build` wendet diese Werte an, ohne neu zu fragen. Freigegeben am 2026-11-04.

## Grundsatz
- Native macOS-26-App nach Apples Human Interface Guidelines, gebaut aus SwiftUI-Standardbausteinen.
- Hell- und Dunkelmodus sind von Anfang an beide abgedeckt, über System-Farben automatisch.
- Keine eigenen Nachbauten von Bausteinen, die macOS schon mitbringt.

## Liquid Glass
- Glas nur für schwebende Ebenen: Sprechblase, Menüleisten-Fenster, Knopfleisten, Hinweise.
- Inhaltsflächen (Einstellungsseiten) bleiben ruhig: gruppierte Formulare wie in den Systemeinstellungen, kein Glas hinter Text.
- Mehrere Glas-Elemente, die nebeneinander stehen, kommen in einen gemeinsamen Glas-Container, damit sie wie eine Fläche wirken.
- „Transparenz reduzieren“ in den macOS-Einstellungen wird respektiert: Das Glas wird zur festen Fläche (Systemverhalten, nicht abschalten).
- Konkrete SwiftUI-Schnittstellen (z. B. `glassEffect`, `GlassEffectContainer`, Glas-Knopfstile) legt `/architecture` von PROJ-1 fest und prüft sie gegen die Xcode-26-Dokumentation.

## Farben
Nur semantische System-Farben, keine festen Hex-Werte und nie reines Schwarz oder Weiß für Flächen oder Text.

| Rolle | Wert | Verwendung |
|-------|------|------------|
| Akzent (primary) | System-Akzentfarbe des Nutzers (`Color.accentColor`) | Hauptknopf, Auswahl, Fokus |
| Text | `Color.primary` | normaler Text |
| Nebentext (secondary) | `Color.secondary` | Erklärungen, Zeitstempel |
| Hintergrund | System-Fenster- und Formular-Hintergründe | Fenster, Gruppen |
| Aufnahme | `Color.red` (System-Rot) | Aufnahme-Punkt, nur während der Aufnahme |
| Destruktiv | `Color.red` über die Rolle „destruktiv“ | Löschen |
| Warnung | `Color.orange` (System-Orange) | fehlende Erlaubnis, fehlender Schlüssel |
| Erfolg | `Color.green` (System-Grün) | Schlüssel geprüft, Text eingefügt |

- Akzent hat Hover-, Gedrückt- und dezente Hintergrund-Variante über die Systemstile, nie eine flache Farbfläche.
- Kontrast mindestens 4,5:1 für Text in beiden Modi; System-Farben auf System-Hintergründen erfüllen das, eigene Kombinationen werden geprüft.

## Schrift
- Systemschrift SF Pro über SwiftUI-Textstile; folgt der vom Nutzer eingestellten Schriftgröße.

| Stufe | Stil | Gewicht |
|-------|------|---------|
| Seitentitel | `.title2` | halbfett |
| Gruppenüberschrift | `.headline` | fett (Systemstandard) |
| Text | `.body` | normal |
| Nebentext | `.callout` / `.caption` | normal, Farbe `secondary` |
| Diktat-Text im Verlauf | `.body` | normal |

## Formen, Abstände, Tiefe
- **Knöpfe und kleine Bedienelemente:** Kapselform (macOS-26-Standard).
- **Flächen** (Sprechblase, Karten, Hinweise): ein einheitlicher Eckenradius von 12 pt; ineinanderliegende Flächen folgen dem konzentrischen System-Radius.
- **Abstände:** Raster 4 / 8 / 12 / 16 / 24 pt.
- **Tiefe:** keine selbst gebauten Schatten; Ebenen entstehen durch Glas und System-Hintergründe, Trennung innerhalb von Inhalten durch Gruppen und feine System-Trennlinien.

## Bausteine
- **Knöpfe:** überall dieselbe Größe (`controlSize` regulär). Hauptknopf hervorgehoben (prominenter Stil), Nebenknöpfe schlicht im selben Format, Löschen mit Rolle „destruktiv“ im selben Format. Nie verschiedene Knopfgrößen nebeneinander.
- **Zustände:** jedes bedienbare Element hat einen sichtbaren Hover- und Tastatur-Fokus-Zustand (System-Fokusring nicht entfernen).
- **Eingabefelder:** Standard-Textfelder der Formulare, einheitliche Höhe; Tastenkürzel-Aufnahme als eigenes Feld im selben Format.
- **Symbole:** ausschließlich SF Symbols, Darstellung „hierarchisch“.
- **Leer:** `ContentUnavailableView` mit Symbol, einem Satz und, wenn sinnvoll, einem Knopf.
- **Laden:** kleine `ProgressView` an der Stelle, die lädt; nie ein blockierendes Fenster.
- **Problem-Hinweis:** Leiste oben im Bereich mit Warnsymbol, einem Satz und einem Lösungsknopf.
- **Sprechblase:** Glas-Kapsel mit Tonwelle und rotem Aufnahme-Punkt; bei „Bewegung reduzieren“ ruhigere Animation ohne Pulsieren.
- **Menüleisten-Symbol:** SF Symbol, das den Zustand zeigt (bereit, nimmt auf, wandelt um, Problem); Zustand zusätzlich für VoiceOver beschriftet.

## Barrierefreiheit
- Alle Bedienelemente sind für VoiceOver beschriftet und per Tastatur erreichbar.
- „Transparenz reduzieren“, „Bewegung reduzieren“ und „Kontrast erhöhen“ werden respektiert.
