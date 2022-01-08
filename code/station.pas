unit Station;

interface
uses Classes,
  CastleUIState, CastleScene, CastleLog, SysUtils, CastleVectors, CastleTransform,
  CastleDebugTransform;

type

{ TStation }

TStation = class
public
  Scene: TCastleScene; 
  RBody: TRigidBody;
  Collider: TBoxCollider;
  {parameters}
  IsNeedTaxi: Boolean;
  TypeStation: Integer;
  constructor Create(AScene: TCastleScene; Translation: TVector2);
end;

implementation


{ TStation }

constructor TStation.Create(AScene: TCastleScene; Translation: TVector2);
var
  Debug: TDebugTransform;
begin
  Scene:= AScene;
  Scene.TranslationXY:= Translation;

  RBody := TRigidBody.Create(Scene);
  RBody.Gravity:= False;
  RBody.Dynamic:= True;
  RBody.Trigger:= True;
  RBody.Setup2D;

  Collider := TBoxCollider.Create(RBody);
  Collider.Size := Vector3(Scene.LocalBoundingBox.Size.XY, 20);

  Scene.RigidBody := RBody;

  Debug := TDebugTransform.Create(Scene);
  Debug.Attach(Scene);
  Debug.Exists := true;
end;

end.
