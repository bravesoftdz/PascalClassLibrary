unit UDrawMethod;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StdCtrls, ExtCtrls, UPlatform, UFastBitmap, Graphics,
  LCLType, IntfGraphics, fpImage, GraphType, BGRABitmap, BGRABitmapTypes,
  LclIntf;

type
  TPaintObject = (poImage, poPaintBox, poOpenGL);

  { TDrawMethod }

  TDrawMethod = class
  private
    FBitmap: TBitmap;
    TempBitmap: TBitmap;
    FPaintBox: TPaintBox;
    procedure SetBitmap(const AValue: TBitmap); virtual;
    procedure SetPaintBox(const AValue: TPaintBox);
  public
    Caption: string;
    Terminated: Boolean;
    FrameDuration: TDateTime;
    PaintObject: TPaintObject;
    constructor Create; virtual;
    destructor Destroy; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); virtual;
    procedure DrawFrameTiming(FastBitmap: TFastBitmap);
    property Bitmap: TBitmap read FBitmap write SetBitmap;
    property PaintBox: TPaintBox read FPaintBox write SetPaintBox;
  end;

  TDrawMethodClass = class of TDrawMethod;

  { TCanvasPixels }

  TCanvasPixels = class(TDrawMethod)
    constructor Create; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); override;
  end;

  { TCanvasPixelsUpdateLock }

  TCanvasPixelsUpdateLock = class(TDrawMethod)
    constructor Create; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); override;
  end;

  { TLazIntfImageColorsCopy }

  TLazIntfImageColorsCopy = class(TDrawMethod)
    TempIntfImage: TLazIntfImage;
    constructor Create; override;
    destructor Destroy; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); override;
  end;

  { TLazIntfImageColorsNoCopy }

  TLazIntfImageColorsNoCopy = class(TDrawMethod)
    TempIntfImage: TLazIntfImage;
    procedure SetBitmap(const AValue: TBitmap); override;
    constructor Create; override;
    destructor Destroy; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); override;
  end;

  { TBitmapRawImageData }

  TBitmapRawImageData = class(TDrawMethod)
    constructor Create; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); override;
  end;

  { TBitmapRawImageDataPaintBox }

  TBitmapRawImageDataPaintBox = class(TDrawMethod)
    constructor Create; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); override;
  end;

  { TBGRABitmapPaintBox }

  TBGRABitmapPaintBox = class(TDrawMethod)
    BGRABitmap: TBGRABitmap;
    procedure SetBitmap(const AValue: TBitmap); override;
    constructor Create; override;
    destructor Destroy; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); override;
  end;

const
  DrawMethodClasses: array[0..6] of TDrawMethodClass = (
    TCanvasPixels, TCanvasPixelsUpdateLock, TLazIntfImageColorsCopy,
    TLazIntfImageColorsNoCopy, TBitmapRawImageData, TBitmapRawImageDataPaintBox,
    TBGRABitmapPaintBox);

implementation

{ TBGRABitmapPaintBox }

procedure TBGRABitmapPaintBox.SetBitmap(const AValue: TBitmap);
begin
  inherited;
  BGRABitmap.SetSize(Bitmap.Width, Bitmap.Height);
end;

constructor TBGRABitmapPaintBox.Create;
begin
  inherited;
  Caption := 'TBGRABitmap PaintBox';
  BGRABitmap := TBGRABitmap.Create(0, 0);
  PaintObject := poPaintBox;
end;

destructor TBGRABitmapPaintBox.Destroy;
begin
  BGRABitmap.Free;
  inherited Destroy;
end;

procedure TBGRABitmapPaintBox.DrawFrame(FastBitmap: TFastBitmap);
var
  X, Y: Integer;
  P: PInteger;
