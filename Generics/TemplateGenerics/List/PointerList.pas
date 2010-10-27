unit PointerList;

{$mode delphi}

interface

uses
  Classes, SysUtils;

type
  TListIndex = Integer;
  TListItem = Pointer;
{$INCLUDE 'GenericListInterface.tpl'}

type
  TPointerList = class(TGList)
  end;

implementation

{$INCLUDE 'GenericListImplementation.tpl'}


end.