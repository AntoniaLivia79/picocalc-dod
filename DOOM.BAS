' =====================================================================
'  DUNGEON OF DOOM  --  GAME MODULE                       DOOM.BAS
'  PicoMite BASIC port for the PicoCalc (320 x 320)
'
'  Ported from the BBC BASIC listing in Usborne's
'  "Write Your Own Fantasy Games For Your Microcomputer".
'
'  Run DUNGEN.BAS and CHARGEN.BAS first.
'
'  The BBC original was real time: it polled the keyboard without
'  waiting, so monsters kept moving whether you pressed anything or
'  not.  A Pico runs that loop far too fast, so TICKMS below paces it.
' =====================================================================


Option Explicit
Option Default Float


' ------------------------------------------------- tuning ----------
Dim Integer TICKMS   = 120   ' length of one game tick in milliseconds
Dim Integer FIXMISS  = 1     ' 1 = "MISSED!" really does no damage
Dim Integer FIXFLAIL = 1     ' 1 = the flail adds to your attack
Dim Integer FIXMOVE  = 1     ' 1 = monsters can close in from any side
Dim Integer NEEDEXP  = 0     ' 1 = restore the book's experience gate
Dim Integer MSPEED   = 2     ' monster speed 1=slow 2=normal 3=fast
Dim Integer TONEMS   = 40
Dim Integer NOISEMS  = 30


Dim DPATH$ = "B:/picomite/games/rpg/DOOM"
Dim SPATH$ = "B:/picomite/games/rpg/DOOM/SAVE"


' ------------------------------------------------- tile codes ------
Dim Integer C0 = 230, C1 = 231, C2 = 232, C3 = 233, C4 = 234
Dim Integer CW = 235, C5 = 236, C6 = 237, C7 = 238


' ------------------------------------------------- geometry --------
Dim Integer TW = 16          ' one dungeon square in pixels
Dim Integer MAPX = 0, MAPY = 16
Dim Integer PANX = 242
Dim Integer YMSG = 258, YSTA = 274, YHRO = 290, YKEY = 306


' ------------------------------------------------- colours ---------
Dim Integer CBG, CFLOOR, CWALL, CMORT, CTBAR, CTTXT
Dim Integer CPBG, CPLAB, CPVAL, CHERO, CBBG, CBTXT, CMSGC
CBG    = RGB(0,0,0)
CFLOOR = RGB(26,28,38)
CWALL  = RGB(112,102,90)
CMORT  = RGB(58,52,46)
CTBAR  = RGB(80,16,16)
CTTXT  = RGB(255,225,150)
CPBG   = RGB(10,14,40)
CPLAB  = RGB(120,160,220)
CPVAL  = RGB(255,255,255)
CHERO  = RGB(255,215,70)
CBBG   = RGB(16,16,20)
CBTXT  = RGB(190,195,205)
CMSGC  = RGB(255,240,180)


Dim Integer TCOL(17)


' ------------------------------------------------- state -----------
Dim Integer R(15,15), SEEN(15,15), TVIS(15,15)
Dim F(8)                     ' 1 STR 2 VIT 3 AGI 4 INT 5 EXP 6 LCK 7 AUR 8 MOR
Dim Integer OBJ(24)
Dim SPL(6)                   ' spell charges
Dim PRY(3)                   ' prayer charges (cleric only)
Dim LCKBOOST, LCKTTL         ' Fortune prayer: bonus and remaining ticks
' TUNE() was T() in the original, but MMBasic will not allow T and T$
' to coexist as different types
Dim Integer D(4,2), TUNE(18), GLY(17,7), BMASK(7), CHAOS(6)
Dim W$(11), T$(12), FLDC$(12)


Dim Integer NX, NY, OX, OY, NF, RH, LASTRH, TX, TY, TF
Dim Integer MX, MY, LX, LY, MT, MS, SX, SY, DX, DY, MSTR, MB
Dim Integer TR, GC, LT, LE, FI, QUIT, IX, IY, NLEV, SNDOK
Dim S1, S2, S3, H, MV, MSTEP
Dim Integer I, J, X, Y, SL
Dim HERO$, CLASS$, MSG$, IK$, K$
Dim TICK


Randomize Timer
Restore


' ------------------------------------------------- tables ----------
Data "GR SWORD","SWORD","AXE","MACE","FLAIL","DAGGER","ARMOUR","ARMOUR"
Data "ARMOUR","HELMET","HEADPC."
For I = 1 To 11 : Read W$(I) : Next I


Data "A GOOD BLOW","WELL HIT SIRE","THY AIM IS TRUE","MISSED!","HIT THEE!!"
Data "THE MONSTER IS SLAIN","NO LIGHT","BROKEN THY","SPELL EXHAUSTED"
Data "PRESS ANY KEY","YOU NEED EXPERIENCE","EXIT FROM THIS LEVEL"
For I = 1 To 12 : Read T$(I) : Next I


Data 0,-1, 1,0, 0,1, -1,0
For I = 1 To 4 : Read D(I,1), D(I,2) : Next I


Data 69,117,73,121,81,129,69,117,73,121,81,129,89,137,97,145,101,149
For I = 1 To 18 : Read TUNE(I) : Next I


' the eighteen user defined characters of the original, 8 x 8 each
Data 255,255,255,255,255,255,255,255      ' 224 solid block
Data 56,56,16,56,84,16,40,68              ' 225 hero facing north
Data 28,28,8,30,40,40,20,18               ' 226 hero facing east
Data 56,56,16,84,56,40,68,40              ' 227 hero facing south
Data 56,56,16,120,148,20,40,72            ' 228 hero facing west
Data 0,0,0,0,8,209,254,221                ' 229 hero fallen
Data 0,0,0,0,0,0,0,0                      ' 230 floor
Data 85,170,85,170,85,170,85,170          ' 231 wall
Data 0,60,24,60,126,126,126,60            ' 232 flask
Data 0,56,100,114,95,73,41,31             ' 233 treasure
Data 20,42,20,20,93,93,62,99              ' 234 the quest object
Data 60,126,255,255,255,253,255,255       ' 235 way in
Data 60,102,195,129,129,129,133,129       ' 236 stair down
Data 129,66,36,0,0,36,66,129              ' 237 trap
Data 0,60,66,66,66,66,60,0                ' 238 magic circle
Data 76,158,170,190,84,30,37,88           ' 239 monster, weakest
Data 0,56,84,124,56,44,68,102             ' 240 monster
Data 0,8,28,42,127,85,65,34               ' 241 monster, worst
For I = 0 To 17
  For J = 0 To 7 : Read GLY(I,J) : Next J
