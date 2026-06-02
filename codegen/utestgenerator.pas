unit uTestGenerator;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uUtils;

function GenJSONTest(const T: TTableDef; Mode: TNamingMode): string;
function GenDBTest(const T: TTableDef; Mode: TNamingMode): string;

implementation

function GenJSONTest(const T: TTableDef; Mode: TNamingMode): string;
var
  SL: TStringList;
  ModelUnit, JSONUnit: string;
  F: TFieldDef;
begin
  SL := TStringList.Create;
  try
    ModelUnit := ModelUnitName(T, Mode);
    JSONUnit := JSONMapperUnitName(T, Mode);

    SL.Add('program test_' + LowerCase(T.UnitName) + '_json;');
    SL.Add('');
    SL.Add('{$mode objfpc}{$H+}');
    SL.Add('');
    SL.Add('uses SysUtils, fpjson, ' + ModelUnit + ', ' + JSONUnit + ';');
    SL.Add('');
    SL.Add('var');
    SL.Add('  R1, R2: T' + T.UnitName + 'Record;');
    SL.Add('  J: TJSONObject;');
    SL.Add('');
    SL.Add('procedure Assert(Cond: Boolean; const Msg: string);');
    SL.Add('begin');
    SL.Add('  if Cond then Writeln(''[PASS] '', Msg)');
    SL.Add('  else Writeln(''[FAIL] '', Msg);');
    SL.Add('end;');
    SL.Add('');
    SL.Add('begin');
    SL.Add('  // Fill R1 with sample values');
    for F in T.Fields do
      SL.Add('  R1.' + F.Name + ' := ' + SampleValue(F, 'json') + ';');
    SL.Add('');
    SL.Add('  // Convert to JSON');
    SL.Add('  J := T' + T.UnitName + 'JSONMapper.ToJSON(R1);');
    SL.Add('  Writeln(''JSON Output: '');');
    SL.Add('  Writeln(J.AsJSON);');
    SL.Add('');
    SL.Add('  // Convert back from JSON');
    SL.Add('  R2 := T' + T.UnitName + 'JSONMapper.FromJSON(J);');
    SL.Add('');
    SL.Add('  // Compare fields');
    for F in T.Fields do
      SL.Add('  Assert(R1.' + F.Name + ' = R2.' + F.Name +
             ', ''Field ' + F.Name + ' round-trip matches'');');
    SL.Add('');
    SL.Add('  J.Free;');
    SL.Add('end.');
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;


function GenDBTest(const T: TTableDef; Mode: TNamingMode): string;
var
  SL: TStringList;
  ModelUnit, ServiceUnit: string;
  F: TFieldDef;
begin
  SL := TStringList.Create;
  try
    ModelUnit := ModelUnitName(T, Mode);
    ServiceUnit := ServiceUnitName(T, Mode);

    SL.Add('program test_' + LowerCase(T.UnitName) + '_db;');
    SL.Add('');
    SL.Add('{$mode objfpc}{$H+}');
    SL.Add('');
    SL.Add('uses SysUtils, uDBContext, ' + ModelUnit + ', ' + ServiceUnit + ';');
    SL.Add('');
    SL.Add('var');
    SL.Add('  S: T' + T.UnitName + 'Service;');
    SL.Add('  R, R2: T' + T.UnitName + 'Record;');
    SL.Add('  ID: Int64;');
    SL.Add('');
    SL.Add('procedure Assert(Cond: Boolean; const Msg: string);');
    SL.Add('begin');
    SL.Add('  if Cond then Writeln(''[PASS] '', Msg)');
    SL.Add('  else Writeln(''[FAIL] '', Msg);');
    SL.Add('end;');
    SL.Add('');
    SL.Add('begin');
    SL.Add('  Writeln(''--- Running DB test for ' + T.UnitName + ' ---'');');
    SL.Add('');
    SL.Add('  // Update parameters in the next line...');
    SL.Add('  TDB.Initialize(''main'', Driver, Host, DBName, User, Password, 32);');
    SL.Add('');
    SL.Add('  S := T' + T.UnitName + 'Service.Create;');
    SL.Add('');
    SL.Add('  // CREATE');
    SL.Add('  FillChar(R, SizeOf(R), 0);');

    for F in T.Fields do
      if not SameText(F.DBName, T.PKDBName) then
        SL.Add('  R.' + F.Name + ' := ' + SampleValue(F, 'db') + ';');

    SL.Add('  ID := S.CreateItem(R);');
    SL.Add('  Assert(ID > 0, ''CreateItem returned valid ID'');');
    SL.Add('');
    SL.Add('  // READ');
    SL.Add('  R2 := S.ReadItem(ID);');
    SL.Add('  Assert(R2.' + T.PKDBName + ' = ID, ''ReadItem returned correct record'');');
    SL.Add('');
    SL.Add('  // UPDATE');

    (*
    for F in T.Fields do
      if not SameText(F.DBName, T.PKDBName) then
        SL.Add('  R2.' + F.Name + ' := ' + SampleUpdatedValue(F) + ';');

    SL.Add('  Assert(S.UpdateItem(R2), ''UpdateItem returned TRUE'');');
    SL.Add('');
    SL.Add('  // READ AGAIN');
    SL.Add('  R2 := S.ReadItem(ID);');

    for F in T.Fields do
      if not SameText(F.DBName, T.PKDBName) then
        SL.Add('  Assert(R2.' + F.Name + ' = ' + SampleUpdatedValue(F) +
               ', ''Field ' + F.Name + ' updated correctly'');');
    *)

    SL.Add('');
    SL.Add('  // DELETE');
    SL.Add('  Assert(S.DeleteItem(ID), ''DeleteItem returned TRUE'');');
    SL.Add('');
    SL.Add('  // VERIFY DELETE');
    SL.Add('  R2 := S.ReadItem(ID);');
    SL.Add('  Assert(R2.' + T.PKDBName + ' = 0, ''Record no longer exists after delete'');');
    SL.Add('');
    SL.Add('  Writeln(''--- Test complete ---'');');
    SL.Add('end.');
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

end.

