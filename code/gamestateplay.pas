{ Main "playing game" state, where most of the game logic takes place.

  Feel free to use this code as a starting point for your own projects.
  (This code is in public domain, unlike most other CGE code which
  is covered by the LGPL license variant, see the COPYING.txt file.) }
unit GameStatePlay;

interface

uses Classes,
  CastleUIState, CastleComponentSerialize, CastleUIControls, CastleControls,
  CastleKeysMouse, CastleViewport, CastleScene, CastleVectors, CastleLog, CastleImages,
  CastleGLImages, CastleTransform, CastleDebugTransform, CastleColors,
  Radar, Station, Universy, Profile;


{ classes }
type

{ TRocket }

TRocket = class
  Landing: Boolean;
  Speed: TVector2;
  Rotation: Double;
  LabelRocket: TCastleLabel;
  Scene: TCastleScene;

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
    HintRadar: TCastleImageControl;
    HintRocket: TCastleImageControl;
    TimerHint: TCastleTimer;

    { Rocket parameters }
    SceneRocket: TCastleScene;
    Rocket: TRocket;
    StationIndex: Integer;
    hyperJump_count: Integer;

    { Radar }  
    Rocket_mini: TCastleImageControl;
    RadarDesign: TCastleUserInterface;
    Radar: TMap;
    RadarZoom: Integer;

    HintAsteroids: THintAsteroid;

    { Background }
    Background, Background_main: TCastleScene;
    _backgroundOriginalSizeX,_backgroundOriginalSizeY: Single;

    {Stations}
    Stations: array of TStation;

    { Mechanics }
    Space_on_Start: TCastleImageControl;

    { Universy }
    Universy: TUniversy;

    { Others }
    Profile: TProfile;
    CheckboxCameraFollow: TCastleCheckbox;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Stop; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: Boolean); override;
    function Press(const Event: TInputPressRelease): Boolean; override;

    procedure HintingRadar(Sender: TObject);
    procedure HintingRocket(Sender: TObject);
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

  { Mechanics }
  Space_on_Start:= DesignedComponent('Space_on_Start') as TCastleImageControl;

  { Hint }
  HintRadar:= DesignedComponent('HintRadar') as TCastleImageControl;
  HintRocket:= DesignedComponent('HintRocket') as TCastleImageControl;
  TimerHint:= DesignedComponent('TimerHint') as TCastleTimer;
  TimerHint.OnTimer:= @HintingRadar;

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
  Background_size.X:= MainViewport.Camera.Orthographic.EffectiveWidth + _backgroundOriginalSizeX * 5;//(MainViewport.Camera.Orthographic.Height * MainViewport.Camera.Orthographic.Scale) * RenderRect.Width / RenderRect.Height;
  Background_size.Y:= MainViewport.Camera.Orthographic.EffectiveHeight + _backgroundOriginalSizeY * 5;//MainViewport.Camera.Orthographic.Height * MainViewport.Camera.Orthographic.Scale + _backgroundOriginalSizeY * 5;

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
  SetLength(Stations, 127);
  Universy.Universy_Skips:= False;
  Universy.SetVectors2(Length(Stations)-1);

  for i:= 0 to Length(Stations)-1 do
  begin
    //Background_size:= Universy.GetVector2;
    Stations[i]:= TStation.Create(Self, 'castle-data:/asteroid/Asteroid.json', Universy.GetVector2,
    i);
    //WritelnLog(IntToStr(i) + ': ' + Background_size.ToString);
    MainViewport.Items.Insert(1, Stations[i]);

    iX:= round(round(Stations[i].Translation.X - SceneRocket.Translation.X) / 200);
    iY:= round(round(Stations[i].Translation.Y - SceneRocket.Translation.Y) / 200);
    if Abs(iX) > 50 then
      iX := 100
    else if iX < 10 then
      iX := 10;
    if iY > 50 then
      iY := 100
    else if iY < 10 then
      iY := 10;
    WritelnLog('Tut2');
    Stations[i].mini.Anchor(hpLeft, hpLeft, iX);
    Stations[i].mini.Anchor(vpBottom, vpBottom, iY);

    Radar_main.InsertFront(Stations[i].mini); 
    WritelnLog('Tut4 _ ' + IntToStr(i));
  end;
  WritelnLog('Tut3');
  HintAsteroids:= THintAsteroid.Create(Self);

  { Parameters }
  Profile:= TProfile.Create;
  Rocket:= TRocket.Create;
  Rocket.Landing:= False;
  Rocket.Scene:= SceneRocket;
  RadarZoom:= 2000;
  Randomize;
  StationIndex:= Random(Length(Stations));
  Stations[StationIndex].IsNeedTaxi:= True;
  Stations[StationIndex].IsDestination:= True;

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

procedure TStatePlay.Stop;
begin
  inherited Stop;
  Profile.Save;
end;