Next I


For I = 0 To 7 : BMASK(I) = 2 ^ (7 - I) : Next I


' harmless tiles the chaos spell may churn through
CHAOS(1) = C0 : CHAOS(2) = C1 : CHAOS(3) = C2
CHAOS(4) = C3 : CHAOS(5) = C6 : CHAOS(6) = C7


For I = 0 To 17 : TCOL(I) = RGB(200,200,200) : Next I
TCOL(8)  = RGB(80,230,230)      ' flask
TCOL(9)  = RGB(255,205,40)      ' treasure
TCOL(10) = RGB(255,110,255)     ' quest object
TCOL(11) = RGB(190,175,130)     ' way in
TCOL(12) = RGB(70,235,110)      ' stair
TCOL(13) = RGB(235,70,60)       ' trap
TCOL(14) = RGB(150,200,255)     ' magic circle
TCOL(15) = RGB(215,80,80)       ' monsters
TCOL(16) = RGB(240,150,50)
TCOL(17) = RGB(200,100,240)


' ------------------------------------------------- audio -----------
SNDOK = 1
On Error Skip 1
Play Tone 440, 440, 20
If MM.Errno <> 0 Then SNDOK = 0
On Error Clear
Pause 30


' ------------------------------------------------- start up --------
NLEV = ReadLevelCount()
Splash
LoadGame
Layout
ShowStatus


' =====================================================================
'  THE GAME
' =====================================================================
Do
  TICK = Timer
  IK$ = Arrow$(Inkey$)


  If IK$ = "A" And DX < 255 Then Attack
  If IK$ = "C" And F(7) > 0 And OBJ(17) + OBJ(18) > 0 Then CastSpell
  If IK$ = "G" Then Grab
  If IK$ = "Q" Then Quaff
  If IK$ = "P" And CLASS$ = "CLERIC" Then Pray
  If IK$ = "R" Then Reveal
  If IK$ = "?" Then Lore
  If IK$ = "S" Then
    SaveGame
    Exit Do
  EndIf


  If IK$ = "B" Then NF = NF - 1
  If IK$ = "N" Then NF = NF + 1
  If NF > 4 Then NF = 1
  If NF < 1 Then NF = 4
  If IK$ = "M" Then NX = NX + D(NF,1) : NY = NY + D(NF,2)
  If NY > 15 Then NY = 15
  If NY < 1  Then NY = 1
  If NX < 1  Then NX = 1
  If NX > 15 Then NX = 15


  RH = R(NX,NY)


  ' light the squares next to you, and notice anything living in them
  For Y = NY - 1 To NY + 1
    For X = NX - 1 To NX + 1
      If X > 0 And X < 16 And Y > 0 And Y < 16 Then
        If X <> OX Or Y <> OY Then Look X, Y
      EndIf
    Next X
  Next Y


  ' walls, loose objects and monsters all bar the way
  If RH = C1 Or RH = C2 Or RH = C3 Or RH = C4 Or RH > C7 Then
    Look NX, NY
    NX = OX : NY = OY
    F(1) = F(1) - .03
  EndIf


  If RH = C6 Then TX = NX : TY = NY : TF = 1 : TVIS(NX,NY) = 1
  If TF = 1 Then NX = TX : NY = TY
  If F(1) < S1 * .8 And Dice(8) < F(6) Then TF = 0


  If IK$ <> "" Then F(1) = F(1) * 0.99
  If F(1) < S1 Then F(1) = F(1) + (F(2) / 1100)


  ' Fortune prayer: decay luck boost
  If LCKTTL > 0 Then
    LCKTTL = LCKTTL - 1
    If LCKTTL = 0 Then F(6) = F(6) - LCKBOOST : LCKBOOST = 0
  EndIf


  DrawHero
  ShowStatus
  If OX <> NX Or OY <> NY Then DrawCell OX, OY
  OX = NX : OY = NY


  If DX < 255 Then MonMove


  If F(1) < 1 Then
    Death
    Exit Do
  EndIf
  If FI = 1 Then Exit Do
  If RH = C5 And LASTRH <> C5 Then NextLevel
  LASTRH = RH


  Do While Timer - TICK < TICKMS : Loop
Loop


CLS CBG
Text 160, 150, "FAREWELL", "CT", 1, 2, CTTXT, CBG
End


' =====================================================================
'  DRAWING
' =====================================================================
Sub Layout
  Local Integer i
  CLS CBG
  Box 0, 0, 320, 16, 0, CTBAR, CTBAR
  Text 4, 2, "DUNGEON OF DOOM", "LT", 1, 1, CTTXT, CTBAR
  Box MAPX, MAPY, 240, 240, 0, CBG, CBG
  Box 240, 16, 80, 240, 0, CPBG, CPBG
  Box 0, 256, 320, 64, 0, CBBG, CBBG


  Text PANX, 20,  "STR",  "LT", 1, 1, CPLAB, CPBG
  Text PANX, 54,  "VIT",  "LT", 1, 1, CPLAB, CPBG
  Text PANX, 88,  "AURA", "LT", 1, 1, CPLAB, CPBG
  Text PANX, 122, "FACE", "LT", 1, 1, CPLAB, CPBG
  Text PANX, 156, "EXP",  "LT", 1, 1, CPLAB, CPBG
  Text PANX, 190, "GOLD", "LT", 1, 1, CPLAB, CPBG
  Text PANX, 224, "TRSR", "LT", 1, 1, CPLAB, CPBG


  Text 4, YHRO, Pad$(HERO$ + " THE " + CLASS$, 40), "LT", 1, 1, CHERO, CBBG
  Text 4, YKEY, "A-ATK G-GET C-CAST P-QUAFF R-LOOK S-SAVE", "LT", 1, 1, CBTXT, CBBG
  For i = 0 To 12 : FLDC$(i) = "" : Next i
