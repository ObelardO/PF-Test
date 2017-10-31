#PortID = 0

#BufferSize = 5

Global *BufferData = AllocateMemory(#BufferSize)

Global DataLength.i
Global DataString.s

Global DrawString.s
Global TempChar.s

Global SThread

Global SerialStatus.b

OpenWindow(0, 0, 0, 220, 120, "PF TEST",  #PB_Window_SystemMenu | #PB_Window_ScreenCentered)

Frame3DGadget(1, 10, 10, 200, 100, "Connection")

TextGadget(2,  20, 30, 180, 20, "Port:")

ComboBoxGadget(3, 100, 30, 100, 20)
For i = 1 To 50
  AddGadgetItem(3, -1, "COM" + Str(i))
Next

SetGadgetState(3, 0)

ButtonGadget(4, 20, 80, 85, 20, "Connect")

ButtonGadget(5, 115, 80, 85, 20, "Start")
DisableGadget(5, #True)

TextGadget(6,  20, 60, 180, 20, "Status: wait connection")


Procedure Connect()
  If OpenSerialPort(#PortID, GetGadgetText(3), 9600, #PB_SerialPort_NoParity, 8, 1, #PB_SerialPort_NoHandshake, 1024, 1024)
    Debug "Success"
    
    SerialStatus = #True
    
    ProcedureReturn #True
  EndIf
  
  SerialStatus = #False

  Debug "Failed"
  ProcedureReturn #False
EndProcedure

Procedure DisConnect()
  If IsSerialPort(#PortID)
    CloseSerialPort(#PortID)
  EndIf
  
  SerialStatus = #False
EndProcedure

Procedure SerialThread(*args)  
  Repeat
    
    If IsSerialPort(#PortID)
  
    If AvailableSerialPortInput(#PortID)
      
      DataLength = ReadSerialPortData(#PortID, *BufferData, #BufferSize)
      
      DataString = PeekS(*BufferData, DataLength)
      
      For i = 1 To Len(DataString)
        TempChar = Mid(DataString, i, 1)
        
        If TempChar = Chr(13)          
          ProcessData(DrawString)
          DrawString = ""
        Else
          DrawString + TempChar
        EndIf
      Next

    EndIf
    
  Else 
    SerialStatus = #False

    EndIf
  ForEver 
EndProcedure

Repeat
  Event = WaitWindowEvent()
  
  Select Event
      
    Case #PB_Event_Gadget
      
      Select EventGadget()
          
        Case 3 ; ComboBox
          
          TextGadget(6,  20, 60, 180, 20, "Status: wait connection")
          SetGadgetColor(6, #PB_Gadget_FrontColor, RGB(0, 0, 0))
          
          DisableGadget(5, #True)
          DisableGadget(4, #False)
          
          DisConnect()
          
          If IsThread(SThread): KillThread(SThread): EndIf
          
        Case 4 ; Button Connect
          
          If Connect()
            DisableGadget(5, #False)
            DisableGadget(4, #True)
            
            TextGadget(6,  20, 60, 180, 20, "Status: success")
            SetGadgetColor(6, #PB_Gadget_FrontColor, RGB(0, 128, 0))
          Else
            TextGadget(6,  20, 60, 180, 20, "Status: failed")
            SetGadgetColor(6, #PB_Gadget_FrontColor, RGB(128, 0, 0))
          EndIf
          
        Case 5 ; Start Gadget
          
          CloseWindow(0)
          
          SThread = CreateThread(@SerialThread(), 0)
          
          
          
          Break
          
            
          
          
      EndSelect
     
  
    Case #PB_Event_CloseWindow  ; If the user has pressed on the close button
      
      DisConnect()
      End
      
  EndSelect

ForEver

; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 24
; FirstLine = 16
; Folding = -
; EnableXP
; Executable = FP-TEST.exe