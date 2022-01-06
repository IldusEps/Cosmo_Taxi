{ Main "playing game" state, where most of the game logic takes place.

  Feel free to use this code as a starting point for your own projects.
  (This code is in public domain, unlike most other CGE code which
  is covered by the LGPL license variant, see the COPYING.txt file.) }
unit GameStatePlay;

interface

uses Classes,
  CastleUIState, CastleComponentSerialize, CastleUIControls, CastleControls,
  CastleKeysMouse, CastleViewport, CastleScene, CastleVectors, CastleLog, CastleImages,
  CastleGLImages, CastleTransform, Radar, Station;

type
  { Main "playing game" state, where most of the game logic takes place. }

  { TStatePlay }

  TStatePlay = class(TUIState)
  private
    { Components designed using CGE editor, loaded from gamestateplay.castle-user-interface. }
    LabelFps: TCastleLabel;
    MainViewport: TCastleViewport;

    { Rocket parameters }
    SceneRocket: TCastleScene;
    RocketSpeed: TVector2;
    RocketRotation: Double;

    { Radar }  
    Rocket_mini: TCastleImageControl;
    RadarDesign: TCastleUserInterface;
    Radar: TMap;
//    Stations_mini: array of TDrawableImage;

    { Background }
    Background, Background_main: TCastleScene;
    _backgroundOriginalSizeX,_backgroundOriginalSizeY: Single;

    {Stations}
    Stations: array of TStation;

    { Others }
    CheckboxCameraFollow: TCastleCheckbox;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Render; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: Boolean); override;
    function Press(const Event: TInputPressRelease): Boolean; override;
  end;

var
  StatePlay: TStatePlay;
  BaseSpeed: Double = 0.5;
  AddSpeed: Double = 0.3;
  BaseRotation: Double = 0.01;

implementation

uses SysUtils, Math,
  GameStateMenu;

{ TStatePlay ----------------------------------------------------------------- }

constructor TStatePlay.Create(AOwner: TComponent);
begin
  inherited;
  DesignUrl := 'castle-data:/gamestateplay.castle-user-interface';
end;

procedure TStatePlay.Start;
var
  Background_size: TVector2;
  Background_: TCastleScene;
  iX, iY: integer;
  i: integer;var
  RBodyRocket: TRigidBody;
  ColliderRocket: TBoxCollider;
begin
  inherited;

  LabelFps := DesignedComponent('LabelFps') as TCastleLabel;
  MainViewport := DesignedComponent('MainViewport') as TCastleViewport;
  CheckboxCameraFollow := DesignedComponent('CheckboxCameraFollow') as TCastleCheckbox;

  { Scenes }
  SceneRocket := DesignedComponent('SceneRocket') as TCastleScene;
  //SceneRocket.Gravity:= False;
  //
  //RBodyRocket := TRigidBody.Create(SceneRocket);
  //RBodyRocket.Setup2D;
  //RBodyRocket.Gravity:= False;
  //
  //ColliderRocket := TBoxCollider.Create(RBodyRocket);
  //ColliderRocket.Size := Vector3(SceneRocket.LocalBoundingBox.Size.XY, 2);
  //ColliderRocket.Mass:= 0;
  //ColliderRocket.Friction:= 0;
  //
  //SceneRocket.RigidBody := RBodyRocket;

  { Radar }
  Rocket_mini := DesignedComponent('Rocket_mini') as TCastleImageControl;
  RadarDesign := DesignedComponent('Radar') as TCastleUserInterface;
  Radar := TMap.Create(RadarDesign);
  //Radar.FullSize := True;
  RadarDesign.InsertFrontIfNotExists(Radar);

  Rocket_mini := DesignedComponent('Rocket_mini') as TCastleImageControl;

  { Background }
  Background_main:= DesignedComponent('Background_main') as TCastleScene;
  Background:= DesignedComponent('Background') as TCastleScene;

  _backgroundOriginalSizeX := Background_main.BoundingBox.SizeX;
  _backgroundOriginalSizeY := Background_main.BoundingBox.SizeY;
  Background_size.X:= (MainViewport.Camera.Orthographic.Height * MainViewport.Camera.Orthographic.Scale) * RenderRect.Width / RenderRect.Height + _backgroundOriginalSizeX * 3;
  Background_size.Y:= MainViewport.Camera.Orthographic.Height * MainViewport.Camera.Orthographic.Scale + _backgroundOriginalSizeY * 3;

  iX:= 0;
  iY:= 0;
  while (Background_main.BoundingBox.SizeX < Background_size.X) OR (iX < 5) do
  begin
    Background_:= TCastleScene.Create(Self);
    Background_.Add(Background);
    Background_.Translation.X:= -Background_size.X/2 + _backgroundOriginalSizeX * iX;
    Background_.Translation.Y:= -Background_size.Y/2 + _backgroundOriginalSizeY * 0;
    Background_.Translation.Z:= 1;
    Background_main.Add(Background_);

    if (iX = 0) then
    begin
      while (Background_main.BoundingBox.SizeY < Background_size.Y) OR (iY < 5) do
      begin
        iY:= iY + 1;
        WritelnLog(FloatToStr(Background_size.Y));

        Background_:= TCastleScene.Create(Self);
        Background_.Add(Background);
        Background_.Translation.X:= -Background_size.X/2 + _backgroundOriginalSizeX * iX;
        Background_.Translation.Y:= -Background_size.Y/2 + _backgroundOriginalSizeY * iY;
        Background_.Translation.Z:= 1;
        Background_main.Add(Background_);
      end;
    end
    else for i:= 1 to iY do
    begin
        Background_:= TStation.Create(Self);
        Background_.Add(Background);
        Background_.Translation.X:= -Background_size.X/2 + _backgroundOriginalSizeX * iX;
        Background_.Translation.Y:= -Background_size.Y/2 + _backgroundOriginalSizeY * i;
        Background_.Translation.Z:= 1;
        Background_main.Add(Background_);
    end;
    iX:= iX + 1;
  end;

  {Stations}
  SetLength(Stations, 1);
  Stations[0]:= TStation.Create(Self);
  Stations[0].Translation.Y:= 1000;
  MainViewport.Items.Add(Stations[0]);