End Sub


' one 8 x 8 glyph, doubled to 16 x 16, drawn as horizontal runs
Sub DrawGlyph(px As Integer, py As Integer, g As Integer, fc As Integer)
  Local Integer r, b, bits, RUNLEN
  If g < 0 Or g > 17 Then Exit Sub
  For r = 0 To 7
    bits = GLY(g,r)
    If bits <> 0 Then
      b = 0
      Do While b <= 7
        If (bits And BMASK(b)) <> 0 Then
          RUNLEN = 0
          Do While b + RUNLEN <= 7
            If (bits And BMASK(b + RUNLEN)) = 0 Then Exit Do
            RUNLEN = RUNLEN + 1
          Loop
          Box px + b*2, py + r*2, RUNLEN*2, 2, 0, fc, fc
          b = b + RUNLEN
        Else
          b = b + 1
        EndIf
      Loop
    EndIf
  Next r
End Sub


Sub DrawCell(x As Integer, y As Integer)
  Local Integer code, px, py, g
  If x < 1 Or x > 15 Or y < 1 Or y > 15 Then Exit Sub
  code = R(x,y)
  SEEN(x,y) = 1
  px = MAPX + (x-1)*TW
  py = MAPY + (y-1)*TW
  If code = C1 Then
    Box px, py, TW, TW, 0, CWALL, CWALL
    Line px, py, px+TW-1, py, 1, CMORT
    Line px, py+8, px+TW-1, py+8, 1, CMORT
    Line px+4, py+1, px+4, py+7, 1, CMORT
    Line px+12, py+9, px+12, py+TW-1, 1, CMORT
    Exit Sub
  EndIf
  Box px, py, TW, TW, 0, CFLOOR, CFLOOR
  If code = C0 Then Exit Sub
  If code = C6 And TVIS(x,y) = 0 And F(4) <= 6 Then Exit Sub
  g = code - 224
  DrawGlyph px, py, g, TCOL(g)
End Sub


' repaint every square the hero has already lit
Sub Redraw
  Local Integer x, y
  For y = 1 To 15
    For x = 1 To 15
      If SEEN(x,y) = 1 Then DrawCell x, y
    Next x
  Next y
End Sub


Sub DrawHero
  DrawCell NX, NY
  DrawGlyph MAPX + (NX-1)*TW, MAPY + (NY-1)*TW, NF, CHERO
End Sub


' show a square, and wake up anything nasty standing on it
Sub Look(x As Integer, y As Integer)
  Local Integer rm
  DrawCell x, y
  rm = R(x,y)
  If Abs(DX) < 4 Then Exit Sub
  If rm <= C7 Then Exit Sub
  MT = rm : MSTR = MT - C2 : MV = (MSTR / 16) * (MSPEED / 2.0) : MS = MSTR * 6
  DX = 3 : LX = x : LY = y : MSTEP = 0
End Sub


' only repaint a panel field when its text has actually changed,
' otherwise the SPI display flickers at every tick
Sub Fld(n As Integer, x As Integer, y As Integer, s$)
  If s$ <> FLDC$(n) Then
    FLDC$(n) = s$
    Text x, y, s$, "LT", 1, 1, CPVAL, CPBG
  EndIf
End Sub


Sub ShowStatus
  Local Integer att
  Local s$
  ' rounded, not truncated: exertion leaves STR fractionally below its
  ' peak and Int() would flicker the display a whole point low
  Fld 1, PANX, 33,  RPad$(NS$(Int(F(1) + 0.5)), 5)
  Fld 2, PANX, 67,  RPad$(NS$(Int(F(2))), 5)
  Fld 3, PANX, 101, RPad$(NS$(Int(F(7))), 5)
  Fld 4, PANX, 135, RPad$(Mid$("NESW.", NF, 1), 5)
  Fld 5, PANX, 169, RPad$(NS$(Int(F(5))), 5)
  Fld 6, PANX, 203, RPad$(NS$(GC), 5)
  Fld 7, PANX, 237, RPad$(NS$(TR), 5)


  att = Int(F(1) + OBJ(1)+OBJ(2)+OBJ(3)+OBJ(4)+OBJ(5)+OBJ(7)+OBJ(8))
  If FIXFLAIL = 1 Then att = att + OBJ(6)
  s$ = "ATT" + RPad$(NS$(att), 4) + "  SPL" + RPad$(NS$(Int(SPL(1)+SPL(2)+SPL(3)+SPL(4)+SPL(5)+SPL(6))), 3)
  If CLASS$ = "CLERIC" Then
    s$ = s$ + "  PRY" + RPad$(NS$(Int(PRY(1)+PRY(2)+PRY(3))), 3)
  Else
    s$ = s$ + "  LGT" + RPad$(NS$(LT), 3)
  EndIf
  s$ = s$ + "  POT" + RPad$(NS$(OBJ(23)+OBJ(24)), 3)
  If s$ <> FLDC$(8) Then
    FLDC$(8) = s$
    Text 4, YSTA, Pad$(s$, 40), "LT", 1, 1, CBTXT, CBBG
  EndIf


  s$ = "LEVEL " + NS$(LE)
  If NLEV > 0 Then s$ = s$ + " OF " + NS$(NLEV)
  If s$ <> FLDC$(9) Then
    FLDC$(9) = s$
    Text 316, 2, RPad$(s$, 16), "RT", 1, 1, CTTXT, CTBAR
  EndIf
End Sub


' =====================================================================
'  MESSAGES
' =====================================================================
Sub Say(s$)
  Text 4, YMSG, Pad$(s$, 39), "LT", 1, 1, CMSGC, CBBG
End Sub


Sub SayFor(s$)
  Say s$
  Pause 650
  Say ""
End Sub


' =====================================================================
'  SOUND
' =====================================================================
' BBC SOUND pitch values are four units to a semitone with 100 around
' middle C, which converts straight into a frequency.
Sub Snd(p)
  Local f
  If SNDOK = 0 Then Exit Sub
  f = 261.63 * 2 ^ ((p - 100) / 48)
  If f < 40 Then f = 40
  If f > 6000 Then f = 6000
  Play Tone f, f, TONEMS
  Pause TONEMS
