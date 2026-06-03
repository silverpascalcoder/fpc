unit uUtils;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, StrUtils, sqldb, IBConnection;

type
  TNamingMode = (nmDotted, nmFlat);

  TFieldDef = record
    Name: string;
    DBName: string;
    PascalType: string;
    JSONName: string;
  end;

  TFieldDefArray = array of TFieldDef;

  TTableDef = record
    UnitName: string;
    TableName: string;
    Fields: TFieldDefArray;
    PKDBName: string;
    PKFieldName: string;
  end;

function SmartPascalCase(const S: string): string;
function PascalCase(const S: string): string;
function AsPascalType(const F: TFieldDef): string;
function SampleValue(const F: TFieldDef; const Suffix: string): string;
function LoadTable(const TableName, DBUser, DBPass, DBPath: string): TTableDef;

function ModelUnitName(const T: TTableDef; Mode: TNamingMode): string;
function MapperUnitName(const T: TTableDef; Mode: TNamingMode): string;
function ServiceUnitName(const T: TTableDef; Mode: TNamingMode): string;
function JSONMapperUnitName(const T: TTableDef; Mode: TNamingMode): string;

implementation

function SmartPascalCase(const S: string): string;
var
  Parts: TStringList;
  I: Integer;
  P, Tmp: string;
begin
  Parts := TStringList.Create;
  try
    Tmp := S;
    Tmp := StringReplace(Tmp, '_', ' ', [rfReplaceAll]);
    Tmp := StringReplace(Tmp, '-', ' ', [rfReplaceAll]);
    Tmp := Trim(Tmp);

    Parts.Delimiter := ' ';
    Parts.StrictDelimiter := False;
    Parts.DelimitedText := Tmp;

    Result := '';
    for I := 0 to Parts.Count - 1 do
    begin
      P := Trim(Parts[I]);
      if P = '' then Continue;

      if (Length(P) <= 4) and (UpperCase(P) = P) then
      begin
        Result := Result + UpperCase(P);
        Continue;
      end;

      P := LowerCase(P);
      P[1] := UpCase(P[1]);
      Result := Result + P;
    end;
  finally
    Parts.Free;
  end;
end;

function PascalCase(const S: string): string;
var
  Parts: TStringList;
  I: Integer;
  P: string;
begin
  Parts := TStringList.Create;
  try
    Parts.Delimiter := '_';
    Parts.StrictDelimiter := True;
    Parts.DelimitedText := StringReplace(S, '-', '_', [rfReplaceAll]);
    Result := '';
    for I := 0 to Parts.Count - 1 do
    begin
      P := LowerCase(Trim(Parts[I]));
      if P = '' then Continue;
      P[1] := UpCase(P[1]);
      Result := Result + P;
    end;
  finally
    Parts.Free;
  end;
end;

function SampleValue(const F: TFieldDef; const Suffix: string): string;
begin
  if F.PascalType = 'string' then
    Result := '''Sample_' + F.Name + '_' + Suffix + ''''
  else if F.PascalType = 'Int64' then
    Result := '1'
  else if F.PascalType = 'Boolean' then
    Result := 'True'
  else if F.PascalType = 'Double' then
    Result := '1.23'
  else if (F.PascalType = 'TDate') or (F.PascalType = 'TTime') or (F.PascalType = 'TDateTime') then
    Result := 'Now'
  else
    Result := '''Sample''';
end;

function AsPascalType(const F: TFieldDef): string;
begin
  if F.PascalType = 'string' then Result := 'AsString'
  else if F.PascalType = 'Int64' then Result := 'AsInteger'
  else if F.PascalType = 'Boolean' then Result := 'AsBoolean'
  else if F.PascalType = 'Double' then Result := 'AsFloat'
  else if F.PascalType = 'TDate' then Result := 'AsDate'
  else if F.PascalType = 'TTime' then Result := 'AsTime'
  else if F.PascalType = 'TDateTime' then Result := 'AsDateTime'
  else Result := 'AsString';
end;

