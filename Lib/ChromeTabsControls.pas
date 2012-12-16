unit ChromeTabsControls;

// The contents of this file are subject to the Mozilla Public License
// Version 1.1 (the "License"); you may not use this file except in compliance
// with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/
//
// Alternatively, you may redistribute this library, use and/or modify it under the terms of the
// GNU Lesser General Public License as published by the Free Software Foundation;
// either version 2.1 of the License, or (at your option) any later version.
// You may obtain a copy of the LGPL at http://www.gnu.org/copyleft/.
//
// Software distributed under the License is distributed on an "AS IS" basis,
// WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the
// specific language governing rights and limitations under the License.
//
// The original code is ChromeTabs.pas, released December 2012.
//
// The initial developer of the original code is Easy-IP AS (Oslo, Norway, www.easy-ip.net),
// written by Paul Spencer Thornton (paul.thornton@easy-ip.net, www.easy-ip.net).
//
// Portions created by Easy-IP AS are Copyright
// (C) 2012 Easy-IP AS. All Rights Reserved.

interface

uses
  Windows, Classes, Controls, SysUtils, ImgList, Graphics,

  GDIPObj, GDIPAPI,

  ChromeTabsTypes,
  ChromeTabsUtils,
  ChromeTabsClasses;

type
  TBaseChromeTabsControl = class(TObject)
  private
    FControlRect: TRect;
    FChromeTabs: IChromeTabs;
    FDrawState: TDrawState;
    FDestinationRect: TRect;
    FAnimationIncrements: TRect;
    FPositionInitialised: Boolean;
    FScrollableControl: Boolean;
    FOverrideBidi: Boolean;

    function GetBidiControlRect: TRect;
  protected
    FInvalidated: Boolean;
    FControlType: TChromeTabItemType;

    procedure DoChanged; virtual;

    procedure SetAnimationIncrements(SourceRect, DestinationRect: TRect); virtual;
    procedure EndAnimation; virtual;
    function NewPolygon(ControlRect: TRect; const Polygon: array of TPoint; Orientation: TTabOrientation): TPolygon; virtual;
    procedure Invalidate; virtual;
    function ScrollRect(ARect: TRect): TRect;
    function BidiRect(ARect: TRect): TRect;
    function BidiPolygon(Polygon: TPolygon): TPolygon;

    property ChromeTabs: IChromeTabs read FChromeTabs;
  public
    constructor Create(ChromeTabs: IChromeTabs); virtual;

    procedure DrawTo(TabCanvas: TGPGraphics; CanvasBmp, BackgroundBmp: TBitmap; MouseX, MouseY: Integer); virtual; abstract;

    function GetPolygons: IChromeTabPolygons; virtual;
    function Animate: Boolean; virtual;
    function Animating: Boolean; virtual;
    function ControlRectScrolled: TRect; virtual;
    function ContainsPoint(Pt: TPoint): Boolean; virtual;

    property ControlRect: TRect read FControlRect;
    property BiDiControlRect: TRect read GetBidiControlRect;
    property DestinationRect: TRect read FDestinationRect;

    procedure SetDrawState(const Value: TDrawState; Animate: Boolean; AnimationSteps: Integer; ForceUpdate: Boolean = FALSE); virtual;
    procedure SetPosition(ARect: TRect; Animate: Boolean); virtual;
    procedure SetHeight(const Value: Integer; Animate: Boolean); virtual;
    procedure SetWidth(const Value: Integer; Animate: Boolean); virtual;
    procedure SetLeft(const Value: Integer; Animate: Boolean); virtual;
    procedure SetTop(const Value: Integer; Animate: Boolean); virtual;

    property DrawState: TDrawState read FDrawState;
    property ControlType: TChromeTabItemType read FControlType;
    property ScrollableControl: Boolean read FScrollableControl write FScrollableControl;
    property OverrideBidi: Boolean read FOverrideBidi write FOverrideBidi;
  end;

  TChromeTabControlProperties = record
    FontColor: TColor;
    FontAlpha: Byte;
    FontName: String;
    FontSize: Integer;
    TextRendoringMode: TTextRenderingHint;
    StartColor: TColor;
    StopColor: TColor;
    OutlineColor: TColor;
    OutlineSize: Single;
    OutlineAlpha: Integer;
    StartAlpha: Integer;
    StopAlpha: Integer;
  end;

  TChromeTabControlPropertyItems = class
  private
    FTransformPercent: Integer;
    FAnimationSteps: Integer;
    FStartTabProperties: TChromeTabControlProperties;
    FStopTabProperties: TChromeTabControlProperties;
    FCurrentTabProperties: TChromeTabControlProperties;
  public
    procedure SetProperties(Style: TChromeTabsLookAndFeelStyle; StyleFont: TChromeTabsLookAndFeelFont; DefaultFont: TChromeTabsLookAndFeelBaseFont; AnimationSteps: Integer; Animate: Boolean);
    function TransformColors: Boolean;

    property StartTabProperties: TChromeTabControlProperties read FStartTabProperties write FStartTabProperties;
    property StopTabProperties: TChromeTabControlProperties read FStopTabProperties write FStopTabProperties;
    property CurrentTabProperties: TChromeTabControlProperties read FCurrentTabProperties write FCurrentTabProperties;
    property TransformPercent: Integer read FTransformPercent write FTransformPercent;
    property AnimationSteps: Integer read FAnimationSteps write FAnimationSteps;
  end;

  TBaseChromeButtonControl = class(TBaseChromeTabsControl)
  private
    FButtonBrush: TGPLinearGradientBrush;
    FButtonPen: TGPPen;
    FSymbolBrush: TGPLinearGradientBrush;
    FSymbolPen: TGPPen;
  protected
    FButtonControlPropertyItems: TChromeTabControlPropertyItems;
    FSymbolControlPropertyItems: TChromeTabControlPropertyItems;

    FButtonStyle: TChromeTabsLookAndFeelStyle;
    FSymbolStyle: TChromeTabsLookAndFeelStyle;

    function GetButtonBrush: TGPLinearGradientBrush; virtual;
    function GetButtonPen: TGPPen; virtual;
    function GetSymbolBrush: TGPLinearGradientBrush; virtual;
    function GetSymbolPen: TGPPen; virtual;

    procedure SetStylePropertyClasses; virtual;
  public
    constructor Create(ChromeTabs: IChromeTabs); override;
    destructor Destroy; override;

    function Animate: Boolean; override;
    function Animating: Boolean; override;

    procedure SetDrawState(const Value: TDrawState; Animate: Boolean; AnimationSteps: Integer; ForceUpdate: Boolean = FALSE); override;
  end;

  TChromeTabControl = class(TBaseChromeTabsControl)
  private
    FChromeTab: IChromeTab;
    FBmp: TBitmap;
    FCloseButtonState: TDrawState;
    FChromeTabControlPropertyItems: TChromeTabControlPropertyItems;
    FTabProperties: TChromeTabsLookAndFeelStyleProperties;
    FTabBrush: TGPLinearGradientBrush;
    FTabPen: TGPPen;
    FModifiedPosition: Integer;
    FModifiedMovingLeft: Boolean;
    FPenInvalidated: Boolean;
    FBrushInvalidated: Boolean;
    FCloseButtonInvalidate: Boolean;

    function CloseButtonVisible: Boolean;
    function GetTabBrush: TGPLinearGradientBrush;
    function GetTabPen: TGPPen;
    function ImageVisible(ImageList: TCustomImageList; ImageIndex: Integer): Boolean;
    function AnimateModified: Boolean;
    function GetModifiedGlowX: Integer;
  protected
    procedure SetCloseButtonState(const Value: TDrawState); virtual;
    procedure EndAnimation; override;

    property ChromeTab: IChromeTab read FChromeTab;
  public
    constructor Create(ChromeTabs: IChromeTabs; TabInterface: IChromeTab); reintroduce;
    destructor Destroy; override;

    procedure Invalidate; override;
    function Animate: Boolean; override;
    function Animating: Boolean; override;
    procedure DrawTo(TabCanvas: TGPGraphics; CanvasBmp, BackgroundBmp: TBitmap; MouseX, MouseY: Integer); override;
    function GetPolygons: IChromeTabPolygons; override;
    function GetHitTestArea(MouseX, MouseY: Integer): THitTestArea;
    function GetCloseButonRect: TRect;
    function GetCloseButtonCrossRect: TRect;
    procedure SetDrawState(const Value: TDrawState; Animate: Boolean; AnimationSteps: Integer; ForceUpdate: Boolean = FALSE); override;

    property CloseButtonState: TDrawState read FCloseButtonState write SetCloseButtonState;
  end;

  TAddButtonControl = class(TBaseChromeButtonControl)
  protected
    procedure SetStylePropertyClasses; override;
  public
    constructor Create(ChromeTabs: IChromeTabs); override;

    procedure DrawTo(TabCanvas: TGPGraphics; CanvasBmp, BackgroundBmp: TBitmap; MouseX, MouseY: Integer); override;
    function GetPolygons: IChromeTabPolygons; override;
  end;

  TScrollButtonControl = class(TBaseChromeButtonControl)
  protected
    procedure SetStylePropertyClasses; override;
    function GetArrowPolygons(Direction: TChromeTabDirection): IChromeTabPolygons;
  public
    procedure DrawTo(TabCanvas: TGPGraphics; CanvasBmp, BackgroundBmp: TBitmap; MouseX, MouseY: Integer); override;
  end;

  TScrollButtonLeftControl = class(TScrollButtonControl)
  public
    constructor Create(ChromeTabs: IChromeTabs); override;

    procedure DrawTo(TabCanvas: TGPGraphics; CanvasBmp, BackgroundBmp: TBitmap; MouseX, MouseY: Integer); override;
    function GetPolygons: IChromeTabPolygons; override;
  end;

  TScrollButtonRightControl = class(TScrollButtonControl)
  public
    constructor Create(ChromeTabs: IChromeTabs); override;

    procedure DrawTo(TabCanvas: TGPGraphics; CanvasBmp, BackgroundBmp: TBitmap; MouseX, MouseY: Integer); override;
    function GetPolygons: IChromeTabPolygons; override;
  end;

