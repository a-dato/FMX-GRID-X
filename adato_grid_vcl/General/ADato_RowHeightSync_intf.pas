{$I Jedi.inc}
unit ADato_RowHeightSync_intf;

interface

uses
  System_;

type
  IRowHeightCollection = {$IFDEF DOTNET}public{$ENDIF} interface(IBaseInterface)
  {$IFDEF DELPHI}
    ['{9BCA3342-5B7A-4D9B-9008-99B318393371}']
    function  get_RowHeight(const DataRow: CObject): Integer;
    procedure set_RowHeight(const DataRow: CObject; Value: Integer);
  {$ENDIF}

    procedure Clear;

    property RowHeight[const DataRow: CObject] : Integer
      read  {$IFDEF DELPHI}get_RowHeight{$ENDIF}
      write {$IFDEF DELPHI}set_RowHeight{$ENDIF}; default;
  end;

implementation

end.
