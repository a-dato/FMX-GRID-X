unit ADato.Models.ContextUpdater.intf;

interface

uses
  System_,
  System.Collections.Generic,

  ADato.InsertPosition,
  ADato.ObjectModel.List.Tracking.intf;

type
  IObjectModelContextUpdater = interface(IBaseInterface)
    ['{CF168956-69F4-4DF7-B7BE-D488785B5CDB}']
    procedure set_Model(const Value: IObjectListModelChangeTracking);

    procedure DoAddNew(const Value: CObject; var Index: Integer; Position: InsertPosition);
    function  DoRemove(const Value: CObject; out Index: Integer): CObject;

    function  RetrieveUpdatedItems: Dictionary<CObject, TObjectListChangeType>;
    function  ConvertToDataItem(const Value: CObject): CObject;

    property Model: IObjectListModelChangeTracking write set_Model;
  end;

implementation

end.