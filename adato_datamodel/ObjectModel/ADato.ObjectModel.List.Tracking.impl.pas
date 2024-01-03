{$I Jedi.inc}
unit ADato.ObjectModel.List.Tracking.impl;

interface

uses
  {$IFDEF DELPHI}
  System.SysUtils,
  {$ENDIF}
  System_, 
  System.Collections.Generic,
  System.ComponentModel,
  ADato.ObjectModel.intf,
  ADato.ObjectModel.List.intf,
  ADato.ObjectModel.List.Tracking.intf,
  ADato.ObjectModel.impl, System.Collections,
  ADato.ObjectModel.List.ContextStorage.impl,
  ADato.InsertPosition,
  ADato.Models.ContextUpdater.intf;

type
  IChangedItem = record
  public
    Item: CObject;
    ChangeType: TObjectListChangeType;
  end;

  TObjectListModelWithChangeTracking<T> = {$IFDEF DOTNET}public{$ENDIF} class(
    TObjectListModelContextStorage<T>,
    IObjectListModelChangeTracking,
    IAddingNew,
    IEditState,
    IEditableModel)

  protected
    _CreatorFunc  : TFunc<T>;
    _ChangedItems : Dictionary<CObject, TObjectListChangeType>;   // List
    _orignalContext: IList;
    _EditContext  : IObjectModelContext;
    _OnAskForApply: AskForApplyEventHandler;
    _contextUpdater: IObjectModelContextUpdater;
    _OnItemChanged: IList<IListItemChanged>;
    _UpdateCount  : Integer;
    _StoreChangedItems: Boolean;

    procedure BeginUpdate;
    procedure EndUpdate;
    function  CreateObjectModelContext : IObjectModelContext; override;
    procedure UpdateEditContext(const Context: IObjectModelContext; Cancel: Boolean = False);
    procedure UpdateStoredContext;

    procedure NotifyAddingNew(const Context: IObjectModelContext; var Index: Integer; Position: InsertPosition);
//    procedure NotifyAdded(const Item: CObject; const Index: Integer);
    procedure NotifyRemoved(const Item: CObject; const Index: Integer);
    procedure NotifyBeginEdit(const Context: IObjectModelContext); virtual;
    procedure NotifyCancelEdit(const Context: IObjectModelContext; const OriginalObject: CObject);
    procedure NotifyEndEdit(const Context: IObjectModelContext; const OriginalObject: CObject; Index: Integer; Position: InsertPosition); virtual;

    procedure set_StoreChangedItems(const Value: Boolean);
    procedure UpdateChangedItem(const Obj: CObject; ChangeType: TObjectListChangeType);

    // IEditState
    function  get_IsChanged: Boolean;
    function  get_IsEdit: Boolean;
    function  get_IsNew: Boolean;
    function  get_IsEditOrNew: Boolean;

    // IEditableModel
    procedure AddNew(Index: Integer; Position: InsertPosition);
    procedure BeginEdit(Index: Integer);
    procedure CancelEdit;
    procedure EndEdit; virtual;
    procedure Remove; overload;
    procedure Remove(Item: CObject); overload;

    function CanAdd : Boolean;
    function CanEdit : Boolean;
    function CanRemove : Boolean;

    // IObjectListModelChangeTracking
    function  get_HasChangedItems: Boolean;
    function  get_ChangedItems: Dictionary<CObject, TObjectListChangeType>;
    function  get_OnItemChanged: IList<IListItemChanged>;

    function  RetrieveUpdatedItems: Dictionary<CObject, TObjectListChangeType>;

    procedure set_Context(const Value: IList); override;
    procedure set_ObjectContext(const Value: CObject); override;
    {$IFDEF DELPHI}
    function  get_OnAskForApply: AskForApplyEventHandler;
    {$ENDIF}

    // IAddNewSupport
    function CreateInstance: CObject;
  public
    constructor Create; overload; override;
    constructor Create(const ContextUpdater: IObjectModelContextUpdater); overload;
    constructor Create(const ContextUpdater: IObjectModelContextUpdater; const CreatorFunc: TFunc<T> = nil); overload;

    {$IFDEF DEBUG_XX}
    destructor Destroy; override;
    {$ENDIF}

    property StoreChangedItems: Boolean write set_StoreChangedItems;

    {$IFDEF DELPHI}
    property OnAskForApply: AskForApplyEventHandler read get_OnAskForApply;
    {$ELSE}
    event OnAskForApply: AskForApplyEventHandler;
    {$ENDIF}
  end;

  TEditableObjectModelContext = class(TObjectModelContext, IEditableListObject, IEditState)
  {$IFDEF DELPHI}protected{$ELSE}public{$ENDIF}
    _IsChanged: Boolean;
    _IsNew: Boolean;
    _Index: Integer;
    _Position: InsertPosition;
    _SavedContext: CObject;
    [weak]Owner: IObjectListModelChangeTracking;

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
    constructor Create(const AModel: IObjectModel; const AOwner: IObjectListModelChangeTracking); reintroduce; overload;
