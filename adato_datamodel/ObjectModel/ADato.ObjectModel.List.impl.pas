{$I Adato.inc}
unit ADato.ObjectModel.List.impl;

interface

uses
  {$IFDEF DELPHI}
  System.TypInfo, 
  System.SysUtils,
  System.Classes,
  {$ENDIF}
  System_,
  ADato.ObjectModel.List.intf,
  System.Collections.Generic,
  System.Collections,
  ADato.ObjectModel.intf,
  ADato.ObjectModel.impl,
  System.ComponentModel, 
  ADato.Sortable.Intf;

type
  TObjectListModel<T> = class(TBaseInterfacedObject, IObjectListModel)
  protected
    _ObjectType: &Type;
    _OnContextChanging: ListContextChangingEventHandler;
    _OnContextChanged: ListContextChangedEventHandler;
    _Context: IList;
    _ObjectModel: IObjectModel;

    _ObjectModelContext: IObjectModelContext;
//    _ObjectModelContextSupport: IObjectModelContextSupport;
    _MultiSelectionContext: List<CObject>;

    function  CreateObjectModel : IObjectModel; virtual;
    function  CreateObjectModelContext : IObjectModelContext; virtual;
    procedure ResetModelProperties;

    {$IFDEF DOTNET}
    function  GetTypeEx: &Type;
    event OnContextChanging: ListContextChangingEventHandler delegate _OnContextChanging;
    event OnContextChanged: ListContextChangedEventHandler delegate _OnContextChanged;
    {$ENDIF}
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

//    function  get_ObjectModelContextSupport: IObjectModelContextSupport;
    function  get_ObjectModelContext: IObjectModelContext;
//    procedure set_ObjectModelContext(const Value: IObjectModelContext);
    function  get_MultiSelectionContext: List<CObject>;
    procedure set_MultiSelectionContext(const Value: List<CObject>);

    // IObjectListModel<T>
//    function  get_Context_T: IList<T>;
//    procedure set_Context_T(const Value: IList<T>);

  public
    constructor Create;
  end;

  TSingleObjectContextSupport = class(TBaseInterfacedObject, IObjectModelContextSupport)
  private
    _objectModelContext: IObjectModelContext;

    function  get_ObjectModelContext: IObjectModelContext;
    procedure set_ObjectModelContext(const Value: IObjectModelContext);

  public
    property ObjectModelContext: IObjectModelContext read get_ObjectModelContext write set_ObjectModelContext;
  end;

implementation

uses
  {$IFDEF WINDOWS}
  Winapi.Windows,
  {$ENDIF}
  ADato.ListComparer.Impl;

{ TObjectListModel<T> }

constructor TObjectListModel<T>.Create;
begin
  _ObjectType := Global.GetTypeOf<T>;
  {$IFDEF DELPHI}
  _OnContextChanging := ListContextChangingEventDelegate.Create;
  _OnContextChanged := ListContextChangedEventDelegate.Create;
  {$ENDIF}
end;

function TObjectListModel<T>.CreateObjectModel: IObjectModel;
begin
  if ListHoldsObjectType then
    Result := TObjectModel.Create(_ObjectType) else
    Result := TOrdinalTypeObjectModel.Create(_ObjectType);
end;

function TObjectListModel<T>.CreateObjectModelContext: IObjectModelContext;
begin
  Result := get_ObjectModel.CreateObjectModelContext;
end;

procedure TObjectListModel<T>.ResetModelProperties;
begin
  if _ObjectModel <> nil then
    _ObjectModel.ResetModelProperties;
end;

function TObjectListModel<T>.get_Context: IList;
begin
  Result := _Context;
end;

// IObjectListModel<T>
//function TObjectListModel<T>.get_Context_T: IList<T>;
//begin
//  Result := get_Context as IList<T>;
//end;

function TObjectListModel<T>.get_ObjectContext: CObject;
begin
  Result := get_ObjectModelContext.Context;
end;

function TObjectListModel<T>.get_ObjectModel: IObjectModel;
begin
  if (_ObjectModel = nil) then
    _ObjectModel := CreateObjectModel;

  Result := _ObjectModel;
end;

function TObjectListModel<T>.get_OnContextChanging: ListContextChangingEventHandler;
begin
  Result := _OnContextChanging;
end;

function TObjectListModel<T>.get_OnContextChanged: ListContextChangedEventHandler;
begin
  Result := _OnContextChanged;
end;

function TObjectListModel<T>.ListHoldsObjectType: Boolean;
begin
  Result := _ObjectType.IsInterfaceType or _ObjectType.IsObjectType;
end;

procedure TObjectListModel<T>.set_Context(const Value: IList);
begin
  {$IFDEF WINDOWS}
  Assert(GetCurrentThreadID = MainThreadID);
  {$ENDIF}

  if _OnContextChanging <> nil then
  begin
    var allow := True;
    _OnContextChanging.Invoke(Self, _Context, allow);
    if not allow then Exit;
  end;

  set_ObjectContext(nil);
  _Context := Value;

  if _OnContextChanged <> nil then
 		_OnContextChanged.Invoke(Self, get_Context);
end;

//procedure TObjectListModel<T>.set_Context_T(const Value: IList<T>);
//begin
//  set_Context(Value as IList);
//end;

procedure TObjectListModel<T>.set_ObjectContext(const Value: CObject);
begin
  get_ObjectModelContext.Context := Value;
end;

procedure TObjectListModel<T>.set_ObjectModel(const Value: IObjectModel);
begin
  _ObjectModel := Value;
end;

//function TObjectListModel<T>.get_ObjectModelContextSupport: IObjectModelContextSupport;
//begin
//  if _ObjectModelContextSupport = nil then
//    _ObjectModelContextSupport := TSingleObjectContextSupport.Create;
//
//  Result := _ObjectModelContextSupport;
//end;

function TObjectListModel<T>.get_ObjectModelContext: IObjectModelContext;
begin
  if _ObjectModelContext = nil then
    _ObjectModelContext := CreateObjectModelContext;

  Result := _ObjectModelContext;
end;

//procedure TObjectListModel<T>.set_ObjectModelContext(const Value: IObjectModelContext);
//begin
//  _ObjectModelContextSupport.ObjectModelContext := Value;
//end;

function TObjectListModel<T>.get_MultiSelectionContext: List<CObject>;
begin
  Result := _MultiSelectionContext;
end;

procedure TObjectListModel<T>.set_MultiSelectionContext(const Value: List<CObject>);
begin
  _MultiSelectionContext := Value;
end;

{$IFDEF DOTNET}
function  TObjectListModel<T>.GetTypeEx: &Type;
begin
  Result := _ObjectType;
end;
{$ENDIF}

{ TSingleObjectContextSupport }

function TSingleObjectContextSupport.get_ObjectModelContext: IObjectModelContext;
begin
  Result := _objectModelContext;
end;

procedure TSingleObjectContextSupport.set_ObjectModelContext(const Value: IObjectModelContext);
begin
  _objectModelContext := Value;
end;

end.
