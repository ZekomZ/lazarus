{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

  Author: Maciej Izak

  DaThoX 2004-2015
  FreeSparta.com
}

unit sparta_FakeForm;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, TypInfo, LCLIntf,
  LCLType, sparta_DesignedForm, sparta_FakeCustom;


const
  BorderStylesAllowAutoScroll = [bsSizeable, bsSizeToolWin];

type
  { TFakeForm }

  TFakeForm = class(TFakeCustomForm, IDesignedFakeForm)
  private
    FHackAlign: TAlign;
    FHackAnchors: TAnchors;
    FHackVisible: Boolean;
    FHackAutoScroll: Boolean;
    FHackBorderStyle: TFormBorderStyle;
    FHackBorderIcons: TBorderIcons;
    FHackFormStyle: TFormStyle;

    FPopupMode: TPopupMode;
    FPopupParent: TCustomForm;

    FHorzScrollBar: TControlScrollBar;
    FVertScrollBar: TControlScrollBar;

    FControlForHackedConstraints: TControl;
    FHackConstraints: TSizeConstraints;

    function IsAnchorsStored: Boolean;
    function IsAutoScrollStored: Boolean;
    procedure SetAlign(Value: TAlign);
    procedure SetAnchors(const AValue: TAnchors);
    procedure SetHorzScrollBar(AValue: TControlScrollBar);
    procedure SetVertScrollBar(AValue: TControlScrollBar);
    procedure SetPopupMode(const AValue: TPopupMode);
    procedure SetPopupParent(const AValue: TCustomForm);

    procedure SetFormBorderStyle(ANewStyle: TFormBorderStyle);
    procedure SetBorderIcons(AVal: TBorderIcons);
    procedure SetFormStyle(AValue : TFormStyle);
    procedure SetCaption(const AValue: string);
    function GetBorderStyle: TFormBorderStyle;
    function GetBorderIcons: TBorderIcons;
    function GetFormStyle: TFormStyle;
    function GetCaption: string;
  public
    property RealPopupMode: TPopupMode read GetRealPopupMode write SetRealPopupMode;
    property RealPopupParent: TCustomForm read GetRealPopupParent write SetRealPopupParent;

    constructor CreateNew(AOwner: TComponent; Num: Integer = 0); override;
    destructor Destroy; override;
  published
    property Align: TAlign read FHackAlign write SetAlign default alNone;
    property Anchors: TAnchors read FHackAnchors write SetAnchors stored IsAnchorsStored default [akLeft, akTop];
    property AutoScroll: Boolean read FHackAutoScroll write FHackAutoScroll stored IsAutoScrollStored default False;
    property BorderIcons: TBorderIcons read GetBorderIcons write SetBorderIcons default [biSystemMenu, biMinimize, biMaximize];
    property BorderStyle: TFormBorderStyle read GetBorderStyle write SetFormBorderStyle default bsSizeable;
    property FormStyle: TFormStyle read GetFormStyle write SetFormStyle default fsNormal;

    property PopupMode: TPopupMode read FPopupMode write SetPopupMode default pmNone;
    property PopupParent: TCustomForm read FPopupParent write SetPopupParent;

    property HorzScrollBar: TControlScrollBar read FHorzScrollBar write SetHorzScrollBar;
    property VertScrollBar: TControlScrollBar read FVertScrollBar write SetVertScrollBar;

    property Constraints: TSizeConstraints read FHackConstraints write FHackConstraints;
    property Caption: string read GetCaption write SetCaption;
    property Visible: boolean read FHackVisible write FHackVisible;
  end;

implementation

{ TFakeForm }

procedure TFakeForm.SetHorzScrollBar(AValue: TControlScrollBar);
begin
  FHorzScrollBar.Assign(AValue);
end;

function TFakeForm.IsAutoScrollStored: Boolean;
begin
  Result := BorderStyle in BorderStylesAllowAutoScroll;
end;

function TFakeForm.IsAnchorsStored: Boolean;
begin
  Result:=(Anchors<>AnchorAlign[Align]);
end;

procedure TFakeForm.SetAlign(Value: TAlign);
var
  OldAlign: TAlign;
  a: TAnchorKind;
