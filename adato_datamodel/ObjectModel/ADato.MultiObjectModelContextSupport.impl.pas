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
  ADato.ObjectModel.List.Tracking.impl, 
  ADato.InsertPosition;

type
  TEditableObjectModelContext = class(TObjectModelContext, IEditableListObject, IEditState)
  {$IFDEF DELPHI}protected{$ELSE}public{$ENDIF}
    _IsChanged: Boolean;
    _IsNew: Boolean;
    _Index: Integer;
    _Position: InsertPosition;
    _SavedContext: CObject;
    [weak]_Owner: IObjectListModel;

    function  get_IsChanged: Boolean;
    function  get_IsEdit: Boolean;
    function  get_IsNew: Boolean;
    function  get_IsEditOrNew: Boolean;

    procedure AddNew(const item: CObject; Index: Integer; Position: InsertPosition);
    procedure BeginEdit(Index: Integer);
    procedure CancelEdit;
    procedure EndEdit;
    procedure StartChange;

    function  DoContextChanging: Boolean; override;
    procedure UpdatePropertyBindingValues; override;
    procedure UpdatePropertyBindingValues(const APropertyName: CString); override;
    procedure UpdateValueFromBoundProperty(const ABinding: IPropertyBinding; const Value: CObject; ExecuteTriggers: Boolean); override;
    procedure UpdateValueFromBoundProperty(const APropertyName: CString; const Value: CObject; ExecuteTriggers: Boolean); override;

  public
    constructor Create(const AModel: IObjectModel; const AOwner: IObjectListModel); reintroduce; overload;
//    constructor Create(const Other: IObjectModelContext; const AOwner: IObjectListModelChangeTracking); overload;
  end;

  TMultiEditableObjectModelContext = class(TEditableObjectModelContext, IMultiObjectContextSupport)
  protected
    _contexts: Dictionary<CObject, IObjectModelContext>;
    _onListItemChanged: IListItemChanged;

    function  get_StoredContexts: Dictionary<CObject, IObjectModelContext>;
    procedure OnContextChanged(const Sender: IObjectListModel; const Context: IList);

  public
    constructor Create(const AModel: IObjectModel; const AOwner: IObjectListModel); reintroduce; overload;
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

{ TEditableObjectModelContext }
constructor TEditableObjectModelContext.Create(const AModel: IObjectModel; const AOwner: IObjectListModel);
begin
  inherited Create(AModel);
  _Owner := AOwner;
end;

procedure TEditableObjectModelContext.AddNew(const Item: CObject; Index: Integer; Position: InsertPosition);
begin
  // Added by JvA 25-11-2021
  if get_IsEditOrNew then
    EndEdit;

  _IsChanged := False;
  _IsNew := True;
  _Index := Index;

  inherited set_Context(item);

  var notify: INotifyListItemChanged;
  if interfaces.Supports<INotifyListItemChanged>(_Owner, notify) then
    notify.NotifyAddingNew(Self, {var} _Index, Position);

  var cln: ICloneable;
  if _Context.TryGetValue<ICloneable>(cln) then
    _SavedContext := cln.Clone else
    _SavedContext := Item;
end;

procedure TEditableObjectModelContext.BeginEdit(Index: Integer);
var
  eo: IEditableObject;
  cln: ICloneable;
begin
//  Assert((Self as IObjectModelContext) = Owner.ObjectModelContext);

  _IsChanged := False;
  _IsNew := False;
  _Index := Index;

  _SavedContext := _Context;

  if _Context.TryGetValue<ICloneable>(cln) then
  begin
    BeginUpdate;
    try
      inherited set_Context(cln.Clone);
    finally
      EndUpdate;
    end;
  end;

  if _Context.TryGetValue<IEditableObject>(eo) then
    eo.BeginEdit;

  var notify: INotifyListItemChanged;
  if interfaces.Supports<INotifyListItemChanged>(_Owner, notify) then
    notify.NotifyBeginEdit(Self);
end;

procedure TEditableObjectModelContext.CancelEdit;
var
  eo: IEditableObject;
