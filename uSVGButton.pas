unit uSVGButton;

interface

uses
  System.SysUtils
  , System.Classes
  , FMX.Objects
  , FMX.Skia
  , FMX.Types
  , FMX.Ani
  ;

type
  TSVGButton = class(TNoRefCountObject, IFreeNotification)
  private var
    FSVG: TSkSVG;
    FCircle: TCircle;
    FAni: TFloatAnimation;
  private
    procedure FreeNotification(AObject: TObject);
    function GetOnClick: TNotifyEvent;
    procedure SetOnClick(const AValue: TNotifyEvent);
  public
    constructor Create(
      const ASVG: TSkSVG;
      const AOnClick: TNotifyEvent); reintroduce;
    destructor Destroy; override;
    property OnClick: TNotifyEvent read GetOnClick write SetOnClick;
  end;

implementation

uses
  System.UITypes
  , FMX.Graphics
  ;

{ TSVGButton }

constructor TSVGButton.Create(const ASVG: TSkSVG; const AOnClick: TNotifyEvent);
begin
  inherited Create;

  FSVG := ASVG;
  FSVG.AddFreeNotify(Self);

  FCircle := TCircle.Create(nil);
  FCircle.Stroke.Kind := TBrushKind.None;
  FCircle.Fill.Color := TAlphaColors.White;
  FCircle.Opacity := 0;
  FCircle.OnClick := AOnClick;
  FCircle.Align := TAlignLayout.Contents;

  FAni := TFloatAnimation.Create(nil);
  FAni.PropertyName := 'Opacity';
  FAni.Trigger := 'IsMouseOver=true';
  FAni.TriggerInverse := 'IsMouseOver=false';
  FAni.StartValue := 0;
  FAni.StopValue := 0.5;

  FAni.Parent := FCircle;
  FCircle.Parent := FSVG;
end;

destructor TSVGButton.Destroy;
begin
  FCircle.Free;

  inherited;
end;

procedure TSVGButton.FreeNotification(AObject: TObject);
begin
  FSVG.RemoveFreeNotify(Self);
  Free;
end;

function TSVGButton.GetOnClick: TNotifyEvent;
begin
  Result := FCircle.OnClick;
end;

procedure TSVGButton.SetOnClick(const AValue: TNotifyEvent);
begin
  FCircle.OnClick := AValue;
end;

end.
