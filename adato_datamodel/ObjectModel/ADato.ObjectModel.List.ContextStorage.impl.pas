unit ADato.ObjectModel.List.ContextStorage.impl;

interface

uses
  ADato.ObjectModel.intf, System.Collections.Generic, System_,
  System.Collections, ADato.ObjectModel.List.impl,
  ADato.ObjectModel.List.intf, ADato.ObjectModel.impl;

type
  TObjectListModelContextStorage<T> = class(TObjectListModel<T>, IObjectListModelContextStorage)
  protected
    _contexts: Dictionary<CObject, IObjectModelContext>;

    procedure set_Context(const Value: IList); override;
    function  get_StoredContexts: Dictionary<CObject, IObjectModelContext>;
  public
    constructor Create; reintroduce; virtual;
    function FindObjectModelContext(const DataItem: CObject; const CreateIfNotExists: Boolean): IObjectModelContext;
    procedure RemoveObjectModelContext(const DataItem: CObject);

    property StoredContexts: Dictionary<CObject, IObjectModelContext> read get_StoredContexts;
  end;

  TStorageObjectModelContext = class(TObjectModelContext)
  protected
    [weak] _listObjectModelContext: IObjectModelContext;

    procedure UpdateListObjectContext;
    procedure UpdateValueFromBoundProperty(const APropertyName: CString; const Value: CObject; ExecuteTriggers: Boolean); override;
    procedure UpdateValueFromBoundProperty(const ABinding: IPropertyBinding; const Value: CObject; ExecuteTriggers: Boolean); override;
  public
    constructor Create(const AModel: IObjectModel; const ListObjectModelContext: IObjectModelContext); reintroduce;
  end;

implementation

uses
  System.ComponentModel;

{ TObjectListModelContextStorage<T> }

constructor TObjectListModelContextStorage<T>.Create;
begin
  inherited Create;
  _Contexts := CDictionary<CObject, IObjectModelContext>.Create;
end;

procedure TObjectListModelContextStorage<T>.set_Context(const Value: IList);
begin
  _Contexts.Clear;
  inherited;
end;

function TObjectListModelContextStorage<T>.FindObjectModelContext(const DataItem: CObject; const CreateIfNotExists: Boolean): IObjectModelContext;
begin
  Assert(DataItem <> nil, 'DataItem may not be nil');

  if not _Contexts.TryGetValue(DataItem, Result) and CreateIfNotExists then
  begin
    Result := TStorageObjectModelContext.Create(get_ObjectModel, get_ObjectModelContext);

    // keep object reference in memory, so we can search back for it and keep track of changes
    _Contexts.Add(DataItem, Result);
  end;

  // update dataitem, for "Stored Context" can be nil (if new), or contain "Old Version" of Object
  if Result <> nil then
    Result.Context := DataItem;
end;

function TObjectListModelContextStorage<T>.get_StoredContexts: Dictionary<CObject, IObjectModelContext>;
begin
  Result := _Contexts;
end;

procedure TObjectListModelContextStorage<T>.RemoveObjectModelContext(const DataItem: CObject);
var
  mdlContext: IObjectModelContext;
begin
  if not _Contexts.TryGetValue(DataItem, mdlContext) then
    Exit;

  mdlContext.Unbind;
  _Contexts.Remove(DataItem);
end;

{ TStorageObjectModelContext }

constructor TStorageObjectModelContext.Create(const AModel: IObjectModel; const ListObjectModelContext: IObjectModelContext);
begin
  inherited Create(AModel);
  _listObjectModelContext := ListObjectModelContext;
end;

procedure TStorageObjectModelContext.UpdateListObjectContext;
begin
  _listObjectModelContext.Context := Self.get_Context;
end;

procedure TStorageObjectModelContext.UpdateValueFromBoundProperty(const ABinding: IPropertyBinding; const Value: CObject; ExecuteTriggers: Boolean);
begin
  UpdateListObjectContext;
  _listObjectModelContext.UpdateValueFromBoundProperty(ABinding, Value, ExecuteTriggers);

  inherited;
end;

procedure TStorageObjectModelContext.UpdateValueFromBoundProperty(const APropertyName: CString; const Value: CObject; ExecuteTriggers: Boolean);
begin
  UpdateListObjectContext;
  _listObjectModelContext.UpdateValueFromBoundProperty(APropertyName, Value, ExecuteTriggers);

  inherited;
end;

end.
