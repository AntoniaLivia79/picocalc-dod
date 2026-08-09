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

### Attributes

Every hero has eight attributes rolled during character creation (1d5 + 2, range 3–7 each). Here is what each one does in practice:

| Attribute | Abbrev | Role during play |
|-----------|--------|-----------------|
| **Strength** | STR | Your current hit points. Falls from exertion, bumps, traps, and monster hits. If it drops below 1 you die. Recovers slowly when idle (rate governed by VIT). Also contributes to your attack damage. |
| **Vitality** | VIT | Maximum hit-point ceiling and recovery rate. The higher your VIT, the faster STR regenerates. Slowly depleted when you take damage. Restored by salves or the RENEWAL spell. |
| **Agility** | AGI | Determines whether a monster's blow connects — higher AGI (combined with Luck) lets you dodge attacks. Also factors into attack accuracy. Contributes to final score. |
| **Intelligence** | INT | Determines class at creation (Cleric requires INT > 6; Magician requires INT > 8). During play, a hero with INT above 6 can detect hidden traps — they are always visible on the map. Lower-INT heroes only see a trap after stepping on it. |
| **Experience** | EXP | Grows as you kill monsters (+0.1), land hits (+0.05), and cast spells (+0.2). Multiplies gold in the final score formula. If the optional experience gate is enabled, you must earn enough experience (one per level) to descend stairs. |
| **Luck** | LCK | Adds randomness to your attacks, helps you dodge monster blows, and determines how quickly you escape traps (must roll under Luck once STR falls below 80% of peak). |
| **Aura** | AUR | Magical energy. Required to cast spells (must be > 0). The MEND and RENEWAL spells each cost one point of Aura. Also scales spell charge counts when a level is loaded. |
| **Morality** | MOR | Used only during character creation to determine class and restrict shop purchases. Has no mechanical effect during play. |

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

### Equipment Shops

After spending spare attribute points you visit three shops with a purse of 120–180 gold coins. Items below index 23 can only be bought once; salves and potions may be purchased repeatedly. You can **Buy** at list price or **Offer** a lower amount (up to 3 gold discount chosen randomly).

Class restrictions use a five-class mask (Wanderer / Cleric / Magician / Warrior / Barbarian). A "✗" means the class **cannot** buy that item.

#### Armoury (Weapons)

Weapons add directly to your **ATT** (attack) total. ATT = STR + the sum of all weapon item values you carry. A hit deals ATT + a Luck die roll, reduced by the monster's toughness. Monsters can permanently destroy one piece of equipment when they strike you (items 1–11 are vulnerable).

| # | Item | Cost | Qty | ATT bonus | Wanderer | Cleric | Magician | Warrior | Barbarian |
|---|------|------|-----|-----------|----------|--------|----------|---------|-----------|
| 1 | 2 Hand Sword | 20 | 5 | +5 | ✗ | ✗ | ✗ | ✗ | ✓ |
| 2 | Broadsword | 16 | 4 | +4 | ✗ | ✗ | ✗ | ✓ | ✓ |
| 3 | Short Sword | 12 | 3 | +3 | ✓ | ✗ | ✗ | ✓ | ✓ |
| 4 | Axe | 15 | 3 | +3 | ✓ | ✗ | ✗ | ✓ | ✓ |
| 5 | Mace | 8 | 2 | +2 | ✓ | ✗ | ✗ | ✓ | ✓ |
| 6 | Flail | 10 | 2 | +2 | ✗ | ✗ | ✗ | ✓ | ✓ |
| 7 | Dagger | 8 | 1 | +1 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 8 | Gauntlet | 6 | 1 | +1 | ✓ | ✗ | ✗ | ✓ | ✓ |

> **Note on the Flail:** The original listing omitted the flail from the attack formula. The port includes a bug-fix flag (`FIXFLAIL = 1`) so the flail now contributes to ATT as expected.

#### Accoutrements (Armour & Defence)

Armour items reduce incoming monster damage. The formula divides raw damage by (3 + sum of all armour item values), so each point raises your effective toughness. Armour items 9–11 and helmets 13–14 can be destroyed by monster strikes.