function LoadTable(const TableName, DBUser, DBPass, DBPath: string): TTableDef;
var
  Conn: TIBConnection;
  Tx: TSQLTransaction;
  Q: TSQLQuery;
  F: TFieldDef;
  I: Integer;
  PKName: string;
begin
  Conn := TIBConnection.Create(nil);
  Tx := TSQLTransaction.Create(nil);
  Q := TSQLQuery.Create(nil);
  try
    Conn.DatabaseName := DBPath;
    Conn.UserName := DBUser;
    Conn.Password := DBPass;
    Conn.Transaction := Tx;
    Tx.DataBase := Conn;
    Q.DataBase := Conn;
    Q.Transaction := Tx;

    Conn.Open;

    Q.SQL.Text :=
      'SELECT rf.rdb$field_name, f.rdb$field_type, f.rdb$field_sub_type, ' +
      'f.rdb$field_length, f.rdb$field_precision, f.rdb$field_scale ' +
      'FROM rdb$relation_fields rf ' +
      'JOIN rdb$fields f ON f.rdb$field_name = rf.rdb$field_source ' +
      'WHERE rf.rdb$relation_name = UPPER(:t) ' +
      'ORDER BY rf.rdb$field_position';

    Q.ParamByName('t').AsString := TableName;
    Q.Open;
    if Q.IsEmpty then
    begin
      Writeln('Table ', TableName, ' not found in database');
      Writeln('Exiting program');
      Halt(1);
    end;

    Result.TableName := LowerCase(TableName);

    SetLength(Result.Fields, Q.RecordCount);
    I := 0;
    while not Q.EOF do
    begin
      F.DBName := Trim(Q.FieldByName('rdb$field_name').AsString);
      F.Name := F.DBName;
      F.JSONName := F.DBName;

      case Q.FieldByName('rdb$field_type').AsInteger of
        7, 8, 16: F.PascalType := 'Int64';
        14, 37:   F.PascalType := 'string';
        23:       F.PascalType := 'Boolean';
        10, 27:   F.PascalType := 'Double';
        12:       F.PascalType := 'TDate';
        13:       F.PascalType := 'TTime';
        35:       F.PascalType := 'TDateTime';
      else
        F.PascalType := 'string';
      end;

      Result.Fields[I] := F;
      Inc(I);
      Q.Next;
    end;
    Q.Close;

    PKName := '';
    Q.SQL.Text :=
      'SELECT sg.rdb$field_name ' +
      'FROM rdb$relation_constraints rc ' +
      'JOIN rdb$index_segments sg ON sg.rdb$index_name = rc.rdb$index_name ' +
      'WHERE rc.rdb$relation_name = UPPER(:t) ' +
      'AND rc.rdb$constraint_type = ''PRIMARY KEY'' ' +
      'ORDER BY sg.rdb$field_position';

    Q.ParamByName('t').AsString := TableName;
    Q.Open;
    if not Q.EOF then
      PKName := Trim(Q.FieldByName('rdb$field_name').AsString);
    Q.Close;

    if PKName = '' then
      PKName := 'id';

    Result.PKDBName := PKName;
    Result.PKFieldName := PKName;
  finally
    Q.Free;
    Tx.Free;
    Conn.Free;
  end;
end;

function ModelUnitName(const T: TTableDef; Mode: TNamingMode): string;
begin
  if Mode = nmDotted then
    Result := 'Model.' + T.UnitName
  else
    Result := T.UnitName + 'Model';
end;

function MapperUnitName(const T: TTableDef; Mode: TNamingMode): string;
begin
  if Mode = nmDotted then
    Result := 'Mapper.' + T.UnitName + '.DB'
  else
    Result := T.UnitName + 'DBMapper';
end;

function JSONMapperUnitName(const T: TTableDef; Mode: TNamingMode): string;
begin
  if Mode = nmDotted then
    Result := 'Mapper.' + T.UnitName + '.JSON'
  else
    Result := T.UnitName + 'JSONMapper';
end;

function ServiceUnitName(const T: TTableDef; Mode: TNamingMode): string;
begin
  if Mode = nmDotted then
    Result := 'Service.' + T.UnitName
  else
    Result := T.UnitName + 'Service';
end;

end.

