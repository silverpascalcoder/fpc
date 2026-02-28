unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, LCLType, LCLIntf,
  uAssets;  // TAssetManager, TSprite

const
  TILE_SIZE = 32;
  GRID_W = 20;
  GRID_H = 20;
  FORM_W = GRID_W * TILE_SIZE;
  FORM_H = GRID_H * TILE_SIZE + 60;  // extra for score bar

type

  { TMainForm }

  TMainForm = class(TForm)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormPaint(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    FAssets: TAssetManager;
    FBuffer: TBitmap;

    FSnake: array of TPoint;
    FDirection: TDirection;
    FNextDir: TDirection;
    FFood: TPoint;
    FScore: integer;
    FHighScore: integer;
    FGameOver: boolean;
    FPaused: boolean;
    FStarted: boolean;

    procedure DrawBMPTile(ABMP: TBitmap; ACol, ARow: integer);
    procedure DrawTile(ASprite: TSprite; ACol, ARow: integer);
    procedure InitGame;
    procedure PlaceFood;
    procedure MoveSnake;
    function SnakeAt(APoint: TPoint): boolean;

    procedure DrawGame;
    function GetDirection(ADX, ADY: integer): TDirection;
    procedure DrawSnake;
    function BodySprite(AIdx: integer): TSprite;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

// -----------------------------------------------------------------------------
// Form lifetime
// -----------------------------------------------------------------------------

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Caption := 'Snake';
  Width := FORM_W;
  Height := FORM_H;
  BorderStyle := bsSingle;
  Position := poScreenCenter;
  DoubleBuffered := True;

  FBuffer := TBitmap.Create;
  FBuffer.Width := FORM_W;
  FBuffer.Height := FORM_H;

  FAssets := TAssetManager.Create;
  FAssets.Load;

  FHighScore := 0;
  InitGame;

  Timer1.Interval := 400; //140;
  Timer1.Enabled := True;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FAssets.Free;
  FBuffer.Free;
end;

// -----------------------------------------------------------------------------
// Game logic
// -----------------------------------------------------------------------------

procedure TMainForm.InitGame;
var
  Mid: integer;
begin
  FGameOver := False;
  FPaused := False;
  FStarted := False;
  FScore := 0;
  FDirection := dirRight;
  FNextDir := dirRight;

  Mid := GRID_H div 2;
  SetLength(FSnake, 3);
  FSnake[0] := TPoint.Create(GRID_W div 2 + 1, Mid);  // head
  FSnake[1] := TPoint.Create(GRID_W div 2, Mid);
  FSnake[2] := TPoint.Create(GRID_W div 2 - 1, Mid);  // tail

  PlaceFood;
end;

procedure TMainForm.PlaceFood;
var
  LPoint: TPoint;
begin
  repeat
    LPoint.X := Random(GRID_W);
    LPoint.Y := Random(GRID_H);
  until not SnakeAt(LPoint);
  FFood := LPoint;
end;

function TMainForm.SnakeAt(APoint: TPoint): boolean;
var
  I: integer;
begin
  for I := 0 to High(FSnake) do
    if (FSnake[I] = APoint) then
      Exit(True);
  Result := False;
end;

procedure TMainForm.MoveSnake;
var
  NewHead: TPoint;
  I, Len: integer;
begin
  FDirection := FNextDir;
  NewHead := FSnake[0];

  case FDirection of
    dirRight: Inc(NewHead.X);
    dirLeft: Dec(NewHead.X);
    dirUp: Dec(NewHead.Y);
    dirDown: Inc(NewHead.Y);
  end;

  // Wall collision
  if (NewHead.X < 0) or (NewHead.X >= GRID_W) or
    (NewHead.Y < 0) or (NewHead.Y >= GRID_H) then
  begin
    FGameOver := True;
    Exit;
  end;

  Len := Length(FSnake);

  // Self collision (exclude tail -- it vacates its cell this tick)
  for I := 0 to Len - 2 do
    if FSnake[I] = NewHead then
    begin
      FGameOver := True;
      Exit;
    end;

  if NewHead = FFood then
  begin
    // Grow: insert new head, keep tail
    SetLength(FSnake, Len + 1);
    for I := Len downto 1 do
      FSnake[I] := FSnake[I - 1];
    FSnake[0] := NewHead;
    Inc(FScore, 10);
    if FScore > FHighScore then FHighScore := FScore;
    PlaceFood;
    if Timer1.Interval > 60 then
      Timer1.Interval := Timer1.Interval - 2;
  end
  else
  begin
    // Slide: shift body, drop tail
    for I := Len - 1 downto 1 do
      FSnake[I] := FSnake[I - 1];
    FSnake[0] := NewHead;
  end;
end;

function TMainForm.GetDirection(ADX, ADY: integer): TDirection;
begin
  if ADX =  1 then Result := dirRight
  else if ADX = -1 then Result := dirLeft
  else if ADY = -1 then Result := dirUp
  else Result := dirDown;
end;

function TMainForm.BodySprite(AIdx: integer): TSprite;
var
  DXi, DYi, DXo, DYo: integer;
begin
  // Each body segment has two neighbours:
  //   - the segment closer to the head  (AIdx - 1)
  //   - the segment closer to the tail  (AIdx + 1)
  //
  // By comparing their coordinates, we can determine the
  // shape of this segment:
  //   - straight horizontal
  //   - straight vertical
  //   - one of four corner pieces

  // Direction *into* this segment (from the head side).
  DXi := FSnake[AIdx].X - FSnake[AIdx - 1].X;
  DYi := FSnake[AIdx].Y - FSnake[AIdx - 1].Y;

  // Direction *out of* this segment (toward the tail).
  DXo := FSnake[AIdx + 1].X - FSnake[AIdx].X;
  DYo := FSnake[AIdx + 1].Y - FSnake[AIdx].Y;

  // Straight horizontal: both neighbours differ in X only.
  if (DXi <> 0) and (DXo <> 0) then
    Exit(spBodyH);

  // Straight vertical: both neighbours differ in Y only.
  if (DYi <> 0) and (DYo <> 0) then
    Exit(spBodyV);

  // Corners:
  // We check combinations of incoming and outgoing directions.
  // Each case corresponds to one of the four possible turns.

  // Turn from left > down, or up > right  (top-left corner)
  if ((DXi = -1) and (DYo = 1)) then
    Exit(spBodyTL);

  // Turn from right > down, or up > left  (top-right corner)
  if ((DXi = 1) and (DYo = 1)) or
     ((DYi = -1) and (DXo = -1)) then
    Exit(spBodyTR);

  // Turn from left > up, or down > right  (bottom-left corner)
  if ((DXi = -1) and (DYo = -1)) or
     ((DYi = 1) and (DXo = 1)) then
    Exit(spBodyBL);

  // Turn from right > up, or down > left  (bottom-right corner)
  if ((DXi = 1) and (DYo = -1)) then
    Exit(spBodyBR);

  // Fallback: treat as horizontal if something unexpected occurs.
  Result := spBodyH;
end;


procedure TMainForm.DrawTile(ASprite: TSprite; ACol, ARow: integer);
begin
  FBuffer.Canvas.Draw(ACol * TILE_SIZE, ARow * TILE_SIZE + 60, FAssets[ASprite]);
end;


procedure TMainForm.DrawBMPTile(ABMP: TBitmap; ACol, ARow: integer);
begin
  FBuffer.Canvas.Draw(ACol * TILE_SIZE, ARow * TILE_SIZE + 60, ABMP);
end;

procedure TMainForm.DrawSnake;

  function GetTailDir: TDirection;
  var
    Len, DX, DY: integer;
  begin
    Len := High(FSnake);
    DX := FSnake[Len].X - FSnake[Len-1].X;
    DY := FSnake[Len].Y - FSnake[Len-1].Y;

    if DX =  1 then Result := dirRight
    else if DX = -1 then Result := dirLeft
    else if DY = -1 then Result := dirUp
    else Result := dirDown;
  end;

var
  Len, I: integer;
  TailDir: TDirection;
begin
  Len := Length(FSnake);
  TailDir := GetTailDir;
  DrawBMPTile(FAssets.GetTailSprite(TailDir), FSnake[Len-1].X, FSnake[Len -1].Y);
  for I := 1 to Len - 2 do
    DrawTile(BodySprite(I), FSnake[I].X, FSnake[I].Y);
  DrawBMPTile(FAssets.GetHeadSprite(FDirection), FSnake[0].X, FSnake[0].Y);
end;

procedure TMainForm.DrawGame;

const
  S_Snake = 'SNAKE';
  S_StartGame = 'Press SPACE to start';
  S_Keys = 'Arrow keys / WASD to move';
  S_Paused = 'PAUSED';
  S_ResumeGame = 'Press SPACE to resume';
  S_GameOver = 'GAME OVER';
  S_PlayAgain = 'Press SPACE to play again';

  procedure DrawGameHeader(ACanvas: TCanvas);
  begin
    ACanvas.Brush.Color := $AA000000;
    ACanvas.FillRect(0, 60, FORM_W, FORM_H);
  end;

  function CenterTextX(ACanvas: TCanvas; const AString: string): integer;
  begin
    Result := (FORM_W - ACanvas.TextWidth(AString)) div 2;
  end;

  procedure CenterText(ACanvas: TCanvas; AY: integer; const AString: string);
  begin
    ACanvas.TextOut(CenterTextX(ACanvas, AString), AY, AString)
  end;

  procedure SetFontHeader(ACanvas: TCanvas);
  begin
    ACanvas.Font.Color := clWhite;
    ACanvas.Font.Size := 22;
    ACanvas.Font.Style := [fsBold];
  end;

  procedure SetFontSmall(ACanvas: TCanvas);
  begin
    ACanvas.Font.Color := clWhite;
    ACanvas.Font.Size := 12;
    ACanvas.Font.Style := [];
  end;


var
  C, R, I, Len: integer;
  LCanvas: TCanvas;
  LScore: string;
begin
  LCanvas := FBuffer.Canvas;

  // Score bar
  LCanvas.Brush.Color := $222222;
  LCanvas.FillRect(0, 0, FORM_W, 60);
  LCanvas.Font.Color := clWhite;
  LCanvas.Font.Size := 14;
  LCanvas.Font.Style := [fsBold];
  LCanvas.Brush.Style := bsClear;
  LCanvas.TextOut(10, 10, Format('Score: %d', [FScore]));
  LCanvas.TextOut(FORM_W - 180, 10, Format('Best: %d', [FHighScore]));

  // Background grid
  for R := 0 to GRID_H - 1 do
    for C := 0 to GRID_W - 1 do
      DrawTile(spBg, C, R);

  // Food
  DrawTile(spApple, FFood.X, FFood.Y);

  // Snake: tail -> body -> head
  DrawSnake;

  // Overlays
  if not FStarted then
  begin
    DrawGameHeader(LCanvas);
    SetFontHeader(LCanvas);
    CenterText(LCanvas, 120, S_Snake);
    SetFontSmall(LCanvas);
    CenterText(LCanvas, 180, S_StartGame);
    CenterText(LCanvas, 210, S_Keys)
  end
  else if FPaused then
  begin
    DrawGameHeader(LCanvas);
    SetFontHeader(LCanvas);
    CenterText(LCanvas, 160, S_Paused);
    SetFontSmall(LCanvas);
    CenterText(LCanvas, 210, S_StartGame);
  end
  else if FGameOver then
  begin
    LScore := Format('Score: %d', [FScore]);
    DrawGameHeader(LCanvas);
    SetFontHeader(LCanvas);
    CenterText(LCanvas, 140, S_GameOver);
    SetFontSmall(LCanvas);
    CenterText(LCanvas, 200, LScore);
    CenterText(LCanvas, 230, S_PlayAgain);
  end;
end;

// -----------------------------------------------------------------------------
// Event handlers
// -----------------------------------------------------------------------------

procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  if FStarted and (not FPaused) and (not FGameOver) then
  begin
    MoveSnake;
    Invalidate;
  end;
end;

procedure TMainForm.FormPaint(Sender: TObject);
begin
  DrawGame;
  Canvas.Draw(0, 0, FBuffer);
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  case Key of
    VK_SPACE:
    begin
      if FGameOver then
      begin
        Timer1.Interval := 140;
        InitGame;
        FStarted := True;
      end
      else if not FStarted then
        FStarted := True
      else
        FPaused := not FPaused;
    end;

    VK_RIGHT,
    Ord('D'):
      if FDirection <> dirLeft then
        FNextDir := dirRight;

    VK_LEFT,
    Ord('A'):
      if FDirection <> dirRight then
        FNextDir := dirLeft;

    VK_UP,
    Ord('W'):
      if FDirection <> dirDown then
        FNextDir := dirUp;

    VK_DOWN,
    Ord('S'):
      if FDirection <> dirUp then
        FNextDir := dirDown;

    VK_ESCAPE: Close;
  end;
end;

initialization
  Randomize;

end.
