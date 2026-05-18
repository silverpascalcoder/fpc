program mustachedemo3;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, fpjson, fpmustache;

procedure RunRenderTest(const TestTitle: String; Context: TJSONObject);
var
  Engine: TMustache;
  Template: String;
  ResultString: String;
begin
  Template := 'Client Status: {{client_name}}' + LineEnding +
              '{{#has_notes}}' +
              '  [NOTES]: {{notes}}' + LineEnding +
              '{{/has_notes}}' +
              '{{^has_notes}}' +
              '  [ALERT]: No special notes or requirements provided for this account.' + LineEnding +
              '{{/has_notes}}';

  Engine := TMustache.Create(nil);
  try
    Engine.Template:= Template;
    ResultString := Engine.Render(Context);
    Writeln('--- ', TestTitle, ' ---');
    Writeln(ResultString);
  finally
    Engine.Free;
  end;
end;

var
  ContextA, ContextB: TJSONObject;
begin
  // Test Case A: Has Notes (Evaluates to True)
  ContextA := TJSONObject.Create;
  try
    ContextA.Add('client_name', 'Alpha Corporate Events');
    ContextA.Add('has_notes', True);
    ContextA.Add('notes', 'Requires early access to the venue for tech setup.');

    RunRenderTest('Test A (True Condition)', ContextA);
  finally
    ContextA.Free;
  end;

  // Test Case B: No Notes / False (Evaluates to False, triggering inverted section)
  ContextB := TJSONObject.Create;
  try
    ContextB.Add('client_name', 'Beta Catering Supplies');
    ContextB.Add('has_notes', False); // Omitting or setting to false triggers inversion
    ContextB.Add('notes', '');

    RunRenderTest('Test B (Inverted/False Condition)', ContextB);
  finally
    ContextB.Free;
  end;

  Write('Press Enter to exit...');
  Readln;
end.
