' =====================================================================
'  DUNGEON OF DOOM  --  LEVEL GENERATOR                DUNGEN.BAS
'  PicoMite BASIC port for the PicoCalc (320 x 320)
'
'  Ported from the BBC BASIC listing in Usborne's
'  "Write Your Own Fantasy Games For Your Microcomputer".
'
'  This is the book's interactive level designer: you drive a cursor
'  round a 15 x 15 grid and press a digit to lay a tile.
'
'  Writes  B:/DOOM/LEVEL1.DAT ... LEVELn.DAT  and  B:/DOOM/DUNGEON.DAT
' =====================================================================


Option Explicit
Option Default Float


Dim DPATH$ = "B:/DOOM"
Dim SPATH$ = "B:/DOOM/SAVE"


' ------------------------------------------------- tile codes -------
' The BBC original stored the map as the CHR$ codes of its user
' defined characters, 224 upwards.  Those codes are kept here so the
' listing still reads the same way, and so DOOM.BAS agrees.
Dim Integer C0 = 230      ' bare floor          key 0
Dim Integer C1 = 231      ' wall                key 1
Dim Integer C2 = 232      ' vase / flask        key 2
Dim Integer C3 = 233      ' chest               key 3
Dim Integer C4 = 234      ' the idol, the quest key 4
Dim Integer CW = 235      ' way in              key 5
Dim Integer C5 = 236      ' exit, the way down  key 6
Dim Integer C6 = 237      ' trap                key 7
Dim Integer C7 = 238      ' safe place          key 8
Dim Integer MON1 = 239, MON2 = 240, MON3 = 241   '                key 9


' ------------------------------------------- random level tuning ---
' Used by the R key.  The lo/hi pairs are ranges; how many of each
' thing a conjured level gets is picked from between them.
Dim Integer RWALL  = 5       ' one interior square in RWALL is a wall
Dim Integer RFLOOR = 60      ' fewest walkable squares worth keeping
Dim Integer RCHLO = 3, RCHHI = 4     ' chests
Dim Integer RVALO = 3, RVAHI = 4     ' vases
Dim Integer RTRLO = 2, RTRHI = 3     ' traps
Dim Integer RSAFE = 1                ' safe places
Dim Integer RMNLO = 4, RMNHI = 5     ' monsters


' ------------------------------------------------- geometry ---------
Dim Integer TW = 16
Dim Integer MAPX = 0, MAPY = 20
Dim Integer PANX = 244
Dim Integer YMSG = 262, YSTA = 280, YKEY = 298


' ------------------------------------------------- colours ---------
Dim Integer CBG, CFLOOR, CWALL, CMORT, CTBAR, CTTXT
Dim Integer CPBG, CPTXT, CCUR, CMSGC, CBBG, CBTXT
CBG    = RGB(0,0,0)
CFLOOR = RGB(26,28,38)
CWALL  = RGB(112,102,90)
CMORT  = RGB(58,52,46)
CTBAR  = RGB(80,16,16)
CTTXT  = RGB(255,225,150)
CPBG   = RGB(10,14,40)
CPTXT  = RGB(150,180,225)
CCUR   = RGB(255,225,60)
CMSGC  = RGB(255,240,180)
CBBG   = RGB(16,16,20)
CBTXT  = RGB(190,195,205)


Dim Integer TCOL(17), GLY(17,7), BMASK(7)


' ------------------------------------------------- state -----------
Dim Integer R(15,15)
Dim Integer X, Y, IX, IY, LEV, DIRTY
Dim Integer I, J
Dim KEY$, MSG$


Randomize Timer


