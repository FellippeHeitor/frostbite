'Frosbite Tribute
'A clone of Frostbite for the Atari 2600, originally designed
'by Steve Cartwright and published by Activision in 1983.
'
'Fellippe Heitor / @FellippeHeitor / fellippeheitor@gmail.com
'
' - Beta 1: (November 30th, 2015)
'    - Screen layout, with aurora and logo on the bottom.
'    - Ripped hero sprites from youtube gameplays.
'    - Can move around, jump up and down. Still walks on
'      water, though.
'
' - Beta 2: (December 1st, 2015)
'    - Primitive ice blocks are around, and our hero moves
'      along with them.
'    - Blocks are mirrored on the other side when they go
'      offscreen. However, until they are reset on screen,
'      the mirrored blocks aren't "seen" by the code, yet.
'    - Very basic detection of landing safely, to see if
'      the hero will drown.
'    - Drowning/losing lives.
'    - Scores for ice blocks the hero steps on.
'
' - Beta 3: (December 2nd, 2015)
'    - Ripped audio effects. Not required for gameplay, though.
'    - Added a .MirroredPosition variable to IceRows, which
'      now allows the hero to step on any ice block he sees
'      fit.
'    - When temperature reaches 0 degrees, hero loses a life by
'      freezing to death.
'    - Moved drawing routines to subprocedures, to make reading
'      easier.
'
' - Beta 4: (December 3rd 2015)
'    - More code beautification.
'    - Spritesheet no longer necessary; sprites are now created
'      on the fly with pixel data READ from DATA statements
'      (I decided to do so after seeing some code from TrialAndTerror).
'    - WE NOW HAVE AN IGLOO!! With every ice block the Hero steps on
'      a new block is placed on his brand new igloo. After the igloo
'      is finished (that's when the door is placed = 16 ice blocks)
'      the Hero must enter the igloo to end the level.
'    - You can use SPACEBAR to change ice blocks direction, however
'      that'll cost you a piece of your igloo.
'    - Upon entering the igloo, the level is complete. Scores are then
'      calculated. New sound effects are used for that.
'
' - Beta 5: (December 8th, 2015)
'    - Fixed: Temperature timer wasn't reset after setting a new level.
'    - Added: Different block types: DOUBLEBLOCK and MOVINGBLOCK, which can
'      be seen from level 2 onward.
'    - Improved aurora simulation, to better mimick the original game.
'    - Ice blocks now look more like in the original game.
'    - Creatures (fish, birds, crabs and clams) came to life and the
'      hero must now avoid them, except for fish. Fish are good.
'

$RESIZE:SMOOTH

$LET INTERNALBUILD = FALSE

'Game constants: --------------------------------------------------------------
CONST True = -1
CONST False = NOT True

'Block types
CONST SINGLEBLOCK = 1
CONST DOUBLEBLOCK = 2
CONST MOVINGBLOCK = 3

'Directions
CONST MOVINGLEFT = -1
CONST MOVINGRIGHT = 1
CONST STOPPED = 0

'Actions
CONST WALKING = 1
CONST JUMPINGUP = 2
CONST JUMPINGDOWN = 3
CONST FREEZING = 4
CONST DROWNING = 5
CONST ENTERINGIGLOO = 6
CONST EATINGFISH = 7

'Light conditions
CONST DAY = 1
CONST NIGHT = 2

'Creatures
CONST BIRD = 1
CONST FISH = 2
CONST CRAB = 4
CONST CLAM = 8

'Misc:
CONST GAMESTART = -1
CONST NEXTLEVEL = 0

CONST FIRST = 48
CONST SECOND = 12
CONST THIRD = 3

CONST HeroStartRow = 95
CONST HeroHeight = 36
CONST HeroWidth = 30
CONST DoorX = 276
CONST MaxSpaceBetween = 15

CONST InitialTemperature = 45

CONST UnsteppedBlockColor = _RGB32(208, 208, 208)
CONST SteppedBlockColor = _RGB32(73, 134, 213)
CONST IglooBlockColor = _RGB32(136, 136, 136)

'Type definitions: ------------------------------------------------------------
TYPE RowInfo
    Position AS INTEGER
    MirroredPosition AS INTEGER
    Direction AS INTEGER
    State AS _BYTE ' True when row has been stepped on
END TYPE

TYPE CreaturesInfo
    Species AS INTEGER
    X AS INTEGER
    Y AS SINGLE
    Direction AS INTEGER
    Number AS INTEGER
    Spacing AS INTEGER
    RowWidth AS INTEGER
    State AS _BYTE 'Indicates fish in row (11) or fish eaten (00) as in &B110011 = fish, no fish, fish
    Frame AS _BYTE
END TYPE

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

TYPE LevelInfo
    Speed AS SINGLE
    BlockType AS _BYTE
    TimeOfDay AS _BYTE
    CreaturesAllowed AS _BYTE
END TYPE

'Game variables: --------------------------------------------------------------
DIM SHARED AnimationStep AS INTEGER
DIM SHARED Aurora(1 TO 7) AS LONG
DIM SHARED AuroraH AS INTEGER
DIM SHARED IceRows(1 TO 4) AS INTEGER
DIM SHARED Creatures(1 TO 4) AS CreaturesInfo
DIM SHARED CreatureSprite AS LONG
DIM SHARED CreatureWidth(1 TO 8) AS INTEGER
DIM SHARED CreditsBarH AS INTEGER
DIM SHARED CreditsIMG AS LONG, CreditY AS INTEGER
DIM SHARED FishPoints AS INTEGER
DIM SHARED FishSprites(1 TO 2) AS LONG
DIM SHARED FramesTimer AS INTEGER
DIM SHARED GameOver AS _BIT
DIM SHARED GameScreen AS LONG
DIM SHARED GroundH AS INTEGER
DIM SHARED Hero AS HeroInfo
DIM SHARED HeroFreezingSprite AS LONG
DIM SHARED HeroSprites(1 TO 4) AS LONG
DIM SHARED BirdSprites(1 TO 2) AS LONG
DIM SHARED IceRow(1 TO 4) AS RowInfo
DIM SHARED IglooPieces AS INTEGER
DIM SHARED InGame AS _BYTE
DIM SHARED JustLanded AS _BIT
DIM SHARED LevelComplete AS _BIT
DIM SHARED Lives AS INTEGER
DIM SHARED LoopLimit AS INTEGER
DIM SHARED MainScreen AS LONG
DIM SHARED MaxLevelCreatures AS INTEGER
DIM SHARED NewLevelSet AS SINGLE
DIM SHARED RestoreRowsTimer AS SINGLE
DIM SHARED RowWidth AS SINGLE
DIM SHARED Safe AS SINGLE
DIM SHARED Score AS LONG
DIM SHARED SkyH AS INTEGER
DIM SHARED SpaceBetween AS SINGLE
DIM SHARED Temperature AS INTEGER
DIM SHARED TempTimer AS INTEGER
DIM SHARED ThisAurora AS LONG
DIM SHARED ThisLevel AS INTEGER
DIM SHARED ThisRowColor AS LONG
DIM SHARED UserWantsToQuit AS _BYTE
DIM SHARED WaterH AS INTEGER

REDIM SHARED Levels(0) AS LevelInfo
REDIM SHARED ThisLevelCreatures(0) AS INTEGER

DIM i AS LONG

'Variables to hold sounds:
DIM SHARED JumpSound AS LONG
DIM SHARED BlockSound AS LONG
DIM SHARED DrowningSound AS LONG
DIM SHARED IglooBlockCountSound AS LONG
DIM SHARED ScoreCountSound AS LONG
DIM SHARED CollectFishSound AS LONG

'For testing/debugging purposes
$IF INTERNALBUILD = TRUE THEN
    DIM SHARED Frames AS _UNSIGNED LONG
    DIM SHARED RunStart AS DOUBLE
    RunStart = TIMER
$END IF

'Game setup: ------------------------------------------------------------------
RestoreData
ScreenSetup
LoadAssets
SpritesSetup
SetTimers
SetLevel GAMESTART
NewLevelSet = 0
LoopLimit = 24

'Main game loop: --------------------------------------------------------------
DO: _LIMIT LoopLimit 'Default = 24
    IF LevelComplete THEN
        CalculateScores
    END IF

    NewLevelPause
    DrawScenery
    DrawIgloo
    MoveIceBlocks
    MoveCreatures
    MoveHero
    CheckLanding
    CheckCreatures

    UpdateScreen

    IF LevelComplete AND IglooPieces > 0 THEN _DELAY .107
    IF LevelComplete AND IglooPieces = 0 AND Temperature > 0 THEN _DELAY .05

    ReadKeyboard
LOOP UNTIL UserWantsToQuit
SYSTEM

'Game data: -------------------------------------------------------------------
AuroraColors:
DATA 207,199,87
DATA 208,161,62
DATA 199,141,54
DATA 210,95,110
DATA 183,101,193
DATA 157,111,224
DATA 120,116,237

