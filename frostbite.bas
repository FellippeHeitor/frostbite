'Frosbite Tribute
'A clone of Frostbite for the Atari 2600, originally designed
'by Steve Cartwright and published by Activition in 1983.
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

$RESIZE:SMOOTH

'Game constants: --------------------------------------------------------------
CONST True = -1
CONST False = NOT True

CONST FPS_COUNTER = False

CONST SINGLEBLOCK = 1
CONST DOUBLEBLOCK = 2
CONST MOVINGBLOCK = 3

CONST MOVINGLEFT = -1
CONST MOVINGRIGHT = 1
CONST STOPPED = 0

CONST WALKING = 1
CONST JUMPINGUP = 2
CONST JUMPINGDOWN = 3
CONST FREEZING = 4
CONST DROWNING = 5
CONST ENTERINGIGLOO = 6

CONST DAY = 1
CONST NIGHT = 2

CONST GAMESTART = -1
CONST NEXTLEVEL = 0

CONST HeroStartRow = 95
CONST HeroHeight = 36
CONST HeroWidth = 30
CONST DoorX = 276

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

TYPE HeroInfo
    CurrentRow AS INTEGER
    X AS INTEGER
    Y AS INTEGER
    Direction AS INTEGER
    Face AS INTEGER
    Action AS INTEGER
    Frame AS _BYTE
END TYPE

TYPE LevelInfo
    Speed AS _BYTE
    TimeOfDay AS _BYTE
END TYPE

'Game variables: --------------------------------------------------------------
DIM SHARED AnimationStep AS INTEGER
DIM SHARED Aurora(1 TO 7) AS LONG
DIM SHARED AuroraH AS INTEGER
DIM SHARED IceRows(1 TO 4) AS INTEGER
DIM SHARED BlockType AS _BYTE
DIM SHARED CreditsBarH AS INTEGER
DIM SHARED CreditsIMG AS LONG, CreditY AS INTEGER
DIM SHARED FramesTimer AS INTEGER
DIM SHARED GameOver AS _BIT
DIM SHARED GameScreen AS LONG
DIM SHARED GroundH AS INTEGER
DIM SHARED Hero AS HeroInfo
DIM SHARED HeroFreezingSprite AS LONG
DIM SHARED HeroSprites(1 TO 4) AS LONG
DIM SHARED IceRow(1 TO 4) AS RowInfo
DIM SHARED IglooPieces AS INTEGER
DIM SHARED InGame AS _BYTE
DIM SHARED JustLanded AS _BIT
DIM SHARED Level AS INTEGER
DIM SHARED Levels(1 TO 9) AS LevelInfo
DIM SHARED LevelComplete AS _BIT
DIM SHARED LevelSpeed AS INTEGER
DIM SHARED Lives AS INTEGER
DIM SHARED MainScreen AS LONG
DIM SHARED NewLevelSet AS SINGLE
DIM SHARED RestoreRowsTimer AS SINGLE
DIM SHARED RunStart AS DOUBLE
DIM SHARED Safe AS _BIT
DIM SHARED Score AS LONG
DIM SHARED SkyH AS INTEGER
DIM SHARED Temperature AS INTEGER
DIM SHARED TemperatureBlink AS INTEGER
DIM SHARED TempTimer AS INTEGER
DIM SHARED ThisAurora AS LONG
DIM SHARED ThisRowColor AS LONG
DIM SHARED UserWantsToQuit AS _BYTE
DIM SHARED WaterH AS INTEGER
DIM i AS LONG

IF FPS_COUNTER THEN DIM SHARED Frames AS _UNSIGNED LONG

'Variables to hold sounds:
DIM SHARED JumpSound AS LONG
DIM SHARED BlockSound AS LONG
DIM SHARED DrowningSound AS LONG
DIM SHARED IglooBlockCountSound AS LONG
DIM SHARED ScoreCountSound AS LONG

'Game setup: ------------------------------------------------------------------
IF FPS_COUNTER THEN RunStart = TIMER 'For testing/debugging purposes (FPS)

RestoreData
ScreenSetup
LoadAssets
SpritesSetup
SetTimers
SetLevel GAMESTART
NewLevelSet = 0