implementation

{ TBaseChromeTabControl }

function TBaseChromeTabsControl.ScrollRect(ARect: TRect): TRect;
begin
  if FScrollableControl then
    Result := ChromeTabs.ScrollRect(ARect)
  else
    Result := ARect;
end;

function TBaseChromeTabsControl.BidiPolygon(Polygon: TPolygon): TPolygon;
begin
  if ChromeTabs.GetBiDiMode in [bdRightToLeftNoAlign, bdRightToLeftReadingOnly] then
    Result := HorzFlipPolygon(BidiControlRect, Polygon)
  else
    Result := Polygon;
end;

function TBaseChromeTabsControl.BidiRect(ARect: TRect): TRect;
begin
  if ChromeTabs.GetBiDiMode in [bdRightToLeftNoAlign, bdRightToLeftReadingOnly] then
    Result := HorzFlipRect(BidiControlRect, HorzFlipRect(BidiControlRect, ChromeTabs.BidiRect(ARect)))
  else
    Result := ARect;
end;

function TBaseChromeTabsControl.NewPolygon(ControlRect: TRect; const Polygon: Array of TPoint; Orientation: TTabOrientation): TPolygon;
var
  ScrolledRect: TRect;
begin
  ScrolledRect := ScrollRect(ControlRect);

  Result := GeneratePolygon(ScrolledRect, Polygon, Orientation);
end;

function TBaseChromeTabsControl.Animate: Boolean;

  procedure TransformPoint(Current, Destination, AnimationStep: Integer; var Value: Integer);
  begin
    if Current = Destination then
      Value := Current
    else
    begin
      Result := TRUE;

      Value := Current + AnimationStep;

      if ((Current > Destination) and
          (Value < Destination)) or
         ((Current < Destination) and
          (Value > Destination)) then
      begin
        Value := Destination;
      end;
    end;
  end;

var
  Right, Left, Top, Bottom: Integer;
begin
  Result := FALSE;

  if Animating then
  begin
    TransformPoint(ControlRect.Left, FDestinationRect.Left, FAnimationIncrements.Left, Left);
    TransformPoint(ControlRect.Right, FDestinationRect.Right, FAnimationIncrements.Right, Right);
    TransformPoint(ControlRect.Top, FDestinationRect.Top, FAnimationIncrements.Top, Top);
    TransformPoint(ControlRect.Bottom, FDestinationRect.Bottom, FAnimationIncrements.Bottom, Bottom);

    FControlRect := Rect(Left, Top, Right, Bottom);
  end;
end;

function TBaseChromeTabsControl.Animating: Boolean;
begin
  Result := not SameRect(FControlRect, FDestinationRect);
end;

function TBaseChromeTabsControl.ContainsPoint(Pt: TPoint): Boolean;
var
  i: Integer;
  ChromeTabPolygons: IChromeTabPolygons;
begin
  Result := FALSE;

  ChromeTabPolygons := GetPolygons;

  for i := 0 to pred(ChromeTabPolygons.PolygonCount) do
    if PointInPolygon(ChromeTabPolygons.Polygons[i].Polygon, Pt.X, Pt.Y) then
    begin
      Result := TRUE;

      Break;
    end;
end;

function TBaseChromeTabsControl.ControlRectScrolled: TRect;
begin
  Result := ChromeTabs.ScrollRect(ControlRect);
end;

constructor TBaseChromeTabsControl.Create(
  ChromeTabs: IChromeTabs);
begin
  FChromeTabs := ChromeTabs;

  FPositionInitialised := FALSE;
  FScrollableControl := FALSE;
end;

procedure TBaseChromeTabsControl.DoChanged;
begin
  FChromeTabs.DoOnChange(nil, tcControlState);
end;

procedure TBaseChromeTabsControl.EndAnimation;
begin
  // Override if required
end;

function TBaseChromeTabsControl.GetBidiControlRect: TRect;
begin
  if FOverrideBidi then
    REsult := FControlRect
  else
    Result := ChromeTabs.BidiRect(FControlRect);
end;

function TBaseChromeTabsControl.GetPolygons: IChromeTabPolygons;
begin
  ChromeTabs.DoOnGetControlPolygons(ControlRect, FControlType, ChromeTabs.GetOptions.Display.Tabs.Orientation, Result);
end;

procedure TBaseChromeTabsControl.Invalidate;
begin
  FInvalidated := TRUE;
end;

procedure TBaseChromeTabsControl.SetDrawState(const Value: TDrawState; Animate: Boolean; AnimationSteps: Integer; ForceUpdate: Boolean);
begin
  // Override in descendants if animation is required
  if (ForceUpdate) or (FDrawState <> Value) then
  begin
    FDrawState := Value;

    DoChanged;
    //Invalidate;
  end;
end;

procedure TBaseChromeTabsControl.SetHeight(const Value: Integer; Animate: Boolean);
begin
  SetPosition(Rect(FControlRect.Left,
                   FControlRect.Top,
                   FControlRect.Right,
                   FControlRect.Top + Value),
              Animate);
end;

procedure TBaseChromeTabsControl.SetLeft(const Value: Integer; Animate: Boolean);
begin
  SetPosition(Rect(Value,
                   FControlRect.Top,
                   RectWidth(FControlRect) + Value,
                   FControlRect.Bottom),
              Animate);
end;

procedure TBaseChromeTabsControl.SetWidth(const Value: Integer; Animate: Boolean);
begin
  SetPosition(Rect(FControlRect.Left,
                   FControlRect.Top,
                   FControlRect.Left + Value,
                   FControlRect.Bottom),
              Animate);
end;

procedure TBaseChromeTabsControl.SetTop(const Value: Integer; Animate: Boolean);
begin
  SetPosition(Rect(FControlRect.Left,
                   Value,
                   FControlRect.Right,
                   RectHeight(FControlRect) + Value),
              Animate);
end;

procedure TBaseChromeTabsControl.SetPosition(ARect: TRect; Animate: Boolean);
begin
  if (FPositionInitialised) and
     (Animate) then
  begin
    // If we want to animate, or we are curently animating,
    // set the destination Rect and calculate the animation increments
    if not SameRect(FDestinationRect, ARect) then
    begin
      FDestinationRect := ARect;

      SetAnimationIncrements(FControlRect, FDestinationRect);
    end;
  end
  else
  begin
    // Set the flag to indicate that we're set the initial position
    FPositionInitialised := TRUE;

    if Animating then
      EndAnimation;

    // Otherwise, set the destination Rect
    FControlRect := ARect;
    FDestinationRect := ARect;

    SetAnimationIncrements(FControlRect, FDestinationRect);
  end;
