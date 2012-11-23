unit UCanvasPixelsUpdateLock;

{$mode delphi}

interface

uses
  Classes, SysUtils, UDrawMethod, UFastBitmap, Graphics;

type
  { TCanvasPixelsUpdateLock }

  TCanvasPixelsUpdateLock = class(TDrawMethodImage)
    constructor Create; override;
    procedure DrawFrame(FastBitmap: TFastBitmap); override;
  end;


implementation

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
    Image.Picture.Bitmap.BeginUpdate(True);
    for Y := 0 to Size.Y - 1 do
      for X := 0 to Size.X - 1 do
        Image.Picture.Bitmap.Canvas.Pixels[X, Y] := TColor(SwapBRComponent(Pixels[X, Y]));
  finally
    Image.Picture.Bitmap.EndUpdate(False);
  end;
end;


end.