'Main game loop: --------------------------------------------------------------
DO: _LIMIT 24
    IF LevelComplete THEN
        CalculateScores
    END IF

    NewLevelPause
    DrawScenery
    DrawIgloo
    MoveIceBlocks
    MoveHero
    CheckLanding

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
DATA 111111111111222221111111111111
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
DATA 111113333333333333333331111111
DATA 111113333333333333333331111111
DATA 111113333333111113333331111111
DATA 111113333333111113333331111111
DATA 111113333333111113333331111111
DATA 111113333333111113333331111111
DATA 111113333333444444444114441111
DATA 111111111444444444444114441111
DATA 111114444444444444444114441111
DATA 111444444444441114444444441111
DATA 111444444444441114444444441111
DATA 111444444444444444444444441111
DATA 111444444444444444444444441111
DATA 111444444444444444444444441111
DATA 111444111444441114444441111111
DATA 111444111444441114444441111111
DATA 111444111444444444444441111111
DATA 111111111555555555555111111111
DATA 111111111555555555555111111111
DATA 111111111555555555555111111111
DATA 111111111555111115555111111111
DATA 111555555555555555555555551111
DATA 111555555555555555555555551111

'------------------------------------------------------------------------------
'Subprocedures start here:
'------------------------------------------------------------------------------
SUB NewLevelPause
IF InGame THEN EXIT SUB
IF NewLevelSet <> 0 THEN
    IF TIMER - NewLevelSet > 1 THEN
        InGame = True
        NewLevelSet = 0
    END IF
END IF
END SUB

'------------------------------------------------------------------------------
SUB DrawScenery
LINE (0, 0)-STEP(_WIDTH, GroundH), _RGB32(192, 192, 192), BF '                    Ground/ice
LINE (0, 0)-STEP(_WIDTH, SkyH), _RGB32(37, 54, 189), BF '                         Sky
LINE (0, GroundH - 2)-STEP(_WIDTH, 3), _RGB32(0, 0, 0), BF '                      Black separator
LINE (0, GroundH + 2)-STEP(_WIDTH, WaterH), _RGB32(0, 27, 141), BF '              Water
_PUTIMAGE (0, SkyH - AuroraH + 1), ThisAurora, GameScreen '                       Aurora
LINE (0, _HEIGHT - CreditsBarH)-STEP(_WIDTH, CreditsBarH), _RGB32(0, 0, 0), BF '  Credits bar
_PUTIMAGE (0, _HEIGHT - CreditsBarH), CreditsIMG, GameScreen, (0, CreditY)-STEP(_WIDTH(CreditsIMG), CreditsBarH)

COLOR _RGB32(126, 148, 254), _RGBA32(0, 0, 0, 0)
_PRINTSTRING (72 - (LEN(TRIM$(Score)) * _FONTWIDTH), 2), TRIM$(Score)
SELECT CASE Temperature
    CASE 1 TO 5
        TemperatureBlink = TemperatureBlink + 1
        IF INT(TemperatureBlink / 2) <> TemperatureBlink / 2 AND NOT LevelComplete THEN
            COLOR _RGBA32(0, 0, 0, 0), _RGBA32(0, 0, 0, 0)
        END IF
    CASE ELSE
        TemperatureBlink = 0
END SELECT
_PRINTSTRING (72 - (LEN(TRIM$(Lives)) * _FONTWIDTH), 14), TRIM$(Lives)
_PRINTSTRING (40 - (LEN(TRIM$(Temperature)) * _FONTWIDTH), 14), TRIM$(Temperature) + CHR$(248)

'For debugging/testing purposes:
IF FPS_COUNTER THEN
    crd$ = "Frames=" + TRIM$(Frames) + " FPS=" + TRIM$(_CEIL(Frames / (TIMER - RunStart)))
    _PRINTSTRING (_WIDTH - (LEN(crd$) * _FONTWIDTH), 14), crd$