| # | Item | Cost | Qty | Defence bonus | Wanderer | Cleric | Magician | Warrior | Barbarian |
|---|------|------|-----|---------------|----------|--------|----------|---------|-----------|
| 9 | Heavy Armour | 18 | 5 | +5 | ✗ | ✗ | ✗ | ✓ | ✓ |
| 10 | Chain Armour | 15 | 4 | +4 | ✗ | ✗ | ✗ | ✓ | ✓ |
| 11 | Leather Armour | 9 | 3 | +3 | ✓ | ✗ | ✗ | ✓ | ✓ |
| 12 | Heavy Robe | 9 | 1 | +1 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 13 | Gold Helmet | 14 | 2 | +2 | ✗ | ✗ | ✗ | ✓ | ✓ |
| 14 | Headpiece | 8 | 1 | +1 | ✓ | ✓ | ✗ | ✓ | ✓ |
| 15 | Shield | 6 | 3 | — | ✓ | ✓ | ✗ | ✓ | ✓ |
| 16 | Torch | 6 | 1 | — | ✓ | ✓ | ✓ | ✓ | ✓ |

- **Shield** — has no direct stat bonus in the current code; it occupies an equipment slot and can be destroyed by monsters (absorbing a hit that would otherwise break something else).
- **Torch** — grants 20 lamp oil charges, used by pressing `R` to reveal the 7×7 area around you.

#### Emporium (Magic & Consumables)

| # | Item | Cost | Qty | Effect | Wanderer | Cleric | Magician | Warrior | Barbarian |
|---|------|------|-----|--------|----------|--------|----------|---------|-----------|
| 17 | Necronomicon | 20 | 4 | Grants spells 1–3 (SMITE, WARD, TRANSPORT). Each spell receives AURA charges. | ✓ | ✓ | ✓ | ✗ | ✗ |
| 18 | Scrolls | 15 | 3 | Grants spells 4–6 (MEND, CHAOS, RENEWAL). Each spell receives AURA charges. | ✗ | ✗ | ✓ | ✗ | ✗ |
| 19 | Ring | 14 | 2 | No mechanical effect (flavour item). | ✓ | ✓ | ✓ | ✗ | ✗ |
| 20 | Mystic Amulet | 12 | 2 | No mechanical effect (flavour item). | ✓ | ✗ | ✓ | ✗ | ✗ |
| 21 | Sash | 10 | 3 | No mechanical effect (flavour item). | ✓ | ✓ | ✓ | ✗ | ✗ |
| 22 | Cloak | 8 | 1 | No mechanical effect (flavour item). | ✓ | ✓ | ✓ | ✗ | ✗ |
| 23 | Healing Salve | 6 | 1 | Restores VIT to peak when quaffed (`Q`). Can be bought multiple times. | ✓ | ✓ | ✓ | ✓ | ✓ |
| 24 | Potions | 6 | 1 | Restores STR to peak when quaffed (`Q`). Can be bought multiple times. | ✓ | ✓ | ✓ | ✓ | ✓ |

> **Qty** is the number of units one purchase provides. For weapons and armour this value doubles as the stat bonus (a 2 Hand Sword gives 5 quantity points which all add to ATT). For consumables it is the number of uses gained.

---

## DOOM.BAS — The Game

Loads the level and hero files and saves progress. Run this to play.

### Saving and resuming

Press `S` during play. The current map state and hero are written to `B:/DOOM/SAVE/`, then the game stops.

On the next run, DOOM.BAS offers **Resume** or **New**.

The original level files in `B:/DOOM/` are never overwritten — the game reads a saved level if one exists and falls back to the original otherwise. Starting a new hero gives a fresh dungeon without re-running DUNGEN.BAS.

### Options menu

When starting a **new** game (not resuming), an options screen appears before play begins. Press the indicated key to cycle each setting, then press **Enter** to start.

| Key | Option | Values |
|-----|--------|--------|
| `E` | **Experience gate** | OFF (default) / ON — when ON, you must earn enough experience (one point per level) before the stairs will let you descend. |
| `S` | **Monster speed** | 1 (slow) / 2 (normal, default) / 3 (fast) — scales how quickly monsters close in on you. |

Chosen options are saved with your hero, so they persist across save/resume cycles.