//    constructor Create(const Other: IObjectModelContext; const AOwner: IObjectListModelChangeTracking); overload;
  end;

implementation

uses
  {$IFDEF DELPHI}
  System.Classes,
  System.TypInfo,
  {$ENDIF}
  ADato.Data.DataModel.intf,
  ADato.TraceEvents.intf;

{ TObjectListModel<T> }

procedure TObjectListModelWithChangeTracking<T>.AddNew(Index: Integer; Position: InsertPosition);
begin
  BeginUpdate;
  try
    var item := CreateInstance;
    if item <> nil then
    begin
      var e: IEditableListObject;
      if Interfaces.Supports<IEditableListObject>(get_ObjectModelContext, e) then
        e.AddNew(item, Index, Position);
    end;
  finally
    EndUpdate;
  end;
end;

procedure TObjectListModelWithChangeTracking<T>.BeginEdit(Index: Integer);
begin
  var e: IEditableListObject;
  if Interfaces.Supports<IEditableListObject>(get_ObjectModelContext, e) then
    e.BeginEdit(Index);
end;

procedure TObjectListModelWithChangeTracking<T>.BeginUpdate;
begin
  inc(_UpdateCount);
end;

function TObjectListModelWithChangeTracking<T>.CanAdd: Boolean;
begin
  Result := ((_Context <> nil) {or (_dataModel <> nil)}) and Assigned(_CreatorFunc);
end;

procedure TObjectListModelWithChangeTracking<T>.CancelEdit;
begin
  UpdateEditContext(nil, True);
end;

function TObjectListModelWithChangeTracking<T>.CanEdit: Boolean;
begin
  Result := True;
end;

function TObjectListModelWithChangeTracking<T>.CanRemove: Boolean;
begin
  Result := (_Context <> nil) and (_Context.Count > 0);
end;

constructor TObjectListModelWithChangeTracking<T>.Create;
begin
  inherited Create;

  _StoreChangedItems := True;
  _ChangedItems := CDictionary<CObject, TObjectListChangeType>.Create;

  {$IFDEF DELPHI}
  _OnAskForApply := AskForApplyEventDelegate.Create;
  {$ENDIF}
end;


constructor TObjectListModelWithChangeTracking<T>.Create(const ContextUpdater: IObjectModelContextUpdater);
begin
  Create;

  _contextUpdater := ContextUpdater;
  _contextUpdater.Model := Self;
end;

constructor TObjectListModelWithChangeTracking<T>.Create(const ContextUpdater: IObjectModelContextUpdater; const CreatorFunc: TFunc<T>);
begin
  Create(ContextUpdater);
  _CreatorFunc := CreatorFunc;
end;

{$IFDEF DEBUG_XX}
destructor TObjectListModelWithChangeTracking<T>.Destroy;
begin
  _OnItemChanged.Clear;
  inherited Destroy;
end;
{$ENDIF}

function TObjectListModelWithChangeTracking<T>.CreateObjectModelContext : IObjectModelContext;
begin
  if ListHoldsObjectType then
    Result := TEditableObjectModelContext.Create(get_ObjectModel, Self) else
    Result := inherited;
end;

function TObjectListModelWithChangeTracking<T>.get_HasChangedItems: Boolean;
begin
  Result := _ChangedItems.Count > 0;
end;

function TObjectListModelWithChangeTracking<T>.get_ChangedItems: Dictionary<CObject, TObjectListChangeType>;
begin
  Result := _ChangedItems;
end;

function TObjectListModelWithChangeTracking<T>.get_IsChanged: Boolean;
begin
  var e: IEditState;
  Result := Interfaces.Supports<IEditState>(_EditContext, e) and e.IsChanged;
end;

function TObjectListModelWithChangeTracking<T>.get_IsEdit: Boolean;
begin
  var e: IEditState;
  Result := Interfaces.Supports<IEditState>(_EditContext, e) and e.IsEdit;
end;

function TObjectListModelWithChangeTracking<T>.get_IsEditOrNew: Boolean;
begin
  var e: IEditState;
  Result := Interfaces.Supports<IEditState>(_EditContext, e) and e.IsEditOrNew;
end;

function TObjectListModelWithChangeTracking<T>.get_IsNew: Boolean;
begin
  var e: IEditState;
  Result := Interfaces.Supports<IEditState>(_EditContext, e) and e.IsNew;
end;

{$IFDEF DELPHI}
function TObjectListModelWithChangeTracking<T>.get_OnAskForApply: AskForApplyEventHandler;
begin
  Result := _OnAskForApply;
