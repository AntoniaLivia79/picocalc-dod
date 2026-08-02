' =====================================================================
'  DUNGEON OF DOOM  --  CHARACTER GENERATOR            CHARGEN.BAS
'  PicoMite BASIC port for the PicoCalc (320 x 320)
'
'  Ported from the BBC BASIC listing in Usborne's
'  "Write Your Own Fantasy Games For Your Microcomputer".
'
'  Run this ONCE to roll up a hero.  It writes  B:/DOOM/HERO.DAT
'  which is then read by DOOM.BAS.
' =====================================================================


Option Explicit
Option Default Float


' ------------------------------------------------- paths ------------
Dim DPATH$ = "B:/picomite/games/rpg/DOOM"
Dim SPATH$ = "B:/picomite/games/rpg/DOOM/SAVE"


' ------------------------------------------------- geometry ---------
' Font 1 at scale 2 gives 16 x 24 pixel cells = 20 columns, the same
' width as the BBC Micro's MODE 5 screen the original was written for.
Dim Integer SC   = 2          ' text scale for the main lists
Dim Integer ROWH = 24         ' pixel height of one scaled row
Dim Integer YTTL = 2          ' title bar
Dim Integer YMSG = 28         ' message line
Dim Integer YPTS = 52         ' points / gold line
Dim Integer YLST = 80         ' first item row
Dim Integer YCLS = 280        ' class line
Dim Integer YKEY = 306        ' key help (scale 1)


' ------------------------------------------------- colours ----------
Dim Integer CBG, CTTL, CTTLB, CMSG, CMSGB, CLIST, CLISTB, CSEL, CCLASS
CBG   = RGB(0,0,0)
CTTL  = RGB(255,235,150) : CTTLB = RGB(90,20,20)
CMSG  = RGB(0,0,0)       : CMSGB = RGB(190,175,120)
CLIST  = RGB(230,230,235) : CLISTB = RGB(20,25,45)
CSEL  = RGB(255,210,60)
CCLASS  = RGB(120,230,160)


' ------------------------------------------------- data -------------
Dim Integer NOBJ = 24         ' D*3 in the original listing


Dim FV(4,9)                   ' 1,* = attributes   2..4,* = shop prices
Dim FN$(4,9)                  ' matching names, ,9 = department title
Dim CNAME$(5)                 ' character classes
Dim Integer OBJ(24)           ' how many of each object the hero owns
Dim PERM$(24)                 ' 5 char mask: may class 1..5 buy it?
Dim Integer QTY(24)           ' how many units one purchase yields


Dim Integer I, J, K, N, C, P, MP, GC, PURSE, BR, OFR, PR, YES
Dim Integer FINISHED
Dim MSG$, HEAD$, HERO$, KEY$


Randomize Timer


' --------------------------------------------- static tables --------
' purchase permission masks, one per object, one digit per class
Data "00001","00011","10011","10011","10011","00011","11111","10011"
Data "00011","00011","10011","11111","00011","11011","11011","11111"
Data "11100","00100","11100","10100","11100","11100","11111","11111"
For I = 1 To NOBJ : Read PERM$(I) : Next I


' shop prices
Data 20,16,12,15,8,10,8,6
Data 18,15,9,9,14,8,6,6
Data 20,15,14,12,10,8,6,6
For J = 2 To 4 : For I = 1 To 8 : Read FV(J,I) : Next I : Next J


' units supplied per purchase
Data 5,4,3,3,2,2,1,1
Data 5,4,3,1,2,1,3,1
Data 4,3,2,2,3,1,1,1
For I = 1 To NOBJ : Read QTY(I) : Next I


' attribute names, then the three shop inventories
Data "STRENGTH","VITALITY","AGILITY","INTELLIGENCE"
Data "EXPERIENCE","LUCK","AURA","MORALITY","CHARACTER CREATION"
Data "2 HAND SWORD","BROADSWORD","SHORT SWORD"
Data "AXE","MACE","FLAIL","DAGGER","GAUNTLET","ARMOURY"
Data "HEAVY ARMOUR","CHAIN ARMOUR","LEATHER ARMOUR","HEAVY ROBE"
Data "GOLD HELMET","HEADPIECE","SHIELD","TORCH","ACCOUTREMENTS"
Data "NECRONOMICON","SCROLLS","RING","MYSTIC AMULET","SASH","CLOAK"
Data "HEALING SALVE","POTIONS","EMPORIUM"
For J = 1 To 4 : For I = 1 To 9 : Read FN$(J,I) : Next I : Next J


