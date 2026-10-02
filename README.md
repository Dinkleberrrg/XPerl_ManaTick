# X-Perl ManaTick

Add-on module for X-Perl UnitFrames (WoW 1.12): shows the five-second rule and the mana tick as a thin strip on the X-Perl mana bar.

## What it shows
- **Five-second rule:** after spending mana, spirit-based regeneration pauses for five seconds. The strip fills up during that time with a spark riding the leading edge.
- **Two-second tick:** afterwards mana comes back every two seconds; the strip shows the next tick.

Both phases can be turned off individually. The default look matches the energy ticker of X-Perl 3.x (WotLK).

## Usage
- `/xpm` or `/xperlmana` opens the settings.
- Alternatively use the button next to the X-Perl options.

## How it works
Vanilla has neither an event for the regeneration tick nor an API for the remaining lockout. Both are derived from `UNIT_MANA`: mana goes down, so the lockout restarts; mana goes up, so a tick just happened.

## Requirements
XPerl

## Saved data
`XPerlManaTickConfig`
