'Frosbite Tribute
'A clone of Frostbite for the Atari 2600, originally designed
'by Steve Cartwright and published by Activition in 1983.
'
'Fellippe Heitor / @FellippeHeitor / fellippeheitor@gmail.com
'
' - Beta 1: November 30th, 2015:
'    - Screen layout, with aurora and logo on the bottom.
'    - Ripped hero sprites from youtube gameplays.
'    - Can move around, jump up and down. Still walks on
'      water, though.
'
' - Beta 2:
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
' - Beta 3:
'    - Ripped audio effects. Not required for gameplay, though.
'    - Added a .MirroredPosition variable to IceRows, which
'      now allows the hero to step on any ice block he sees
'      fit.
'    - When temperature reaches 0 degrees, hero loses a life by
'      freezing to death.
'    - Moved drawing routines to subprocedures, to make reading
'      easier.
'
$RESIZE:SMOOTH

CONST True = -1
CONST False = NOT True

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

CONST HeroStartRow = 95
CONST HeroHeight = 36
CONST HeroWidth = 30

CONST InitialTemperature = 45

CONST NewBlockColor = _RGB32(208, 208, 208)
CONST OldBlockColor = _RGB32(73, 134, 213)

TYPE RowInfo
    Position AS INTEGER
    MirroredPosition AS INTEGER
    Direction AS INTEGER
    State AS _BYTE 'True when row has been stepped on
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

DIM SHARED GameScreen AS LONG, MainScreen AS LONG
DIM SHARED Temperature AS INTEGER, TempTimer AS INTEGER
DIM SHARED Score AS LONG
DIM SHARED GameOver AS _BIT
DIM SHARED Aurora(1 TO 7) AS LONG, ThisAurora AS LONG, FramesTimer AS INTEGER
DIM SHARED IceRow(1 TO 4) AS RowInfo, BlockType AS _BYTE, ThisRowColor AS LONG
DIM SHARED Hero AS HeroInfo
DIM SHARED Lives AS INTEGER
DIM SHARED LevelSpeed AS INTEGER
DIM SHARED Level AS INTEGER
DIM SHARED InGame AS _BYTE
DIM SHARED CreditsIMG AS LONG, CreditY AS INTEGER
DIM SHARED HeroSprites(1 TO 4) AS LONG
DIM SHARED AnimationStep AS INTEGER
DIM SHARED GroundH AS INTEGER
DIM SHARED WaterH AS INTEGER
DIM SHARED SkyH AS INTEGER
DIM SHARED CreditsBarH AS INTEGER
DIM SHARED AuroraH AS INTEGER
DIM SHARED BlockRows(1 TO 4) AS INTEGER
DIM SHARED JustLanded AS _BIT
DIM SHARED Safe AS _BIT
DIM SHARED RestoreRowsTimer AS SINGLE
DIM SHARED TemperatureBlink AS INTEGER
DIM SHARED HeroFreezingSprite AS LONG

'Sounds
DIM SHARED JumpSound AS LONG
DIM SHARED BlockSound AS LONG
DIM SHARED DrowningSound AS LONG

JumpSound = _SNDOPEN("jump.ogg", "SYNC")
BlockSound = _SNDOPEN("block.ogg", "SYNC")
DrowningSound = _SNDOPEN("drowning.ogg", "SYNC")

DIM i AS LONG
DIM SpriteSheet AS LONG

GameScreen = _NEWIMAGE(400, 300, 32)
MainScreen = _NEWIMAGE(800, 600, 32)
SCREEN MainScreen

_TITLE "Frostbite Tribute"

RESTORE AuroraColors
FOR i = 1 TO 7
    READ AuroraR, AuroraG, AuroraB
    Aurora(i) = _RGB32(AuroraR, AuroraG, AuroraB)
NEXT i

RESTORE BlockRowsDATA
FOR i = 1 TO 4
    READ BlockRows(i)
NEXT i

