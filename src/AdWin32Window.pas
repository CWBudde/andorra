{
* This program is licensed under the Common Public License (CPL) Version 1.0
* You should have recieved a copy of the license with this file.
* If not, see http://www.opensource.org/licenses/cpl1.0.txt for more informations.
* 
* Inspite of the incompatibility between the Common Public License (CPL) and the GNU General Public License (GPL) you're allowed to use this program * under the GPL. 
* You also should have recieved a copy of this license with this file. 
* If not, see http://www.gnu.org/licenses/gpl.txt for more informations.
*
* Project: Andorra 2D
* Author:  Andreas Stoeckel
* File: AdWin32Window.pas
* Comment: Contains a non-vcl Win32 window.
}

{Contains a non-vcl Win32 window.}
unit AdWin32Window;

interface


uses
  Messages, Windows, AdEvents, AdWindowFramework;


type
  TAdWin32Window = class(TAdHandleWindowFramework)
    private
      FBinded:boolean;
      FInitialized:boolean;
      FWnd: TWndClassEx;
      FMsg: TMsg;
      FProps: TAdDisplayProperties;
      FWndProc : Pointer;
      FClose : boolean;
      FClicked : boolean;
      FDblClicked : boolean;
      function WndProc(hWnd: HWND; uMsg: UINT; wParam: wParam; lParam: LParam):lresult; stdcall;
      function MakeProcInstance(M: TMethod): Pointer;
      function ChangeResolution(width, height, bitdepth : LongWord):boolean;
      procedure PlaceWindow;

      function GetShift:TAdShiftState;
      function ParamToShift(Param:Longint):TAdShiftState;
      function GetXCoord(Param:Longint):Word;
      function GetYCoord(Param:Longint):Word;

      procedure ProcessMouseMove(wParam, lParam:LongInt);
      procedure ProcessMouseUp(msg: UInt; wParam, lParam:LongInt);
      procedure ProcessMouseDown(msg: UInt; wParam, lParam:LongInt);
      procedure ProcessMouseWheel(wParam, lParam: LongInt);
      procedure ProcessKey(msg:UInt; wParam: LongInt);
      function GetWindowClientRect:TRect;
    protected
      function GetClientWidth:integer;override;
      function GetClientHeight:integer;override;
      procedure SetTitle(AValue:string);override;
    public
      constructor Create;override;
      destructor Destroy;override;
      
      function BindTo(AObj:Pointer):boolean;override;
      function InitDisplay(AProps:TAdDisplayProperties):boolean;override;

      procedure Run;override;
  end;

implementation

{ TAdWin32Window }

constructor TAdWin32Window.Create;
var
  M : TMethod;
begin
  inherited Create;

  M.Code := @TAdWin32Window.WndProc;
  M.Data := self;
  FWndProc := MakeProcInstance(M);
end;

destructor TAdWin32Window.Destroy;
begin
  inherited;
end;

function TAdWin32Window.BindTo(AObj: Pointer): boolean;
begin
  FBinded := AObj = nil;
  result := FBinded;
end;

