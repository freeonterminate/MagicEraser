unit uMain;

interface

uses
  System.Classes
  , System.Skia
  , System.SysUtils
  , System.Types
  , System.UITypes
  , System.Variants
  , FMX.Ani
  , FMX.Controls
  , FMX.Controls.Presentation
  , FMX.Dialogs
  , FMX.Forms
  , FMX.Graphics
  , FMX.Layouts
  , FMX.MediaLibrary
  , FMX.MultiView
  , FMX.Objects
  , FMX.StdCtrls
  , FMX.Skia
  , FMX.Types
  ;

type
  TfrmMain = class(TForm)
    layoutRoot: TLayout;
    barTop: TToolBar;
    mviewMenu: TMultiView;
    bookImpressiveDark: TStyleBook;
    lblTopTitle: TLabel;
    svgMVFileOpen: TSkSvg;
    lblMVFileOpenCaption: TLabel;
    svgMVFileSave: TSkSvg;
    lblMVFileSaveCaption: TLabel;
    circleMVFileSaveCircle: TCircle;
    aniMVFileSaveEffect: TFloatAnimation;
    circleMVFileOpenCircle: TCircle;
    aniMVFileOpenEffect: TFloatAnimation;
    svgTopClose: TSkSvg;
    svgTopOpen: TSkSvg;
    svgMVOpEraser: TSkSvg;
    lblMVOpEraser: TLabel;
    svgMVOpMove: TSkSvg;
    lblMVOpMove: TLabel;
    btnTopMV: TButton;
    dlgOpen: TOpenDialog;
    rectWaiterBase: TRectangle;
    aniWaitor: TAniIndicator;
    pnlOpBase: TPanel;
    layoutOpEraserBase: TLayout;
    layoutOpMoveBase: TLayout;
    svgZoomIn: TSkSvg;
    svgZoomOut: TSkSvg;
    layoutOpZoomBase: TLayout;
    layoutOpZoomUpBase: TLayout;
    layoutOpZoomDownBase: TLayout;
    lblOpZoomBy: TLabel;
    scrollHBar: TScrollBar;
    layoutScrollBase: TLayout;
    scrollVBar: TScrollBar;
    rectSelector: TRectangle;
    imgImage: TImage;
    layoutImageBase: TLayout;
    trackDiameter: TTrackBar;
    pnlTopBase: TPanel;
    dlgSave: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure btnTopMVApplyStyleLookup(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar;
      Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: WideChar;
      Shift: TShiftState);
    procedure scrollVBarChange(Sender: TObject);
    procedure scrollHBarChange(Sender: TObject);
    procedure layoutScrollBaseResize(Sender: TObject);
    procedure layoutImageBaseMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure layoutImageBaseMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Single);
    procedure FormDestroy(Sender: TObject);
    procedure layoutImageBaseGesture(Sender: TObject;
      const EventInfo: TGestureEventInfo; var Handled: Boolean);
  private type
    TToolType = (Move, Eraser);
  private var
    FIsDesktop: Boolean;
    FTool: TToolType;
    FLastDistance: Single;
    FLastPos: TPointF;
    FScreenScale: Single;
    FZoomScale: Single;
    FSetImageSizeProcessing: Boolean;
    FSpacePressed: Boolean;
    FHScrollbarValue: Single;
    FVScrollbarValue: Single;
    FOldPos: TPointF;
    FDiameter: Single;
    FAlphaBitmap: TBitmap;
  private
    procedure ShowWaiter;
    procedure HideWaiter;
    function CalcPos(const AX, AY: Single): TPointF;
    procedure InitScrollBar;
    procedure SetImageSize;
    procedure SetZoomScale(const AZoomScale: Single);
    procedure SetTool(const ALayout: TLayout; const ATool: TToolType);
    procedure SetMVButtonVisible(const AOpened: Boolean);
    procedure TakePhotoFinishHandler(AImage: TBitmap);
    procedure FileOpenClickHandler(Sender: TObject);
    procedure FileSaveClickHandler(Sender: TObject);
    procedure OpMoveClickHandler(Sender: TObject);
    procedure OpEraserClickHandler(Sender: TObject);
    procedure ZoomOutClickHandler(Sender: TObject);
    procedure ZoomInClickHandler(sender: TObject);
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