end;
{$ENDIF}

function TObjectListModelWithChangeTracking<T>.get_OnItemChanged: IList<IListItemChanged>;
begin
  if _OnItemChanged = nil then
    _OnItemChanged := CList<IListItemChanged>.Create;

  Result := _OnItemChanged;
end;

function TObjectListModelWithChangeTracking<T>.RetrieveUpdatedItems: Dictionary<CObject, TObjectListChangeType>;
begin
  Result := _contextUpdater.RetrieveUpdatedItems;
end;

procedure TObjectListModelWithChangeTracking<T>.UpdateEditContext(const Context: IObjectModelContext; Cancel: Boolean);
var
  ctxt: IObjectModelContext;
begin
  ctxt := Context;
  if _EditContext <> nil then
  begin
    BeginUpdate;
    try
      var e: IEditableListObject;
      if Interfaces.Supports<IEditableListObject>(_EditContext, e) then
      begin
        if Cancel then
        begin
//          var oldEditContext := _EditContext;

          e.CancelEdit;
//          var es: IEditState;
//          if Interfaces.Supports<IEditState>(oldEditContext, es) and es.IsNew then
//            ctxt := oldEditContext; // keep state to _IsNew
        end
        else
        begin
          if Assigned(_OnAskForApply) then
          begin
            var canApply := True;
            _OnAskForApply.Invoke(Self, canApply);
            if not canApply then
              Exit;
          end;

          e.EndEdit;
        end;
      end;
    finally
      EndUpdate;
    end;
  end;

  _EditContext := Context;
end;

procedure TObjectListModelWithChangeTracking<T>.NotifyBeginEdit(const Context: IObjectModelContext);
begin
  UpdateEditContext(Context);
  UpdateStoredContext;

  var dm: IDataModel;
  if interfaces.Supports<IDatamodel>(Self._Context, dm) then
  begin
    var dr := dm.FindByKey(Context.Context);
    if dr <> nil then
      dr.Data := Context.Context;
  end else begin
    var i := _Context.IndexOf(Context.Context);
    if i = -1 then
      raise Exception.Create('NotifyBeginEdit, item could not be located');

    _Context[i] := Context.Context;
  end;

  if _OnItemChanged <> nil then
  begin
    var n: IListItemChanged;
    for n in _OnItemChanged do
      n.BeginEdit(Context.Context);
  end;
end;

procedure TObjectListModelWithChangeTracking<T>.NotifyCancelEdit(const Context: IObjectModelContext; const OriginalObject: CObject);
begin
  _EditContext := nil;

  var dm: IDataModel;
  if interfaces.Supports<IDatamodel>(Self._Context, dm) then
  begin
    var dr := dm.FindByKey(Context.Context);
    if dr <> nil then
      dr.Data := OriginalObject;
  end else begin
    var i := _Context.IndexOf(Context.Context);
    if i = -1 then
      raise Exception.Create('NotifyCancelEdit, item could not be located');

    _Context[i] := OriginalObject;
  end;

  UpdateStoredContext;

  if _OnItemChanged <> nil then
  begin
    var n :IListItemChanged;
    for n in _OnItemChanged do
      n.CancelEdit(Context.Context);
  end;
end;

procedure TObjectListModelWithChangeTracking<T>.NotifyEndEdit(const Context: IObjectModelContext; const OriginalObject: CObject; Index: Integer; Position: InsertPosition);
var
  item: CObject;
  savableItem: CObject;
begin
  var e: IEditState;
  if not Interfaces.Supports<IEditState>(Context, e) or not e.IsEditOrNew then
    Exit;

  _EditContext := nil;

  item := Context.Context;
  savableItem := _contextUpdater.ConvertToDataItem(item);

  if e.IsEdit then
  begin
    if (_Context <> nil) and not Interfaces.Supports(_Context, IDataModel) then
    begin
      if Index <> -1 then
        _Context[Index] := item

      else begin
        var i := _Context.IndexOf(OriginalObject);
        if i = -1 then
          raise Exception.Create('NotifyEndEdit, item could not be located');
        _Context[i] := item;
      end;
    end;

//      else if _DataModel <> nil then
//      begin
//        // do nothing.
//        // Datamodel already contains correct item
//      end;

    // Do not override initial change (object might have been added)
    UpdateChangedItem(OriginalObject, TObjectListChangeType.Changed);

    if _OnItemChanged <> nil then
    begin
     var n: IListItemChanged;
     for n in _OnItemChanged do
        n.EndEdit(item);
    end;
  end
  else if e.IsNew then
  begin
    UpdateChangedItem(savableItem, TObjectListChangeType.Added);

    if _OnItemChanged <> nil then
    begin
     var n: IListItemChanged;
     for n in _OnItemChanged do
       n.Added(item, Index);
    end;
  end;