begin
  if FHackAlign = Value then exit;
  OldAlign := FHackAlign;
  FHackAlign := Value;
  if (not (csLoading in ComponentState))
  and (Align in [alLeft,alTop,alRight,alBottom,alClient]) then begin
    // Align for alLeft,alTop,alRight,alBottom,alClient takes precedence
    // over AnchorSides => clean up
    for a:=low(TAnchorKind) to High(TAnchorKind) do
    begin
      if not (a in AnchorAlign[FHackAlign]) then continue;
      AnchorSide[a].Control:=nil;
      AnchorSide[a].Side:=asrTop;
    end;
  end;

  // Notes:
  // - if anchors had default values then change them to new default values
  //   This is done for Delphi compatibility.
  // - Anchors are not stored if they are AnchorAlign[Align]
  if (Anchors = AnchorAlign[OldAlign]) and (Anchors <> AnchorAlign[FHackAlign]) then
    Anchors := AnchorAlign[FHackAlign];
end;

procedure TFakeForm.SetAnchors(const AValue: TAnchors);
var
  NewAnchors: TAnchors;
  a: TAnchorKind;
begin
  if Anchors = AValue then Exit;
  NewAnchors:=AValue-FHackAnchors;
  FHackAnchors := AValue;
  for a:=Low(TAnchorKind) to high(TAnchorKind) do
    if (a in NewAnchors) and (AnchorSide[a].Side=asrCenter) then
      AnchorSide[a].FixCenterAnchoring;
end;

procedure TFakeForm.SetFormBorderStyle(ANewStyle: TFormBorderStyle);
begin
  if FHackBorderStyle = ANewStyle then exit;

  if not (ANewStyle in BorderStylesAllowAutoScroll) then
    AutoScroll := False;

  FHackBorderStyle := ANewStyle;
end;

procedure TFakeForm.SetBorderIcons(AVal: TBorderIcons);
begin
  FHackBorderIcons := AVal;
end;

procedure TFakeForm.SetFormStyle(AValue: TFormStyle);
var
  LHackFormStyle: TFormStyle;
Begin
  if FHackFormStyle = AValue then
    exit;

  LHackFormStyle := FHackFormStyle;
  FHackFormStyle := AValue;

  if FHackFormStyle = fsSplash then
    BorderStyle := bsNone
  else
  if LHackFormStyle = fsSplash then
    BorderStyle := bsSizeable;
end;

procedure TFakeForm.SetCaption(const AValue: string);
begin
  inherited Caption := AValue;
end;

procedure TFakeForm.SetPopupMode(const AValue: TPopupMode);
begin
  if FPopupMode <> AValue then
  begin
    FPopupMode := AValue;
    if FPopupMode = pmAuto then
      PopupParent := nil;
  end;
end;

procedure TFakeForm.SetPopupParent(const AValue: TCustomForm);
begin
  if FPopupParent <> AValue then
  begin
    if FPopupParent <> nil then
      FPopupParent.RemoveFreeNotification(Self);
    FPopupParent := AValue;
    if FPopupParent <> nil then
    begin
      FPopupParent.FreeNotification(Self);
      FPopupMode := pmExplicit;
    end;
  end;
end;


function TFakeForm.GetBorderStyle: TFormBorderStyle;
begin
  Result := FHackBorderStyle;
end;

function TFakeForm.GetBorderIcons: TBorderIcons;
begin
  Result := FHackBorderIcons;
end;

function TFakeForm.GetFormStyle: TFormStyle;
begin
  Result := FHackFormStyle;
end;

function TFakeForm.GetCaption: string;
begin
  Result := inherited Caption;
end;

procedure TFakeForm.SetVertScrollBar(AValue: TControlScrollBar);
begin
  FVertScrollBar.Assign(AValue);
end;

constructor TFakeForm.CreateNew(AOwner: TComponent; Num: Integer);
begin
  inherited CreateNew(AOwner, Num);

  FHorzScrollBar := TControlScrollBar.Create(Self, sbHorizontal);
  FVertScrollBar := TControlScrollBar.Create(Self, sbVertical);

  BorderIcons := inherited BorderIcons;
  BorderStyle := inherited BorderStyle;
  FormStyle   := inherited FormStyle;

  PopupMode := inherited PopupMode;

  FControlForHackedConstraints := TControl.Create(nil);
  FHackConstraints := TSizeConstraints.Create(FControlForHackedConstraints);

  FHackAnchors := [akLeft,akTop];
  FHackAlign := alNone;
end;

destructor TFakeForm.Destroy;
begin
  FHorzScrollBar.Free;
  FVertScrollBar.Free;

  FHackConstraints.Free;
  FControlForHackedConstraints.Free;

  inherited Destroy;
end;

end.