---

## Playing the Game

The game runs in real time — one tick is 120 ms. Monsters move every tick whether you act or not. Tarry not.

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

Whenever STR is below its peak it recovers slowly, at a rate set by your VIT — the hardier the hero, the faster the wind returns. Stand still a moment and watch it climb. A potion (`Q`) restores STR to its peak at once.

The STR figure in the panel is rounded to the nearest whole point, so small wear and recovery won't show until it amounts to something.

If STR ever falls below one the hero dies, whether by blows or by sheer exhaustion. Keep a potion for the long fights.

### Visibility

Your hero automatically lights the 3×3 area around them every tick — any square you walk next to becomes permanently visible. Pressing `R` (or the LIGHT prayer) lights a wider 7×7 area at a cost. Squares you have never lit remain pitch black on the map. Revealing a square may also wake a monster sleeping on it.

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

Walking onto the stair tile (`>`) descends automatically (only triggers the first time you step on it; standing still does not repeatedly descend). If no deeper level file exists, the game says "THIS IS THE DEEPEST LEVEL" and you stay put.

### Monsters

There are three monster tiers. Only **one monster can be active** at a time — the game tracks a single pursuer. If a second monster is lit while the first is still alive, it sits dormant until the active one is slain.

| Tile | Tier | Hit Points | Speed | Strength |
|------|------|-----------|-------|----------|
| `a` | Weakest | 54 | Slow | 9 |
| `b` | Medium | 72 | Medium | 10 |
| `c` | Worst | 90 | Fast | 11 |

- **Aggro:** A monster activates the moment you light the square it occupies (by walking adjacent or using Reveal). Once active it moves toward you every tick at its speed rate.
- **Movement:** Monsters close one full square per accumulated fractional steps. They path directly toward you, blocked only by walls and other non-floor tiles.
- **Adjacent attacks:** When a monster is within one square of you (and you are not standing on a magic circle), it automatically attempts to hit you each tick.

A trap (`^`) snares you in place while your exertion drains STR. Only once STR has worn below 80% of its peak can a roll of your LUCK spring you free — a trap is always a costly detour.

Traps are **hidden** until you step on one, at which point it becomes permanently visible on the map. Heroes with high Intelligence (INT > 6) can sense all traps and always see them.

### Combat

Press `A` to attack the active monster. You can attack from any facing — only grabbing and the CHAOS spell require you to face the target.

#### Your attack

1. **Damage roll:** ATT + 1d(Luck). ATT = STR + all weapon bonuses.
2. **Hit check:** If your AGI + Luck < 1d(monster strength) + 2, the blow misses and deals zero damage.
3. **On hit:** Monster HP is reduced by the damage roll. You lose a tiny bit of STR (damage / 100) from the effort, and gain +0.05 EXP.
4. **Kill:** When monster HP drops below 1, it dies and you gain +0.1 EXP.

#### Monster attack (automatic each tick when adjacent)

1. **Dodge check:** If (monster strength × 0.5) × 12 < your Luck + Agility, the monster's blow fails to connect and nothing happens.
2. **Damage dealt:** Raw damage = monster strength × 0.5, divided by (3 + sum of all armour bonuses). The result is subtracted from STR. A fraction of the damage (÷ 101) also chips away at VIT.
3. **Equipment break:** The monster rolls 1d(strength). On a roll of 1, one of your equipment items (weapons and armour, slots 1–11) is permanently destroyed. The first non-zero item found is smashed.
4. **Magic circle immunity:** If you are standing on a magic circle tile (`O`), the monster cannot harm you at all — no damage, no equipment break.

#### Killing monsters for EXP

| Source | EXP gained |
|--------|-----------|
| Landing a hit (even if monster survives) | +0.05 |
| Killing a monster | +0.1 |
| Casting any spell | +0.2 |
| Grabbing the Lost Idol | quest ends |

> **Note:** Picking up treasure does **not** grant EXP during play — it only contributes to your final score.

### Picking things up

Press `G` (or `↓`) to grab what is one square ahead of you.

| Tile | What you get |
|------|-------------|
| `!` Flask | One salve and one potion |
| `$` Treasure | One treasure piece (adds to TRSR and score) |
| `&` Lost Idol | Quest complete — victory screen shown |

