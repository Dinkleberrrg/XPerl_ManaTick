# X-Perl ManaTick

Zusatzmodul für X-Perl UnitFrames (WoW 1.12): zeigt die Fünf-Sekunden-Regel und den Mana-Tick als schmalen Streifen am XPerl-Manabalken.

## Was es zeigt
- **Fünf-Sekunden-Regel:** Nach jedem Manaverbrauch pausiert die geistbasierte Regeneration fünf Sekunden. Der Streifen füllt sich in dieser Zeit, ein Funke läuft an der Vorderkante mit.
- **Zwei-Sekunden-Tick:** Danach kommt Mana im Zwei-Sekunden-Takt zurück, der Streifen zeigt den nächsten Tick.

Beide Phasen lassen sich einzeln abschalten. Die Standardoptik entspricht dem Energy-Ticker aus XPerl 3.x (WotLK).

## Bedienung
- `/xpm` oder `/xperlmana` öffnet die Einstellungen.
- Alternativ über den Knopf neben den XPerl-Optionen.

## Wie es funktioniert
Vanilla hat weder ein Ereignis für den Regenerationstick noch eine API für die verbleibende Sperrzeit. Beides wird aus `UNIT_MANA` abgeleitet: Mana sinkt, also startet die Sperre neu; Mana steigt, also war gerade ein Tick.

## Voraussetzungen
XPerl

## Gespeicherte Daten
`XPerlManaTickConfig`