end;

procedure TObjectListModelWithChangeTracking<T>.UpdateChangedItem(const Obj: CObject; ChangeType: TObjectListChangeType);
begin
  if not _storeChangedItems then
    Exit;

  // Do not override initial change (object might have been added)
  if not _ChangedItems.ContainsKey(Obj) then
    _ChangedItems.Add(Obj, ChangeType)
  else if ChangeType = TObjectListChangeType.Removed then
  begin
    var ct: TObjectListChangeType;
    if _ChangedItems.TryGetValue(Obj, ct) and (ct = TObjectListChangeType.Added) then
      _ChangedItems.Remove(Obj) else
      _ChangedItems[Obj] := TObjectListChangeType.Removed;
  end;
end;

procedure TObjectListModelWithChangeTracking<T>.UpdateStoredContext;
var
  ctxt: IObjectModelContext;
begin
  if not get_StoredContexts.TryGetValue(get_ObjectContext, ctxt) then
    Exit;

  (ctxt as IUpdatableObject).BeginUpdate;
  try
    ctxt.Context := get_ObjectContext; // overwrite with clone / original object
  finally
    (ctxt as IUpdatableObject).EndUpdate;
  end;
end;

function TObjectListModelWithChangeTracking<T>.CreateInstance: CObject;
begin
  {$IFDEF DELPHI}
  if Assigned(_CreatorFunc) then
    Result := CObject.From<T>(_CreatorFunc);
  {$ELSE}
  if Assigned(_CreatorFunc) then
    Result := _CreatorFunc.Invoke;
  {$ENDIF}
end;

procedure TObjectListModelWithChangeTracking<T>.EndEdit;
begin
  UpdateEditContext(nil);
end;

procedure TObjectListModelWithChangeTracking<T>.EndUpdate;
begin
  dec(_UpdateCount);
end;

procedure TObjectListModelWithChangeTracking<T>.NotifyAddingNew(const Context: IObjectModelContext; var Index: Integer; Position: InsertPosition);
begin
  _contextUpdater.DoAddNew(Context.Context, Index, Position);

  UpdateEditContext(Context);

  if _OnItemChanged <> nil then
  begin
    var n: IListItemChanged;
    for n in _OnItemChanged do
      n.AddingNew(Context.Context, {var}Index, Position);
  end;
end;

procedure TObjectListModelWithChangeTracking<T>.NotifyRemoved(const Item: CObject; const Index: Integer);
begin
  UpdateChangedItem(Item, TObjectListChangeType.Removed);

  if _OnItemChanged <> nil then
  begin
    var &notify :IListItemChanged;
    for &notify in _OnItemChanged do
      &notify.Removed(Item, Index);
  end;
end;

procedure TObjectListModelWithChangeTracking<T>.Remove(Item: CObject);
begin
  if Item = nil then Exit;

  UpdateEditContext(nil, True);

  var ix: Integer;
  var newSelected := _contextUpdater.DoRemove(Item, {out} ix);
  NotifyRemoved(Item, ix);

  inherited set_ObjectContext(newSelected);
end;

procedure TObjectListModelWithChangeTracking<T>.Remove;
begin
  Remove(get_ObjectContext);
end;

procedure TObjectListModelWithChangeTracking<T>.set_Context(const Value: IList);
begin
  inherited;
  _ChangedItems.Clear;
end;

procedure TObjectListModelWithChangeTracking<T>.set_ObjectContext(const Value: CObject);
begin
  if not CObject.ReferenceEquals(get_ObjectContext, Value) then
  begin
    UpdateEditContext(nil);
    inherited;
  end;
end;

procedure TObjectListModelWithChangeTracking<T>.set_StoreChangedItems(const Value: Boolean);
begin
  _storeChangedItems := Value;
  if not Value then
    _ChangedItems.Clear;
end;

{ TEditableObjectModelContext }
constructor TEditableObjectModelContext.Create(const AModel: IObjectModel; const AOwner: IObjectListModelChangeTracking);
begin
  inherited Create(AModel);
  Owner := AOwner;
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

  if Owner <> nil then
    Owner.NotifyAddingNew(Self, {var} _Index, Position);

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

  if Owner <> nil then
    Owner.NotifyBeginEdit(Self);
end;

procedure TEditableObjectModelContext.CancelEdit;
var
  eo: IEditableObject;
begin
  if get_IsEditOrNew then
  begin
    if _Context.TryGetValue<IEditableObject>(eo) then
      eo.CancelEdit;

    if (Owner <> nil) and (_UpdateCount = 0) then
      Owner.NotifyCancelEdit(Self, _SavedContext);

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

    if (Owner <> nil) and (_UpdateCount = 0) then
      Owner.NotifyEndEdit(Self, _SavedContext, _Index, _Position);

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

end.