end;

procedure TBaseChromeTabsControl.SetAnimationIncrements(SourceRect, DestinationRect: TRect);

  function GetIncrement(Source, Destination: Integer): Integer;
  var
    Distance: Integer;
  begin
    Distance := Destination - Source;

    if Distance = 0 then
      Result := 0
    else
    begin
      Result := Distance div ChromeTabs.GetOptions.Animation.AnimationMovementIncrement;

      if Abs(Result) < 5 then
      begin
        if Distance < 0 then
          Result := -5
        else
          Result := 5;
      end;
    end;
  end;

begin
  FAnimationIncrements := Rect(GetIncrement(SourceRect.Left, DestinationRect.Left),
                               GetIncrement(SourceRect.Top, DestinationRect.Top),
                               GetIncrement(SourceRect.Right, DestinationRect.Right),
                               GetIncrement(SourceRect.Bottom, DestinationRect.Bottom));
end;


{ TrkAddButton }

function TAddButtonControl.GetPolygons: IChromeTabPolygons;
var
  LeftOffset, TopOffset: Integer;
  Brush: TGPBrush;
begin
  Result := inherited GetPolygons;

  if Result = nil then
  begin
    Result := TChromeTabPolygons.Create;

    Brush := GetButtonBrush;

    Result.AddPolygon(BidiPolygon(
                      NewPolygon(BidiControlRect, [Point(7, RectHeight(BidiControlRect)),
                                 Point(4, RectHeight(BidiControlRect) - 2),
                                 Point(0, 2),
                                 Point(1, 0),
                                 Point(RectWidth(BidiControlRect) - 7, 0),
                                 Point(RectWidth(BidiControlRect) - 4, 2),
                                 Point(RectWidth(BidiControlRect), RectHeight(BidiControlRect) - 2),
                                 Point(RectWidth(BidiControlRect), RectHeight(BidiControlRect))],
                      ChromeTabs.GetOptions.Display.Tabs.Orientation)),
                      Brush,
                      GetButtonPen);

    if ChromeTabs.GetOptions.Display.AddButton.ShowPlusSign then
    begin

      LeftOffset := (ChromeTabs.GetOptions.Display.AddButton.Width div 2) - 4;
      TopOffset := (ChromeTabs.GetOptions.Display.AddButton.Height div 2) - 4;

      Result.AddPolygon(BidiPolygon(
                        NewPolygon(Rect(BidiControlRect.Left + LeftOffset,
                                   BidiControlRect.Top + TopOffset,
                                   BidiControlRect.Right - LeftOffset,
                                   BidiControlRect.Bottom - TopOffset),
                                  [Point(0, 3),
                                   Point(3, 3),
                                   Point(3, 0),
                                   Point(6, 0),
                                   Point(6, 3),
                                   Point(9, 3),
                                   Point(9, 6),
                                   Point(6, 6),
                                   Point(6, 9),
                                   Point(3, 9),
                                   Point(3, 6),
                                   Point(0, 6),
                                   Point(0, 3)],
                               ChromeTabs.GetOptions.Display.Tabs.Orientation)),
                               GetSymbolBrush,
                               GetSymbolPen);
    end;
  end;
end;

procedure TAddButtonControl.SetStylePropertyClasses;
begin
  case FDrawState of
    dsDown:
      begin
        FButtonStyle := ChromeTabs.GetLookAndFeel.AddButton.Button.Down;
        FSymbolStyle := ChromeTabs.GetLookAndFeel.AddButton.PlusSign.Down;
      end;

    dsHot:
      begin
        FButtonStyle := ChromeTabs.GetLookAndFeel.AddButton.Button.Hot;
        FSymbolStyle := ChromeTabs.GetLookAndFeel.AddButton.PlusSign.Hot;
      end
  else
    begin
      FButtonStyle := ChromeTabs.GetLookAndFeel.AddButton.Button.Normal;
      FSymbolStyle := ChromeTabs.GetLookAndFeel.AddButton.PlusSign.Normal;
    end;
  end;
end;

constructor TAddButtonControl.Create(ChromeTabs: IChromeTabs);
begin
  inherited Create(ChromeTabs);

  FControlType := itAddButton;

  FButtonStyle := ChromeTabs.GetLookAndFeel.AddButton.Button.Normal;
  FSymbolStyle := ChromeTabs.GetLookAndFeel.AddButton.PlusSign.Normal;
end;

procedure TAddButtonControl.DrawTo(TabCanvas: TGPGraphics; CanvasBmp, BackgroundBmp: TBitmap; MouseX, MouseY: Integer);
var
  Handled: Boolean;
begin
  ChromeTabs.DoOnBeforeDrawItem(TabCanvas, ControlRect, itAddButton, -1, Handled);

  if not Handled then
    GetPolygons.DrawTo(TabCanvas);

  ChromeTabs.DoOnAfterDrawItem(TabCanvas, ControlRect, itAddButton, -1);
end;


{ TChromeTabControl }

constructor TChromeTabControl.Create(ChromeTabs: IChromeTabs; TabInterface: IChromeTab);
begin
  inherited Create(ChromeTabs);

  FChromeTabControlPropertyItems := TChromeTabControlPropertyItems.Create;

  FBmp := TBitmap.Create;
  FBmp.PixelFormat := pf32Bit;

  FControlType := itTab;

  FChromeTab := TabInterface;

  FScrollableControl := TRUE;
end;

destructor TChromeTabControl.Destroy;
begin
  FreeAndNil(FBmp);
  FreeAndNil(FChromeTabControlPropertyItems);

  inherited;
end;

function TChromeTabControl.GetHitTestArea(MouseX, MouseY: Integer): THitTestArea;
var
  TabPolygon: IChromeTabPolygons;
  CloseRect: TRect;
  i: Integer;
begin
  TabPolygon := GetPolygons;

  Result := htBackground;

  if CloseButtonVisible then
  begin
    CloseRect := ChromeTabs.ScrollRect(BidiRect(GetCloseButonRect));

    if PtInRect(CloseRect, Point(MouseX, MouseY)) then
    begin
      Result := htCloseButton;

      Exit;
    end;
  end;

  for i := 0 to pred(TabPolygon.PolygonCount) do
  begin
    if PointInPolygon(TabPolygon.Polygons[i].Polygon, MouseX, MouseY) then
    begin
      Result := htTab;

      Break;
    end;
  end;
end;

function TChromeTabControl.GetModifiedGlowX: Integer;
var
  LowX, HighX: Integer;
  ScrolledRect: TRect;
  //SinValue: Extended;
begin
  ScrolledRect := ScrollRect(ControlRect);

  LowX := ScrolledRect.Left - ChromeTabs.GetOptions.Display.TabModifiedGlow.Width;
  HighX := ScrolledRect.Right;

  Result := Round((((HighX - LowX) / ChromeTabs.GetOptions.Display.TabModifiedGlow.AnimationSteps) * FModifiedPosition) + LowX);

  //SinValue := Sin(Pi / (ChromeTabs.GetOptions.Display.ModifiedTabGlow.AnimationSteps * 2)) * FModifiedPosition;

  //Result := Round(LowX + (((HighX - LowX) * SinValue)));
end;

function TChromeTabControl.AnimateModified: Boolean;
begin
  Result := (FChromeTab.GetModified) and
            (ChromeTabs.GetOptions.Display.TabModifiedGlow.Style <> msNone);

  if Result then
  begin
    case ChromeTabs.GetOptions.Display.TabModifiedGlow.Style of
      msLeftToRight:
        begin
          Inc(FModifiedPosition);

          if FModifiedPosition > ChromeTabs.GetOptions.Display.TabModifiedGlow.AnimationSteps then
            FModifiedPosition := 0;
        end;

      msRightToLeft:
        begin
          Dec(FModifiedPosition);

          if FModifiedPosition < 0 then
            FModifiedPosition := ChromeTabs.GetOptions.Display.TabModifiedGlow.AnimationSteps;
        end;

      msKnightRider:
        begin
          if FModifiedMovingLeft then
            Dec(FModifiedPosition)
          else
            Inc(FModifiedPosition);

          if (FModifiedPosition < 0) or
             (FModifiedPosition > ChromeTabs.GetOptions.Display.TabModifiedGlow.AnimationSteps) then
            FModifiedMovingLeft := not FModifiedMovingLeft;
        end;
    end;
  end;