End Sub


Sub Nse
  Local f
  If SNDOK = 0 Then Exit Sub
  f = 70 + Rnd * 260
  Play Tone f, f, NOISEMS
  Pause NOISEMS
End Sub


' =====================================================================
'  MONSTERS
' =====================================================================
Sub MonMove
  Local Integer rm, i
  DX = LX - NX : SX = Sgn(DX)
  DY = LY - NY : SY = Sgn(DY)


  If FIXMOVE = 1 Then
    ' MV is under one square a tick, so bank the fractions up
    MSTEP = MSTEP + MV
    If MSTEP >= 1 Then
      MSTEP = MSTEP - 1
      MX = LX - SX : MY = LY - SY
    Else
      MX = LX : MY = LY
    EndIf
  Else
    ' faithful to the listing, where truncation let monsters move
    ' only leftwards and upwards
    MX = Int(LX - MV*SX) : MY = Int(LY - MV*SY)
  EndIf


  If MX < 1 Then MX = 1
  If MX > 15 Then MX = 15
  If MY < 1 Then MY = 1
  If MY > 15 Then MY = 15


  rm = R(MX,MY)
  If (rm > C0 And rm <> MT) Or (Abs(DX) <= 1 And Abs(DY) <= 1) Then
    MX = LX : MY = LY
  EndIf


  R(LX,LY) = C0 : DrawCell LX, LY
  R(MX,MY) = MT : DrawCell MX, MY
  LX = MX : LY = MY


  H = 0
  If Abs(DX) <= 1 And Abs(DY) <= 1 And RH <> C7 Then
    H = MSTR * .5
    Snd H
  EndIf
  If H * 12 < F(6) + F(3) Then Exit Sub


  SayFor T$(5)
  Nse
  H = H / (3 + OBJ(9)+OBJ(10)+OBJ(11)+OBJ(12)+OBJ(13)+OBJ(14))
  F(1) = F(1) - H
  F(2) = F(2) - (H / 101)


  MB = Dice(MSTR)
  Snd MT : Nse
  For i = 1 To 11
    If MB = 1 And OBJ(i) > 0 Then
      OBJ(i) = 0
      SayFor T$(8) + " " + W$(i)
      MB = 0
      Nse : Snd i
    EndIf
  Next i
End Sub


Sub Attack
  Local Integer i
  MSG$ = T$(Dice(3))
  Nse
  H = F(1) + OBJ(1)+OBJ(2)+OBJ(3)+OBJ(4)+OBJ(5)+OBJ(7)+OBJ(8) + Dice(F(6))
  If FIXFLAIL = 1 Then H = H + OBJ(6)
  If F(3) + F(6) < Dice(MSTR) + 2 Then
    MSG$ = T$(4)
    ' the listing said HT=0 here, which cancelled nothing at all
    If FIXMISS = 1 Then H = 0
  EndIf
  MS = MS - H
  SayFor MSG$
  F(1) = F(1) - (H / 100)
  F(5) = F(5) + .05
  If MS < 1 Then MonDies
End Sub


Sub MonDies
  Local Integer j
  DX = 255 : MS = 0
  R(MX,MY) = C0
  F(5) = F(5) + .1
  SayFor T$(6)
  For j = 200 To 150 Step -8
    Snd j : Nse
  Next j
  DrawCell MX, MY
End Sub


' =====================================================================
'  ACTIONS
' =====================================================================
Sub Grab
  Local Integer gx, gy, gt
  gx = NX + D(NF,1) : gy = NY + D(NF,2)
  If gx < 1 Then gx = 1
  If gy < 1 Then gy = 1
  If gx > 15 Then gx = 15
  If gy > 15 Then gy = 15
  gt = R(gx,gy)
  If gt > C1 And gt < C4 Then R(gx,gy) = C0
  If gt = C2 Then
    OBJ(23) = OBJ(23) + 1 : OBJ(24) = OBJ(24) + 1
    MSG$ = "A FLASK, SALVE AND POTION"
  EndIf
  If gt = C3 Then
    TR = TR + 1
    MSG$ = "TREASURE!"
  EndIf
  If gt = C4 Then QuestOver : Exit Sub
  DrawCell gx, gy
  If gt > C1 And gt < C4 Then
    Snd gt : Snd gt + 5
    SayFor MSG$
  EndIf
End Sub


Sub Quaff
  If OBJ(24) > 0 And F(1) < S1 Then
    F(1) = S1 : OBJ(24) = OBJ(24) - 1
    SayFor "VIGOUR RETURNS"
  ElseIf OBJ(23) > 0 And F(2) < S2 Then
    F(2) = S2 : OBJ(23) = OBJ(23) - 1
    SayFor "THE SALVE HEALS THEE"
  EndIf
End Sub


Sub Pray
  Local Integer j, sl2
  Local k$
  Text 4, YMSG, Pad$("1 LIGHT   2 HEAL   3 FORTUNE", 39), "LT", 1, 1, CMSGC, CBBG
  Text 4, YSTA, Pad$("", 39), "LT", 1, 1, CMSGC, CBBG
  Text 4, YHRO, Pad$("WHICH PRAYER?  (0 TO CANCEL)", 40), "LT", 1, 1, CMSGC, CBBG


  Do
    Do
      k$ = Inkey$
      If k$ = "" Then Pause 5
    Loop Until k$ <> ""
    sl2 = Val(k$)
    If sl2 = 0 Then Exit Do
    If sl2 > 3 Then sl2 = -1
  Loop Until sl2 > 0


  FLDC$(8) = "" : FLDC$(0) = ""
  Say ""
  Text 4, YHRO, Pad$(HERO$ + " THE " + CLASS$, 40), "LT", 1, 1, CHERO, CBBG
  ShowStatus
  If sl2 <= 0 Then Exit Sub


  PRY(sl2) = PRY(sl2) - 1
  If PRY(sl2) < 0 Then
    PRY(sl2) = 0
    SayFor "THY PRAYERS ARE SPENT"
    Exit Sub
  EndIf


  Select Case sl2
    Case 1                                  ' light (same as Reveal)
      Local Integer x, y
      For y = NY - 3 To NY + 3
        For x = NX - 3 To NX + 3
          If x > 0 And x < 16 And y > 0 And y < 16 Then Look x, y
        Next x
      Next y
      Snd 200 : Snd 100
      SayFor "THE DARKNESS LIFTS"


    Case 2                                  ' heal (same as Mend spell)
      F(2) = F(2) + Dice(Int(PRY(2)) + 1)
      F(1) = F(1) + Dice(Int(PRY(2)) + 1)
      Snd 80 : Snd 160
      SayFor "THY WOUNDS CLOSE"


    Case 3                                  ' fortune (boost luck)
      If LCKTTL > 0 Then F(6) = F(6) - LCKBOOST
      LCKBOOST = 3 + Dice(3)
      LCKTTL = 20 + Dice(10)
      F(6) = F(6) + LCKBOOST
      Snd 120 : Snd 240
      SayFor "FORTUNE SMILES UPON THEE"
  End Select
