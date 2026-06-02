unit uGenerator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, uUtils, uFileWriter, uHTMXGenerator,
  uServiceGenerator, uDBPoolGenerator, uTestGenerator, uMapperGenerator;

procedure WriteAll(const T: TTableDef; Mode: TNamingMode; UsePool: Boolean;
  const DBUser, DBPass, DBPath: string; const PrettyName: string);

implementation

function GenModel(const T: TTableDef; Mode: TNamingMode): string;
var
  SL: TStringList;
  F: TFieldDef;
  UnitName: string;
  I: Integer;
begin
  SL := TStringList.Create;
  try
    UnitName := ModelUnitName(T, Mode);

    SL.Add('unit ' + UnitName + ';');
    SL.Add('');
    SL.Add('{$mode objfpc}{$H+}{$MODESWITCH ADVANCEDRECORDS}');
    SL.Add('');
    SL.Add('interface');
    SL.Add('');
    SL.Add('uses SysUtils;');
    SL.Add('');
    SL.Add('type');
    SL.Add('  T' + T.UnitName + 'Record = record');
    for F in T.Fields do
      SL.Add('    ' + F.Name + ': ' + F.PascalType + ';');
    SL.Add('');
    SL.Add('    function Debug: string;');
    SL.Add('  end;');
    SL.Add('');
    SL.Add('  T' + T.UnitName + 'RecordList = array of T' + T.UnitName + 'Record;');
    SL.Add('');
    SL.Add('implementation');
    SL.Add('');
    SL.Add('function T' + T.UnitName + 'Record.Debug: string;');
    SL.Add('begin');
    SL.Add('  Result := ''{'' + ');
    for I := 0 to High(T.Fields) do
    begin
      F := T.Fields[I];
      if F.PascalType = 'string' then
        SL.Add('    ''"' + F.JSONName + '": "'' + ' + F.Name + ' + ''",'' +')
      else
        SL.Add('    ''"' + F.JSONName + '": '' + ' + F.Name + '.ToString' + ' + '','' +');
    end;
    SL.Add('    ''}'';');
    SL.Add('end;');
    SL.Add('');
    SL.Add('end.');
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;


procedure WriteAll(const T: TTableDef; Mode: TNamingMode; UsePool: Boolean;
  const DBUser, DBPass, DBPath: string; const PrettyName: string);
var
  BaseName, TableLower: string;
  S: string;
begin
  BaseName := T.UnitName;
  TableLower := LowerCase(T.TableName);

  // model
  S := GenModel(T, Mode);
  if Mode = nmDotted then
    WriteStrToFile('Model/' + BaseName + '.pas', S)
  else
    WriteStrToFile(BaseName + 'Model.pas', S);

  // mapper
  S := GenJSONMapper(T, Mode);
  if Mode = nmDotted then
    WriteStrToFile('Mapper/' + BaseName + '.JSON.pas', S)
  else
    WriteStrToFile(BaseName + 'JSONMapper.pas', S);

  S := GenDBMapper(T, Mode);
  if Mode = nmDotted then
    WriteStrToFile('Mapper/' + BaseName + '.DB.pas', S)
  else
    WriteStrToFile(BaseName + 'DBMapper.pas', S);

  // service
  S := GenService(T, Mode, DBPath, DBUser, DBPass);
  if Mode = nmDotted then
    WriteStrToFile('Service/' + BaseName + '.pas', S)
  else
    WriteStrToFile(BaseName + 'Service.pas', S);

  // JSON test
  S := GenJSONTest(T, Mode);
  WriteStrToFile('tests/test_' + TableLower + '_json.lpr', S);

  // DB test
  S := GenDBTest(T, Mode, 'main');
  WriteStrToFile('tests/test_' + TableLower + '_db.lpr', S);

  // HTMX partials
  WriteStrToFile('partials/' + TableLower + '_header.mustache', GenHTMXHeader(T));
  WriteStrToFile('partials/' + TableLower + '_row.mustache', GenHTMXRow(T));
  WriteStrToFile('partials/' + TableLower + '_table.mustache', GenHTMXTable(T, PrettyName));
  WriteStrToFile('partials/' + TableLower + '_form_fields.mustache', GenHTMXFormFields(T, PrettyName));
  WriteStrToFile('partials/' + TableLower + '_form.mustache', GenHTMXForm(T, PrettyName));
  WriteStrToFile('partials/' + TableLower + '_form_wrapper.mustache', GenHTMXFormWrapper(T, PrettyName));

  if UsePool then
    WriteStrToFile('DBPool.pas', GenDBPoolUnit(DBPath, DBUser, DBPass));
end;

end.

