# Dungeon of Doom

Ported from BBC BASIC to PicoMite BASIC for the PicoCalc (320×320).

Originally from Usborne's *Write Your Own Fantasy Games For Your Microcomputer*.

## Setup

The game consists of three BASIC programs. Copy all three to a folder called `DOOM` on the root of the SD card:

```
B:/DOOM/DUNGEN.BAS
B:/DOOM/CHARGEN.BAS
B:/DOOM/DOOM.BAS
```

On PicoMite, `A:` is internal flash and `B:` is the SD card. The paths are set in two variables at the top of each program and can be changed there:

```basic
Dim DPATH$ = "B:/DOOM"
Dim SPATH$ = "B:/DOOM/SAVE"
```

### First-time setup

Run the programs in this order before playing for the first time:

1. **DUNGEN.BAS** — design and save your dungeon levels
2. **CHARGEN.BAS** — roll and equip a hero
3. **DOOM.BAS** — play the game

After the initial setup you can go straight to `DOOM.BAS` each time.

---

## DUNGEN.BAS — Level Designer

Writes `LEVEL1.DAT` through `LEVELn.DAT` and a `DUNGEON.DAT` index to `B:/DOOM/`.

`DUNGEON.DAT` records the total number of levels so the game can display "LEVEL 2 OF 5".

### Controls

| Key | Action |
|-----|--------|
| Arrow keys or H J K L | Move cursor |
| `1` | Place WALL |
| `2` | Place VASE |
| `3` | Place TREASURE |
| `4` | Place LOST IDOL |
| `5` | Place ENTRANCE |
| `6` | Place EXIT |
| `7` | Place TRAP |
| `8` | Place SAFE PLACE |
| `9` | Place MONSTER |
| `0` | Erase tile |
| `E` | Wipe the level |
| `N` | Save and go one level deeper |
| `S` | Save and stop |
| `Q` | Quit without saving |
| `?` | Show tile lore |

### Notes

- A level cannot be saved until an entrance (`5`) has been placed.
- The Lost Idol (`4`) ends the quest — place it on your deepest level.
- Levels already saved are loaded for editing, so you can revise a level without redrawing it from scratch.
- Rolling a new character or redrawing a level clears the matching save file.

---

## CHARGEN.BAS — Character Generator

Rolls stats and equips a hero, then writes `HERO.DAT` to `B:/DOOM/`.

---

## DOOM.BAS — The Game

Loads the level and hero files and saves progress. Run this to play.

### Saving and resuming

Press `S` during play. The current map state and hero are written to `B:/DOOM/SAVE/`, then the game stops.

On the next run, DOOM.BAS offers **Resume** or **New**.

The original level files in `B:/DOOM/` are never overwritten — the game reads a saved level if one exists and falls back to the original otherwise. Starting a new hero gives a fresh dungeon without re-running DUNGEN.BAS.

---

## Playing the Game

The game runs in real time. Monsters move every tick whether you act or not. Tarry not.

### Screen layout

The dungeon occupies the left 15×15 grid. A status panel runs down the right side:

| Field | Meaning |
|-------|---------|
| STR | Current hit points |
| VIT | Vitality — max hit points, depletes slowly when struck |
| AURA | Magical energy, needed to cast spells |
| FACE | Direction you are facing: N E S W |
| EXP | Experience |
| GOLD | Gold carried |
| TRSR | Treasure pieces found |

The bottom bar shows:

| Field | Meaning |
|-------|---------|
| ATT | Total attack power (STR + weapons) |
| SPL | Spell charges remaining |
| LGT | Lamp oil charges |
| POT | Potions and salves combined |

Your hero (`@`) changes sprite to show which way you face.

### Movement

You move one square at a time in the direction you are currently facing.

| Key | Action |
|-----|--------|
| `↑` or `M` | Move forward |
| `←` or `B` | Turn left (widdershins) |
| `→` or `N` | Turn right (sunwise) |

Bumping into a wall, monster, or loose object costs a sliver of STR.

### Tiles

Only squares you have already lit are visible. Unexplored passages stay dark.

| Tile | Meaning |
|------|---------|
| `@` | Your hero |
| `#` | Wall — impassable |
| `!` | Flask — contains a salve and a potion |
| `$` | Treasure |
| `&` | The Lost Idol — your quest goal |
| `*` | Entrance |
| `>` | Stairs down to the next level |
| `^` | Trap |
| `O` | Magic circle — you cannot be damaged while standing on it |
| `a` `b` `c` | Monsters, weakest to worst |

Walking onto the stair tile (`>`) descends automatically.

A trap (`^`) snares you in place, draining STR each tick, until a lucky Agility check frees you.

### Combat

Press `A` to attack the monster one square ahead of you.

Your attack connects if Agility plus Luck beats the monster's roll. A miss does no damage. A hit deals damage based on your STR plus any weapons carried, reduced by the monster's toughness. Monsters strike back automatically when adjacent — armour and a helmet reduce what gets through.

A monster can smash one piece of your equipment when it hits. Killing a monster adds an EXP bonus.

### Picking things up

Press `G` (or `↓`) to grab what is one square ahead of you.

| Tile | What you get |
|------|-------------|
| `!` Flask | One salve and one potion |
| `$` Treasure | One treasure piece (adds to TRSR and score) |
| `&` Lost Idol | Quest complete — victory screen shown |

### Potions and salves

Press `P` to quaff. The game uses a potion first if STR is below its peak, otherwise uses a salve if VIT is below its peak.

- **Potion** — restores STR to its peak value
- **Salve** — restores VIT to its peak value

### Lamp and darkness

Press `R` to reveal — lights the 7×7 area around you, costing one lamp oil charge. Without oil, the message "NO LIGHT" is shown. Squares already visited stay visible without spending oil.

### Spells

Press `C` to open the spell menu. Requires AURA above zero and at least one spellbook or scroll set carried.

- The **Necronomicon** grants spells 1–3.
- The **Scrolls** grant spells 4–6.

| # | Name | Effect |
|---|------|--------|
| 1 | SMITE | Instantly slays the monster in front of you |
| 2 | WARD | Lays a magic circle (`O`) beneath your feet |
| 3 | TRANSPORT | Teleports you to a random square on the level |
| 4 | MEND | Heals a small amount of STR and VIT |
| 5 | CHAOS | Randomly remakes the tile directly ahead — can clear a monster or obstacle |
| 6 | RENEWAL | Fully restores STR and VIT |

Each spell costs one charge. Casting with no charges left wastes the action. Spells 4 and 6 also drain one point of AURA.

Press `0` to cancel the spell menu without casting.

### Key reference

Press `?` in-game to show the lore screen.

| Key | Action |
|-----|--------|
| `↑` / `M` | Move forward |
| `←` / `B` | Turn left |
| `→` / `N` | Turn right |
| `↓` / `G` | Pick up ahead |
| `A` | Attack |
| `C` | Cast spell |
| `P` | Quaff potion or salve |
| `R` | Reveal area (costs lamp oil) |
| `S` | Save and stop |
| `?` | Show lore screen |

### Victory and defeat

Grab the Lost Idol (`&`) on the deepest level to complete the quest. Your final score is:

```
(treasure × 10) + (gold × experience) + STR + VIT + Agility
```

If STR reaches zero, your hero expires. The level they fell on is shown on the death screen.