End Sub


Sub Reveal
  Local Integer x, y
  If LT = 0 Then SayFor T$(7) : Exit Sub
  For y = NY - 3 To NY + 3
    For x = NX - 3 To NX + 3
      If x > 0 And x < 16 And y > 0 And y < 16 Then Look x, y
    Next x
  Next y
  LT = LT - 1
End Sub


' =====================================================================
'  MAGIC
' =====================================================================
' 1 to 3 come from the Necronomicon, 4 to 6 from the Scrolls, exactly
' as the original's rather odd range tests intended.
Sub CastSpell
  Local Integer j, ex, ey
  Local k$
  Text 4, YMSG, Pad$("1 SMITE   2 WARD    3 TRANSPORT", 39), "LT", 1, 1, CMSGC, CBBG
  Text 4, YSTA, Pad$("4 MEND    5 CHAOS   6 RENEWAL", 39), "LT", 1, 1, CMSGC, CBBG
  Text 4, YHRO, Pad$("USE SPELL NUMBER?  (0 TO THINK BETTER OF IT)", 40), "LT", 1, 1, CMSGC, CBBG


  Do
    Do
      k$ = Inkey$
      If k$ = "" Then Pause 5
    Loop Until k$ <> ""
    SL = Val(k$)
    If SL = 0 Then Exit Do
    If (OBJ(17) = 0 And SL < 5) Or (OBJ(18) = 0 And SL > 3) Or SL > 6 Then SL = -1
  Loop Until SL > 0


  FLDC$(8) = "" : FLDC$(0) = ""
  Say ""
  Text 4, YHRO, Pad$(HERO$ + " THE " + CLASS$, 40), "LT", 1, 1, CHERO, CBBG
  ShowStatus
  If SL <= 0 Then Exit Sub


  SPL(SL) = SPL(SL) - 1
  If SPL(SL) < 0 Then
    MSG$ = T$(9)
    SayFor MSG$
    Exit Sub
  EndIf


  Select Case SL
    Case 1                                  ' smite the beast
      For j = 1 To 12 : Snd j : Nse : Next j
      If DX < 255 Then MonDies


    Case 2                                  ' ward, a circle of safety
      If RH = C0 Then R(NX,NY) = C7
      Snd 100 : Snd 200
      DrawHero


    Case 3                                  ' transport, and take pot luck
      NX = Dice(13) : NY = Dice(13)
      For j = 0 To 255 Step 24 : Nse : Snd j : Next j
      DrawHero


    Case 4                                  ' mend
      F(2) = F(2) + Dice(SPL(SL))
      F(1) = F(1) + Dice(SPL(SL))
      F(7) = F(7) - 1


    Case 5                                  ' chaos, remakes the way ahead
      ex = NX + D(NF,1) : ey = NY + D(NF,2)
      If ex >= 1 And ex <= 15 And ey >= 1 And ey <= 15 Then
        ' the listing flickered through RND(8)+1+C0, which could conjure
        ' the idol or a stairway and left the last one lying there
        For j = 1 To 12
          R(ex,ey) = CHAOS(Dice(6))
          Snd j : DrawCell ex, ey
        Next j
        If DX < 255 And LX = ex And LY = ey Then DX = 255 : MS = 0
        R(ex,ey) = C0
        DrawCell ex, ey
        For j = 1 To 20 Step 4 : Snd j : Next j
      EndIf


    Case 6                                  ' renewal
      F(2) = S2 : F(1) = S1 : F(7) = F(7) - 1
  End Select


  F(5) = F(5) + .2
End Sub


' =====================================================================
'  ENDINGS
' =====================================================================
Sub QuestOver
  Local Integer i, j, sc
  FI = 1
  MS = 0
  sc = Int((TR * 10) + (GC * F(5)) + F(1) + F(2) + F(3))
  For i = 1 To 18
    Snd TUNE(i)
  Next i
  CLS CBG
  Text 160, 40,  "THY QUEST IS OVER!", "CT", 1, 2, CHERO, CBG
  Text 160, 100, HERO$ + " THE " + CLASS$, "CT", 1, 1, CTTXT, CBG
  Text 160, 140, "TREASURE  " + NS$(TR), "CT", 1, 1, CBTXT, CBG
  Text 160, 156, "GOLD      " + NS$(GC), "CT", 1, 1, CBTXT, CBG
  Text 160, 172, "EXPERIENCE " + NS$(Int(F(5))), "CT", 1, 1, CBTXT, CBG
  Text 160, 172 + 16, "LEVELS DELVED " + NS$(LE), "CT", 1, 1, CBTXT, CBG
  Text 160, 230, "THY SCORE = " + NS$(sc), "CT", 1, 2, CHERO, CBG
  Text 160, 290, "PRESS ANY KEY", "CT", 1, 1, CBTXT, CBG
  j = Asc(WaitKey$())
End Sub