end;

function TChromeTabControl.Animate: Boolean;
begin
  Result := inherited Animate;

  Result := FChromeTabControlPropertyItems.TransformColors or Result;

  Result := AnimateModified or Result;

  if Result then
    Invalidate;
end;

function TChromeTabControl.Animating: Boolean;
begin
  Result := inherited Animating or (FChromeTabControlPropertyItems.TransformPercent <> 100) or (FChromeTab.GetModified);
end;

function TChromeTabControl.CloseButtonVisible: Boolean;
begin
  if (not ChromeTab.GetActive) and
     (RectWidth(ControlRect) -
      ChromeTabs.GetOptions.Display.Tabs.ContentOffsetRight -
      ChromeTabs.GetOptions.Display.Tabs.ContentOffsetLeft <= ChromeTabs.GetOptions.Display.CloseButton.AutoHideWidth) then
    Result := FALSE
  else
  begin
    case ChromeTabs.GetOptions.Display.CloseButton.Visibility of
      bvAll: Result := not ChromeTab.GetPinned;
      bvActive: Result := (not ChromeTab.GetPinned) and (FDrawState = dsActive);
    else
      Result := FALSE;
    end;
  end;
end;

function TChromeTabControl.ImageVisible(ImageList: TCustomImageList; ImageIndex: Integer): Boolean;
begin
  Result := (ChromeTabs.GetOptions.Display.Tabs.ShowImages) and
            (ImageList <> nil) and
            (ImageIndex >= 0) and
            (ImageIndex < ImageList.Count);
end;

procedure TChromeTabControl.Invalidate;
begin
  inherited;

  FPenInvalidated := TRUE;
  FBrushInvalidated := TRUE;
  FCloseButtonInvalidate := TRUE;
end;

function TChromeTabControl.GetPolygons: IChromeTabPolygons;
begin
  Result := inherited GetPolygons;

  if Result = nil then
  begin
    Result := TChromeTabPolygons.Create;

    Result.AddPolygon(NewPolygon(BidiControlRect, [Point(0, RectHeight(ControlRect)),
                                       Point(4, RectHeight(ControlRect) - 3),
                                       Point(12, 3),
                                       Point(13, 2),
                                       Point(14, 1),
                                       Point(16, 0),
                                       Point(RectWidth(ControlRect) - 16, 0),
                                       Point(RectWidth(ControlRect) - 14, 1),
                                       Point(RectWidth(ControlRect) - 13, 2),
                                       Point(RectWidth(ControlRect) - 12, 3),
                                       Point(RectWidth(ControlRect) - 3, RectHeight(ControlRect) - 2),
                                       Point(RectWidth(ControlRect), RectHeight(ControlRect))],
                                 ChromeTabs.GetOptions.Display.Tabs.Orientation),
                      GetTabBrush,
                      GetTabPen);
  end;
end;

function TChromeTabControl.GetCloseButonRect: TRect;
begin
  Result.Left := ControlRect.Right -
                 ChromeTabs.GetOptions.Display.Tabs.ContentOffsetRight -
                 ChromeTabs.GetOptions.Display.CloseButton.Width -
                 ChromeTabs.GetOptions.Display.CloseButton.Offsets.Horizontal;
  Result.Top := ControlRect.Top +
                ChromeTabs.GetOptions.Display.CloseButton.Offsets.Vertical;
  Result.Right := Result.Left +
                  ChromeTabs.GetOptions.Display.CloseButton.Width;
  Result.Bottom := Result.Top +
                   ChromeTabs.GetOptions.Display.CloseButton.Height;
end;

function TChromeTabControl.GetCloseButtonCrossRect: TRect;
begin
  Result := GetCloseButonRect;

  Result := Rect(Result.Left + ChromeTabs.GetOptions.Display.CloseButton.CrossRadialOffset,
                 Result.Top + ChromeTabs.GetOptions.Display.CloseButton.CrossRadialOffset,
                 Result.Right - ChromeTabs.GetOptions.Display.CloseButton.CrossRadialOffset,
                 Result.Bottom - ChromeTabs.GetOptions.Display.CloseButton.CrossRadialOffset);
end;

function TChromeTabControl.GetTabBrush: TGPLinearGradientBrush;
begin
  if FBrushInvalidated then
  begin
    FBrushInvalidated := FALSE;

    FreeAndNil(FTabBrush);
  end;

  if FTabBrush = nil then
    FTabBrush := TGPLinearGradientBrush.Create(MakePoint(0, ControlRect.Top),
                                               MakePoint(0, ControlRect.Bottom),
                                               MakeGDIPColor(FChromeTabControlPropertyItems.CurrentTabProperties.StartColor, FChromeTabControlPropertyItems.CurrentTabProperties.StartAlpha),
                                               MakeGDIPColor(FChromeTabControlPropertyItems.CurrentTabProperties.StopColor, FChromeTabControlPropertyItems.CurrentTabProperties.StopAlpha));

  Result := FTabBrush;
end;

function TChromeTabControl.GetTabPen: TGPPen;
begin
  if FPenInvalidated then
  begin
    FPenInvalidated := FALSE;

    FreeAndNil(FTabPen);
  end;

  if FTabPen = nil then
    FTabPen := TGPPen.Create(MakeGDIPColor(FChromeTabControlPropertyItems.CurrentTabProperties.OutlineColor,
                                           FChromeTabControlPropertyItems.CurrentTabProperties.OutlineAlpha),
                                           FChromeTabControlPropertyItems.CurrentTabProperties.OutlineSize);

  Result := FTabPen;
end;