Data "WANDERER","CLERIC","MAGICIAN","WARRIOR","BARBARIAN"
For I = 1 To 5 : Read CNAME$(I) : Next I


' --------------------------------------------- roll the hero --------
For I = 1 To 8 : FV(1,I) = Dice(5) + 2 : Next I
FV(1,5) = 1                    ' experience always starts at 1
MP    = 3 + Dice(5)            ' spare attribute points
GC    = 120 + Dice(60)         ' starting purse
C     = 1
For I = 1 To NOBJ : OBJ(I) = 0 : Next I


CLS CBG


' =====================================================================
'  PHASE 1 -- spend the spare points
' =====================================================================
J = 1 : PURSE = MP : HEAD$ = "POINTS"
MSG$ = "SHAPE THY SELF"
DrawPage
K = 1 : Classify : DrawList : DrawCursor : ShowMsg


Do
  KEY$ = WaitKey$()
  If KEY$ = "L" And PURSE > 0 Then
    FV(1,K) = FV(1,K) + 1 : PURSE = PURSE - 1 : DrawList
  ElseIf KEY$ = "H" And FV(1,K) > 1 Then
    FV(1,K) = FV(1,K) - 1 : PURSE = PURSE + 1 : DrawList
  ElseIf KEY$ = "J" And K < 8 Then
    K = K + 1 : If K = 5 Then K = 6      ' experience cannot be bought
    DrawList : DrawCursor
  ElseIf KEY$ = "K" And K > 1 Then
    K = K - 1 : If K = 5 Then K = 4
    DrawList : DrawCursor
  EndIf
  Classify
  ShowMsg
Loop Until KEY$ = " "


' =====================================================================
'  PHASE 2 -- the three shops
' =====================================================================
PURSE = GC : HEAD$ = "GOLD COINS"


For J = 2 To 4
  K = 1
  MSG$ = "CHOOSE WELL SIRE!"
  DrawPage : DrawList : DrawCursor : ShowMsg
  Do
    KEY$ = WaitKey$()
    N   = 8 * (J - 2) + K
    BR  = 0 : OFR = 0
    If KEY$ = "J" And K < 8 Then
      K = K + 1 : DrawList : DrawCursor
    ElseIf KEY$ = "K" And K > 1 Then
      K = K - 1 : DrawList : DrawCursor
    ElseIf KEY$ = "B" Then
      MSG$ = "MAKE YOUR CHOICE" : Allowed
      OFR = FV(J,K) : Bargain : DrawCursor
    ElseIf KEY$ = "O" Then
      MSG$ = "MAKE YOUR CHOICE" : Allowed
      BR  = Dice(3)
      OFR = AskNum("THY OFFER?")
      Bargain : DrawCursor
    EndIf
    ShowMsg
  Loop Until KEY$ = " "
Next J


' =====================================================================
'  PHASE 3 -- name and save
' =====================================================================
MSG$ = "NAME THY CHARACTER"
J = 1                    ' back off the shop loop's exit value of 5,
                         ' which would index FN$(5,9) out of bounds
DrawPage : ShowMsg
HERO$ = AskText$("NAME:", 10)
If HERO$ = "" Then HERO$ = "NAMELESS"


MSG$ = "ONE MOMENT PLEASE" : ShowMsg
MakeDir DPATH$
MakeDir SPATH$
SaveHero DPATH$ + "/HERO.DAT"


' a freshly rolled hero invalidates any previous save game
Scrub SPATH$ + "/HERO.DAT"
For I = 1 To 9
  Scrub SPATH$ + "/LEVEL" + NS$(I) + ".DAT"
Next I