IceRowsDATA:
DATA 134,173,212,251

CreaturesDATA:
DATA 30,30,30,30

LevelsDATA:
DATA 4
DATA 1,1,1,1
DATA 1,2,1,3
DATA 1,3,2,7
DATA 1.5,3,2,15

HeroPalette:
'Total colors, color values (_UNSIGNED LONG)
DATA 5,0,4289225241,4291259443,4287072135,4288845861

Hero1:
DATA 111111111111111111111111111111
DATA 111111111111111111111111111111
DATA 111122222222222111111111111111
DATA 111122222222222111111111111111
DATA 111122222222222222211111111111
DATA 111122222222222222211111111111
DATA 222222222222222222211111111111
DATA 222222222222222222211111111111
DATA 222222222222222222222222221111
DATA 222222222222222222222222221111
DATA 222222222222222222222222221111
DATA 222222222222222222222222221111
DATA 222222222222222222222222221111
DATA 111133333333333333333311111111
DATA 111133333333333333333311111111
DATA 111133333333333333333333331111
DATA 111133333333333333333333331111
DATA 111111113333333333333311111111
DATA 111111113333333333333311111111
DATA 111144444444444444444411111111
DATA 111144444444444444444411111111
DATA 111144411114444444444444441111
DATA 111144411114444444444444441111
DATA 111144411114444444444444441111
DATA 111144411111111444444444441111
DATA 111144444441111444444444441111
DATA 111144444441111111144444441111
DATA 111144444444444111144444441111
DATA 111144444444444111144444441111
DATA 111144444444444444444444441111
DATA 111111115555555111155555551111
DATA 111111115555555111155555551111
DATA 111111115555555111155555551111
DATA 111111115555555111155555551111
DATA 555555555555555555555555555555
DATA 555555555555555555555555555555

Hero2:
DATA 111122222222222111111111111111
DATA 111122222222222111111111111111
DATA 111122222222222222111111111111
DATA 111122222222222222111111111111
DATA 222222222222222222111111111111
DATA 222222222222222222111111111111
DATA 222222222222222222222222221111
DATA 222222222222222222222222221111
DATA 222222222222222222222222221111
DATA 222222222222222222222222221111
DATA 222222222222222222222222221111
DATA 111133333333333333333311111111
DATA 111133333333333333333311111111
DATA 111133333333333333333333331111
DATA 111133333333333333333333331111
DATA 111111133333333333333311111111
DATA 111111133333333333333311111111
DATA 111144444444444444444411111111
DATA 111144444444444444444411111111
DATA 111144411114444444444444441111
DATA 111144411114444444444444441111
DATA 111144411111111444444444441111
DATA 111144411111111444444444441111
DATA 111144444444441111444444441111
DATA 111144444444441111444444441111
DATA 111144444444444444444444441111
DATA 111144444444444444444444441111
DATA 111144444444444444444444441111
DATA 111111111115555555555511111111
DATA 111111111115555555555511111111
DATA 111111111115555555555511111111
DATA 111111111115555555555511111111
DATA 111111111115555555555511111111
DATA 111111111115555555555511111111
DATA 555555555555555555555555555555
DATA 555555555555555555555555555555

Hero3:
DATA 111112222222222211111111111111
DATA 111112222222222211111111111111
DATA 111112222222222222221111111111
DATA 111112222222222222221111111111
DATA 122222222222222222221111111111
DATA 122222222222222222221111111111
DATA 122222222222222222222222222111
DATA 122222222222222222222222222111
DATA 122222222222222222222222222111
DATA 122222222222222222222222222111
DATA 133333333333333333333333333111
DATA 133333333333333333333333333111
DATA 111113333333333333333333333111
DATA 111113333333333333333333111111
DATA 111111113333333333333333111111
DATA 111114444444444444444444111111
DATA 111114444444444444444444111111
DATA 111114444111444444444444444411
DATA 111114444111444444444444444411
DATA 111114444111111111111111444411
DATA 111114444111111111111111444411
DATA 111114444444444444444444444411
DATA 111114444444444444444444444411
DATA 111114444444444444444444444411
DATA 111114444444444444444444444411
DATA 111111111111555551115555111111
DATA 111115555555555555555555555511
DATA 111115555555555555555555555511
DATA 111115555555555555555555555511
DATA 111111111111111111111111111111
DATA 111111111111111111111111111111
DATA 111111111111111111111111111111
DATA 111111111111111111111111111111
DATA 111111111111111111111111111111
DATA 111111111111111111111111111111
DATA 111111111111111111111111111111

Hero4:
DATA 111111111111111111111111111111
DATA 111111111111111111111111111111
DATA 111111111111222222111111111111
DATA 111111111222222222222111111111
DATA 111111111222222222222111111111
DATA 111111111222222222222111111111
DATA 111111111222222222222111111111
DATA 111111111222222222222111111111
DATA 111222222222222222222222221111
DATA 111222222222222222222222221111
DATA 111222222222222222222222221111
DATA 111222222222222222222222221111
DATA 111222222222222222222222221111
DATA 111111333333333333333331111111
DATA 111111333333333333333331111111
DATA 111111333333333333333331111111
DATA 111111333333333333333331111111
DATA 111111333333111113333331111111
DATA 111111333333111113333331111111
DATA 111111333333333333333334441111
DATA 111111111444444444444114441111
DATA 111114444444444444444114441111
DATA 111444444444111444444114441111
DATA 111444444444111444444444441111
DATA 111444444444444444444444441111
DATA 111444444444444444444444441111
DATA 111444111444444444444444441111
DATA 111444111444111444444441111111
DATA 111444111444111444444441111111
DATA 111444111444444444444441111111
DATA 111111111555555555555111111111
DATA 111111111555555555555111111111
DATA 111111111555555555555111111111
DATA 111111111555111115555111111111
DATA 111555555555555555555555551111
DATA 111555555555555555555555551111

BirdPalette:
DATA 2,0,4286877948

Bird1:
DATA 111111111111111111111111111111
DATA 111111111111111111111122211111
DATA 111111111111111111111122211111
DATA 111111111111111111222222222211
DATA 111111111111111111222222222211
DATA 122222222222222222222211111111
DATA 122222222222222222222211111111
DATA 111122222222222222111111111111
DATA 111111122222222222111111111111
DATA 111111122222221111111111111111
DATA 111122222222221111111111111111
DATA 111122222221111111111111111111
DATA 122222222221111111111111111111
DATA 122222221111111111111111111111
DATA 122222221111111111111111111111

Bird2:
DATA 111111111111111111111111111111
DATA 122222222222111111112222111111
DATA 122222222222111111112222111111
DATA 111111111222222211112222222211
DATA 111111111222222211112222222211
DATA 111111111222222211112222222211
DATA 122222222222222222222222111111
DATA 122222222222222222222222111111
DATA 111112222222222222221111111111
DATA 111112222222222222221111111111
DATA 111112222222222222221111111111
DATA 111111111222222211111111111111
DATA 111111111222222211111111111111
DATA 111112222111111111111111111111
DATA 111112222111111111111111111111

FishPalette:
DATA 2,0,4285518447

Fish1:
DATA 111111111111111111111111111111
DATA 111111111111111111111111111111
DATA 122221111122222222221111111111
DATA 122221111122222222221111111111
DATA 122222221111122222222221111111
DATA 122222222222222222222222221111
DATA 111122222222222222221122221111
DATA 111111112222222222222222221111
DATA 111111112222222222222222221111
DATA 111111112222222222222222221111
DATA 111122222222222222222221111111
DATA 122222222222222222222222221111
DATA 122222221111122222222222221111
DATA 122221111122222222221111111111
DATA 122221111122222222221111111111

Fish2:
DATA 111111111111111111111111111111
DATA 111111111111111111111111111111
DATA 111111111111122222111111111111
DATA 111111111111122222111111111111
DATA 222222211122222222222211111111
DATA 222222222222222222222222211111
DATA 222222222222222222111222211111
DATA 111111222222222222222222211111
DATA 111111222222222222222222211111
DATA 111111222222222222222222211111
DATA 222222222222222222222222211111
DATA 222222222222222222222222211111
DATA 222222211122222222222211111111
DATA 111111111111122222111111111111
DATA 111111111111122222111111111111

'------------------------------------------------------------------------------
'Subprocedures start here:
'------------------------------------------------------------------------------
SUB NewLevelPause
IF InGame THEN EXIT SUB
IF NewLevelSet <> 0 THEN
    IF TIMER - NewLevelSet > 1 THEN
        InGame = True
        TIMER(TempTimer) ON
        NewLevelSet = 0
    END IF
END IF
END SUB

'------------------------------------------------------------------------------
SUB DrawScenery
STATIC TemperatureBlink AS INTEGER

