unit ADato.Models.VirtualListItemDelegate;

interface

uses
  System_,
  ADato.ObjectModel.TrackInterfaces,
  ADato.InsertPosition;

type
  TVirtualListItemChanged = class(TBaseInterfacedObject, IListItemChanged)
  protected
    procedure AddingNew(const Value: CObject; var Index: Integer; Position: InsertPosition); virtual;
    procedure Added(const Value: CObject; const Index: Integer); virtual;
    procedure Removed(const Value: CObject; const Index: Integer); virtual;
    procedure BeginEdit(const Item: CObject); virtual;
    procedure CancelEdit(const Item: CObject); virtual;
    procedure EndEdit(const Item: CObject); virtual;
  end;

implementation

{ TVirtualListItemChanged }

procedure TVirtualListItemChanged.Added(const Value: CObject; const Index: Integer);
begin
  // nothing to do
end;

procedure TVirtualListItemChanged.AddingNew(const Value: CObject; var Index: Integer; Position: InsertPosition);
begin
  // nothing to do
end;

procedure TVirtualListItemChanged.BeginEdit(const Item: CObject);
begin
  // nothing to do
end;

procedure TVirtualListItemChanged.CancelEdit(const Item: CObject);
begin
  // nothing to do
end;

procedure TVirtualListItemChanged.EndEdit(const Item: CObject);
begin
  // nothing to do
end;

procedure TVirtualListItemChanged.Removed(const Value: CObject; const Index: Integer);
begin
  // nothing to do
end;

end.