procedure TStatePlay.Update(const SecondsPassed: Single; var HandleInput: Boolean);
var
  CamPos: TVector3;
  Trans, Radius, Display_XY: TVector2;
  i, iX, iY, u: integer;
  T: TCastleTransform;

  function getRadius(v: TVector2): TVector2;
  var
    H, r: Double;
  begin
    if (v.X <> 0) OR (v.Y <>0) then
    begin
      H:= Sqrt(Sqr(v.X) + Sqr(v.Y));
      getRadius.X:= 60 * (v.X / H);
      getRadius.Y:= Sqrt(Sqr(60) - Sqr(getRadius.X));
    end;
  end;

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
    CamPos.Y := SceneRocket.Translation.Y - MainViewport.Camera.Orthographic.EffectiveHeight / 2;
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
    Rocket.LabelRocket.Text[5] := ('Translation_X: ' + FloatToStr(SceneRocket.Translation.X));

  for i := 0 to SceneRocket.RigidBody.GetCollidingTransforms.Count - 1 do
    if (Copy(SceneRocket.RigidBody.GetCollidingTransforms[i].Name, 1, 8) = 'Asteroid') AND NOT(Rocket.Landing) then
    begin
      T:= SceneRocket.RigidBody.GetCollidingTransforms[i];
      Rocket.LabelRocket.Text[4] := ('Trans: ' + FloatToStr(SceneRocket.Translation.Y - T.Translation.Y)) + ' __ ' + T.Name;
      if (SceneRocket.Translation.Y - T.Translation.Y <= 150) AND (SceneRocket.Translation.Y - T.Translation.Y > 0)
      AND (abs(SceneRocket.Translation.X - T.Translation.X) <= 150)
       AND (-Rocket.Speed.Y <= 3) AND (-Rocket.Speed.Y >= 0.5)
       AND (Rocket.Speed.X <= 10) AND (cos(Rocket.Rotation) >= 0.98) then
      begin
        Rocket.Land;
        Space_on_Start.Exists:= True;
        if (TStation(T).IsDestination) then
        begin
          TStation(T).IsDestination:= False;
          Profile.Money:= Profile.Money + TStation(T).Price;
          Profile.Save;
        end;
      end;
    end;

  { ImageControls }
  Rocket_mini.Rotation := Rocket.Rotation;

  Display_XY:= Vector2(MainViewport.Camera.Orthographic.EffectiveWidth / 2,
        MainViewport.Camera.Orthographic.EffectiveHeight / 2);
  for i := 0 to Length(Stations) - 1 do
  begin
    iX:= round((round(Stations[i].Translation.X) - round(SceneRocket.Translation.X)) / RadarZoom);
    iY:= round((round(Stations[i].Translation.Y) - round(SceneRocket.Translation.Y)) / RadarZoom);
    if i = 1 then
    begin
      Rocket.LabelRocket.Text[2] := ('Vector2_Asteroid: ' + Stations[i].Translation.ToString + '__' + 'Vector2_mini: ' + Vector2(iX, iY).ToString);
      Rocket.LabelRocket.Text[3] := ('Radius: ' + getRadius(Vector2(iX, iY)).ToString);
    end;

    u:= 1;
    if iX < 0 then
      u:= -1;
    if (abs(iX) > 50) then
      if (abs(iX) < 70) OR (Stations[i].IsDestination) then
      begin
        iX:= min(abs(iX), abs(round(getRadius(Vector2(iX, iY)).X)));
        iX:= u * iX;
      end
      else
      begin
        iX:= -100;
      end;
    u:= 1;
    if iY < 0 then
      u:= -1;
    if (abs(iY) > 50) then
      if (abs(iY) < 70) OR (Stations[i].IsDestination) then
      begin
        iY:= min(abs(iY), abs(round(getRadius(Vector2(iX, iY)).Y)));
        iY:= u * iY;
      end
      else
      begin
        iY:= -100;
      end;
    if Stations[i].IsDestination then
    begin
       Stations[i].mini.ColorPersistent.Blue:= 0.4352941;
       Stations[i].mini.ColorPersistent.Alpha:= 1;
    end
    else
       Stations[i].mini.ColorPersistent.Blue:= 1;
    Stations[i].mini.Anchor(hpMiddle, hpMiddle, iX);
    Stations[i].mini.Anchor(vpMiddle, vpMiddle, iY);
    iX:= round(Stations[i].Translation.X - SceneRocket.Translation.X);
    iY:= round(Stations[i].Translation.Y - SceneRocket.Translation.Y);

    HintAsteroids.Add(Vector2(iX, iY),
      Vector3(Display_XY.X, Display_XY.Y, MainViewport.Camera.Orthographic.Scale),
      Stations[i].CaptionStation,
      Stations[i].IsDestination,
      Self);
  end;
end;

function TStatePlay.Press(const Event: TInputPressRelease): Boolean;

  procedure HintClose;
  begin
    if HintRadar.Exists then
    begin
      HintRadar.Exists:= False;
      TimerHint.Exists:= True; 
      TimerHint.OnTimer:= @HintingRadar;
      if HintRocket.Exists then
        HintRocket.Exists:= False;
    end
    else
      TimerHint.IntervalSeconds:= 15;
  end;

