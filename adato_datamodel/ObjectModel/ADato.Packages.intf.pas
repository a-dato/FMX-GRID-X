{$I Adato.inc}

unit ADato.Packages.intf;

interface

uses
  System_;

type
  IExtensionPackage = interface
    ['{5747925E-E86D-4774-A1B1-C808C56E653B}']
    procedure Register;
  end;

  IPackageManager = interface
    ['{5EBCBEAD-AEAE-4F4B-8E1F-662F3440F062}']

    procedure AddPackage(const Package: IExtensionPackage);
    function  GetTypeFromName(const Name: string) : &Type;
  end;

var
  PackageManager: IPackageManager;

implementation

end.