procedure TChromeTabControl.DrawTo(TabCanvas: TGPGraphics; CanvasBmp, BackgroundBmp: TBitmap; MouseX, MouseY: Integer);

  function Scanline(BitmapData : TBitmapData; Row : integer): PRGBQuad;
  begin
    result := bitmapData.Scan0;

    inc(PByte(result), Row * bitmapData.stride);
  end;

  procedure DrawGDITextWithOffset(const Text: String; TextRect: TRect; OffsetX, OffsetY: Integer; FontColor: TColor);
  const
    BlendFactorsNormal: array[0..2] of Single = (0.0, 0.0, 0.0);
  var
    TabsFont: TGPFont;
    GPRect: TGPRectF;
    TxtFormat: TGPStringFormat;
    TabsTxtBrush: TGPLinearGradientBrush;
    TextFormatFlags: Integer;
    TabText: String;
    TextSize: Integer;
    BlendPositions: array[0..2] of Single;
    BlendFactorsFade: array[0..2] of Single;
  begin
    if ChromeTabs.GetOptions.Behaviour.DebugMode then
      TextSize := 7
    else
      TextSize := FChromeTabControlPropertyItems.CurrentTabProperties.FontSize;

    TabsFont := TGPFont.Create(FChromeTabControlPropertyItems.StopTabProperties.FontName, TextSize);
    try
      TabsTxtBrush := TGPLinearGradientBrush.Create(RectToGPRect(TextRect),
                                                    MakeGDIPColor(FChromeTabControlPropertyItems.CurrentTabProperties.FontColor, FChromeTabControlPropertyItems.CurrentTabProperties.FontAlpha),
                                                    MakeGDIPColor(FChromeTabControlPropertyItems.CurrentTabProperties.FontColor, 0),
                                                    LinearGradientModeHorizontal);
      try
        GPRect.X := TextRect.Left + OffsetX;
        GPRect.Y := TextRect.Top + OffsetY;
        GPRect.Width := RectWidth(TextRect);
        GPRect.Height := RectHeight(TextRect);

        TxtFormat := TGPStringFormat.Create();
        try
          TabCanvas.SetTextRenderingHint(FChromeTabControlPropertyItems.StopTabProperties.TextRendoringMode);

          BlendPositions[0] := 0.0;
          BlendPositions[2] := 1.0;

          BlendFactorsFade[1] := 0.0;;

          // Calculate the position at which we start to fade the text
          // A correction is made for text under 80 pixels
          if RectWidth(TextRect) > 80 then
            BlendPositions[1] := 0.85
          else
            BlendPositions[1] := 0.85 - ((80 - RectWidth(TextRect)) / 80);

          // Set the text trim mode
          if ChromeTabs.GetOptions.Display.Tabs.TextTrimType <> tttFade then
          begin
            TxtFormat.SetTrimming(TStringTrimming(ChromeTabs.GetOptions.Display.Tabs.TextTrimType));

            TabsTxtBrush.SetBlend(@BlendFactorsNormal[0], @BlendPositions[0], Length(BlendFactorsNormal));
          end
          else
          begin
            // Set the fade blend factors to fade the end of the text
            TxtFormat.SetTrimming(StringTrimmingNone);

            if ChromeTabs.GetBiDiMode in [bdLeftToRight, bdRightToLeftNoAlign] then
            begin
              BlendFactorsFade[0] := 0.0;
              BlendFactorsFade[2] := 1.0;
            end
            else
            begin
              BlendFactorsFade[0] := 1.0;
              BlendFactorsFade[2] := 0.0;

              BlendPositions[1] := 1 - BlendPositions[1];
            end;

            TabsTxtBrush.SetBlend(@BlendFactorsFade[0], @BlendPositions[0], Length(BlendFactorsFade));
          end;

          // Set the horizontal alignment
          case ChromeTabs.GetOptions.Display.Tabs.TextAlignmentVertical of
            taAlignTop: TxtFormat.SetLineAlignment(StringAlignmentNear);
            taAlignBottom: TxtFormat.SetLineAlignment(StringAlignmentFar);
            taVerticalCenter: TxtFormat.SetLineAlignment(StringAlignmentCenter);
          end;

          // Set the vertical alignment
          case ChromeTabs.GetOptions.Display.Tabs.TextAlignmentHorizontal of
            taLeftJustify: TxtFormat.SetAlignment(StringAlignmentNear);
            taRightJustify: TxtFormat.SetAlignment(StringAlignmentFar);
            taCenter: TxtFormat.SetAlignment(StringAlignmentCenter);
          end;

          TextFormatFlags := 0;

          // Set other flags
          if not ChromeTabs.GetOptions.Behaviour.DebugMode then
          begin
            if not ChromeTabs.GetOptions.Display.Tabs.WordWrap then
              TextFormatFlags := TextFormatFlags + StringFormatFlagsNoWrap;

            if ChromeTabs.GetBiDiMode in [bdRightToLeft, bdRightToLeftReadingOnly] then
              TextFormatFlags := TextFormatFlags + StringFormatFlagsDirectionRightToLeft;
          end;

          TxtFormat.SetFormatFlags(TextFormatFlags);

          // Debug mode text
          if ChromeTabs.GetOptions.Behaviour.DebugMode then
            TabText := format('L: %d, T: %d, R: %d: B: %d W: %d H: %d',
                              [ControlRect.Left,
                               ControlRect.Top,
                               ControlRect.Right,
                               ControlRect.Bottom,
                               RectWidth(ControlRect),
                               RectHeight(ControlRect)])
          else
            TabText := ChromeTab.GetCaption;

          // Draw the text
          TabCanvas.DrawString(PChar(TabText),
                               Length(TabText),
                               TabsFont,
                               GPRect,
                               TxtFormat,
                               TabsTxtBrush);
        finally
          FreeAndNil(TxtFormat);
        end;
      finally
        FreeAndNil(TabsTxtBrush);
      end;
    finally
      FreeAndNil(TabsFont);
    end;
  end;

  procedure DrawGDIText(const Text: String; TextRect: TRect);
  begin
    DrawGDITextWithOffset(Text, TextRect, 0, 0, FChromeTabControlPropertyItems.CurrentTabProperties.FontColor);
  end;

  procedure DrawImage(Images: TCustomImageList; ImageIndex: Integer; ImageRect: TRect; ChromeTabItemType: TChromeTabItemType);
  var
    ImageBitmap: TGPImage;
    Handled: Boolean;
  begin
    ChromeTabs.DoOnBeforeDrawItem(TabCanvas, ImageRect, ChromeTabItemType, ChromeTab.GetIndex, Handled);

    if not Handled then
    begin
      ImageBitmap := ImageListToTGPImage(Images, ImageIndex);
      try
        TabCanvas.DrawImage(ImageBitmap, ImageRect.Left, ImageRect.Top);
      finally
        FreeAndNil(ImageBitmap);
      end;
    end;

    ChromeTabs.DoOnAfterDrawItem(TabCanvas, ImageRect, ChromeTabItemType, ChromeTab.GetIndex);
  end;

  procedure CalculateRects(var ImageRect, TextRect, CloseButtonRect, CloseButtonCrossRect: TRect;
                           var NormalImageVisible, OverlayImageVisible, TextVisible: Boolean);
  var
    LeftOffset, RightOffset, ImageWidth, ImageHeight: Integer;
  begin
    // Get the close button rect
    CloseButtonRect := GetCloseButonRect;
    CloseButtonCrossRect := GetCloseButtonCrossRect;

    if CloseButtonVisible then
      RightOffset := CloseButtonRect.Left - 1
    else
      RightOffset := ControlRect.Right - ChromeTabs.GetOptions.Display.Tabs.ContentOffsetRight;

    // Get image size
    LeftOffset := ControlRect.Left + ChromeTabs.GetOptions.Display.Tabs.ContentOffsetLeft;

    NormalImageVisible := ImageVisible(ChromeTabs.GetImages, ChromeTab.GetImageIndex);
    OverlayImageVisible := ImageVisible(ChromeTabs.GetImagesOverlay, ChromeTab.GetImageIndexOverlay);

    ImageWidth := 0;
    ImageHeight := 0;

    if (NormalImageVisible) or
       (OverlayImageVisible) then
    begin
      ImageWidth := ChromeTabs.GetImages.Width;
      ImageHeight := ChromeTabs.GetImages.Height;
    end;

    if OverlayImageVisible then
    begin
      if ChromeTabs.GetImagesOverlay.Width > ChromeTabs.GetImagesOverlay.Width then
        ImageWidth := ChromeTabs.GetImagesOverlay.Width;

      if ChromeTabs.GetImagesOverlay.Height > ChromeTabs.GetImagesOverlay.Height then
        ImageHeight := ChromeTabs.GetImagesOverlay.Height;
    end;

    // Does the image fit between the left margin and the close button?
    if LeftOffset + ImageWidth > RightOffset then
    begin
      NormalImageVisible := FALSE;
      OverlayImageVisible := FALSE;
    end
    else
    begin
      // Should we centre the image?
      if ChromeTab.GetPinned then
        ImageRect := Rect(ControlRect.Left + (RectWidth(ControlRect) div 2) - (ImageWidth div 2),
                          ControlRect.Top + (RectHeight(ControlRect) div 2) - (ImageHeight div 2),
                          ControlRect.Left + (RectWidth(ControlRect) div 2) - (RectWidth(CloseButtonRect) div 2) + ImageHeight,
                          (ControlRect.Top + (RectHeight(ControlRect) div 2) - (ImageHeight div 2)) + ImageHeight)
      else
      begin
        ImageRect := Rect(LeftOffset,
                          ControlRect.Top + (RectHeight(ControlRect) div 2) - (ImageHeight div 2),
                          LeftOffset + ImageWidth,
                          (ControlRect.Top + (RectHeight(ControlRect) div 2) - (ImageHeight div 2)) + ImageHeight);

        LeftOffset := LeftOffset + ImageWidth + 1;
      end;
    end;

    // Does the Text fit?
    TextVisible := (not ChromeTab.GetPinned) and
                   (RightOffset - LeftOffset >= 5);

    if TextVisible then
    begin
      TextRect := Rect(LeftOffset,
                       ControlRect.Top,
                       RightOffset,
                       ControlRect.Bottom);
    end;

    if (CloseButtonVisible) and
       (not TextVisible) and
       (not NormalImageVisible) and
       (not OverlayImageVisible) then
    begin
      // If only the close button is visible, we need to centre it
      CloseButtonRect := Rect(ControlRect.Left + (RectWidth(ControlRect) div 2) - (RectWidth(CloseButtonRect) div 2),
                              CloseButtonRect.Top,
                              ControlRect.Left + (RectWidth(ControlRect) div 2) - (RectWidth(CloseButtonRect) div 2) + RectWidth(CloseButtonRect),
                              CloseButtonRect.Bottom);

      CloseButtonCrossRect := Rect(ControlRect.Left + (RectWidth(ControlRect) div 2) - (RectWidth(CloseButtonCrossRect) div 2),
                                   CloseButtonCrossRect.Top,
                                   ControlRect.Left + (RectWidth(ControlRect) div 2) - (RectWidth(CloseButtonCrossRect) div 2) + RectWidth(CloseButtonCrossRect),
                                   CloseButtonCrossRect.Bottom);
    end;

    ImageRect := ScrollRect(BidiRect(ImageRect));
    TextRect := ScrollRect(BidiRect(TextRect));
    CloseButtonRect := ScrollRect(BidiRect(CloseButtonRect));
    CloseButtonCrossRect := ScrollRect(BidiRect(CloseButtonCrossRect));
  end;

  procedure SetTabClipRegion(ChromeTabPolygons: IChromeTabPolygons);
  var
    TabPathPolygon: PGPPoint;
    TabPath: TGPGraphicsPath;
  begin
    TabPathPolygon := PGPPoint(ChromeTabPolygons.Polygons[0].Polygon);

    // Create a clip region so we don't draw outside the tab
    TabPath := TGPGraphicsPath.Create;
    try
      TabPath.AddPolygon(TabPathPolygon, length(ChromeTabPolygons.Polygons[0].Polygon));

      TabCanvas.SetClip(TabPath);
    finally
      FreeAndNil(TabPath);
    end;
  end;

  procedure DrawGlow(GlowRect: TRect; CentreColor, OutsideColor: TColor; CentreAlpha, OutsideAlpha: Byte);
  var
    GPGraphicsPath: TGPGraphicsPath;
    GlowBrush: TGPPathGradientBrush;
    SurroundColors : array[0..0] of TGPColor;
    ColCount: Integer;
  begin
    GPGraphicsPath := TGPGraphicsPath.Create;
    try
      // Add the glow ellipse to the path
      GPGraphicsPath.AddEllipse(RectToGPRectF(GlowRect));

      // Create the glow brush
      GlowBrush := TGPPathGradientBrush.Create(GPGraphicsPath);
      try
        // Set the glow parameters
        GlowBrush.SetCenterPoint(PointToGPPoint(Point(GlowRect.Left +
                                                      (RectWidth(GlowRect) div 2),
                                                      GlowRect.Top +
                                                      (Rectheight(GlowRect) div 2))));

        GlowBrush.SetCenterColor(MakeGDIPColor(CentreColor,
                                               CentreAlpha));
        ColCount := 1;

        SurroundColors[0] := MakeGDIPColor(OutsideColor,
                                           OutsideAlpha);

        GlowBrush.SetSurroundColors(@SurroundColors[0],
                                    ColCount);

        // Draw the glow
        TabCanvas.FillPath(GlowBrush, GPGraphicsPath);
      finally
        FreeAndNil(GlowBrush);
      end;
    finally
      FreeAndNil(GPGraphicsPath);
    end;
  end;