begin
  with FastBitmap do
  for Y := 0 to Size.Y - 1 do begin
    P := PInteger(BGRABitmap.ScanLine[Y]);
    for X := 0 to Size.X - 1 do begin
      P^ := NoSwapBRComponent(Pixels[X, Y]) or $ff000000;
      (*P^.red := Pixels[X, Y];
      P^.green := Pixels[X, Y];
      P^.blue := Pixels[X, Y];
      P^.alpha := 255; *)
      Inc(P);
    end;
  end;
  BGRABitmap.InvalidateBitmap; // changed by direct access
  //BGRABitmap.Draw(Bitmap.Canvas, 0, 0, True);
  BGRABitmap.Draw(PaintBox.Canvas, 0, 0, True);
//  Bitmap.RawImage.Ass
end;

{ TBitmapRawImageDataPaintBox }

constructor TBitmapRawImageDataPaintBox.Create;
begin
  inherited;
  Caption := 'TBitmap.RawImage.Data PaintBox';
  PaintObject := poPaintBox;
end;

procedure TBitmapRawImageDataPaintBox.DrawFrame(FastBitmap: TFastBitmap);
var
  Y, X: Integer;
  PixelPtr: PInteger;
  RowPtr: PInteger;
  P: TPixelFormat;
  RawImage: TRawImage;
  BytePerPixel: Integer;
  BytePerRow: Integer;
  hPaint, hBmp: HDC;
begin
  P := TempBitmap.PixelFormat;
    with FastBitmap do
    try
      TempBitmap.BeginUpdate(False);
      RawImage := TempBitmap.RawImage;
      RowPtr := PInteger(RawImage.Data);
      BytePerPixel := RawImage.Description.BitsPerPixel div 8;
      BytePerRow := RawImage.Description.BytesPerLine;
      for Y := 0 to Size.Y - 1 do begin
        PixelPtr := RowPtr;
        for X := 0 to Size.X - 1 do begin
          PixelPtr^ := Pixels[X, Y];
          Inc(PByte(PixelPtr), BytePerPixel);
        end;
        Inc(PByte(RowPtr), BytePerRow);
      end;
    finally
      TempBitmap.EndUpdate(False);
    end;
    hBmp := TempBitmap.Canvas.Handle;
    hPaint := PaintBox.Canvas.Handle;
    PaintBox.Canvas.CopyRect(Rect(0, 0, Bitmap.Width, Bitmap.Height), TempBitmap.Canvas,
      Rect(0, 0, TempBitmap.Width, TempBitmap.Height));
    //BitBlt(hPaint, 0, 0, TempBitmap.Width, TempBitmap.Height, hBmp, 0, 0, srcCopy);
end;

{ TBitmapRawImageData }

constructor TBitmapRawImageData.Create;
begin
  inherited;
  Caption := 'TBitmap.RawImage.Data';
end;

procedure TBitmapRawImageData.DrawFrame(FastBitmap: TFastBitmap);
type
  TFastBitmapPixelComponents = packed record
  end;
var
  Y, X: Integer;
  PixelPtr: PInteger;
  RowPtr: PInteger;
  P: TPixelFormat;
  RawImage: TRawImage;
  BytePerPixel: Integer;
  BytePerRow: Integer;
begin
  P := Bitmap.PixelFormat;
    with FastBitmap do
    try
      Bitmap.BeginUpdate(False);
      RawImage := Bitmap.RawImage;
      RowPtr := PInteger(RawImage.Data);
      BytePerPixel := RawImage.Description.BitsPerPixel div 8;
      BytePerRow := RawImage.Description.BytesPerLine;
      for Y := 0 to Size.Y - 1 do begin
        PixelPtr := RowPtr;
        for X := 0 to Size.X - 1 do begin
          PixelPtr^ := Pixels[X, Y];
          Inc(PByte(PixelPtr), BytePerPixel);
        end;
        Inc(PByte(RowPtr), BytePerRow);
      end;
    finally
      Bitmap.EndUpdate(False);
    end;
end;

{ TLazIntfImageColorsNoCopy }

procedure TLazIntfImageColorsNoCopy.SetBitmap(const AValue: TBitmap);
begin
  inherited SetBitmap(AValue);
  TempIntfImage.Free;
  TempIntfImage := Bitmap.CreateIntfImage;
end;