' ------------------------------------------------- glyphs ----------
' The eighteen VDU 23 characters of the original, byte for byte.
Data 255,255,255,255,255,255,255,255      ' 224 solid block
Data 56,56,16,56,84,16,40,68              ' 225 hero facing north
Data 28,28,8,30,40,40,20,18               ' 226 hero facing east
Data 56,56,16,84,56,40,68,40              ' 227 hero facing south
Data 56,56,16,120,148,20,40,72            ' 228 hero facing west
Data 0,0,0,0,8,209,254,221                ' 229 hero fallen
Data 0,0,0,0,0,0,0,0                      ' 230 floor
Data 85,170,85,170,85,170,85,170          ' 231 wall
Data 0,60,24,60,126,126,126,60            ' 232 vase
Data 0,56,100,114,95,73,41,31             ' 233 chest
Data 20,42,20,20,93,93,62,99              ' 234 idol
Data 60,126,255,255,255,253,255,255       ' 235 way in
Data 60,102,195,129,129,129,133,129       ' 236 exit
Data 129,66,36,0,0,36,66,129              ' 237 trap
Data 0,60,66,66,66,66,60,0                ' 238 safe place
Data 76,158,170,190,84,30,37,88           ' 239 guard, weakest
Data 0,56,84,124,56,44,68,102             ' 240 guard
Data 0,8,28,42,127,85,65,34               ' 241 guard, worst
For I = 0 To 17
  For J = 0 To 7 : Read GLY(I,J) : Next J
Next I


For I = 0 To 7 : BMASK(I) = 2 ^ (7 - I) : Next I


For I = 0 To 17 : TCOL(I) = RGB(200,200,200) : Next I
TCOL(8)  = RGB(80,230,230)      ' vase
TCOL(9)  = RGB(255,205,40)      ' chest
TCOL(10) = RGB(255,110,255)     ' idol
TCOL(11) = RGB(190,175,130)     ' way in
TCOL(12) = RGB(70,235,110)      ' exit
TCOL(13) = RGB(235,70,60)       ' trap
TCOL(14) = RGB(150,200,255)     ' safe place
TCOL(15) = RGB(215,80,80)       ' guards
TCOL(16) = RGB(240,150,50)
TCOL(17) = RGB(200,100,240)


' ------------------------------------------------- start up --------
CheckSD
MakeDir DPATH$
MakeDir SPATH$
Splash


LEV = 1
LoadOrBlank LEV
X = 8 : Y = 8 : MSG$ = ""
Layout
Redraw


' =====================================================================
'  THE EDITOR   (original lines 100-220)
' =====================================================================
Do
  DrawCursor 1
  KEY$ = WaitKey$()
  DrawCursor 0


  Select Case KEY$
    Case "H" : If X > 1  Then X = X - 1
    Case "L" : If X < 15 Then X = X + 1
    Case "K" : If Y > 1  Then Y = Y - 1
    Case "J" : If Y < 15 Then Y = Y + 1


    Case "0","1","2","3","4","5","6","7","8","9"
      Place Val(KEY$)


    Case "?" : Lore


    Case "E"
      If Confirm$("WIPE THIS LEVEL? Y/N") = "Y" Then
        Blank : Redraw : Say "LEVEL WIPED"
      Else
        Say ""
      EndIf


    Case "R"
      If Confirm$("CONJURE A RANDOM LEVEL? Y/N") = "Y" Then
        Generate : Redraw
        Say "BEHOLD! NOW EDIT AWAY, OR SAVE"
      Else
        Say ""
      EndIf


    Case "N"
      If Ready() Then
        SaveLevel LEV
        LEV = LEV + 1
        If LEV > 9 Then
          LEV = 9
          Say "NINE LEVELS IS THE LIMIT"
        Else
          LoadOrBlank LEV
          X = 8 : Y = 8
          Layout : Redraw
        EndIf
      EndIf


    Case "S"
      If Ready() Then
        SaveLevel LEV
        WriteIndex
        Farewell
        End
      EndIf


    Case "Q"
      If Confirm$("QUIT, LOSING THIS LEVEL? Y/N") = "Y" Then
        WriteIndex
        Farewell
        End
      Else
        Say ""
      EndIf
  End Select


  ShowState
Loop


