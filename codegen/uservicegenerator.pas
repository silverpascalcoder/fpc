unit uServiceGenerator;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uUtils;

function GenService(const T: TTableDef; Mode: TNamingMode; const APoolProfileName: string): string;

implementation

function GenService(const T: TTableDef; Mode: TNamingMode; const APoolProfileName: string): string;
var
  SL: TStringList;
  UnitName, ModelUnit, MapperUnit: string;
  F: TFieldDef;
  InsertFields, InsertParams, UpdateAssignments: string;
  I: Integer;
begin
  SL := TStringList.Create;
  try
    UnitName := ServiceUnitName(T, Mode);
    ModelUnit := ModelUnitName(T, Mode);
    MapperUnit := MapperUnitName(T, Mode);

    InsertFields := '';
    InsertParams := '';
    UpdateAssignments := '';

    for I := 0 to High(T.Fields) do
    begin
      F := T.Fields[I];

      if SameText(F.DBName, T.PKDBName) then
        Continue;

      if InsertFields <> '' then
      begin
        InsertFields := InsertFields + ', ';
        InsertParams := InsertParams + ', ';
      end;

      InsertFields := InsertFields + F.DBName;
      InsertParams := InsertParams + ':' + F.DBName;

      if UpdateAssignments <> '' then
        UpdateAssignments := UpdateAssignments + ', ';

      UpdateAssignments := UpdateAssignments + F.DBName + ' = :' + F.DBName;
    end;

    SL.Add('unit ' + UnitName + ';');
    SL.Add('');
    SL.Add('{$mode objfpc}{$H+}');
    SL.Add('');
    SL.Add('interface');
    SL.Add('');
    SL.Add('uses SysUtils, sqldb, uDBContext, ' + ModelUnit + ', ' + MapperUnit + ';');
    SL.Add('');
    SL.Add('type');
    SL.Add('  T' + T.UnitName + 'Service = class');
    SL.Add('  public');
    SL.Add('    function CreateItem(const R: T' + T.UnitName + 'Record): Int64;');
    SL.Add('    function ReadItem(ID: Int64): T' + T.UnitName + 'Record;');
    SL.Add('    function UpdateItem(const R: T' + T.UnitName + 'Record): Boolean;');
    SL.Add('    function DeleteItem(ID: Int64): Boolean;');
    SL.Add('    function GetAll: T' + T.UnitName + 'RecordList;');
    SL.Add('  end;');
    SL.Add('');
    SL.Add('implementation');
    SL.Add('');

    { CREATE }
    SL.Add('function T' + T.UnitName + 'Service.CreateItem(const R: T' + T.UnitName + 'Record): Int64;');
    SL.Add('var DB: IDBContext; Q: TSQLQuery;');
    SL.Add('begin');
    SL.Add('  DB := TDB.GetContext(''' + APoolProfileName + ''');');
    SL.Add('  Q := DB.NewQuery(''INSERT INTO ' + UpperCase(T.TableName) + ' '' + ');
    SL.Add('    ''(' + InsertFields + ') '' + ');
    SL.Add('    ''VALUES (' + InsertParams + ') '' + ');
    SL.Add('    ''RETURNING ' + T.PKDBName + ''');');
    SL.Add('  try');

    for F in T.Fields do
      if not SameText(F.DBName, T.PKDBName) then
        SL.Add('    Q.ParamByName(''' + F.DBName + ''').' + AsPascalType(F) + ' := R.' + F.Name + ';');

    SL.Add('    Q.Open;');
    SL.Add('    Result := Q.FieldByName(''' + T.PKDBName + ''').AsLargeInt;');
    SL.Add('    DB.Commit;');
    SL.Add('  finally');
    SL.Add('    Q.Free;');
    SL.Add('  end;');
    SL.Add('end;');
    SL.Add('');

    { READ }
    SL.Add('function T' + T.UnitName + 'Service.ReadItem(ID: Int64): T' + T.UnitName + 'Record;');
    SL.Add('var DB: IDBContext; Q: TSQLQuery;');
    SL.Add('begin');
    SL.Add('  DB := TDB.GetContext(''' + APoolProfileName + ''');');
    SL.Add('  Q := DB.NewQuery(''SELECT * FROM ' + UpperCase(T.TableName) + ' WHERE ' + T.PKDBName + ' = :id'');');
    SL.Add('  try');
    SL.Add('    Q.ParamByName(''id'').AsLargeInt := ID;');
    SL.Add('    Q.Open;');
    SL.Add('');
    SL.Add('    if not Q.EOF then');
    SL.Add('      Result := T' + T.UnitName + 'DBMapper.FromDataset(Q)');
    SL.Add('    else');
    SL.Add('      FillChar(Result, SizeOf(Result), 0);');
    SL.Add('');
    SL.Add('    DB.Commit;');
    SL.Add('  finally');
    SL.Add('    Q.Free;');
    SL.Add('  end;');
    SL.Add('end;');
    SL.Add('');

    { UPDATE }
    SL.Add('function T' + T.UnitName + 'Service.UpdateItem(const R: T' + T.UnitName + 'Record): Boolean;');
    SL.Add('var DB: IDBContext; Q: TSQLQuery;');
    SL.Add('begin');
    SL.Add('  DB := TDB.GetContext(''' + APoolProfileName + ''');');
    SL.Add('  Q := DB.NewQuery(''UPDATE ' + UpperCase(T.TableName) + ' SET ' + UpdateAssignments + ' WHERE ' + T.PKDBName + ' = :' + T.PKDBName + ''');');
    SL.Add('  try');

    for F in T.Fields do
      SL.Add('    Q.ParamByName(''' + F.DBName + ''').' + AsPascalType(F) + ' := R.' + F.Name + ';');

    SL.Add('    Q.ExecSQL;');
    SL.Add('    Result := Q.RowsAffected > 0;');
    SL.Add('    DB.Commit;');
    SL.Add('  finally');
    SL.Add('    Q.Free;');
    SL.Add('  end;');
    SL.Add('end;');
    SL.Add('');

    { DELETE }
    SL.Add('function T' + T.UnitName + 'Service.DeleteItem(ID: Int64): Boolean;');
    SL.Add('var DB: IDBContext; Q: TSQLQuery;');
    SL.Add('begin');
    SL.Add('  DB := TDB.GetContext(''' + APoolProfileName + ''');');
    SL.Add('  Q := DB.NewQuery(''DELETE FROM ' + UpperCase(T.TableName) + ' WHERE ' + T.PKDBName + ' = :id'');');
    SL.Add('  try');
    SL.Add('    Q.ParamByName(''id'').AsLargeInt := ID;');
    SL.Add('    Q.ExecSQL;');
    SL.Add('    Result := Q.RowsAffected > 0;');
    SL.Add('    DB.Commit;');
    SL.Add('  finally');
    SL.Add('    Q.Free;');
    SL.Add('  end;');
    SL.Add('end;');
    SL.Add('');

    { GET ALL }
    SL.Add('function T' + T.UnitName + 'Service.GetAll: T' + T.UnitName + 'RecordList;');
    SL.Add('var DB: IDBContext; Q: TSQLQuery; R: T' + T.UnitName + 'Record;');
    SL.Add('begin');
    SL.Add('  SetLength(Result, 0);');
    SL.Add('  DB := TDB.GetContext(''' + APoolProfileName + ''');');
    SL.Add('  Q := DB.NewQuery(''SELECT * FROM ' + UpperCase(T.TableName) + ' ORDER BY 1'');');
    SL.Add('  try');
    SL.Add('    Q.Open;');
    SL.Add('');
    SL.Add('    while not Q.EOF do');
    SL.Add('    begin');
    SL.Add('      R := T' + T.UnitName + 'DBMapper.FromDataset(Q);');
    SL.Add('      SetLength(Result, Length(Result) + 1);');
    SL.Add('      Result[High(Result)] := R;');
    SL.Add('      Q.Next;');
    SL.Add('    end;');
    SL.Add('');
    SL.Add('    DB.Commit;');
    SL.Add('  finally');
    SL.Add('    Q.Free;');
    SL.Add('  end;');
    SL.Add('end;');
    SL.Add('');

    SL.Add('end.');

    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

end.