Sub Death
  Local Integer j
  NF = 5 : F(1) = 0
  Say ""
  DrawHero
  Text 4, YHRO, Pad$("THOU HAST EXPIRED!", 40), "LT", 1, 1, RGB(255,80,80), CBBG
  For j = 150 To 1 Step -8
    Snd j : Nse
    DrawHero
  Next j
  Pause 800
  CLS CBG
  Text 160, 110, "THOU HAST EXPIRED", "CT", 1, 2, RGB(255,80,80), CBG
  Text 160, 160, HERO$ + " THE " + CLASS$, "CT", 1, 1, CTTXT, CBG
  Text 160, 180, "FELL ON LEVEL " + NS$(LE), "CT", 1, 1, CBTXT, CBG
  Text 160, 240, "PRESS ANY KEY", "CT", 1, 1, CBTXT, CBG
  j = Asc(WaitKey$())
End Sub


' =====================================================================
'  LEVELS
' =====================================================================
' the filename local must not be called f$: a local F of any type
' hides the global F() stats array from the whole sub
Sub NextLevel
  Local fn$
  SayFor T$(12)
  ' lines 1760 and 1920 of the listing were commented out: they refused
  ' the stairs until the hero had earned a point of experience per level
  If NEEDEXP = 1 And F(5) < LE + 1 Then
    SayFor T$(11)
    Exit Sub
  EndIf
  LE = LE + 1
  fn$ = LevelFile$(LE)
  If fn$ = "" Then
    LE = LE - 1
    SayFor "THIS IS THE DEEPEST LEVEL"
    Exit Sub
  EndIf
  Say "DESCENDING TO LEVEL " + NS$(LE)
  LoadLevel LE
  NX = IX : NY = IY : OX = NX : OY = NY
  DX = 255 : TF = 0 : MS = 0 : LASTRH = 0
  Layout
  ShowStatus
  DrawHero
End Sub


' prefer the saved copy of a level, fall back on the freshly dug one
Function LevelFile$(n As Integer)
  Local a$, b$
  a$ = SPATH$ + "/LEVEL" + NS$(n) + ".DAT"
  b$ = DPATH$ + "/LEVEL" + NS$(n) + ".DAT"
  If FileExists(a$) Then
    LevelFile$ = a$
  ElseIf FileExists(b$) Then
    LevelFile$ = b$
  Else
    LevelFile$ = ""
  EndIf
End Function


Sub LoadLevel(n As Integer)
  Local Integer x, y
  Local f$, ln$
  f$ = LevelFile$(n)
  If f$ = "" Then Exit Sub
  For y = 1 To 15
    For x = 1 To 15
      SEEN(x,y) = 0
      TVIS(x,y) = 0
    Next x
  Next y
  Open f$ For Input As #1
  Line Input #1, ln$                      ' DOOMLEV1
  Line Input #1, ln$ : LE = Val(ln$)
  Line Input #1, ln$ : IX = Val(ln$)
  Line Input #1, ln$ : IY = Val(ln$)
  For y = 1 To 15
    Line Input #1, ln$
    For x = 1 To 15
      R(x,y) = TileCode(Mid$(ln$, x, 1))
    Next x
  Next y
  Close #1
End Sub


Sub SaveLevel(n As Integer)
  Local Integer x, y
  Local ln$
  Open SPATH$ + "/LEVEL" + NS$(n) + ".DAT" For Output As #1
  Print #1, "DOOMLEV1"
  Print #1, NS$(n)
  Print #1, NS$(NX)
  Print #1, NS$(NY)
  For y = 1 To 15
    ln$ = ""
    For x = 1 To 15
      ln$ = ln$ + TileChar$(R(x,y))
    Next x
    Print #1, ln$
  Next y
  Close #1
End Sub


Function TileCode(ch$) As Integer
  Local Integer c
  Select Case ch$
    Case "." : c = C0
    Case "#" : c = C1
    Case "!" : c = C2
    Case "$" : c = C3
    Case "&" : c = C4
    Case "*" : c = CW
    Case ">" : c = C5
    Case "^" : c = C6
    Case "O" : c = C7
    Case "a" : c = 239
    Case "b" : c = 240
    Case "c" : c = 241
    Case Else : c = C0
  End Select
  TileCode = c
End Function


Function TileChar$(c As Integer)
  Local ch$
  Select Case c
    Case C0  : ch$ = "."
    Case C1  : ch$ = "#"
    Case C2  : ch$ = "!"
    Case C3  : ch$ = "$"
    Case C4  : ch$ = "&"
    Case CW  : ch$ = "*"
    Case C5  : ch$ = ">"
    Case C6  : ch$ = "^"
    Case C7  : ch$ = "O"
    Case 239 : ch$ = "a"
    Case 240 : ch$ = "b"
    Case 241 : ch$ = "c"
    Case Else : ch$ = "."
  End Select
  TileChar$ = ch$
End Function


Function ReadLevelCount() As Integer
  Local f$, ln$
  Local Integer n
  n = 0
  f$ = DPATH$ + "/DUNGEON.DAT"
  If FileExists(f$) Then
    Open f$ For Input As #1
    Line Input #1, ln$
    Line Input #1, ln$ : n = Val(ln$)
    Close #1
  EndIf
  ReadLevelCount = n
End Function