LINE (0, 0)-STEP(_WIDTH, GroundH), _RGB32(192, 192, 192), BF '                    Ground/ice
LINE (0, 0)-STEP(_WIDTH, SkyH), _RGB32(37, 54, 189), BF '                         Sky
LINE (0, GroundH - 2)-STEP(_WIDTH, 3), _RGB32(0, 0, 0), BF '                      Black separator
LINE (0, GroundH + 2)-STEP(_WIDTH, WaterH), _RGB32(0, 27, 141), BF '              Water
_PUTIMAGE (0, SkyH - AuroraH / 2), ThisAurora, GameScreen '                       Aurora
LINE (0, _HEIGHT - CreditsBarH)-STEP(_WIDTH, CreditsBarH), _RGB32(0, 0, 0), BF '  Credits bar
_PUTIMAGE (0, _HEIGHT - CreditsBarH), CreditsIMG, GameScreen, (0, CreditY)-STEP(_WIDTH(CreditsIMG), CreditsBarH)

COLOR _RGB32(126, 148, 254), _RGBA32(0, 0, 0, 0)
_PRINTSTRING (72 - (LEN(TRIM$(Score)) * _FONTWIDTH), 2), TRIM$(Score)
SELECT CASE Temperature
    CASE 1 TO 5
        TemperatureBlink = TemperatureBlink + 1
        SELECT CASE TemperatureBlink
            CASE 7 TO 14
                IF NOT LevelComplete AND NOT GameOver THEN
                    COLOR _RGBA32(0, 0, 0, 0), _RGBA32(0, 0, 0, 0)
                END IF
            CASE 15
                TemperatureBlink = 0
        END SELECT
    CASE ELSE
        TemperatureBlink = 0
END SELECT
_PRINTSTRING (40 - (LEN(TRIM$(Temperature)) * _FONTWIDTH), 14), TRIM$(Temperature) + CHR$(248)
IF Lives > 0 THEN _PRINTSTRING (72 - (LEN(TRIM$(Lives)) * _FONTWIDTH), 14), TRIM$(Lives)


$IF INTERNALBUILD = TRUE THEN
    'Variable watch on screen, for debugging purposes:
    COLOR _RGB32(0, 0, 0), _RGBA32(255, 255, 255, 200)
    i = 0
    crd$ = "Frames=" + TRIM$(Frames) + " FPS=" + TRIM$(_CEIL(Frames / (TIMER - RunStart))): _PRINTSTRING (_WIDTH - (LEN(crd$) * _FONTWIDTH), i), crd$

    i = i + 8
    crd$ = "Hero.X=" + TRIM$(Hero.X): _PRINTSTRING (_WIDTH - (LEN(crd$) * _FONTWIDTH), i), crd$

    i = i + 8
    crd$ = "Hero.CurrentRow=" + TRIM$(Hero.CurrentRow): _PRINTSTRING (_WIDTH - (LEN(crd$) * _FONTWIDTH), i), crd$

    FOR j = 1 TO 4
    i = i + 8
    crd$ = "Creatures(" + TRIM$(j) + ").species=" + TRIM$(Creatures(j).Species): _PRINTSTRING (_WIDTH - (LEN(crd$) * _FONTWIDTH), i), crd$
    NEXT j
$END IF

END SUB

'------------------------------------------------------------------------------
SUB DrawIgloo
STATIC IglooBlink AS _BIT
DIM IglooDoorColor AS _UNSIGNED LONG

IF IglooPieces = 0 THEN EXIT SUB

SELECT EVERYCASE IglooPieces
    CASE IS > 0
        LINE (232, 57)-STEP(32, -9), IglooBlockColor, BF
    CASE IS > 1
        LINE (264, 57)-STEP(32, -9), IglooBlockColor, BF
    CASE IS > 2
        LINE (296, 57)-STEP(32, -9), IglooBlockColor, BF
    CASE IS > 3
        LINE (328, 57)-STEP(32, -9), IglooBlockColor, BF
    CASE IS > 4
        LINE (328, 48)-STEP(32, -9), IglooBlockColor, BF
    CASE IS > 5
        LINE (296, 48)-STEP(32, -9), IglooBlockColor, BF
    CASE IS > 6
        LINE (264, 48)-STEP(32, -9), IglooBlockColor, BF
    CASE IS > 7
        LINE (232, 48)-STEP(32, -9), IglooBlockColor, BF
    CASE IS > 8
        LINE (232, 39)-STEP(32, -9), IglooBlockColor, BF
    CASE IS > 9
        LINE (264, 39)-STEP(32, -9), IglooBlockColor, BF
    CASE IS > 10
        LINE (296, 39)-STEP(32, -9), IglooBlockColor, BF
    CASE IS > 11
        LINE (328, 39)-STEP(32, -9), IglooBlockColor, BF
    CASE IS > 12
        LINE (248, 31)-STEP(49, -9), IglooBlockColor, BF
    CASE IS > 13
        LINE (297, 31)-STEP(49, -9), IglooBlockColor, BF
    CASE IS > 14
        LINE (265, 25)-STEP(65, -9), IglooBlockColor, BF
    CASE IS > 15
        IglooDoorColor = _RGB32(0, 0, 0)
        IF Levels(ThisLevel).TimeOfDay = NIGHT THEN
            IF IglooBlink THEN
                IglooBlink = False
                IglooDoorColor = _RGB32(217, 134, 69)
            ELSE
                IglooBlink = True
            END IF
        END IF
        LINE (276, 57)-STEP(35, -16), _RGB32(0, 0, 0), BF
        LINE (281, 43)-STEP(25, -5), _RGB32(0, 0, 0), BF
END SELECT
END SUB

'------------------------------------------------------------------------------
SUB MoveIceBlocks
DIM i AS INTEGER
DIM j AS INTEGER
DIM x AS INTEGER
DIM x.m AS INTEGER
DIM BlockLines AS INTEGER

