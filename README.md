# Dungeon of Doom

Ported from BBC BASIC to PicoMite BASIC for the PicoCalc (320×320).

Originally from Usborne's *Write Your Own Fantasy Games For Your Microcomputer*.

## Setup

The game consists of three BASIC programs. Copy all three to the SD card folder `B:/picomite/games/rpg/DOOM`:

```
B:/picomite/games/rpg/DOOM/DUNGEN.BAS
B:/picomite/games/rpg/DOOM/CHARGEN.BAS
B:/picomite/games/rpg/DOOM/DOOM.BAS
```

On PicoMite, `A:` is internal flash and `B:` is the SD card. The data paths are set in two variables at the top of each program and can be changed there (the programs create missing folders themselves):

```basic
Dim DPATH$ = "B:/picomite/games/rpg/DOOM"
Dim SPATH$ = "B:/picomite/games/rpg/DOOM/SAVE"
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
| `R` | Conjure a random level |
| `E` | Wipe the level |
| `N` | Save and go one level deeper |
| `S` | Save and stop |
| `Q` | Quit without saving |
| `?` | Show tile lore |

### Notes

- A level cannot be saved until an entrance (`5`) has been placed.
- The Lost Idol (`4`) ends the quest — place it on your deepest level.
- `R` generates a complete level — walls, entrance, exit, treasure, traps and monsters — with every square guaranteed reachable from the entrance. Edit the result before saving; the Idol must still be placed by hand. Wall density and item counts are tuning constants at the top of DUNGEN.BAS.
- Levels already saved are loaded for editing, so you can revise a level without redrawing it from scratch.
- Rolling a new character or redrawing a level clears the matching save file.

---

## CHARGEN.BAS — Character Generator

Rolls stats and equips a hero, then writes `HERO.DAT` to `B:/DOOM/`.

### Character Classes

Your class is determined automatically from your attributes after spending spare points. The checks are evaluated in order — later matches override earlier ones, so if you qualify for both Cleric and Warrior you become a Warrior.

| # | Class | Requirements |
|---|-------|--------------|
| 1 | **Wanderer** | Default — any hero who meets no other criteria |
| 2 | **Cleric** | INT > 6 **and** MORALITY > 7 |
| 3 | **Magician** | INT > 8 **and** AURA > 7 |
| 4 | **Warrior** | STR > 7 **and** MORALITY > 5 **and** STR + VIT > 10 |
| 5 | **Barbarian** | STR > 8 **and** VIT + AGI > 12 **and** MORALITY < 6 |

#### Minimum attributes to guarantee each class

Because later rules override earlier ones, you must also ensure you **don't** accidentally qualify for a higher-numbered class.

| Class | Minimum build | Key constraints |
|-------|--------------|-----------------|
| **Wanderer** | No special requirements | Fail all other class checks — keep INT ≤ 6, STR ≤ 7, and (STR ≤ 8 or VIT+AGI ≤ 12 or MORALITY ≥ 6) |
| **Cleric** | INT 7, MORALITY 8 | Must also fail Magician (keep INT ≤ 8 or AURA ≤ 7), fail Warrior (keep STR ≤ 7 or MORALITY ≤ 5 or STR+VIT ≤ 10), and fail Barbarian (keep STR ≤ 8 or VIT+AGI ≤ 12 or MORALITY ≥ 6) |
| **Magician** | INT 9, AURA 8 | Must also fail Warrior (keep STR ≤ 7 or MORALITY ≤ 5 or STR+VIT ≤ 10) and fail Barbarian (keep STR ≤ 8 or VIT+AGI ≤ 12 or MORALITY ≥ 6) |
| **Warrior** | STR 8, MORALITY 6, and STR+VIT > 10 (e.g. STR 8 + VIT 3) | Must also fail Barbarian (keep STR ≤ 8 or VIT+AGI ≤ 12 or MORALITY ≥ 6). Since MORALITY ≥ 6, Barbarian is already blocked |
| **Barbarian** | STR 9, VIT+AGI > 12 (e.g. VIT 7 + AGI 6), MORALITY ≤ 5 | Highest priority — no further checks needed |

#### Practical example builds (using minimum spare points)

| Class | STR | VIT | AGI | INT | LUCK | AURA | MORALITY |
|-------|-----|-----|-----|-----|------|------|----------|
| Wanderer | 5 | 5 | 5 | 5 | 5 | 5 | 5 |
| Cleric | 5 | 5 | 5 | 7 | 5 | 5 | 8 |
| Magician | 5 | 5 | 5 | 9 | 5 | 8 | 5 |
| Warrior | 8 | 3 | 3 | 3 | 3 | 3 | 6 |
| Barbarian | 9 | 7 | 6 | 3 | 3 | 3 | 3 |

> **Tip:** Attributes are rolled as 1d5 + 2 (range 3–7) and you receive 3–8 spare points to distribute. The class display updates live as you move points around.

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

### Movement and facing

Your hero always faces one of the four compass directions — N, E, S or W. The FACE field in the status panel shows which, and the hero's sprite points the same way.

| Key | Action |
|-----|--------|
| `↑` or `M` | Move forward one square, in the direction faced |
| `←` or `B` | Turn left on the spot (widdershins) |
| `→` or `N` | Turn right on the spot (sunwise) |

All movement is forwards. There is **no key to step backwards or sideways** — this is by design, kept from the original BBC game's controls. To retreat you must turn about (two turns) and then walk, and since the game runs in real time the monster keeps coming while you turn. Choose your facing before trouble arrives.

Facing also governs your hands: `G` grabs whatever lies in the square directly ahead of you, and the CHAOS spell remakes the square directly ahead. Face a thing to use it.

Bumping into a wall, monster, or loose object costs a sliver of STR.

### Exertion and rest

Every tick in which you press any key saps 1% of your STR — action is effort. Bumping obstacles costs a little more, and traps grind you down while they hold you.

Whenever STR is below its peak it recovers slowly, at a rate set by your VIT — the hardier the hero, the faster the wind returns. Stand still a moment and watch it climb. A potion (`P`) restores STR to its peak at once.

The STR figure in the panel is rounded to the nearest whole point, so small wear and recovery won't show until it amounts to something.

If STR ever falls below one the hero dies, whether by blows or by sheer exhaustion. Keep a potion for the long fights.

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

A trap (`^`) snares you in place while your exertion drains STR. Only once STR has worn below 80% of its peak can a roll of your LUCK spring you free — a trap is always a costly detour.

### Combat

Press `A` to attack the monster that has closed with you. Once a monster is spotted it hunts you, and `A` strikes at it when it is near, whichever way you face — only grabbing and the CHAOS spell insist on facing.

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
