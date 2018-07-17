'Frosbite Tribute
'A clone of Frostbite for the Atari 2600, originally designed
'by Steve Cartwright and published by Activition in 1983.
'
'Fellippe Heitor / @FellippeHeitor / fellippeheitor@gmail.com
'
' - Beta 1: November 30th, 2015:
'    - Screen layout, with aurora and logo on the bottom.
'    - Ripped sprites from youtube gameplays.
'    - Can move around, jump up and down. Still walks on
'      water, though.
'
' - Beta 2:
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

CONST HeroHeight = 36
CONST HeroWidth = 30

TYPE RowInfo
    Position AS INTEGER
    Direction AS INTEGER
    State AS _BYTE
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
DIM SHARED Temperature AS _BYTE, TempTimer AS INTEGER
DIM SHARED Score AS LONG
DIM SHARED GameOver AS _BIT
DIM SHARED Aurora(1 TO 7) AS LONG, ThisAurora AS LONG, AuroraTimer AS INTEGER
DIM SHARED IceRow(1 TO 4) AS RowInfo, BlockType AS _BYTE
DIM SHARED Hero AS HeroInfo
DIM SHARED Lives AS INTEGER
DIM SHARED LevelSpeed AS INTEGER
DIM SHARED InGame AS _BYTE
DIM SHARED Credits AS LONG, CreditY AS INTEGER, CreditCount AS INTEGER
DIM SHARED HeroSprites(1 TO 3) AS LONG
DIM SHARED JumpStep AS INTEGER
DIM SHARED GroundH AS INTEGER
DIM SHARED WaterH AS INTEGER
DIM SHARED SkyH AS INTEGER
DIM SHARED CreditsBarH AS INTEGER
DIM SHARED AuroraH AS INTEGER

DIM i AS LONG
DIM k AS INTEGER
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

SpriteSheet = _LOADIMAGE("fbsprites.png", 32)
IF SpriteSheet < -1 THEN
    _SETALPHA 0, _RGB32(255, 0, 255), SpriteSheet
    FOR i = 0 TO 2
        HeroSprites(i + 1) = _NEWIMAGE(30, 36, 32)
        _PUTIMAGE (0, 0), SpriteSheet, HeroSprites(i + 1), (i * 30, 0)-STEP(30, 36)
    NEXT i
    _FREEIMAGE SpriteSheet
ELSE
    PRINT "Game files not found."
    END
END IF

_DEST GameScreen

Temperature = 45
Lives = 3
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
Hero.Y = 95
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

Credits = _NEWIMAGE(_WIDTH(GameScreen), 40, 32)
_DEST Credits
_FONT 16
COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
_PRINTSTRING (10, 0), "Copyleft 2015, Fellippe Heitor"
FOR i = 22 TO 31
    LINE (0, i)-(20, i), Aurora(_CEIL(RND * 7))
NEXT i
_PRINTSTRING (20, 20), "Frostbite Tribute"

_DEST GameScreen
_FONT 8


TempTimer = _FREETIMER
ON TIMER(TempTimer, 1) DecreaseTemperature

AuroraTimer = _FREETIMER
ON TIMER(AuroraTimer, .3) UpdateAurora
TIMER(AuroraTimer) ON

