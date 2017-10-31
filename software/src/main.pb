Declare ProcessData(InputData.s)

IncludeFile "code\Xors3d.pbi"
IncludeFile "code\Serial.pb"

xGraphics3D(950, 500, 32, #False, #True)
xsetbuffer(xbackbuffer())

xAppTitle("PF TEST")

Global FontTitle = xLoadFont("segoe ui light", 14)
Global FontText  = xLoadFont("segoe ui light", 9)

Structure tTest
  ID.i
  Limit.i
  PassCount.i
  Result.i
  
  Saved.b
EndStructure
Global NewList Tests.tTest()

Structure tPass
  *Test.tTest
  ID.i
  Line.i
  Value.i
EndStructure 
Global NewList Passes.tPass()

Structure tCommand
  Text.s
EndStructure
Global NewList Commands.tCommand()

Global CurrentTestID

Global MousePosX, MousePosY, MouseHitL

Procedure AddTest(TestID, TestLimit, TestPasses)
  ForEach Passes()
    If Passes()\Test\ID = TestID
      DeleteElement(Passes())
    EndIf
  Next
  
  ForEach Tests()
    If Tests()\ID = TestID
      DeleteElement(Tests())
    EndIf   
  Next
  
  AddElement(Tests())
  With Tests()
    \ID        = TestID
    \Limit     = TestLimit
    \PassCount = TestPasses
    \Result    = -1
  EndWith
  
  CurrentTestID = TestID
  
  Debug "newtest: " + Str(Tests()\ID)
EndProcedure

Procedure AddPass(PassID, PassLine)
  If ListSize(Tests()) = 0: ProcedureReturn: EndIf

  AddElement(Passes())
  
  With Passes()
    \ID   = PassID
    \Line = PassLine
    ;\Test = Tests()
    
    PushListPosition(Tests())
    ForEach Tests()
      If Tests()\ID = CurrentTestID
        \Test = Tests()
        Break
      EndIf
    Next
    PopListPosition(Tests())
    
  EndWith
  
  Debug "newpass: " + Str(Passes()\ID) + " of test " + Str(Passes()\Test\ID)
EndProcedure

Procedure AddValue(PassValue)  
  If ListSize(Passes()) = 0: ProcedureReturn: EndIf
  

  LastElement(Passes())
  
  Passes()\Value + PassValue

  Debug "newvalue: " + Str(Passes()\Value) + " of pass " + Str(Passes()\ID) + " of test " + Str(Passes()\Test\ID)
EndProcedure

Procedure AddResult(Result)
  If ListSize(Tests()) = 0: ProcedureReturn: EndIf
  
  LastElement(Tests())
  
  Tests()\Result = Result
  
  CurrentTestID = 0
  
  Debug "newresult: " + Str(Result) + " of test " + Str(Tests()\ID)
EndProcedure

Procedure FreeTests()
  ClearList(Tests())
  ClearList(Passes())
  
  CurrentTestID = 0
EndProcedure

Procedure SaveTest()
  PauseThread(SThread)
  
  CreateDirectory("logs")
  
  TestFile = OpenFile(0, "logs\test_" + Str(Tests()\ID) +"_"+FormatDate("%hh.%ii.%ss", Date()) + ".txt")
  
  ForEach Passes()
    With Passes()
      
      If \Test\ID = Tests()\ID
        WriteStringN(0, Str(\ID) + ":  " +  Str(\Value) + " \ " + Str(\Line))
      EndIf
    EndWith
  Next
  
  WriteStringN(0, "RESULT: " + Str(Tests()\Result) + "%")
  
  CloseFile(0)
  
  Tests()\Saved = #True
  
  ResumeThread(SThread)
EndProcedure

Procedure ProcessData(InputData.s)
  
  AddElement(Commands())
  
  Commands()\Text = InputData
EndProcedure

Procedure DoCommands()
  
  Protected TestID, TestLimit, TestPasses
  
  Protected PassID, PassLine
  
  
  ForEach Commands()
    With Commands()
  
      If FindString(\Text, "test", 1, #PB_String_NoCase)
        TestID     = Val(StringField(\Text, 2, ":"))
        TestLimit  = Val(StringField(\Text, 3, ":"))
        TestPasses = Val(StringField(\Text, 4, ":"))
        AddTest(TestID, TestLimit, TestPasses)
      EndIf
      
      If FindString(\Text, "pass", 1, #PB_String_NoCase)
        PassID   = Val(StringField(\Text, 2, ":"))
        PassLine = Val(StringField(\Text, 3, ":"))
        AddPass(PassID, PassLine)
      EndIf 
      
      If FindString(\Text, "plus", 1, #PB_String_NoCase)
        AddValue(Val(StringField(\Text, 2, ":")))
      EndIf 
        
      If FindString(\Text, "select", 1, #PB_String_NoCase)
        CurrentTestID = 0
      EndIf
      
      If FindString(\Text, "result", 1, #PB_String_NoCase)
        AddResult(Val(StringField(\Text, 2, ":")))
      EndIf
      
      DeleteElement(Commands())
    
    EndWith
  Next
EndProcedure

#GUI_Offset = 50
#GUI_TestWidth  = 250
#GUI_TestHeight = 300
#GUI_FrameOffset = 20
#GUI_FrameWidth  = #GUI_TestWidth - 60
#GUI_FrameHeight = #GUI_FrameWidth
#GUI_ButtonWidth  = 80
#GUI_ButtonHeight = 30

Procedure DrawButton(GUI_ButtonX, GUI_ButtonY, Text.s, Disable = #False)
  
  Protected ButtonStatus
  
  xSetFont(TextFont)
  
  xColor(0, 0, 0, 24)
  xRect(GUI_ButtonX, GUI_ButtonY, #GUI_ButtonWidth, #GUI_ButtonHeight, #True)
  
  xColor(64, 64, 64, 64)
  xText(GUI_ButtonX + #GUI_ButtonWidth / 2, GUI_ButtonY + #GUI_ButtonHeight / 2, Text, #True, #True)
  
  If Disable: ProcedureReturn: EndIf
  
  xColor(64, 64, 64, 255)
  xText(GUI_ButtonX + #GUI_ButtonWidth / 2, GUI_ButtonY + #GUI_ButtonHeight / 2, Text, #True, #True)
  
  If MousePosX > GUI_ButtonX And MousePosX < GUI_ButtonX + #GUI_ButtonWidth
    If MousePosY > GUI_ButtonY And MousePosY < GUI_ButtonY + #GUI_ButtonHeight
      
      xColor(0, 128, 192, 255)
      xRect(GUI_ButtonX, GUI_ButtonY, #GUI_ButtonWidth, #GUI_ButtonHeight, #True)
  
      xColor(255, 255, 255, 255)
      xText(GUI_ButtonX + #GUI_ButtonWidth / 2, GUI_ButtonY + #GUI_ButtonHeight / 2, Text, #True, #True)
      
      ButtonStatus = MouseHitL
    EndIf
  EndIf

  ProcedureReturn ButtonStatus   
EndProcedure

Procedure DrawPasses(GUI_FrameX, GUI_FrameY)
  Protected GUI_PassX, GUI_PassY, GUI_PassWidth, GUI_PassLine, GUI_PassValue
  
  PushListPosition(Passes())
  
  ForEach Passes()

    If Passes()\Test = Tests()
      
      GUI_PassWidth = #GUI_FrameWidth / Passes()\Test\PassCount
      
      GUI_PassLine  = #GUI_FrameHeight * (1.0 * Passes()\Line / Passes()\Test\Limit)
      
      GUI_PassValue = #GUI_FrameHeight * (1.0 * Passes()\Value / Passes()\Test\Limit)
      
      If GUI_PassValue > #GUI_FrameHeight
        GUI_PassValue =   #GUI_FrameHeight
      EndIf
      
      GUI_PassX = GUI_FrameX + (Passes()\ID-1) * GUI_PassWidth
      GUI_PassY = GUI_FrameY + (#GUI_FrameHeight - GUI_PassLine)
      
      xColor(0, 0, 0, 24)
      xRect(GUI_PassX, GUI_PassY, GUI_PassWidth, GUI_PassLine, #True)
      
      xColor(0, 128, 192, 255)
      xSetFont(TextFont)
      xText(GUI_FrameX + #GUI_FrameWidth + 5, GUI_PassY, Str(Passes()\Line), #False, #True)

      GUI_PassY = GUI_FrameY + (#GUI_FrameHeight - GUI_PassValue)
      
      xColor(0, 128, 192, 255)
      xRect(GUI_PassX, GUI_PassY, GUI_PassWidth, GUI_PassValue, #True)
      
      If MousePosX > GUI_PassX And MousePosX < GUI_PassX + GUI_PassWidth
        If MousePosY > GUI_PassY And MousePosY < GUI_PassY + GUI_PassValue
          
          xRect(GUI_FrameX + #GUI_FrameWidth + 2, GUI_PassY - 8, xStringWidth(Str(Passes()\Value)) + 6, 16, #True)
          
          xColor(255, 255, 255, 255)
          xText(GUI_FrameX + #GUI_FrameWidth + 5, GUI_PassY, Str(Passes()\Value), #False, #True)
          
          xColor(255, 255, 255, 60)
          xRect(GUI_PassX, GUI_PassY, GUI_PassWidth, GUI_PassValue, #True)
          
        EndIf
      EndIf
      
    EndIf
  Next
  
  PopListPosition(Passes())
EndProcedure

Procedure DrawTests()

  Protected GUI_TestX, GUI_TestY
  Protected GUI_FrameX, GUI_FrameY
  Protected GUI_ButtonX, GUI_ButtonY
  
  MousePosX = xMouseX()
  MousePosY = xMouseY()
  MouseHitL = xMouseHit(#MOUSE_LEFT)
  
  PushListPosition(Tests())
  
  ForEach Tests()
    With Tests()
      
      GUI_TestX = (\ID-1) * (#GUI_TestWidth + #GUI_Offset) + #GUI_Offset
      GUI_TestY = #GUI_Offset
      
      GUI_FrameX = GUI_TestX + #GUI_FrameOffset
      GUI_FrameY = GUI_TestY + 40
      
      GUI_ButtonX = GUI_TestX + #GUI_TestWidth - #GUI_ButtonWidth - #GUI_FrameOffset 
      GUI_ButtonY = GUI_TestY + #GUI_TestHeight - #GUI_ButtonHeight - #GUI_FrameOffset
      
      xColor(245, 245, 245, 255)
      xRect(GUI_TestX, GUI_TestY, #GUI_TestWidth, #GUI_TestHeight, #True)
      
      xColor(64, 64, 64, 255)
      xRect(GUI_TestX, GUI_TestY, #GUI_TestWidth, #GUI_TestHeight, #False)
      
      xSetFont(FontTitle)
      xColor(0, 128, 192, 255)
      xText(GUI_FrameX, GUI_TestY + 7, "Test " + Str(\ID))
      
      xColor(0, 0, 0, 10)
      xRect(GUI_FrameX, GUI_FrameY, #GUI_FrameWidth, #GUI_FrameHeight, #True)
          
      DrawPasses(GUI_FrameX, GUI_FrameY)
      
      xColor(0, 128, 192, 255)
      xLine(GUI_FrameX, GUI_FrameY, GUI_FrameX, GUI_FrameY + #GUI_FrameHeight)
      xLine(GUI_FrameX, GUI_FrameY + #GUI_FrameHeight, GUI_FrameX + #GUI_FrameWidth, GUI_FrameY + #GUI_FrameHeight)

      If \Result > -1
        xColor(0, 128, 192, 255)
        xSetFont(TextFont)
        xText(GUI_FrameX, GUI_ButtonY + #GUI_ButtonHeight/ 2, "result: " + Str(\Result) + "%", #False, #True)  

        If DrawButton(GUI_ButtonX, GUI_ButtonY, "save", \Saved)
          SaveTest()
        EndIf
      EndIf

      If CurrentTestID = \ID Or CurrentTestID = 0: Continue: EndIf
      
      xColor(0, 0, 0, 60)
      xRect(GUI_TestX, GUI_TestY, #GUI_TestWidth, #GUI_TestHeight, #True)    
      
    EndWith
  Next
  
  PopListPosition(Tests())
  
  
EndProcedure

xClsColor(128, 128, 128, 255)

While Not (xKeyDown(#KEY_ESCAPE) Or xWinMessage("WM_CLOSE"))
  xcls()
  
  xSetFont(FontText)
  xColor(255, 255, 255, 92)
  xtext(10, 10, Str(xGetFPS()))
  
  DoCommands()
  
  DrawTests()
  
  xFlip()
Wend

KillThread(SThread)

End
; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 3
; FirstLine = 59
; Folding = Ah
; EnableXP
; Executable = PF-TEST.exe