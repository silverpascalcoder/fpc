unit UHighScore;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser;

type
  TScoreEntry = record
    PlayerName: string;
    Score: Integer;
    Date: TDateTime;
  end;

  TScoreEntryList =  array of TScoreEntry;

  THighScoreList = class
  private
    FList: TScoreEntryList; // array of TScoreEntry;
    FMaxEntries: Integer;
    FFileName: string;
  public
    constructor Create(AMaxEntries: Integer = 10);
    function IsQualified(AScore: Integer): Boolean;
    procedure AddScore(APlayer: string; AScore: Integer; ADate: TDateTime = 0);
    procedure Load;
    procedure Save;
    property Entries: TScoreEntryList read FList;
  end;

implementation

constructor THighScoreList.Create(AMaxEntries: Integer);
begin
  FMaxEntries := AMaxEntries;
  // Flatpak-friendly: ~/.var/app/[AppID]/config/snake/scores.json
  FFileName := IncludeTrailingPathDelimiter(GetAppConfigDir(False)) + 'scores.json';
end;

function THighScoreList.IsQualified(AScore: Integer): Boolean;
begin
  if Length(FList) < FMaxEntries then Exit(True);
  Result := AScore > FList[High(FList)].Score;
end;

procedure THighScoreList.AddScore(APlayer: string; AScore: Integer; ADate: TDateTime = 0);
var
  i, InsertPos: Integer;
begin
  InsertPos := -1;

  // Find where this failure... I mean, achievement... fits.
  for i := 0 to High(FList) do
    if AScore > FList[i].Score then
    begin
      InsertPos := i;
      Break;
    end;

  // If list isn't full and it's lower than everyone else, it's still last place.
  if (InsertPos = -1) and (Length(FList) < FMaxEntries) then
    InsertPos := Length(FList);

  if InsertPos <> -1 then
  begin
    if Length(FList) < FMaxEntries then
      SetLength(FList, Length(FList) + 1);

    // Shift the better players up (or rather, the worse ones down)
    for i := High(FList) downto InsertPos + 1 do
      FList[i] := FList[i - 1];

    FList[InsertPos].PlayerName := APlayer;
    FList[InsertPos].Score := AScore;

    if ADate = 0 then
      FList[InsertPos].Date := Now
    else
      FList[InsertPos].Date := ADate;
  end;
end;

procedure THighScoreList.Load;
var
  JSONData: TJSONData;
  DataArray: TJSONArray;
  i: Integer;
  LList: TStringList;
begin
  if not FileExists(FFileName) then Exit;

  // Clear current list to avoid duplicates on re-load
  SetLength(FList, 0);

  LList := TStringList.Create;
  try
    LList.LoadFromFile(FFileName);
    JSONData := GetJSON(LList.Text);
    try
      DataArray := JSONData.FindPath('highscores') as TJSONArray;
      if Assigned(DataArray) then
      begin
        // We use AddScore during Load to ensure the list is
        // perfectly sorted and capped, regardless of the file's state.
        for i := 0 to DataArray.Count - 1 do
        begin
          AddScore(
            DataArray.Objects[i].Get('name', 'Anonymous'),
            DataArray.Objects[i].Get('score', 0),
            StrToDateTimeDef(DataArray.Objects[i].Get('date', ''), Now)
          );
        end;
      end;
    finally
      JSONData.Free;
    end;
  finally
    LList.Free;
  end;
end;

procedure THighScoreList.Save;
var
  Root, Entry: TJSONObject;
  DataArray: TJSONArray;
  i: Integer;
  LList: TStringList;
begin
  // Ensure the directory exists (crucial for first-run in Flatpak)
  ForceDirectories(ExtractFilePath(FFileName));

  Root := TJSONObject.Create;
  DataArray := TJSONArray.Create;
  try
    for i := 0 to High(FList) do
    begin
      Entry := TJSONObject.Create;
      Entry.Add('name', FList[i].PlayerName);
      Entry.Add('score', FList[i].Score);
      Entry.Add('date', DateTimeToStr(FList[i].Date));
      DataArray.Add(Entry);
    end;
    Root.Add('highscores', DataArray);

    LList := TStringList.Create;
    try
      LList.Text := Root.FormatJSON(); // FormatJSON makes it human-readable
      LList.SaveToFile(FFileName);
    finally
      LList.Free;
    end;
  finally
    Root.Free;
  end;
end;

end.