### Potions and salves

Press `Q` to quaff. The game uses a potion first if STR is below its peak, otherwise uses a salve if VIT is below its peak.

- **Potion** — restores STR to its peak value
- **Salve** — restores VIT to its peak value

### Lamp and darkness

Press `R` to reveal — lights the 7×7 area around you, costing one lamp oil charge. Without oil, the message "NO LIGHT" is shown. Squares already visited stay visible without spending oil.

### Spells

Press `C` to open the spell menu. Requires AURA above zero and at least one spellbook or scroll set carried.

- The **Necronomicon** grants spells 1–3.
- The **Scrolls** grant spells 4–6.

**Spell charges at game start:** Each of the three spells from a book receives charges equal to your AURA stat. For example, AURA 5 with the Necronomicon gives 5 charges of SMITE, 5 of WARD, and 5 of TRANSPORT.

| # | Name | Effect |
|---|------|--------|
| 1 | SMITE | Instantly slays the active monster, wherever it is |
| 2 | WARD | Lays a magic circle (`O`) beneath your feet (only on empty floor) |
| 3 | TRANSPORT | Teleports you to a random square — **dangerous**, you may land on a wall, trap, or monster |
| 4 | MEND | Heals STR and VIT by a small random amount (1d remaining charges). Costs 1 AURA. |
| 5 | CHAOS | Randomly remakes the tile directly ahead — can clear a monster, wall, or obstacle. Cycles through several random tiles then leaves empty floor. |
| 6 | RENEWAL | Fully restores STR and VIT to peak values. Costs 1 AURA. |

Each spell costs one charge. Casting with no charges left wastes the action. **Every successful cast also grants +0.2 EXP.**

Press `0` to cancel the spell menu without casting.

### Prayers (Cleric only)

Press `P` to open the prayer menu. Only heroes with the **Cleric** class can pray. Prayers have a limited number of charges (based on AURA + 2 at character creation), similar to spells.

| # | Name | Effect |
|---|------|--------|
| 1 | LIGHT | Reveals the 7×7 area around you (same as lamp oil reveal, but free of oil) |
| 2 | HEAL | Restores a small amount of STR and VIT (same as the Mend spell) |
| 3 | FORTUNE | Boosts Luck by 3–6 points for 20–30 ticks |

Press `0` to cancel the prayer menu without praying.

The status bar shows `PRY` (total prayer charges remaining) in place of `LGT` for Clerics.

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
| `Q` | Quaff potion or salve |
| `P` | Pray (Cleric only) |
| `R` | Reveal area (costs lamp oil) |
| `S` | Save and stop |
| `?` | Show lore screen |

### Victory and defeat

Grab the Lost Idol (`&`) on the deepest level to complete the quest. Your final score is:

```
(treasure × 10) + (gold × experience) + STR + VIT + Agility
```

If STR reaches zero, your hero expires. The level they fell on is shown on the death screen.

---

## Tips and Strategy

- **Buy heavy armour if you can.** The defence formula divides damage by (3 + armour), so heavy armour (+5) nearly halves incoming damage compared to being unarmoured.
- **Potions are cheap — stock up.** Multiple potion purchases stack. Each one fully restores STR in an emergency.
- **Stand on magic circles during tough fights.** You are completely immune to monster damage while on one, and the WARD spell can create them anywhere.
- **Use SMITE on `c`-tier monsters.** The worst monsters have 90 HP and hit hard — a single spell charge is worth more than the STR you'll lose fighting them.
- **INT > 6 is always useful.** Seeing traps before you step on them saves potions and keeps you moving.
- **Only one monster hunts at a time.** You can avoid waking a second monster by not revealing the square it stands on until the first is dead.
- **Transport is risky.** You may teleport into a wall (stuck bumping) or onto a trap. Use it only when cornered.
- **The Cleric's LIGHT prayer replaces the torch.** Clerics don't need lamp oil — each LIGHT prayer reveals the same 7×7 area for free.
- **Rest to heal.** Standing still costs nothing and STR regenerates at VIT/1100 per tick. Between fights, pause to recover.
