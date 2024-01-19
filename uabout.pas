unit uAbout;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ButtonPanel,
  StdCtrls, LclIntf;

type

  { TfAbout }

  TfAbout = class(TForm)
    ButtonPanel1: TButtonPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure Label2Click(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fAbout: TfAbout;

implementation

{$R *.lfm}

{ TfAbout }

procedure TfAbout.Label2Click(Sender: TObject);
begin
  OpenURL((Sender As TLabel).Caption);
end;

end.

