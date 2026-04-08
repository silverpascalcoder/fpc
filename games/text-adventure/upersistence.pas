unit uPersistence;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uGameTypes, uGameWorld;

type
  { Service class for handling Disk I/O }
  TGamePersistence = class
  public
    class procedure Save(AWorld: TGameWorld; const AFileName: string);
    class procedure Load(AWorld: TGameWorld; const AFileName: string);
  end;

implementation

class procedure TGamePersistence.Save(AWorld: TGameWorld; const AFileName: string);
var
  FS: TFileStream;
  Writer: TWriter;
  Loc: TItemLocation;
begin
  FS := TFileStream.Create(AFileName, fmCreate);
  Writer := TWriter.Create(FS, 4096);
  try
    Writer.WriteInteger(AWorld.Player.CurrentLocation);
    Writer.WriteInteger(AWorld.Player.Health);

    Writer.WriteInteger(AWorld.Ledger.Count);
    for Loc in AWorld.Ledger do
    begin
      Writer.WriteInteger(Loc.Instance.InstanceId);
      Writer.WriteInteger(Loc.LocationId);
    end;
  finally
    Writer.Free;
    FS.Free;
  end;
end;

class procedure TGamePersistence.Load(AWorld: TGameWorld; const AFileName: string);
var
  FS: TFileStream;
  Reader: TReader;
  i, LCount, LInstID, LLocID: Integer;
  Loc: TItemLocation;
begin
  if not FileExists(AFileName) then Exit;

  FS := TFileStream.Create(AFileName, fmOpenRead);
  Reader := TReader.Create(FS, 4096);
  try
    AWorld.Player.CurrentLocation := Reader.ReadInteger;
    AWorld.CurrentLocation := AWorld.Player.CurrentLocation;
    AWorld.Player.Health := Reader.ReadInteger;

    LCount := Reader.ReadInteger;
    for i := 1 to LCount do
    begin
      LInstID := Reader.ReadInteger;
      LLocID := Reader.ReadInteger;

      for Loc in AWorld.Ledger do
      begin
        if Loc.Instance.InstanceId = LInstID then
        begin
          Loc.LocationId := LLocID;
          Break;
        end;
      end;
    end;
  finally
    Reader.Free;
    FS.Free;
  end;
end;

end.