CLS CBG
Text 160, 60,  HERO$, "CT", 1, 2, CSEL, CBG
Text 160, 92,  "THE " + CNAME$(C), "CT", 1, 2, CCLASS, CBG
Text 160, 150, "SAVED TO", "CT", 1, 1, CLIST, CBG
Text 160, 166, DPATH$ + "/HERO.DAT", "CT", 1, 1, CLIST, CBG
Text 160, 210, "NOW RUN DUNGEN.BAS", "CT", 1, 1, CTTL, CBG
Text 160, 226, "THEN RUN DOOM.BAS", "CT", 1, 1, CTTL, CBG
Text 160, 280, "PRESS ANY KEY", "CT", 1, 1, CLIST, CBG
KEY$ = WaitKey$()
End


' =====================================================================
'  SCREEN
' =====================================================================
Sub DrawPage
  CLS CBG
  Box 0, 0, 320, 26, 0, CTTLB, CTTLB
  Text 160, YTTL, Pad$(FN$(J,9), 20), "CT", 1, SC, CTTL, CTTLB
  Box 0, 26, 320, 50, 0, CMSGB, CMSGB
  Box 0, 76, 320, 200, 0, CLISTB, CLISTB
  Text 160, YKEY, KeyHelp$(), "CT", 1, 1, CLIST, CBG
End Sub


Sub DrawList
  Local Integer i, y, c
  For i = 1 To 8
    y = YLST + (i - 1) * ROWH
    c = CLIST : If i = K Then c = CSEL
    If i = 5 And J = 1 Then c = RGB(120,120,130)
    Text 24,  y, Pad$(FN$(J,i), 15), "LT", 1, SC, c, CLISTB
    Text 296, y, RPad$(Str$(Int(FV(J,i))), 3), "RT", 1, SC, c, CLISTB
  Next i
End Sub


Sub DrawCursor
  Local Integer i, y
  For i = 1 To 8
    y = YLST + (i - 1) * ROWH
    If i = K Then
      Text 4, y, ">", "LT", 1, SC, CSEL, CLISTB
    ElseIf J > 1 Then
      If OBJ(8 * (J - 2) + i) > 0 Then
        Text 4, y, "*", "LT", 1, SC, CCLASS, CLISTB
      Else
        Text 4, y, " ", "LT", 1, SC, CSEL, CLISTB
      EndIf
    Else
      Text 4, y, " ", "LT", 1, SC, CSEL, CLISTB
    EndIf
  Next i
End Sub


Sub ShowMsg
  Text 8,  YMSG, Pad$(MSG$, 19), "LT", 1, SC, CMSG, CMSGB
  Text 8,  YPTS, Pad$(HEAD$, 12), "LT", 1, SC, CMSG, CMSGB
  Text 312, YPTS, RPad$(Str$(PURSE), 4), "RT", 1, SC, CMSG, CMSGB
  Text 160, YCLS, Pad$(CNAME$(C), 20), "CT", 1, SC, CCLASS, CBG
End Sub


Function KeyHelp$()
  If J = 1 Then
    KeyHelp$ = "K/J MOVE   H/L SPEND   SPACE WHEN DONE"
  Else
    KeyHelp$ = "K/J MOVE  B BUY  O OFFER  SPACE LEAVE"
  EndIf
End Function


' =====================================================================
'  RULES
' =====================================================================
' Later tests override earlier ones, exactly as in the original.
Sub Classify
  C = 1
  If FV(1,4) > 6 And FV(1,8) > 7 Then C = 2                    ' cleric
  If FV(1,4) > 8 And FV(1,7) > 7 Then C = 3                    ' magician
  If FV(1,1) > 7 And FV(1,8) > 5 And FV(1,1)+FV(1,2) > 10 Then C = 4
  If FV(1,1) > 8 And FV(1,2)+FV(1,3) > 12 And FV(1,8) < 6 Then C = 5
End Sub


' may this class trade in this item?
Sub Allowed
  YES = 0
  If Mid$(PERM$(N), C, 1) = "1" Then YES = 1
  If YES = 0 Then MSG$ = "NOT FOR " + CNAME$(C)
End Sub


