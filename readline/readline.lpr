program readline;

uses Classes, SysUtils, Crt;

procedure ReadLine(var S: string; AHistory: TStrings);
var
  Ch: Char;
  InputBuf: string;
  Pos: Integer; // Logical position in string (1..Length+1)
  OriginX: Integer;
  HistoryIdx: Integer;
begin
  OriginX := WhereX;
  InputBuf := '';
  Pos := 1;

  if Assigned(AHistory) then
    HistoryIdx := AHistory.Count
  else
    HistoryIdx := -1;

  repeat
    Ch := ReadKey;

    if Ch = #0 then // Functional key (Arrows)
    begin
      Ch := ReadKey;
      case Ch of
        #75: if Pos > 1 then Dec(Pos); // Left
        #77: if Pos <= Length(InputBuf) then Inc(Pos); // Right
        #72: if Assigned(AHistory) and (HistoryIdx > 0) then
             begin
               Dec(HistoryIdx);
               InputBuf := AHistory[HistoryIdx];
               Pos := Length(InputBuf) + 1;
             end;

        #80: if Assigned(AHistory) then
             begin
               if HistoryIdx < AHistory.Count - 1 then
               begin
                 Inc(HistoryIdx);
                 InputBuf := AHistory[HistoryIdx];
                 Pos := Length(InputBuf) + 1;
               end
               else if HistoryIdx = AHistory.Count - 1 then
               begin
                 Inc(HistoryIdx);
                 InputBuf := '';
                 Pos := 1;
               end;
             end;
      end;
    end

    else if Ch = #8 then // Backspace
    begin
      if Pos > 1 then
      begin
        Delete(InputBuf, Pos - 1, 1);
        Dec(Pos);
      end;
    end
    else if Ch = #27 then
    begin
      InputBuf := '';
      Break;
    end
    else if Ch in [#32..#126] then // Printable
    begin
      Insert(Ch, InputBuf, Pos);
      Inc(Pos);
    end;

    { The Redraw Strategy }
    GotoXY(OriginX, WhereY);
    ClrEol;
    Write(InputBuf);
    GotoXY(OriginX + Pos - 1, WhereY);

  until Ch = #13; // Enter
  S := InputBuf;
end;

var
  input: string;
  previous: tstringlist;
begin
  previous := tstringlist.create;
  previous.add('go north');
  previous.add('look');
  previous.add('take axe');

  Write('Enter string>');
  ReadLine(input, previous);
  Writeln;
  Writeln('You entered: ' + input);

end.

