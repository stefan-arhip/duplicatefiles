unit uOptions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ButtonPanel,
  StdCtrls, IniPropStorage;

type

  { TfOptions }

  TfOptions = class(TForm)
    ButtonPanel1: TButtonPanel;
    coFilesType: TComboBox;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fOptions: TfOptions;

implementation

{$R *.lfm}

end.

