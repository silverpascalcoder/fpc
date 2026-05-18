program htmxmustachedemo;

{$mode objfpc}{$H+}

uses
  cthreads, Classes, SysUtils, fphttpapp, httpdefs, httproute,
  fpjson, jsonparser, fpmustache;

{ -----------------------------------------------------------------------
  Helper: build mock guest data
  ----------------------------------------------------------------------- }
function MockGuestData: TJSONArray;
var
  Guest: TJSONObject;
begin
  Result := TJSONArray.Create;

  Guest := TJSONObject.Create;
  Guest.Add('name', 'Alice Cooper');
  Guest.Add('table', '1');
  Guest.Add('status', 'Confirmed');
  Result.Add(Guest);

  Guest := TJSONObject.Create;
  Guest.Add('name', 'Garry Moore');
  Guest.Add('table', '3');
  Guest.Add('status', 'Pending');
  Result.Add(Guest);

  Guest := TJSONObject.Create;
  Guest.Add('name', 'Lizzy Borden');
  Guest.Add('table', '1');
  Guest.Add('status', 'Confirmed');
  Result.Add(Guest);
  Guest := TJSONObject.Create;

  Guest.Add('name', 'Blondie');
  Guest.Add('table', '2');
  Guest.Add('status', 'Declined');
  Result.Add(Guest);
end;

{ -----------------------------------------------------------------------
  Route: GET /  — renders the full HTML page
  ----------------------------------------------------------------------- }
procedure HandleMainPage(ARequest: TRequest; AResponse: TResponse);
var
  Engine: TMustache;
  Context: TJSONObject;
  RowTemplate, Template: String;
begin
  RowTemplate :=
    '{{#guests}}' +
    '<tr><td>{{name}}</td><td>{{table}}</td><td>{{status}}</td></tr>' +
    '{{/guests}}' +
    '{{^guests}}' +
    '<tr><td colspan="3" style="color:gray;text-align:center;">No matching guests found.</td></tr>' +
    '{{/guests}}';

  Template :=
    '<!DOCTYPE html>' +
    '<html lang="en"><head>' +
    '  <meta charset="UTF-8">' +
    '  <title>Wedding Tracker (FP + HTMX)</title>' +
    '  <script src="https://unpkg.com/htmx.org@2.0.0"></script>' +
    '  <style>' +
    '    body{font-family:sans-serif;margin:40px;background:#f9f9f9;color:#333}' +
    '    .container{max-width:600px;background:#fff;padding:20px;border-radius:8px;box-shadow:0 2px 5px rgba(0,0,0,.1)}' +
    '    input{width:100%;padding:10px;margin-bottom:20px;box-sizing:border-box;border:1px solid #ccc;border-radius:4px}' +
    '    table{width:100%;border-collapse:collapse}' +
    '    th,td{text-align:left;padding:10px;border-bottom:1px solid #ddd}' +
    '    th{background:#f2f2f2}' +
    '  </style>' +
    '</head><body>' +
    '  <div class="container">' +
    '    <h2>Guest RSVP Search</h2>' +
    '    <input type="text" name="search" placeholder="Type a guest name to filter..."' +
    '           hx-post="/search-guests"' +
    '           hx-trigger="keyup changed delay:300ms, search"' +
    '           hx-target="#search-results">' +
    '    <table>' +
    '      <thead><tr><th>Name</th><th>Table</th><th>Status</th></tr></thead>' +
    '      <tbody id="search-results">{{> guest_rows}}</tbody>' +
    '    </table>' +
    '  </div>' +
    '</body></html>';

  Context := TJSONObject.Create;
  Context.Add('guests', MockGuestData);

  Engine := TMustache.Create(nil);
  try
    Engine.Template := Template;
    // Partials is a TStrings — assign via name=value
    Engine.Partials.Values['guest_rows'] := RowTemplate;
    AResponse.ContentType := 'text/html; charset=utf-8';
    AResponse.Content := Engine.Render(Context);
    AResponse.SendResponse;
  finally
    Engine.Free;
    Context.Free;
  end;
end;

{ -----------------------------------------------------------------------
  Route: POST /search-guests  — returns an HTML fragment for HTMX to swap
  ----------------------------------------------------------------------- }
procedure HandleSearchGuests(ARequest: TRequest; AResponse: TResponse);
var
  Engine: TMustache;
  FullList, FilteredList: TJSONArray;
  GuestObj: TJSONObject;
  Context: TJSONObject;
  SearchQuery: String;
  I: Integer;
  Template: String;
begin
  SearchQuery := LowerCase(ARequest.ContentFields.Values['search']);

  FullList     := MockGuestData;
  FilteredList := TJSONArray.Create;

  for I := 0 to FullList.Count - 1 do
  begin
    // Correct accessor: Items[I] cast to TJSONObject, not .Objects[I]
    GuestObj := FullList.Items[I] as TJSONObject;
    if (SearchQuery = '') or
      (Pos(SearchQuery, LowerCase(GuestObj.Strings['name'])) > 0) then
      FilteredList.Add(GuestObj.Clone as TJSONObject);
  end;
  FullList.Free;

  Context := TJSONObject.Create;
  Context.Add('guests', FilteredList);

  Template :=
    '{{#guests}}' +
    '<tr><td>{{name}}</td><td>{{table}}</td><td>{{status}}</td></tr>' +
    '{{/guests}}' +
    '{{^guests}}' +
    '<tr><td colspan="3" style="color:gray;text-align:center;">No matching guests found.</td></tr>' +
    '{{/guests}}';

  Engine := TMustache.Create(nil);
  try
    Engine.Template := Template;
    AResponse.ContentType := 'text/html; charset=utf-8';
    AResponse.Content := Engine.Render(Context);
    AResponse.SendResponse;
  finally
    Engine.Free;
    Context.Free;
  end;
end;

{ -----------------------------------------------------------------------
  Program entry point
  ----------------------------------------------------------------------- }
begin
  // Register routes — the correct fpweb/httproute pattern.
  // No Application.OnRequest: routing is handled by HTTPRouter.
  HTTPRouter.RegisterRoute('/',              rmGet,  @HandleMainPage);
  HTTPRouter.RegisterRoute('/search-guests', rmPost, @HandleSearchGuests);

  Application.Title      := 'HTMX + fpmustache Demo Server';
  Application.Port       := 8080;
  Application.Threaded   := True;
  Application.Initialize;

  Writeln('Server starting on http://localhost:8080');
  Application.Run;
end.