var
  CloseButtonStyle: TChromeTabsLookAndFeelStyle;
  CloseButtonCrossPen: TGPPen;
  ImageRect, TextRect, ButtonRect, CrossRect: TRect;
  NormalImageVisible, OverlayImageVisible, TextVisible: Boolean;
  Handled: Boolean;
  ChromeTabPolygons: IChromeTabPolygons;
begin
  if (FTabProperties <> nil) and (ChromeTabs <> nil) then
  begin
    // Fire the before draw event
    ChromeTabs.DoOnBeforeDrawItem(TabCanvas, ControlRect, itTab, ChromeTab.GetIndex, Handled);

    // Only continue if the drawing hasn't already been handled
    if not Handled then
    begin
      ChromeTabPolygons := GetPolygons;

      // Calculate the positions and visibilty of the controls
      CalculateRects(ImageRect, TextRect, ButtonRect, CrossRect, NormalImageVisible, OverlayImageVisible, TextVisible);

      // Draw the tab background
      ChromeTabPolygons.DrawTo(TabCanvas, dfBrush);

      // Set the clip region to that of the tab so the glows stay within the tab
      SetTabClipRegion(ChromeTabPolygons);

      // Draw the modified glow
      if FChromeTab.GetModified then
        DrawGlow(BidiRect(Rect(GetModifiedGlowX,
                      ChromeTabs.GetOptions.Display.TabModifiedGlow.VerticalOffset,
                      ChromeTabs.GetOptions.Display.TabModifiedGlow.Width + GetModifiedGlowX,
                      ChromeTabs.GetOptions.Display.TabModifiedGlow.Height + ChromeTabs.GetOptions.Display.TabModifiedGlow.VerticalOffset)),
                      ChromeTabs.GetLookAndFeel.Tabs.Modified.CentreColor,
                      ChromeTabs.GetLookAndFeel.Tabs.Modified.OutsideColor,
                      ChromeTabs.GetLookAndFeel.Tabs.Modified.CentreAlpha,
                      ChromeTabs.GetLookAndFeel.Tabs.Modified.OutsideAlpha);

      // Draw the mouse glow
      if (ChromeTabs.GetOptions.Display.TabMouseGlow.Visible) and
         (PointInPolygon(ChromeTabPolygons.Polygons[0].Polygon, MouseX, MouseY)) then
        DrawGlow(Rect(MouseX - (ChromeTabs.GetOptions.Display.TabMouseGlow.Width div 2),
                      MouseY - (ChromeTabs.GetOptions.Display.TabMouseGlow.Height div 2),
                      MouseX + (ChromeTabs.GetOptions.Display.TabMouseGlow.Width div 2),
                      MouseY + (ChromeTabs.GetOptions.Display.TabMouseGlow.Height div 2)),
                      ChromeTabs.GetLookAndFeel.Tabs.MouseGlow.CentreColor,
                      ChromeTabs.GetLookAndFeel.Tabs.MouseGlow.OutsideColor,
                      ChromeTabs.GetLookAndFeel.Tabs.MouseGlow.CentreAlpha,
                      ChromeTabs.GetLookAndFeel.Tabs.MouseGlow.OutsideAlpha);

      // Reset the clip region
      TabCanvas.ResetClip;

      // Draw the text
      if (not ChromeTab.GetPinned) and (TextVisible) then
      begin
        ChromeTabs.DoOnBeforeDrawItem(TabCanvas, TextRect, itTabText, ChromeTab.GetIndex, Handled);

        if not Handled then
          DrawGDIText(ChromeTab.GetCaption, TextRect);

        ChromeTabs.DoOnAfterDrawItem(TabCanvas, TextRect, itTabText, ChromeTab.GetIndex);
      end;

      // Draw the border after the modified glow and text
      ChromeTabPolygons.DrawTo(TabCanvas, dfPen);

      // Draw the close button
      if CloseButtonVisible then
      begin
        ChromeTabs.DoOnBeforeDrawItem(TabCanvas, ButtonRect, itTabCloseButton, ChromeTab.GetIndex, Handled);

        if not Handled then
        begin
          case FCloseButtonState of
            dsDown:
              begin
                CloseButtonStyle := ChromeTabs.GetLookAndFeel.CloseButton.Circle.Down;
                CloseButtonCrossPen := ChromeTabs.GetLookAndFeel.CloseButton.Cross.Down.GetPen;
              end;

            dsHot:
              begin
                CloseButtonStyle := ChromeTabs.GetLookAndFeel.CloseButton.Circle.Hot;
                CloseButtonCrossPen := ChromeTabs.GetLookAndFeel.CloseButton.Cross.Hot.GetPen;
              end;

            else
              begin
                CloseButtonStyle := ChromeTabs.GetLookAndFeel.CloseButton.Circle.Normal;
                CloseButtonCrossPen := ChromeTabs.GetLookAndFeel.CloseButton.Cross.Normal.GetPen;
              end;
          end;

          // Draw the circle
          TabCanvas.FillEllipse(CloseButtonStyle.GetBrush(ButtonRect),
                                                          ButtonRect.Left,
                                                          ButtonRect.Top,
                                                          RectWidth(ButtonRect),
                                                          RectHeight(ButtonRect));

          TabCanvas.DrawEllipse(CloseButtonStyle.GetPen,
                                ButtonRect.Left,
                                ButtonRect.Top,
                                RectWidth(ButtonRect),
                                RectHeight(ButtonRect));

          // Draw the cross
          TabCanvas.DrawLine(CloseButtonCrossPen, CrossRect.Left, CrossRect.Top, CrossRect.Right, CrossRect.Bottom);
          TabCanvas.DrawLine(CloseButtonCrossPen, CrossRect.Left, CrossRect.Bottom, CrossRect.Right, CrossRect.Top);
        end;

        ChromeTabs.DoOnAfterDrawItem(TabCanvas, ButtonRect, itTabCloseButton, ChromeTab.GetIndex);
      end;

      // Draw the normal and overlay images
      if NormalImageVisible then
        DrawImage(ChromeTabs.GetImages, ChromeTab.GetImageIndex, ImageRect, itTabImage);

      if OverlayImageVisible then
        DrawImage(ChromeTabs.GetImagesOverlay, ChromeTab.GetImageIndexOverlay, ImageRect, itTabImageOverlay);
    end;
  end;

  ChromeTabs.DoOnAfterDrawItem(TabCanvas, ControlRect, itTab, ChromeTab.GetIndex);