uses
  System.Math
  , FMX.Platform
  , PK.Graphic.BitmapCodecManagerHelper
  , PK.Storage.Utils
  , PK.Storage.Permission
  , PK.Utils.Dialogs
  , uSVGButton
  {$IFDEF ANDROID}
  , Androidapi.Helpers
  , Androidapi.Jni.App
  {$ENDIF}
  ;

procedure TfrmMain.btnTopMVApplyStyleLookup(Sender: TObject);
begin
  // ボタンの押下エフェクトを消す
  for var C in btnTopMV.Children do
    if C is TEllipse then
    begin
      TEllipse(C).Visible := False;
      Break;
    end
end;

function TfrmMain.CalcPos(const AX, AY: Single): TPointF;
begin
  // Desktop は仮想解像度なので座標の計算にスクリーンスケールは不要
  var S := {$IF defined(ANDROID) or defined(IOS)}FScreenScale{$ELSE}1{$ENDIF};
  
  Result.X := (FHScrollbarValue + AX) * S / FZoomScale;
  Result.Y := (FVScrollbarValue + AY) * S / FZoomScale;
end;

procedure TfrmMain.FileOpenClickHandler(Sender: TObject);
begin
  var Service: IFMXTakenImageService;
  if
    TPlatformServices.Current.SupportsPlatformService(
      IFMXTakenImageService,
      Service
    )
  then
  begin
    // モバイル環境では IFMXTakenImageService を使って画像を取得
    var P: TParamsPhotoQuery;
    P.RequiredResolution := TSize.Create($ffff, $ffff);
    P.Editable := True;
    P.NeedSaveToAlbum := False;
    P.PickerPresentation := TPickerPresentation.Latest;
    P.OnDidFinishTaking := TakePhotoFinishHandler;
    P.OnDidCancelTaking := nil;
    P.OnDidFailTaking  := nil;

    ShowWaiter;
    try
      Service.TakeImageFromLibrary(nil, P);
      InitScrollBar;
    finally
      HideWaiter;
    end;
  end
  else
  begin
    // デスクトップ環境ではファイルダイアログで画像を取得
    if FIsDesktop and dlgOpen.Execute then
    begin
      ShowWaiter;
      mviewMenu.HideMaster;

      TThread.CreateAnonymousThread(
        procedure
        begin
          try
            imgImage.Bitmap.LoadFromFile(dlgOpen.FileName);
          finally
            TThread.Synchronize(
              nil,
              procedure
              begin
                InitScrollBar;
                HideWaiter;
              end
            );
          end;
        end
      ).Start;
    end;
  end;
end;

procedure TfrmMain.FileSaveClickHandler(Sender: TObject);
begin
  if not imgImage.Bitmap.IsEmpty then
  begin
    // デスクトップ環境では保存ダイアログで保存
    if FIsDesktop and dlgSave.Execute then
    begin
      ShowWaiter;
      try
        imgImage.Bitmap.SaveToFile(dlgSave.FileName);
      finally
        HideWaiter;
      end;
    end
    else
    begin
      // モバイル環境では Shared Pictures に保存
      ShowWaiter;

      TThread.CreateAnonymousThread(
        procedure
        begin
          try
            SaveBitmapToSharedFolder(
              imgImage.Bitmap,
              'MagicEraser'
            );
          finally
            TThread.Synchronize(
              nil,
              procedure
              begin
                HideWaiter;
              end
            );
          end;
        end
      ).Start;
    end;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
type
  TAlphaColorArray = array [0.. 0] of TAlphaColor;
  PAlphaColorArray = ^TAlphaColorArray;
