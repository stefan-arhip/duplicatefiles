unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, EditBtn,
  ExtCtrls, ComCtrls, Menus, CRC, ShellApi, StrUtils, DateUtils, LclIntf;

type

  { TfMain }

  TfMain = class(TForm)
    lvFiles: TListView;
    MenuItem1: TMenuItem;
    miFileOpen: TMenuItem;
    miFilePath: TMenuItem;
    MenuItem4: TMenuItem;
    miFileCopy: TMenuItem;
    miFileMove: TMenuItem;
    miFileDeleteSelected: TMenuItem;
    MenuItem8: TMenuItem;
    miFileProperties: TMenuItem;
    miFileClear: TMenuItem;
    miHelpAbout: TMenuItem;
    miHelp: TMenuItem;
    miToolsOptions: TMenuItem;
    miTools: TMenuItem;
    miFileDeleteChecked: TMenuItem;
    mmMain: TMainMenu;
    miFile: TMenuItem;
    miFileSearch: TMenuItem;
    pmFiles: TPopupMenu;
    sdFileSearch: TSelectDirectoryDialog;
    StatusBar1: TStatusBar;
    procedure miFileClearClick(Sender: TObject);
    procedure miFileDeleteCheckedClick(Sender: TObject);
    procedure miFileOpenClick(Sender: TObject);
    procedure miFilePathClick(Sender: TObject);
    procedure miFileSearchClick(Sender: TObject);
    procedure miHelpAboutClick(Sender: TObject);
    procedure miToolsOptionsClick(Sender: TObject);
    procedure mmMainChange(Sender: TObject; Source: TMenuItem; Rebuild: boolean);
    procedure pmFilesPopup(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    procedure FileSearch(const DirName: string);
  end;

var
  fMain: TfMain;

implementation

{$R *.lfm}

{ TfMain }

uses uOptions, uAbout;

var
  Duplicates: word;
  StartTime: TDateTime;
  LoadingTime: real;

function CrcFile(filename: string): string;
var
  Len: integer;
  tmp: cardinal;
  buff: array[0..127] of byte;
begin
  tmp := crc32(0, nil, 0); //Grund Hash von leeren Bytes erstellen
  with TFileStream.Create(FileName, fmOpenRead) do  //Datei öffnen
  begin
    try
      repeat
        Len := Read(buff, 128);  // 128 Byte aus datei Lesen
        tmp := crc32(tmp, @buff, len); // Hash Updaten
      until len < 128; // Solange lesen bis EOF
    finally
      Free;
    end;
  end;
  Result := IntToHex(tmp, 8);
end;

procedure DeleteFileToBin(aFile: PChar);
var
  fileOpStruct: ShellApi.TSHFileOpStruct;
begin
  fileOpStruct.Wnd := 0;
  fileOpStruct.wFunc := FO_DELETE;
  fileOpStruct.pFrom := aFile;
  fileOpStruct.fFlags := FOF_ALLOWUNDO + FOF_NOCONFIRMATION;
  SHFileOperation(fileOpStruct);
end;

procedure TfMain.FileSearch(const DirName: string);
var
  SearchResult: SysUtils.TSearchRec;
  FileModifyDate: TDateTime;
  strCRC, strExt, strMsg: string;
  i: integer;
begin
  if FindFirst(IncludeTrailingBackSlash(DirName) + '*', faAnyFile, SearchResult) = 0 then
  begin
    try
      repeat
        Application.ProcessMessages;
        FileModifyDate := FileDateToDateTime(SearchResult.Time);
        if (SearchResult.Attr and faDirectory) = 0 then
        begin
          strExt := ExtractFileExt(SearchResult.Name);
          if (fOptions.coFilesType.Text = '.*') or
            (StrUtils.AnsiContainsStr(fOptions.coFilesType.Text, strExt)) then
            with lvFiles.Items.Add do
            begin
              Caption := SearchResult.Name;
              try
                strCRC := CrcFile(IncludeTrailingBackSlash(DirName) + SearchResult.Name);
              except
                strCRC := '#error';
              end;
              SubItems.Add(strCRC);
              SubItems.Add(Format('%d', [SearchResult.Size]));       // Size
              SubItems.Add(strExt);                                  // Ext
              SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss', FileModifyDate));
              SubItems.Add(IncludeTrailingBackSlash(DirName) + SearchResult.Name);

              LoadingTime := DateUtils.MilliSecondsBetween(Now(), StartTime) / 1000;
              if LoadingTime < 60 then                               // Seconds
                strMsg := Format('working...   %0.2f seconds', [LoadingTime])
              else if LoadingTime < 60 * 60 then                     // Minutes
                strMsg := Format('working...   %0.2f minutes', [LoadingTime / 60])
              else if LoadingTime < 60 * 60 * 60 then                // Minutes
                strMsg := Format('working...   %0.2f hours', [LoadingTime / 60 / 60]);
              StatusBar1.Panels[0].Text := strMsg;

              strMsg := Format('%d files found', [lvFiles.Items.Count]);
              StatusBar1.Panels[1].Text := strMsg;

              for i := 1 to lvFiles.Items.Count - 1 do
                if (lvFiles.Items[i - 1].SubItems[0] = strCRC) and
                  (strCRC <> '#error') then
                begin
                  Inc(Duplicates);
                  if Duplicates > 0 then
                    strMsg := Format('%d files to be deleted', [Duplicates])
                  else
                    strMsg := '';
                  StatusBar1.Panels[2].Text := strMsg;
                  Checked := True;
                  Break;
                end;
              strMsg := Format('process file %s', [SearchResult.Name]);
              StatusBar1.Panels[3].Text := strMsg;
            end;
        end
        else
        if (SearchResult.Name <> '.') and (SearchResult.Name <> '..') then
          FileSearch(IncludeTrailingBackSlash(DirName) + SearchResult.Name);
      until FindNext(SearchResult) <> 0
    finally
      FindClose(SearchResult);
      StatusBar1.Panels[3].Text := '';
    end;
  end;
end;

procedure TfMain.miFileSearchClick(Sender: TObject);
begin
  if sdFileSearch.Execute then
  begin
    Screen.Cursor := crHourGlass;
    miFile.Enabled := False;
    miTools.Enabled := False;

    //Duplicates := 0;
    StartTime := Now();
    StatusBar1.Panels[0].Text := 'working...';
    //StatusBar1.Panels[1].Text := '';
    //StatusBar1.Panels[2].Text := '';

    lvFiles.Items.BeginUpdate;
    lvFiles.Items.Clear;
    FileSearch(sdFileSearch.FileName);
    lvFiles.SortType := stNone;
    lvFiles.SortType := stBoth;
    lvFiles.SortColumn := 0;
    lvFiles.SortDirection := sdDescending;
    lvFiles.Items.EndUpdate;

    StatusBar1.Panels[0].Text := 'ready';
    miFile.Enabled := True;
    miTools.Enabled := True;
    Screen.Cursor := crDefault;
  end;
end;

procedure TfMain.miHelpAboutClick(Sender: TObject);
begin
  fAbout.ShowModal;
end;

procedure TfMain.miToolsOptionsClick(Sender: TObject);
begin
  fOptions.ShowModal;
end;

procedure TfMain.mmMainChange(Sender: TObject; Source: TMenuItem; Rebuild: boolean);
begin
  miFileDeleteChecked.Enabled := Duplicates > 0;
end;

procedure TfMain.pmFilesPopup(Sender: TObject);
var
  b: boolean;
begin
  b := lvFiles.ItemFocused <> nil;
  miFileOpen.Enabled := b;
  miFilePath.Enabled := b;
  miFileCopy.Enabled := b;
  miFileMove.Enabled := b;
  miFileDeleteSelected.Enabled := b;
  miFileProperties.Enabled := b;
end;

procedure TfMain.miFileDeleteCheckedClick(Sender: TObject);
var
  i: integer;
  strMsg: string;
begin
  if Messagedlg('Move selected files to Recycle Bin?', mtConfirmation,
    [mbYes, mbNo], 0) = mrYes then
    for i := lvFiles.Items.Count downto 1 do
      if lvFiles.Items[i - 1].Checked then
      begin
        DeleteFileToBin(PChar(lvFiles.Items[i - 1].SubItems[4] + #0));
        if not FileExists(PChar(lvFiles.Items[i - 1].SubItems[4])) then
        begin
          Dec(Duplicates);
          lvFiles.Items[i - 1].Delete;
          StatusBar1.Panels[1].Text := Format('%d files found', [lvFiles.Items.Count]);
          if Duplicates > 0 then
            StrMsg := Format('%d files to be deleted', [Duplicates])
          else
            strMsg := '';
          StatusBar1.Panels[2].Text := strMsg;
        end;
      end;
end;

procedure TfMain.miFileOpenClick(Sender: TObject);
begin
  if lvFiles.Selected <> nil then
    OpenDocument(lvFiles.Selected.SubItems[4]);
end;

procedure TfMain.miFilePathClick(Sender: TObject);
begin
  if lvFiles.Selected <> nil then
    OpenDocument(ExtractFilePath(lvFiles.Selected.SubItems[4]));
end;

procedure TfMain.miFileClearClick(Sender: TObject);
var
  strMsg: string;
begin
  lvFiles.Items.Beginupdate;
  lvFiles.Items.Clear;
  Duplicates := 0;
  StatusBar1.Panels[1].Text := Format('%d files found', [lvFiles.Items.Count]);
  if Duplicates > 0 then
    strMsg := Format('%d files to be deleted', [Duplicates])
  else
    strMsg := '';
  StatusBar1.Panels[2].Text := strMsg;
  lvFiles.Items.EndUpdate;
end;

initialization
  Duplicates := 0;

end.