'Ice blocks:
FOR i = 1 TO 4
    IF NOT IceRow(i).State THEN ThisRowColor = UnsteppedBlockColor ELSE ThisRowColor = SteppedBlockColor

    IF InGame AND Hero.Action <> DROWNING AND Hero.Action <> FREEZING AND Hero.Action <> EATINGFISH AND NOT LevelComplete THEN
        IceRow(i).Position = IceRow(i).Position + Levels(ThisLevel).Speed * IceRow(i).Direction
        IF IceRow(i).Direction = MOVINGRIGHT THEN
            IF IceRow(i).Position >= _WIDTH(GameScreen) THEN
                IceRow(i).Position = 0
                IceRow(i).MirroredPosition = 0
            END IF
        END IF
        IF IceRow(i).Direction = MOVINGLEFT THEN
            IF IceRow(i).Position < -RowWidth THEN
                IceRow(i).Position = _WIDTH(GameScreen) - 1 - RowWidth
                IceRow(i).MirroredPosition = 0
            END IF
        END IF
    END IF

    x = IceRow(i).Position

    SELECT CASE Levels(ThisLevel).BlockType
        CASE SINGLEBLOCK
            'Draw normal blocks
            FOR j = -8 TO 8
                BlockLines = j + _CEIL(RND(j) * 6)
                LINE (x + BlockLines, IceRows(i) - j)-STEP(HeroWidth * 2, 0), ThisRowColor
                LINE (x + BlockLines + HeroWidth * 3.5, IceRows(i) - j)-STEP(HeroWidth * 2, 0), ThisRowColor
                LINE (x + BlockLines + HeroWidth * 7, IceRows(i) - j)-STEP(HeroWidth * 2, 0), ThisRowColor
            NEXT j

            IF IceRow(i).Direction = MOVINGLEFT THEN
                IF IceRow(i).Position < 0 THEN
                    IceRow(i).MirroredPosition = _WIDTH(GameScreen) + IceRow(i).Position
                END IF
            ELSE
                IF IceRow(i).Position + HeroWidth * 7 + HeroWidth * 2 > _WIDTH(GameScreen) THEN
                    IceRow(i).MirroredPosition = -_WIDTH(GameScreen) + IceRow(i).Position
                END IF
            END IF

            'Draw mirrored blocks
            IF IceRow(i).MirroredPosition THEN
                x = IceRow(i).MirroredPosition
                FOR j = -8 TO 8
                    BlockLines = j + _CEIL(RND(j) * 6)
                    LINE (x + BlockLines, IceRows(i) - j)-STEP(HeroWidth * 2, 0), ThisRowColor
                    LINE (x + BlockLines + HeroWidth * 3.5, IceRows(i) - j)-STEP(HeroWidth * 2, 0), ThisRowColor
                    LINE (x + BlockLines + HeroWidth * 7, IceRows(i) - j)-STEP(HeroWidth * 2, 0), ThisRowColor
                NEXT j
            END IF
        CASE DOUBLEBLOCK
            'Draw normal blocks
            FOR j = -8 TO 8
                BlockLines = j + _CEIL(RND(j) * 6)
                LINE (x + BlockLines, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
                LINE (x + BlockLines + HeroWidth * 1.5, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
                LINE (x + BlockLines + HeroWidth * 3, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
                LINE (x + BlockLines + HeroWidth * 4.5, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
                LINE (x + BlockLines + HeroWidth * 6, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
                LINE (x + BlockLines + HeroWidth * 7.5, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
            NEXT j

            IF IceRow(i).Direction = MOVINGLEFT THEN
                IF IceRow(i).Position < 0 THEN
                    IceRow(i).MirroredPosition = _WIDTH(GameScreen) + IceRow(i).Position
                END IF
            ELSE
                IF IceRow(i).Position + HeroWidth * 7 + HeroWidth * 2 > _WIDTH(GameScreen) THEN
                    IceRow(i).MirroredPosition = -_WIDTH(GameScreen) + IceRow(i).Position
                END IF
            END IF

            'Draw mirrored blocks
            IF IceRow(i).MirroredPosition THEN
                x = IceRow(i).MirroredPosition
                FOR j = -8 TO 8
                    BlockLines = j + _CEIL(RND(j) * 6)
                    LINE (x + BlockLines, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
                    LINE (x + BlockLines + HeroWidth * 1.5, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
                    LINE (x + BlockLines + HeroWidth * 3, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
                    LINE (x + BlockLines + HeroWidth * 4.5, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
                    LINE (x + BlockLines + HeroWidth * 6, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
                    LINE (x + BlockLines + HeroWidth * 7.5, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
                NEXT j
            END IF
        CASE MOVINGBLOCK
            'Draw normal blocks
            FOR j = -8 TO 8
                BlockLines = j + _CEIL(RND(j) * 6)
                LINE (x + BlockLines + SpaceBetween, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
                LINE (x + BlockLines + HeroWidth * 1.5 - SpaceBetween, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
                LINE (x + BlockLines + HeroWidth * 3 + SpaceBetween, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
                LINE (x + BlockLines + HeroWidth * 4.5 - SpaceBetween, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
                LINE (x + BlockLines + HeroWidth * 6 + SpaceBetween, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
                LINE (x + BlockLines + HeroWidth * 7.5 - SpaceBetween, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
            NEXT j

            IF IceRow(i).Direction = MOVINGLEFT THEN
                IF IceRow(i).Position < 0 THEN
                    IceRow(i).MirroredPosition = _WIDTH(GameScreen) + IceRow(i).Position
                END IF
            ELSE
                IF IceRow(i).Position + HeroWidth * 7 + HeroWidth * 2 > _WIDTH(GameScreen) THEN
                    IceRow(i).MirroredPosition = -_WIDTH(GameScreen) + IceRow(i).Position
                END IF
            END IF

            'Draw mirrored blocks
            IF IceRow(i).MirroredPosition THEN
                x = IceRow(i).MirroredPosition
                FOR j = -8 TO 8
                    BlockLines = j + _CEIL(RND(j) * 6)
                    LINE (x + BlockLines + SpaceBetween, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
                    LINE (x + BlockLines + HeroWidth * 1.5 - SpaceBetween, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
                    LINE (x + BlockLines + HeroWidth * 3 + SpaceBetween, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
                    LINE (x + BlockLines + HeroWidth * 4.5 - SpaceBetween, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
                    LINE (x + BlockLines + HeroWidth * 6 + SpaceBetween, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
                    LINE (x + BlockLines + HeroWidth * 7.5 - SpaceBetween, IceRows(i) - j)-STEP(HeroWidth, 0), ThisRowColor
                NEXT j
            END IF
    END SELECT
NEXT i
END SUB

'------------------------------------------------------------------------------
SUB MoveCreatures
DIM i AS INTEGER
DIM X AS INTEGER
DIM SubmergeOffset AS INTEGER
STATIC Floating AS SINGLE
STATIC FloatStep AS SINGLE

IF NOT InGame THEN EXIT SUB

IF FloatStep = 0 THEN FloatStep = .5

'Four rows of creatures:
FOR i = 1 TO 4
    IF Hero.Action <> DROWNING AND Hero.Action <> FREEZING AND Hero.Action <> EATINGFISH AND NOT LevelComplete THEN
        IF Hero.Grabbed AND i = Hero.CurrentRow THEN
            IF Creatures(i).Direction = MOVINGRIGHT THEN
                IF Creatures(i).X < _WIDTH(GameScreen) - CreatureWidth(Creatures(i).Species) THEN
                    Creatures(i).X = Creatures(i).X + (Levels(ThisLevel).Speed * Creatures(i).Direction) + Creatures(i).Direction
                END IF
            ELSEIF Creatures(i).Direction = MOVINGLEFT THEN
                IF Creatures(i).X > 0 THEN
                    Creatures(i).X = Creatures(i).X + (Levels(ThisLevel).Speed * Creatures(i).Direction) + Creatures(i).Direction
                END IF
            END IF
        ELSE
            Creatures(i).X = Creatures(i).X + (Levels(ThisLevel).Speed * Creatures(i).Direction) + Creatures(i).Direction
        END IF

        Floating = Floating + FloatStep
        IF Floating > HeroHeight / 2 THEN FloatStep = -.5
        IF Floating <= 0 THEN FloatStep = .5

        'Birds fly linearly. Other creatures are in water, and so they float:
        IF Creatures(i).Species <> BIRD THEN Creatures(i).Y = Creatures(i).Y + FloatStep

        'Once the creature row leaves screen, it is reset:
        IF Creatures(i).Direction = MOVINGRIGHT THEN
            IF Creatures(i).X >= _WIDTH(GameScreen) THEN
                Creatures(i).Species = 0
            END IF
        END IF
        IF Creatures(i).Direction = MOVINGLEFT THEN
            IF Creatures(i).X < -Creatures(i).RowWidth THEN
                Creatures(i).Species = 0
            END IF
        END IF
    END IF

    'if a creature has not yet been set (or just been cleared) for this row,
    'we'll generate a new one:
    IF Creatures(i).Species = 0 THEN MakeCreature i

    X = Creatures(i).X

    IF X < -Creatures(i).RowWidth THEN EXIT SUB

    SubmergeOffset = 5
    SELECT CASE Creatures(i).Species
        CASE BIRD: CreatureSprite = BirdSprites(Creatures(i).Frame): SubmergeOffset = 0: text$ = "BIRD"
        CASE FISH: CreatureSprite = FishSprites(Creatures(i).Frame): text$ = "FISH"
        CASE CRAB: CreatureSprite = 0: text$ = "CRAB"
        CASE CLAM: CreatureSprite = 0: text$ = "CLAM"
    END SELECT

    'First creature in row is always drawn at the same position:
    IF Creatures(i).State AND FIRST THEN
        IF CreatureSprite < -1 THEN
            IF Creatures(i).Direction = MOVINGRIGHT THEN
                _PUTIMAGE (X, Creatures(i).Y), CreatureSprite, GameScreen
            ELSE
                _PUTIMAGE (X + CreatureWidth(Creatures(i).Species), Creatures(i).Y)-STEP(-CreatureWidth(Creatures(i).Species) - 1, _HEIGHT(CreatureSprite) - 1), CreatureSprite, GameScreen
            END IF
        ELSE
            LINE (X, Creatures(i).Y)-STEP(CreatureWidth(Creatures(i).Species), 8), _RGB32(255, 0, 0), BF
            _PRINTSTRING (X, Creatures(i).Y), text$
        END IF
    END IF

    'Second creature in row (position will be affected by Creatures().Spacing):
    IF Creatures(i).Number > 1 AND (Creatures(i).State AND SECOND) THEN
        IF CreatureSprite < -1 THEN
            IF Creatures(i).Direction = MOVINGRIGHT THEN
                _PUTIMAGE (X + CreatureWidth(Creatures(i).Species) + Creatures(i).Spacing, Creatures(i).Y), CreatureSprite, GameScreen
            ELSE
                _PUTIMAGE (X + CreatureWidth(Creatures(i).Species) + Creatures(i).Spacing + CreatureWidth(Creatures(i).Species), Creatures(i).Y)-STEP(-CreatureWidth(Creatures(i).Species) - 1, _HEIGHT(CreatureSprite) - 1), CreatureSprite, GameScreen
            END IF
        ELSE
            LINE (X + CreatureWidth(Creatures(i).Species) + Creatures(i).Spacing, Creatures(i).Y)-STEP(CreatureWidth(Creatures(i).Species), 8), _RGB32(255, 0, 0), BF
            _PRINTSTRING (X + CreatureWidth(Creatures(i).Species) + Creatures(i).Spacing, Creatures(i).Y), text$
        END IF
    END IF

    'Third creature in row (always at the same spot)
    IF Creatures(i).Number = 3 AND (Creatures(i).State AND THIRD) THEN
        IF CreatureSprite < -1 THEN
            IF Creatures(i).Direction = MOVINGRIGHT THEN
                _PUTIMAGE (X + CreatureWidth(Creatures(i).Species) * 2 + Creatures(i).Spacing * 2, Creatures(i).Y), CreatureSprite, GameScreen
            ELSE
                _PUTIMAGE (X + CreatureWidth(Creatures(i).Species) * 2 + Creatures(i).Spacing * 2 + CreatureWidth(Creatures(i).Species), Creatures(i).Y)-STEP(-CreatureWidth(Creatures(i).Species) - 1, _HEIGHT(CreatureSprite) - 1), CreatureSprite, GameScreen
            END IF
        ELSE
            LINE (X + CreatureWidth(Creatures(i).Species) * 2 + Creatures(i).Spacing * 2, Creatures(i).Y)-STEP(CreatureWidth(Creatures(i).Species), 8), _RGB32(255, 0, 0), BF
            _PRINTSTRING (X + CreatureWidth(Creatures(i).Species) * 2 + Creatures(i).Spacing * 2, Creatures(i).Y), text$
        END IF
    END IF
NEXT i
END SUB

'------------------------------------------------------------------------------
SUB MakeCreature (RowNumber)
'Randomly selects a new creature from the current level's array
DIM NewCreature AS INTEGER

RANDOMIZE TIMER
NewCreature = _CEIL(RND * MaxLevelCreatures)
Creatures(RowNumber).Species = ThisLevelCreatures(NewCreature)
DO WHILE Creatures(RowNumber).Direction = 0
    Creatures(RowNumber).Direction = INT(RND * 3) - 1
LOOP
IF ThisLevel <= 2 THEN
    Creatures(RowNumber).Number = ThisLevel
ELSE
    Creatures(RowNumber).Number = _CEIL(RND * 3)
END IF

SELECT CASE Creatures(RowNumber).Number
    CASE 2: Creatures(RowNumber).Spacing = HeroWidth * 2.5
    CASE 3: Creatures(RowNumber).Spacing = HeroWidth * 1
END SELECT

Creatures(RowNumber).RowWidth = (Creatures(RowNumber).Spacing + CreatureWidth(Creatures(RowNumber).Species) * Creatures(RowNumber).Number)

SELECT CASE Creatures(RowNumber).Direction
    CASE MOVINGRIGHT
        Creatures(RowNumber).X = -Creatures(RowNumber).RowWidth - _CEIL(RND * 100)
    CASE MOVINGLEFT
        Creatures(RowNumber).X = _WIDTH(GameScreen) + _CEIL(RND * 100)
END SELECT

IF Creatures(RowNumber).Species = BIRD THEN
    Creatures(RowNumber).Y = IceRows(RowNumber) - HeroHeight + 6
ELSE
    Creatures(RowNumber).Y = IceRows(RowNumber) - HeroHeight + 6
END IF

'Make all creatures in row visible:
Creatures(RowNumber).State = 0 XOR FIRST XOR SECOND XOR THIRD
Creatures(RowNumber).Frame = 1
END SUB

'------------------------------------------------------------------------------
SUB MoveHero
'Hero:
IF InGame THEN

    IF NOT Hero.Grabbed THEN
        Hero.X = Hero.X + Hero.Direction * 3
        IF Hero.CurrentRow > 0 AND (Hero.Action = STOPPED OR Hero.Action = WALKING) THEN
            Hero.X = Hero.X + IceRow(Hero.CurrentRow).Direction * Levels(ThisLevel).Speed
        END IF
    ELSE
        IF (Hero.Action = STOPPED OR Hero.Action = WALKING) AND Hero.Action <> EATINGFISH THEN
            Hero.X = Hero.X + Creatures(Hero.CurrentRow).Direction * Levels(ThisLevel).Speed + Creatures(Hero.CurrentRow).Direction
        END IF
    END IF

    'Hero can't go past a certain point to the left of the screen if WALKING.
    'However, if he jumps from an ice block, he can stand there:
    'IF Hero.CurrentRow = 0 AND Hero.Action = WALKING AND Hero.Direction = MOVINGLEFT THEN
    '    IF Hero.X > HeroWidth + 3 THEN
    '        Hero.X = Hero.X + Hero.Direction * 3
    '    END IF
    'ELSEIF Hero.CurrentRow = 0 AND Hero.Action = WALKING AND Hero.Direction = MOVINGRIGHT THEN
    'ELSEIF Hero.Action = JUMPINGUP OR Hero.Action = JUMPINGDOWN THEN
    'END IF

    SELECT CASE Hero.Action
        CASE JUMPINGUP
            IF Hero.CurrentRow = 0 THEN Hero.Action = WALKING ELSE AnimationStep = AnimationStep + 1
            SELECT CASE AnimationStep
                CASE 1 TO 6
                    Hero.Y = Hero.Y - 8
                    Hero.Frame = 3
                CASE 10 TO 12
                    Hero.Y = Hero.Y + 3
                    Hero.Frame = 1
                CASE 13
                    Hero.CurrentRow = Hero.CurrentRow - 1
                    JustLanded = True
                    Hero.Action = STOPPED: Hero.Direction = Hero.Action
            END SELECT
        CASE JUMPINGDOWN
            IF Hero.CurrentRow = 4 THEN Hero.Action = WALKING ELSE AnimationStep = AnimationStep + 1
            SELECT CASE AnimationStep
                CASE 1 TO 3
                    Hero.Y = Hero.Y - 3
                    Hero.Frame = 3
                CASE 7 TO 12
                    Hero.Y = Hero.Y + 8
                    Hero.Frame = 1
                CASE 13
                    Hero.CurrentRow = Hero.CurrentRow + 1
                    JustLanded = True
                    Hero.Action = STOPPED: Hero.Direction = Hero.Action
            END SELECT
        CASE ENTERINGIGLOO
            AnimationStep = AnimationStep + 1
            SELECT CASE AnimationStep
                CASE 1 TO 6
                    Hero.Y = Hero.Y - 8
                    Hero.Frame = 3
                    _PUTIMAGE (Hero.X, Hero.Y - HeroHeight + AnimationStep)-STEP(HeroWidth, HeroHeight - AnimationStep), HeroSprites(Hero.Frame), GameScreen, (0, 0 + AnimationStep * 6)-(HeroWidth, HeroHeight)
                CASE 20
                    LevelComplete = True
            END SELECT
        CASE DROWNING
            AnimationStep = AnimationStep + 1
            SELECT CASE AnimationStep
                CASE 1 TO 5, 11 TO 15, 21 TO 25, 30 TO 35
                    _PUTIMAGE (Hero.X, Hero.Y - HeroHeight + AnimationStep)-STEP(HeroWidth, HeroHeight - AnimationStep), HeroSprites(Hero.Frame), GameScreen, (0, 0)-(HeroWidth, HeroHeight - AnimationStep)
                CASE 6 TO 10, 16 TO 20, 26 TO 29
                    _PUTIMAGE (Hero.X + HeroWidth, Hero.Y - HeroHeight + AnimationStep)-STEP(-HeroWidth, HeroHeight - AnimationStep), HeroSprites(Hero.Frame), GameScreen, (0, 0)-(HeroWidth, HeroHeight - AnimationStep)
                CASE 36
                    IF Lives = -1 THEN
                        GameOver = True
                        InGame = False
                    ELSE
                        TIMER(TempTimer) ON
                        SetLevel ThisLevel
                    END IF
            END SELECT
        CASE FREEZING
            AnimationStep = AnimationStep + 1
            'Recolor the hero sprite to show it's freezing
            _DEST HeroFreezingSprite
            FOR i = 0 TO _WIDTH(HeroFreezingSprite) - 1
                IF AnimationStep >= _HEIGHT(HeroFreezingSprite) THEN EXIT FOR
                IF POINT(i, AnimationStep) <> _RGBA32(0, 0, 0, 0) THEN
                    PSET (i, AnimationStep), _RGB32(0, 150 - AnimationStep * 3, 219 + AnimationStep)
                END IF
            NEXT i
            _DEST GameScreen
            SELECT CASE AnimationStep
                CASE 1 TO 5, 11 TO 39
                    _PUTIMAGE (Hero.X, Hero.Y - HeroHeight)-STEP(HeroWidth - 1, HeroHeight - 1), HeroFreezingSprite, GameScreen
                CASE 6 TO 10
                    _PUTIMAGE (Hero.X + HeroWidth, Hero.Y - HeroHeight)-STEP(-HeroWidth - 1, HeroHeight - 1), HeroFreezingSprite, GameScreen
                CASE 40
                    _FREEIMAGE HeroFreezingSprite
                    IF Lives = -1 THEN
                        GameOver = True
                        InGame = False
                    ELSE
                        Temperature = InitialTemperature
                        TIMER(TempTimer) ON
                        SetLevel ThisLevel
                    END IF
            END SELECT
        CASE EATINGFISH
            IF FishPoints THEN
                Score = Score + 50
                FishPoints = FishPoints - 50
            ELSE
                Hero.Action = STOPPED
            END IF
        CASE STOPPED
            Hero.Frame = 1
    END SELECT

    IF Hero.X + HeroWidth > _WIDTH THEN Hero.X = _WIDTH - HeroWidth
    IF Hero.X < 0 THEN Hero.X = 0
END IF

IF Hero.Face THEN
    SELECT CASE Hero.Face
        CASE MOVINGRIGHT
            _PUTIMAGE (Hero.X, Hero.Y - HeroHeight), HeroSprites(Hero.Frame), GameScreen
        CASE MOVINGLEFT
            _PUTIMAGE (Hero.X + HeroWidth, Hero.Y - HeroHeight)-STEP(-HeroWidth - 1, HeroHeight - 1), HeroSprites(Hero.Frame), GameScreen
    END SELECT
END IF
END SUB

'------------------------------------------------------------------------------
SUB CheckLanding
'Check to see if the hero landed safely:
DIM i AS INTEGER
DIM X AS INTEGER
DIM m.X AS INTEGER

IF Hero.CurrentRow > 0 AND (Hero.Action = STOPPED OR Hero.Action = WALKING) THEN
    Safe = False
    X = IceRow(Hero.CurrentRow).Position
    m.X = IceRow(Hero.CurrentRow).MirroredPosition
    SELECT CASE Levels(ThisLevel).BlockType
        CASE SINGLEBLOCK
            IF Hero.X + HeroWidth > X AND Hero.X < X + HeroWidth * 2 THEN
                Safe = True
            ELSEIF m.X AND Hero.X + HeroWidth > m.X AND Hero.X < m.X + HeroWidth * 2 THEN
                Safe = True
            ELSEIF Hero.X + HeroWidth > X + HeroWidth * 3.5 AND Hero.X < X + HeroWidth * 3.5 + HeroWidth * 2 THEN
                Safe = True
            ELSEIF m.X AND Hero.X + HeroWidth > m.X + HeroWidth * 3.5 AND Hero.X < m.X + HeroWidth * 3.5 + HeroWidth * 2 THEN
                Safe = True
            ELSEIF Hero.X + HeroWidth > X + HeroWidth * 7 AND Hero.X < X + HeroWidth * 7 + HeroWidth * 2 THEN
                Safe = True
            ELSEIF m.X AND Hero.X + HeroWidth > m.X + HeroWidth * 7 AND Hero.X < m.X + HeroWidth * 7 + HeroWidth * 2 THEN
                Safe = True
            END IF
        CASE DOUBLEBLOCK
            IF Hero.X + HeroWidth > X AND Hero.X < X + RowWidth THEN
                Safe = True
            ELSEIF m.X AND Hero.X + HeroWidth > m.X AND Hero.X < m.X + RowWidth THEN
                Safe = True
            END IF
        CASE MOVINGBLOCK
            IF Hero.X + HeroWidth > X + BlockLines + SpaceBetween AND Hero.X < X + BlockLines + SpaceBetween + HeroWidth THEN
                Safe = True
            ELSEIF m.X AND Hero.X + HeroWidth > m.X + BlockLines + SpaceBetween AND Hero.X < m.X + BlockLines + SpaceBetween + HeroWidth THEN
                Safe = True
            ELSEIF Hero.X + HeroWidth > X + BlockLines + HeroWidth * 1.5 - SpaceBetween AND Hero.X < X + BlockLines + HeroWidth * 1.5 - SpaceBetween + HeroWidth THEN
                Safe = True
            ELSEIF m.X AND Hero.X + HeroWidth > m.X + BlockLines + HeroWidth * 1.5 - SpaceBetween AND Hero.X < m.X + BlockLines + HeroWidth * 1.5 - SpaceBetween + HeroWidth THEN
                Safe = True
            ELSEIF Hero.X + HeroWidth > X + BlockLines + HeroWidth * 3 + SpaceBetween AND Hero.X < X + BlockLines + HeroWidth * 3 + SpaceBetween + HeroWidth THEN
                Safe = True
            ELSEIF m.X AND Hero.X + HeroWidth > m.X + BlockLines + HeroWidth * 3 + SpaceBetween AND Hero.X < m.X + BlockLines + HeroWidth * 3 + SpaceBetween + HeroWidth THEN
                Safe = True
            ELSEIF Hero.X + HeroWidth > X + BlockLines + HeroWidth * 4.5 - SpaceBetween AND Hero.X < X + BlockLines + HeroWidth * 4.5 - SpaceBetween + HeroWidth THEN
                Safe = True
            ELSEIF m.X AND Hero.X + HeroWidth > m.X + BlockLines + HeroWidth * 4.5 - SpaceBetween AND Hero.X < m.X + BlockLines + HeroWidth * 4.5 - SpaceBetween + HeroWidth THEN
                Safe = True
            ELSEIF Hero.X + HeroWidth > X + BlockLines + HeroWidth * 6 + SpaceBetween AND Hero.X < X + BlockLines + HeroWidth * 6 + SpaceBetween + HeroWidth THEN
                Safe = True
            ELSEIF m.X AND Hero.X + HeroWidth > m.X + BlockLines + HeroWidth * 6 + SpaceBetween AND Hero.X < m.X + BlockLines + HeroWidth * 6 + SpaceBetween + HeroWidth THEN
                Safe = True
            ELSEIF Hero.X + HeroWidth > X + BlockLines + HeroWidth * 7.5 - SpaceBetween AND Hero.X < X + BlockLines + HeroWidth * 7.5 - SpaceBetween + HeroWidth THEN
                Safe = True
            ELSEIF m.X AND Hero.X + HeroWidth > m.X + BlockLines + HeroWidth * 7.5 - SpaceBetween AND Hero.X < m.X + BlockLines + HeroWidth * 7.5 - SpaceBetween + HeroWidth THEN
                Safe = True
            END IF
    END SELECT
    IF Safe THEN
        Safe = False
        IF IceRow(Hero.CurrentRow).State = False AND JustLanded THEN
            JustLanded = False
            IF BlockSound THEN _SNDPLAYCOPY BlockSound
            IF IglooPieces < 16 THEN IglooPieces = IglooPieces + 1
            IF IglooPieces = 16 THEN
                FOR i = 1 TO 4
                    IceRow(i).State = True
                NEXT i
            ELSE
                IceRow(Hero.CurrentRow).State = True
                RestoreRowsTimer = TIMER
            END IF
            Score = Score + ThisLevel * 10
        END IF
    ELSE
        IF Hero.Action <> DROWNING THEN
            IF DrowningSound THEN _SNDPLAYCOPY DrowningSound
            TIMER(TempTimer) OFF
            Hero.Frame = 4
            Hero.Action = DROWNING
            Hero.Face = STOPPED
            Hero.Direction = STOPPED
            Lives = Lives - 1
            AnimationStep = 0
        END IF
    END IF
END IF
END SUB

'------------------------------------------------------------------------------
SUB CheckCreatures
DIM i AS INTEGER
DIM j AS INTEGER
DIM X AS INTEGER
DIM Touched AS _BIT
DIM WhichCreature AS _BYTE

IF Hero.Grabbed OR Hero.CurrentRow = 0 OR (Hero.Action = JUMPINGUP OR Hero.Action = JUMPINGDOWN OR Hero.Action = DROWNING OR Hero.Action = FREEZING) THEN EXIT SUB
i = Hero.CurrentRow

IF Creatures(i).Species = 0 THEN EXIT SUB

X = Creatures(i).X

DIM EvalCreatures(1 TO Creatures(i).Number) AS INTEGER

EvalCreatures(1) = Creatures(i).X
SELECT EVERYCASE Creatures(i).Number
    CASE IS > 1
        EvalCreatures(2) = X + CreatureWidth(Creatures(i).Species) + Creatures(i).Spacing
    CASE 3
        EvalCreatures(3) = X + CreatureWidth(Creatures(i).Species) * 2 + Creatures(i).Spacing * 2
END SELECT

'Check for first creature in row, left to right:
IF (Creatures(i).State AND FIRST) AND Hero.X + HeroWidth > EvalCreatures(1) AND Hero.X < EvalCreatures(1) + CreatureWidth(Creatures(i).Species) THEN
    Touched = True
    WhichCreature = FIRST
END IF

'Check for second creature in row, left to right:
IF Creatures(i).Number > 1 THEN
    IF (Creatures(i).State AND SECOND) AND Hero.X + HeroWidth > EvalCreatures(2) AND Hero.X < EvalCreatures(2) + CreatureWidth(Creatures(i).Species) THEN
        Touched = True
        WhichCreature = SECOND
    END IF
END IF

'Check for second creature in row, left to right:
IF Creatures(i).Number = 3 THEN
    IF (Creatures(i).State AND THIRD) AND Hero.X + HeroWidth > EvalCreatures(3) AND Hero.X < EvalCreatures(3) + CreatureWidth(Creatures(i).Species) THEN
        Touched = True
        WhichCreature = THIRD
    END IF
END IF

IF Touched THEN
    IF Creatures(i).Species = FISH THEN
        Creatures(i).State = Creatures(i).State XOR WhichCreature
        IF Hero.Action <> EATINGFISH THEN
            IF CollectFishSound THEN _SNDPLAYCOPY CollectFishSound
            Hero.Frame = 1
            Hero.Action = EATINGFISH
            Hero.Direction = STOPPED
            AnimationStep = 0
            FishPoints = 200
        END IF
    ELSE
        Hero.Grabbed = True
        IF IceRow(i).Direction = Creatures(i).Direction THEN
            IF IceRow(i).Direction = MOVINGRIGHT THEN IceRow(i).Direction = MOVINGLEFT ELSE IceRow(i).Direction = MOVINGRIGHT
        END IF
    END IF
END IF
END SUB

'------------------------------------------------------------------------------
SUB UpdateScreen
_PUTIMAGE , GameScreen, MainScreen
_DISPLAY
$IF INTERNALBUILD THEN
    Frames = Frames + 1
$END IF
END SUB

'------------------------------------------------------------------------------
SUB ReadKeyboard
DIM k AS INTEGER

k = _KEYHIT
SELECT CASE k
    CASE 27
        UserWantsToQuit = True
    CASE 13
        IF NOT InGame THEN
            IF GameOver THEN SetLevel GAMESTART: NewLevelSet = TIMER
            GameOver = False
            InGame = True
            TIMER(TempTimer) ON
        END IF
    CASE 32
        IF NOT Hero.Grabbed AND Hero.CurrentRow > 0 AND (Hero.Action = STOPPED OR Hero.Action = WALKING) AND InGame THEN
            IF IglooPieces > 0 THEN
                IF IglooPieces < 16 THEN IglooPieces = IglooPieces - 1
                IF BlockSound THEN _SNDPLAYCOPY BlockSound
                IF IceRow(Hero.CurrentRow).Direction = MOVINGRIGHT THEN
                    IceRow(Hero.CurrentRow).Direction = MOVINGLEFT
                    IF IceRow(Hero.CurrentRow).MirroredPosition THEN SWAP IceRow(Hero.CurrentRow).Position, IceRow(Hero.CurrentRow).MirroredPosition
                ELSE
                    IceRow(Hero.CurrentRow).Direction = MOVINGRIGHT
                    IF IceRow(Hero.CurrentRow).MirroredPosition THEN SWAP IceRow(Hero.CurrentRow).Position, IceRow(Hero.CurrentRow).MirroredPosition
                END IF
            END IF
        END IF
END SELECT

'Check if a movement must be processed:
IF NOT InGame OR Hero.Action = DROWNING OR Hero.Action = FREEZING OR Hero.Action = ENTERINGIGLOO OR Hero.Action = EATINGFISH THEN EXIT SUB

IF Hero.Action = WALKING THEN Hero.Action = STOPPED: Hero.Direction = Hero.Action

'Is the left arrow key down?
IF _KEYDOWN(19200) THEN Hero.Direction = MOVINGLEFT: Hero.Face = Hero.Direction: IF Hero.Action = STOPPED THEN Hero.Action = WALKING

'Is the right arrow key down?
IF _KEYDOWN(19712) THEN Hero.Direction = MOVINGRIGHT: Hero.Face = Hero.Direction: IF Hero.Action = STOPPED THEN Hero.Action = WALKING

'If the hero has been grabbed by a creature, no jumps are allowed.
IF Hero.Grabbed THEN EXIT SUB

'Is the up arrow key down?
IF _KEYDOWN(18432) THEN
    IF Hero.CurrentRow > 0 AND (Hero.Action = STOPPED OR Hero.Action = WALKING) THEN
        Hero.Action = JUMPINGUP
        AnimationStep = 0
        IF JumpSound THEN _SNDPLAYCOPY JumpSound
    ELSEIF Hero.CurrentRow = 0 AND IglooPieces = 16 THEN
        'The igloo has been finished. If the hero is standing under the door,
        'we'll let him in:
        IF Hero.X + HeroWidth > DoorX + 5 AND Hero.X < DoorX + 17 THEN
            IF JumpSound THEN _SNDPLAYCOPY JumpSound
            TIMER(TempTimer) OFF
            Hero.Action = ENTERINGIGLOO
            Hero.Direction = STOPPED
            Hero.Face = STOPPED
            Hero.X = DoorX
            AnimationStep = 0
        END IF
    END IF
END IF

'Is the down arrow key down?
IF _KEYDOWN(20480) AND Hero.CurrentRow < 4 AND (Hero.Action = STOPPED OR Hero.Action = WALKING) THEN
    Hero.Action = JUMPINGDOWN
    AnimationStep = 0
    IF JumpSound THEN _SNDPLAYCOPY JumpSound
END IF
END SUB

'------------------------------------------------------------------------------
SUB DecreaseTemperature
Temperature = Temperature - 1
IF Temperature = 0 THEN
    IF DrowningSound THEN _SNDPLAYCOPY DrowningSound
    TIMER(TempTimer) OFF
    HeroFreezingSprite = _COPYIMAGE(HeroSprites(4))
    _SOURCE HeroFreezingSprite
    Hero.Action = FREEZING
    Hero.Face = STOPPED
    Hero.Direction = STOPPED
    Lives = Lives - 1
    AnimationStep = 0
END IF
END SUB

'------------------------------------------------------------------------------
FUNCTION TRIM$ (Value)
TRIM$ = LTRIM$(RTRIM$(STR$(Value)))
END FUNCTION

'------------------------------------------------------------------------------
SUB UpdateFrames
DIM PrevDest AS LONG
DIM i AS _BYTE
DIM AuroraLineColor AS _UNSIGNED LONG
STATIC AuroraCount AS INTEGER
STATIC CreditCount AS INTEGER
STATIC CreditUpdate AS INTEGER
STATIC BlockCount AS SINGLE

AuroraCount = AuroraCount + 1
IF AuroraCount > 3 THEN
    RANDOMIZE TIMER
    AuroraCount = 0
    PrevDest = _DEST
    _DEST ThisAurora
    FOR i = 1 TO AuroraH STEP 2
        SELECT CASE i
            CASE 1 TO AuroraH / 3
                AuroraLineColor = Aurora(_CEIL(RND * 3))
            CASE AuroraH / 3 + 1 TO (AuroraH / 3) + (AuroraH / 4)
                AuroraLineColor = Aurora(_CEIL(RND * 3) + 3)
            CASE ELSE
                AuroraLineColor = Aurora(_CEIL(RND * 2) + 5)
        END SELECT
        LINE (0, 0)-STEP(_WIDTH(ThisAurora), AuroraH - i), AuroraLineColor, BF 'Aurora
    NEXT i
    _DEST PrevDest
END IF

IF NOT InGame THEN
    CreditUpdate = CreditUpdate + 1
    IF CreditUpdate > 1 THEN
        CreditUpdate = 0
        SELECT CASE CreditY
            CASE -2
                CreditCount = CreditCount + 1
                IF CreditCount > 10 THEN
                    CreditCount = 0
                    CreditY = CreditY + 1
                END IF
            CASE -1 TO 16
                CreditY = CreditY + 1
            CASE 17
                CreditCount = CreditCount + 1
                IF CreditCount > 15 THEN
                    CreditCount = 0
                    CreditY = -2
                END IF
        END SELECT
    END IF
ELSE
    CreditY = 17
END IF

IF Hero.Action = WALKING AND InGame THEN
    IF Hero.Frame = 1 THEN Hero.Frame = 2 ELSE Hero.Frame = 1
END IF

IF InGame AND NOT LevelComplete AND (Hero.Action <> DROWNING AND Hero.Action <> FREEZING AND Hero.Action <> EATINGFISH) THEN
    FOR i = 1 TO 4
        IF Creatures(i).Frame = 1 THEN Creatures(i).Frame = 2 ELSE Creatures(i).Frame = 1
    NEXT i
END IF

IF IceRow(1).State AND IceRow(2).State AND IceRow(3).State AND IceRow(4).State AND IglooPieces < 16 THEN
    IF NOT LevelComplete THEN
        IF TIMER - RestoreRowsTimer > .3 THEN
            FOR i = 1 TO 4
                IceRow(i).State = False
            NEXT i
        END IF
    END IF
END IF

IF Levels(ThisLevel).BlockType = MOVINGBLOCK AND (Hero.Action <> DROWNING AND Hero.Action <> FREEZING AND Hero.Action <> EATINGFISH) AND NOT LevelComplete THEN
    BlockCount = BlockCount + .5
    IF BlockCount > MaxSpaceBetween THEN BlockCount = -MaxSpaceBetween
    SELECT CASE BlockCount
        CASE -MaxSpaceBetween TO -1
            SpaceBetween = ABS(BlockCount + 1)
        CASE 0 TO MaxSpaceBetween
            SpaceBetween = BlockCount
    END SELECT
END IF
END SUB

'------------------------------------------------------------------------------
SUB SetLevel (TargetLevel)
DIM CreatureCheck AS INTEGER

SELECT CASE TargetLevel
    CASE GAMESTART
        LevelComplete = False
        ThisLevel = 1
        Lives = 3
        Score = 0
        Temperature = InitialTemperature
        IglooPieces = 0
    CASE NEXTLEVEL
        LevelComplete = False
        ThisLevel = ThisLevel + 1
        Temperature = InitialTemperature
END SELECT

IF ThisLevel > UBOUND(levels) THEN ThisLevel = ThisLevel - 1

'Set hero's initial position and state:
Hero.CurrentRow = 0
Hero.X = 100
Hero.Y = HeroStartRow
Hero.Direction = STOPPED
Hero.Face = MOVINGRIGHT
Hero.Action = STOPPED
Hero.Frame = 1
Hero.Grabbed = False

'Erase existing creatures and fills an array with the ones allowed:
ERASE Creatures
MaxLevelCreatures = 0
CreatureCheck = 1
DO
    IF Levels(ThisLevel).CreaturesAllowed AND CreatureCheck THEN
        MaxLevelCreatures = MaxLevelCreatures + 1
        REDIM _PRESERVE ThisLevelCreatures(1 TO MaxLevelCreatures)
        ThisLevelCreatures(MaxLevelCreatures) = CreatureCheck
    END IF
    CreatureCheck = CreatureCheck * 2
    IF CreatureCheck > CLAM THEN EXIT DO
LOOP

'Set ice rows initial position and direction:
IceRow(1).Position = 90
IceRow(1).Direction = MOVINGLEFT
IceRow(2).Position = 10
IceRow(2).Direction = MOVINGRIGHT
IceRow(3).Position = 90
IceRow(3).Direction = MOVINGLEFT
IceRow(4).Position = 10
IceRow(4).Direction = MOVINGRIGHT

FOR I = 1 TO 4
    IceRow(I).MirroredPosition = 0
    IceRow(I).State = False
NEXT I

NewLevelSet = TIMER
InGame = False

SELECT CASE Levels(ThisLevel).BlockType
    CASE SINGLEBLOCK: RowWidth = HeroWidth * 9
    CASE DOUBLEBLOCK OR MOVINGBLOCK: RowWidth = HeroWidth * 8.5
END SELECT

END SUB

'------------------------------------------------------------------------------
SUB LoadAssets
JumpSound = _SNDOPEN("jump.ogg", "SYNC")
BlockSound = _SNDOPEN("block.ogg", "SYNC")
DrowningSound = _SNDOPEN("drowning.ogg", "SYNC")
IglooBlockCountSound = _SNDOPEN("iglooblock.ogg", "SYNC")
ScoreCountSound = _SNDOPEN("scorecount.ogg", "SYNC")
CollectFishSound = _SNDOPEN("fish.ogg", "SYNC")
END SUB

'------------------------------------------------------------------------------
SUB ScreenSetup
GameScreen = _NEWIMAGE(400, 300, 32)
MainScreen = _NEWIMAGE(800, 600, 32)
SCREEN MainScreen
_TITLE "Frostbite Tribute"

$IF WIN THEN
    _SCREENMOVE _MIDDLE
$END IF

GroundH = _HEIGHT(GameScreen) / 3 '1/3 of the GameScreen
WaterH = (_HEIGHT(GameScreen) / 3) * 2 '2/3 of the GameScreen
SkyH = GroundH / 3 '1/3 of GroundH
CreditsBarH = _HEIGHT(GameScreen) / 15 '1/11 of the GameScreen
AuroraH = SkyH / 2

ThisAurora = _NEWIMAGE(_WIDTH, AuroraH, 32)

CreditsIMG = _NEWIMAGE(_WIDTH(GameScreen), 40, 32)
_DEST CreditsIMG
_FONT 16
COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
_PRINTSTRING (10, 0), "Copyleft 2015, Fellippe Heitor. ENTER to start."
FOR I = 22 TO 31
    LINE (0, I)-(20, I), Aurora(I MOD 7 + 1)
NEXT I
_PRINTSTRING (20, 20), "Frostbite Tribute"
CreditY = -2

_DEST GameScreen
_FONT 8

END SUB

'------------------------------------------------------------------------------
SUB RestoreData
DIM MaxLevels AS INTEGER
DIM i AS INTEGER

RESTORE AuroraColors
FOR i = 1 TO 7
    READ AuroraR, AuroraG, AuroraB
    Aurora(i) = _RGB32(AuroraR, AuroraG, AuroraB)
NEXT i

RESTORE IceRowsDATA
FOR i = 1 TO 4
    READ IceRows(i)
NEXT i

RESTORE LevelsDATA
READ MaxLevels
REDIM Levels(1 TO MaxLevels) AS LevelInfo

FOR i = 1 TO MaxLevels
    READ Levels(i).Speed
    READ Levels(i).BlockType
    READ Levels(i).TimeOfDay
    READ Levels(i).CreaturesAllowed
NEXT i

RESTORE CreaturesDATA
READ CreatureWidth(FISH)
READ CreatureWidth(BIRD)
READ CreatureWidth(CRAB)
READ CreatureWidth(CLAM)

END SUB

'------------------------------------------------------------------------------
SUB SpritesSetup
'Generates sprites from pixel DATA:
DIM ColorIndex AS INTEGER
DIM ColorsInPalette AS INTEGER
DIM SpritePalette(0) AS _UNSIGNED LONG
DIM i AS INTEGER

'Hero
FOR i = 1 TO 4
    HeroSprites(i) = _NEWIMAGE(30, 36, 32)
NEXT i
RESTORE HeroPalette
READ ColorsInPalette
REDIM SpritePalette(1 TO ColorsInPalette) AS _UNSIGNED LONG
FOR i = 1 TO ColorsInPalette
    READ SpritePalette(i)
NEXT i

RESTORE Hero1: LoadSprite HeroSprites(1), 30, 36, SpritePalette()
RESTORE Hero2: LoadSprite HeroSprites(2), 30, 36, SpritePalette()
RESTORE Hero3: LoadSprite HeroSprites(3), 30, 36, SpritePalette()
RESTORE Hero4: LoadSprite HeroSprites(4), 30, 36, SpritePalette()

'Bird
FOR i = 1 TO 2
    BirdSprites(i) = _NEWIMAGE(30, 15, 32)
NEXT i

RESTORE BirdPalette
READ ColorsInPalette
REDIM SpritePalette(1 TO ColorsInPalette) AS _UNSIGNED LONG
FOR i = 1 TO ColorsInPalette
    READ SpritePalette(i)
NEXT i

RESTORE Bird1: LoadSprite BirdSprites(1), 30, 15, SpritePalette()
RESTORE Bird2: LoadSprite BirdSprites(2), 30, 15, SpritePalette()


'Fish
FOR i = 1 TO 2
    FishSprites(i) = _NEWIMAGE(30, 15, 32)
NEXT i

RESTORE FishPalette
READ ColorsInPalette
REDIM SpritePalette(1 TO ColorsInPalette) AS _UNSIGNED LONG
FOR i = 1 TO ColorsInPalette
    READ SpritePalette(i)
NEXT i

RESTORE Fish1: LoadSprite FishSprites(1), 30, 15, SpritePalette()
RESTORE Fish2: LoadSprite FishSprites(2), 30, 15, SpritePalette()
END SUB

'------------------------------------------------------------------------------
SUB LoadSprite (ImageHandle AS LONG, ImageWidth AS INTEGER, ImageHeight AS INTEGER, SpritePalette() AS LONG)
'Loads a sprite from DATA fields. You must use RESTORE appropriately before calling this SUB.
DIM i AS INTEGER
DIM DataLine AS STRING
DIM Pixel AS INTEGER
DIM PrevDest AS LONG

PrevDest = _DEST
_DEST ImageHandle

FOR i = 0 TO ImageHeight - 1
    READ DataLine
    FOR Pixel = 0 TO ImageWidth - 1
        PSET (Pixel, i), SpritePalette(VAL(MID$(DataLine, Pixel + 1, 1)))
    NEXT Pixel
NEXT i

_DEST PrevDest
END SUB

'------------------------------------------------------------------------------
SUB SetTimers
TempTimer = _FREETIMER
ON TIMER(TempTimer, 1) DecreaseTemperature

FramesTimer = _FREETIMER
ON TIMER(FramesTimer, .1) UpdateFrames
TIMER(FramesTimer) ON
END SUB

'------------------------------------------------------------------------------
SUB CalculateScores

'Calculate points for each igloo block
IF IglooPieces > 0 THEN
    IF IglooBlockCountSound THEN _SNDPLAYCOPY IglooBlockCountSound
    Score = Score + (ThisLevel * 10)
    IglooPieces = IglooPieces - 1
END IF

'Calculate points for each degree remaining
IF IglooPieces = 0 AND Temperature > 0 THEN
    IF ScoreCountSound THEN _SNDPLAYCOPY ScoreCountSound
    Score = Score + (10 * ThisLevel)
    Temperature = Temperature - 1
END IF

IF IglooPieces = 0 AND Temperature = 0 THEN SetLevel NEXTLEVEL
END SUB
