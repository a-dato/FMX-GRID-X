unit ADato.Models.ContextUpdater.impl;

interface

uses
  System_,
  System.Collections.Generic,
  ADato.InsertPosition,
  ADato.ObjectModel.List.Tracking.intf,
  ADato.Models.ContextUpdater.intf;

type
  TObjectModelContextUpdater = class(TBaseInterfacedObject, IObjectModelContextUpdater)
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

procedure TObjectModelContextUpdater.DoAddNew(const Value: CObject; var &Index: Integer; Position: InsertPosition);
var
  location: IDataRow;
  dataRow: IDataRow;
  drv: IDataRowView;
  dm: IDataModel;
begin
  var o := _model.ObjectContext;

  if not Interfaces.Supports<IDataModel>(_model.Context, dm) then
  begin
    _model.Context.Insert(&Index, Value);
    Exit;
  end;
  
  var current := dm.DefaultCurrencyManager.Current;
  var count: Integer := dm.DefaultView.Rows.Count;
  if (current < count) and (count > 0) then
    location := dm.DefaultView.Rows[current].Row else
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

function TObjectModelContextUpdater.DoRemove(const Value: CObject; out Index: Integer): CObject;
var
  dm: IDataModel;
begin
  Result := nil;

  if Interfaces.Supports<IDataModel>(_model.Context, dm) then
  begin
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
  end
  else
  begin
    {out} Index := _model.Context.IndexOf(Value);
    if Index <> -1 then
    begin
      if Index > 0 then
        Result := _model.Context[Index - 1]
      else if _model.Context.Count > 1 then
        Result := _model.Context[1]
      else
        Result := nil;

      _model.Context.RemoveAt(Index);
    end;
  end;
end;

function TObjectModelContextUpdater.RetrieveUpdatedItems: Dictionary<CObject, TObjectListChangeType>;
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

function TObjectModelContextUpdater.ConvertToDataItem(const Value: CObject): CObject;
var
  drv: IDataRowView;
begin
  if Value.TryAsType<IDataRowView>(drv) then
    Result := drv.Row.Data else
    Result := Value;
end;

class function TObjectModelContextUpdater.CreateNew: IObjectModelContextUpdater;
begin
  Result := TObjectModelContextUpdater.Create;
end;

procedure TObjectModelContextUpdater.set_Model(const Value: IObjectListModelChangeTracking);
begin
  _model := Value;
end;

end.