' =====================================================================
'  EDITING
' =====================================================================
' Key 9 lays a guard of random strength, as the original's
' IF I=9 THEN I=8+RND(3) did.  Key 5 also records the way in.
Sub Place(n As Integer)
  Local Integer code
  Select Case n
    Case 0 : code = C0
    Case 1 : code = C1
    Case 2 : code = C2
    Case 3 : code = C3
    Case 4 : code = C4
    Case 5 : code = CW
    Case 6 : code = C5
    Case 7 : code = C6
    Case 8 : code = C7
    Case 9 : code = 238 + Dice(3)
  End Select


  ' only one way in per level, so lift the old one
  If code = CW Then
    If IX > 0 Then
      R(IX,IY) = C0
      DrawCell IX, IY
    EndIf
    IX = X : IY = Y
  ElseIf X = IX And Y = IY Then
    IX = 0 : IY = 0
  EndIf


  R(X,Y) = code
  DrawCell X, Y
  DIRTY = 1
End Sub


Sub Blank
  Local Integer x1, y1
  For y1 = 1 To 15
    For x1 = 1 To 15
      R(x1,y1) = C0
    Next x1
  Next y1
  IX = 0 : IY = 0 : DIRTY = 1
End Sub


' Conjure a whole level: walls round the rim, a scattering of walls
' within, then the way in.  A flood fill from the way in finds every
' square a hero could walk to, and the exit and all the furniture are
' laid only on those squares, so nothing is ever sealed off.  The
' deepest level still wants its idol laid by hand, key 4.
Sub Generate
  Local Integer x1, y1, i, n, nf, qh, cx, cy, d, best
  Local Integer V(15,15), FX(225), FY(225)

  Do
    For y1 = 1 To 15
      For x1 = 1 To 15
        If x1 = 1 Or x1 = 15 Or y1 = 1 Or y1 = 15 Then
          R(x1,y1) = C1
        ElseIf Dice(RWALL) = 1 Then
          R(x1,y1) = C1
        Else
          R(x1,y1) = C0
        EndIf
      Next x1
    Next y1

    Do
      IX = 1 + Dice(13) : IY = 1 + Dice(13)
    Loop Until R(IX,IY) = C0
    R(IX,IY) = CW

    ' breadth first from the way in; the queue doubles as the list of
    ' reached squares once the fill is done
    For y1 = 1 To 15 : For x1 = 1 To 15 : V(x1,y1) = 0 : Next x1 : Next y1
    FX(1) = IX : FY(1) = IY : V(IX,IY) = 1 : nf = 1 : qh = 1
    Do While qh <= nf
      cx = FX(qh) : cy = FY(qh) : qh = qh + 1
      If R(cx+1,cy) <> C1 And V(cx+1,cy) = 0 Then
        V(cx+1,cy) = 1 : nf = nf + 1 : FX(nf) = cx+1 : FY(nf) = cy
      EndIf
      If R(cx-1,cy) <> C1 And V(cx-1,cy) = 0 Then
        V(cx-1,cy) = 1 : nf = nf + 1 : FX(nf) = cx-1 : FY(nf) = cy
      EndIf
      If R(cx,cy+1) <> C1 And V(cx,cy+1) = 0 Then
        V(cx,cy+1) = 1 : nf = nf + 1 : FX(nf) = cx : FY(nf) = cy+1
      EndIf
      If R(cx,cy-1) <> C1 And V(cx,cy-1) = 0 Then
        V(cx,cy-1) = 1 : nf = nf + 1 : FX(nf) = cx : FY(nf) = cy-1
      EndIf
    Loop

    ' a cramped cave is no dungeon; try again
  Loop Until nf >= RFLOOR

  ' the way down goes as far from the way in as a hero can walk
  best = -1
  For i = 2 To nf
    d = Abs(FX(i) - IX) + Abs(FY(i) - IY)
    If d > best Then best = d : n = i
  Next i
  R(FX(n),FY(n)) = C5
  FX(n) = FX(nf) : FY(n) = FY(nf) : nf = nf - 1

  Sprinkle C3, Between(RCHLO, RCHHI), FX(), FY(), nf
  Sprinkle C2, Between(RVALO, RVAHI), FX(), FY(), nf
  Sprinkle C6, Between(RTRLO, RTRHI), FX(), FY(), nf
  Sprinkle C7, RSAFE, FX(), FY(), nf
  For i = 1 To Between(RMNLO, RMNHI)
    Sprinkle 238 + Dice(3), 1, FX(), FY(), nf
  Next i

  DIRTY = 1
