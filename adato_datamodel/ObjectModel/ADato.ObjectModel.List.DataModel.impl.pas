unit ADato.ObjectModel.List.DataModel.impl;

interface

uses
  System_,

  ADato.Data.DataModel.intf,
  ADato.ObjectModel.intf,
  ADato.ObjectModel.List.intf,
  ADato.ObjectModel.List.impl,
  ADato.ObjectModel.List.DataModel.intf;

type
  TDataModelObjectListModel<T> = class(TObjectListModel<T>, IDataModelObjectListModel)
  private
    _validatePosition: TValidatePosition;

    function  get_ValidatePosition: TValidatePosition;
    procedure set_ValidatePosition(const Value: TValidatePosition);

  protected
    _DataModel: IDataModel;
    function  get_DataModel: IDataModel;

  public
    function  CanMoveUp : Boolean;
    function  CanMoveDown : Boolean;
    function  CanIndent : Boolean;
    function  CanOutdent : Boolean;

    function  DoMoveUp : Boolean;
    function  DoMoveDown : Boolean;
    function  DoIndent : Boolean;
    function  DoOutdent : Boolean;

    procedure SetupDefaultDataModel;
  end;

implementation

uses
  ADato.Data.DataModel.impl, ADato.InsertPosition;

{ TDataModelObjectListModel<T> }

procedure TDataModelObjectListModel<T>.SetupDefaultDataModel;
var
  prop: _PropertyInfo;
  column: IDataModelColumn;

begin
  _dataModel := TDataModel.Create;

  for prop in _ObjectType.GetProperties do
  begin
    column := DataModelColumn.Create;
    column.Name := prop.Name;
    column.DataType := prop.GetType;
    _dataModel.Columns.Add(column);
  end;
end;

procedure TDataModelObjectListModel<T>.set_ValidatePosition(const Value: TValidatePosition);
begin
  _validatePosition := Value;
end;

function TDataModelObjectListModel<T>.CanIndent: Boolean;
var
  dr: IDataRow;
  drv: IDataRowView;
begin
  dr := _dataModel.FindByKey(get_ObjectContext);
  if dr = nil then Exit(False);

  drv := _dataModel.DefaultView.FindRow(dr);
  if (drv <> nil) and (drv.ViewIndex > 0) then
    Result := drv.Row.Level <= _dataModel.DefaultView.Rows[drv.ViewIndex - 1].Row.Level else
    Result := False;
end;

function TDataModelObjectListModel<T>.CanMoveDown: Boolean;
var
  dr: IDataRow;
  drv: IDataRowView;
begin
  dr := _dataModel.FindByKey(get_ObjectContext);
  if dr = nil then Exit(False);

  drv := _dataModel.DefaultView.FindRow(dr);
  Result := (drv <> nil) and (drv.ViewIndex < _dataModel.DefaultView.Rows.Count - 1);
end;

function TDataModelObjectListModel<T>.CanMoveUp: Boolean;
var
  dr: IDataRow;
  drv: IDataRowView;
begin
  dr := _dataModel.FindByKey(get_ObjectContext);
  if dr = nil then Exit(False);

  drv := _dataModel.DefaultView.FindRow(dr);
  Result := (drv <> nil) and (drv.ViewIndex > 0);
end;

function TDataModelObjectListModel<T>.CanOutdent: Boolean;
var
  dr: IDataRow;
  drv: IDataRowView;
begin
  dr := _dataModel.FindByKey(get_ObjectContext);
  if dr = nil then Exit(False);

  drv := _dataModel.DefaultView.FindRow(dr);
  Result := (drv <> nil) and (drv.Row.Level > 0);
end;

function TDataModelObjectListModel<T>.DoIndent: Boolean;
var
  dr: IDataRow;
  destRow, srcRow: IDataRowView;