const
  TRANS_COLORS: array [0.. 1] of TAlphaColor = ($ff_ff_ff_ff, $ff_cc_cc_cc);
begin
  // Permission の取得 (Android 11 未満の場合)
  RequestStorageAccess(
    '画像ファイルの読み書き用に権限が必要です',
    procedure(const ASuccess: Boolean)
    begin
      if not ASuccess then
      begin
        ShowErrorDialog(
          '終了します',
          procedure
          begin
            Close;
          end
        );
      end;
    end
  );

  // ダイアログのフィルター設定
  // Open と Save で同じフィルターを使う手抜き実装のため保存出来ない拡張子を削除
  dlgOpen.Filter := TBitmapCodecManager.GetDialogFilter(['ico', 'wbmp', 'hdp']);
  dlgSave.Filter := dlgOpen.Filter;
  layoutImageBase.AutoCapture := True;

  // 講師画像を作成
  FAlphaBitmap := TBitmap.Create(16, 16);

  var Data: TBitmapData;
  FAlphaBitmap.Map(TMapAccess.Write, Data);
  try
    for var Y := 0 to Data.Height - 1 do
    begin
      var Line := PAlphaColorArray(Data.GetScanline(Y));

      {$R-} 
      for var X := 0 to Data.Width - 1 do
        Line[X] := TRANS_COLORS[((X xor Y) and %0000_1000) shr 3];
    end;
  finally
    FAlphaBitmap.Unmap(Data);
  end;

  // TSkSVG をボタンぽく振る舞わせる TSVGButton を生成
  TSVGButton.Create(svgMVFileOpen, FileOpenClickHandler);
  TSVGButton.Create(svgMVFileSave, FileSaveClickHandler);
  TSVGButton.Create(svgMVOpMove, OpMoveClickHandler);
  TSVGButton.Create(svgMVOpEraser, OpEraserClickHandler);
  TSVGButton.Create(svgZoomOut, ZoomOutClickHandler);
  TSVGButton.Create(svgZoomIn, ZoomInClickHandler);

  // GUI を初期状態にする
  SetMVButtonVisible(mviewMenu.Presenter.Opened);
  SetTool(layoutOpMoveBase, TToolType.Move);
  InitScrollBar;

  // デスクトップかどうかを示すフラグ
  FIsDesktop :=
    TOSVersion.Platform in
    [
      TOSVersion.TPlatform.pfWindows,
      TOSVersion.TPlatform.pfMacOS,
      TOSVersion.TPlatform.pfLinux
    ];

  { // ドッキングビューにしたい場合はコメントアウト
  if FIsDesktop then
    mviewMenu.Mode := TMultiViewMode.Panel;
  }

  // iOS だけ Trackbar コントロールの外観が違うため補正
  {$IFDEF IOS}
  trackDiameter.Margins.Left := -24;
  {$ENDIF}

  HideWaiter;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // 講師画像を解放
  FAlphaBitmap.Free;
end;

procedure TfrmMain.FormKeyDown(
  Sender: TObject;
  var Key: Word;
  var KeyChar: WideChar;
  Shift: TShiftState);
