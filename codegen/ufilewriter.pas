unit uFileWriter;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes;

procedure WriteStrToFile(const FileName, S: string);

implementation

procedure EnsureDirForFile(const FileName: string);
var
  Dir: string;
begin
  Dir := ExtractFileDir(FileName);
  if (Dir <> '') and (not DirectoryExists(Dir)) then
    ForceDirectories(Dir);
end;

procedure WriteStrToFile(const FileName, S: string);
var
  FS: TFileStream;
  Bytes: TBytes;
begin
  EnsureDirForFile(FileName);
  Bytes := TEncoding.UTF8.GetBytes(S);
  FS := TFileStream.Create(FileName, fmCreate);
  try
    if Length(Bytes) > 0 then
      FS.WriteBuffer(Bytes[0], Length(Bytes));
  finally
    FS.Free;
  end;
end;

end.

