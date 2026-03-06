unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, LCLType, LCLIntf,
  uAssets, UHighScore, UGameUtils;  // TAssetManager, TSprite



type

  TGameState = (gsMenu, gsPaused, gsPlaying, gsGameOver, gsHighScores);

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
    FHighScores: THighScoreList;
    FState: TGameState;

    procedure CheckHighScores;
    procedure DrawBMPTile(ABMP: TBitmap; ACol, ARow: integer);
    procedure DrawHallOfFame;
    procedure DrawOverlay(const AHeader, ASubText: string);
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
  FHighScores := THighScoreList.Create(10);
  FHighScores.Load;

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

procedure TMainForm.CheckHighScores;
var
  LName: string;
begin
  if FHighScores.IsQualified(FScore) then
  begin
    LName := InputBox('New High Score!',
      'Unexpectedly competent. Name?', 'Player');
    FHighScores.AddScore(LName, FScore);
    FHighScores.Save;
  end;
  FState := gsGameOver;
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
    CheckHighScores;
    Exit;
  end;

  Len := Length(FSnake);

  // Self collision (exclude tail -- it vacates its cell this tick)
  for I := 0 to Len - 2 do
    if FSnake[I] = NewHead then
    begin
      CheckHighScores;
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
  if ((DXi = -1) and (DYo = 1)) or
     ((DYi = -1) and (DXo = 1)) then
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
  if ((DXi = 1) and (DYo = -1)) or
     ((DYi = 1) and (DXo = -1)) then
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

procedure TMainForm.DrawOverlay(const AHeader, ASubText: string);
var
  LCanvas: TCanvas;
begin
  LCanvas := FBuffer.Canvas;

  // 1. Draw the semi-transparent "dimmer"
  // We use a dark brush with a pattern or just a solid dark fill
  LCanvas.Brush.Color := clBlack;
  LCanvas.Brush.Style := bsSolid;
  // This gives that "focused" look over the grid
  LCanvas.Rectangle(40, 100, FORM_W - 40, FORM_H - 100);

  // 2. Header text
  LCanvas.Font.Color := clWhite;
  LCanvas.Font.Size := 24;
  LCanvas.Font.Style := [fsBold];
  LCanvas.Brush.Style := bsClear;
  CenterText(LCanvas, 140, AHeader);

  // 3. Sub-text (instructions)
  LCanvas.Font.Size := 12;
  LCanvas.Font.Style := [];
  // Handling the sLineBreak if passed in ASubText
  LCanvas.TextOut(CenterTextX(LCanvas, ASubText), 220, ASubText);
end;

procedure TMainForm.DrawHallOfFame;
var
  LCanvas: TCanvas;
  i: Integer;
  LText, LScoreStr: string;
  YPos: Integer;
begin
  LCanvas := FBuffer.Canvas;

  // Background Box
  LCanvas.Brush.Color := $1A1A1A; // Deep charcoal
  LCanvas.FillRect(20, 80, FORM_W - 20, FORM_H - 40);

  // Header
  LCanvas.Font.Color := $00FFCC; // Minty green for that retro look
  LCanvas.Font.Size := 20;
  LCanvas.Font.Style := [fsBold];
  CenterText(LCanvas, 100, 'TOP 10 SLITHERS');

  // Table Headers
  LCanvas.Font.Size := 10;
  LCanvas.Font.Color := clGray;
  LCanvas.TextOut(60, 140, 'PLAYER');
  LCanvas.TextOut(FORM_W - 120, 140, 'SCORE');

  LCanvas.Pen.Color := clGray;
  LCanvas.MoveTo(60, 160);
  LCanvas.LineTo(FORM_W - 60, 160);

  // List Entries
  LCanvas.Font.Color := clWhite;
  YPos := 175;

  for i := 0 to High(FHighScores.Entries) do
  begin
    LText := Format('%2d. %s', [i + 1, FHighScores.Entries[i].PlayerName]);
    LScoreStr := IntToStr(FHighScores.Entries[i].Score);

    LCanvas.TextOut(60, YPos, LText);
    // Right-align the score
    LCanvas.TextOut(FORM_W - 60 - LCanvas.TextWidth(LScoreStr), YPos, LScoreStr);

    Inc(YPos, 22);
  end;

  // Footer
  LCanvas.Font.Size := 9;
  LCanvas.Font.Color := clYellow;
  CenterText(LCanvas, FORM_H - 70, 'Press H to return to game');
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

  case FState of
    gsMenu:      DrawOverlay('SNAKE', 'Press SPACE to Start');
    gsPaused:    DrawOverlay('PAUSED', 'Press SPACE to Resume');
    gsGameOver:  DrawOverlay('GAME OVER', 'Sucks to be you! Space to try again.');
    gsHighScores: DrawHallOfFame;
  end;
end;

// -----------------------------------------------------------------------------
// Event handlers
// -----------------------------------------------------------------------------

procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  if  FState = gsPlaying then
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
  case FState of
    { --- WE ARE AT THE START SCREEN --- }
    gsMenu:
    begin
      if Key = VK_SPACE then
      begin
        InitGame;
        FState := gsPlaying;
      end
      else if Key = Ord('H') then
        FState := gsHighScores;
    end;

    { --- WE ARE ACTIVELY SLITHERING --- }
    gsPlaying:
    begin
      case Key of
        VK_SPACE: FState := gsPaused;

        VK_RIGHT, Ord('D'):
          if FDirection <> dirLeft then FNextDir := dirRight;

        VK_LEFT, Ord('A'):
          if FDirection <> dirRight then FNextDir := dirLeft;

        VK_UP, Ord('W'):
          if FDirection <> dirDown then FNextDir := dirUp;

        VK_DOWN, Ord('S'):
          if FDirection <> dirUp then FNextDir := dirDown;
      end;
    end;

    { --- GAME IS PAUSED --- }
    gsPaused:
    begin
      if Key = VK_SPACE then
        FState := gsPlaying
      else if Key = Ord('H') then
        FState := gsHighScores;
    end;

    { --- THE END OF THE ROAD --- }
    gsGameOver:
    begin
      if Key = VK_SPACE then
      begin
        InitGame;
        FState := gsPlaying;
      end
      else if Key = Ord('H') then
        FState := gsHighScores;
    end;

    { --- VIEWING THE LEADERBOARD --- }
    gsHighScores:
    begin
      // Return to Menu or Game Over screen when 'H' or ESC is pressed
      if (Key = Ord('H')) or (Key = VK_ESCAPE) then
        FState := gsMenu;
    end;
  end;

  // Global Escape key to quit the app
  if Key = VK_ESCAPE then
  begin
    if FState <> gsHighScores then // Let ESC exit high scores first
      Close;
  end;

  Invalidate; // Force a repaint to show the state change
end;

initialization
  Randomize;

end.