RANDOMIZE TIMER
DO: _LIMIT 20
    LINE (0, 0)-STEP(_WIDTH, GroundH), _RGB32(192, 192, 192), BF 'Ground
    LINE (0, 0)-STEP(_WIDTH, SkyH), _RGB32(37, 54, 189), BF 'Sky
    LINE (0, GroundH - 2)-STEP(_WIDTH, 3), _RGB32(0, 0, 0), BF 'Black separator
    LINE (0, GroundH + 2)-STEP(_WIDTH, WaterH), _RGB32(0, 27, 141), BF 'Water
    _PUTIMAGE (0, SkyH - AuroraH), ThisAurora, GameScreen
    LINE (0, _HEIGHT - CreditsBarH)-STEP(_WIDTH, CreditsBarH), _RGB32(0, 0, 0), BF 'Credits bar
    _PUTIMAGE (0, _HEIGHT - CreditsBarH), Credits, GameScreen, (0, CreditY)-STEP(_WIDTH(Credits), CreditsBarH)

    COLOR _RGB32(126, 148, 254), _RGBA32(0, 0, 0, 0)
    _PRINTSTRING (72 - (LEN(TRIM$(Score)) * _FONTWIDTH), 2), TRIM$(Score)
    _PRINTSTRING (40 - (LEN(TRIM$(Temperature)) * _FONTWIDTH), 14), TRIM$(Temperature) + CHR$(248)
    _PRINTSTRING (72 - (LEN(TRIM$(Lives)) * _FONTWIDTH), 14), TRIM$(Lives)

    crd$ = "Hero.X=" + TRIM$(Hero.X) + " Hero.Y=" + TRIM$(Hero.Y)
    _PRINTSTRING (_WIDTH - (LEN(crd$) * _FONTWIDTH), 14), crd$

    'Ice blocks:
    FOR i = 1 TO 4
        IF InGame THEN
            IceRow(i).Position = IceRow(i).Position + LevelSpeed * IceRow(i).Direction
        END IF
    NEXT i

    'Hero:
    Hero.X = Hero.X + Hero.Direction * 3
    SELECT CASE Hero.Action
        CASE WALKING
            IF Hero.Frame = 1 THEN Hero.Frame = 2 ELSE Hero.Frame = 1
        CASE JUMPINGUP
            IF Hero.CurrentRow = 0 THEN Hero.Action = WALKING ELSE JumpStep = JumpStep + 1
            SELECT CASE JumpStep
                CASE 1 TO 6
                    Hero.Y = Hero.Y - 8
                    Hero.Frame = 3
                CASE 7 TO 9
                    Hero.Y = Hero.Y + 3
                    Hero.Frame = 1
                CASE 10
                    Hero.CurrentRow = Hero.CurrentRow - 1
                    Hero.Action = STOPPED: Hero.Direction = Hero.Action
            END SELECT
        CASE JUMPINGDOWN
            IF Hero.CurrentRow = 4 THEN Hero.Action = WALKING ELSE JumpStep = JumpStep + 1
            SELECT CASE JumpStep
                CASE 1 TO 3
                    Hero.Y = Hero.Y - 3
                    Hero.Frame = 3
                CASE 4 TO 9
                    Hero.Y = Hero.Y + 8
                    Hero.Frame = 1
                CASE 10
                    Hero.CurrentRow = Hero.CurrentRow + 1
                    Hero.Action = STOPPED: Hero.Direction = Hero.Action
            END SELECT
        CASE STOPPED
            Hero.Frame = 1
    END SELECT

    IF Hero.X + HeroWidth > _WIDTH THEN Hero.X = _WIDTH - HeroWidth
    IF Hero.X < 0 THEN Hero.X = 0

    SELECT CASE Hero.Face
        CASE MOVINGRIGHT
            _PUTIMAGE (Hero.X, Hero.Y - HeroHeight), HeroSprites(Hero.Frame), GameScreen
        CASE MOVINGLEFT
            _PUTIMAGE (Hero.X + HeroWidth, Hero.Y - HeroHeight)-STEP(-HeroWidth, HeroHeight), HeroSprites(Hero.Frame), GameScreen
    END SELECT

    'LINE (Hero.X, Hero.Y - HeroHeight)-STEP(HeroWidth, HeroHeight), _RGB32(0, 0, 0), B

    UpdateScreen

    k = _KEYHIT
    IF k = 13 THEN InGame = True: TIMER(TempTimer) ON
    IF k = 27 THEN EXIT DO

    ReadKeyboard
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

'------------------------------------------------------------------------------
'Subprocedures start here:
'------------------------------------------------------------------------------
SUB ReadKeyboard
IF Hero.Action = WALKING THEN Hero.Action = STOPPED: Hero.Direction = Hero.Action
IF ScanKey%(75) THEN Hero.Direction = MOVINGLEFT: Hero.Face = Hero.Direction: IF Hero.Action = STOPPED THEN Hero.Action = WALKING
IF ScanKey%(77) THEN Hero.Direction = MOVINGRIGHT: Hero.Face = Hero.Direction: IF Hero.Action = STOPPED THEN Hero.Action = WALKING
IF ScanKey%(72) AND Hero.CurrentRow > 0 THEN IF Hero.Action = WALKING OR Hero.Action = STOPPED THEN Hero.Action = JUMPINGUP: JumpStep = 0
IF ScanKey%(80) AND Hero.CurrentRow < 4 THEN IF Hero.Action = WALKING OR Hero.Action = STOPPED THEN Hero.Action = JUMPINGDOWN: JumpStep = 0
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
    GameOver = True
    TIMER(TempTimer) OFF
END IF
END SUB

'------------------------------------------------------------------------------
FUNCTION TRIM$ (Value)
TRIM$ = LTRIM$(RTRIM$(STR$(Value)))
END FUNCTION

'------------------------------------------------------------------------------
SUB UpdateAurora
DIM PrevDest AS LONG, i AS _BYTE

PrevDest = _DEST
_DEST ThisAurora
FOR i = 1 TO AuroraH
    LINE (0, 0)-STEP(_WIDTH(ThisAurora), AuroraH - i), Aurora(_CEIL(RND * 7)), BF 'Aurora
NEXT i
_DEST PrevDest

IF NOT InGame THEN
    IF CreditY > 16 THEN CreditCount = CreditCount + 1 ELSE CreditY = CreditY + 1
    IF CreditCount > 30 THEN CreditCount = 0: CreditY = 0
ELSE
    CreditY = 17
END IF
END SUB

'------------------------------------------------------------------------------
FUNCTION ScanKey% (scancode%)
STATIC Ready%, keyflags%()
IF NOT Ready% THEN REDIM keyflags%(0 TO 127): Ready% = -1
i% = INP(&H60) 'read keyboard states
IF (i% AND 128) THEN keyflags%(i% XOR 128) = 0
IF (i% AND 128) = 0 THEN keyflags%(i%) = -1
K$ = INKEY$
ScanKey% = keyflags%(scancode%)
END FUNCTION

