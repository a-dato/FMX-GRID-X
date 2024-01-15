program Inspector;

uses
  System.StartUpCopy,
  FMX.Forms,
  Main in 'Main.pas' {frmInspector},
  Login in 'Login.pas' {frmLogin},
  OpenRecordset in 'OpenRecordset.pas' {OpenRecordSetFrame: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmInspector, frmInspector);
  Application.CreateForm(TfrmLogin, frmLogin);
  Application.Run;
end.
