# Frostbite Tribute - AI Coding Instructions

## Project Overview
Frostbite Tribute is a QB64 clone of the classic Atari 2600 game (1983). This is a single-file BASIC game (~3200 lines) that recreates Frostbite Bailey's igloo-building adventure with floating ice blocks, arctic creatures, and temperature mechanics.

**Language**: QB64 (BASIC dialect)  
**Main file**: [frostbite.bas](../frostbite.bas)  
**Binary**: [binaries/frostbite_macos](../binaries/frostbite_macos)

## QB64-Specific Conventions

### Variable Declarations
- `DIM SHARED` for global variables accessible across all procedures
- Type suffixes: `AS LONG`, `AS INTEGER`, `AS SINGLE`, `AS _BYTE`, `AS _BIT`, `AS _UNSIGNED LONG`
- All game state variables declared in "Game variables" section (lines 165-220)

### Constants and Enums
- QB64 uses `CONST` keyword for constants (lines 91-141)
- Emulated enums via grouped constants (e.g., creature types: `BIRD = 1`, `FISH = 2`, `CRAB = 4`, `CLAM = 8`)
- Boolean values: `True = -1`, `False = NOT True`

### Type Definitions
Custom types defined with `TYPE...END TYPE` (lines 143-163):
```vb
TYPE HeroInfo
    CurrentRow AS INTEGER
    X AS INTEGER
    Y AS INTEGER
    Direction AS INTEGER
    Face AS INTEGER
    Action AS INTEGER
    Grabbed AS _BYTE
    Frame AS _BYTE
END TYPE
```

### Sprite System
Sprites are **not loaded from files** - they're generated from pixel data in `DATA` statements:
- Each sprite has palette DATA (e.g., `HeroPalette:`) followed by pixel grid DATA (e.g., `Hero1:`)
- Pixel DATA uses digits mapping to palette indices: `1` = transparent, `2-5` = colors
- `LoadSprite` SUB (line 3114) reads DATA and draws pixels to `_NEWIMAGE` surfaces
- All sprites loaded in `SpritesSetup` (line 3056)

### Sound Handling
Audio files are **embedded as base64-like strings** in the source code:
- `LoadAssets` SUB (line 1507) decodes and writes `.ogg` files to disk
- Files are recreated every run, then loaded with `_SNDOPEN`
- This technique from Dav's QBasic site allows single-file distribution

### Graphics Architecture
- Dual-screen system: `MainScreen` (title/credits) and `GameScreen` (gameplay)
- `_DEST` switches drawing target; `_PUTIMAGE` composites sprites
- Aurora effect: Gradient lines drawn from palette array (lines 3006-3010)
- Day/night cycle: Swaps `SceneryPalette` between two color schemes

## Game Architecture

### Main Loop Structure
Game loop in lines 265-281:
1. `CalculateScores` - Level completion scoring
2. `NewLevelPause` - Delay between levels
3. `ComposeScenery` - Draw background/aurora
4. `DrawIgloo` - Render igloo progress
5. `MoveIceBlocks` - Update ice row positions
6. `MoveCreatures` - Creature movement/animation
7. `MoveHero` - Player physics/animation
8. `CheckLanding` - Collision detection with ice/water
9. `CheckCreatures` - Collision detection with enemies
10. `UpdateScreen` - Flip buffers
11. `ReadKeyboard` - Input handling

### Ice Block System
- 4 horizontal rows of moving ice blocks (`IceRow(1 TO 4)`)
- Each row has `Position`, `MirroredPosition` (wrapping), `Direction`, `State` (stepped on)
- 3 block types: `SINGLEBLOCK`, `DOUBLEBLOCK`, `MOVINGBLOCK`
- Blocks mirror to opposite side when offscreen (wrapping effect)
- Hero moves with blocks when standing on them

### Level Progression
- Level data stored in `Levels()` array, read from `LevelsDATA` section
- Each level defines: `Speed`, `BlockType`, `CreaturesAllowed` (bitfield)
- `SetLevel` SUB (line 1425) initializes rows, creatures, temperature, score
- Igloo building: Collect 16 ice blocks to complete level

### Creature System
- 4 simultaneous creatures max (`Creatures(1 TO 4)`)
- Species determined by bitfield: `BIRD`, `FISH`, `CRAB`, `CLAM`
- Fish are friendly (bonus points); others deadly
- Creatures animate with 2-frame cycles
- `MakeCreature` SUB (line 906) spawns creatures based on level configuration

## Development Workflow

### Building
Requires QB64 compiler (www.qb64.org):
```bash
# Compile for current platform
qb64 frostbite.bas -o binaries/frostbite_macos
```

### Running
```bash
cd binaries
./frostbite_macos
```
Sound files auto-extract to same directory on first run.

### Debug Mode
Set `$LET INTERNALBUILD = TRUE` (line 88) for debug features:
- Frame counter
- Runtime measurement

### Key Code Sections
- **Sprite DATA**: Lines 283-545 (pixel grids)
- **Level DATA**: Search for `LevelsDATA:` label
- **Main loop**: Lines 265-281
- **Hero movement**: `MoveHero` SUB (line 950)
- **Collision detection**: `CheckLanding` (line 1081), `CheckCreatures` (line 1165)

## Common Patterns

### Reading DATA Statements
```vb
RESTORE LabelName
READ variable1, variable2
```
`RESTORE` sets read pointer to label; `READ` sequentially consumes DATA.

### Screen Switching
```vb
_DEST GameScreen  ' Draw to game buffer
_SOURCE MainScreen ' Read from title screen
```

### Timing
- `_DELAY .03` in main loop (30ms ≈ 33 FPS)
- `TIMER` for time-based events (temperature decrease, level pause)

## Important Notes
- **Single-file architecture**: All code, data, sprites, and sounds in one `.bas` file
- **No external assets required**: Everything self-contained for distribution
- **BASIC label-based GOTOs**: Avoided in favor of structured SUBs/FUNCTIONs
- **QB64 modernisms**: Uses `_RGB32`, `_NEWIMAGE`, `_SNDOPEN` (not standard BASIC)
