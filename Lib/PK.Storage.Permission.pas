(*
 * Android Permission Support Utils
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

unit PK.Storage.Permission;

interface

uses
  System.SysUtils;

type
  TRequestStrageAccessCompletionProc =
    reference to procedure(const ASuccess: Boolean);

procedure RequestStorageAccess(
  const AInformationMessage: String;
  const AProc: TRequestStrageAccessCompletionProc);

implementation

uses
  System.Permissions
  , System.Types
  , System.UITypes
  , FMX.DialogService
  ;

procedure RequestStorageAccess(
  const AInformationMessage: String;
  const AProc: TRequestStrageAccessCompletionProc);
begin
  const
    RW_PERMISSIONS: TArray<String> =
      [
        'android.permission.READ_EXTERNAL_STORAGE',
        'android.permission.WRITE_EXTERNAL_STORAGE'
      ];

  // Android 11 以降は実行時権限チェックは必要なくなった（常に失敗が返る）
  if
    (TOSVersion.Platform <> TOSVersion.TPlatform.pfAndroid) or
    TOSVersion.Check(11)
  then
  begin
    if Assigned(AProc) then
      AProc(True);

    Exit;
  end;

  if
    not PermissionsService.IsEveryPermissionGranted(RW_PERMISSIONS)
  then
  begin
    TDialogService.ShowMessage(
      AInformationMessage,
      procedure(const AResult: TModalResult)
      begin
        PermissionsService.RequestPermissions(
          RW_PERMISSIONS,
          procedure(
            const APermissions: TClassicStringDynArray;
            const AGrantResults: TClassicPermissionStatusDynArray)
            begin
              if Assigned(AProc) then
                AProc(
                  (Length(AGrantResults) = 2) and
                  (AGrantResults[0] = TPermissionStatus.Granted) and
                  (AGrantResults[1] = TPermissionStatus.Granted)
                );
            end
          );
      end
    );
  end;
end;

end.
