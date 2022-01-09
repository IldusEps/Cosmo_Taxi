{ Main "playing game" state, where most of the game logic takes place.

  Feel free to use this code as a starting point for your own projects.
  (This code is in public domain, unlike most other CGE code which
  is covered by the LGPL license variant, see the COPYING.txt file.) }
unit GameStatePlay;

interface

uses Classes,
  CastleUIState, CastleComponentSerialize, CastleUIControls, CastleControls,
  CastleKeysMouse, CastleViewport, CastleScene, CastleVectors, CastleLog, CastleImages,
  CastleGLImages, CastleTransform, Radar, Station, Universy, CastleDebugTransform;


{ classes }
type

{ TRocket }

TRocket = class
  Landing: Boolean;
  Speed: TVector2;
  Rotation: Double;
  LabelRocket: TCastleLabel;
  Scene: TCastleScene;

  { constans }
  BaseSpeed: Double;
  AddSpeed: Double;
  BaseRotation: Double;

  procedure Land;
end;

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
    Rocket: TRocket;

    { Radar }  
    Rocket_mini: TCastleImageControl;
    RadarDesign: TCastleUserInterface;
    Radar: TMap;
    Stations_mini: array of TCastleImageControl;

    { Background }
    Background, Background_main: TCastleScene;
    _backgroundOriginalSizeX,_backgroundOriginalSizeY: Single;

    {Stations}
    Stations: array of TStation;

    { Universy }
    Universy: TUniversy;

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

implementation

uses SysUtils, Math,
  GameStateMenu;

{ TRocket }

procedure TRocket.Land;
begin
  Speed.X:= 0;
  Speed.Y:= 0;
  Rotation:= 0;

  Landing:= True;

  Scene.PlayAnimation('Landing', false);
end;

{ TStatePlay ----------------------------------------------------------------- }

constructor TStatePlay.Create(AOwner: TComponent);
begin
  inherited;
  DesignUrl := 'castle-data:/gamestateplay.castle-user-interface';
end;

procedure TStatePlay.Start;
var
  Background_size: TVector2;
  Background_, Asteroid_: TCastleScene;
  iX, iY: integer;
  i: integer;
  RBodyRocket: TRigidBody;
  ColliderRocket: TBoxCollider;
  Debug: TDebugTransform;

  Radar_main: TCastleUserInterface;
