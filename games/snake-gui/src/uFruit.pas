unit uFruit;

{$mode objfpc}{$H+}

// ---------------------------------------------------------------------------
// All fruit-related types and logic.
//
// Responsibilities:
//   - Define fruit kind and state enums.
//   - Define the TFruit record.
//   - Provide spawn logic (random kind, random rotten roll).
//   - Provide score calculation for an eaten fruit.
//   - Track the pear move countdown.
//
// Does NOT know about: drawing, assets, the snake, or the form.
// ---------------------------------------------------------------------------

interface

{$modeswitch advancedrecords}
uses
  Classes, SysUtils;

const
  // Spawn probabilities (percent, must sum <= 100)
  FRUIT_PEAR_CHANCE   = 30;   // 30% pear, 70% apple
  FRUIT_ROTTEN_CHANCE = 15;   // 15% of any fruit is rotten

  // How many snake moves a pear stays on the board before despawning
  PEAR_MOVES          = 20;

  // Base score values -- rotten negates these
  SCORE_APPLE         = 10;
  SCORE_PEAR          = 25;

  // Sentinel meaning "this fruit never expires"
  MOVES_UNLIMITED     = -1;

type
  // What kind of fruit it is.
  TFruitKind = (fkApple, fkPear);

  // Whether the fruit is rotten.
  // Rotten fruit looks identical to normal but costs points instead of awarding them.
  TFruitState = (fsNormal, fsRotten);

  // A single piece of fruit on the board.

  { TFruit }

  TFruit = record
    Location  : TPoint;
    Kind      : TFruitKind;
    State     : TFruitState;

    // Moves remaining before this fruit despawns.
    // MOVES_UNLIMITED (-1) = never expires (apple).
    // Counts down each snake move; despawns when it reaches 0.
    MovesLeft : Integer;

    procedure DecrementMoves;
    // Returns True if this fruit expires and has run out of moves.
    function IsExpired: Boolean;
    function IsAtLocation(APoint: TPoint): Boolean;
    function ScoreValue: Integer;
  end;

// Spawn a new fruit at a random location, rolling kind and rotten state.
// AIsOccupied is a callback so uFruit doesn't need to know about the snake.
type
  TOccupiedFunc = function(APoint: TPoint): Boolean of object;

function SpawnFruit(AIsOccupied: TOccupiedFunc;
                    AGridW, AGridH: Integer): TFruit;

implementation

// ---------------------------------------------------------------------------
// TFruit
// ---------------------------------------------------------------------------

function TFruit.IsExpired: Boolean;
begin
  Result := (MovesLeft <> MOVES_UNLIMITED) and (MovesLeft <= 0);
end;

function TFruit.IsAtLocation(APoint: TPoint): Boolean;
begin
  result := self.Location = APoint;
end;

procedure TFruit.DecrementMoves;
begin
  if MovesLeft <> MOVES_UNLIMITED then
    Dec(MovesLeft);
end;

function TFruit.ScoreValue: Integer;
var
  Base: Integer;
begin
  case Kind of
    fkApple : Base := SCORE_APPLE;
    fkPear  : Base := SCORE_PEAR;
  else        Base := SCORE_APPLE;
  end;

  // Rotten fruit deducts the same value it would have awarded.
  if State = fsRotten then
    Result := -Base
  else
    Result := Base;
end;

// ---------------------------------------------------------------------------
// SpawnFruit
// ---------------------------------------------------------------------------

function SpawnFruit(AIsOccupied: TOccupiedFunc;
                    AGridW, AGridH: Integer): TFruit;
var
  LPoint: TPoint;
begin
  repeat
    LPoint.X := Random(AGridW);
    LPoint.Y := Random(AGridH);
  until not AIsOccupied(LPoint);

  Result.Location := LPoint;

  // Roll fruit kind: FRUIT_PEAR_CHANCE% pear, rest apple
  if Random(100) < FRUIT_PEAR_CHANCE then
  begin
    Result.Kind      := fkPear;
    Result.MovesLeft := PEAR_MOVES;
  end
  else
  begin
    Result.Kind      := fkApple;
    Result.MovesLeft := MOVES_UNLIMITED;
  end;

  // Roll rotten: same probability regardless of kind
  if Random(100) < FRUIT_ROTTEN_CHANCE then
    Result.State := fsRotten
  else
    Result.State := fsNormal;
end;

end.