end;

procedure TStatePlay.Render;
begin
  Rocket_mini.Rotation := RocketRotation;
end;

procedure TStatePlay.Update(const SecondsPassed: Single; var HandleInput: Boolean);
var
  CamPos: TVector3;
  Trans: TVector2;
begin
  inherited;
  { This virtual method is executed every frame.}

  LabelFps.Caption := 'FPS: ' + Container.Fps.ToString;

  SceneRocket.Translation.Y := SceneRocket.Translation.Y + RocketSpeed.Y;
  SceneRocket.Translation.X := SceneRocket.Translation.X + RocketSpeed.X;
  SceneRocket.Rotation := Vector4(0, 0, 1, RocketRotation);

  if CheckboxCameraFollow.Checked then
  begin
    CamPos := MainViewport.Camera.Position;
    CamPos.X := SceneRocket.Translation.X;
    CamPos.Y := SceneRocket.Translation.Y - (MainViewport.Camera.Orthographic.Height * MainViewport.Camera.Orthographic.Scale) / 2;
    MainViewport.Camera.Position := CamPos;
  end;

  Trans.X:= SceneRocket.Translation.X - Background_main.Translation.X;
  Trans.Y:= SceneRocket.Translation.Y - Background_main.Translation.Y;
  if (Trans.X >= _backgroundOriginalSizeX) then
     Background_main.Translation.X:= SceneRocket.Translation.X
  else
  if (Trans.X <= -_backgroundOriginalSizeX) then
    Background_main.Translation.X:= SceneRocket.Translation.X;

  if (Trans.Y >= _backgroundOriginalSizeY) then
  begin
     Background_main.Translation.Y:= SceneRocket.Translation.Y;
  end
  else
  if (Trans.Y <= -_backgroundOriginalSizeY) then
    Background_main.Translation.Y:= SceneRocket.Translation.Y;
end;

function TStatePlay.Press(const Event: TInputPressRelease): Boolean;
begin
  Result := inherited;
  if Result then Exit; // allow the ancestor to handle keys

  if Event.IsKey(keyW) then
  begin
    RocketSpeed.Y := RocketSpeed.Y + BaseSpeed * cos(RocketRotation);
    RocketSpeed.X := RocketSpeed.X - BaseSpeed * sin(RocketRotation);
    SceneRocket.PlayAnimation('Speed', false);
  end
  else if Event.IsKey(keyS) then
  begin
    RocketSpeed.Y := RocketSpeed.Y - BaseSpeed * cos(RocketRotation);
    RocketSpeed.X := RocketSpeed.X + BaseSpeed * sin(RocketRotation);
    SceneRocket.PlayAnimation('Down', false);
  end
  else if Event.IsKey(keyA) then
  begin
    RocketRotation := RocketRotation + BaseRotation;
    SceneRocket.PlayAnimation('LeftRotate', false);
  end
  else if Event.IsKey(keyD) then
  begin
    RocketRotation := RocketRotation - BaseRotation;

    SceneRocket.PlayAnimation('RightRotate', false);
  end
  else if Event.IsKey(keyQ) then
  begin
    RocketSpeed.Y := RocketSpeed.Y - AddSpeed * sin(RocketRotation);
    RocketSpeed.X := RocketSpeed.X - AddSpeed * cos(RocketRotation);
    SceneRocket.PlayAnimation('Left', false);
  end
  else if Event.IsKey(keyE) then
  begin
    RocketSpeed.Y := RocketSpeed.Y + AddSpeed * sin(RocketRotation);
    RocketSpeed.X := RocketSpeed.X + AddSpeed * cos(RocketRotation);
    SceneRocket.PlayAnimation('Right', false);
  end;

  if Event.IsKey(keyF5) then
  begin
    Container.SaveScreenToDefaultFile;
    Exit(true);
  end;

  if Event.IsKey(keyEscape) then
  begin
    TUIState.Current := StateMenu;
    Exit(true);
  end;
end;


end.
