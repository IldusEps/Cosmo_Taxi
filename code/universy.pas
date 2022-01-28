unit Universy;

interface
uses
CastleVectors;

type

  { TUniversy }

  TUniversy = class
  private
    AVector2_index: Integer;
    AVector2: array of TVector2;
  public
    Equation: integer; //Уравнение, по которому определяется вселенная
    Equation_max: integer;
    Universy_Size: TVector2;

    Universy_Skips: Boolean;

    constructor Create;
    procedure SetVectors2(Count: Integer);
    function GetVector2: TVector2;
  end;

implementation
const
  { Stations Sizes and offset }
  Stations_offset_max = 200000;//100000;
  Stations_offset_min = 500;


{ TUniversy }

constructor TUniversy.Create;
begin
  Equation:= 0;
  Equation_max:= 0;

  Universy_Size:= Vector2(50000, 50000);
  Universy_Skips:= True;
end;

procedure TUniversy.SetVectors2(Count: Integer);
var
  i: Integer;
  iX, iY, t: Double;
begin
  SetLength(AVector2, 0);
  AVector2_index:= 0;
  SetLength(AVector2, Length(AVector2) + 1);
  Randomize;
  iX:= Random(Stations_offset_max - Stations_offset_min) + Stations_offset_min;
  iY:= Random(Stations_offset_max - Stations_offset_min) + Stations_offset_min;
  AVector2[Length(AVector2)-1]:= Vector2(iX, iY);
  t:= 0;  

  Randomize;
  for i:= 0 to Count do
  begin
    SetLength(AVector2, Length(AVector2) + 1);
    iX:= Random(Stations_offset_max - Stations_offset_min) + Stations_offset_min;
    iY:= Random(Stations_offset_max - Stations_offset_min) + Stations_offset_min;

    case Equation of
      0: begin
        iX:= (Stations_offset_min + iX * t) * cos(t);
        iY:= (Stations_offset_min - iY * t) * sin(t);
        if Universy_Skips then
          t:= t + 0.5 * Random(3 + round(t))
        else
          t:= t + 0.5;
      end;
      1: begin
        iX:= Universy_Size.X/2 + round(AVector2[Length(AVector2)-2].X * cos(t * pi / 180)) + iX;
        iY:= Universy_Size.Y/2 - round(AVector2[Length(AVector2)-2].Y * cos(t * pi / 180)) + iY;
        t:= t + 20;
      end;
    end;
    AVector2[Length(AVector2)-1]:= Vector2(iX, iY);
  end;
end;

function TUniversy.GetVector2: TVector2;
begin
  case Equation of
    0: begin
      GetVector2:= AVector2[AVector2_index];
    end;
  end;
  AVector2_index:= AVector2_index + 1;
end;

end.