END IF

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
        IF Levels(Level).TimeOfDay = NIGHT THEN
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
'Ice blocks:
FOR I = 1 TO 4
    IF NOT IceRow(I).State THEN ThisRowColor = UnsteppedBlockColor ELSE ThisRowColor = SteppedBlockColor
    SELECT CASE BlockType
        CASE SINGLEBLOCK
            RowWidth = HeroWidth * 9

            IF InGame AND Hero.Action <> DROWNING AND Hero.Action <> FREEZING AND NOT LevelComplete THEN
                IceRow(I).Position = IceRow(I).Position + LevelSpeed * IceRow(I).Direction
                IF IceRow(I).Direction = MOVINGRIGHT THEN
                    IF IceRow(I).Position >= _WIDTH(GameScreen) THEN
                        IceRow(I).Position = 0
                        IceRow(I).MirroredPosition = 0
                    END IF
                END IF
                IF IceRow(I).Direction = MOVINGLEFT THEN
                    IF IceRow(I).Position < -RowWidth THEN
                        IceRow(I).Position = _WIDTH(GameScreen) - 1 - RowWidth
                        IceRow(I).MirroredPosition = 0
                    END IF
                END IF
            END IF

            'Draw normal blocks
            LINE (IceRow(I).Position, IceRows(I))-STEP(HeroWidth * 2, 0), ThisRowColor
            LINE (IceRow(I).Position + HeroWidth * 3.5, IceRows(I))-STEP(HeroWidth * 2, 0), ThisRowColor
            LINE (IceRow(I).Position + HeroWidth * 7, IceRows(I))-STEP(HeroWidth * 2, 0), ThisRowColor

            IF IceRow(I).Direction = MOVINGLEFT THEN
                IF IceRow(I).Position < 0 THEN
                    IceRow(I).MirroredPosition = _WIDTH(GameScreen) + IceRow(I).Position
                END IF
            ELSE
                IF IceRow(I).Position + HeroWidth * 7 + HeroWidth * 2 > _WIDTH(GameScreen) THEN
                    IceRow(I).MirroredPosition = -_WIDTH(GameScreen) + IceRow(I).Position
                END IF
            END IF

            'Draw mirrored blocks
            IF IceRow(I).MirroredPosition THEN
                LINE (IceRow(I).MirroredPosition, IceRows(I))-STEP(HeroWidth * 2, 0), ThisRowColor
                LINE (IceRow(I).MirroredPosition + HeroWidth * 3.5, IceRows(I))-STEP(HeroWidth * 2, 0), ThisRowColor
                LINE (IceRow(I).MirroredPosition + HeroWidth * 7, IceRows(I))-STEP(HeroWidth * 2, 0), ThisRowColor
            END IF
        CASE DOUBLEBLOCK
        CASE MOVINGBLOCK
    END SELECT
NEXT I
END SUB

'------------------------------------------------------------------------------
SUB MoveHero
'Hero:
IF InGame THEN
    Hero.X = Hero.X + Hero.Direction * 3
    IF Hero.CurrentRow > 0 AND (Hero.Action = STOPPED OR Hero.Action = WALKING) THEN
        Hero.X = Hero.X + IceRow(Hero.CurrentRow).Direction * LevelSpeed
    END IF

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
                    IF Lives = 0 THEN
                        GameOver = True
                        InGame = False
                    ELSE
                        TIMER(TempTimer) ON
                        SetLevel Level
                    END IF
            END SELECT
        CASE FREEZING
            AnimationStep = AnimationStep + 1
            'Recolor the hero sprite to show it's freezing
            _DEST HeroFreezingSprite
            FOR I = 0 TO _WIDTH(HeroFreezingSprite) - 1
                IF AnimationStep >= _HEIGHT(HeroFreezingSprite) THEN EXIT FOR
                IF POINT(I, AnimationStep) <> _RGBA32(0, 0, 0, 0) THEN
                    PSET (I, AnimationStep), _RGB32(0, 150 - AnimationStep * 3, 219 + AnimationStep)
                END IF
            NEXT I
            _DEST GameScreen
            SELECT CASE AnimationStep
                CASE 1 TO 5, 11 TO 39
                    _PUTIMAGE (Hero.X, Hero.Y - HeroHeight)-STEP(HeroWidth - 1, HeroHeight - 1), HeroFreezingSprite, GameScreen
                CASE 6 TO 10
                    _PUTIMAGE (Hero.X + HeroWidth, Hero.Y - HeroHeight)-STEP(-HeroWidth - 1, HeroHeight - 1), HeroFreezingSprite, GameScreen
                CASE 40
                    _FREEIMAGE HeroFreezingSprite
                    IF Lives = 0 THEN
                        GameOver = True
                        InGame = False
                    ELSE
                        Temperature = InitialTemperature
                        TIMER(TempTimer) ON
                        SetLevel Level
                    END IF
            END SELECT
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

