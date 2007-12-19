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
* File: AdPNStandardFontGenerator.pas
* Comment: The standard font generator class
}

unit AdStandardFontGenerator;

interface

uses
  AdTypes, AdClasses, AdFontGenerator, Graphics, AdBitmap;

type
  TAdStandardFontProperties = packed record
    FontName:ShortString;
    FontSize:integer;
    FontStyles:TAdFontStyles;
    ShadowColor:longint;
    ShadowAlpha:byte;
    ShadowOffsetX:integer;
    ShadowOffsetY:integer;
    ShadowBlur:byte;
  end;

  PAdStandardFontProperties = ^TAdStandardFontProperties;

  TAdStandardFontGenerator = class(TAdFontGenerator)
    public
      procedure Generate(AData:Pointer;ASize:Cardinal;
        var ASizes:TAdCharSizes; var APatterns: TAdCharPatterns; ATexture:TAd2dBitmapTexture);override;
      function IsValidData(AData:Pointer;ASize:Cardinal):boolean;override;
  end;


implementation

{ TAdStandardFontGenerator }

procedure TAdStandardFontGenerator.Generate(AData: Pointer; ASize: Cardinal;
  var ASizes: TAdCharSizes; var APatterns: TAdCharPatterns; ATexture: TAd2dBitmapTexture);
var
  tmp:PByte;
  data:PAdStandardFontProperties;
  rgb, alpha:TBitmap;
  i,j:integer;
  c:char;
  maxw, maxh, ax, ay, sx, sy, cx, cy:integer;
  shadow:boolean;
  adbmp:TAdBitmap;
  alphacolor:longint;
  params:TAd2dBitmapTextureParameters;
begin
  tmp := AData;
  inc(tmp, 5);

  data := PAdStandardFontProperties(tmp);
  with data^ do
  begin
    rgb := TBitmap.Create;

    //Set font properties
    with rgb.Canvas.Font do
    begin
      Name := FontName;
      Size := FontSize;
      Color := clWhite;
      Style := [];
      if afItalic in FontStyles then Style := Style + [fsItalic];
      if afBold in FontStyles then Style := Style + [fsBold];
      if afUnderLine in FontStyles then Style := Style + [fsUnderline];
    end;

    //Calculate max char size
    maxw := 0;
    maxh := 0;

    for i := 0 to 255 do
    begin
      ax := rgb.Canvas.TextWidth(chr(i));
      ay := rgb.Canvas.TextHeight(chr(i));
      if ax > maxw then maxw := ax;
      if ay > maxh then maxh := ay;
    end;

    maxw := maxw + abs(ShadowOffsetX) + ShadowBlur + 1;
    maxh := maxh + abs(ShadowOffsetY) + ShadowBlur + 1;

    //Set bitmap size as calculated
    rgb.Width := (maxw) * 16;
    rgb.Height := (maxh) * 16;

    shadow := (ShadowOffsetX <> 0) or (ShadowOffSetY <> 0) or (ShadowBlur <> 0);

    //Prepare alphachannel
    alphacolor := AdTypes.RGB(ShadowAlpha,ShadowAlpha,ShadowAlpha);
    alpha := TBitmap.Create;
    alpha.Width := rgb.Width;
    alpha.Height := rgb.Height;

    alpha.Canvas.Font.Assign(rgb.Canvas.Font);
    alpha.Canvas.Font.Color := alphacolor;

    with rgb.Canvas do
    begin
      alpha.Canvas.Brush.Color := clBlack;
      alpha.Canvas.FillRect(ClipRect);
      alpha.Canvas.Brush.Style := bsClear;

      Brush.Color := ShadowColor;
      FillRect(ClipRect);
      Brush.Style := bsClear;

      for i := 0 to 15 do
      begin
        for j := 0 to 15 do
        begin
          c := chr(i * 16 + j);
          ax := TextWidth(c) + ShadowBlur;
          ay := TextHeight(c) + ShadowBlur;

          sx := j * maxw;
          sy := i * maxh;

          cx := sx;
          cy := sy;

          if shadow then
          begin
            if ShadowOffsetX < 0 then
              cx := cx - ShadowOffsetX;
            if ShadowOffsetY < 0 then
              cy := cy - ShadowOffsetY;

            ax := ax + abs(ShadowOffsetX);
            ay := ay + abs(ShadowOffsetY);

            alpha.Canvas.Font.Color := alphacolor;
            alpha.Canvas.TextOut(cx + ShadowOffsetX, cy + ShadowOffsetY, c);
          end;

          ASizes[i * 16 + j] := AdPoint(ax, ay);
          APatterns[i * 16 + j] := AdRect(j*maxw, i*maxh, j*maxw + (maxw + ax) div 2, i*maxh + (maxh + ay) div 2);

          //Alphachannel
          alpha.Canvas.Font.Color := clWhite;
          alpha.Canvas.TextOut(cx, cy, c);
          
          TextOut(cx, cy, c);
        end;
      end;
    end;

    adbmp := TAdBitmap.Create;
    adbmp.Assign(rgb);
    adbmp.AssignAlphaChannel(alpha);

    with params do
    begin
      BitDepth := 32;
      UseMipmaps := true;
      MinFilter := atPoint;
      MagFilter := atPoint;
      MipFilter := atPoint;
    end;
    ATexture.LoadFromBitmap(adbmp, params);

    adbmp.Free;

    alpha.Free;
    rgb.Free;
  end;
end;

function TAdStandardFontGenerator.IsValidData(AData: Pointer;
  ASize: Cardinal): boolean;
var
  pss:^TAdVeryShortString;
begin
  pss := AData;
  result := pss^ = 'STDF';
end;

initialization
  RegisterFontGeneratorClass(TAdStandardFontGenerator);

end.