Sub Bargain
  If OBJ(N) > 0 And N < 23 Then MSG$ = "YOU HAVE IT SIRE" : Exit Sub
  PR = FV(J,K) - BR
  If PURSE < PR Then MSG$ = "YOU CANNOT AFFORD" : Exit Sub
  If OFR >= PR And YES = 1 Then
    OBJ(N) = OBJ(N) + QTY(N)
    PURSE  = PURSE - PR
    MSG$   = "TIS YOURS!"
  ElseIf OFR < PR And YES = 1 Then
    MSG$ = "OFFER REJECTED"
  EndIf
  If PURSE < 0 Then PURSE = 0
End Sub


' =====================================================================
'  SAVING
' =====================================================================
' One value per line so the file can be inspected or hand edited with
' any text editor on the SD card.
Sub SaveHero(f$)
  Local Integer i
  Open f$ For Output As #1
  Print #1, "DOOMHERO1"
  Print #1, HERO$
  Print #1, CNAME$(C)
  Print #1, "0"                       ' current dungeon level, 0 = new
  Print #1, "0"                       ' saved X (0 = use level entrance)
  Print #1, "0"                       ' saved Y
  For i = 1 To 8  : Print #1, Str$(FV(1,i)) : Next i
  Print #1, Str$(FV(1,1))             ' S1 peak strength
  Print #1, Str$(FV(1,2))             ' S2 peak vitality
  Print #1, Str$(FV(1,5))             ' S3 starting experience
  For i = 1 To NOBJ : Print #1, Str$(OBJ(i)) : Next i
  Print #1, Str$(PURSE)               ' gold left over
  Print #1, "0"                       ' treasure carried
  For i = 1 To 6 : Print #1, "0" : Next i   ' spell charges, game fills
  Print #1, "0"                       ' lamp life, game fills
  Close #1
End Sub


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


' =====================================================================
'  INPUT
' =====================================================================
' Returns a single upper case key.  Arrow keys are folded onto the
' original vi-style HJKL so either set works on the PicoCalc.
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


Function AskText$(p$, mx As Integer)
  Local s$, k$
  Local Integer a
  s$ = ""
  Do
    Text 8, YPTS, Pad$(p$ + " " + s$ + "_", 19), "LT", 1, SC, CMSG, CMSGB
    Do
      k$ = Inkey$
      If k$ = "" Then Pause 5
    Loop Until k$ <> ""
    a = Asc(k$)
    If a = 13 Or a = 10 Then Exit Do
    If a = 8 Or a = 127 Then
      If Len(s$) > 0 Then s$ = Left$(s$, Len(s$) - 1)
    ElseIf a >= 32 And a < 127 And Len(s$) < mx Then
      s$ = s$ + UCase$(k$)
    EndIf
  Loop
  Text 8, YPTS, Pad$("", 19), "LT", 1, SC, CMSG, CMSGB
  AskText$ = s$
End Function


Function AskNum(p$) As Integer
  Local s$
  s$ = AskText$(p$, 4)
  AskNum = Val(s$)
End Function


' =====================================================================
'  ODDS AND ENDS
' =====================================================================
Function Dice(n) As Integer
  If n < 1 Then Dice = 0 Else Dice = Int(Rnd * Int(n)) + 1
End Function


Function NS$(n As Integer)
  Local t$
  t$ = Str$(n)
  Do While Left$(t$,1) = " " : t$ = Mid$(t$,2) : Loop
  NS$ = t$
End Function


' left justify in a field n characters wide
Function Pad$(s$, n As Integer)
  Local t$
  t$ = s$
  If Len(t$) > n Then t$ = Left$(t$, n)
  Do While Len(t$) < n : t$ = t$ + " " : Loop
  Pad$ = t$
End Function


' strip the leading space some BASICs put in front of a number
Function RPad$(s$, n As Integer)
  Local t$
  t$ = s$
  Do While Left$(t$,1) = " " : t$ = Mid$(t$,2) : Loop
  If Len(t$) > n Then t$ = Right$(t$, n)
  Do While Len(t$) < n : t$ = " " + t$ : Loop
  RPad$ = t$
End Function
