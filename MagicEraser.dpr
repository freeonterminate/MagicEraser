program MagicEraser;

uses
  System.StartUpCopy,
  FMX.Forms,
  FMX.Skia,
  uMain in 'uMain.pas' {frmMain},
  uSVGButton in 'uSVGButton.pas',
  PK.Graphic.BitmapCodecManagerHelper in 'Lib\PK.Graphic.BitmapCodecManagerHelper.pas',
  PK.Utils.Dialogs in 'Lib\PK.Utils.Dialogs.pas',
  PK.Storage.Utils in 'Lib\PK.Storage.Utils.pas',
  PK.Storage.Permission in 'Lib\PK.Storage.Permission.pas';

{$R *.res}

begin
  GlobalUseSkia := True;

  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}

  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