constructor TLazIntfImageColorsNoCopy.Create;
begin
  inherited;
  Caption := 'TLazIntfImage.Colors no copy';
end;

destructor TLazIntfImageColorsNoCopy.Destroy;
begin
  TempIntfImage.Free;
  inherited Destroy;
end;

procedure TLazIntfImageColorsNoCopy.DrawFrame(FastBitmap: TFastBitmap);
var
  Y, X: Integer;
begin
  with FastBitmap do begin
    for X := 0 to Size.X - 1 do
      for Y := 0 to Size.Y - 1 do
        TempIntfImage.Colors[X, Y] := TColorToFPColor(SwapBRComponent(Pixels[X, Y]));
    Bitmap.LoadFromIntfImage(TempIntfImage);
  end;
end;

{ TLazIntfImageColorsCopy }

constructor TLazIntfImageColorsCopy.Create;
begin
  inherited;
  Caption := 'TLazIntfImage.Colors copy';
  TempIntfImage := TLazIntfImage.Create(0, 0);
end;

destructor TLazIntfImageColorsCopy.Destroy;
begin
  TempIntfImage.Free;
  inherited Destroy;
end;

procedure TLazIntfImageColorsCopy.DrawFrame(FastBitmap: TFastBitmap);
var
  Y, X: Integer;
begin
  with FastBitmap do begin
    TempIntfImage.LoadFromBitmap(Bitmap.Handle,
      Bitmap.MaskHandle);
    for X := 0 to Size.X - 1 do
      for Y := 0 to Size.Y - 1 do
        TempIntfImage.Colors[X, Y] := TColorToFPColor(SwapBRComponent(Pixels[X, Y]));
    Bitmap.LoadFromIntfImage(TempIntfImage);
  end;
end;

{ TCanvasPixelsUpdateLock }

constructor TCanvasPixelsUpdateLock.Create;
begin
  inherited;
  Caption := 'TBitmap.Canvas.Pixels Update locking';
end;

procedure TCanvasPixelsUpdateLock.DrawFrame(FastBitmap: TFastBitmap);
var
  Y, X: Integer;
begin
  with FastBitmap do
  try
    Bitmap.BeginUpdate(True);
    for X := 0 to Size.X - 1 do
      for Y := 0 to Size.Y - 1 do
        Bitmap.Canvas.Pixels[X, Y] := SwapBRComponent(Pixels[X, Y]);
  finally
    Bitmap.EndUpdate(False);
  end;
end;

{ TCanvasPixels }

constructor TCanvasPixels.Create;
begin
  inherited;
  Caption := 'TBitmap.Canvas.Pixels';
end;

procedure TCanvasPixels.DrawFrame(FastBitmap: TFastBitmap);
var
  Y, X: Integer;
begin
  with FastBitmap do begin
    for X := 0 to Size.X - 1 do
      for Y := 0 to Size.Y - 1 do
        Bitmap.Canvas.Pixels[X, Y] := SwapBRComponent(Pixels[X, Y]);
  end;
end;

{ TDrawMethod }

procedure TDrawMethod.SetBitmap(const AValue: TBitmap);
begin
  if FBitmap = AValue then exit;
  FBitmap := AValue;
  TempBitmap.SetSize(FBitmap.Width, FBitmap.Height);
end;

procedure TDrawMethod.SetPaintBox(const AValue: TPaintBox);
begin
  if FPaintBox = AValue then Exit;
  FPaintBox := AValue;
end;

constructor TDrawMethod.Create;
begin
  TempBitmap := TBitmap.Create;
end;

destructor TDrawMethod.Destroy;
begin
  TempBitmap.Free;
  inherited Destroy;
end;

procedure TDrawMethod.DrawFrame(FastBitmap: TFastBitmap);
begin

end;

procedure TDrawMethod.DrawFrameTiming(FastBitmap: TFastBitmap);
var
  StartTime: TDateTime;
begin
  StartTime := NowPrecise;
  DrawFrame(FastBitmap);
  FrameDuration := NowPrecise - StartTime;
end;

end.