IF Hero.CurrentRow > 0 AND (Hero.Action = STOPPED OR Hero.Action = WALKING) THEN
    SELECT CASE BlockType
        CASE SINGLEBLOCK
            IF Hero.X + HeroWidth > IceRow(Hero.CurrentRow).Position AND Hero.X < IceRow(Hero.CurrentRow).Position + HeroWidth * 2 THEN
                'Safe on the first block
                Safe = True
            ELSEIF IceRow(Hero.CurrentRow).MirroredPosition AND Hero.X + HeroWidth > IceRow(Hero.CurrentRow).MirroredPosition AND Hero.X < IceRow(Hero.CurrentRow).MirroredPosition + HeroWidth * 2 THEN
                'Safe on the first mirrored block
                Safe = True
            ELSEIF Hero.X + HeroWidth > IceRow(Hero.CurrentRow).Position + HeroWidth * 3.5 AND Hero.X < IceRow(Hero.CurrentRow).Position + HeroWidth * 3.5 + HeroWidth * 2 THEN
                'Safe on the second block
                Safe = True
            ELSEIF IceRow(Hero.CurrentRow).MirroredPosition AND Hero.X + HeroWidth > IceRow(Hero.CurrentRow).MirroredPosition + HeroWidth * 3.5 AND Hero.X < IceRow(Hero.CurrentRow).MirroredPosition + HeroWidth * 3.5 + HeroWidth * 2 THEN
                'Safe on the second mirrored block
                Safe = True
            ELSEIF Hero.X + HeroWidth > IceRow(Hero.CurrentRow).Position + HeroWidth * 7 AND Hero.X < IceRow(Hero.CurrentRow).Position + HeroWidth * 7 + HeroWidth * 2 THEN
                'Safe on the third block
                Safe = True
            ELSEIF IceRow(Hero.CurrentRow).MirroredPosition AND Hero.X + HeroWidth > IceRow(Hero.CurrentRow).MirroredPosition + HeroWidth * 7 AND Hero.X < IceRow(Hero.CurrentRow).MirroredPosition + HeroWidth * 7 + HeroWidth * 2 THEN
                'Safe on the third mirrored block
                Safe = True
            ELSE
                'Drowned
                IF Hero.Action <> DROWNING THEN
                    IF DrowningSound THEN _SNDPLAYCOPY (DrowningSound)
                    TIMER(TempTimer) OFF
                    Hero.Frame = 4
                    Hero.Action = DROWNING
                    Hero.Face = STOPPED
                    Hero.Direction = STOPPED
                    Lives = Lives - 1
                    AnimationStep = 0
                END IF
            END IF
        CASE DOUBLEBLOCK
        CASE MOVINGBLOCK
    END SELECT
    IF Safe THEN
        Safe = False
        IF IceRow(Hero.CurrentRow).State = False AND JustLanded THEN
            JustLanded = False
            IF BlockSound THEN _SNDPLAYCOPY (BlockSound)
            IF IglooPieces < 16 THEN IglooPieces = IglooPieces + 1
            IF IglooPieces = 16 THEN
                FOR i = 1 TO 4
                    IceRow(i).State = True
                NEXT i
            ELSE
                IceRow(Hero.CurrentRow).State = True
                RestoreRowsTimer = TIMER
            END IF
            Score = Score + Level * 10
        END IF
    END IF
END IF
END SUB

