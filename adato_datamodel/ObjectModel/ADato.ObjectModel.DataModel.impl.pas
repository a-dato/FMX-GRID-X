{$I ADato.inc}

unit ADato.ObjectModel.DataModel.impl;

interface

uses
  System_,
  ADato.ObjectModel.intf,
  ADato.ObjectModel.List.intf,
  System.Collections,
  System.Collections.Generic,
  ADato.Data.DataModel.intf,
  ADato.ObjectModel.TrackInterfaces,
  ADato.ObjectModel.impl;

type
  TDataModelObjectListModel = class(TBaseInterfacedObject,
    IObjectListModel,
    IOnItemChangedSupport)
  protected
    _dataModel: IDataModel;

    _OnContextChanging: ListContextChangingEventHandler;
    _OnContextChanged: ListContextChangedEventHandler;
    _ObjectModel: IObjectModel;
    _ObjectModelContext: IObjectModelContext;

    _DoMultiContextSupport: Boolean;

    // IOnItemChangedSupport
    _OnItemChanged: IList<IListItemChanged>;

    // DATAMODLE
    procedure OnRowChanged(const Sender: IBaseInterface; Args: RowChangedEventArgs);

    // TObjectModel
    function  CreateObjectModel : IObjectModel; virtual;
    function  CreateObjectModelContext : IObjectModelContext; virtual;
    procedure ResetModelProperties;

    function  ListHoldsObjectType: Boolean; virtual;

    // IObjectListModel
    function  get_Context: IList; virtual;
    procedure set_Context(const Value: IList); virtual;
    function  get_ObjectContext: CObject; virtual;
    procedure set_ObjectContext(const Value: CObject); virtual;
    function  get_OnContextChanging: ListContextChangingEventHandler;
    function  get_OnContextChanged: ListContextChangedEventHandler;
    function  get_ObjectModel: IObjectModel;
    procedure set_ObjectModel(const Value: IObjectModel);
    function  get_ObjectModelContext: IObjectModelContext;

    function  get_MultiSelectionContext: List<CObject>;
    procedure set_MultiSelectionContext(const Value: List<CObject>);

    // IOnItemChangedSupport
    function get_OnItemChanged: IList<IListItemChanged>;
  public
    constructor Create(DoMultiContextSupport: Boolean);
  end;

  TDataModelObjectModel = {$IFDEF DOTNET}public{$ENDIF} class(TBaseInterfacedObject, IObjectModel)
  protected
    _dataModelType: &Type;
    _dataModel: IDataModel;

    function  GetType: &Type; {$IFDEF DELPHI}override;{$ENDIF}
    function  CreateObjectModelContext : IObjectModelContext;
    function  CreateInstance(const AObjectType: &Type): IObjectModel; virtual;
  public
    constructor Create(const DataModel: IDataModel); virtual;

    procedure ResetModelProperties; virtual;
  end;

  TDataModelPropertyForObjectModel = class(CPropertyInfo)
  protected
    _name: CString;

    function  get_Name: CString; override;
    function  get_CanRead: Boolean; override;
    function  get_CanWrite: Boolean; override;

    function GetObjectProperty(const obj: CObject): _PropertyInfo;
  public
    constructor Create(const Name: CString; const AType: &Type);

    function  GetValue(const obj: CObject; const index: array of CObject): CObject; override;
    procedure SetValue(const obj: CObject; const value: CObject; const index: array of CObject; ExecuteTriggers: Boolean = false); override;
  end;

implementation

uses
  ADato.MultiObjectModelContextSupport.impl, System.JSON, ADato.JSON;

{ TObjectListModel }

constructor TDataModelObjectListModel.Create(DoMultiContextSupport: Boolean);
begin
  inherited Create;

  {$IFDEF DELPHI}
  _OnContextChanging := ListContextChangingEventDelegate.Create;
  _OnContextChanged := ListContextChangedEventDelegate.Create;
  {$ENDIF}

  _DoMultiContextSupport := DoMultiContextSupport;
end;

function TDataModelObjectListModel.CreateObjectModel: IObjectModel;
begin
  Result := TDataModelObjectModel.Create(_dataModel);
end;

function TDataModelObjectListModel.CreateObjectModelContext: IObjectModelContext;
begin
  if _DoMultiContextSupport then
    Result := TMultiEditableObjectModelContext.Create(get_ObjectModel, Self) else
    Result := TEditableObjectModelContext.Create(get_ObjectModel, Self);
end;

function TDataModelObjectListModel.get_Context: IList;
begin
  Result := _datamodel as IList;
end;

function TDataModelObjectListModel.get_MultiSelectionContext: List<CObject>;
begin

end;

function TDataModelObjectListModel.get_ObjectContext: CObject;
begin
  Result := get_ObjectModelContext.Context;
end;

function TDataModelObjectListModel.get_ObjectModel: IObjectModel;
begin
  if (_ObjectModel = nil) then
    _ObjectModel := CreateObjectModel;

  Result := _ObjectModel;
end;

function TDataModelObjectListModel.get_ObjectModelContext: IObjectModelContext;
begin
  if _ObjectModelContext = nil then
    _ObjectModelContext := CreateObjectModelContext;

  Result := _ObjectModelContext;
