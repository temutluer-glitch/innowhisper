# Datenmodell

> Die app-weite Übersicht, **welche Daten das Produkt speichert und wie sie zusammenhängen**. Alle Features richten sich danach.
>
> - Angelegt durch `/init` am 2026-11-04.
> - Verfeinert durch `/architecture`, sobald ein Feature geplant wird.
> - **Flughöhe:** hier nur Dinge, Zusammenhänge und Zuständigkeit. Speicherformat, Felder und Schlüssel entscheidet das `design.md` des jeweiligen Features.

Es gibt keinen Server (ADR-002). Alle Daten liegen nur auf dem jeweiligen Mac und gehören dem dort angemeldeten Nutzer; nichts wird zwischen Macs abgeglichen.

## Dinge, die gespeichert werden

| Ding | Was es darstellt | Gehört / sichtbar für |
|------|------------------|-----------------------|
| Einstellungen | Modell („Schnell“ ab Werk oder „Genauer“) und Sprache (Deutsch ab Werk, Englisch, Automatisch) für die Umwandlung (PROJ-6), Ausgabe (einfügen oder Zwischenablage), Mikrofonwahl (Systemmikrofon oder ein bestimmtes Gerät, PROJ-5), Töne, Start beim Anmelden | Nutzer des Macs |
| Zugangsschlüssel | Der eigene Groq-Schlüssel; liegt ausschließlich im Schlüsselbund. Dazu ein Prüf-Stand (gilt, noch nicht geprüft, ungültig) in den Einstellungen (PROJ-4) | Nutzer des Macs |
| Tastenkürzel | Zusatztaste allein (z. B. rechte ⌘, ab Werk) oder Tastenkombination, Modus (halten oder ein/aus) und die verknüpfte KI-Vorlage; in PROJ-5 genau eins, ohne Vorlage | Nutzer des Macs |
| KI-Vorlage | Anweisung, wie die KI den Text überarbeitet; „Ohne KI“ ist fest eingebaut und nicht löschbar | Nutzer des Macs |
| Wörterbuch-Eintrag | Ein Name oder Fachbegriff, der richtig geschrieben werden soll | Nutzer des Macs |
| Ersetzung | Regel „aus X wird Y“, inklusive gesprochener Satzzeichen | Nutzer des Macs |
| Verlaufs-Eintrag | Ein fertiges Diktat mit Zeitpunkt, Text und benutzter Vorlage; höchstens 50 | Nutzer des Macs |
| Aufnahme | Tonaufnahme eines Diktats mit laufender Nummer (Sprech-Reihenfolge); entsteht in PROJ-5, wird von PROJ-6 umgewandelt und gehört danach zu einem Verlaufs-Eintrag, damit „noch einmal umwandeln“ möglich ist. PROJ-6 führt eine Aufnahme-Liste (Stand offen oder umgewandelt, ohne Text): offene bleiben, bis sie umgewandelt sind, auch über Neustarts; von den umgewandelten bleiben die letzten 50. Abgebrochene, verworfene, stille („Nichts erkannt“), kaputte und Probe-Aufnahmen werden sofort gelöscht | Nutzer des Macs |
| Einführungs-Fortschritt | Welche Einführungs-Schritte erledigt sind und ob die Einführung schon einmal abgeschlossen wurde (PROJ-3); Erlaubnis-Stände werden nicht gespeichert, sondern bei macOS abgefragt | Nutzer des Macs |
| Protokoll-Eintrag | Technischer Ablauf und Fehler, nie der gesprochene oder umgewandelte Inhalt; aufbewahrt höchstens 7 Tage und insgesamt höchstens 10 MB (PROJ-2) | Nutzer des Macs |

## Zusammenhänge

- Es gibt genau einen Satz Einstellungen und höchstens einen Zugangsschlüssel pro Nutzer.
- Den Schlüssel der alten App liest InnoWhisper nur einmal auf Wunsch, um ihn zu übernehmen; dessen Eintrag bleibt unverändert (PROJ-4).
- Jedes Tastenkürzel benutzt genau eine KI-Vorlage; eine Vorlage kann von mehreren Kürzeln benutzt werden.
- Wird eine Vorlage gelöscht, fallen die Kürzel, die sie benutzt haben, auf „Ohne KI“ zurück.
- Jede fertige Aufnahme wird in der Reihenfolge, in der gesprochen wurde, umgewandelt (PROJ-5 vergibt die Nummer, PROJ-6 hält die Reihenfolge ein).
- Jeder Verlaufs-Eintrag hat höchstens eine Aufnahme; wird der Eintrag gelöscht, wird die Aufnahme mitgelöscht.
- Kommt der 51. Verlaufs-Eintrag dazu, fällt der älteste samt Aufnahme automatisch weg.
- Bis PROJ-10 gebaut ist, gilt dieselbe Grenze schon für die Aufnahmen selbst: Kommt die 51. umgewandelte dazu, fällt die älteste weg (PROJ-6).
- Wörterbuch-Einträge und Ersetzungen gelten für jedes Diktat; beide lassen sich gemeinsam als Datei weitergeben und einlesen.
- Es gibt genau einen Einführungs-Fortschritt pro Nutzer; er merkt sich Schritt-Kennungen, die von den Features stammen, die Schritte einfügen (PROJ-3, PROJ-4, PROJ-5, PROJ-7).
- Protokoll-Einträge hängen an keinem anderen Ding und enthalten keine Diktat-Inhalte.

## Skizze

```
Einstellungen (1)
Zugangsschlüssel (0..1, Schlüsselbund)
KI-Vorlage (viele, „Ohne KI“ fest)
  └─ wird benutzt von vielen Tastenkürzeln
Wörterbuch-Einträge + Ersetzungen (viele) ──► Weitergabe als Datei
Verlaufs-Eintrag (max. 50)
  └─ hat höchstens eine Aufnahme (wird mitgelöscht)
Einführungs-Fortschritt (1)
Protokoll-Einträge (ohne Inhalte)
```

---

_Lebendes Dokument. Wenn `/architecture` ein Feature plant, das ein Ding einführt oder ändert, wird zuerst diese Übersicht angepasst._