'------------------------------------------------------------------------------
SUB UpdateScreen
_PUTIMAGE , GameScreen, MainScreen
_DISPLAY
IF FPS_COUNTER THEN Frames = Frames + 1
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
            IF GameOver THEN SetLevel GAMESTART
            GameOver = False
            InGame = True
            TIMER(TempTimer) ON
        END IF
    CASE 32
        IF Hero.CurrentRow > 0 AND (Hero.Action = STOPPED OR Hero.Action = WALKING) AND InGame THEN
            IF IglooPieces > 0 THEN
                IF IglooPieces < 16 THEN IglooPieces = IglooPieces - 1
                IF BlockSound THEN _SNDPLAYCOPY (BlockSound)
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
IF NOT InGame OR Hero.Action = DROWNING OR Hero.Action = FREEZING OR Hero.Action = ENTERINGIGLOO THEN EXIT SUB

IF Hero.Action = WALKING THEN Hero.Action = STOPPED: Hero.Direction = Hero.Action

'Is the left arrow key down?
IF _KEYDOWN(19200) THEN Hero.Direction = MOVINGLEFT: Hero.Face = Hero.Direction: IF Hero.Action = STOPPED THEN Hero.Action = WALKING

'Is the right arrow key down?
IF _KEYDOWN(19712) THEN Hero.Direction = MOVINGRIGHT: Hero.Face = Hero.Direction: IF Hero.Action = STOPPED THEN Hero.Action = WALKING

'Is the up arrow key down?
IF _KEYDOWN(18432) THEN
    IF Hero.CurrentRow > 0 AND (Hero.Action = STOPPED OR Hero.Action = WALKING) THEN
        IF Hero.Action = WALKING OR Hero.Action = STOPPED THEN Hero.Action = JUMPINGUP: AnimationStep = 0
        IF JumpSound THEN _SNDPLAYCOPY (JumpSound)
    ELSEIF Hero.CurrentRow = 0 AND IglooPieces = 16 THEN
        'The igloo has been finished. If the hero is standing under the door,
        'We'll let him in:
        IF Hero.X + HeroWidth > DoorX AND Hero.X < DoorX + 17 THEN
            IF JumpSound THEN _SNDPLAYCOPY (JumpSound)
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
    IF Hero.Action = WALKING OR Hero.Action = STOPPED THEN Hero.Action = JUMPINGDOWN: AnimationStep = 0
    IF JumpSound THEN _SNDPLAYCOPY (JumpSound)
END IF
END SUB

'------------------------------------------------------------------------------
SUB DecreaseTemperature
Temperature = Temperature - 1
IF Temperature = 0 THEN
    IF DrowningSound THEN _SNDPLAYCOPY (DrowningSound)
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
DIM PrevDest AS LONG, i AS _BYTE
STATIC AuroraCount AS INTEGER
STATIC CreditCount AS INTEGER
STATIC CreditUpdate AS INTEGER

AuroraCount = AuroraCount + 1
IF AuroraCount > 3 THEN
    AuroraCount = 0
    PrevDest = _DEST
    _DEST ThisAurora
    FOR i = 1 TO AuroraH
        LINE (0, 0)-STEP(_WIDTH(ThisAurora), AuroraH - i), Aurora(_CEIL(RND * 7)), BF 'Aurora
    NEXT i
    _DEST PrevDest
END IF

IF NOT InGame THEN
    CreditUpdate = CreditUpdate + 1
    IF CreditUpdate > 2 THEN
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

IF IceRow(1).State AND IceRow(2).State AND IceRow(3).State AND IceRow(4).State AND IglooPieces < 16 THEN
    IF NOT LevelComplete THEN
        IF TIMER - RestoreRowsTimer > .3 THEN
            FOR i = 1 TO 4
                IceRow(i).State = False
            NEXT i
        END IF
    END IF
END IF

END SUB

'------------------------------------------------------------------------------
SUB SetLevel (TargetLevel)

SELECT CASE TargetLevel
    CASE GAMESTART
        LevelComplete = False
        Level = 1
        Lives = 3
        Score = 0
        Temperature = InitialTemperature
        IglooPieces = 0
    CASE NEXTLEVEL
        LevelComplete = False
        Level = Level + 1
        Temperature = InitialTemperature
END SELECT

