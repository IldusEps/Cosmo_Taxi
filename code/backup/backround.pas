unit Backround;

interface
uses Classes,
  CastleUIState, CastleScene, CastleLog;

type

{ TBackground }

TBackground = class
public
  Background: TCastleScene;
  Height, Width: Double;
  constructor Create(Background_: TCastleScene);
  function CheckBackground(x, y, xBack, yBack: Double): Boolean;
end;

implementation

{ TBackground }

constructor TBackground.Create(Background_: TCastleScene);
begin
  Background:= Background_;
end;

function TBackground.CheckBackground(x, y: Double): Boolean;
begin
  WritelnLog(Background.BoundingBox.Size.Y);
  WritelnLog(Background.Translation.Y + Background.BoundingBox.Size.Y);
  if (Background.Translation.Y + Background.BoundingBox.Size.Y + 200 > y + Height) then
     WritelnLog('FFF');
end;

end.