End Sub


' lay cnt tiles of one kind on squares drawn from the reached list,
' never on the way in at slot one, each square used once
Sub Sprinkle(code As Integer, cnt As Integer, PX() As Integer, PY() As Integer, np As Integer)
  Local Integer i, k
  For k = 1 To cnt
    If np < 2 Then Exit For
    i = 1 + Dice(np - 1)
    R(PX(i),PY(i)) = code
    PX(i) = PX(np) : PY(i) = PY(np) : np = np - 1
  Next k
End Sub


' a level with no way in cannot be entered, which the original also
' enforced with IF IX>0
Function Ready() As Integer
  If IX = 0 Then
    Say "PLACE A WAY IN FIRST, KEY 5"
    Ready = 0
  Else
    Ready = 1
  EndIf
End Function


' =====================================================================
'  DRAWING
' =====================================================================
Sub Layout
  Local Integer i, ty
  CLS CBG
  Box 0, 0, 320, 18, 0, CTBAR, CTBAR
  Text 4, 3, "LEVEL GENERATOR", "LT", 1, 1, CTTXT, CTBAR
  Text 316, 3, "LEVEL " + NS$(LEV), "RT", 1, 1, CTTXT, CTBAR


  Box 240, 18, 80, 242, 0, CPBG, CPBG
  Box 0, 260, 320, 60, 0, CBBG, CBBG


  ' the palette, drawn with the very glyphs the game will use
  For i = 0 To 9
    ty = 24 + i * 16
    Text PANX, ty + 4, Mid$("1234567890", i + 1, 1), "LT", 1, 1, CCUR, CPBG
    DrawGlyph PANX + 12, ty, PalGlyph(i), TCOL(PalGlyph(i))
    Text PANX + 30, ty + 4, PalName$(i), "LT", 1, 1, CPTXT, CPBG
  Next i


  Text PANX, 188, "? HELP",   "LT", 1, 1, CBTXT, CPBG
  Text PANX, 200, "R RANDOM", "LT", 1, 1, CBTXT, CPBG
  Text PANX, 212, "E WIPE",   "LT", 1, 1, CBTXT, CPBG
  Text PANX, 224, "N NEXT",   "LT", 1, 1, CBTXT, CPBG
  Text PANX, 236, "S SAVE",   "LT", 1, 1, CBTXT, CPBG
  Text PANX, 248, "Q QUIT",   "LT", 1, 1, CBTXT, CPBG


  Text 4, YKEY, "ARROWS OR H J K L MOVE THE CURSOR", "LT", 1, 1, CBTXT, CBBG
End Sub


Function PalGlyph(i As Integer) As Integer
  Local Integer g
  Select Case i
    Case 0 : g = 7        ' wall
    Case 1 : g = 8        ' vase
    Case 2 : g = 9        ' chest
    Case 3 : g = 10       ' idol
    Case 4 : g = 11       ' way in
    Case 5 : g = 12       ' exit
    Case 6 : g = 13       ' trap
    Case 7 : g = 14       ' safe place
    Case 8 : g = 15       ' guard
    Case Else : g = 6     ' floor
  End Select
  PalGlyph = g
End Function