Hero.CurrentRow = 0
Hero.X = 100
Hero.Y = HeroStartRow
Hero.Direction = STOPPED
Hero.Face = MOVINGRIGHT
Hero.Action = STOPPED
Hero.Frame = 1

SELECT CASE Level
    CASE 1 TO 9
        LevelSpeed = 1
        BlockType = SINGLEBLOCK

        FOR I = 1 TO 4
            IceRow(I).MirroredPosition = 0
            IceRow(I).State = False
        NEXT I

        IceRow(1).Position = 90
        IceRow(1).Direction = MOVINGLEFT
        IceRow(2).Position = 10
        IceRow(2).Direction = MOVINGRIGHT
        IceRow(3).Position = 90
        IceRow(3).Direction = MOVINGLEFT
        IceRow(4).Position = 10
        IceRow(4).Direction = MOVINGRIGHT
        NewLevelSet = TIMER
        InGame = False
    CASE ELSE
END SELECT


END SUB

'------------------------------------------------------------------------------
SUB LoadAssets
JumpSound = _SNDOPEN("jump.ogg", "SYNC")
BlockSound = _SNDOPEN("block.ogg", "SYNC")
DrowningSound = _SNDOPEN("drowning.ogg", "SYNC")
IglooBlockCountSound = _SNDOPEN("iglooblock.ogg", "SYNC")
ScoreCountSound = _SNDOPEN("scorecount.ogg", "SYNC")
END SUB

'------------------------------------------------------------------------------
SUB ScreenSetup
GameScreen = _NEWIMAGE(400, 300, 32)
MainScreen = _NEWIMAGE(800, 600, 32)
SCREEN MainScreen
_TITLE "Frostbite Tribute"

GroundH = _HEIGHT(GameScreen) / 3 '1/3 of the GameScreen
WaterH = (_HEIGHT(GameScreen) / 3) * 2 '2/3 of the GameScreen
SkyH = GroundH / 3 '1/3 of GroundH
CreditsBarH = _HEIGHT(GameScreen) / 15 '1/11 of the GameScreen
AuroraH = SkyH / 4

ThisAurora = _NEWIMAGE(_WIDTH, AuroraH, 32)

CreditsIMG = _NEWIMAGE(_WIDTH(GameScreen), 40, 32)
_DEST CreditsIMG
_FONT 16
COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
_PRINTSTRING (10, 0), "Copyleft 2015, Fellippe Heitor. ENTER to start."
FOR I = 22 TO 31
    LINE (0, I)-(20, I), Aurora(_CEIL(RND * 7))
NEXT I
_PRINTSTRING (20, 20), "Frostbite Tribute"
CreditY = -2

_DEST GameScreen
_FONT 8

END SUB

'------------------------------------------------------------------------------
SUB RestoreData
RESTORE AuroraColors
FOR I = 1 TO 7
    READ AuroraR, AuroraG, AuroraB
    Aurora(I) = _RGB32(AuroraR, AuroraG, AuroraB)
NEXT I

RESTORE IceRowsDATA
FOR I = 1 TO 4
    READ IceRows(I)
NEXT I
END SUB

'------------------------------------------------------------------------------
SUB SpritesSetup
DIM ColorIndex AS INTEGER
DIM ColorsInPalette AS INTEGER
DIM SpritePalette(0) AS _UNSIGNED LONG
DIM i AS INTEGER

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

END SUB

'------------------------------------------------------------------------------
SUB LoadSprite (ImageHandle AS LONG, ImageWidth AS INTEGER, ImageHeight AS INTEGER, SpritePalette() AS LONG)
'Loads a sprite from DATA fields
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
RANDOMIZE TIMER

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
    IF IglooBlockCountSound THEN _SNDPLAYCOPY (IglooBlockCountSound)
    Score = Score + (Level * 10)
    IglooPieces = IglooPieces - 1
END IF

'Calculate points for each degree remaining
IF IglooPieces = 0 AND Temperature > 0 THEN
    IF ScoreCountSound THEN _SNDPLAYCOPY (ScoreCountSound)
    Score = Score + (10 * Level)
    Temperature = Temperature - 1
END IF

IF IglooPieces = 0 AND Temperature = 0 THEN SetLevel NEXTLEVEL
END SUB


