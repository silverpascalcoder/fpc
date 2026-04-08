unit uOutput;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  { Defines how the game communicates with the user }
  TOutputType = (otDescription, otInventory, otStatus, otCombat, otError, otSystem);

  { A procedural type for callbacks (Dependency Injection) }
  TOutputEvent = procedure(const AMsg: string; AType: TOutputType = otDescription) of object;

  TOutputService = class
  private
    FOnOutput: TOutputEvent;
    constructor Create;
  public
    class function Instance: TOutputService;

    { The core method to replace WriteLn }
    procedure Write(const AMsg: string; AType: TOutputType = otDescription);

    { Connect your UI/Console to this event }
    property OnOutput: TOutputEvent read FOnOutput write FOnOutput;
  end;

var
  { Global access point for the service }
  Output: TOutputService;

implementation

var
  _Instance: TOutputService = nil;

constructor TOutputService.Create;
begin
  FOnOutput := nil;
end;

class function TOutputService.Instance: TOutputService;
begin
  if _Instance = nil then _Instance := TOutputService.Create;
  Result := _Instance;
end;

procedure TOutputService.Write(const AMsg: string; AType: TOutputType = otDescription);
begin
  { If a handler is assigned, use it. Otherwise, fallback to WriteLn }
  if Assigned(FOnOutput) then
    FOnOutput(AMsg, AType)
  else
    WriteLn(AMsg);
end;

initialization
  Output := TOutputService.Instance;

finalization
  if _Instance <> nil then _Instance.Free;

end.
