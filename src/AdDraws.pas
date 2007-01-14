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

uses Windows, Controls, Math, Types, SysUtils, Classes, AdClasses, AdDllLoader,
     Graphics, Dialogs, Huffman;

type

  {This is the main class for using Andorra 2D. It is comparable to DelphiX's TDXDraw.}
  TAdDraw = class;
  //This represents one image in an ImageList.
  TPictureCollectionItem = class;

  {Specifies a textures texture state.}
  TTextureMode = (tmWrap,tmMirror,tmClamp);
  {Specifies the event which called the procedure}
  TSurfaceEventState = (seInitialize,seFinalize,seInitialized);
  {The declaration of the surface event handler}
  TSurfaceEvent = procedure(Sender:TObject;AEvent:TSurfaceEventState) of object;
  {A pointer on TSurfaceEvent}
  PSurfaceEvent = ^TSurfaceEvent;
  {A list which contains the surface events}
  TSurfaceEventList = class(TList)
    private
      function GetItem(AIndex:integer):TSurfaceEvent;
      procedure SetItem(AIndex:integer;AItem:TSurfaceEvent);
    protected
      procedure Notify(Ptr: Pointer; Action: TListNotification);override;
    public
      property Items[AIndex:integer]:TSurfaceEvent read GetItem write SetItem;default;
      procedure Add(Item:TSurfaceEvent);
      procedure Remove(Item:TSurfaceEvent);
  end;


  //A record for adding a new log entry into the log system
  TAdLogMessage = record
    Text:string;
    Sender:string;
    Typ:string;
  end;

  //The log system class
  TAdLog = class
    private
      Items:TStringList;
    public
      //This specifies an file the log is automaticly saved to. May be '' for no auto saving.
      FileName:string;
      //A constructor.
      constructor Create;
      //Wow. A destructor.
      destructor Destroy;override;
      //Load an old logfile
      procedure LoadFromFile(AFile:string);
      //Save the current logfile. Happens automaticly if FileName is set.
      procedure SaveToFile(AFile:string);
      //Adds an TAdLog Message Record to the log system.
      procedure AddMessage(AMessage:TAdLogMessage);
  end;

  {This is the main class for using Andorra 2D. It is comparable to DelphiX's TDXDraw.}
  TAdDraw = class
  private

    FParent:TWinControl;
    FOptions:TAdOptions;
    FDllName:string;
    FFinalize:TNotifyEvent;
    FInitialize:TNotifyEvent;
    FInitialized:boolean;
    FDisplayRect:TRect;

    FAmbientColor:TColor;

    FLog:TAdLog;
    FLogFileName:string;
    FAutoLoadLog:boolean;

    FSurfaceEventList:TSurfaceEventList;
    //FCanvas:TSurfaceCanvas;

    procedure SetDllName(val : string);

    procedure SetupThings;

    procedure SetOptions(AValue:TAdOptions);
    procedure SetAmbientColor(AValue:TColor);

    procedure SetAutoLoadLog(AValue:boolean);

    function GetDisplayRect:TRect;

  protected
    procedure CallNotifyEvent(AEventState:TSurfaceEventState);
  public
    {The Andorra Dll Loader. You can use this class to get direct control over
    the engine.}
    AdDllLoader : TAndorraDllLoader;
    {The Andorra Reference for the DllLoader}
    AdAppl:TAd2DApplication;
    //This property contains the diplay settings (width, height and bitcount)
    Display : TAdDisplay;

    //Create the class. AParent is the handle of the control, where displaying should take place.
    constructor Create(AParent : TWinControl);
    //This is a destroctor.
    destructor Destroy; override;

    //Here you can read the parent value, you've set in the constructor.
    property Parent : TWinControl read FParent;

    //The Rect the Displaing takes place
    property DisplayRect:TRect read FDisplayRect;

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

    //Recives log events
    procedure LogProc(LogItem:TAdLogItem);

    //Register an event that will be called if the surface is finalized or initialized.
    procedure RegisterNotifyEvent(AProc:TSurfaceEvent);
    //UnRegister a registered event.
    procedure UnRegisterNotifyEvent(AProc:TSurfaceEvent);

    //This property contains the options (see TAdDrawMode)
    property Options : TAdOptions read FOptions write SetOptions;
    //Set this value to load a library
    property DllName : string read FDllName write SetDllName;
    //Returns weather the application is initialized
    property Initialized : boolean read FInitialized;
    //Set the ambient light color here
    property AmbientColor:TColor read FAmbientColor write SetAmbientColor;

    //Event is called before the application is finalized
    property OnFinalize : TNotifyEvent read FFinalize write FFinalize;
    //Event is called after the application is initialized
    property OnInitialize : TNotifyEvent read FInitialize write FInitialize;

    //The log system
    property Log : TAdLog read FLog;
    //Specifies weather the log should automaticly be loaded at startup and saved at shutdown.
    property AutoLoadLog: boolean read FAutoLoadLog write SetAutoLoadLog;
    //The name of the logfile.
    property LogFileName:string read FLogFileName write FLogFileName;
  end;

  {TAdLight is the representation of a light in your game. Before using lights
  be sure that you've turned on "doLights" in the options. You can only use 8 Lights in a scene by one time.}
  {TAdLight = class
    private
      FParent:TAdDraw;
    protected
    public
      //Link to Andorras Light
      AdLight:TAndorraLight;
      //Contains information about the light.
      Data:TLight;
      //A constructor
      constructor Create(AParent:TAdDraw);
      //A destructor
      destructor Destroy;override;
      //Push the settings you've made in "data" into the engine.
      procedure Restore;
      {Enables the light. Note that most graphic boards can only display 8 Lights a time.

      All lights are automaticly disabled in the "EndScene" routine.}
      {procedure Enable;
      //Disable a light manually.
      procedure Disable;
  end;      }

  TInitialLetters = string[4];

  {The abstract picture compressor class}
  TCompressor = class(TPersistent)
    public
      //Returns the initial letters of this compressor. Will be calles without creating the object!!!
      function GetInitial:TInitialLetters;virtual;abstract;
      //Writes the bitmap into a stream
      procedure Write(AStream:TStream;ABmp:TAdBitmap);virtual;abstract;
      //Reads the bitmap from the stream
      procedure Read(AStream:TStream;ABmp:TAdBitmap);virtual;abstract;
  end;

  //An error raised if there is an error due loading the picture
  ELoad = class(Exception);
  //An error raised if the compressor used isn't found.
  ENoCompressor = class(ELoad);

  {The standard compressor. The data will be compressed with the "Huffman"
  Algorithm. Uses an Huffman-Algorithm written by Marc Schmitz. Available on http://www.delphipraxis.net/topic51522_huffman+algorithmus.html&highlight=huffman}
  THAICompressor = class(TCompressor)
    public
      //Returns the initial letters of this compressor. Will be calles without creating the object!!!
      function GetInitial:TInitialLetters;override;
      //Writes the bitmap into a stream
      procedure Write(AStream:TStream;ABmp:TAdBitmap);override;
      //Reads the bitmap from the stream
      procedure Read(AStream:TStream;ABmp:TAdBitmap);override;
  end;

  {A class of the compressor for easy registering}
  TCompressorClass = class of TCompressor;

  EFormatNotSupportet = class(Exception);

  TAdPictFormat = class(TPersistent)
    public
      procedure FileExts(strs:TStringList);virtual;abstract;
      function LoadFromFile(AFile:string;ABmp:TAdBitmap;Transparent:boolean;TransparentColor:TColor):boolean;virtual;abstract;
      procedure AssignGraphic(AGraphic:TGraphic;ABmp:TAdBitmap);virtual;abstract;
      function SupportsGraphicClass(AGraphicClass:TGraphicClass):boolean;virtual;abstract;
  end;

  TAdSimpleFormat = class(TAdPictFormat)
    public
      procedure FileExts(strs:TStringList);override;
      function LoadFromFile(AFile:string;ABmp:TAdBitmap;Transparent:boolean;TransparentColor:TColor):boolean;override;
      procedure AssignGraphic(AGraphic:TGraphic;ABmp:TAdBitmap);override;
      function SupportsGraphicClass(AGraphicClass:TGraphicClass):boolean;override;
  end;

  TAdPictFormatClass = class of TAdPictFormat;

  TAdTexture = class
    private
      FParent:TAdDraw;
      FCache:TMemoryStream;
      FAd2DTexture:TAd2DBitmapTexture;
      FCompressor:TCompressor;
      FCompressorClass:TCompressorClass;
      function GetInitialized:boolean;
      procedure SetCompressor(AClass:TCompressorClass);
    protected
      procedure Notify(ASender:TObject;AEvent:TSurfaceEventState);
    public
      constructor Create(AParent:TAdDraw);
      destructor Destroy;override;

      procedure LoadFromStream(AStream:TStream);
      procedure SaveToStream(AStream:TStream);

      procedure SaveToFile(AFile:string);
      procedure LoadFromFile(AFile:string);

      procedure LoadGraphicFromFile(AFile:string;Transparent:boolean;TransparentColor:TColor);
      procedure LoadFromGraphic(AGraphic:TGraphic);

      procedure Initialize;
      procedure Finalize;
      procedure Clear;
      property Texture:TAd2DBitmapTexture read FAd2DTexture;
      property Initialized:boolean read GetInitialized;
      //Set a compressor class. Default: TBMPCompressor;
      property Compressor:TCompressorClass read FCompressorClass write SetCompressor;
  end;

  {A list which is able to contain TRects}
  TRectList = class(TList)
    private
     	function GetItem(AIndex:integer):TRect;
     	procedure SetItem(AIndex:integer;AItem:TRect);
    protected
      procedure Notify(Ptr: Pointer; Action: TListNotification);override;
    public
      {Read/Write acess to the rectangles.}
     	property Items[AIndex:integer]:TRect read GetItem write SetItem;default;
      {Add a rectangle.}
      procedure Add(ARect:TRect);
    published
  end;

  //This represents one image in an ImageList.
  TPictureCollectionItem = class
    private
      FParent:TAdDraw;
      FWidth,FHeight:integer;
      FPatternWidth,FPatternHeight:integer;
      FSkipWidth,FSkipHeight:integer;
      FTexture:TAdTexture;
      FColor:TColor;
      FLastColor:TAndorraColor;
      FAlpha:byte;
      FName:string;
      FDetails:integer;
      FOwnTexture:boolean;
      FSrcRect:TRect;
      FUseIndexBuffer:boolean;
      procedure SetPatternWidth(AValue:integer);
      procedure SetPatternHeight(AValue:integer);
      procedure SetSkipWidth(AValue:integer);
      procedure SetSkipHeight(AValue:integer);
      function GetPatternCount:integer;
      function GetWidth:integer;
      function GetHeight:integer;
      function GetColor:TAndorraColor;
      procedure SetCurrentColor(Alpha:byte);
      procedure SetDetails(AValue:integer);
      procedure SetTexture(AValue:TAdTexture);
    protected
      Rects:TRectList;
      procedure DrawMesh(DestApp:TAdDraw;DestRect,SourceRect:TRect;Rotation:integer;
        RotCenterX,RotCenterY:single;BlendMode:TAd2DBlendMode);
      procedure BuildVertices;
      procedure CreatePatternRects;
      procedure Notify(ASender:TObject;AEvent:TSurfaceEventState);
    public
      //True if this item can be freed by the image list
      FreeByList:boolean;
      //Contains the link to Andorras Image
      AdMesh:TAd2DMesh;
      //A Constructor
      constructor Create(AAdDraw:TAdDraw);
      //A Destructor
      destructor Destroy;override;
      //Draws the image at a specified position. If you've set "PatternWidth" and "PatternHeight", this will draw the pattern you've specified in PatternIndex.
      procedure Draw(Dest:TAdDraw;X,Y,PatternIndex:integer);
      //The same as Draw, but you can stretch the Image.
      procedure StretchDraw(Dest:TAdDraw;const DestRect:TRect;PatternIndex:integer);
      //Draw a sprite with additive blending.
      procedure DrawAdd(Dest: TAdDraw; const DestRect: TRect; PatternIndex: Integer;
        Alpha: Integer);
      //Draw a sprite with alpha blending.
      procedure DrawAlpha(Dest: TAdDraw; const DestRect: TRect; PatternIndex: Integer;
        Alpha: Integer);
      //Draw only the mask.
      procedure DrawMask(Dest: TAdDraw; const DestRect: TRect; PatternIndex: Integer;
        Alpha: Integer);
      //Draw a sprite rotated. CenterX and CenterY specify the center of the rotation - May be a value between 0 and 1. Rotation is a value between 0 and 360.
      procedure DrawRotate(Dest: TAdDraw; X, Y, Width, Height: Integer; PatternIndex: Integer;
        CenterX, CenterY: Double; Angle: Integer);
      //The same as DrawRotate, just with additive blending.
      procedure DrawRotateAdd(Dest: TAdDraw; X, Y, Width, Height: Integer; PatternIndex: Integer;
        CenterX, CenterY: Double; Angle: Integer;
        Alpha: Integer);
      //The same as DrawRotate, just with alpha blending.
      procedure DrawRotateAlpha(Dest: TAdDraw; X, Y, Width, Height: Integer; PatternIndex: Integer;
        CenterX, CenterY: Double; Angle: Integer;
        Alpha: Integer);
      //The same as DrawRotate, just drawing a the mask.        
      procedure DrawRotateMask(Dest: TAdDraw; X, Y, Width, Height: Integer; PatternIndex: Integer;
        CenterX, CenterY: Double; Angle: Integer;
        Alpha: Integer);
      //Draw only specified part from the image. Alpha blending.
      procedure StretchBltAlpha(Dest:TAdDraw; SourceRect,DestRect:TRect;CenterX,CenterY:integer;Angle:Integer;Alpha:Integer);
      //Draw only specified part from the image. Additive blending.
      procedure StretchBltAdd(Dest:TAdDraw; SourceRect,DestRect:TRect;CenterX,CenterY:integer;Angle:Integer;Alpha:Integer);
      //If you've set the color or a new texture you have to call this function to see your changes.
      procedure Restore;
      //Frees all data
      procedure Finalize;
      //Restores all freed date
      procedure Initialize;
      //Returns the rect of one pattern.
      function GetPatternRect(ANr:integer):TRect;
      //Saves the image to a stream
      procedure SaveToStream(AStream:TStream);
      //Loads the image from a stream
      procedure LoadFromStream(AStream:TStream);
      //Saves the image to a file
      procedure SaveToFile(AFile:string);
      //Loads the image from a file
      procedure LoadFromFile(AFile:string);
      //Returns the parent you've set in the constructor
      property Parent:TAdDraw read FParent write FParent;
      //Returns the width of the image.
      property Width:integer read GetWidth;
      //Returns the height of the image.
      property Height:integer read GetHeight;
      //Set the width of one pattern.
      property PatternWidth:integer read FPatternWidth write SetPatternWidth;
      //Set the height of one pattern.
      property PatternHeight:integer read FPatternHeight write SetPatternHeight;
      //The horizontal space between the patterns.
      property SkipWidth:integer read FSkipWidth write SetSkipWidth;
      //The vertical space between the patterns.
      property SkipHeight:integer read FSkipHeight write SetSkipHeight;
      //The texture which will be painted.
      property Texture:TAdTexture read FTexture write SetTexture;
      //Returns the count of the patterns.
      property PatternCount:integer read GetPatternCount;
      //Here you can dye an image.
      property Color:TColor read FColor write FColor;
      //Name of the image in the imagelist.
      property Name:string read FName write FName;
      //Important for using lights: How many vertices does the image have.
      property Details:integer read FDetails write SetDetails;
  end;

  //Administrates the images
  TPictureCollection = class(TList)
    private
      FParent:TAdDraw;
      FCompressor:TCompressorClass;
     	function GetItem(AIndex:integer):TPictureCollectionItem;
     	procedure SetItem(AIndex:integer;AItem:TPictureCollectionItem);
      procedure SetCompressor(ACompressor:TCompressorClass);
    protected
      procedure Notify(Ptr: Pointer; Action: TListNotification); override;
    public
      //Returns you an item
     	property Items[AIndex:integer]:TPictureCollectionItem read GetItem write SetItem;default;
      //Add a new image to the list.
      function Add(AName:string):TPictureCollectionItem;overload;
      //Find an image in the list.
      function Find(AName:string):TPictureCollectionItem;
      //Call the restore function of every item in the list.
      procedure Restore;
      //A constructor
      constructor Create(AAdDraw:TAdDraw);
      //A destructor
      destructor Destroy;override;
      //Save the whole list to a stream
      procedure SaveToStream(AStream:TStream);
      //Load a whole list from a stream
      procedure LoadFromStream(AStream:TStream);
      //Saves the whole list to a file
      procedure SaveToFile(AFile:string);
      //Loads a whole list from a file
      procedure LoadFromFile(AFile:string);
      //The parent you've specified in the constructor.
      property Parent:TAdDraw read FParent;
      //Set this to the same compressor to every item
      property Compressor:TCompressorClass read FCompressor write SetCompressor; 
    published
  end;

  //Class for calculating the FPS
  TPerformanceCounter = class
    private
      lt,th,ffps:integer;
    public
      //Time between the frames in ms
      TimeGap:integer;
      //The current FPS
      FPS:integer;
      //Calculates the new values
      procedure Calculate;
      //Creates a new instance of the performance counter
      constructor Create;
  end;

const
  CanvasPatternSize = 512;

var
  //Contains all registered compressors. You must not change the contents.
  RegisteredCompressors:TStringList;
  RegisteredFormats:TStringList;

//Is called for registering a compressor class. If you register a compressor it will be automaticly used for decompressing.
procedure RegisterCompressor(AClass:TClass);

//Is called for registering a format class. The format classes are used to give the ability to load files of serveral formats.
procedure RegisterFormat(AClass:TClass);


implementation

procedure RegisterCompressor(AClass:TClass);
begin
  RegisterClass(TPersistentClass(AClass));
  RegisteredCompressors.Add(AClass.ClassName);
end;

procedure RegisterFormat(AClass:TClass);
begin
  RegisterClass(TPersistentClass(AClass));
  RegisteredFormats.Add(AClass.ClassName);
end;

{ TAdDraw }

constructor TAdDraw.Create(AParent : TWinControl);
var amsg:TAdLogMessage;
begin
	inherited Create;
  FParent := AParent;
  FAmbientColor := clWhite;
  AdDllLoader := TAndorraDllLoader.Create;
  SetupThings;

  FLog := TAdLog.Create;
  FLogFileName := 'adlog.txt';

  FSurfaceEventList := TSurfaceEventList.Create;

  AutoLoadLog := true;

  amsg.Text := 'AdDraw was created: '+TimeToStr(Time);
  amsg.Sender := self.ClassName;
  amsg.Typ := 'Info';
  FLog.AddMessage(amsg);
end;

procedure TAdDraw.SetupThings;
begin
  //Initialize all Parameters
  with Display do
  begin
    Width := 800;
    Height := 600;
    BitCount := 32;
    Freq := 0;
  end;

  FOptions := [doHardware];
end;

destructor TAdDraw.Destroy;
begin
  //Free all loaded objects
  if AdAppl <> nil then
  begin
    Finalize;
  end;
  
  AdDllLoader.Destroy;

  if FAutoLoadLog then
  begin
    Log.SaveToFile(FLogFileName);
  end;
  FLog.Free;

  FSurfaceEventList.Free;

	inherited Destroy;
end;

procedure TAdDraw.UnRegisterNotifyEvent(AProc: TSurfaceEvent);
begin
  FSurfaceEventList.Remove(AProc)
end;

procedure TAdDraw.RegisterNotifyEvent(AProc: TSurfaceEvent);
begin
  FSurfaceEventList.Add(AProc);
end;


procedure TAdDraw.SetAmbientColor(AValue: TColor);
begin
  {if Initialized then
  begin
    FAmbientColor := AValue;
    AdDllLoader.SetAmbientLight(AdAppl,AD_RGB(GetRValue(AValue),GetGValue(AValue),
      GetBValue(AValue)));
  end;}
end;

procedure TAdDraw.SetAutoLoadLog(AValue: boolean);
begin
  FAutoLoadLog := AValue;
  if FAutoLoadLog then
  begin
    if FileExists(FLogFileName) then
    begin
      FLog.LoadFromFile(FLogFileName);
      FLog.FileName := FLogFileName;
    end;
  end
  else
  begin
    FLog.FileName := '';
  end;
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

procedure TAdDraw.SetOptions(AValue:TAdOptions);
begin
  FOptions := AValue;
  if Initialized then
  begin
    //AdDllLoader.SetOptions(AdAppl,Options);
  end;
end;

function TAdDraw.Initialize: boolean;
var amsg:TAdLogMessage;
begin

  result := false;

  if not Initialized then
  begin
    //Create the new Application
    AdAppl := AdDllLoader.CreateApplication;
    if (AdAppl <> nil) and (FParent <> nil) and (AdDllLoader.LibraryLoaded) then
    begin
      //Give the Plugin the possibility to send logs
      AdAppl.SetLogProc(LogProc);

      FDisplayRect := GetDisplayRect;
      Display.Width := FDisplayRect.Right;
      Display.Height := FDisplayRect.Bottom;

      result := AdAppl.Initialize(FParent.Handle,Options,Display);

      //AdDllLoader.SetTextureQuality(AdAppl,tqNone);
      Setup2DScene;
    end
    else
    begin
      amsg.Text := 'Unable to initialize Andorra 2D. Check weather you have installed the newest driver.';
      amsg.Sender := 'TAdDraw';
      amsg.Typ := 'Fatal Error';
      Log.AddMessage(amsg);
    end;

    if Assigned(FInitialize) then
    begin
      //OnInitialize
      FInitialize(Self);
    end;

    FInitialized := result;

    if CanDraw then
    begin
      CallNotifyEvent(seInitialize);
      CallNotifyEvent(seInitialized);
    end;
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
    FInitialized := false;
    CallNotifyEvent(seFinalize);
    AdAppl.Finalize;
    if AdAppl <> nil then FreeAndNil(AdAppl);
  end;
end;

procedure TAdDraw.LogProc(LogItem: TAdLogItem);
var Temp:TAdLogMessage;
begin
  Temp.Sender := self.ClassName;
  case LogItem.Typ of
    ltInfo: Temp.Typ := 'Info';
    ltWarning: Temp.Typ := 'Warning';
    ltError: Temp.Typ := 'Error';
    ltFatalError: Temp.Typ := 'Fatal Error';
    ltNone: Temp.Typ := 'Info';
  end;
  Temp.Text := PChar(LogItem.Text);
  Log.AddMessage(Temp);
end;

procedure TAdDraw.ClearSurface(Color:TColor);
begin
  AdAppl.ClearSurface(Ad_RGB(GetRValue(Color),GetGValue(Color),GetBValue(Color)));
end;

procedure TAdDraw.BeginScene;
begin
  if AdAppl <> nil then
  begin
    AdAppl.BeginScene;
  end;
end;

procedure TAdDraw.EndScene;
begin
  if AdAppl <> nil then
  begin
    AdAppl.EndScene;
  end;
end;

procedure TAdDraw.Setup2DScene;
begin
  if AdAppl <> nil then
  begin
    FDisplayRect := GetDisplayRect;
    AdAppl.Setup2DScene(FDisplayRect.Right,FDisplayRect.Bottom);
  end;
end;

procedure TAdDraw.Flip;
begin
  if AdAppl <> nil then
  begin
    AdAppl.Flip;
  end;
end;

function TAdDraw.GetDisplayRect: TRect;
begin
  if dofullscreen in Options then
  begin
    result := Bounds(0,0,Display.Width,Display.Height);
  end
  else
  begin
    result := Bounds(0,0,FParent.ClientWidth,FParent.ClientHeight);
  end;
end;

procedure TAdDraw.CallNotifyEvent(AEventState: TSurfaceEventState);
var i:integer;
begin
  i := 0;
  while i < FSurfaceEventList.Count do
  begin
    FSurfaceEventList.Items[i](self,AEventState);
    i := i + 1;
  end;
end;

function TAdDraw.CanDraw:boolean;
begin
  result := (AdAppl <> nil) and (Initialized);
end;

{TRectList}

procedure TRectList.Add(ARect: TRect);
var ar:PRect;
begin
  new(ar);
  ar^ := ARect;
  inherited Add(ar);
end;

function TRectList.GetItem(AIndex:integer):TRect;
begin
  result := PRect(inherited Items[AIndex])^;
end;

procedure TRectList.Notify(Ptr: Pointer; Action: TListNotification);
begin
  if Action = lnDeleted then
  begin
    Dispose(Ptr);
  end;
  inherited;
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
  FParent.RegisterNotifyEvent(Notify);
  Rects := TRectList.Create;
  FColor := clWhite;
  FAlpha := 255;
  FOwnTexture := true;
  FDetails := 1;
  Initialize;
end;

destructor TPictureCollectionItem.Destroy;
begin
  if FOwnTexture then
  begin
    FTexture.Free;
  end;
  Rects.Free;
  FParent.UnRegisterNotifyEvent(Notify);
  Finalize;
  inherited Destroy;
end;

procedure TPictureCollectionItem.DrawMesh(DestApp: TAdDraw; DestRect,
  SourceRect: TRect; Rotation: integer; RotCenterX, RotCenterY: single;
  BlendMode: TAd2DBlendMode);
var
  mat1,mat2:TAdMatrix;
  curx,cury:single;  
begin
  if not CompRects(SourceRect,FSrcRect) then
  begin
    FSrcRect := SourceRect;
    BuildVertices;
  end;

  //Initialize "The Matrix"
  mat1 := AdMatrix_Identity;
  mat2 := AdMatrix_Identity;

  //Set the scale matrix
  mat1 := AdMatrix_Scale((DestRect.Right-DestRect.Left)/FWidth,(DestRect.Bottom-DestRect.Top)/FHeight,0);
  mat2 := AdMatrix_Multiply(mat1,mat2);

  if (Rotation <> 0) then
  begin
    CurX := (DestRect.Right-DestRect.Left)*RotCenterX;
    CurY := (DestRect.Bottom-DestRect.Top)*RotCenterY;

    mat1 := AdMatrix_Translate(-CurX,-CurY,0);
    mat2 := AdMatrix_Multiply(mat2,mat1);

    mat1 := AdMatrix_RotationZ(Rotation/360*2*PI);
    mat2 := AdMatrix_Multiply(mat2,mat1);

    mat1 := AdMatrix_Translate(CurX,CurY,0);
    mat2 := AdMatrix_Multiply(mat2,mat1);
  end;

  //Translate the Box
  mat1 := AdMatrix_Translate(DestRect.Left,DestRect.Top,0);
  mat2 := AdMatrix_Multiply(mat2,mat1);

  AdMesh.SetMatrix(mat2); 
  
  AdMesh.Draw(BlendMode);
end;

procedure TPictureCollectionItem.BuildVertices;
var
  Vertices:TAdVertexArray;
  Indices:TAdIndexArray;
  i,x,y:integer;
  ax,ay:double;
  w,h:integer;
  vc,ic:integer;
  c:TAndorraColor;
begin
  if AdMesh <> nil then
  begin
    vc := (FDetails+1)*(FDetails+1);
    ic := FDetails*FDetails*6;

    SetLength(Vertices,vc);
    SetLength(Indices,ic);

    FUseIndexBuffer := FDetails > 1;

    w := FSrcRect.Right - FSrcRect.Left;
    h := FSrcRect.Bottom - FSrcRect.Top;

    c := GetColor;

    i := 0;
    for y := 0 to FDetails do
    begin
      for x := 0 to FDetails do
      begin
        ay := y*fheight/FDetails;
        ax := x*fwidth/FDetails;
        Vertices[i].Position := AdVector3(ax,ay,0);
        Vertices[i].Color := c;
        Vertices[i].Texture := AdVector2((FSrcRect.Left + w/FDetails*x)/FWidth,(FSrcRect.Top + h/FDetails*y)/FHeight);
        Vertices[i].Normal := AdVector3(0,0,-1);
        i := i + 1;
      end;
    end;
    AdMesh.Vertices := Vertices;

    if FUseIndexBuffer then
    begin
      i := 0;
      for y := 0 to FDetails - 1 do
      begin
        for x := 0 to FDetails - 1 do
        begin
          Indices[i] :=   y     * (FDetails+1) + x + 1;
          Indices[i+1] := (y+1) * (FDetails+1) + x;
          Indices[i+2] := y     * (FDetails+1) + x;
          Indices[i+3] := y     * (FDetails+1) + x + 1;
          Indices[i+4] := (y+1) * (FDetails+1) + x + 1;
          Indices[i+5] := (y+1) * (FDetails+1) + x;
          i := i + 6;
        end;
      end;
      AdMesh.IndexBuffer := Indices;
    end
    else
    begin
      AdMesh.IndexBuffer := nil;
    end;

    AdMesh.PrimitiveCount := FDetails*FDetails*2;
    AdMesh.Update;
  end;
end;

procedure TPictureCollectionItem.CreatePatternRects;
var ax,ay:integer;
begin
  Rects.Clear;
  with FTexture.Texture do
  begin
    if (FPatternWidth <> 0) and (FPatternHeight <> 0) then
    begin
      for ay := 0 to ((BaseHeight+FSkipHeight) div (PatternHeight+FSkipHeight)) - 1 do
      begin
        for ax := 0 to ((BaseWidth+FSkipWidth) div (PatternWidth+FSkipWidth)) - 1 do
        begin
          Rects.Add(Bounds(
            ax*(PatternWidth+FSkipWidth),ay*(PatternHeight+FSkipHeight),
            Width,Height));
        end;
      end;
    end
    else
    begin
      Rects.Add(Rect(0,0,BaseWidth,BaseHeight));
    end;
  end;
end;

procedure TPictureCollectionItem.Draw(Dest:TAdDraw;X,Y,PatternIndex:integer);
begin
  if (Texture.Texture.Loaded) and (Dest.CanDraw) and (AdMesh <> nil) then
  begin
    SetCurrentColor(255);
    if (PatternIndex < 0) then PatternIndex := 0;
    if (PatternIndex > PatternCount-1) then PatternIndex := PatternCount-1;
    DrawMesh(Dest,Rect(X,Y,X+Width,Y+Height),Rects[PatternIndex],
      0,0,0,bmAlpha);
  end;
end;

procedure TPictureCollectionItem.DrawAdd(Dest: TAdDraw; const DestRect: TRect;
  PatternIndex, Alpha: Integer);
begin
  if (Texture.Texture.Loaded) and (Dest.CanDraw) and (AdMesh <> nil) then
  begin
    SetCurrentColor(Alpha);
    if (PatternIndex < 0) then PatternIndex := 0;
    if (PatternIndex > PatternCount-1) then PatternIndex := PatternCount-1;
    DrawMesh(Dest,DestRect,Rects[PatternIndex],0,0,0,bmAdd);
  end;
end;

procedure TPictureCollectionItem.DrawAlpha(Dest: TAdDraw; const DestRect: TRect;
  PatternIndex, Alpha: Integer);
begin
  if (Texture.Texture.Loaded) and (Dest.CanDraw) and (AdMesh <> nil) then
  begin
    SetCurrentColor(Alpha);
    if (PatternIndex < 0) then PatternIndex := 0;
    if (PatternIndex > PatternCount-1) then PatternIndex := PatternCount-1;
    DrawMesh(Dest,DestRect,Rects[PatternIndex],0,0,0,bmAlpha);
  end;
end;

procedure TPictureCollectionItem.DrawMask(Dest: TAdDraw; const DestRect: TRect;
  PatternIndex, Alpha: Integer);
begin
  if (Texture.Texture.Loaded) and (Dest.CanDraw) and (AdMesh <> nil) then
  begin
    SetCurrentColor(Alpha);
    if (PatternIndex < 0) then PatternIndex := 0;
    if (PatternIndex > PatternCount-1) then PatternIndex := PatternCount-1;
    DrawMesh(Dest,DestRect,Rects[PatternIndex],0,0,0,bmMask);
  end;
end;

procedure TPictureCollectionItem.DrawRotate(Dest: TAdDraw; X, Y, Width, Height,
  PatternIndex: Integer; CenterX, CenterY: Double; Angle: Integer);
begin
  if (Texture.Texture.Loaded) and (Dest.CanDraw) and (AdMesh <> nil) then
  begin
    SetCurrentColor(255);
    if (PatternIndex < 0) then PatternIndex := 0;
    if (PatternIndex > PatternCount-1) then PatternIndex := PatternCount-1;
    DrawMesh(Dest,Rect(X,Y,X+Width,Y+Height),Rects[PatternIndex],Angle,CenterX,CenterY,bmAlpha);
  end;
end;

procedure TPictureCollectionItem.DrawRotateAdd(Dest: TAdDraw; X, Y, Width,
  Height, PatternIndex: Integer; CenterX, CenterY: Double; Angle,
  Alpha: Integer);
begin
  if (Texture.Texture.Loaded) and (Dest.CanDraw) and (AdMesh <> nil) then
  begin
    SetCurrentColor(Alpha);
    if (PatternIndex < 0) then PatternIndex := 0;
    if (PatternIndex > PatternCount-1) then PatternIndex := PatternCount-1;
    DrawMesh(Dest,Rect(X,Y,X+Width,Y+Height),Rects[PatternIndex],Angle,CenterX,CenterY,bmAdd);
  end;
end;

procedure TPictureCollectionItem.DrawRotateAlpha(Dest: TAdDraw; X, Y, Width,
  Height, PatternIndex: Integer; CenterX, CenterY: Double; Angle,
  Alpha: Integer);
begin
  if (Texture.Texture.Loaded) and (Dest.CanDraw) and (AdMesh <> nil) then
  begin
    SetCurrentColor(Alpha);
    if (PatternIndex < 0) then PatternIndex := 0;
    if (PatternIndex > PatternCount-1) then PatternIndex := PatternCount-1;
    DrawMesh(Dest,Rect(X,Y,X+Width,Y+Height),Rects[PatternIndex],Angle,CenterX,CenterY,bmAlpha);
  end;
end;

procedure TPictureCollectionItem.DrawRotateMask(Dest: TAdDraw; X, Y, Width,
  Height, PatternIndex: Integer; CenterX, CenterY: Double; Angle,
  Alpha: Integer);
begin
  if (Texture.Texture.Loaded) and (Dest.CanDraw) and (AdMesh <> nil) then
  begin
    SetCurrentColor(Alpha);
    if (PatternIndex < 0) then PatternIndex := 0;
    if (PatternIndex > PatternCount-1) then PatternIndex := PatternCount-1;
    DrawMesh(Dest,Rect(X,Y,X+Width,Y+Height),Rects[PatternIndex],Angle,CenterX,CenterY,bmMask);
  end;
end;

procedure TPictureCollectionItem.StretchBltAdd(Dest: TAdDraw; SourceRect,
  DestRect: TRect; CenterX, CenterY, Angle, Alpha: Integer);
begin
  if (Texture.Texture.Loaded) and (Dest.CanDraw) and (AdMesh <> nil) then
  begin
    SetCurrentColor(Alpha);
    DrawMesh(Dest,DestRect,SourceRect,Angle,CenterX,CenterY,bmAdd);
  end;
end;

procedure TPictureCollectionItem.StretchBltAlpha(Dest: TAdDraw; SourceRect,
  DestRect: TRect; CenterX, CenterY, Angle, Alpha: Integer);
begin
  if (Texture.Texture.Loaded) and (Dest.CanDraw) and (AdMesh <> nil) then
  begin
    SetCurrentColor(Alpha);
    DrawMesh(Dest,DestRect,SourceRect,Angle,CenterX,CenterY,bmAlpha);
  end;
end;

procedure TPictureCollectionItem.StretchDraw(Dest: TAdDraw; const DestRect: TRect; PatternIndex: integer);
begin
  if (Texture.Texture.Loaded) and (Dest.CanDraw) and (AdMesh <> nil) then
  begin
    SetCurrentColor(255);
    if (PatternIndex < 0) then PatternIndex := 0;
    if (PatternIndex > PatternCount-1) then PatternIndex := PatternCount-1;
    DrawMesh(Dest,DestRect,Rects[PatternIndex],0,0,0,bmAlpha);
  end;
end;

procedure TPictureCollectionItem.Restore;
begin
  FWidth := Texture.Texture.BaseWidth;
  FHeight := Texture.Texture.BaseHeight;
  AdMesh.Texture := Texture.Texture;
  CreatePatternRects;

  FSrcRect := Rect(0,0,FWidth,FHeight);
  FLastColor := GetColor;
  BuildVertices;
end;

procedure TPictureCollectionItem.SetPatternWidth(AValue: Integer);
begin
  FPatternWidth := AValue;
  CreatePatternRects;
end;

procedure TPictureCollectionItem.SetSkipHeight(AValue: integer);
begin
  FSkipHeight := AValue;
  CreatePatternRects;
end;

procedure TPictureCollectionItem.SetSkipWidth(AValue: integer);
begin
  FSkipWidth := AValue;
  CreatePatternRects;
end;

procedure TPictureCollectionItem.SetTexture(AValue: TAdTexture);
begin
  if FOwnTexture then
  begin
    FTexture.Free;
  end;
  FOwnTexture := false;
  FTexture := AValue;
end;

procedure TPictureCollectionItem.SetCurrentColor(Alpha: byte);
var CurCol:TAndorraColor;
begin
  if Texture.Texture.Loaded then
  begin
    FAlpha := Alpha;
    CurCol := GetColor;
    if not CompareColors(CurCol,FLastColor) then
    begin
      FLastColor := CurCol;
      BuildVertices;
    end;    
  end;
end;

procedure TPictureCollectionItem.SetDetails(AValue: integer);
begin
  if (AValue > 0) and (AValue <> FDetails) then
  begin
    FDetails := AValue;
    BuildVertices;
  end;
end;

procedure TPictureCollectionItem.SetPatternHeight(AValue: Integer);
begin
  FPatternHeight := AValue;
  CreatePatternRects;
end;

function TPictureCollectionItem.GetColor: TAndorraColor;
begin
  result := Ad_ARGB(FAlpha,GetRValue(FColor),GetGValue(FColor),GetBValue(FColor));
end;

function TPictureCollectionItem.GetHeight: integer;
begin
  Result := FPatternHeight;
  if (Result<=0) then
    Result := FHeight;
end;

function TPictureCollectionItem.GetWidth: integer;
begin
  Result := FPatternWidth;
  if (Result<=0) then
    Result := FWidth;
end;

procedure TPictureCollectionItem.Initialize;
begin
  if AdMesh <> nil then
  begin
    Finalize;
  end;
  AdMesh := FParent.AdAppl.CreateMesh;
end;

procedure TPictureCollectionItem.LoadFromFile(AFile: string);
var ms:TMemoryStream;
begin
  ms := TMemoryStream.Create;
  ms.LoadFromFile(AFile);
  ms.Position := 0;
  LoadFromStream(ms);
  ms.Free;
end;

procedure TPictureCollectionItem.SaveToFile(AFile: string);
var ms:TMemoryStream;
begin
  ms := TMemoryStream.Create;
  SaveToStream(ms);
  ms.SaveToFile(AFile);
  ms.Free;
end;

procedure TPictureCollectionItem.LoadFromStream(AStream: TStream);
var s:string;
    c:char;
    l:integer;
begin
  s := '';
  AStream.Read(c,1); s := s + c;
  AStream.Read(c,1); s := s + c;
  if s = 'PI' then
  begin
    Texture.LoadFromStream(AStream);
    AStream.Read(l,SizeOf(l));
    SetLength(FName,l);
    AStream.Read(FName[1],l);
    AStream.Read(FDetails,SizeOf(FDetails));
    AStream.Read(FPatternWidth,SizeOf(FPatternWidth));
    AStream.Read(FPatternHeight,SizeOf(FPatternHeight));
    AStream.Read(FSkipWidth,SizeOf(FSkipWidth));
    AStream.Read(FSkipHeight,SizeOf(FSkipHeight));
    Restore;
  end
  else
  begin
    raise ELoad.Create('This is not a vaild picture collection item.');
  end;
end;

procedure TPictureCollectionItem.SaveToStream(AStream: TStream);
var c:char;
    l:integer;
begin
  c := 'P'; AStream.Write(c,1);
  c := 'I'; AStream.Write(c,1);
  Texture.SaveToStream(AStream);
  l := length(FName);
  AStream.Write(l,SizeOf(l));
  AStream.Write(FName[1],l);
  AStream.Write(FDetails,SizeOf(FDetails));
  AStream.Write(FPatternWidth,SizeOf(FPatternWidth));
  AStream.Write(FPatternHeight,SizeOf(FPatternHeight));
  AStream.Write(FSkipWidth,SizeOf(FSkipWidth));
  AStream.Write(FSkipHeight,SizeOf(FSkipHeight));
end;

procedure TPictureCollectionItem.Finalize;
begin
  if AdMesh <> nil then
  begin
    FreeAndNil(AdMesh);
  end;
end;

procedure TPictureCollectionItem.Notify(ASender: TObject;AEvent: TSurfaceEventState);
begin
  if AEvent = seFinalize then
  begin
    Finalize;
  end;
  if AEvent = seInitialize then
  begin
    Initialize;
  end;
  if AEvent = seInitialized then
  begin
    Restore;
  end;
end;

function TPictureCollectionItem.GetPatternCount: integer;
begin
  result := Rects.Count;
end;

function TPictureCollectionItem.GetPatternRect(ANr: Integer):TRect;
begin
  result := Rects[ANr];
end;


{TPictureCollection}

function TPictureCollection.Add(AName: string): TPictureCollectionItem;
begin
  result := TPictureCollectionItem.Create(FParent);
  result.Name := AName;
  result.FreeByList := true;
  inherited Add(result);
end;

constructor TPictureCollection.Create(AAdDraw: TAdDraw);
begin
  inherited Create;
  FParent := AAdDraw;
end;

destructor TPictureCollection.Destroy;
begin
  inherited Destroy;
end;

function TPictureCollection.Find(AName: string): TPictureCollectionItem;
var i:integer;
begin
  result := nil;
  for i := 0 to Count - 1 do
  begin
    if Items[i].Name = AName then
    begin
      result := Items[i];
      break;
    end;
  end;
end;

function TPictureCollection.GetItem(AIndex:integer):TPictureCollectionItem;
begin
 result := inherited Items[AIndex];
end;

procedure TPictureCollection.SaveToFile(AFile: string);
var ms:TMemoryStream;
begin
  ms := TMemoryStream.Create;
  SaveToStream(ms);
  ms.SaveToFile(AFile);
  ms.Free;
end;

procedure TPictureCollection.LoadFromFile(AFile: string);
var ms:TMemoryStream;
begin
  ms := TMemoryStream.Create;
  ms.LoadFromFile(AFile);
  ms.Position := 0;
  LoadFromStream(ms);
  ms.Free;
end;

procedure TPictureCollection.SaveToStream(AStream: TStream);
var i:integer;
    s:string;
    ms:TMemoryStream;
    size:int64;
begin
  s := 'TADPictCol';
  AStream.Write(s[1],10);
  i := Count;
  AStream.Write(i,SizeOf(i));
  for i := 0 to Count - 1 do
  begin
    ms := TMemoryStream.Create;
    Items[i].SaveToStream(ms);
    size := ms.Size;
    AStream.Write(size,SizeOf(size));
    ms.Position := 0;
    ms.SaveToStream(AStream);
    ms.Free;
  end;
end;

procedure TPictureCollection.LoadFromStream(AStream: TStream);
var i,c:integer;
    s:string;
    ms:TMemoryStream;
    size:int64;
    temp:TPictureCollectionItem;
begin
  SetLength(s,10);
  AStream.Read(s[1],10);
  if s = 'TADPictCol' then
  begin
    Clear;
    AStream.Read(c,SizeOf(c));
    for i := 0 to c - 1 do
    begin
      AStream.Read(size,SizeOf(Size));
      ms := TMemoryStream.Create;
      ms.CopyFrom(AStream,size);
      ms.Position := 0;
      temp := TPictureCollectionItem.Create(FParent);
      with temp do
      begin
        FreeByList := true;
        LoadFromStream(ms);
      end;
      Add(temp);
      ms.Free;
    end;
  end
  else
  begin
    raise ELoad.Create('This is not a vaild Andorra Picture Library!');
  end;
end;

procedure TPictureCollection.Notify(Ptr: Pointer; Action: TListNotification);
begin
  if Action = lnDeleted then
  begin
    with TPictureCollectionItem(Ptr) do
    begin
      if FreeByList then
      begin
        Free;
      end;
    end;
  end;
end;

procedure TPictureCollection.Restore;
var i:integer;
begin
  for i := 0 to Count - 1 do
  begin
    Items[i].Restore;
  end;
end;

procedure TPictureCollection.SetCompressor(ACompressor: TCompressorClass);
var i:integer;
begin
  FCompressor := ACompressor;
  for i := 0 to Count - 1 do
  begin
    Items[i].Texture.Compressor := FCompressor;
  end;
end;

procedure TPictureCollection.SetItem(AIndex:integer;AItem:TPictureCollectionItem);
begin
 inherited Items[AIndex] := AItem;
end;

{ TAdLight }

{constructor TAdLight.Create(AParent: TAdDraw);
begin
  inherited Create;
  FParent := AParent;
  AdLight := AParent.AdDllLoader.CreateLight(AParent.AdAppl);
end;

destructor TAdLight.Destroy;
begin
  FParent.AdDllLoader.DestroyLight(AdLight);
  inherited Destroy;
end;

procedure TAdLight.Disable;
begin
  FParent.AdDllLoader.DisableLight(AdLight);
end;

procedure TAdLight.Enable;
begin
  FParent.AdDllLoader.EnableLight(AdLight);
end;

procedure TAdLight.Restore;
begin
  FParent.AdDllLoader.RestoreLight(AdLight,Data);
end; }

{ TAdLog }

procedure TAdLog.AddMessage(AMessage: TAdLogMessage);
begin
  Items.Add('['+AMessage.Sender+']'+' ['+AMessage.Typ+'] '+AMessage.Text);
  if FileName <> '' then
  begin
    SaveToFile(FileName);
  end;
end;

constructor TAdLog.Create;
begin
  inherited Create;
  Items := TStringList.Create;
end;

destructor TAdLog.Destroy;
begin
  Items.Free;
  inherited Destroy;
end;

procedure TAdLog.LoadFromFile(AFile: string);
begin
  Items.LoadFromFile(AFile);
  Items.Add('');
end;

procedure TAdLog.SaveToFile(AFile: string);
begin
  Items.SaveToFile(AFile);
end;

{ TPerformanceCounter }

procedure TPerformanceCounter.Calculate;
var t:integer;
begin
  t := GetTickCount;
  timegap := t-lt;
  th := th + timegap;
  lt := t;
  fFPS := fFPS + 1;
  if th >= 1000 then
  begin
    th := 0;
    FPS := fFPS;
    fFPS := 0;
  end;
end;

constructor TPerformanceCounter.Create;
begin
  inherited Create;
  lt := GetTickCount;
  th := 0;
  timegap := 0;
  fps := 0;
end;

{ TSurfaceEventList }

procedure TSurfaceEventList.Add(Item: TSurfaceEvent);
var Event:PSurfaceEvent;
begin
  New(Event);
  Event^ := Item;
  inherited Add(Event);
end;

function TSurfaceEventList.GetItem(AIndex:integer):TSurfaceEvent;
begin
  result := PSurfaceEvent(inherited Items[AIndex])^;
end;

procedure TSurfaceEventList.Notify(Ptr: Pointer; Action: TListNotification);
begin
  if Action = lnDeleted then
  begin
    Dispose(Ptr);
  end;
  inherited;
end;

procedure TSurfaceEventList.Remove(Item: TSurfaceEvent);
var i:integer;
begin
  i := 0;
  while i < Count do
  begin
    if (TMethod(Items[i]).Code = TMethod(Item).Code) and
       (TMethod(Items[i]).Data = TMethod(Item).Data) then
    begin
      Delete(i);
    end;
    i := i + 1;
  end;
end;

procedure TSurfaceEventList.SetItem(AIndex:integer;AItem:TSurfaceEvent);
begin
  inherited Items[AIndex] := @AItem;
end;

{ THAICompressor }

function THAICompressor.GetInitial: TInitialLetters;
begin
  result := #3+'HAI'
end;

procedure THAICompressor.Read(AStream: TStream; ABmp:TAdBitmap);
var
  input:TMemoryStream;
  output:TMemoryStream;
  dec:THuffmanDecoder;
  s:int64;
begin
  input := TMemoryStream.Create;
  AStream.Read(s,SizeOf(s));
  input.CopyFrom(AStream,s);

  output := TMemoryStream.Create;
  input.Position := 0;
  dec := THuffmanDecoder.Create;
  dec.Input := input;
  dec.Output := output;
  dec.Decode;
  input.Free;
  dec.Free;
  output.Position := 0;

  ABmp.LoadFromStream(output);
  output.Free;
end;

procedure THAICompressor.Write(AStream: TStream; ABmp:TAdBitmap);
var
    input:TMemoryStream;
    output:TMemoryStream;
    enc:THuffmanEncoder;
    s:int64;
begin
  input := TMemoryStream.Create;
  ABmp.SaveToStream(input);

  output := TMemoryStream.Create;

  Input.Position := 0;
  Input.SaveToFile('test.raw');


  enc := THuffmanEncoder.Create;
  enc.Input := input;
  enc.Output := output;
  enc.Encode;
  enc.Free;
  input.Free;

  s := Output.Size;
  AStream.Write(s,SizeOf(s));
  Output.SaveToStream(AStream);
  Output.Free;
end; 

{ TAdTexture }

procedure TAdTexture.Clear;
begin
  if FCache <> nil then
  begin
    FreeAndNil(FCache);
    Texture.FlushTexture;
  end;
end;

constructor TAdTexture.Create(AParent:TAdDraw);
begin
  inherited Create;
  FParent := AParent;
  Initialize;
  FParent.RegisterNotifyEvent(Notify);
  Compressor := THAICompressor;
end;

destructor TAdTexture.Destroy;
begin
  if FCompressor <> nil then
  begin
    FreeAndNil(FCompressor);
  end;
  FParent.UnRegisterNotifyEvent(Notify);
  Finalize;
  Inherited Destroy;
end;

procedure TAdTexture.Finalize;
begin
  if Initialized then
  begin
    FreeAndNil(FAd2DTexture);
  end;
end;

function TAdTexture.GetInitialized: boolean;
begin
  result := FAd2DTexture <> nil;
end;

procedure TAdTexture.Initialize;
begin
  Finalize;
  FAd2DTexture := FParent.AdAppl.CreateBitmapTexture;
end;

procedure TAdTexture.SaveToFile(AFile: string);
var ms:TMemoryStream;
begin
  ms := TMemoryStream.Create;
  SaveToStream(ms);
  ms.SaveToFile(AFile);
end;

procedure TAdTexture.LoadFromFile(AFile: string);
var ms:TMemoryStream;
begin
  ms := TMemoryStream.Create;
  ms.LoadFromFile(AFile);
  ms.Position := 0;
  ms.LoadFromStream(ms);
  ms.Free;
end;

procedure TAdTexture.LoadFromGraphic(AGraphic: TGraphic);
var
  fmt:TAdPictFormat;
  i:integer;
  cref:TAdPictFormatClass;
  bmp:TAdBitmap;
begin
  for i := 0 to RegisteredFormats.Count-1 do
  begin
    cref := TAdPictFormatClass(GetClass(RegisteredFormats[i]));
    if cref <> nil then
    begin
      fmt := TAdPictFormat(cref.Create);
      if fmt.SupportsGraphicClass(TGraphicClass(AGraphic.ClassType)) then
      begin
        break;
      end;
      fmt.Free;
      fmt := nil;
    end;
    if fmt <> nil then
    begin
      bmp := TAdBitmap.Create;
      fmt.AssignGraphic(AGraphic,bmp);
      Texture.LoadFromBitmap(bmp);
      bmp.Free;
    end;    
  end;
end;

procedure TAdTexture.LoadGraphicFromFile(AFile: string; Transparent: boolean;
  TransparentColor: TColor);
var
  fmt:TAdPictFormat;
  i:integer;
  cref:TAdPictFormatClass;
  ext:string;
  str:TStringList;
  bmp:TAdBitmap;
begin
  ext := ExtractFileExt(AFile);
  for i := 0 to RegisteredFormats.Count-1 do
  begin
    cref := TAdPictFormatClass(GetClass(RegisteredFormats[i]));
    if cref <> nil then
    begin
      fmt := TAdPictFormat(cref.Create);
      str := TStringlist.Create;
      fmt.FileExts(str);
      if str.IndexOf(ext) > -1 then
      begin
        str.Free;
        break;
      end;
      str.Free;
      fmt.Free;
      fmt := nil;
    end;
  end;
  if fmt <> nil then
  begin
    bmp := TAdBitmap.Create;
    fmt.LoadFromFile(AFile,bmp,transparent,transparentcolor);
    fmt.Free;
    Texture.LoadFromBitmap(bmp);
    bmp.Free;
  end;
end;

procedure TAdTexture.LoadFromStream(AStream: TStream);
var c:char;
    i:integer;
    s:string;
    cref:TPersistentClass;
    atemp:TCompressor;
    bmp:TAdBitmap;
    bits:byte;
begin
  AStream.Read(c,1);
  if c = 'T' then
  begin
    //Select a compressor
    SetLength(s,4);
    AStream.Read(s[1],4);
    for i := 0 to RegisteredCompressors.Count - 1 do
    begin
      cref := GetClass(RegisteredCompressors[i]);
      if cref <> nil then
      begin
        atemp := TCompressor(TCompressorClass(cref).Create);
        if atemp.GetInitial <> s then
        begin
          FreeAndNil(atemp);
        end
        else
        begin
          break;
        end;
      end;
    end;
    if ATemp <> nil then
    begin
      bmp := TAdBitmap.Create;
      ATemp.Read(AStream,bmp);
      AStream.Read(bits,1);
      Texture.LoadFromBitmap(bmp,bits);
      ATemp.Free;
      bmp.Free;
    end
    else
    begin
      raise ENoCompressor.Create('The compressor '+s+' is not registered!');
    end;
  end;
end;

procedure TAdTexture.SaveToStream(AStream: TStream);
var c:char;
    bmp:TAdBitmap;
    s:string;
    bits:byte;
begin
  if (Texture.Loaded) and (FCompressor <> nil) then
  begin
    c := 'T'; AStream.Write(c,1);

    s := FCompressor.GetInitial;
    AStream.Write(s[1],4);

    bmp := TAdBitmap.Create;
    bmp.ReserveMemory(Texture.Width,Texture.Height);
    Texture.SaveToBitmap(bmp);
    FCompressor.Write(AStream,bmp);
    bmp.Free;

    bits := Texture.BitCount;
    AStream.Write(bits,1);

  end
  else
  begin
    c := #0; AStream.Write(c,1);
  end;
end;

procedure TAdTexture.Notify(ASender: TObject; AEvent: TSurfaceEventState);
var bmp:TAdBitmap;
    ms:TMemoryStream;
begin
  if AEvent = seFinalize then
  begin
    if FCache <> nil then
    begin
      FreeAndNil(FCache);
    end;
    if FAd2DTexture.Loaded then
    begin
      FCache := TMemoryStream.Create;
      SaveToStream(FCache);
      FCache.Position := 0;
    end;
    Finalize;
  end;
  
  if AEvent = seInitialize then
  begin
    Initialize;
    if FCache <> nil then
    begin
      FCache.Position := 0;
      LoadFromStream(FCache);
      FreeAndNil(FCache);
    end;
  end;
end;

procedure TAdTexture.SetCompressor(AClass: TCompressorClass);
begin
  if FCompressor <> nil then
  begin
    FreeAndNil(FCompressor);
  end;
  FCompressor := AClass.Create;
  FCompressorClass := AClass;
end;

{ TAdSimpleFormat }

procedure TAdSimpleFormat.AssignGraphic(AGraphic: TGraphic; ABmp: TAdBitmap);
var bmp:TBitmap;
begin
  if SupportsGraphicClass(TGraphicClass(AGraphic.ClassType)) then
  begin
    bmp := TBitmap.Create;
    if AGraphic is TBitmap then
    begin
      bmp.Assign(AGraphic);
    end
    else
    begin
      bmp.Width := AGraphic.Width;
      bmp.Height := AGraphic.Height;
      bmp.Canvas.StretchDraw(rect(0,0,bmp.Width,bmp.Height),AGraphic);
    end;
    ABmp.AssignBitmap(bmp);
    bmp.Free;
  end
  else
  begin
    raise EFormatNotSupportet.Create('Can not assign the graphic with the format '+AGraphic.ClassName+'. Only support TBitmap, TIcon and TMetafile.');
  end;
end;

procedure TAdSimpleFormat.FileExts(strs: TStringList);
begin
  strs.Add('.bmp');
  strs.Add('.dib');
  strs.Add('.ico');
  strs.Add('.wfm');
  strs.Add('.emf');
end;

function TAdSimpleFormat.LoadFromFile(AFile: string; ABmp: TAdBitmap;Transparent:boolean;TransparentColor:TColor): boolean;
var
  pict:TPicture;
  bmp:TBitmap;
begin
  result := true;
  pict := TPicture.Create;
  try
    pict.LoadFromFile(AFile);
    bmp := TBitmap.Create;
    if pict.Graphic is TBitmap then
    begin
      bmp.Assign(pict.Graphic);
    end
    else
    begin
      bmp.Width := pict.Graphic.Width;
      bmp.Height := pict.Graphic.Height;
      bmp.Canvas.StretchDraw(rect(0,0,bmp.Width,bmp.Height),pict.Graphic);
    end;
    bmp.Transparent := Transparent;
    bmp.TransparentColor := TransparentColor;
    bmp.TransparentMode := tmFixed;
    ABmp.AssignBitmap(bmp);
    bmp.Free;
  except
    result := false;
  end;
  pict.Free;
end;

function TAdSimpleFormat.SupportsGraphicClass(AGraphicClass: TGraphicClass): boolean;
begin
  result := (AGraphicClass = TBitmap) or (AGraphicClass = TMetafile) or (AGraphicClass = TIcon);
end;

initialization
  RegisteredCompressors := TStringList.Create;
  RegisteredFormats := TStringList.Create;
  RegisterCompressor(THAICompressor);
  RegisterFormat(TAdSimpleFormat);

finalization
  RegisteredCompressors.Free;
  RegisteredFormats.Free;

end.
