program codegen;

{$mode objfpc}{$H+}
{
Generates:
1. model unit
2. json and db mapper
3. service unit
4. test programs
5. htmx/mustache templates
}

uses
  SysUtils, IniFiles, uUtils, uGenerator, uHTMXGenerator, uServiceGenerator,
  uTestGenerator, uMapperGenerator, uDBContext;

const
  INI_FILENAME = 'codegen.ini';

procedure LoadDBConfig(var DBUser, DBPass, DBPath: string);
var
  Ini: TIniFile;
begin
  if FileExists(INI_FILENAME) then
  begin
    Ini := TIniFile.Create(INI_FILENAME);
    try
      DBUser := Ini.ReadString('database', 'user', '');
      DBPass := Ini.ReadString('database', 'pass', '');
      DBPath := Ini.ReadString('database', 'path', '');
    finally
      Ini.Free;
    end;
  end;
end;

procedure SaveDBConfig(const DBUser, DBPass, DBPath: string);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(INI_FILENAME);
  try
    Ini.WriteString('database', 'user', DBUser);
    Ini.WriteString('database', 'pass', DBPass);
    Ini.WriteString('database', 'path', DBPath);
  finally
    Ini.Free;
  end;
end;

procedure ShowUsage;
begin
  Writeln('Usage: ');
  Writeln('codegen <tablename> [--flat|--dotted] [--with-pool]');
  Writeln('  [--name="Vendor Item"]');
  Writeln('  [--db-user=USER --db-pass=PASS --db-path=/path/to/db.fdb]');
  Writeln('  [--save-db]');
  Halt(1);
end;

var
  TableName: string;
  TableDef: TTableDef;
  Mode: TNamingMode;
  I: Integer;
  UsePool: Boolean;
  CustomName: string;
  DBUser, DBPass, DBPath: string;
  SaveDB: Boolean;
  Answer: string;

begin
  if ParamCount < 1 then
  begin
    ShowUsage; // And it will halt!
  end;

  Mode := nmFlat;
  UsePool := False;
  CustomName := '';
  SaveDB := False;

  DBUser := '';
  DBPass := '';
  DBPath := '';

  { Load defaults from INI if present }
  LoadDBConfig(DBUser, DBPass, DBPath);

  { Parse command-line overrides }
  for I := 2 to ParamCount do
  begin
    if ParamStr(I) = '--flat' then Mode := nmFlat;
    if ParamStr(I) = '--dotted' then Mode := nmDotted;
    if ParamStr(I) = '--with-pool' then UsePool := True;
    if ParamStr(I) = '--save-db' then SaveDB := True;

    if ParamStr(I).StartsWith('--name=') then
      CustomName := Copy(ParamStr(I), 8, Length(ParamStr(I)));

    if ParamStr(I).StartsWith('--db-user=') then
      DBUser := Copy(ParamStr(I), 11, Length(ParamStr(I)));

    if ParamStr(I).StartsWith('--db-pass=') then
      DBPass := Copy(ParamStr(I), 11, Length(ParamStr(I)));

    if ParamStr(I).StartsWith('--db-path=') then
      DBPath := Copy(ParamStr(I), 11, Length(ParamStr(I)));
  end;

  { If DB parameters still missing, prompt user }
  if (DBUser = '') or (DBPass = '') or (DBPath = '') then
  begin
    Writeln('Database configuration missing.');
    Writeln('Enter DB user: '); ReadLn(DBUser);
    Writeln('Enter DB password: '); ReadLn(DBPass);
    Writeln('Enter DB path: '); ReadLn(DBPath);

    Writeln('Save these settings to ', INI_FILENAME, ' (y/n): ');
    ReadLn(Answer);
    if LowerCase(Answer) = 'y' then
      SaveDBConfig(DBUser, DBPass, DBPath);
  end
  else if SaveDB then
  begin
    SaveDBConfig(DBUser, DBPass, DBPath);
    Writeln('Saved DB settings to ', INI_FILENAME);
  end;

  TableName := ParamStr(1);

  if TableName = '' then
  begin
    ShowUsage; // And it will halt!
  end;
  Writeln('Using DB settings: DBUser=', DBUser, ';DBPath=', DBPath);
  TableDef := LoadTable(TableName, DBUser, DBPass, DBPath);

  if CustomName <> '' then
    TableDef.UnitName := SmartPascalCase(CustomName)
  else
    TableDef.UnitName := PascalCase(TableName);

  WriteAll(TableDef, Mode, DBUser, DBPass, DBPath, CustomName);

  Writeln('Generated ', TableDef.UnitName, ' (table: ', TableDef.TableName, ')');
  if UsePool then
    Writeln('Connection pool unit generated at src/db/DBPool.pas');
end.

