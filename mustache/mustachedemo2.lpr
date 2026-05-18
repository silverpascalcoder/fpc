program mustachedemo2;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, fpjson, fpmustache;

// Helper function to cleanly build individual wedding objects
function CreateWedding(const Couple, Date, Venue: String): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('couple', Couple);
  Result.Add('date', Date);
  Result.Add('venue', Venue);
end;

var
  Engine: TMustache;
  Context: TJSONObject;
  WeddingList: TJSONArray;
  Template: String;
  ResultString: String;
begin
  Template := 'Upcoming Wedding Schedule Overview:' + LineEnding +
              '====================================' + LineEnding +
              '{{#weddings}}' +
              'Event:  {{{couple}}}' + LineEnding +
              'Date:   {{date}}' + LineEnding +
              'Venue:  {{venue}}' + LineEnding +
              '------------------------------------' + LineEnding +
              '{{/weddings}}';

  Context := TJSONObject.Create;
  try
    WeddingList := TJSONArray.Create;

    WeddingList.Add(CreateWedding('Sarah & Michael', '2026-09-12', 'The Old Church Chapel'));
    WeddingList.Add(CreateWedding('David & Jessica', '2026-10-05', 'Botanical Gardens Pavilion'));
    WeddingList.Add(CreateWedding('James & Emma',    '2026-11-21', 'Riverside Marquee'));

    Context.Add('weddings', WeddingList);

    Engine := TMustache.Create(nil);
    try
      Engine.Template:= Template;
      ResultString := Engine.Render(Context);

      Writeln('--- Demo 2 Output ---');
      Writeln(ResultString);
    finally
      Engine.Free;
    end;

  finally
    Context.Free;
  end;

  Write('Press Enter to exit...');
  Readln;
end.