begin
  dr := _dataModel.FindByKey(get_ObjectContext);
  if dr = nil then Exit(False);

  srcRow := _dataModel.DefaultView.FindRow(dr);
  destRow := _dataModel.DefaultView.PrevSibling(srcRow);
  if destRow = nil then Exit(False);

  Result := not Assigned(_validatePosition) or _validatePosition(srcRow, destRow, InsertPosition.Child, False, True);
  if Result then
  begin
    _dataModel.MoveRow(srcRow.Row, destRow.Row, InsertPosition.Child);
    _dataModel.DefaultView.MakeRowVisible(srcRow.Row);
  end;
end;

function TDataModelObjectListModel<T>.DoMoveDown: Boolean;
var
  dr: IDataRow;
  parent: IDataRowView;
  srcRow: IDataRowView;
  destRow: IDataRowView;

begin
  dr := _dataModel.FindByKey(get_ObjectContext);
  if dr = nil then Exit(False);

  srcRow := _dataModel.DefaultView.FindRow(dr);
  destRow := _dataModel.DefaultView.NextSibling(srcRow);

  // check can move down
  Result := _dataModel.DefaultView.Rows[_dataModel.DefaultView.Rows.Count-1] <> srcRow;
  if Result then
  begin
    // No more siblings in current branch
    // Jump to branch of previous parent
    if destRow = nil then
    begin
      parent := _dataModel.DefaultView.Parent(srcRow);
      if parent = nil then Exit;

      destRow := _dataModel.DefaultView.NextSibling(parent);
      if destRow = nil then Exit;

      _dataModel.MoveRow(srcRow.Row, destRow.Row, InsertPosition.Child);
      _dataModel.DefaultView.MakeRowVisible(srcRow.Row);
    end else
      _dataModel.MoveRow(srcRow.Row, destRow.Row, InsertPosition.After);

    _dataModel.DefaultView.MakeRowVisible(srcRow.Row);
  end;
end;

function TDataModelObjectListModel<T>.DoMoveUp: Boolean;
var
  dr: IDataRow;
  parent: IDataRowView;
  srcRow: IDataRowView;
  destRow: IDataRowView;
begin
  dr := _dataModel.FindByKey(get_ObjectContext);
  if dr = nil then Exit(False);

  srcRow := _dataModel.DefaultView.FindRow(dr);
  destRow := _dataModel.DefaultView.PrevSibling(srcRow);

  // check can move up
  Result := _dataModel.DefaultView.Rows[0] <> srcRow;
  if Result then
  begin
    // No more siblings in current branch
    // Jump to branch of previous parent
    if destRow = nil then
    begin
      parent := _dataModel.DefaultView.Parent(srcRow);
      if parent = nil then Exit;

      destRow := _dataModel.DefaultView.PrevSibling(parent);
      if destRow = nil then Exit;

      _dataModel.MoveRow(srcRow.Row, destRow.Row, InsertPosition.Child);
      _dataModel.DefaultView.MakeRowVisible(srcRow.Row);
    end else
      _dataModel.MoveRow(srcRow.Row, destRow.Row, InsertPosition.Before);

    _dataModel.DefaultView.MakeRowVisible(srcRow.Row);
  end;
end;

function TDataModelObjectListModel<T>.DoOutdent: Boolean;
var
  dr: IDataRow;
  destRow, srcRow: IDataRowView;
begin
  dr := _dataModel.FindByKey(get_ObjectContext);
  if dr = nil then Exit(False);

  srcRow := _dataModel.DefaultView.FindRow(dr);
  if srcRow.Row.Level = 0 then Exit(False);

  destRow := _dataModel.DefaultView.Parent(srcRow);

  Result := not Assigned(_validatePosition) or _validatePosition(srcRow, destRow, InsertPosition.After, False, True);
  if Result then
    _dataModel.MoveRow(srcRow.Row, destRow.Row, InsertPosition.After);
end;

function TDataModelObjectListModel<T>.get_DataModel: IDataModel;
begin
  Result := _dataModel;
end;

function TDataModelObjectListModel<T>.get_ValidatePosition: TValidatePosition;
begin
  Result := _validatePosition;
end;

end.
