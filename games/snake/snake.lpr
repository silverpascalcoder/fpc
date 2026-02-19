program snakegame;

{$mode objfpc}{$H+}

uses
  ncurses, sysutils;

const
  W = 40;
  H = 20;
  MaxLen = 400;

type
  TPoint = record
    X, Y: Integer;
  end;

var
  Snake: array[1..MaxLen] of TPoint;
  Len: Integer;
  DirX, DirY: Integer;
  Food: TPoint;
  Score: Integer;
  GameOver: Boolean;
  DelayMs: Integer;

procedure InitGame;
var
  i: Integer;
begin
  Randomize;

  {setup initial position of snake}
  Len := 5;
  for i := 1 to Len do
  begin
    Snake[i].X := W div 2 - i;
    Snake[i].Y := H div 2;
  end;

  {initial location of food/fruit}
  Food.X := Random(W - 2) + 2;
  Food.Y := Random(H - 2) + 2;

  {other variables...}
  DirX := 1;
  DirY := 0;
  Score := 0;
  DelayMs := 180;
  GameOver := False;
end;

procedure DrawBorder;
var
  x, y: Integer;
begin
  attron(COLOR_PAIR(3));
  for x := 1 to W do
  begin
    mvaddch(1, x, Ord('#'));
    mvaddch(H, x, Ord('#'));
  end;

  for y := 1 to H do
  begin
    mvaddch(y, 1, Ord('#'));
    mvaddch(y, W, Ord('#'));
  end;
  attroff(COLOR_PAIR(3));
end;

procedure DrawSnake;
var
  i: Integer;
begin
  attron(COLOR_PAIR(1));
  mvaddch(Snake[1].Y, Snake[1].X, Ord('O'));
  for i := 2 to Len do
  begin
    mvaddch(Snake[i].Y, Snake[i].X, Ord('o'));
  end;
  attroff(COLOR_PAIR(1));
end;

procedure DrawFood;
begin
  attron(COLOR_PAIR(2));
  mvaddch(Food.Y, Food.X, Ord('*'));
  attroff(COLOR_PAIR(2));
end;

procedure SpawnFood;
begin
  Food.X := Random(W - 2) + 2;
  Food.Y := Random(H - 2) + 2;
end;

procedure UpdateDirection;
var
  ch: Integer;
begin
  {in each case, want to ensure movement is not 180 degrees}
  ch := getch;
  case ch of
    KEY_UP: if DirY <> 1 then
      begin
        DirX := 0;
        DirY := -1;
      end;
    KEY_DOWN: if DirY <> -1 then
      begin
        DirX := 0;
        DirY := 1;
      end;
    KEY_LEFT: if DirX <> 1 then
      begin
        DirX := -1;
        DirY := 0;
      end;
    KEY_RIGHT: if DirX <> -1 then
      begin
        DirX := 1;
        DirY := 0;
      end;
    27: GameOver := True; // ESC
  end;
end;

procedure MoveSnake;
var
  i: Integer;
  NewHead: TPoint;
begin
  {update the position of snake}
  NewHead.X := Snake[1].X + DirX;
  NewHead.Y := Snake[1].Y + DirY;

  {check collision (!) with border?}
  if (NewHead.X <= 1) or (NewHead.X >= W) or
     (NewHead.Y <= 1) or (NewHead.Y >= H) then
  begin
    GameOver := True;
    Exit;
  end;

  {check if snake runs into itself}
  for i := 1 to Len do
    if (Snake[i].X = NewHead.X) and (Snake[i].Y = NewHead.Y) then
    begin
      GameOver := True;
      Exit;
    end;

  {update points of the snake}
  for i := Len downto 2 do
    Snake[i] := Snake[i - 1];
  Snake[1] := NewHead;

  {finally, check if the snake has found the food}
  if (Snake[1].X = Food.X) and (Snake[1].Y = Food.Y) then
  begin
    if Len < MaxLen then
      Inc(Len);
    Snake[Len] := Snake[Len - 1];
    Inc(Score);
    if DelayMs > 40 then
      Dec(DelayMs, 5);
    SpawnFood;
  end;
end;

procedure DrawHUD;
begin
  mvprintw(H + 1, 1, PChar('Score: ' + IntToStr(Score) + '   ESC to quit'));
end;

procedure GameLoop;
begin
  while not GameOver do
  begin
    erase;
    DrawBorder;
    DrawSnake;
    DrawFood;
    DrawHUD;
    refresh;

    UpdateDirection;
    MoveSnake;

    napms(DelayMs);
  end;
end;

begin
  initscr;

  start_color;
  use_default_colors;
  init_pair(1, COLOR_GREEN, -1);  // snake
  init_pair(2, COLOR_RED, -1);    // food
  init_pair(3, COLOR_WHITE, -1);  // border

  noecho;
  curs_set(0);
  keypad(stdscr, True);
  nodelay(stdscr, True);

  InitGame;
  GameLoop;

  nodelay(stdscr, False);
  timeout(-1);
  mvprintw(H + 2, 1, PChar('Game Over. Final score: ' + IntToStr(Score)));
  refresh;
  getch;

  endwin;
end.

