(*
 * Dialog Utils
 *
 * PLATFORMS
 *   Windows / macOS / Android / iOS
 *
 * LICENSE
 *   Copyright (c) 2018 HOSOKAWA Jun
 *   Released under the MIT license
 *   http://opensource.org/licenses/mit-license.php
 *
 * 2016/05/13 Version 1.0.0
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

unit PK.Utils.Dialogs;

interface

uses
  System.SysUtils
  , System.UITypes
  , FMX.Dialogs
  , FMX.DialogService
  ;

procedure ShowMessageDialog(
  const iMsg: String;
  const iDlgType: TMsgDlgType;
  const iButtons: TMsgDlgButtons;
  const iDefaultButton: TMsgDlgBtn;
  const iProc: TInputCloseDialogProc);

type
  TDialogResultProc = reference to procedure (const iOK: Boolean);

procedure QueryMessageDialog(
  const iMsg: String;
  const iButtons: TMsgDlgButtons;
  const iDefaultButton: TMsgDlgBtn;
  const iOKResult: TModalResult;
  const iProc: TDialogResultProc);

procedure ShowInfoDialog(const iMsg: String; const iProc: TProc = nil);
procedure ShowWarningDialog(const iMsg: String; const iProc: TProc = nil);
procedure ShowErrorDialog(const iMsg: String; const iProc: TProc = nil);

procedure QueryYesNoDialog(
  const iMsg: String;
  const iProc: TDialogResultProc);

procedure QueryOKCancelDialog(
  const iMsg: String;
  const iProc: TDialogResultProc);

implementation

procedure ShowInfoDialog(const iMsg: String; const iProc: TProc);
begin
  ShowMessageDialog(
    iMsg,
    TMsgDlgType.mtInformation,
    [TMsgDlgBtn.mbOK],
    TMsgDlgBtn.mbOK,
    procedure (const iResult: TModalResult)
    begin
      if Assigned(iProc) then
        iProc;
    end
  );
end;

procedure ShowWarningDialog(const iMsg: String; const iProc: TProc);
begin
  ShowMessageDialog(
    iMsg,
    TMsgDlgType.mtWarning,
    [TMsgDlgBtn.mbOK],
    TMsgDlgBtn.mbOK,
    procedure (const iResult: TModalResult)
    begin
      if Assigned(iProc) then
        iProc;
    end
  );
end;

procedure ShowErrorDialog(const iMsg: String; const iProc: TProc);
begin
  ShowMessageDialog(
    iMsg,
    TMsgDlgType.mtError,
    [TMsgDlgBtn.mbOK],
    TMsgDlgBtn.mbOK,
    procedure (const iResult: TModalResult)
    begin
      if Assigned(iProc) then
        iProc;
    end
  );
end;

procedure QueryYesNoDialog(
  const iMsg: String;
  const iProc: TDialogResultProc);
begin
  QueryMessageDialog(
    iMsg,
    [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
    TMsgDlgBtn.mbYes,
    mrYes,
    iProc);
end;

procedure QueryOKCancelDialog(
  const iMsg: String;
  const iProc: TDialogResultProc);
begin
  QueryMessageDialog(
    iMsg,
    [TMsgDlgBtn.mbOK, TMsgDlgBtn.mbCancel],
    TMsgDlgBtn.mbOK,
    mrOK,
    iProc);
end;

procedure QueryMessageDialog(
  const iMsg: String;
  const iButtons: TMsgDlgButtons;
  const iDefaultButton: TMsgDlgBtn;
  const iOKResult: TModalResult;
  const iProc: TDialogResultProc);
begin
  ShowMessageDialog(
    iMsg,
    TMsgDlgType.mtConfirmation,
    iButtons,
    iDefaultButton,
    procedure(const iResult: TModalResult)
    begin
      iProc(iResult = iOKResult);
    end
  );
end;

procedure ShowMessageDialog(
  const iMsg: String;
  const iDlgType: TMsgDlgType;
  const iButtons: TMsgDlgButtons;
  const iDefaultButton: TMsgDlgBtn;
  const iProc: TInputCloseDialogProc);
begin
  TDialogService.MessageDialog(
    iMsg,
    iDlgType,
    iButtons,
    iDefaultButton,
    0,
    iProc
  );
end;

end.
 