begin
  inherited;

  LabelFps := DesignedComponent('LabelFps') as TCastleLabel;
  MainViewport := DesignedComponent('MainViewport') as TCastleViewport;
  CheckboxCameraFollow := DesignedComponent('CheckboxCameraFollow') as TCastleCheckbox;
  Radar_main := DesignedComponent('Radar_main') as TCastleUserInterface;

  { Scenes }
  SceneRocket := DesignedComponent('SceneRocket') as TCastleScene;

  RBodyRocket := TRigidBody.Create(SceneRocket);
  RBodyRocket.Setup2D;
  RBodyRocket.Gravity:= False;
  RBodyRocket.Dynamic:= False;
  RBodyRocket.Animated:= True;

  ColliderRocket := TBoxCollider.Create(RBodyRocket);
  ColliderRocket.Size := Vector3(SceneRocket.LocalBoundingBox.Size.XY, 20);

  SceneRocket.RigidBody := RBodyRocket;

  Debug := TDebugTransform.Create(Self);
  Debug.Attach(SceneRocket);
  Debug.Exists := true;

  { Radar }
  Rocket_mini := DesignedComponent('Rocket_mini') as TCastleImageControl;
  RadarDesign := DesignedComponent('Radar') as TCastleUserInterface;
  Radar := TMap.Create(RadarDesign);
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
        Background_:= TCastleScene.Create(Self);
        Background_.Add(Background);
        Background_.Translation.X:= -Background_size.X/2 + _backgroundOriginalSizeX * iX;
        Background_.Translation.Y:= -Background_size.Y/2 + _backgroundOriginalSizeY * i;
        Background_.Translation.Z:= 1;
        Background_main.Add(Background_);
    end;
    iX:= iX + 1;
  end;

  { Universy }
  Universy:= TUniversy.Create;

  { Stations }
  SetLength(Stations, 50); 
  SetLength(Stations_mini, Length(Stations));
  Universy.SetVectors2(Length(Stations)-1);

  for i:= 0 to Length(Stations)-1 do
  begin
    Stations[i]:= TStation.Create(Self, 'castle-data:/asteroid/Asteroid.json', Universy.GetVector2,
    i);
    MainViewport.Items.Insert(1, Stations[i]);

    //   Stations_mini[i]:= TCastleImageControl.Create(Self);
    //case Stations[i].TypeStation of
    //  'Fill': Stations_mini[i].URL:= 'castle-data:/Fill_mini.png';
    //  'Boots': Stations_mini[i].URL:= 'castle-data:/Boots_mini.png';
    //  else
    //    Stations_mini[i].URL:= 'castle-data:/radar/Asteroid_mini.png';
    //end;
    //Stations_mini[i].Width:= 10;
    //Stations_mini[i].Height:= 10;
    //iX:= round(round(Stations[i].Translation.X) - round(SceneRocket.Translation.X) / 200 + 55.0);
    //iY:= round(round(Stations[i].Translation.Y) - round(SceneRocket.Translation.Y) / 200 + 55.0);
    //if iX > 100 then
    //  iX := 100
    //else if iX < 10 then
    //  iX := 10;
    //if iY > 100 then
    //  iY := 100
    //else if iY < 10 then
    //  iY := 10;
    //Stations_mini[i].Align(hpMiddle, hpMiddle, iX);
    //Stations_mini[i].Align(vpMiddle, vpMiddle, iY);
    //
    //Radar_main.InsertFront(Stations_mini[i]);

  end;

    Stations_mini[0]:= TCastleImageControl.Create(Self);
    case Stations[0].TypeStation of
      'Fill': Stations_mini[0].URL:= 'castle-data:/Fill_mini.png';
      'Boots': Stations_mini[0].URL:= 'castle-data:/Boots_mini.png';
      else
        Stations_mini[0].URL:= 'castle-data:/radar/Asteroid_mini.png';
    end;
    Stations_mini[0].Width:= 10;
    Stations_mini[0].Height:= 10;
    iX:= round(round(Stations[0].Translation.X) - round(SceneRocket.Translation.X) / 200 + 55.0);
    iY:= round(round(Stations[0].Translation.Y) - round(SceneRocket.Translation.Y) / 200 + 55.0);
    if iX > 100 then
      iX := 100
    else if iX < 10 then
      iX := 10;
    if iY > 100 then
      iY := 100
    else if iY < 10 then
      iY := 10;
    Stations_mini[0].Align(hpMiddle, hpMiddle, iX);
    Stations_mini[0].Align(vpMiddle, vpMiddle, iY);

    Radar_main.InsertFront(Stations_mini[0]);
//  MainViewport.Items.SortBackToFront2D;

  { Parameters }
  Rocket:= TRocket.Create;
  Rocket.Landing:= False;
  Rocket.BaseSpeed:= 0.5;
  Rocket.AddSpeed:= 0.3;
  Rocket.BaseRotation:= 0.01;
  Rocket.Scene:= SceneRocket;

  // Debuging
  //Background_main.Visible:= False;
  Rocket.LabelRocket:= DesignedComponent('Rocket') as TCastleLabel;
  with Rocket.LabelRocket.Text do
  begin
    Clear;
    Append('Speed_Y: ' + FloatToStr(Rocket.Speed.Y));
    Append('Speed_X: ' + FloatToStr(Rocket.Speed.X));
    Append('Rotation: ' + FloatToStr(Rocket.Rotation));
    Append('Landing: ' + BoolToStr(Rocket.Landing, True));
    Append('');
    Append('');
  end;
end;

procedure TStatePlay.Render;
begin
end;

procedure TStatePlay.Update(const SecondsPassed: Single; var HandleInput: Boolean);
var
  CamPos: TVector3;
  Trans: TVector2;
  i, iX, iY: integer;
  T: TCastleTransform;