end;

function TDataModelObjectListModel.get_OnContextChanged: ListContextChangedEventHandler;
begin
  Result := _OnContextChanged;
end;

function TDataModelObjectListModel.get_OnContextChanging: ListContextChangingEventHandler;
begin
  Result := _OnContextChanging;
end;

function TDataModelObjectListModel.ListHoldsObjectType: Boolean;
begin
  Result := False;
end;

procedure TDataModelObjectListModel.OnRowChanged(const Sender: IBaseInterface; Args: RowChangedEventArgs);
begin
//  if Args.NewIndex = -1 then Exit; don't know if this can happen??
  var new := _dataModel.DefaultView.Rows[Args.NewIndex];
  set_ObjectContext(new.Row.Data);
end;

procedure TDataModelObjectListModel.ResetModelProperties;
begin
  _ObjectModel.ResetModelProperties;
end;

procedure TDataModelObjectListModel.set_Context(const Value: IList);
begin
  {$IFDEF WINDOWS}
  Assert(GetCurrentThreadID = MainThreadID);
  {$ENDIF}

  if _OnContextChanging <> nil then
  begin
    var allow := True;
    _OnContextChanging.Invoke(Self, get_Context, allow);
    if not allow then Exit;
  end;

  if _dataModel <> nil then
  begin
    _dataModel.DefaultCurrencyManager.CurrentRowChanged.Remove(OnRowChanged);

    _ObjectModel := nil;
    _ObjectModelContext := nil;
    set_ObjectContext(nil);
  end;

  _dataModel := Value as IDataModel;

  if _dataModel <> nil then
    _dataModel.DefaultCurrencyManager.CurrentRowChanged.Add(OnRowChanged);

  if _OnContextChanged <> nil then
 		_OnContextChanged.Invoke(Self, get_Context);
end;

procedure TDataModelObjectListModel.set_MultiSelectionContext(
  const Value: List<CObject>);
begin

end;

procedure TDataModelObjectListModel.set_ObjectContext(const Value: CObject);
begin
  get_ObjectModelContext.Context := Value;
end;

procedure TDataModelObjectListModel.set_ObjectModel(const Value: IObjectModel);
begin
  _ObjectModel := Value;
end;

function TDataModelObjectListModel.get_OnItemChanged: IList<IListItemChanged>;
begin
  if _OnItemChanged = nil then
    _OnItemChanged := CList<IListItemChanged>.Create;

  Result := _OnItemChanged;
end;

{ TDataModelObjectModel }

constructor TDataModelObjectModel.Create(const DataModel: IDataModel);
begin
  _dataModel := DataModel;
end;

function TDataModelObjectModel.CreateInstance(const AObjectType: &Type): IObjectModel;
begin

end;

function TDataModelObjectModel.CreateObjectModelContext: IObjectModelContext;
begin
  raise NotImplementedException.Create;
end;

function TDataModelObjectModel.GetType: &Type;
begin
  if not Assigned(_dataModelType.GetPropertiesExternal) and (_dataModel <> nil) then
  begin
    _dataModelType := Global.GetTypeOf<TJsonValue>;
    _dataModelType.GetPropertiesExternal :=
      function : PropertyInfoArray begin
        SetLength(Result, _dataModel.Columns.Count);
        var i := 0;
        for var clmn in _dataModel.Columns do
        begin
          var prop: _PropertyInfo := TDataModelPropertyForObjectModel.Create(clmn.Name, clmn.DataType);
          Result[i] := TObjectModelPropertyWrapper.Create(prop);
          inc(i);
        end;
      end;
  end;

  Result := _dataModelType;
end;

procedure TDataModelObjectModel.ResetModelProperties;
begin
  _dataModelType.GetPropertiesExternal := nil;
end;

{ TDataModelPropertyForObjectModel }

constructor TDataModelPropertyForObjectModel.Create(const Name: CString; const AType: &Type);
begin
  inherited Create;
  _name := Name;
  _Type := AType;
end;

function TDataModelPropertyForObjectModel.GetObjectProperty(const obj: CObject): _PropertyInfo;
begin
  Result := obj.GetType.PropertyByName(_name);
end;

function TDataModelPropertyForObjectModel.get_CanRead: Boolean;
begin
  Result := True; // check CanRead will be done in function GetValue
end;

function TDataModelPropertyForObjectModel.get_CanWrite: Boolean;
begin
  Result := True; // check CaanWrite will be done in function SetValue
end;

function TDataModelPropertyForObjectModel.get_Name: CString;
begin
  Result := _name;
end;

function TDataModelPropertyForObjectModel.GetValue(const obj: CObject; const index: array of CObject): CObject;
begin
  var prop := GetObjectProperty(obj);
  if (prop <> nil) and prop.CanWrite then
    Result := prop.GetValue(obj, index) else
    Result := nil;
end;

procedure TDataModelPropertyForObjectModel.SetValue(const obj, value: CObject; const index: array of CObject; ExecuteTriggers: Boolean);
begin
  var prop := GetObjectProperty(obj);
  if (prop <> nil) and prop.CanWrite then
    prop.SetValue(obj, value, index, ExecuteTriggers);
end;

end.
