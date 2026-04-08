unit uParser;

{$IFDEF FPC}
{$mode ObjFPC}{$H+}
{$ENDIF}

interface

uses
  Classes, SysUtils, uGameTypes;

type
  { A record to map a single word to a specific game action }
  TCommandEntry = record
    Verb: string;
    Command: TCommandType; // e.g., ctMove, ctAttack
    HelpText: string;
  end;

const
  { The Command Table: A centralized list of all valid verbs }
  CommandTable: array[0..20] of TCommandEntry = (
    { MOVEMENT }
    (Verb: 'go';        Command: ctMove;      HelpText: 'Move in a direction (e.g., go north)'),
    (Verb: 'walk';      Command: ctMove;      HelpText: 'Move in a direction'),
    (Verb: 'move';      Command: ctMove;      HelpText: 'Move in a direction'),
    (Verb: 'run';       Command: ctMove;      HelpText: 'Move quickly in a direction'),
    (Verb: 'sneak';     Command: ctSneak;     HelpText: 'Move stealthily'),

    { COMBAT }
    (Verb: 'attack';    Command: ctAttack;    HelpText: 'Attack a target'),
    (Verb: 'kill';      Command: ctAttack;    HelpText: 'Attack a target'),
    (Verb: 'hit';       Command: ctAttack;    HelpText: 'Strike a target'),

    { INTERACTION }
    (Verb: 'take';      Command: ctTake;      HelpText: 'Pick up an item'),
    (Verb: 'get';       Command: ctTake;      HelpText: 'Pick up an item'),
    (Verb: 'drop';      Command: ctDrop;      HelpText: 'Discard an item from inventory'),
    (Verb: 'use';       Command: ctUse;       HelpText: 'Use or equip an item'),
    (Verb: 'equip';     Command: ctUse;       HelpText: 'Wear or wield an item'),

    { INFORMATION }
    (Verb: 'look';      Command: ctLook;      HelpText: 'Examine your surroundings or an object'),
    (Verb: 'examine';   Command: ctLook;      HelpText: 'Get a detailed description of an object'),
    (Verb: 'l';         Command: ctLook;      HelpText: 'Short for look'),
    (Verb: 'inventory'; Command: ctInventory; HelpText: 'List the items you are carrying'),
    (Verb: 'i';         Command: ctInventory; HelpText: 'Short for inventory'),
    (Verb: 'stats';     Command: ctStats;     HelpText: 'View character status'),

    { SYSTEM }
    (Verb: 'quit';      Command: ctQuit;      HelpText: 'Exit the game'),
    (Verb: 'help';      Command: ctHelp;      HelpText: 'Show this list of commands')
  );

function ParseInput(const ARawInput: string): TAction;

implementation

uses StrUtils;

{ Helper to identify directions from a single string }
function GetDirection(const S: string): TDirection;
var
  d: TDirection;
begin
  for d := dNorth to High(TDirection) do
    if AnsiSameText(ShortDirections[d], S) or AnsiSameText(LongDirections[d], S) then
      Exit(d);
  Result := dUnknown;
end;

{ Checks if a word is in our ignore list using IndexText for speed/clarity }
function CanIgnoreWord(const AWord: string): Boolean;
const
  { Define noise words as a constant array for easy maintenance }
  IgnoreWordList: array[0..7] of string =
    ('the', 'at', 'to', 'a', 'an', 'with', 'in', 'of');
begin
  Result := IndexText(AWord, IgnoreWordList) <> -1;
end;

{ Strips out "noise" words to allow for natural phrasing }
function FilterNoiseWords(const S: string): string;
var
  Words: TStringArray;
  Word, ResultStr: string;
begin
  ResultStr := '';
  Words := S.Split([' ']);
  for Word in Words do
  begin
    if CanIgnoreWord(Word) then Continue;

    if ResultStr <> '' then ResultStr := ResultStr + ' ';
    ResultStr := ResultStr + Word;
  end;
  Result := ResultStr;
end;

function ParseInput(const ARawInput: string): TAction;
var
  CleanInput, Verb, Noun: string;
  SpacePos: integer;
  i: Integer;
  Found: Boolean;
begin
  { 1. Initial cleanup and noise reduction }
  CleanInput := FilterNoiseWords(Trim(LowerCase(ARawInput)));

  Result.Command := ctError;
  Result.Target := '';
  Result.ErrorMessage := '';

  if CleanInput = '' then
  begin
    Result.ErrorMessage := 'You stand in silence.';
    Exit;
  end;

  { 2. Split into Verb and Noun }
  SpacePos := Pos(' ', CleanInput);
  if SpacePos > 0 then
  begin
    Verb := Copy(CleanInput, 1, SpacePos - 1);
    Noun := Copy(CleanInput, SpacePos + 1, Length(CleanInput));
  end
  else
  begin
    Verb := CleanInput;
    Noun := '';
  end;

  { ... (Split logic remains the same) ... }

  Found := False;
  for i := Low(CommandTable) to High(CommandTable) do
  begin
    if CommandTable[i].Verb = Verb then
    begin
      Result.Command := CommandTable[i].Command;
      Found := True;
      Break;
    end;
  end;

  { Handle Logic based on the identified Command }
  if Found then
  begin
    case Result.Command of
      ctMove, ctSneak: Result.Dir := GetDirection(Noun);
      ctAttack, ctTake, ctDrop, ctUse, ctLook: Result.Target := Noun;
    end;
  end
  else
  begin
    { Fallback for direct directions like just typing 'north' }
    Result.Dir := GetDirection(Verb);
    if Result.Dir <> dUnknown then
      Result.Command := ctMove
    else
      Result.ErrorMessage := 'I don''t know how to "' + Verb + '".';
  end;
end;

end.
