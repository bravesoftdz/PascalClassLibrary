unit UCommFrame;

{$mode Delphi}{$H+}

interface

uses
  Classes, UStreamHelper, Dialogs, SysUtils,
  UCommPin;

const
  SpecialChar = $fe;
  ControlCodeFrameStart = $fd;
  ControlCodeFrameEnd = $fc;
  ControlCodeSpecialChar = $fb;
  TimeoutRepeatCount = 3;

type
  TFrameState = (fsOutside, fsStart, fsInside, fsEnd);

  TCommFrame = class
  private
    LastCharIsSpecialChar: Boolean;
    ReceiveBuffer: TStreamHelper;
    FrameState: TFrameState;
    FFrameErrorCount: Integer;
    FCRCErrorCount: Integer;
    function GetStreamCRC8(Stream: TStream): Byte;
  public
    RawDataPin: TCommPin;
    FrameDataPin: TCommPin;
    PacketLoss: Real;
    procedure RawDataReceive(Sender: TCommPin; Stream: TStream);
    procedure FrameDataReceive(Sender: TCommPin; Stream: TStream);
    constructor Create;
    destructor Destroy; override;
    property FrameErrorCount: Integer read FFrameErrorCount;
    property CRCErrorCount: Integer read FCRCErrorCount;
  end;


implementation

{ TCommFrame }

constructor TCommFrame.Create;
begin
  ReceiveBuffer := TStreamHelper.Create;
  RawDataPin := TCommPin.Create;
  RawDataPin.OnReceive := RawDataReceive;
  FrameDataPin := TCommPin.Create;
  FrameDataPin.OnReceive := FrameDataReceive;
  PacketLoss := 0.005;
end;

destructor TCommFrame.Destroy;
begin
  FreeAndNil(RawDataPin);
  FreeAndNil(FrameDataPin);
  ReceiveBuffer.Free;
  inherited;
end;

procedure TCommFrame.FrameDataReceive(Sender: TCommPin; Stream: TStream);
var
  RawData: TStreamHelper;
  I: Integer;
  Character: Byte;
  CRC: Byte;
begin
  // Write CRC code to end of frame
  Stream.Position := 0;
  CRC := GetStreamCRC8(Stream);

  // Byte stuffing
  Stream.Position := 0;
  try
    RawData := TStreamHelper.Create;
    RawData.WriteByte(SpecialChar);
    RawData.WriteByte(ControlCodeFrameStart);
    for I := 0 to Stream.Size - 1 do begin
      Character := Stream.ReadByte;
      if Character = SpecialChar then begin
        RawData.WriteByte(SpecialChar);
        RawData.WriteByte(ControlCodeSpecialChar);
      end else RawData.WriteByte(Character);
    end;

    Character := CRC;
    if Character = SpecialChar then begin
      RawData.WriteByte(SpecialChar);
      RawData.WriteByte(ControlCodeSpecialChar);
    end else RawData.WriteByte(Character);

    RawData.WriteByte(SpecialChar);
    RawData.WriteByte(ControlCodeFrameEnd);
    //if Random >= PacketLoss then
      RawDataPin.Send(RawData);

  finally
    RawData.Free;
  end;
end;

procedure TCommFrame.RawDataReceive(Sender: TCommPin; Stream: TStream);
var
  Character: Byte;
  CRC: Byte;
  ExpectedCRC: Byte;
  I: Integer;
begin
  for I := 0 to Stream.Size - 1 do begin
    Character := Stream.ReadByte;
    if LastCharIsSpecialChar then begin
      if Character = ControlCodeSpecialChar then begin
          ReceiveBuffer.WriteByte(SpecialChar)
        end else
        if Character = ControlCodeFrameStart then begin
          if FrameState = fsInside then
            Inc(FFrameErrorCount);
          ReceiveBuffer.Size := 0;
          FrameState := fsInside;
        end else
        if Character = ControlCodeFrameEnd then begin
          if FrameState = fsInside then begin
            // Check CRC
            if ReceiveBuffer.Size > 0 then begin
              ReceiveBuffer.Position := ReceiveBuffer.Size - 1;
              CRC := ReceiveBuffer.ReadByte;
              ReceiveBuffer.Size := ReceiveBuffer.Size - 1;
              ExpectedCRC := GetStreamCRC8(ReceiveBuffer);

              if ExpectedCRC <> CRC then Inc(FCRCErrorCount)
                else begin
                  //if Random >= PacketLoss then
                    FrameDataPin.Send(ReceiveBuffer);
                end;
            end else Inc(FCRCErrorCount);
          end else Inc(FFrameErrorCount);
          FrameState := fsOutside;
        end;
        LastCharIsSpecialChar := False;
      end else begin
        if Character = SpecialChar then LastCharIsSpecialChar := True
        else ReceiveBuffer.WriteByte(Character);
      end;
    end;
end;

function TCommFrame.GetStreamCRC8(Stream: TStream): Byte;
var
  I: Integer;
  B: Integer;
  Pom: Byte;
const
  Polynom: Byte = $18;
begin
  Stream.Position := 0;
  Result := 0;
  for I := 0 to Stream.Size - 1 do begin
    Stream.Read(Pom, 1);
    for B := 0 to 7 do begin
      if ((Result xor Pom) and 1) = 1 then Result := ((Result xor Polynom) shr 1) or $80
        else Result := Result shr 1;
      Pom := (Pom shr 1) or ((Pom shl 7) and $80); // Rotace vpravo
    end;
  end;
end;


end.
