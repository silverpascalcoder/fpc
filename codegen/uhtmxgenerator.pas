unit uHTMXGenerator;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, StrUtils,
  uUtils;

function GenHTMXHeader(const T: TTableDef): string;
function GenHTMXRow(const T: TTableDef): string;
function GenHTMXTable(const T: TTableDef; const DisplayName: string): string;

function GenHTMXFormFields(const T: TTableDef; const DisplayName: string): string;
function GenHTMXForm(const T: TTableDef; const DisplayName: string): string;
function GenHTMXFormWrapper(const T: TTableDef; const DisplayName: string): string;

implementation

function GenHTMXHeader(const T: TTableDef): string;
var
  SL: TStringList;
  F: TFieldDef;
begin
  SL := TStringList.Create;
  try
    SL.Add('<tr>');
    for F in T.Fields do
      SL.Add('  <th>' + F.Name + '</th>');
    SL.Add('  <th>Actions</th>');
    SL.Add('</tr>');
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

function GenHTMXRow(const T: TTableDef): string;
var
  SL: TStringList;
  F: TFieldDef;
begin
  SL := TStringList.Create;
  try
    SL.Add('<tr>');
    for F in T.Fields do
      SL.Add('  <td>{{' + F.JSONName + '}}</td>');
    SL.Add('  <td>');
    SL.Add('    <button hx-get="/' + LowerCase(T.TableName) + '/edit/{{' + T.PKDBName + '}}">Edit</button>');
    SL.Add('    <button hx-delete="/' + LowerCase(T.TableName) + '/{{' + T.PKDBName + '}}">Delete</button>');
    SL.Add('  </td>');
    SL.Add('</tr>');
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

function GenHTMXTable(const T: TTableDef; const DisplayName: string): string;
var
  SL: TStringList;
  TableLower: string;
  ColCount: Integer;
begin
  SL := TStringList.Create;
  try
    TableLower := LowerCase(T.TableName);
    ColCount := Length(T.Fields) + 1;

    SL.Add('<table class="table table-striped">');
    SL.Add('  <thead>');
    SL.Add('    {{> ' + TableLower + '_header }}');
    SL.Add('  </thead>');
    SL.Add('');
    SL.Add('  <tbody>');
    SL.Add('    {{#items}}');
    SL.Add('      {{> ' + TableLower + '_row }}');
    SL.Add('    {{/items}}');
    SL.Add('');
    SL.Add('    {{^items}}');
    SL.Add('      <tr>');
    SL.Add('        <td colspan="' + IntToStr(ColCount) + '" class="text-center text-muted">');
    SL.Add('          No ' + DisplayName + ' found.');
    SL.Add('        </td>');
    SL.Add('      </tr>');
    SL.Add('    {{/items}}');
    SL.Add('  </tbody>');
    SL.Add('</table>');

    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

function GenHTMXFormFields(const T: TTableDef; const DisplayName: string): string;
var
  SL: TStringList;
  F: TFieldDef;
  InputType, ExtraAttr: string;
begin
  SL := TStringList.Create;
  try
    for F in T.Fields do
    begin
      if SameText(F.DBName, T.PKDBName) then
        Continue;

      InputType := 'text';
      ExtraAttr := '';

      if F.PascalType = 'Int64' then
        InputType := 'number'
      else if F.PascalType = 'Double' then
      begin
        InputType := 'number';
        ExtraAttr := ' step="0.01"';
      end
      else if F.PascalType = 'TDate' then
        InputType := 'date'
      else if F.PascalType = 'TTime' then
        InputType := 'time'
      else if F.PascalType = 'TDateTime' then
        InputType := 'datetime-local';

      SL.Add('<div class="form-group">');
      SL.Add('  <label for="' + F.JSONName + '">' + F.Name + '</label>');

      if F.PascalType = 'Boolean' then
      begin
        SL.Add('  <select id="' + F.JSONName + '" name="' + F.JSONName + '" class="form-control">');
        SL.Add('    <option value="true" {{#' + F.JSONName + '}}selected{{/' + F.JSONName + '}}>Yes</option>');
        SL.Add('    <option value="false" {{^' + F.JSONName + '}}selected{{/' + F.JSONName + '}}>No</option>');
        SL.Add('  </select>');
      end
      else
      begin
        SL.Add('  <input');
        SL.Add('    type="' + InputType + '"');
        SL.Add('    id="' + F.JSONName + '"');
        SL.Add('    name="' + F.JSONName + '"');
        SL.Add('    value="{{' + F.JSONName + '}}"');
        SL.Add('    class="form-control"' + ExtraAttr);
        SL.Add('  >');
      end;

      SL.Add('</div>');
      SL.Add('');
    end;

    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

function GenHTMXForm(const T: TTableDef; const DisplayName: string): string;
var
  SL: TStringList;
  TableLower: string;
begin
  SL := TStringList.Create;
  try
    TableLower := LowerCase(T.TableName);

    SL.Add('<form');
    SL.Add('  hx-post="/' + TableLower + '"');
    SL.Add('  hx-put="/' + TableLower + '/{{' + T.PKDBName + '}}"');
    SL.Add('  hx-target="#' + TableLower + '-container"');
    SL.Add('  hx-swap="outerHTML"');
    SL.Add('>');
    SL.Add('');
    SL.Add('  {{#isEdit}}');
    SL.Add('    <input type="hidden" name="' + T.PKDBName + '" value="{{' + T.PKDBName + '}}">');
    SL.Add('  {{/isEdit}}');
    SL.Add('');
    SL.Add('  {{> ' + TableLower + '_form_fields }}');
    SL.Add('');
    SL.Add('  <div class="form-actions">');
    SL.Add('    <button type="submit" class="btn btn-primary">');
    SL.Add('      {{#isEdit}}Update{{/isEdit}}{{^isEdit}}Create{{/isEdit}} ' + DisplayName);
    SL.Add('    </button>');
    SL.Add('  </div>');
    SL.Add('');
    SL.Add('</form>');

    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

function GenHTMXFormWrapper(const T: TTableDef; const DisplayName: string): string;
var
  SL: TStringList;
  TableLower: string;
begin
  SL := TStringList.Create;
  try
    TableLower := LowerCase(T.TableName);
    SL.Add('<div id="' + TableLower + '-form-container">');
    SL.Add('  {{> ' + TableLower + '_form }}');
    SL.Add('</div>');
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

end.