end;

procedure TChromeTabControl.EndAnimation;
begin
  FChromeTabControlPropertyItems.TransformPercent := -1;

  Animate;
end;

procedure TChromeTabControl.SetCloseButtonState(const Value: TDrawState);
begin
  if FCloseButtonState <> Value then
  begin
    FCloseButtonState := Value;

    FCloseButtonInvalidate := TRUE;

    FChromeTabs.DoOnChange(FChromeTab.GetTab, tcControlState);
  end;
end;

procedure TChromeTabControl.SetDrawState(const Value: TDrawState; Animate: Boolean; AnimationSteps: Integer; ForceUpdate: Boolean);
var
  DefaultFont: TChromeTabsLookAndFeelBaseFont;
begin
  // Only update if the state has changed
  if (ForceUpdate) or (Value <> FDrawState) then
  begin
    // Retrieve the properties for the current state
    case Value of
      dsActive: FTabProperties := ChromeTabs.GetLookAndFeel.Tabs.Active;
      dsHot: FTabProperties := ChromeTabs.GetLookAndFeel.Tabs.Hot
    else
      FTabProperties := ChromeTabs.GetLookAndFeel.Tabs.NotActive;
    end;

    if FTabProperties.Font.UseDefaultFont then
      DefaultFont := ChromeTabs.GetLookAndFeel.Tabs.DefaultFont
    else
      DefaultFont := nil;

    FChromeTabControlPropertyItems.SetProperties(FTabProperties.Style, FTabProperties.Font, DefaultFont, AnimationSteps, Animate);
  end;

  inherited;
end;


{ TScrollButtonControl }

procedure TScrollButtonControl.DrawTo(TabCanvas: TGPGraphics; CanvasBmp, BackgroundBmp: TBitmap; MouseX, MouseY: Integer);
begin
  GetPolygons.DrawTo(TabCanvas);
end;

function TScrollButtonControl.GetArrowPolygons(
  Direction: TChromeTabDirection): IChromeTabPolygons;
begin
  Result := TChromeTabPolygons.Create;

  Result.AddPolygon(BidiPolygon(
                    NewPolygon(BidiControlRect, [Point(0, RectHeight(ControlRect)),
                                             Point(0, 0),
                                             Point(RectWidth(ControlRect), 0),
                                             Point(RectWidth(ControlRect), RectHeight(ControlRect))],
                               ChromeTabs.GetOptions.Display.Tabs.Orientation)),
                               GetButtonBrush,
                               GetButtonPen);


  case Direction of
    drLeft:
      begin
        Result.AddPolygon(BidiPolygon(
                          NewPolygon(BidiControlRect, [Point(3, RectHeight(ControlRect) div 2),
                                                   Point(RectWidth(ControlRect) - 3, 2),
                                                   Point(RectWidth(ControlRect) - 3, RectHeight(ControlRect) - 2),
                                                   Point(3, RectHeight(ControlRect) div 2)],
                                     ChromeTabs.GetOptions.Display.Tabs.Orientation)),
                                     GetSymbolBrush,
                                     GetSymbolPen);
      end;

    drRight:
      begin
        Result.AddPolygon(BidiPolygon(
                          NewPolygon(BidiControlRect, [Point(RectWidth(ControlRect) - 3, RectHeight(ControlRect) div 2),
                                                   Point(3, 2),
                                                   Point(3, RectHeight(ControlRect) - 2),
                                                   Point(RectWidth(ControlRect) - 3, RectHeight(ControlRect) div 2)],
                                     ChromeTabs.GetOptions.Display.Tabs.Orientation)),
                                     GetSymbolBrush,
                                     GetSymbolPen);
      end;
  end;
end;

procedure TScrollButtonControl.SetStylePropertyClasses;
begin
  case FDrawState of
    dsDown:
      begin
        FButtonStyle := ChromeTabs.GetLookAndFeel.ScrollButtons.Button.Down;
        FSymbolStyle := ChromeTabs.GetLookAndFeel.ScrollButtons.Arrow.Down;
      end;

    dsHot:
      begin
        FButtonStyle := ChromeTabs.GetLookAndFeel.ScrollButtons.Button.Hot;
        FSymbolStyle := ChromeTabs.GetLookAndFeel.ScrollButtons.Arrow.Hot;
      end;

    dsDisabled:
      begin
        FButtonStyle := ChromeTabs.GetLookAndFeel.ScrollButtons.Button.Disabled;
        FSymbolStyle := ChromeTabs.GetLookAndFeel.ScrollButtons.Arrow.Disabled;
      end;
  else
    begin
      FButtonStyle := ChromeTabs.GetLookAndFeel.ScrollButtons.Button.Normal;
      FSymbolStyle := ChromeTabs.GetLookAndFeel.ScrollButtons.Arrow.Normal;
    end;
  end;
end;


{ TScrollButtonLeftControl }

constructor TScrollButtonLeftControl.Create(
  ChromeTabs: IChromeTabs);
begin
  inherited;

  FControlType := itScrollLeftButton;
end;

procedure TScrollButtonLeftControl.DrawTo(TabCanvas: TGPGraphics; CanvasBmp, BackgroundBmp: TBitmap; MouseX, MouseY: Integer);
var
  Handled: Boolean;
begin
  ChromeTabs.DoOnBeforeDrawItem(TabCanvas, ControlRect, itScrollLeftButton, -1, Handled);

  if not Handled then
    inherited;

  ChromeTabs.DoOnAfterDrawItem(TabCanvas, ControlRect, itScrollLeftButton, -1);
end;

function TScrollButtonLeftControl.GetPolygons: IChromeTabPolygons;
begin
  Result := inherited GetPolygons;

  if Result = nil then
    Result := GetArrowPolygons(drLeft);
end;


{ TScrollButtonRightControl }

constructor TScrollButtonRightControl.Create(
  ChromeTabs: IChromeTabs);
begin
  inherited;

  FControlType := itScrollRightButton;
end;

procedure TScrollButtonRightControl.DrawTo(TabCanvas: TGPGraphics; CanvasBmp, BackgroundBmp: TBitmap; MouseX, MouseY: Integer);
var
  Handled: Boolean;
begin
  ChromeTabs.DoOnBeforeDrawItem(TabCanvas, ControlRect, itScrollRightButton, -1, Handled);

  if not Handled then
    inherited;

  ChromeTabs.DoOnAfterDrawItem(TabCanvas, ControlRect, itScrollRightButton, -1);
end;

function TScrollButtonRightControl.GetPolygons: IChromeTabPolygons;
begin
  Result := inherited GetPolygons;

  if Result = nil then
    Result := GetArrowPolygons(drRight);
end;


{ TChromeTabControlPropertyItems }