Function PalName$(i As Integer)
  Local s$
  Select Case i
    Case 0 : s$ = "WALL"
    Case 1 : s$ = "VASE"
    Case 2 : s$ = "CHEST"
    Case 3 : s$ = "IDOL"
    Case 4 : s$ = "WAY IN"
    Case 5 : s$ = "EXIT"
    Case 6 : s$ = "TRAP"
    Case 7 : s$ = "SAFE"
    Case 8 : s$ = "GUARD"
    Case Else : s$ = "ERASE"
  End Select
  PalName$ = s$
End Function


' one 8 x 8 glyph doubled to 16 x 16, painted as horizontal runs
Sub DrawGlyph(px As Integer, py As Integer, g As Integer, fc As Integer)
  Local Integer r, bits, b, RUNLEN
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


Sub DrawCell(cx As Integer, cy As Integer)
  Local Integer code, px, py, g
  code = R(cx,cy)
  px = MAPX + (cx-1)*TW
  py = MAPY + (cy-1)*TW
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
  g = code - 224
  DrawGlyph px, py, g, TCOL(g)
End Sub


Sub Redraw
  Local Integer x1, y1
  For y1 = 1 To 15
    For x1 = 1 To 15
      DrawCell x1, y1
    Next x1
  Next y1
End Sub


Sub DrawCursor(sw As Integer)
  Local Integer px, py, c
  px = MAPX + (X-1)*TW
  py = MAPY + (Y-1)*TW
  If sw = 1 Then
    Box px, py, TW, TW, 1, CCUR
  Else
    DrawCell X, Y
  EndIf
End Sub


Sub Say(s$)
  Text 4, YMSG, Pad$(s$, 39), "LT", 1, 1, CMSGC, CBBG
End Sub


Sub ShowState
  Local s$
  s$ = "AT " + NS$(X) + "," + NS$(Y) + "   WAY IN "
  If IX = 0 Then s$ = s$ + "NOT SET" Else s$ = s$ + NS$(IX) + "," + NS$(IY)
  Text 4, YSTA, Pad$(s$, 39), "LT", 1, 1, CBTXT, CBBG
End Sub


' =====================================================================
'  SCREENS
' =====================================================================
Sub Splash
  CLS CBG
  Text 160, 30, "DUNGEON", "CT", 1, 3, CTTXT, CBG
  Text 160, 66, "OF DOOM", "CT", 1, 3, CTTXT, CBG
  Text 160, 116, "THE LEVEL GENERATOR", "CT", 1, 1, CBTXT, CBG
  Text 160, 150, "DRIVE THE CURSOR WITH THE ARROWS", "CT", 1, 1, CBTXT, CBG
  Text 160, 166, "AND PRESS A DIGIT TO LAY A TILE.", "CT", 1, 1, CBTXT, CBG
  Text 160, 196, "EVERY LEVEL NEEDS A WAY IN, KEY 5.", "CT", 1, 1, RGB(255,150,150), CBG
  Text 160, 212, "THE DEEPEST NEEDS THE IDOL, KEY 4.", "CT", 1, 1, RGB(255,150,150), CBG
  Text 160, 242, "EXISTING LEVELS ARE LOADED FOR", "CT", 1, 1, CBTXT, CBG
  Text 160, 258, "EDITING, SO YOU CAN COME BACK.", "CT", 1, 1, CBTXT, CBG
  Text 160, 292, "PRESS ANY KEY", "CT", 1, 1, CTTXT, CBG
  KEY$ = WaitKey$()
End Sub