{Code written by Michael Puff (http://www.michael-puff.de/Artikel/2007/2007_08_02_CallbackMethod.php)}
function TAdWin32Window.MakeProcInstance(M: TMethod): Pointer;
begin
  // Ausf�hrbaren Speicher alloziieren f� 15 Byte an Code
  Result := VirtualAlloc(nil, 15, MEM_COMMIT, PAGE_EXECUTE_READWRITE);
  asm
    // MOV ECX,
    MOV BYTE PTR [EAX], $B9
    MOV ECX, M.Data
    MOV DWORD PTR [EAX+$1], ECX
    // POP EDX (bisherige R�cksprungadresse nach edx)
    MOV BYTE PTR [EAX+$5], $5A
    // PUSH ECX (self als Parameter 0 anf�gen)
    MOV BYTE PTR [EAX+$6], $51
    // PUSH EDX (R�cksprungadresse zur�ck auf den Stack)
    MOV BYTE PTR [EAX+$7], $52
    // MOV ECX, (Adresse nach ecx laden)
    MOV BYTE PTR [EAX+$8], $B9
    MOV ECX, M.Code
    MOV DWORD PTR [EAX+$9], ECX
    // JMP ECX (Sprung an den ersten abgelegten Befehl und Methode aufrufen)
    MOV BYTE PTR [EAX+$D], $FF
    MOV BYTE PTR [EAX+$E], $E1
    // hier kein Call, ansonsten w�rde noch eine R�cksprungadresse auf den Stack gelegt
  end;
end;

function TAdWin32Window.ChangeResolution(width, height,
  bitdepth: LongWord): boolean;
var
  DeviceMode: TDeviceModeA;
  i:integer;
begin
  result := false;
  i := 0;
  while EnumDisplaySettings(nil, i, DeviceMode) do
  begin
    with DeviceMode do
    begin
      if (dmPelsWidth = width) and (dmPelsHeight = height) and (dmBitsPerPel = bitdepth) then
      begin
        if ChangeDisplaySettings(DeviceMode, CDS_TEST) = DISP_CHANGE_SUCCESSFUL then
        begin
          result := true;
          ChangeDisplaySettings(DeviceMode, CDS_FULLSCREEN);
        end
        else
          exit;
      end;
    end;

    i := i + 1;
  end;
end;

function TAdWin32Window.InitDisplay(AProps: TAdDisplayProperties): boolean;
var
  WndStyle:Cardinal;
begin
  result := false;
  if (FBinded) and (not FInitialized) then
  begin

    if AProps.Mode = dmWindowed then
      WndStyle := WS_CAPTION or WS_VISIBLE or WS_SYSMENU
    else
    begin
      if AProps.Mode = dmFullscreen then
      begin
        if not ChangeResolution(AProps.Width, AProps.Height, AProps.BitDepth) then
        begin
          result := false;
          exit;
        end;
      end;
      WndStyle := WS_VISIBLE or WS_POPUP;
    end; 

    FProps := AProps;

    FWnd.cbSize := SizeOf(TWndClassEx);
    FWnd.style := CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS;
    FWnd.lpfnWndProc := FWndProc;
    FWnd.cbClsExtra := 0;
    FWnd.cbWndExtra := 0;
    FWnd.hbrBackground := CreateSolidBrush(0);
    FWnd.lpszMenuName := nil;
    FWnd.lpszClassName := 'WndClass';
    FWnd.hIconSm := 0;
    FWnd.hInstance := hInstance;
    FWnd.hIcon := LoadIcon(hInstance, MAKEINTRESOURCE(100));
    FWnd.hCursor := LoadCursor(0, IDC_ARROW);;

    RegisterClassEx(FWnd);
    FHandle := CreateWindowEx(0, 'WndClass', PChar(Title), WndStyle,
      0, 0, AProps.Width, AProps.Height, 0, 0, hInstance, nil);

    result := true;
    FInitialized := true;
  end;
end;

procedure TAdWin32Window.Run;
var
  Done:boolean;
begin
  while GetMessage(FMsg,0,0,0) do
  begin
    TranslateMessage(FMsg);
    DispatchMessage(FMsg);

    Done := true;
    if Assigned(Events.OnIdle) then Events.OnIdle(self, Done);
    while (not Done) and (not FClose) do
    begin
      if PeekMessage(FMsg, FHandle, 0, 0, PM_REMOVE) then
      begin
        TranslateMessage(FMsg);
        DispatchMessage(FMsg);
      end;
      
      Done := true;
      if Assigned(Events.OnIdle) then Events.OnIdle(self, Done);
    end;
  end;
end;

procedure TAdWin32Window.SetTitle(AValue: string);
begin
  inherited;
  if FInitialized then
  begin
    SendMessage(FHandle, WM_SETTEXT, 0, Integer(PChar(Title)));
  end;
end;

procedure TAdWin32Window.PlaceWindow;
var
  ScreenWidth, ScreenHeight : integer;
begin
  ScreenWidth := GetSystemMetrics(SM_CXSCREEN);
  ScreenHeight := GetSystemMetrics(SM_CYSCREEN);
  if FProps.Mode = dmWindowed then
  begin
    MoveWindow(FHandle,
      (ScreenWidth - FProps.Width) div 2,
      (ScreenHeight - FProps.Height) div 2,
      FProps.Width, FProps.Height, true);
  end
  else
  begin
    MoveWindow(FHandle, 0, 0, ScreenWidth, ScreenHeight, true);
  end;
end;

function TAdWin32Window.ParamToShift(Param: Integer): TAdShiftState;
begin
  result := [];
  if (Param and MK_LBUTTON = MK_LBUTTON) then
    result := result + [asLeft];
  if (Param and MK_RBUTTON = MK_RBUTTON) then
    result := result + [asRight];
  if (Param and MK_MBUTTON = MK_MBUTTON) then
    result := result + [asMiddle];
  if (Param and MK_SHIFT = MK_SHIFT) then
    result := result + [asShift];
  if (Param and MK_CONTROL = MK_CONTROL) then
    result := result + [asCtrl];
  if GetKeyState(VK_MENU) < 0 then
    result := result + [asAlt];
end;

function TAdWin32Window.GetClientHeight: integer;
var
  rect:TRect;
begin
  result := 0;
  if FInitialized then
  begin
    rect := GetWindowClientRect;
    result := rect.Bottom - rect.Top;
  end; 
end;

function TAdWin32Window.GetClientWidth: integer;
var
  rect:TRect;
begin
  result := 0;
  if FInitialized then
  begin
    rect := GetWindowClientRect;
    result := rect.Right - rect.Left;
  end;
end;

function TAdWin32Window.GetShift: TAdShiftState;
begin
  result := [];
  if GetKeyState(VK_SHIFT) < 0 then
    result := result + [asShift];
  if GetKeyState(VK_CONTROL) < 0 then
    result := result + [asCtrl];
  if GetKeyState(VK_MENU) < 0 then
    result := result + [asAlt];  
end;

function TAdWin32Window.GetWindowClientRect: TRect;
var
  info:TWindowInfo;
begin
  info.cbSize := SizeOf(TWindowInfo);
  if FInitialized then
  begin
    GetWindowInfo(FHandle, info);
    result := info.rcClient;
  end;
end;

function TAdWin32Window.GetXCoord(Param: Integer): Word;
begin
  result := Param and $0000FFFF;
  if result = High(Word) then result := 0;
end;

function TAdWin32Window.GetYCoord(Param: Integer): Word;
begin
  result := Param and $FFFF0000 shr 16;
  if result = High(Word) then result := 0;
end;


procedure TAdWin32Window.ProcessMouseMove(wParam, lParam: Integer);
begin
  if Assigned(Events.OnMouseMove) then
  begin
    Events.OnMouseMove(
      Self, ParamToShift(wParam), GetXCoord(lParam), GetYCoord(lParam));
  end;
end;

procedure TAdWin32Window.ProcessMouseDown(msg: UInt; wParam, lParam: Integer);
var
  btn:TAdMouseButton;
  dbl:boolean;
begin
  FClicked := false;
  FDblClicked := false;
  btn := abLeft;
  dbl := false;

  case msg of
    WM_LBUTTONDOWN: FClicked := true;
    WM_RBUTTONDOWN: btn := abRight;
    WM_MBUTTONDOWN: btn := abMiddle;   
    WM_LBUTTONDBLCLK:
      begin
        dbl := true;
        btn := abLeft;
        FDblClicked := true;
      end;
    WM_RBUTTONDBLCLK:
      begin
        dbl := true;
        btn := abRight;
      end;
    WM_MBUTTONDBLCLK:
      begin
        dbl := true;
        btn := abMiddle;
      end;
  end;

  if Assigned(Events.OnMouseDown) then
  begin
    if dbl then
      Events.OnMouseDown(Self, btn, ParamToShift(wParam), GetXCoord(lParam), GetYCoord(lParam))
    else
      Events.OnMouseDown(Self, btn, ParamToShift(wParam) + [asDouble], GetXCoord(lParam), GetYCoord(lParam));
  end;
end;

procedure TAdWin32Window.ProcessMouseUp(msg: UInt; wParam, lParam: Integer);
var
  btn:TAdMouseButton;
begin
  btn := abLeft;
  
  case msg of
    WM_LBUTTONDOWN: FClicked := true;
    WM_RBUTTONDOWN: btn := abRight;
    WM_MBUTTONDOWN: btn := abMiddle;
  end;

  if Assigned(Events.OnMouseDown) then
  begin
    Events.OnMouseUp(Self, btn, ParamToShift(wParam), GetXCoord(lParam), GetYCoord(lParam));
  end;
  if Assigned(Events.OnClick) and (FClicked) then
  begin
    Events.OnClick(Self, GetXCoord(lParam), GetYCoord(lParam));
  end;
  if Assigned(Events.OnClick) and (FDblClicked) then
  begin
    Events.OnDblClick(Self, GetXCoord(lParam), GetYCoord(lParam));
  end;

  FClicked := false;
  FDblClicked := false;
end;

procedure TAdWin32Window.ProcessMouseWheel(wParam, lParam: Integer);
var
  zDelta:SmallInt;
begin
  if Assigned(Events.OnMouseWheel) then
  begin
    zDelta := wParam and $FFFF0000 shr 16;
    Events.OnMouseWheel(Self, ParamToShift(wParam), zDelta, GetXCoord(lParam), GetYCoord(lParam));
  end;
end;

procedure TAdWin32Window.ProcessKey(msg:UInt; wParam: LongInt);
begin
  if Assigned(Events.OnKeyDown) and (msg = WM_KEYDOWN) then
  begin
    Events.OnKeyDown(Self, wParam, GetShift);
  end else
  if Assigned(Events.OnKeyUp) and (msg = WM_KEYUP) then
  begin
    Events.OnKeyUp(Self, wParam, GetShift);
  end;
end;

function TAdWin32Window.WndProc(hWnd: HWND; uMsg: UINT; wParam: wParam;
  lParam: LParam): lresult;
var
  CanClose : boolean;
begin
  Result := 0;

  case uMsg of
    WM_CREATE:
      begin
        FHandle := hWnd;
        PlaceWindow;
      end;
    WM_DESTROY:
      begin
        FClose := true;
        PostQuitMessage(0);
      end;
    WM_PAINT:
      if Assigned(Events.OnPaint) then Events.OnPaint(Self);
    WM_SIZE:
      if Assigned(Events.OnResize) then Events.OnResize(Self);
    WM_ACTIVATE:
      begin
        if (wParam and WA_ACTIVE = WA_ACTIVE) or
           (wParam and WA_CLICKACTIVE = WA_CLICKACTIVE) then
        begin
          if Assigned(Events.OnActivate) then Events.OnActivate(Self);
        end
        else
        begin
          if Assigned(Events.OnDeactivate) then Events.OnDeactivate(Self);
        end;
      end;
    WM_MOUSEMOVE:
      ProcessMouseMove(wParam, lParam);
    WM_LBUTTONDOWN, WM_RBUTTONDOWN, WM_MBUTTONDOWN,
    WM_LBUTTONDBLCLK, WM_RBUTTONDBLCLK, WM_MBUTTONDBLCLK:
      ProcessMouseDown(uMsg, wParam, lParam);
    WM_LBUTTONUP, WM_RBUTTONUP, WM_MBUTTONUP:
      ProcessMouseUp(uMsg, wParam, lParam);
    WM_CLOSE:
      begin
        CanClose := true;
        if Assigned(Events.OnClose) then Events.OnClose(Self, CanClose);
        if CanClose then
          result := DefWindowProc(hWnd, uMsg, wParam, lParam)
        else
          result := 0;
      end;
    WM_MOUSEWHEEL:
      ProcessMouseWheel(wParam, lParam);
    WM_KEYDOWN, WM_KEYUP:
      ProcessKey(uMsg, wParam);
    WM_CHAR:
      if Assigned(Events.OnKeyPress) then Events.OnKeyPress(Self, Chr(wParam));
  else
    Result := DefWindowProc(hWnd, uMsg, wParam, lParam);
  end;
end;

initialization
  RegisterWindowFramework(TAdWin32Window);

end.