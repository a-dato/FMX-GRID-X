unit ADato.Models.DataModelUpdater.impl;

interface

uses
  System_,
  System.Collections.Generic,
  ADato.InsertPosition,
  ADato.ObjectModel.List.Tracking.intf,
  ADato.Models.ContextUpdater.intf;

type
  TDataModelModelContextUpdater = class(TBaseInterfacedObject, IObjectModelContextUpdater)
  protected
    [weak] _model: IObjectListModelChangeTracking;

    procedure set_Model(const Value: IObjectListModelChangeTracking);

  public
    procedure DoAddNew(const Value: CObject; var Index: Integer; Position: InsertPosition);
    function  DoRemove(const Value: CObject; out Index: Integer): CObject;

    function  RetrieveUpdatedItems: Dictionary<CObject, TObjectListChangeType>;
    function  ConvertToDataItem(const Value: CObject): CObject;

    class function CreateNew: IObjectModelContextUpdater;
  end;

implementation

uses
  ADato.Data.DataModel.intf;

procedure TDataModelModelContextUpdater.DoAddNew(const Value: CObject; var &Index: Integer; Position: InsertPosition);
var
  location: IDataRow;
  dataRow: IDataRow;
  drv: IDataRowView;
  dm: IDataModel;
begin
  var o := _model.ObjectContext;

  if not Interfaces.Supports<IDataModel>(_model.Context, dm) then
    raise NotSupportedException.Create('Context must implement IDataModel');

  var current := dm.DefaultCurrencyManager.Current;
  var count: Integer := dm.DefaultView.Rows.Count;
  if (current < count) and (count > 0) then
  begin
    location := dm.DefaultView.Rows[current].Row;
    if dm.IndexOf(location) = -1 then
      location := nil;
  end
  else
    location := nil;

  if o = nil then
    dataRow := dm.AddNew(location, Position)
  else if (location <> nil) and (location.Data <> nil) then
    dataRow := dm.Add(o, location.Data, Position)
  else
    dataRow := dm.Add(o, nil, Position);

  if dataRow <> nil then
  begin
    dm.DefaultView.MakeRowVisible(dataRow);
    drv := dm.DefaultView.FindRow(dataRow);
    if drv <> nil then
      dm.DefaultCurrencyManager.Current := drv.ViewIndex;
  end;
end;

function TDataModelModelContextUpdater.DoRemove(const Value: CObject; out Index: Integer): CObject;
var
  dm: IDataModel;
begin
  Result := nil;

  if not Interfaces.Supports<IDataModel>(_model.Context, dm) then
    raise NotSupportedException.Create('Context must implement IDataModel');

  var dr := dm.FindByKey(Value);
  if dr <> nil then
  begin
    var drv := dm.DefaultView.FindRow(dr);
    if drv = nil then
    begin
      if not dm.DefaultView.MakeRowVisible(dr) then
        Exit;

      drv := dm.DefaultView.FindRow(dr);
    end;

    {out} Index := drv.ViewIndex;
    if Index > 0 then
      Result := dm.DefaultView.Rows[Index - 1].Row.Data
    else if dm.DefaultView.Rows.Count > 1 then
      Result := dm.DefaultView.Rows[1].Row.Data
    else
      Result := nil;

    dm.DefaultCurrencyManager.Current := Index;
    dm.Remove(dr);
  end;
end;

function TDataModelModelContextUpdater.RetrieveUpdatedItems: Dictionary<CObject, TObjectListChangeType>;
var
  obj: CObject;
  changeType: TObjectListChangeType;
begin
  Result := CDictionary<CObject, TObjectListChangeType>.Create;
  if not _model.HasChangedItems then
    Exit;

  // new and changed items
  for obj in _model.Context do
  begin
    // item is the current state of the object.
    // ChangedItems contains the orignal objects
    var item := ConvertToDataItem(obj);
    if _model.ChangedItems.TryGetValue(item, changeType) then
      Result.Add(item, changeType);
  end;

  // deleted items
  for obj in _model.ChangedItems.Keys do
    if _model.ChangedItems[obj] = TObjectListChangeType.Removed then
      Result.Add(obj, TObjectListChangeType.Removed);
end;

function TDataModelModelContextUpdater.ConvertToDataItem(const Value: CObject): CObject;
var
  drv: IDataRowView;
begin
  if Value.TryAsType<IDataRowView>(drv) then
    Result := drv.Row.Data else
    Result := Value;
end;

class function TDataModelModelContextUpdater.CreateNew: IObjectModelContextUpdater;
begin
  Result := TDataModelModelContextUpdater.Create;
end;

procedure TDataModelModelContextUpdater.set_Model(const Value: IObjectListModelChangeTracking);
begin
  _model := Value;
end;

end.