' named Lore, as in DOOM.BAS -- newer PicoMite firmware has a built in
' HELP command, so a Sub called Help is shadowed and the call becomes
' a firmware help lookup that dies wanting A:/help.txt
Sub Lore
  Local k$
  CLS CBG
  Text 160, 16, "THE LORE OF DIGGING", "CT", 1, 2, CTTXT, CBG
  Text 160, 56,  "1 WALL      BARS THE WAY", "CT", 1, 1, CBTXT, CBG
  Text 160, 72,  "2 VASE      YIELDS SALVE AND POTION", "CT", 1, 1, CBTXT, CBG
  Text 160, 88,  "3 CHEST     TREASURE, WORTH SCORE", "CT", 1, 1, CBTXT, CBG
  Text 160, 104, "4 IDOL      THE QUEST ENDS HERE", "CT", 1, 1, CBTXT, CBG
  Text 160, 120, "5 WAY IN    WHERE THE HERO ARRIVES", "CT", 1, 1, CBTXT, CBG
  Text 160, 136, "6 EXIT      STAIRS TO THE NEXT LEVEL", "CT", 1, 1, CBTXT, CBG
  Text 160, 152, "7 TRAP      HOLDS THEE FAST", "CT", 1, 1, CBTXT, CBG
  Text 160, 168, "8 SAFE      NO BEAST MAY STRIKE THEE", "CT", 1, 1, CBTXT, CBG
  Text 160, 184, "9 GUARD     A BEAST OF RANDOM MIGHT", "CT", 1, 1, CBTXT, CBG
  Text 160, 200, "0 ERASE     BACK TO BARE FLOOR", "CT", 1, 1, CBTXT, CBG
  Text 160, 216, "R CONJURE A RANDOM LEVEL", "CT", 1, 1, CPTXT, CBG
  Text 160, 232, "E WIPE THE WHOLE LEVEL", "CT", 1, 1, CPTXT, CBG
  Text 160, 248, "N SAVE AND GO ONE LEVEL DEEPER", "CT", 1, 1, CPTXT, CBG
  Text 160, 264, "S SAVE AND STOP    Q STOP", "CT", 1, 1, CPTXT, CBG
  Text 160, 296, "PRESS ANY KEY", "CT", 1, 1, CTTXT, CBG
  k$ = WaitKey$()
  Layout : Redraw : ShowState
End Sub


Function Confirm$(p$)
  Local k$
  Say p$
  Do
    k$ = WaitKey$()
  Loop Until k$ = "Y" Or k$ = "N"
  Confirm$ = k$
End Function


Sub Farewell
  CLS CBG
  Text 160, 80,  "THE DUNGEON IS DUG", "CT", 1, 2, CTTXT, CBG
  Text 160, 130, NS$(CountLevels()) + " LEVELS IN", "CT", 1, 1, CBTXT, CBG
  Text 160, 146, DPATH$, "CT", 1, 1, CBTXT, CBG
  Text 160, 190, "RUN CHARGEN.BAS FOR A HERO", "CT", 1, 1, CTTXT, CBG
  Text 160, 206, "THEN RUN DOOM.BAS TO PLAY", "CT", 1, 1, CTTXT, CBG
  Text 160, 280, "PRESS ANY KEY", "CT", 1, 1, CBTXT, CBG
  KEY$ = WaitKey$()
  CLS CBG
End Sub


' =====================================================================
'  FILES
' =====================================================================
' One item per line.  Fifteen rows of fifteen legend characters, so a
' level can also be drawn by hand in a text editor.
Sub SaveLevel(n As Integer)
  Local Integer x1, y1
  Local ln$, f$
  Say "ONE MOMENT PLEASE"
  f$ = DPATH$ + "/LEVEL" + NS$(n) + ".DAT"
  Open f$ For Output As #1
  Print #1, "DOOMLEV1"
  Print #1, NS$(n)
  Print #1, NS$(IX)
  Print #1, NS$(IY)
  For y1 = 1 To 15
    ln$ = ""
    For x1 = 1 To 15
      ln$ = ln$ + TileChar$(R(x1,y1))
    Next x1
    Print #1, ln$
  Next y1
  Close #1
  ' a redrawn level makes any save game on it meaningless
  Scrub SPATH$ + "/LEVEL" + NS$(n) + ".DAT"
  DIRTY = 0
  Say "LEVEL " + NS$(n) + " SAVED"
End Sub


