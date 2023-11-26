(*
 * Save Bitmap Support Utils
 *
 * PLATFORMS
 *   Windows / macOS / Android / iOS
 *
 * LICENSE
 *   Copyright (c) 2020 HOSOKAWA Jun
 *   Released under the MIT license
 *   http://opensource.org/licenses/mit-license.php
 *
 * 2020/02/25 Version 1.0.0
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

unit PK.Storage.Utils;

interface

uses
  System.SysUtils
  , System.IOUtils
  , FMX.Consts
  , FMX.Graphics
  , FMX.Platform
  , FMX.MediaLibrary
  ;

type
  TSaveBitmapToSharedFolderCompletionProc = 
    reference to procedure(const ASaved: Boolean; const AResultMessage: String);

procedure SaveBitmapToSharedFolderByLibrary(
  const ABitmap: TBitmap;
  const ACompletionProc: TSaveBitmapToSharedFolderCompletionProc = nil);

procedure SaveBitmapToSharedFolder(
  const ABitmap: TBitmap;
  const AFolderName: String = '';
  const AFileName: String = '';
  const ACompletionProc: TSaveBitmapToSharedFolderCompletionProc = nil);

implementation

type
  TSaveBitmapToSharedFolderHandler = class
  private var
    FCompletionProc: TSaveBitmapToSharedFolderCompletionProc;
  public
    procedure WriteImageCompletionHandler(
      const ASaved: Boolean; 
      const AResultMessage: string);
  end;

{ TSaveBitmapToSharedFolderHandler }

procedure TSaveBitmapToSharedFolderHandler.WriteImageCompletionHandler(
  const ASaved: Boolean; 
  const AResultMessage: string);
begin
  if Assigned(FCompletionProc) then
    FCompletionProc(ASaved, AResultMessage);

  Self.Free;
end;

procedure SaveBitmapToSharedFolderByLibrary(
  const ABitmap: TBitmap;
  const ACompletionProc: TSaveBitmapToSharedFolderCompletionProc = nil);
begin
  // IFMXPhotoLibrary を用いる方法
  var PhotoLib: IFMXPhotoLibrary;

  if
    TPlatformServices.Current.SupportsPlatformService(
      IFMXPhotoLibrary,
      PhotoLib
    )
  then
  begin
    var Handler := TSaveBitmapToSharedFolderHandler.Create;
    Handler.FCompletionProc := ACompletionProc;
    PhotoLib.AddImageToSavedPhotosAlbum(
      ABitmap, 
      Handler.WriteImageCompletionHandler
    );
  end
  else
  begin
    if Assigned(ACompletionProc) then
      ACompletionProc(False, 'PhotoLibrary interface is not supported.');
  end;
end;

procedure SaveBitmapToSharedFolder(
  const ABitmap: TBitmap;
  const AFolderName: String = '';
  const AFileName: String = '';
  const ACompletionProc: TSaveBitmapToSharedFolderCompletionProc = nil);
const 
  SAVED_MESSAGES: array [Boolean] of String = (
    'Failed to save.', 
    'Successfully saved.'
  );
begin
  // TBitmap.SaveToFile を用いる方法
  if TOSVersion.Platform = TOSVersion.TPlatform.pfiOS then
  begin
    // iOS では使えないので PhotoLibrary を使う方法に飛ばす
    SaveBitmapToSharedFolderByLibrary(ABitmap, ACompletionProc);
  end
  else
  begin
    var P := TPath.GetSharedPicturesPath;

    // アプリケーション独自のフォルダを作る場合は AFolderName を指定する
    if not AFolderName.IsEmpty then
    begin
      P := TPath.Combine(P, AFolderName);
      TDirectory.CreateDirectory(P);
    end;
    
    if TDirectory.Exists(P) then
    begin
      var FileName := AFileName;
      if FileName.IsEmpty then
        FileName :=
          TPath.Combine(
            P,
            FormatDateTime('yymmdd_hhnnsszzz', Now) + SPNGImageExtension
          );

      P := TPath.Combine(P, FileName);
      ABitmap.SaveToFile(P);

      if Assigned(ACompletionProc) then
      begin
        var Saved := TFile.Exists(P);
        ACompletionProc(Saved, SAVED_MESSAGES[Saved]);
      end;
    end;
  end;
end;

end.
