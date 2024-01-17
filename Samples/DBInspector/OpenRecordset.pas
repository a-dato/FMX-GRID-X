unit OpenRecordset;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Memo.Types, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.FMXUI.Wait, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
  FireDAC.Comp.UI, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  FMX.Layouts, ADato.FMX.Controls.ScrollableControl.Impl,
  ADato.FMX.Controls.ScrollableRowControl.Impl, ADato.Controls.FMX.Tree.Impl,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, System.Actions,
  FMX.ActnList, Delphi.Extensions.VirtualDataset,
  ADato.Data.VirtualDatasetDataModel, ADato.Data.DatasetDataModel,
  System.Diagnostics, FMX.ListBox;

type
  TOpenRecordSetFrame = class(TFrame)
    SqlQuery: TMemo;
    Layout1: TLayout;
    splitSqlSourcePanel: TSplitter;
    DataGrid: TFMXTreeControl;
    DataEditor: TMemo;
    fdConnection: TFDConnection;
    TheQuery: TFDQuery;
    DataSource1: TDataSource;
    Logging: TMemo;
    ActionList1: TActionList;
    btnExecute: TSpeedButton;
    DatasetDataModel1: TDatasetDataModel;
    Button1: TButton;
    acAbort: TAction;
    SpeedButton2: TSpeedButton;
    acNextRecordSet: TAction;
    lblConnection: TLabel;
    lyDataPanel: TLayout;
    Splitter2: TSplitter;
    cbRecordCount: TComboBox;
    Label1: TLabel;
    procedure acAbortExecute(Sender: TObject);
    procedure acNextRecordSetExecute(Sender: TObject);

  private
    FStopWatch: TStopWatch;
    FQueryEditorHeight: Single;

    function  get_CommandText: string;
    procedure set_CommandText(const Value: string);

    procedure set_SqlSourceText(const Value: string);
    procedure AddMessage(AMessage: string);

  protected
    procedure UpdateDialogControls(IsSqlSourceWindow: Boolean);
  public
    { Public declarations }
    procedure ExecuteQuery;
    property CommandText: string read get_CommandText write set_CommandText;
    property SqlSourceText: string read get_CommandText write set_SqlSourceText;
  end;

implementation

{$R *.fmx}

procedure TOpenRecordSetFrame.acAbortExecute(Sender: TObject);
begin
  TheQuery.AbortJob;
end;

procedure TOpenRecordSetFrame.acNextRecordSetExecute(Sender: TObject);
begin
  if TheQuery.Active then
    TheQuery.NextRecordSet;
end;

procedure TOpenRecordSetFrame.AddMessage(AMessage: string);
begin
  TThread.Queue(nil, procedure begin
    Logging.Lines.Add(AMessage);
  end);
end;

procedure TOpenRecordSetFrame.ExecuteQuery;
begin
  FStopWatch := TStopwatch.StartNew;

  Logging.Lines.Clear;
  Logging.Visible := True;

  fdConnection.ResourceOptions.ServerOutput := True;

  var recCount: Integer;
  if Integer.TryParse(cbRecordCount.Text, recCount) then
    TheQuery.FetchOptions.RecsMax := recCount else
    TheQuery.FetchOptions.RecsMax := -1;

  TheQuery.ResourceOptions.CmdExecMode := amBlocking;

  DatasetDataModel1.Close;
  TheQuery.FetchOptions.AutoClose := False;
  TheQuery.Close;

  if SqlQuery.Visible then
    TheQuery.SQL.Text := SqlQuery.Lines.Text;

  TThread.CreateAnonymousThread(procedure begin
    try
      TheQuery.Open;
    except
      on E: Exception do
        AddMessage(E.Message);
    end;

    TThread.Queue(nil, procedure begin

      // Not all queries return a dataset
      if TheQuery.Active then
      begin
        DatasetDataModel1.Open;
        DataGrid.DataModelView := DatasetDataModel1.DataModelView;;
      end;

      if fdConnection.Messages <> nil then
      begin
        for var i := 0 to fdConnection.Messages.ErrorCount - 1 do
          AddMessage(fdConnection.Messages[i].Message);
      end;

      AddMessage(string.Format('Ready: %d ms', [FStopWatch.ElapsedMilliseconds]));
    end);
  end).Start;
end;

{ TOpenRecordSetFrame }

function TOpenRecordSetFrame.get_CommandText: string;
begin
  Result := SqlQuery.Text;
end;

procedure TOpenRecordSetFrame.set_CommandText(const Value: string);
begin
  UpdateDialogControls(False);
  SqlQuery.Text := Value;
end;

procedure TOpenRecordSetFrame.set_SqlSourceText(const Value: string);
begin
  UpdateDialogControls(True);
  SqlQuery.Text := Value;
end;

procedure TOpenRecordSetFrame.UpdateDialogControls(IsSqlSourceWindow: Boolean);
begin
  // Hide data grid, go into Sql source editor mode
  if IsSqlSourceWindow then
  begin
    splitSqlSourcePanel.Visible := False;
    lyDataPanel.Visible := False;
    FQueryEditorHeight := SqlQuery.Height;
    SqlQuery.Align := TAlignLayout.Client;
  end
  else
  begin
    SqlQuery.Align := TAlignLayout.Top;
    if FQueryEditorHeight > 0 then
      SqlQuery.Height := FQueryEditorHeight;

    splitSqlSourcePanel.Visible := True;
    lyDataPanel.Visible := True;
  end;

end;

end.
