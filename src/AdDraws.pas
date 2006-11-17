{
* This program is licensed under the GNU Lesser General Public License Version 2
* You should have recieved a copy of the license with this file.
* If not, see http://www.gnu.org/licenses/lgpl.html for more informations
*
* Project: Andorra 2D
* Author:  Andreas Stoeckel
* File: AdDraws.pas
* Comment: This unit contais the main Andorra 2D Component (TAdDraw) comparable to TDXDraw 
}

{ Contains the main Andorra Classes for graphic output }
unit AdDraws;

interface

uses Windows, Classes, AndorraUtils, Andorra, Graphics;

type


  TAdDrawBitCount = byte;

  {Specifies the dimensions of the display.

  However, remember that this settings will be ignored, when fullscreen isn't turned on.
  To use fullscreen turn the "doFullscreen" property in the "Options" on.}
  TAdDrawDisplay = record
    //The Width of the Display
    Width:integer;
    //The Height of the Display
    Height:integer;
    //The Bitcount of the Display (May be 16 or 32 (and normaly 24, but this is, whyever, very buggy...) )
    BitCount:TAdDrawBitCount;
  end;

  {Specifies the options the application is created with.

  If you change these settings while running, simply call the "restore" function of TAdDraw.}
  TAdDrawMode = (
    doFullscreen,  //< Specifies weather the application should run in the fullscreen mode or not
    doWaitVBlank, //< If turned on, the frame rate is equal to the vertical frequenzy of the screen
    doStretch, //< Should the picture be stretched when the window resizes?
    doHardware,//< Run in hardware mode? (WARNING: Should be set!)
    doZBuffer, //< The ZBuffer has to be used if you are using 3D Objects in your scene
    doAntialias,//< should Antialiasing be used
    doSystemMemory//< use system memory instead of video memory for textures?
  );
  {Declares a set of TAdDrawMode. See above to learn what all these settings mean.}
  TAdDrawModes = set of TAdDrawMode;

  {This is the main class for using Andorra 2D. It is comparable to DelphiX's TDXDraw.}
  TAdDraw = class
  private

    FParent:HWND;
    FOptions:TAdDrawModes;
    FDllName:string;
    FFinalize:TNotifyEvent;
    FInitialize:TNotifyEvent;
    FInitialized:boolean;
    FDisplay:TAdDrawDisplay;

    procedure SetDllName(val : string);

    procedure SetupThings;

  protected
    DisplayWidth,DisplayHeight:integer;
  public
    {The Andorra Dll Loader. You can use this class to get direct control over
    the engine.}
    AdDllLoader : TAndorraDllLoader;
    {The Andorra Reference for the DllLoader}
    AdAppl:TAndorraApplication;

    //Create the class. AParent is the handle of the control, where displaying should take place.
    constructor Create(AParent : HWND);
    //This is a destroctor.
    destructor Destroy; override;

    //Here you can read the parent value, you've set in the constructor.
    property Parent : HWND read FParent;

    //Initialize the application with all parameters set in "options". Returns false if the operation failed.
    function Initialize: boolean;
    //Finalize the application
    procedure Finalize;

    //Fills the Surface with a specific color.
    procedure ClearSurface(Color:TColor);
    //Starts the output. All graphic commands have to come after this command.
    procedure BeginScene;
    //Ends the output. All graphic commands have to come before this command.
    procedure EndScene;
    //Set the projection matrix and the camera to a 2D perspective.
    procedure Setup2DScene;
    //Flip the backbuffer and the frontbuffer and display the current picture.
    procedure Flip;

    //Returns weather Andorra is ready to draw
    function CanDraw:boolean;
  published
    //This property contains the diplay settings (width, height and bitcount)
    property Display: TAdDrawDisplay read FDisplay write FDisplay;
    //This property contains the options (see TAdDrawMode)
    property Options : TAdDrawModes read FOptions write FOptions;
    //Set this value to load a library
    property DllName : string read FDllName write SetDllName;
    //Returns weather the application is initialized
    property Initialized : boolean read FInitialized;

    //Event is called before the application is finalized
    property OnFinalize : TNotifyEvent read FFinalize write FFinalize;
    //Event is called after the application is initialized
    property OnInitialize : TNotifyEvent read FInitialize write FInitialize;
  end;

  {TAdTexture basicly loads a texture from a bitmap or a file into the video memory}
  TAdTexture = class
    private
      FParent:TAdDraw;
      FWidth:integer;
      FHeight:integer;
      FBaseRect:TRect;
      function GetLoaded:boolean;
    protected
      AdTexture:TAndorraTexture;
    public
      {This is a constructor. AADraw defines the parent andorra application.}
      constructor Create(AAdDraw:TAdDraw);
      destructor Destroy;override;
      procedure LoadFromFile(afile:string;ATransparent:boolean;ATransparentColor:TColor);
      procedure LoadFromBitmap(ABitmap:TBitmap);
      procedure AddAlphaChannel(ABitmap:TBitmap);
      procedure SetAlphaValue(AValue:byte);
      procedure FreeTexture;

      property Parent:TAdDraw read FParent write FParent;
      property Loaded:boolean read GetLoaded;
      property Width:integer read FWidth;
      property Height:integer read FHeight;
      {If a loaded texture has a size which sizes are not power of two, it will be resized.
      To keep the original image size it will be stored into BaseRect.}
      property BaseRect:TRect read FBaseRect;
  end;

  type TRectList = class(TList)
    private
     	function GetItem(AIndex:integer):TRect;
     	procedure SetItem(AIndex:integer;AItem:TRect);
      protected
    public
     	property Items[AIndex:integer]:TRect read GetItem write SetItem;default;
      procedure Add(ARect:TRect);
      procedure Clear;override;
    published
  end;

  TPictureCollectionItem = class
    private
      FParent:TAdDraw;
      FWidth,FHeight:integer;
      FPatternWidth,FPatternHeight:integer;
      FTexture:TAdTexture;
      procedure SetPatternWidth(AValue:integer);
      procedure SetPatternHeight(AValue:integer);
      function GetPatternCount:integer;
    protected
      Rects:TRectList;
      procedure CreatePatternRects;
    public
      AdImage:TAndorraImage;
      constructor Create(AAdDraw:TAdDraw);
      destructor Destroy;
      procedure Draw(ASurface:TAdDraw;X,Y,PatternIndex:integer);
      procedure Restore;
      function GetPatternRect(ANr:integer):TRect;
      property Parent:TAdDraw read FParent write FParent;
      property Width:integer read FWidth;
      property Height:integer read FHeight;
      property PatternWidth:integer read FPatternWidth write SetPatternWidth;
      property PatternHeight:integer read FPatternHeight write SetPatternHeight;

      property Texture:TAdTexture read FTexture;
      property PatternCount:integer read GetPatternCount;
  end;

implementation

{ TAdDraw }

constructor TAdDraw.Create(AParent : HWND);
begin
	inherited Create;
  FParent := AParent;
  AdDllLoader := TAndorraDllLoader.Create;

  SetupThings;
end;

procedure TAdDraw.SetupThings;
begin
  //Initialize all Parameters
  with FDisplay do
  begin
    Width := 800;
    Height := 600;
    BitCount := 32;
  end;

  FOptions := [doHardware];
end;

destructor TAdDraw.Destroy;
begin
  //Free all loaded objects
  if AdAppl <> nil then
  begin
    AdDllLoader.DestroyApplication(AdAppl);
  end;
  
  AdDllLoader.Destroy;
	inherited Destroy;
end;

procedure TAdDraw.SetDllName(val : string);
begin
  if val <> FDllName then
  begin
    //If the Library is changed, the system will shut down
    Finalize;

    FDllName := val;

    //Load the new Library
    AdDllLoader.LoadLibrary(val);
  end;
end;

function TAdDraw.Initialize: boolean;
var ARect:TRect;
begin

  result := false;

  if not Initialized then
  begin
    //Create the new Application
    AdAppl := AdDllLoader.CreateApplication;

    if (AdAppl <> nil) and (FParent <> 0) and (AdDllLoader.LibraryLoaded) then
    begin
      //Initialize Andorra 2D
      if doFullscreen in FOptions then
      begin
        //Set a new window position and change the borderstyle to WS_POPUP = bsNone
        SetWindowPos(FParent,HWND_TOPMOST,0,0,FDisplay.Width,FDisplay.Height,SWP_SHOWWINDOW);
        SetWindowLong(FParent,GWL_STYLE,WS_POPUP);

        DisplayWidth := FDisplay.Width;
        DisplayHeight := FDisplay.Height;

        result := AdDllLoader.InitDisplay(AdAppl,FParent, doHardware in FOptions,
              doFullscreen in FOptions, FDisplay.BitCount, FDisplay.Width, Display.Height);
      end
      else
      begin
        //Get the rect of the window
        GetClientRect(FParent,ARect);

        DisplayWidth := ARect.Right-ARect.Left;
        DisplayHeight := ARect.Bottom-ARect.Top;

        result := AdDllLoader.InitDisplay(AdAppl,FParent, doHardware in FOptions,
              doFullscreen in FOptions, FDisplay.BitCount, DisplayWidth, DisplayHeight);
      end;
      AdDllLoader.SetTextureQuality(AdAppl,tqNone);
      Setup2DScene;
    end;

    if Assigned(FInitialize) then
    begin
      //OnInitialize
      FInitialize(Self);
    end;

    FInitialized := result;
  end;
end;

procedure TAdDraw.Finalize;
begin
  if Assigned(FFinalize) then
  begin
    FFinalize(Self);
  end;

  if AdAppl <> nil then
  begin
    AdDllLoader.DestroyApplication(AdAppl);
    AdAppl := nil;
    FInitialized := false;
  end;
end;

procedure TAdDraw.ClearSurface(Color:TColor);
begin
  AdDllLoader.ClearScene(AdAppl,Ad_RGB(GetRValue(Color),GetGValue(Color),GetBValue(Color)));
end;

procedure TAdDraw.BeginScene;
begin
  if AdAppl <> nil then
  begin
    AdDllLoader.BeginScene(AdAppl);
  end;
end;

procedure TAdDraw.EndScene;
begin
  if AdAppl <> nil then
  begin
    AdDllLoader.EndScene(AdAppl);
  end;
end;

procedure TAdDraw.Setup2DScene;
begin
  if AdAppl <> nil then
  begin
    AdDllLoader.SetupScene(AdAppl,DisplayWidth,DisplayHeight);
  end;
end;

procedure TAdDraw.Flip;
begin
  if AdAppl <> nil then
  begin
    AdDllLoader.Flip(AdAppl);  
  end;
end;

function TAdDraw.CanDraw:boolean;
begin
  result := (AdAppl <> nil) and (Initialized);
end;

{TAdTexture}

constructor TAdTexture.Create(AAdDraw:TAdDraw);
begin
  inherited Create;
  AdTexture := nil;
  FParent := AAdDraw;
end;

destructor TAdTexture.Destroy;
begin
  FreeTexture;
  inherited Destroy;
end;

procedure TAdTexture.LoadFromFile(afile:string;ATransparent:boolean;ATransparentColor:TColor);
var FTransparentColor:TAndorraColor;
    Info:TImageInfo;
begin
  FreeTexture;
  FTransparentColor := Ad_ARGB(0,0,0,0);
  if ATransparent then
  begin
    FTransparentColor := Ad_ARGB(255,GetRValue(ATransparentColor),GetGValue(ATransparentColor),GetBValue(ATransparentColor));
  end;
  AdTexture := FParent.AdDllLoader.LoadTextureFromFile(FParent.AdAppl,PChar(Afile),FTransparentColor);
  Info := FParent.AdDllLoader.GetTextureInfo(AdTexture);
  FWidth := Info.Width;
  FHeight := Info.Height;
  FBaseRect := Info.BaseRect;
end;

procedure TAdTexture.LoadFromBitmap(ABitmap:TBitmap);
var FColorDepth:byte;
    Info:TImageInfo;
begin
  FreeTexture;
  case ABitmap.PixelFormat of
    pf16bit: FColorDepth := 16;
    pf32bit: FColorDepth := 32;
  else
    FColorDepth := 32;
  end;
  AdTexture := FParent.AdDllLoader.LoadTextureFromBitmap(Fparent.AdAppl,ABitmap,FColorDepth);
  Info := FParent.AdDllLoader.GetTextureInfo(AdTexture);
  FWidth := Info.Width;
  FHeight := Info.Height;
  FBaseRect := Info.BaseRect;
end;

procedure TAdTexture.AddAlphaChannel(ABitmap:TBitmap);
begin
  if AdTexture <> nil then
  begin
    FParent.AdDllLoader.AddTextureAlphaChannel(AdTexture,ABitmap);
  end;
end;

procedure TAdTexture.SetAlphaValue(AValue:byte);
begin
  //
end;

procedure TAdTexture.FreeTexture;
begin
  if AdTexture <> nil then
  begin
    FParent.AdDllLoader.FreeTexture(AdTexture);
  end;
end;

function TAdTexture.GetLoaded:boolean;
begin
  result := AdTexture <> nil;
end;

{TRectList}

procedure TRectList.Add(ARect: TRect);
var ar:PRect;
begin
  new(ar);
  ar^ := ARect;
  inherited Add(ar);
end;

procedure TRectList.Clear;
var i:integer;
begin
  while Count > 0 do
  begin
    FreeMem(inherited Items[0]);
    Delete(0);
  end;
end;

function TRectList.GetItem(AIndex:integer):TRect;
begin
  result := PRect(inherited Items[AIndex])^;
end;

procedure TRectList.SetItem(AIndex:integer;AItem:TRect);
begin
  PRect(inherited Items[AIndex])^ := AItem;
end;


{TPictureCollectionItem}

constructor TPictureCollectionItem.Create(AAdDraw:TAdDraw);
begin
  inherited Create;
  FTexture := TAdTexture.Create(AAdDraw);
  FParent := AAdDraw;
  AdImage := FParent.AdDllLoader.CreateImage(AAdDraw.AdAppl);
  Rects := TRectList.Create;
end;

destructor TPictureCollectionItem.Destroy;
begin
  FTexture.Free;
  FParent.AdDllLoader.DestroyImage(AdImage);
  Rects.Free;
  inherited Destroy;
end;

procedure TPictureCollectionItem.CreatePatternRects;
var ax,ay:integer;
begin
  Rects.Clear;
  with Texture.BaseRect do
  begin
    if (FPatternWidth <> 0) and (FPatternHeight <> 0) then
    begin
      for ay := 0 to (Bottom div PatternHeight) - 1 do
      begin
        for ax := 0 to (Right div PatternWidth) - 1 do
        begin
          Rects.Add(Rect(ax*PatternWidth,ay*PatternHeight,
            (ax+1)*PatternWidth,(ay+1)*PatternHeight));
        end;
      end;
    end
    else
    begin
      Rects.Add(Rect(0,0,Right,Bottom));
    end;
  end;
end;

procedure TPictureCollectionItem.Draw(ASurface:TAdDraw;X,Y,PatternIndex:integer);
begin
  if (FPatternWidth <> 0) and (FPatternHeight <> 0) then
  begin
    FParent.AdDllLoader.DrawImage(
      FParent.AdAppl,AdImage,Rect(X,Y,X+PatternWidth,Y+PatternHeight),Rects[PatternIndex],
      0,0,0,bmAlpha);
  end
  else
  begin
    FParent.AdDllLoader.DrawImage(
      FParent.AdAppl,AdImage,Rect(X,Y,X+Width,Y+Height),Rects[PatternIndex],
      0,0,0,bmAlpha);
  end;
end;

procedure TPictureCollectionItem.Restore;
begin
  with FParent.AdDllLoader do
  begin
    if FTexture.Loaded then
    begin
      ImageLoadTexture(AdImage,FTexture.AdTexture);
      FWidth := Texture.BaseRect.Right;
      FHeight := Texture.BaseRect.Bottom;
      CreatePatternRects;
    end;
  end;
end;

procedure TPictureCollectionItem.SetPatternWidth(AValue: Integer);
begin
  FPatternWidth := AValue;
  CreatePatternRects;
end;

procedure TPictureCollectionItem.SetPatternHeight(AValue: Integer);
begin
  FPatternHeight := AValue;
  CreatePatternRects;
end;

function TPictureCollectionItem.GetPatternCount: integer;
begin
  result := Rects.Count;
end;

function TPictureCollectionItem.GetPatternRect(ANr: Integer):TRect;
begin
  result := Rects[ANr];
end;


end.