begin
  if get_IsEditOrNew then
  begin
    if _Context.TryGetValue<IEditableObject>(eo) then
      eo.CancelEdit;

    var notify: INotifyListItemChanged;
    if (_UpdateCount = 0) and interfaces.Supports<INotifyListItemChanged>(_Owner, notify) then
      notify.NotifyCancelEdit(Self, _SavedContext);

    // in case of clone, set old item back
    BeginUpdate;
    try
      inherited set_Context(_SavedContext);
    finally
      EndUpdate;
    end;

    _SavedContext := nil;
    _IsChanged := False;
  end;
end;

procedure TEditableObjectModelContext.EndEdit;
var
  eo: IEditableObject;
begin
  if get_IsEditOrNew then
  begin
    if _Context.TryGetValue<IEditableObject>(eo) then
      eo.EndEdit;

    var notify: INotifyListItemChanged;
    if (_UpdateCount = 0) and interfaces.Supports<INotifyListItemChanged>(_Owner, notify) then
      notify.NotifyEndEdit(Self, _SavedContext, _Index, _Position);

    _SavedContext := nil;
    _IsChanged := False;
  end;
end;

function TEditableObjectModelContext.get_IsChanged: Boolean;
begin
  Result := _IsChanged;
end;

function TEditableObjectModelContext.get_IsEdit: Boolean;
begin
  Result := (_savedContext <> nil) and not _IsNew;
end;

function TEditableObjectModelContext.get_IsNew: Boolean;
begin
  Result := (_savedContext <> nil) and _IsNew;
end;

function TEditableObjectModelContext.get_IsEditOrNew: Boolean;
begin
  Result := _savedContext <> nil;
end;

function TEditableObjectModelContext.DoContextChanging : Boolean;
begin
  Result := inherited;
  if Result and (_UpdateCount = 0) then
    EndEdit;
end;

procedure TEditableObjectModelContext.UpdatePropertyBindingValues;
begin
  // do not execute by creating a clone in BeginEdit
  if (_updateCount = 0) or _IsChanged then
    inherited;
end;

procedure TEditableObjectModelContext.UpdatePropertyBindingValues(const APropertyName: CString);
begin
  // do not execute by creating a clone in BeginEdit
  if (_updateCount = 0) or _IsChanged then
    inherited;
end;

procedure TEditableObjectModelContext.UpdateValueFromBoundProperty(const ABinding: IPropertyBinding; const Value: CObject; ExecuteTriggers: Boolean);
begin
  StartChange;
  inherited;
end;

procedure TEditableObjectModelContext.UpdateValueFromBoundProperty(const APropertyName: CString; const Value: CObject; ExecuteTriggers: Boolean);
begin
  StartChange;
  inherited;
end;

procedure TEditableObjectModelContext.StartChange;
begin
  if not get_IsEditOrNew then
    BeginEdit(-1);

  _IsChanged := True;
end;

{ TMultiEditableObjectModelContext }

constructor TMultiEditableObjectModelContext.Create(const AModel: IObjectModel; const AOwner: IObjectListModel);
begin
  inherited;

  _contexts := CDictionary<CObject, IObjectModelContext>.Create;

  var support: IOnItemChangedSupport;
  if interfaces.Supports<IOnItemChangedSupport>(_Owner, support) then
  begin
    _onListItemChanged := TOnListItemChanged.Create(_Owner, Self);
    support.OnItemChanged.Add(_onListItemChanged);
  end;

  _Owner.OnContextChanged.Add(OnContextChanged);
end;

function TMultiEditableObjectModelContext.ProvideObjectModelContext(const DataItem: CObject): IObjectModelContext;
begin
  Result := FindObjectModelContext(DataItem);

  if Result = nil then
  begin
    // keep object reference in memory, so we can search back for it and keep track of changes
    var omc := _Owner.ObjectModelContext;
    Result := TStorageObjectModelContext.Create(omc);
    Result.Context := DataItem;

    _Contexts.Add(DataItem, Result);
  end;
end;

destructor TMultiEditableObjectModelContext.Destroy;
begin
  if (_Owner <> nil) then
  begin
    _Owner.OnContextChanged.Remove(OnContextChanged);

    var support: IOnItemChangedSupport;
    if interfaces.Supports<IOnItemChangedSupport>(_Owner, support) then
      support.OnItemChanged.Remove(_onListItemChanged);
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
