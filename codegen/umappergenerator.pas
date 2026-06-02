unit uMapperGenerator;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uUtils;

function GenJSONMapper(const T: TTableDef; Mode: TNamingMode): string;
function GenDBMapper(const T: TTableDef; Mode: TNamingMode): string;

implementation

function GenJSONMapper(const T: TTableDef; Mode: TNamingMode): string;
var
  SL: TStringList;
  UnitName, ModelUnit: string;
  F: TFieldDef;
begin
  SL := TStringList.Create;
  try
    UnitName := JSONMapperUnitName(T, Mode);   // e.g. CustomerJSON
    ModelUnit := ModelUnitName(T, Mode);

    SL.Add('unit ' + UnitName + ';');
    SL.Add('');
    SL.Add('{$mode objfpc}{$H+}');
    SL.Add('');
    SL.Add('interface');
    SL.Add('');
    SL.Add('uses SysUtils, fpjson, ' + ModelUnit + ';');
    SL.Add('');
    SL.Add('type');
    SL.Add('  T' + T.UnitName + 'JSONMapper = class');
    SL.Add('  public');
    SL.Add('    class function ToJSON(const R: T' + T.UnitName + 'Record): TJSONObject; static;');
    SL.Add('    class function FromJSON(J: TJSONObject): T' + T.UnitName + 'Record; static;');
    SL.Add('  end;');
    SL.Add('');
    SL.Add('implementation');
    SL.Add('');

    // ToJSON
    SL.Add('class function T' + T.UnitName + 'JSONMapper.ToJSON(const R: T' + T.UnitName + 'Record): TJSONObject;');
    SL.Add('begin');
    SL.Add('  Result := TJSONObject.Create;');

    for F in T.Fields do
    begin
      if F.PascalType = 'string' then
        SL.Add('  Result.Add(''' + F.JSONName + ''', R.' + F.Name + ');')
      else if F.PascalType = 'Int64' then
        SL.Add('  Result.Add(''' + F.JSONName + ''', R.' + F.Name + ');')
      else if F.PascalType = 'Boolean' then
        SL.Add('  Result.Add(''' + F.JSONName + ''', R.' + F.Name + ');')
      else if F.PascalType = 'Double' then
        SL.Add('  Result.Add(''' + F.JSONName + ''', R.' + F.Name + ');')
      else
        SL.Add('  Result.Add(''' + F.JSONName + ''', R.' + F.Name + ');');
    end;

    SL.Add('end;');
    SL.Add('');

    // FromJSON
    SL.Add('class function T' + T.UnitName + 'JSONMapper.FromJSON(J: TJSONObject): T' + T.UnitName + 'Record;');
    SL.Add('begin');

    for F in T.Fields do
    begin
      if F.PascalType = 'string' then
        SL.Add('  Result.' + F.Name + ' := J.Get(''' + F.JSONName + ''', '''');')
      else if F.PascalType = 'Int64' then
        SL.Add('  Result.' + F.Name + ' := J.Get(''' + F.JSONName + ''', 0);')
      else if F.PascalType = 'Boolean' then
        SL.Add('  Result.' + F.Name + ' := J.Get(''' + F.JSONName + ''', False);')
      else if F.PascalType = 'Double' then
        SL.Add('  Result.' + F.Name + ' := J.Get(''' + F.JSONName + ''', 0.0);')
      else
        SL.Add('  Result.' + F.Name + ' := J.Get(''' + F.JSONName + ''', '''');');
    end;

    SL.Add('end;');
    SL.Add('');
    SL.Add('end.');

    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

function GenDBMapper(const T: TTableDef; Mode: TNamingMode): string;
var
  SL: TStringList;
  UnitName, ModelUnit: string;
  F: TFieldDef;
begin
  SL := TStringList.Create;
  try
    UnitName := MapperUnitName(T, Mode);
    ModelUnit := ModelUnitName(T, Mode);

    SL.Add('unit ' + UnitName + ';');
    SL.Add('');
    SL.Add('{$mode objfpc}{$H+}');
    SL.Add('');
    SL.Add('interface');
    SL.Add('');
    SL.Add('uses SysUtils, sqldb, ' + ModelUnit + ';');
    SL.Add('');
    SL.Add('type');
    SL.Add('  T' + T.UnitName + 'DBMapper = class');
    SL.Add('  public');
    SL.Add('    class function SQL_SELECT_ALL: string; static;');
    SL.Add('    class function FromDataset(Q: TSQLQuery): T' + T.UnitName + 'Record; static;');
    SL.Add('  end;');
    SL.Add('');
    SL.Add('implementation');
    SL.Add('');
    SL.Add('class function T' + T.UnitName + 'DBMapper.SQL_SELECT_ALL: string;');
    SL.Add('begin');
    SL.Add('  Result := ''SELECT * FROM ' + UpperCase(T.TableName) + ''';');
    SL.Add('end;');
    SL.Add('');
    SL.Add('class function T' + T.UnitName + 'DBMapper.FromDataset(Q: TSQLQuery): T' + T.UnitName + 'Record;');
    SL.Add('begin');
    for F in T.Fields do
    begin
      if F.PascalType = 'string' then
        SL.Add('  Result.' + F.Name + ' := Q.FieldByName(''' + F.DBName + ''').AsString;')
      else if F.PascalType = 'Int64' then
        SL.Add('  Result.' + F.Name + ' := Q.FieldByName(''' + F.DBName + ''').AsLargeInt;')
      else if F.PascalType = 'Boolean' then
        SL.Add('  Result.' + F.Name + ' := Q.FieldByName(''' + F.DBName + ''').AsBoolean;')
      else if F.PascalType = 'Double' then
        SL.Add('  Result.' + F.Name + ' := Q.FieldByName(''' + F.DBName + ''').AsFloat;')
      else if F.PascalType = 'TDate' then
        SL.Add('  Result.' + F.Name + ' := Q.FieldByName(''' + F.DBName + ''').AsDateTime;')
      else if F.PascalType = 'TTime' then
        SL.Add('  Result.' + F.Name + ' := Q.FieldByName(''' + F.DBName + ''').AsDateTime;')
      else if F.PascalType = 'TDateTime' then
        SL.Add('  Result.' + F.Name + ' := Q.FieldByName(''' + F.DBName + ''').AsDateTime;')
      else
        SL.Add('  Result.' + F.Name + ' := Q.FieldByName(''' + F.DBName + ''').AsString;');
    end;
    SL.Add('end;');
    SL.Add('');
    SL.Add('end.');
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

end.