procedure TChromeTabControlPropertyItems.SetProperties(Style: TChromeTabsLookAndFeelStyle; StyleFont: TChromeTabsLookAndFeelFont; DefaultFont: TChromeTabsLookAndFeelBaseFont; AnimationSteps: Integer; Animate: Boolean);
var
  Dst: TChromeTabControlProperties;
  Font: TChromeTabsLookAndFeelBaseFont;
begin
  if DefaultFont <> nil then
    Font := DefaultFont
  else
    Font := StyleFont;

  if Font <> nil then
  begin
    // Copy the property values to the record
    Dst.FontColor := Font.Color;
    Dst.FontAlpha := Font.Alpha;
    Dst.FontName := Font.Name;
    Dst.FontSize := Font.Size;
    Dst.TextRendoringMode := Font.TextRendoringMode;
  end;

  Dst.StartColor := Style.StartColor;
  Dst.StopColor := Style.StopColor;
  Dst.OutlineColor := Style.OutlineColor;
  Dst.OutlineSize := Style.OutlineSize;
  Dst.OutlineAlpha := Style.OutlineAlpha;
  Dst.StartAlpha := Style.StartAlpha;
  Dst.StopAlpha := Style.StopAlpha;

  if Animate then
  begin
    FStopTabProperties := Dst;
    FStartTabProperties := CurrentTabProperties;

    // then start the animation sequence
    FTransformPercent := 1;
  end
  else
  begin
    // If we're not animating, set the values now
    CurrentTabProperties := Dst;
    FStartTabProperties := Dst;
    FStopTabProperties := Dst;

    // Make sure we don't animate
    FTransformPercent := 101;
  end;

  FAnimationSteps := AnimationSteps;
end;

function TChromeTabControlPropertyItems.TransformColors: Boolean;
begin
  Result := FALSE;

  if (FTransformPercent <> 100) or (FTransformPercent = -1) then
  begin
    Result := TRUE;

    if (FTransformPercent >= 100) or (FTransformPercent = -1) then
      FTransformPercent := 100;

    FCurrentTabProperties.FontColor := ColorBetween(FStartTabProperties.FontColor, FStopTabProperties.FontColor, FTransformPercent);
    FCurrentTabProperties.FontAlpha := IntegerBetween(FStartTabProperties.FontAlpha, FStopTabProperties.FontAlpha, FTransformPercent);
    FCurrentTabProperties.FontSize := IntegerBetween(FStartTabProperties.FontSize, FStopTabProperties.FontSize, FTransformPercent);

    FCurrentTabProperties.StartColor := ColorBetween(FStartTabProperties.StartColor, FStopTabProperties.StartColor, FTransformPercent);
    FCurrentTabProperties.StopColor := ColorBetween(FStartTabProperties.StopColor, FStopTabProperties.StopColor, FTransformPercent);
    FCurrentTabProperties.OutlineColor := ColorBetween(FStartTabProperties.OutlineColor, FStopTabProperties.OutlineColor, FTransformPercent);
    FCurrentTabProperties.OutlineSize := SingleBetween(FStartTabProperties.OutlineSize, FStopTabProperties.OutlineSize, FTransformPercent);
    FCurrentTabProperties.StartAlpha := IntegerBetween(FStartTabProperties.StartAlpha, FStopTabProperties.StartAlpha, FTransformPercent);
    FCurrentTabProperties.StopAlpha := IntegerBetween(FStartTabProperties.StopAlpha, FStopTabProperties.StopAlpha, FTransformPercent);
    FCurrentTabProperties.OutlineAlpha := IntegerBetween(FStartTabProperties.OutlineAlpha, FStopTabProperties.OutlineAlpha, FTransformPercent);

    if FTransformPercent < 100 then
      Inc(FTransformPercent, FAnimationSteps);
  end;
end;

{ TBaseChromeButtonControl }

function TBaseChromeButtonControl.Animate: Boolean;
var
  SymbolResult: Boolean;
begin
  Result := FButtonControlPropertyItems.TransformColors;

  if Result then
  begin
    FreeAndNil(FButtonBrush);
    FreeAndNil(FButtonPen);

    SymbolResult := FSymbolControlPropertyItems.TransformColors;

    if SymbolResult then
    begin
      FreeAndNil(FSymbolBrush);
      FreeAndNil(FSymbolPen);
    end;

    Result := Result or SymbolResult;
  end;

  Result := inherited Animate or Result;

  if Result then
    Invalidate;
end;

function TBaseChromeButtonControl.Animating: Boolean;
begin
  Result := inherited Animating or
            (FButtonControlPropertyItems.TransformPercent <> 100) or
            (FSymbolControlPropertyItems.TransformPercent <> 100);
end;

constructor TBaseChromeButtonControl.Create(ChromeTabs: IChromeTabs);
begin
  inherited Create(ChromeTabs);

  FButtonControlPropertyItems := TChromeTabControlPropertyItems.Create;
  FSymbolControlPropertyItems := TChromeTabControlPropertyItems.Create;
end;

destructor TBaseChromeButtonControl.Destroy;
begin
  FreeAndNil(FButtonControlPropertyItems);
  FreeAndNil(FSymbolControlPropertyItems);

  FreeAndNil(FButtonBrush);
  FreeAndNil(FButtonPen);
  FreeAndNil(FSymbolBrush);
  FreeAndNil(FSymbolPen);

  inherited;
end;

function TBaseChromeButtonControl.GetButtonBrush: TGPLinearGradientBrush;
begin
  if FButtonBrush = nil then
    FButtonBrush := TGPLinearGradientBrush.Create(MakePoint(0, ControlRect.Top),
                                               MakePoint(0, ControlRect.Bottom),
                                               MakeGDIPColor(FButtonControlPropertyItems.CurrentTabProperties.StartColor, FButtonControlPropertyItems.CurrentTabProperties.StartAlpha),
                                               MakeGDIPColor(FButtonControlPropertyItems.CurrentTabProperties.StopColor, FButtonControlPropertyItems.CurrentTabProperties.StopAlpha));

  Result := FButtonBrush;
end;

function TBaseChromeButtonControl.GetButtonPen: TGPPen;
begin
  if FButtonPen = nil then
    FButtonPen := TGPPen.Create(MakeGDIPColor(FButtonControlPropertyItems.CurrentTabProperties.OutlineColor,
                                              FButtonControlPropertyItems.CurrentTabProperties.OutlineAlpha),
                                              FButtonControlPropertyItems.CurrentTabProperties.OutlineSize);

  Result := FButtonPen;
end;

function TBaseChromeButtonControl.GetSymbolBrush: TGPLinearGradientBrush;
begin
  if FSymbolBrush = nil then
    FSymbolBrush := TGPLinearGradientBrush.Create(MakePoint(0, ControlRect.Top),
                                               MakePoint(0, ControlRect.Bottom),
                                               MakeGDIPColor(FSymbolControlPropertyItems.CurrentTabProperties.StartColor, FSymbolControlPropertyItems.CurrentTabProperties.StartAlpha),
                                               MakeGDIPColor(FSymbolControlPropertyItems.CurrentTabProperties.StopColor, FSymbolControlPropertyItems.CurrentTabProperties.StopAlpha));

  Result := FSymbolBrush;
end;

function TBaseChromeButtonControl.GetSymbolPen: TGPPen;
begin
  if FSymbolPen = nil then
    FSymbolPen := TGPPen.Create(MakeGDIPColor(FSymbolControlPropertyItems.CurrentTabProperties.OutlineColor,
                                           FSymbolControlPropertyItems.CurrentTabProperties.OutlineAlpha),
                                           FSymbolControlPropertyItems.CurrentTabProperties.OutlineSize);

  Result := FSymbolPen;
end;

procedure TBaseChromeButtonControl.SetDrawState(const Value: TDrawState;
  Animate: Boolean; AnimationSteps: Integer; ForceUpdate: Boolean);
begin
  // Only update if the state has changed
  if (ForceUpdate) or (Value <> FDrawState) then
  begin
    FDrawState := Value;

    SetStylePropertyClasses;

    FButtonControlPropertyItems.SetProperties(FButtonStyle, nil, nil, AnimationSteps, Animate);
    FSymbolControlPropertyItems.SetProperties(FSymbolStyle, nil, nil, AnimationSteps, Animate);
  end;

  inherited;
end;

procedure TBaseChromeButtonControl.SetStylePropertyClasses;
begin
  // Override
end;

end.