begin
  // デスクトップ環境ではスペースキーを押しながらドラッグすると
  // キャンバスを移動できる
  FSpacePressed := FIsDesktop and (KeyChar = #32);

  if FSpacePressed then
    layoutImageBase.Cursor := crHandPoint;
end;

procedure TfrmMain.FormKeyUp(
  Sender: TObject;
  var Key: Word;
  var KeyChar: WideChar;
  Shift: TShiftState);
begin
  // スペースキーの解除
  FSpacePressed := False;

  if layoutImageBase.Cursor = crHandPoint then
    layoutImageBase.Cursor := crDefault;

  // バックキーが押された時の動作
  {$IFDEF ANDROID}
  if Key = vkHardwareBack then
  begin
    Key := 0;
    KeyChar := #0;

    if mviewMenu.Presenter.Opened then
      // ドロワーが開いていたら閉じる
      mviewMenu.HideMaster
    else
    begin
      // アプリを裏に回す
      TAndroidHelper.Activity.MoveTaskToBack(True);
    end;
  end;
  {$ENDIF}
end;

procedure TfrmMain.HideWaiter;
begin
  // 待機グルグルを非表示
  rectWaiterBase.Visible := False;
  aniWaitor.Enabled := False;
end;

procedure TfrmMain.InitScrollBar;
begin
  // スクロールバーを初期化
  scrollHBar.Value := 0;
  scrollVBar.Value := 0;
  SetZoomScale(1);
end;

procedure TfrmMain.layoutImageBaseGesture(
  Sender: TObject;
  const EventInfo: TGestureEventInfo;
  var Handled: Boolean);
begin
  // ピンチイン・アウトでズームイン・アウト
  if EventInfo.GestureID = igiZoom then
  begin
    if
      (not (TInteractiveGestureFlag.gfBegin in EventInfo.Flags))and
      (not (TInteractiveGestureFlag.gfEnd in EventInfo.Flags))
    then
    begin
      var WH := Max(imgImage.Width, imgImage.Height);
      var D := Max(WH + (EventInfo.Distance - FLastDistance), 10);
      SetZoomScale(FZoomScale * D / WH);
    end;
  end;

  // 二本指でドラッグで移動
  if EventInfo.GestureID = igiPan then
  begin
    if
      (not (TInteractiveGestureFlag.gfBegin in EventInfo.Flags))and
      (not (TInteractiveGestureFlag.gfEnd in EventInfo.Flags))
    then
    begin
      var DX := EventInfo.Location.X - FLastPos.X;
      var DY := EventInfo.Location.Y - FLastPos.Y;

      scrollHBar.Value :=
        EnsureRange(scrollHBar.Value + DX, scrollHBar.Min, scrollHBar.Max);

      scrollVBar.Value :=
        EnsureRange(scrollVBar.Value + DY, scrollVBar.Min, scrollVBar.Max);
    end;
  end;

  FLastDistance := EventInfo.Distance;
  FLastPos := EventInfo.Location;
end;

procedure TfrmMain.layoutImageBaseMouseDown(
  Sender: TObject;
  Button: TMouseButton;
  Shift: TShiftState;
  X, Y: Single);
begin
  // マウスダウンで移動・消しゴムの準備
  FHScrollbarValue := scrollHBar.Value;
  FVScrollbarValue := scrollVBar.Value;

  FScreenScale := Screen.DisplayFromForm(Self).Scale;
  FOldPos := CalcPos(X, Y);
  FDiameter := trackDiameter.Value;
end;

procedure TfrmMain.layoutImageBaseMouseMove(
  Sender: TObject;
  Shift: TShiftState;
  X, Y: Single);

  procedure DragImage;
  begin
    var Pos := layoutImageBase.PressedPosition;
    var DX := (X - Pos.X) / FScreenScale;
    var DY := (Y - Pos.Y) / FScreenScale;

    scrollHBar.Value := FHScrollbarValue - DX;
    scrollVBar.Value := FVScrollbarValue - DY;
  end;

begin
  if not layoutImageBase.Pressed then
    Exit;

  var Pos := CalcPos(X, Y);;

  // スペースキーが押されていたらモード関係なく移動
  if FSpacePressed then
    DragImage
  else
    case FTool of
      // 移動モードなら移動
      Move:
        DragImage;

      // 消しゴムモードならα格子を描く
      Eraser:
        if not imgImage.Bitmap.IsEmpty then
          with imgImage.Bitmap.Canvas do
          begin
            BeginScene;
            try
              Fill.Kind := TBrushKind.None;

              Stroke.Thickness := FDiameter;
              Stroke.Cap := TStrokeCap.Round;
              Stroke.Join := TStrokeJoin.Round;

              Stroke.Kind := TBrushKind.Bitmap;
              Stroke.Bitmap.Bitmap := FAlphaBitmap;

              DrawLine(FOldPos, Pos, 1);
            finally
              EndScene;
            end;
          end;
    end;

  FOldPos := Pos;
end;

procedure TfrmMain.layoutScrollBaseResize(Sender: TObject);
begin
  // キャンバスの大きさが変わったとき、スクロールバーの領域を変更
  scrollHBar.ViewportSize := layoutScrollBase.Width;
  scrollVBar.ViewportSize := layoutScrollBase.Height;
  SetImageSize;
end;

procedure TfrmMain.OpEraserClickHandler(Sender: TObject);
begin
  // 消しゴムに設定
  SetTool(layoutOpEraserBase, TToolType.Eraser);
end;

procedure TfrmMain.OpMoveClickHandler(Sender: TObject);
begin
  // 移動に設定
  SetTool(layoutOpMoveBase, TToolType.Move);
end;

procedure TfrmMain.scrollHBarChange(Sender: TObject);
begin
  // スクロールバーの移動に合せてイメージの位置を変更する
  SetImageSize;
end;

procedure TfrmMain.scrollVBarChange(Sender: TObject);
begin
  // スクロールバーの移動に合せてイメージの位置を変更する
  SetImageSize;
end;

procedure TfrmMain.SetImageSize;
begin
  if FSetImageSizeProcessing then
    Exit;

  // 拡大率とスクロールバーの位置に基づいて画像の位置・サイズを設定する
  FSetImageSizeProcessing := True;
  try
    var S := imgImage.Scene.GetSceneScale;
    var W := FZoomScale * imgImage.Bitmap.Width / S;
    var H := FZoomScale * imgImage.Bitmap.Height / S;

    scrollHBar.Max := W;
    scrollVBar.Max := H;

    scrollHBar.Visible := scrollHBar.ViewportSize < W;
    scrollVBar.Visible := scrollVBar.ViewportSize < H;

    if not scrollHBar.Visible then
      scrollHBar.Value := 0;

    if not scrollVBar.Visible then
      scrollVBar.Value := 0;

    imgImage.SetBounds(-scrollHBar.Value, -scrollVBar.Value, W, H);
  finally
    FSetImageSizeProcessing := False;
  end;
end;

procedure TfrmMain.SetMVButtonVisible(const AOpened: Boolean);
begin
  // ドロワーの開閉でアイコンを変更する
  svgTopClose.Visible := AOpened;
  svgTopOpen.Visible := not AOpened;
end;

procedure TfrmMain.SetTool(const ALayout: TLayout; const ATool: TToolType);
begin
  // 移動・消しゴムの選択と選択枠を移動
  FTool := ATool;
  rectSelector.Parent := ALayout;
end;

procedure TfrmMain.SetZoomScale(const AZoomScale: Single);
begin
  // 拡大率を変更
  FZoomScale := AZoomScale;
  SetImageSize;
  lblOpZoomBy.Text := Format('%.1f%%', [FZoomScale * 100]);
end;

procedure TfrmMain.ShowWaiter;
begin
  // 待機グルグルの表示
  rectWaiterBase.Visible := True;
  rectWaiterBase.Align := TAlignLayout.Contents;
  rectWaiterBase.BringToFront;
  aniWaitor.Enabled := True;
end;

procedure TfrmMain.TakePhotoFinishHandler(AImage: TBitmap);
begin
  // 画像取得ハンドラ
  imgImage.Bitmap.Assign(AImage);
  InitScrollBar;
  mviewMenu.HideMaster;
end;

procedure TfrmMain.ZoomInClickHandler(sender: TObject);
begin
  // 拡大
  SetZoomScale(FZoomScale * 2);
end;

procedure TfrmMain.ZoomOutClickHandler(Sender: TObject);
begin
  // 縮小
  SetZoomScale(FZoomScale / 2);
end;

end.
