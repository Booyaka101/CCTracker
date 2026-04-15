# CC Tracker

Lightweight crowd control, silence, and interrupt tracker for **WoW 3.3.5a Ascension**. Designed for the classless system where any player can have any ability.

![Interface 30300](https://img.shields.io/badge/Interface-30300-blue)
![Version 1.0.0](https://img.shields.io/badge/Version-1.0.0-green)

## Features

- **CC Timer Bars** — icon + colored bar + countdown for every crowd control effect on you
- **Interrupt Lockouts** — tracks spell school lockouts from Counterspell, Kick, Pummel, etc.
- **Diminishing Returns** — shows DR state (50% → 25% → IMMUNE) with countdown to reset
- **Full WotLK Coverage** — stuns, silences, fears, roots, incapacitates, and disarms from all classes
- **Combat Log Alert** — raid warning flash when you get interrupted
- **Classless-Ready** — covers every CC ability in WoW 3.3.5, since Ascension players can mix talents

## Display

- Color-coded bars by CC category (red = stun, purple = silence, yellow = fear, etc.)
- Cooldown spiral overlay on icons
- Category labels (STUNNED, SILENCED, FEARED, etc.)
- Bars flash red in the last 2 seconds
- Grow up or down from anchor
- Fully scalable and repositionable

## Settings Panel

Open with `/cct` or `/cct config`. Configure:

- Icon size, bar width/height, spacing, scale
- Show/hide icons, spirals, labels, category text
- Toggle each CC category independently
- DR timer toggle
- PvP/Arena-only mode
- Lock/unlock, preview, reset position

## Slash Commands

| Command | Description |
|---------|-------------|
| `/cct` | Open settings panel |
| `/cct unlock` | Unlock for dragging |
| `/cct lock` | Lock position |
| `/cct test` | Show preview timers |
| `/cct reset` | Reset to default position |
| `/cct debug` | Toggle interrupt debug logging |

## Installation

1. Download or clone this repo into your `Interface/AddOns/` folder
2. Folder name must be `CCTracker`
3. Restart WoW or `/reload`

## Tracked CC Categories

| Category | Color | Examples |
|----------|-------|---------|
| Stun | Red | Hammer of Justice, Kidney Shot, Cheap Shot, Deep Freeze |
| Silence | Purple | Counterspell, Spell Lock, Strangulate |
| Fear | Yellow | Fear, Psychic Scream, Intimidating Shout |
| Root | Green | Frost Nova, Entangling Roots, Chains of Ice |
| Incapacitate | Blue | Polymorph, Sap, Blind, Hex, Cyclone |
| Disarm | Orange | Disarm, Dismantle, Psychic Horror |
| Interrupt | Cyan | Kick, Pummel, Counterspell, Wind Shear |

## License

Free to use and modify.
