unit UGameUtils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics;

const
  TILE_SIZE = 32;
  GRID_W = 20;
  GRID_H = 20;
  FORM_W = GRID_W * TILE_SIZE;
  FORM_H = GRID_H * TILE_SIZE + 60;  // extra for score bar

procedure DrawGameHeader(ACanvas: TCanvas);
function CenterTextX(ACanvas: TCanvas; const AString: string): integer;
procedure CenterText(ACanvas: TCanvas; AY: integer; const AString: string);
procedure SetFontHeader(ACanvas: TCanvas);
procedure SetFontSmall(ACanvas: TCanvas);

implementation

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

end.