Sub LoadOrBlank(n As Integer)
  Local Integer x1, y1
  Local f$, ln$
  Blank
  f$ = DPATH$ + "/LEVEL" + NS$(n) + ".DAT"
  If FileExists(f$) = 0 Then Exit Sub
  Open f$ For Input As #1
  Line Input #1, ln$                       ' DOOMLEV1
  Line Input #1, ln$                       ' level number
  Line Input #1, ln$ : IX = Val(ln$)
  Line Input #1, ln$ : IY = Val(ln$)
  For y1 = 1 To 15
    Line Input #1, ln$
    For x1 = 1 To 15
      R(x1,y1) = TileCode(Mid$(ln$, x1, 1))
    Next x1
  Next y1
  Close #1
  DIRTY = 0
End Sub


Sub WriteIndex
  Open DPATH$ + "/DUNGEON.DAT" For Output As #1
  Print #1, "DOOMDUNGEON1"
  Print #1, NS$(CountLevels())
  Close #1
End Sub


' how many levels run unbroken from one downwards
Function CountLevels() As Integer
  Local Integer n
  n = 0
  Do While n < 9
    If FileExists(DPATH$ + "/LEVEL" + NS$(n + 1) + ".DAT") = 0 Then Exit Do
    n = n + 1
  Loop
  CountLevels = n
End Function


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
    Case "a" : c = MON1
    Case "b" : c = MON2
    Case "c" : c = MON3
    Case Else : c = C0
  End Select
  TileCode = c
End Function


Function TileChar$(c As Integer)
  Local ch$
  Select Case c
    Case C0   : ch$ = "."
    Case C1   : ch$ = "#"
    Case C2   : ch$ = "!"
    Case C3   : ch$ = "$"
    Case C4   : ch$ = "&"
    Case CW   : ch$ = "*"
    Case C5   : ch$ = ">"
    Case C6   : ch$ = "^"
    Case C7   : ch$ = "O"
    Case MON1 : ch$ = "a"
    Case MON2 : ch$ = "b"
    Case MON3 : ch$ = "c"
    Case Else : ch$ = "."
  End Select
  TileChar$ = ch$
End Function


' =====================================================================
'  ODDS AND ENDS
' =====================================================================
Function WaitKey$()
  Local k$
  Do
    k$ = Inkey$
    If k$ = "" Then Pause 5
  Loop Until k$ <> ""
  Select Case Asc(k$)
    Case 128 : k$ = "K"      ' up
    Case 129 : k$ = "J"      ' down
    Case 130 : k$ = "H"      ' left
    Case 131 : k$ = "L"      ' right
  End Select
  WaitKey$ = UCase$(k$)
End Function


Function Dice(n) As Integer
  If n < 1 Then Dice = 0 Else Dice = Int(Rnd * Int(n)) + 1
End Function


Function Between(lo As Integer, hi As Integer) As Integer
  If hi <= lo Then Between = lo Else Between = lo - 1 + Dice(hi - lo + 1)
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


' refuse to start rather than wedge inside Open or Mkdir when the card
' is missing or unreadable.  MM.Info(SDCARD) only reads a status flag,
' so unlike the file commands it cannot hang.
Sub CheckSD
  Local s$
  If UCase$(Left$(DPATH$, 2)) <> "B:" Then Exit Sub
  s$ = MM.Info(SDCARD)
  If UCase$(s$) <> "READY" Then
    Print "SD CARD " + s$
    Print "DUNGEN NEEDS THE CARD FOR " + DPATH$
    Print "CHECK IT IS SEATED AND RUN AGAIN"
    Text 0, 0,  "SD CARD " + s$, "LT", 1, 1, RGB(255,80,80), RGB(0,0,0)
    Text 0, 16, "CHECK IT IS SEATED AND RUN AGAIN", "LT", 1, 1, RGB(255,80,80), RGB(0,0,0)
    End
  EndIf
End Sub


Sub Scrub(f$)
  On Error Skip 1
  Kill f$
  On Error Clear
End Sub


Function NS$(n As Integer)
  Local t$
  t$ = Str$(n)
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
