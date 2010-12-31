{$IFDEF INTERFACE}

{$DEFINE TGListIndex := TGListObjectIndex}
{$DEFINE TGListItem := TGListObjectItem}
{$DEFINE TGList := TGListObjectList}
{$DEFINE TGListSortCompare := TGListObjectSortCompare}
{$DEFINE TGListToStringConverter := TGListObjectToStringConverter}
{$DEFINE TGListFromStringConverter := TGListObjectFromStringConverter}
{$DEFINE INTERFACE}
{$I 'GenericList.inc'}

  // TGListObject<TListObjectIndex, TListObjectItem> = class(TGList)
  TGListObject = class(TGList)
  private
    procedure Put(Index: TGListIndex; const AValue: TGListItem); override;
  public
    OwnsObjects: Boolean;
    procedure Delete(Index: TGListObjectIndex); override;
    procedure Clear; override;
    procedure Assign(Source: TGList); override;
    constructor Create;
    destructor Destroy; override;
  end;

{$UNDEF INTERFACE}
{$ENDIF}

{$IFDEF IMPLEMENTATION_USES}

  {$DEFINE IMPLEMENTATION_USES}
  {$I 'GenericList.inc'}

{$UNDEF IMPLEMENTATION_USES}
{$ENDIF}

{$IFDEF IMPLEMENTATION}

{$DEFINE TGListIndex := TGListObjectIndex}
{$DEFINE TGListItem := TGListObjectItem}
{$DEFINE TGList := TGListObjectList}
{$DEFINE TGListSortCompare := TGListObjectSortCompare}
{$DEFINE TGListToStringConverter := TGListObjectToStringConverter}
{$DEFINE TGListFromStringConverter := TGListObjectFromStringConverter}
{$DEFINE IMPLEMENTATION}
{$I 'GenericList.inc'}

{ TGListObject }

procedure TGListObject.Assign(Source: TGList);
begin
  Clear;
  OwnsObjects := False;
  inherited;
end;

procedure TGListObject.Put(Index: TGListIndex; const AValue: TGListItem);
begin
  if OwnsObjects then FItems[Index].Free;
  inherited Put(Index, AValue);
end;

procedure TGListObject.Delete(Index: TGListObjectIndex);
begin
  if OwnsObjects then FItems[Index].Free;
  inherited Delete(Index);
end;

procedure TGListObject.Clear;
var
  I: TGListObjectIndex;
begin
  if OwnsObjects then begin
    I := 0;
    while I < Count do begin
      FItems[I].Free;
      I := I + 1;
    end;
  end;
  inherited Clear;
end;

constructor TGListObject.Create;
begin
  inherited;
  OwnsObjects := True;
end;

destructor TGListObject.Destroy;
begin
  Clear;
  inherited Destroy;
end;

{$UNDEF IMPLEMENTATION}
{$ENDIF}