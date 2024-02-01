unit ADato.MultiObjectModelContextSupport.impl;

interface

uses
  System_,
  System.Collections,
  System.Collections.Generic,

  ADato.ObjectModel.impl,
  ADato.ObjectModel.intf,
  ADato.ObjectModel.List.impl,
  ADato.ObjectModel.List.intf,
  ADato.MultiObjectModelContextSupport.intf,
  ADato.Models.VirtualListItemDelegate,
  ADato.ObjectModel.List.Tracking.intf,
  ADato.ObjectModel.List.Tracking.impl;

type
  TMultiEditableObjectModelContext = class(TEditableObjectModelContext, IMultiObjectContextSupport)
  protected
    _contexts: Dictionary<CObject, IObjectModelContext>;
    _onListItemChanged: IListItemChanged;

    function  get_StoredContexts: Dictionary<CObject, IObjectModelContext>;
    procedure OnContextChanged(const Sender: IObjectListModel; const Context: IList);

  public
    constructor Create(const AModel: IObjectModel; const AOwner: IObjectListModelChangeTracking); reintroduce; overload;
    destructor Destroy; override;

    function  ProvideObjectModelContext(const DataItem: CObject): IObjectModelContext;
    function  FindObjectModelContext(const DataItem: CObject): IObjectModelContext;
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
    constructor Create(const ListObjectModelContext: IObjectModelContext); reintroduce;
  end;

  TOnListItemChanged = class(TVirtualListItemChanged)
  protected
    [weak] _objectListModel: IObjectListModel;
    [weak] _multiObjectContextSupport: IMultiObjectContextSupport;

    procedure BeginEdit(const Item: CObject); override;
    procedure CancelEdit(const Item: CObject); override;

    procedure UpdateStoredContext;

  public
    constructor Create(const ObjectListModel: IObjectListModel; const MultiObjectContextSupport: IMultiObjectContextSupport);
  end;

implementation

uses
  System.ComponentModel;

{ TMultiEditableObjectModelContext }

constructor TMultiEditableObjectModelContext.Create(const AModel: IObjectModel; const AOwner: IObjectListModelChangeTracking);
begin
  inherited;

  _contexts := CDictionary<CObject, IObjectModelContext>.Create;

  _onListItemChanged := TOnListItemChanged.Create(Owner, Self);
  Owner.OnItemChanged.Add(_onListItemChanged);
  Owner.OnContextChanged.Add(OnContextChanged);
end;

function TMultiEditableObjectModelContext.ProvideObjectModelContext(const DataItem: CObject): IObjectModelContext;
begin
  Result := FindObjectModelContext(DataItem);

  if Result = nil then
  begin
    // keep object reference in memory, so we can search back for it and keep track of changes
    var omc := Owner.ObjectModelContext;
    Result := TStorageObjectModelContext.Create(omc);
    Result.Context := DataItem;

    _Contexts.Add(DataItem, Result);
  end;
end;

destructor TMultiEditableObjectModelContext.Destroy;
begin
  if (Owner <> nil) then
  begin
    Owner.OnContextChanged.Remove(OnContextChanged);
    Owner.OnItemChanged.Remove(_onListItemChanged);
  end;

  _onListItemChanged := nil;

  inherited;
end;

function TMultiEditableObjectModelContext.FindObjectModelContext(const DataItem: CObject): IObjectModelContext;
begin
  Assert(DataItem <> nil, 'DataItem may not be nil');

  if not _Contexts.TryGetValue(DataItem, Result) then
    Exit(nil);

  // update dataitem, for "Stored Context" can be nil (if new), or contain "Old Version" of Object
  Result.Context := DataItem;
end;

function TMultiEditableObjectModelContext.get_StoredContexts: Dictionary<CObject, IObjectModelContext>;
begin
  Result := _Contexts;
end;

procedure TMultiEditableObjectModelContext.OnContextChanged(const Sender: IObjectListModel; const Context: IList);
begin
  _Contexts.Clear;
end;

procedure TMultiEditableObjectModelContext.RemoveObjectModelContext(const DataItem: CObject);
var
  mdlContext: IObjectModelContext;
begin
  if not _Contexts.TryGetValue(DataItem, mdlContext) then
    Exit;

  mdlContext.Unbind;
  _Contexts.Remove(DataItem);
end;

{ TStorageObjectModelContext }

constructor TStorageObjectModelContext.Create(const ListObjectModelContext: IObjectModelContext);
begin
  inherited Create(ListObjectModelContext.Model);
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

{ TOnListItemChanged }

constructor TOnListItemChanged.Create(const ObjectListModel: IObjectListModel; const MultiObjectContextSupport: IMultiObjectContextSupport);
begin
  _objectListModel := ObjectListModel;
  _multiObjectContextSupport := MultiObjectContextSupport;
end;

procedure TOnListItemChanged.BeginEdit(const Item: CObject);
begin
  UpdateStoredContext;
end;

procedure TOnListItemChanged.CancelEdit(const Item: CObject);
begin
  UpdateStoredContext;
end;

procedure TOnListItemChanged.UpdateStoredContext;
var
  ctxt: IObjectModelContext;
begin
  if not _multiObjectContextSupport.StoredContexts.TryGetValue(_objectListModel.ObjectContext, ctxt) then
    Exit;

  (ctxt as IUpdatableObject).BeginUpdate;
  try
    ctxt.Context := _objectListModel.ObjectContext; // overwrite with clone / original object
  finally
    (ctxt as IUpdatableObject).EndUpdate;
  end;
end;

end.