begin
  Result := inherited;
  if Result then Exit; // allow the ancestor to handle keys

  if NOT(Rocket.Landing) then
  begin
    if hyperJump_count > 0 then
    begin
      if NOT(Event.IsKey(keyR)) then
        hyperJump_count:= hyperJump_count - 1;
    end
    else
      hyperJump_count:= hyperJump_count + 1;
    with Rocket do
    begin
      if Event.IsKey(keyW) OR Event.IsKey(keyArrowUp) then
      begin
        Rocket.Speed.Y := Rocket.Speed.Y + Profile.BaseSpeed * cos(Rocket.Rotation);
        Rocket.Speed.X := Rocket.Speed.X - Profile.BaseSpeed * sin(Rocket.Rotation);
        HintClose;
        SceneRocket.PlayAnimation('Speed', false);
      end
      else if Event.IsKey(keyS) OR Event.IsKey(keyArrowDown) then
      begin
        Speed.Y := Speed.Y - Profile.BaseSpeed * cos(Rotation);
        Speed.X := Speed.X + Profile.BaseSpeed * sin(Rotation);
        HintClose;
        SceneRocket.PlayAnimation('Down', false);
      end
      else if Event.IsKey(keyA) OR Event.IsKey(keyArrowLeft) then
      begin
        Rotation := Rocket.Rotation + Profile.BaseRotation;
        HintClose;
        SceneRocket.PlayAnimation('LeftRotate', false);
      end
      else if Event.IsKey(keyD) OR Event.IsKey(keyArrowRight) then
      begin
        Rotation := Rotation - Profile.BaseRotation;
        HintClose;
        SceneRocket.PlayAnimation('RightRotate', false);
      end
      else if Event.IsKey(keyQ) OR Event.IsKey(key4) then
      begin
        Speed.Y := Speed.Y - Profile.AddSpeed * sin(Rotation);
        Speed.X := Speed.X - Profile.AddSpeed * cos(Rotation);
        HintClose;
        SceneRocket.PlayAnimation('Left', false);
      end
      else if Event.IsKey(keyE) OR Event.IsKey(key6) then
      begin
        Speed.Y := Speed.Y + Profile.AddSpeed * sin(Rotation);
        Speed.X := Speed.X + Profile.AddSpeed * cos(Rotation);
        HintClose;
        SceneRocket.PlayAnimation('Right', false);
      end
      else if Event.IsKey(keyR) then
      begin
        hyperJump_count:= hyperJump_count + 1;
        Rocket.Speed.Y := Rocket.Speed.Y + Profile.BaseSpeed * cos(Rocket.Rotation);
        Rocket.Speed.X := Rocket.Speed.X - Profile.BaseSpeed * sin(Rocket.Rotation);
        WritelnLog(IntToStr(hyperJump_count));
        if hyperJump_count > 150 then
        begin
          WritelnLog(FloatToStr(Scene.TranslationXY.X) + '__' + FloatToStr(Scene.TranslationXY.Y));
          Scene.TranslationXY:= Vector2(Scene.TranslationXY.X - (Random(Profile.HyperJumpSpeed - 50000) + 50000) * sin(Rotation), Scene.TranslationXY.Y + (Random(Profile.HyperJumpSpeed - 50000) + 50000) * cos(Rotation));
          WritelnLog(FloatToStr(Scene.TranslationXY.X) + '__' + FloatToStr(Scene.TranslationXY.Y));
          Speed.Y := 1;
          Speed.X := 1;
          hyperJump_count:= hyperJump_count - 50;
        end;
        HintClose;
      end;
    end;
  end else
    if Event.IsKey(keySpace) then
    begin
      if (SceneRocket.PlayAnimation('Starting', false)) then
      begin
        Rocket.Landing:= False;
        HintClose;
        Rocket.Speed.Y:= 3;
        Space_on_Start.Exists:= False;
      end;
    end;

  if Event.IsKey(keyX) then
  begin
    if (RadarZoom < 2000000) then
     RadarZoom:= RadarZoom + 200;
    HintClose;
  end
  else
  if Event.IsKey(keyZ) then
  begin
    if (RadarZoom > 1000) then
     RadarZoom:= RadarZoom - 200;
    HintClose;
  end
  else
  if Event.IsKey(keyC) then
  begin
    RadarZoom:= 2000;
    HintClose;
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

procedure TStatePlay.HintingRadar(Sender: TObject);
begin
  HintRadar.Exists:= True;
  TimerHint.IntervalSeconds:= 30;
  TimerHint.OnTimer:= @HintingRocket;
end;

procedure TStatePlay.HintingRocket(Sender: TObject);
begin
  HintRocket.Exists:= True;
  TimerHint.Exists:= False;
  TimerHint.OnTimer:= @HintingRadar;
end;


end.