' =====================================================================
'  HERO FILE
' =====================================================================
Sub LoadHero(fn$)
  Local Integer i
  Local ln$
  Open fn$ For Input As #1
  Line Input #1, ln$                        ' DOOMHERO1
  Line Input #1, HERO$
  Line Input #1, CLASS$
  Line Input #1, ln$ : LE = Val(ln$)
  Line Input #1, ln$ : NX = Val(ln$)
  Line Input #1, ln$ : NY = Val(ln$)
  For i = 1 To 8 : Line Input #1, ln$ : F(i) = Val(ln$) : Next i
  Line Input #1, ln$ : S1 = Val(ln$)
  Line Input #1, ln$ : S2 = Val(ln$)
  Line Input #1, ln$ : S3 = Val(ln$)
  For i = 1 To 24 : Line Input #1, ln$ : OBJ(i) = Val(ln$) : Next i
  Line Input #1, ln$ : GC = Val(ln$)
  Line Input #1, ln$ : TR = Val(ln$)
  For i = 1 To 6 : Line Input #1, ln$ : SPL(i) = Val(ln$) : Next i
  Line Input #1, ln$ : LT = Val(ln$)
  ' prayer charges (added for cleric mechanic)
  For i = 1 To 3
    If Eof(#1) Then PRY(i) = 0 Else Line Input #1, ln$ : PRY(i) = Val(ln$)
  Next i
  If Eof(#1) Then LCKBOOST = 0 Else Line Input #1, ln$ : LCKBOOST = Val(ln$)
  If Eof(#1) Then LCKTTL = 0 Else Line Input #1, ln$ : LCKTTL = Val(ln$)
  If Eof(#1) Then NEEDEXP = 0 Else Line Input #1, ln$ : NEEDEXP = Val(ln$)
  If Eof(#1) Then MSPEED = 2 Else Line Input #1, ln$ : MSPEED = Val(ln$)
  Close #1
End Sub


Sub SaveHero(fn$)
  Local Integer i
  Open fn$ For Output As #1
  Print #1, "DOOMHERO1"
  Print #1, HERO$
  Print #1, CLASS$
  Print #1, NS$(LE)
  Print #1, NS$(NX)
  Print #1, NS$(NY)
  For i = 1 To 8 : Print #1, Str$(F(i)) : Next i
  Print #1, Str$(S1)
  Print #1, Str$(S2)
  Print #1, Str$(S3)
  For i = 1 To 24 : Print #1, NS$(OBJ(i)) : Next i
  Print #1, NS$(GC)
  Print #1, NS$(TR)
  For i = 1 To 6 : Print #1, Str$(SPL(i)) : Next i
  Print #1, NS$(LT)
  For i = 1 To 3 : Print #1, Str$(PRY(i)) : Next i
  Print #1, Str$(LCKBOOST)
  Print #1, Str$(LCKTTL)
  Print #1, NS$(NEEDEXP)
  Print #1, NS$(MSPEED)
  Close #1
End Sub


Sub SaveGame
  Say "ONE MOMENT PLEASE"
  MakeDir SPATH$
  SaveLevel LE
  SaveHero SPATH$ + "/HERO.DAT"
  CLS CBG
  Text 160, 120, "THY PROGRESS IS RECORDED", "CT", 1, 1, CTTXT, CBG
  Text 160, 150, "RUN DOOM.BAS TO RESUME", "CT", 1, 1, CBTXT, CBG
  Text 160, 210, "PRESS ANY KEY", "CT", 1, 1, CBTXT, CBG
  IK$ = WaitKey$()
  QUIT = 1
End Sub


' =====================================================================
'  START UP
' =====================================================================
Sub Splash
  CLS CBG
  Text 160, 30, "DUNGEON", "CT", 1, 3, CHERO, CBG
  Text 160, 66, "OF DOOM", "CT", 1, 3, CHERO, CBG
  Text 160, 120, "MOVE   M  or UP ARROW", "CT", 1, 1, CBTXT, CBG
  Text 160, 136, "TURN   B / N or LEFT/RIGHT", "CT", 1, 1, CBTXT, CBG
  Text 160, 152, "ATTACK A     GET    G", "CT", 1, 1, CBTXT, CBG
  Text 160, 168, "CAST   C     QUAFF  P", "CT", 1, 1, CBTXT, CBG
  Text 160, 184, "LOOK   R     SAVE   S", "CT", 1, 1, CBTXT, CBG
  Text 160, 200, "HELP   ?", "CT", 1, 1, CBTXT, CBG
  Text 160, 240, "MONSTERS MOVE WHETHER OR NOT", "CT", 1, 1, RGB(255,140,140), CBG
  Text 160, 256, "THOU DOST.  TARRY NOT.", "CT", 1, 1, RGB(255,140,140), CBG
  Text 160, 292, "PRESS ANY KEY", "CT", 1, 1, CTTXT, CBG
  IK$ = WaitKey$()
End Sub


Sub Lore
  Local k$
  CLS CBG
  Text 160, 20, "THE LORE", "CT", 1, 2, CHERO, CBG
  Text 160, 60,  "M MOVE FORWARD    B/N TURN", "CT", 1, 1, CBTXT, CBG
  Text 160, 76,  "A ATTACK THE BEAST BEFORE THEE", "CT", 1, 1, CBTXT, CBG
  Text 160, 92,  "G GET WHAT LIES AHEAD", "CT", 1, 1, CBTXT, CBG
  Text 160, 108, "Q QUAFF A POTION OR SALVE", "CT", 1, 1, CBTXT, CBG
  Text 160, 124, "P PRAY (CLERIC ONLY)", "CT", 1, 1, CBTXT, CBG
  Text 160, 140, "R LOOK ABOUT, SPENDS LAMP OIL", "CT", 1, 1, CBTXT, CBG
  Text 160, 156, "C CAST A SPELL    S SAVE AND STOP", "CT", 1, 1, CBTXT, CBG
  Text 160, 176, "1 SMITE      SLAY THE BEAST", "CT", 1, 1, CPLAB, CBG
  Text 160, 192, "2 WARD       A CIRCLE OF SAFETY", "CT", 1, 1, CPLAB, CBG
  Text 160, 208, "3 TRANSPORT  GO ELSEWHERE", "CT", 1, 1, CPLAB, CBG
  Text 160, 224, "4 MEND       A LITTLE HEALING", "CT", 1, 1, CPLAB, CBG
  Text 160, 240, "5 CHAOS      REMAKE THE WAY AHEAD", "CT", 1, 1, CPLAB, CBG
  Text 160, 256, "6 RENEWAL    WHOLE AGAIN", "CT", 1, 1, CPLAB, CBG
  Text 160, 292, "PRESS ANY KEY", "CT", 1, 1, CTTXT, CBG
  k$ = WaitKey$()
  Layout
  Redraw
  DrawHero
  ShowStatus
End Sub


Sub Options
  Local k$
  Do
    CLS CBG
    Text 160, 30, "OPTIONS", "CT", 1, 2, CHERO, CBG
    If NEEDEXP = 0 Then
      Text 160, 100, "E  EXPERIENCE GATE: OFF", "CT", 1, 1, CBTXT, CBG
    Else
      Text 160, 100, "E  EXPERIENCE GATE: ON", "CT", 1, 1, CBTXT, CBG
    EndIf
    Text 160, 140, "S  MONSTER SPEED:   " + NS$(MSPEED), "CT", 1, 1, CBTXT, CBG
    Text 160, 200, "ENTER TO BEGIN", "CT", 1, 1, CTTXT, CBG
    k$ = WaitKey$()
    If k$ = "E" Then
      If NEEDEXP = 0 Then NEEDEXP = 1 Else NEEDEXP = 0
    ElseIf k$ = "S" Then
      MSPEED = MSPEED + 1
      If MSPEED > 3 Then MSPEED = 1
    EndIf
  Loop Until k$ = Chr$(13)
End Sub


Sub LoadGame
  Local Integer rsm, i, j
  Local k$
  rsm = 0
  If FileExists(SPATH$ + "/HERO.DAT") Then
    CLS CBG
    Text 160, 120, "A SAVED QUEST AWAITS", "CT", 1, 1, CTTXT, CBG
    Text 160, 160, "R  RESUME IT", "CT", 1, 1, CBTXT, CBG
    Text 160, 180, "N  BEGIN ANEW", "CT", 1, 1, CBTXT, CBG
    Do
      k$ = WaitKey$()
    Loop Until k$ = "R" Or k$ = "N"
    If k$ = "R" Then rsm = 1
  EndIf


  If rsm = 1 Then
    LoadHero SPATH$ + "/HERO.DAT"
  Else
    ' start over: throw away any saved levels and the saved hero
    MakeDir SPATH$
    Scrub SPATH$ + "/HERO.DAT"
    For i = 1 To 9
      Scrub SPATH$ + "/LEVEL" + NS$(i) + ".DAT"
    Next i
    If FileExists(DPATH$ + "/HERO.DAT") = 0 Then
      CLS CBG
      Text 160, 130, "NO HERO IS READY", "CT", 1, 1, RGB(255,120,120), CBG
      Text 160, 160, "RUN CHARGEN.BAS FIRST", "CT", 1, 1, CBTXT, CBG
      Text 160, 200, "PRESS ANY KEY", "CT", 1, 1, CBTXT, CBG
      k$ = WaitKey$()
      End
    EndIf
    LoadHero DPATH$ + "/HERO.DAT"
    Options
  EndIf


  If rsm = 0 Then
    ' a fresh hero is at full health, so these values are the peaks
    S1 = F(1) : S2 = F(2) : S3 = F(5)
    ' spell charges and lamp oil, worked out from what was bought
    For i = 1 To 2
      For j = 1 To 3
        SPL((i-1)*3 + j) = OBJ(16 + i) * F(7)
      Next j
    Next i
    LT = 0
    If OBJ(16) = 1 Then LT = 20
    ' prayer charges for clerics, same formula as spells
    For i = 1 To 3
      If CLASS$ = "CLERIC" Then PRY(i) = Int(F(7)) + 2 Else PRY(i) = 0
    Next i
    LCKBOOST = 0 : LCKTTL = 0
    LE = 1
  EndIf
  If LE < 1 Then LE = 1


  If LevelFile$(LE) = "" Then
    CLS CBG
    Text 160, 130, "NO DUNGEON IS DUG", "CT", 1, 1, RGB(255,120,120), CBG
    Text 160, 160, "RUN DUNGEN.BAS FIRST", "CT", 1, 1, CBTXT, CBG
    Text 160, 200, "PRESS ANY KEY", "CT", 1, 1, CBTXT, CBG
    k$ = WaitKey$()
    End
  EndIf


  ' remember where a resumed hero was standing, LoadLevel overwrites it
  i = NX : j = NY
  LoadLevel LE
  If rsm = 1 And i > 0 And j > 0 Then
    NX = i : NY = j
  Else
    NX = IX : NY = IY
  EndIf
  OX = NX : OY = NY
  NF = 1 : DX = 255 : FI = 0 : TF = 0 : MS = 0 : QUIT = 0 : LASTRH = 0
End Sub


' =====================================================================
'  ODDS AND ENDS
' =====================================================================
Function Arrow$(k$)
  Local s$
  s$ = k$
  If s$ = "" Then
    Arrow$ = ""
    Exit Function
  EndIf
  Select Case Asc(s$)
    Case 128 : s$ = "M"      ' up    = walk on
    Case 129 : s$ = "G"      ' down  = pick up
    Case 130 : s$ = "B"      ' left  = turn widdershins
    Case 131 : s$ = "N"      ' right = turn sunwise
  End Select
  Arrow$ = UCase$(s$)
End Function


Function WaitKey$()
  Local k$
  Do
    k$ = Inkey$
    If k$ = "" Then Pause 5
  Loop Until k$ <> ""
  WaitKey$ = UCase$(k$)
End Function


Function Dice(n) As Integer
  If n < 1 Then Dice = 0 Else Dice = Int(Rnd * Int(n)) + 1
End Function


Function FileExists(f$) As Integer
  Local Integer e
  FileExists = 0
  On Error Skip 1
  Open f$ For Input As #9
  e = MM.Errno
  On Error Clear
  If e = 0 Then
    Close #9
    FileExists = 1
  EndIf
End Function


' Mkdir only makes one level at a time, so walk the path and make each
' parent in turn.  Existing directories just raise an error we skip.
Sub MakeDir(d$)
  Local Integer i
  For i = 4 To Len(d$)
    If Mid$(d$, i, 1) = "/" Then
      On Error Skip 1
      Mkdir Left$(d$, i - 1)
      On Error Clear
    EndIf
  Next i
  On Error Skip 1
  Mkdir d$
  On Error Clear
End Sub


Sub Scrub(f$)
  On Error Skip 1
  Kill f$
  On Error Clear
End Sub


Function NS$(n)
  Local t$
  t$ = Str$(Int(n))
  Do While Left$(t$,1) = " " : t$ = Mid$(t$,2) : Loop
  NS$ = t$
End Function


Function Pad$(s$, n As Integer)
  Local t$
  t$ = s$
  If Len(t$) > n Then t$ = Left$(t$, n)
  Do While Len(t$) < n : t$ = t$ + " " : Loop
  Pad$ = t$
End Function


Function RPad$(s$, n As Integer)
  Local t$
  t$ = s$
  If Len(t$) > n Then t$ = Right$(t$, n)
  Do While Len(t$) < n : t$ = " " + t$ : Loop
  RPad$ = t$
End Function