SpriteSheet = _LOADIMAGE("fbsprites.png", 32)
IF SpriteSheet < -1 THEN
    _SETALPHA 0, _RGB32(255, 0, 255), SpriteSheet
    FOR i = 0 TO 3
        HeroSprites(i + 1) = _NEWIMAGE(30, 36, 32)
        _PUTIMAGE (0, 0), SpriteSheet, HeroSprites(i + 1), (i * 30, 0)-STEP(30, 36)
    NEXT i
    _FREEIMAGE SpriteSheet
ELSE
    PRINT "Game files not found."
    END
END IF

_DEST GameScreen

Temperature = InitialTemperature
Lives = 3
Level = 1
LevelSpeed = 1
BlockType = SINGLEBLOCK

IceRow(1).Position = 90
IceRow(1).Direction = MOVINGLEFT
IceRow(2).Position = 10
IceRow(2).Direction = MOVINGRIGHT
IceRow(3).Position = 90
IceRow(3).Direction = MOVINGLEFT
IceRow(4).Position = 10
IceRow(4).Direction = MOVINGRIGHT

Hero.CurrentRow = 0
Hero.X = 100
Hero.Y = HeroStartRow
Hero.Direction = STOPPED
Hero.Face = MOVINGRIGHT
Hero.Action = STOPPED
Hero.Frame = 1

GroundH = _HEIGHT / 3 '1/3 of the GameScreen
WaterH = (_HEIGHT / 3) * 2 '2/3 of the GameScreen
SkyH = GroundH / 3 '1/3 of GroundH
CreditsBarH = _HEIGHT / 15 '1/11 of the GameScreen
AuroraH = SkyH / 4

ThisAurora = _NEWIMAGE(_WIDTH, AuroraH, 32)

CreditsIMG = _NEWIMAGE(_WIDTH(GameScreen), 40, 32)
_DEST CreditsIMG
_FONT 16
COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
_PRINTSTRING (10, 0), "Copyleft 2015, Fellippe Heitor. ENTER to start."
FOR i = 22 TO 31
    LINE (0, i)-(20, i), Aurora(_CEIL(RND * 7))
NEXT i
_PRINTSTRING (20, 20), "Frostbite Tribute"
CreditY = -2

_DEST GameScreen
_FONT 8


TempTimer = _FREETIMER
ON TIMER(TempTimer, 1) DecreaseTemperature

FramesTimer = _FREETIMER
ON TIMER(FramesTimer, .1) UpdateFrames
TIMER(FramesTimer) ON

RANDOMIZE TIMER

'Main game loop: --------------------------------------------------------------
DO: _LIMIT 24 'Feeling cinematic.
    DrawScenery
    MoveIceBlocks
    MoveHero
    CheckLanding

    UpdateScreen

    ReadKeyboard
    '_DELAY .035
LOOP UNTIL GameOver
END

AuroraColors:
DATA 207,199,87
DATA 208,161,62
DATA 199,141,54
DATA 210,95,110
DATA 183,101,193
DATA 157,111,224
DATA 120,116,237

BlockRowsDATA:
DATA 134,173,212,251

'------------------------------------------------------------------------------
'Subprocedures start here:
'------------------------------------------------------------------------------
SUB DrawScenery
LINE (0, 0)-STEP(_WIDTH, GroundH), _RGB32(192, 192, 192), BF 'Ground
LINE (0, 0)-STEP(_WIDTH, SkyH), _RGB32(37, 54, 189), BF 'Sky
LINE (0, GroundH - 2)-STEP(_WIDTH, 3), _RGB32(0, 0, 0), BF 'Black separator
LINE (0, GroundH + 2)-STEP(_WIDTH, WaterH), _RGB32(0, 27, 141), BF 'Water
_PUTIMAGE (0, SkyH - AuroraH), ThisAurora, GameScreen
LINE (0, _HEIGHT - CreditsBarH)-STEP(_WIDTH, CreditsBarH), _RGB32(0, 0, 0), BF 'Credits bar
_PUTIMAGE (0, _HEIGHT - CreditsBarH), CreditsIMG, GameScreen, (0, CreditY)-STEP(_WIDTH(CreditsIMG), CreditsBarH)

