{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit EditorMacroScript;

{$warn 5023 off : no warning about unused units}
interface

uses
  RegisterEMS, EMScriptMacro, EMScriptClasses, EMSSelfTest, EMSIdeOptions, 
  EMSStrings, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('RegisterEMS', @RegisterEMS.Register);
end;

initialization
  RegisterPackage('EditorMacroScript', @Register);
end.
