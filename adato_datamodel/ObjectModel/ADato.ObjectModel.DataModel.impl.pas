unit ADato.ObjectModel.DataModel.impl;

interface

uses
  System_,
  ADato.ObjectModel.intf,
  ADato.ObjectModel.List.intf,
  System.Collections,
  System.Collections.Generic,
  ADato.Data.DataModel.intf;

type
  TDataModelObjectListModel = class(TBaseInterfacedObject, IObjectListModel)
  protected
    _dataModel: IDataModel;

    _OnContextChanging: ListContextChangingEventHandler;
    _OnContextChanged: ListContextChangedEventHandler;
    _ObjectModel: IObjectModel;
    _ObjectModelContext: IObjectModelContext;

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
    procedure set_ObjectModelContext(const Value: IObjectModelContext);

    function  get_MultiSelectionContext: List<CObject>;
    procedure set_MultiSelectionContext(const Value: List<CObject>);

  public
    constructor Create(const DataModel: IDataModel);
  end;

//  TDataModelListImplentation = class(TVirtualListBase)
//  end;

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

implementation

{ TObjectListModel }

constructor TDataModelObjectListModel.Create(const DataModel: IDataModel);
begin
  _dataModel := DataModel;
end;

function TDataModelObjectListModel.CreateObjectModel: IObjectModel;
begin
  Result := TDataModelObjectModel.Create(_dataModel);
end;

function TDataModelObjectListModel.CreateObjectModelContext: IObjectModelContext;
begin

end;

function TDataModelObjectListModel.get_Context: IList;
begin

end;

function TDataModelObjectListModel.get_MultiSelectionContext: List<CObject>;
begin

end;

function TDataModelObjectListModel.get_ObjectContext: CObject;
begin

end;

function TDataModelObjectListModel.get_ObjectModel: IObjectModel;
begin

end;

function TDataModelObjectListModel.get_ObjectModelContext: IObjectModelContext;
begin

end;

function TDataModelObjectListModel.get_OnContextChanged: ListContextChangedEventHandler;
begin

end;

function TDataModelObjectListModel.get_OnContextChanging: ListContextChangingEventHandler;
begin

end;

function TDataModelObjectListModel.ListHoldsObjectType: Boolean;
begin

end;

procedure TDataModelObjectListModel.ResetModelProperties;
begin

end;

procedure TDataModelObjectListModel.set_Context(const Value: IList);
begin

end;

procedure TDataModelObjectListModel.set_MultiSelectionContext(
  const Value: List<CObject>);
begin

end;

procedure TDataModelObjectListModel.set_ObjectContext(const Value: CObject);
begin

end;

procedure TDataModelObjectListModel.set_ObjectModel(const Value: IObjectModel);
begin

end;

procedure TDataModelObjectListModel.set_ObjectModelContext(
  const Value: IObjectModelContext);
begin

end;

{ TDataModelObjectModel }

constructor TDataModelObjectModel.Create(const DataModel: IDataModel);
begin

end;

function TDataModelObjectModel.CreateInstance(const AObjectType: &Type): IObjectModel;
begin

end;

function TDataModelObjectModel.CreateObjectModelContext: IObjectModelContext;
begin

end;

function TDataModelObjectModel.GetType: &Type;
begin

end;

procedure TDataModelObjectModel.ResetModelProperties;
begin

end;

end.