COLOR _RGB32(126, 148, 254), _RGBA32(0, 0, 0, 0)
_PRINTSTRING (72 - (LEN(TRIM$(Score)) * _FONTWIDTH), 2), TRIM$(Score)
SELECT CASE Temperature
    CASE 0 TO 5
        TemperatureBlink = TemperatureBlink + 1
        IF INT(TemperatureBlink / 2) <> TemperatureBlink / 2 THEN
            COLOR _RGBA32(0, 0, 0, 0), _RGBA32(0, 0, 0, 0)
        END IF
    CASE ELSE
        TemperatureBlink = 0
END SELECT
_PRINTSTRING (72 - (LEN(TRIM$(Lives)) * _FONTWIDTH), 14), TRIM$(Lives)
_PRINTSTRING (40 - (LEN(TRIM$(Temperature)) * _FONTWIDTH), 14), TRIM$(Temperature) + CHR$(248)

'For debugging/testing purposes:
'crd$ = "Hero.X=" + TRIM$(Hero.X) + " Hero.Y=" + TRIM$(Hero.Y)
'_PRINTSTRING (_WIDTH - (LEN(crd$) * _FONTWIDTH), 14), crd$
END SUB

'------------------------------------------------------------------------------
SUB MoveIceBlocks
'Ice blocks:
FOR i = 1 TO 4
    IF NOT IceRow(i).State THEN ThisRowColor = NewBlockColor ELSE ThisRowColor = OldBlockColor
    SELECT CASE BlockType
        CASE SINGLEBLOCK
            RowWidth = HeroWidth * 9

            IF InGame AND Hero.Action <> DROWNING AND Hero.Action <> FREEZING THEN
                IceRow(i).Position = IceRow(i).Position + LevelSpeed * IceRow(i).Direction
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

            'Draw normal blocks
            LINE (IceRow(i).Position, BlockRows(i))-STEP(HeroWidth * 2, 0), ThisRowColor
            LINE (IceRow(i).Position + HeroWidth * 3.5, BlockRows(i))-STEP(HeroWidth * 2, 0), ThisRowColor
            LINE (IceRow(i).Position + HeroWidth * 7, BlockRows(i))-STEP(HeroWidth * 2, 0), ThisRowColor

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
                LINE (IceRow(i).MirroredPosition, BlockRows(i))-STEP(HeroWidth * 2, 0), ThisRowColor
                LINE (IceRow(i).MirroredPosition + HeroWidth * 3.5, BlockRows(i))-STEP(HeroWidth * 2, 0), ThisRowColor
                LINE (IceRow(i).MirroredPosition + HeroWidth * 7, BlockRows(i))-STEP(HeroWidth * 2, 0), ThisRowColor
            END IF
        CASE DOUBLEBLOCK
        CASE MOVINGBLOCK
    END SELECT
