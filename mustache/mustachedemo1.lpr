program mustachedemo1;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, fpjson, fpmustache;

var
  Engine: TMustache;
  Context: TJSONObject;
  Template: String;
  ResultString: String;
begin
  // 1. Define the template with placeholders
  Template := 'Hello {{name}}! Welcome back to {{platform}}.' + LineEnding;

  // 2. Set up the data context using fpjson
  Context := TJSONObject.Create;
  try
    Context.Add('name', 'Tim');
    Context.Add('platform', 'Free Pascal');

    // 3. Initialize the engine and render
    Engine := TMustache.Create(nil);
    try
      Engine.Template:= Template;
      ResultString := Engine.Render(Context);

      Writeln('--- Demo 1 Output ---');
      Writeln(ResultString);
      Writeln('---------------------');
    finally
      Engine.Free;
    end;

  finally
    // Freeing the top-level context object cleans up its internal data
    Context.Free;
  end;

  Write('Press Enter to exit...');
  Readln;
end.