begin
  inherited;
  { This virtual method is executed every frame.}

  LabelFps.Caption := 'FPS: ' + Container.Fps.ToString;

  if NOT(Rocket.Landing) then
  begin
    SceneRocket.Translation.Y := SceneRocket.Translation.Y + Rocket.Speed.Y * SecondsPassed*50;
    SceneRocket.Translation.X := SceneRocket.Translation.X + Rocket.Speed.X * SecondsPassed*50;
  end;
  SceneRocket.Rotation := Vector4(0, 0, 1, Rocket.Rotation);

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

  { Collides }
    Rocket.LabelRocket.Text[0] := ('Speed_Y: ' + FloatToStr(Rocket.Speed.Y));
    Rocket.LabelRocket.Text[1] := ('Speed_X: ' + FloatToStr(Rocket.Speed.X));
    Rocket.LabelRocket.Text[2] := ('cos(Rotation): ' + FloatToStr(cos(Rocket.Rotation)));
    Rocket.LabelRocket.Text[3] := ('Landing: ' + BoolToStr(Rocket.Landing, True));
    Rocket.LabelRocket.Text[5] := ('Translation_Y: ' + FloatToStr(SceneRocket.Translation.Y));

  for i := 0 to SceneRocket.RigidBody.GetCollidingTransforms.Count - 1 do
    if (Copy(SceneRocket.RigidBody.GetCollidingTransforms[i].Name, 1, 8) = 'Asteroid') AND NOT(Rocket.Landing) then
    begin
      T:= SceneRocket.RigidBody.GetCollidingTransforms[i];
      Rocket.LabelRocket.Text[4] := ('Trans: ' + FloatToStr(SceneRocket.Translation.Y - T.Translation.Y)) + ' __ ' + T.Name;
      if (SceneRocket.Translation.Y - T.Translation.Y <= 150) AND (SceneRocket.Translation.Y - T.Translation.Y > 0)
       AND (-Rocket.Speed.Y <= 3) AND (-Rocket.Speed.Y >= 0.5)
       AND (Rocket.Speed.X <= 10) AND (cos(Rocket.Rotation) >= 0.98) then
      begin
        Rocket.Land;
      end;
    end;

  { ImageContols }
  Rocket_mini.Rotation := Rocket.Rotation;

  //for i := 0 to 1 do       //Length(Stations) - 1
  i:=0;
  begin
    iX:= round((round(Stations[i].Translation.X) - round(SceneRocket.Translation.X)) / 200);
    if i = 0 then
        WritelnLog(FloatToStr(round((round(Stations[i].Translation.X) - round(SceneRocket.Translation.X)) / 200)));
    iY:= round((round(Stations[i].Translation.Y) - round(SceneRocket.Translation.Y)) / 200);
    if iX > 100 then
      iX := 100
    else if iX < 10 then
      iX := 10;
    if iY > 100 then
      iY := 100
    else if iY < 10 then
      iY := 10;
    Stations_mini[i].Anchor(hpMiddle, hpMiddle, iX);
    Stations_mini[i].Anchor(vpMiddle, vpMiddle, iY);
  end;
end;

function TStatePlay.Press(const Event: TInputPressRelease): Boolean;
begin
  Result := inherited;
  if Result then Exit; // allow the ancestor to handle keys

  if NOT(Rocket.Landing) then
  begin
    with Rocket do
    begin
      if Event.IsKey(keyW) then
      begin
        Rocket.Speed.Y := Rocket.Speed.Y + Rocket.BaseSpeed * cos(Rocket.Rotation);
        Rocket.Speed.X := Rocket.Speed.X - Rocket.BaseSpeed * sin(Rocket.Rotation);
        SceneRocket.PlayAnimation('Speed', false);
      end
      else if Event.IsKey(keyS) then
      begin
        Speed.Y := Speed.Y - BaseSpeed * cos(Rotation);
        Speed.X := Speed.X + BaseSpeed * sin(Rotation);
        SceneRocket.PlayAnimation('Down', false);
      end
      else if Event.IsKey(keyA) then
      begin
        Rotation := Rocket.Rotation + BaseRotation;
        SceneRocket.PlayAnimation('LeftRotate', false);
      end
      else if Event.IsKey(keyD) then
      begin
        Rotation := Rotation - BaseRotation;

        SceneRocket.PlayAnimation('RightRotate', false);
      end
      else if Event.IsKey(keyQ) then
      begin
        Speed.Y := Speed.Y - AddSpeed * sin(Rotation);
        Speed.X := Speed.X - AddSpeed * cos(Rotation);
        SceneRocket.PlayAnimation('Left', false);
      end
      else if Event.IsKey(keyE) then
      begin
        Speed.Y := Speed.Y + AddSpeed * sin(Rotation);
        Speed.X := Speed.X + AddSpeed * cos(Rotation);
        SceneRocket.PlayAnimation('Right', false);
      end;
    end;
  end else
    if Event.IsKey(keySpace) then
    begin
      if (SceneRocket.PlayAnimation('Starting', false)) then
      begin
        Rocket.Landing:= False;
        Rocket.Speed.Y:= 3;
      end;
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