NEXT i
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
                CASE 7 TO 9
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
                CASE 4 TO 6
                CASE 7 TO 12
                    Hero.Y = Hero.Y + 8
                    Hero.Frame = 1
                CASE 13
                    Hero.CurrentRow = Hero.CurrentRow + 1
                    JustLanded = True
                    Hero.Action = STOPPED: Hero.Direction = Hero.Action
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
                    ELSE
                        TIMER(TempTimer) ON
                        Hero.CurrentRow = 0
                        Hero.X = 100
                        Hero.Y = HeroStartRow
                        Hero.Direction = STOPPED
                        Hero.Face = MOVINGRIGHT
                        Hero.Action = STOPPED
                        Hero.Frame = 1
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
                    _PUTIMAGE (Hero.X, Hero.Y - HeroHeight)-STEP(HeroWidth, HeroHeight), HeroFreezingSprite, GameScreen
                CASE 6 TO 10
                    _PUTIMAGE (Hero.X + HeroWidth, Hero.Y - HeroHeight)-STEP(-HeroWidth, HeroHeight), HeroFreezingSprite, GameScreen
                CASE 40
                    _FREEIMAGE HeroFreezingSprite
                    IF Lives = 0 THEN
                        GameOver = True
                    ELSE
                        TIMER(TempTimer) ON
                        Temperature = InitialTemperature
                        Hero.CurrentRow = 0
                        Hero.X = 100
                        Hero.Y = HeroStartRow
                        Hero.Direction = STOPPED
                        Hero.Face = MOVINGRIGHT
                        Hero.Action = STOPPED
                        Hero.Frame = 1
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
            IF BlockSound THEN _SNDPLAYCOPY (BlockSound)
            JustLanded = False
            IceRow(Hero.CurrentRow).State = True
            RestoreRowsTimer = TIMER
            Score = Score + Level * 10
        END IF
    END IF
END IF
END SUB

'------------------------------------------------------------------------------
SUB ReadKeyboard
DIM k AS INTEGER
k = _KEYHIT
IF k = 13 THEN InGame = True: TIMER(TempTimer) ON
IF k = 32 AND Hero.CurrentRow > 0 AND (Hero.Action = STOPPED OR Hero.Action = WALKING) AND InGame THEN
    IF IceRow(Hero.CurrentRow).Direction = MOVINGRIGHT THEN
        IceRow(Hero.CurrentRow).Direction = MOVINGLEFT
        IF IceRow(Hero.CurrentRow).MirroredPosition THEN SWAP IceRow(Hero.CurrentRow).Position, IceRow(Hero.CurrentRow).MirroredPosition
    ELSE
        IceRow(Hero.CurrentRow).Direction = MOVINGRIGHT
        IF IceRow(Hero.CurrentRow).MirroredPosition THEN SWAP IceRow(Hero.CurrentRow).Position, IceRow(Hero.CurrentRow).MirroredPosition
    END IF
END IF

IF NOT InGame OR Hero.Action = DROWNING OR Hero.Action = FREEZING THEN EXIT SUB
IF Hero.Action = WALKING THEN Hero.Action = STOPPED: Hero.Direction = Hero.Action

IF _KEYDOWN(19200) THEN Hero.Direction = MOVINGLEFT: Hero.Face = Hero.Direction: IF Hero.Action = STOPPED THEN Hero.Action = WALKING
IF _KEYDOWN(19712) THEN Hero.Direction = MOVINGRIGHT: Hero.Face = Hero.Direction: IF Hero.Action = STOPPED THEN Hero.Action = WALKING
IF _KEYDOWN(18432) AND Hero.CurrentRow > 0 AND (Hero.Action = STOPPED OR Hero.Action = WALKING) THEN
    IF Hero.Action = WALKING OR Hero.Action = STOPPED THEN Hero.Action = JUMPINGUP: AnimationStep = 0
    IF JumpSound THEN _SNDPLAYCOPY (JumpSound)
END IF
IF _KEYDOWN(20480) AND Hero.CurrentRow < 4 AND (Hero.Action = STOPPED OR Hero.Action = WALKING) THEN
    IF Hero.Action = WALKING OR Hero.Action = STOPPED THEN Hero.Action = JUMPINGDOWN: AnimationStep = 0
    IF JumpSound THEN _SNDPLAYCOPY (JumpSound)
END IF
END SUB

'------------------------------------------------------------------------------
SUB UpdateScreen
_PUTIMAGE , GameScreen, MainScreen
_DISPLAY
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
                IF CreditCount > 15 THEN
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

IF IceRow(1).State AND IceRow(2).State AND IceRow(3).State AND IceRow(4).State AND NOT IglooFinished THEN
    IF TIMER - RestoreRowsTimer > .3 THEN
        FOR i = 1 TO 4
            IceRow(i).State = False
        NEXT i
    END IF
END IF

END SUB
