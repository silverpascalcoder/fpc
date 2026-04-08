unit uEngine;

{$IFDEF FPC}
{$mode ObjFPC}{$H+}
{$ENDIF}

interface

uses
  Classes, SysUtils, uGameTypes, uGameWorld, uParser, uCombat, uItemLogic;

{ The Master Loop that drives the experience }
procedure RunGame(var W: TGameWorld);
procedure HandleRoomEntry(W: TGameWorld);

implementation

{ Checks if an alert enemy is currently preventing non-combat movement }
function IsCombatLockActive(W: TGameWorld; Action: TAction): Boolean;
var
  E: TEnemy;
begin
  Result := False;
  E := W.FindEnemyInRoom;

  { Lock only triggers if enemy exists, is alive, and is AWARE of the player }
  if (E = nil) or (E.IsDead) or (E.State in [esUnaware, esSleeping, esHidden]) then
    Exit(False);

  { If the enemy is Aware, they block movement and taking items }
  if not (Action.Command in [ctAttack, ctStats, ctQuit, ctUse, ctInventory]) then
  begin
    WriteLn('The ' + E.Name + ' blocks your path, baring its teeth!');
    Result := True;
  end;
end;

procedure HandleCommand_ShowInventory(W: TGameWorld);
var
  Loc: TItemLocation;
  Found: Boolean;
begin
  Found := False;
  WriteLn('Inventory:');
  for Loc in W.Ledger do
  begin
    if Loc.LocationId = LOC_INVENTORY then
    begin
      WriteLn('  - ' + Loc.Instance.Definition.Name);
      Found := True;
    end;
  end;
  if not Found then WriteLn('  (Empty)');
end;

procedure HandleCommand_Look(const W: TGameWorld);
var
  Item: TItemLocation;
  E: TEnemy;
  d: TDirection;
  CurrentNode: TMapNode;
  ExitList: string;
begin
  ExitList := '';
  CurrentNode := W.GetCurrentNode;

  WriteLn('');
  WriteLn('--- ' + Uppercase(CurrentNode.Title) + ' ---');
  WriteLn(CurrentNode.Description);

  { Check for Enemies and describe their state/equipment }
  E := W.FindEnemyInRoom;
  if E <> nil then
  begin
    case E.State of
      esSleeping: WriteLn('A ' + E.Name + ' is curled up here, sleeping soundly.');
      esUnaware:  WriteLn('A ' + E.Name + ' is here with its back turned, busy with something.');
      esAware:    WriteLn('A hostile ' + E.Name + ' is here, tracking your every move!');
    end;

    if Assigned(E.EquippedWeapon) then
      WriteLn('It is wielding a ' + E.EquippedWeapon.Definition.Name + '.');
  end;

  { List Items in the room }
  WriteLn('Visible Items:');
  for Item in W.Ledger do
    if Item.LocationId = W.CurrentLocation then
      WriteLn('  - ' + Item.Instance.Definition.Name);

  { List Exits }
  for d := dNorth to dDown do
    if CurrentNode.Exits[d] <> 0 then
      ExitList := ExitList + LongDirections[d] + ' ';

  if ExitList <> '' then
    WriteLn('Exits: ' + ExitList)
  else
    WriteLn('There are no obvious exits.');
end;

procedure HandleCommand_Sneak(W: TGameWorld; ADir: TDirection);
var
  E: TEnemy;
  Roll: Integer;
begin
  E := W.FindEnemyInRoom;

  { If no enemy or they already see you, sneak acts as a standard move attempt }
  if (E = nil) or (E.State = esAware) then
  begin
    if E <> nil then WriteLn('They''ve already seen you! You can''t sneak past now.');
    if (E = nil) and (W.GetCurrentNode.Exits[ADir] <> 0) then
    begin
      W.CurrentLocation := W.GetCurrentNode.Exits[ADir];
      HandleRoomEntry(W);
    end;
    Exit;
  end;

  { Agility Check vs Enemy Agility }
  Randomize;
  Roll := Random(20) + W.Player.Stats.Agility;

  if Roll > (10 + E.Stats.Agility) then
  begin
    WriteLn('You shadow-step across the room, unheard...');
    W.CurrentLocation := W.GetCurrentNode.Exits[ADir];
    HandleRoomEntry(W);
  end
  else
  begin
    WriteLn('Your boot scuffs the stone! The ' + E.Name + ' snaps alert!');
    E.State := esAware;
    { Enemy gets an immediate strike for catching the player }
    TCombatEngine.ExecuteEnemyTurn(W.Player, E, W);
  end;
end;

procedure HandleCommand_ShowStats(W: TGameWorld);
var
  E: TEnemy;
begin
  WriteLn('');
  WriteLn('--- CHARACTER RECORD ---');
  WriteLn('Name:   ' + W.Player.PlayerName);
  WriteLn(Format('Health: %d/%d', [W.Player.Health, W.Player.MaxHealth]));
  WriteLn(Format('STR:    %d | AGI: %d', [W.Player.Stats.Strength, W.Player.Stats.Agility]));
  WriteLn(Format('INT:    %d | CHA: %d', [W.Player.Stats.Intelligence, W.Player.Stats.Charisma]));

  if Assigned(W.Player.EquippedWeapon) then
    WriteLn('Weapon: ' + W.Player.EquippedWeapon.Definition.Name +
            ' (DMG: ' + IntToStr(W.Player.EquippedWeapon.Definition.BaseDamage) + ')')
  else
    WriteLn('Weapon: Bare Hands (DMG: 2)');

  { Tactical Scan: Reveal enemy stats in the current room }
  E := W.FindEnemyInRoom;
  if E <> nil then
  begin
    WriteLn('');
    WriteLn('--- TARGET ANALYSIS ---');
    WriteLn('Enemy:  ' + E.Name);
    WriteLn(Format('Health: %d', [E.Health]));
    WriteLn(Format('STR:    %d | AGI: %d', [E.Stats.Strength, E.Stats.Agility]));
    case E.State of
      esSleeping: WriteLn('Status: Sleeping');
      esUnaware:  WriteLn('Status: Unaware');
      esAware:    WriteLn('Status: Hostile');
    end;
  end;
  WriteLn('------------------------');
end;

procedure HandleRoomEntry(W: TGameWorld);
var
  E: TEnemy;
begin
  HandleCommand_Look(W);

  E := W.FindEnemyInRoom;
  if (E <> nil) and (E.State = esAware) then
  begin
    WriteLn('The ' + E.Name + ' lunges at you as you enter!');
    TCombatEngine.ExecuteEnemyTurn(W.Player, E, W);
  end;
end;

procedure RunGame(var W: TGameWorld);
var
  UserLine: string;
  Action: TAction;
  E: TEnemy;
begin
  WriteLn('--- THE SILVER ADVENTURE ---');
  HandleRoomEntry(W);

  while W.IsRunning do
  begin
    WriteLn;
    Write('> ');
    ReadLn(UserLine);

    Action := ParseInput(UserLine);

    { Enforce Combat Lock }
    if IsCombatLockActive(W, Action) then Continue;

    case Action.Command of
      ctMove:
        begin
          if W.GetCurrentNode.Exits[Action.Dir] <> 0 then
          begin
            W.CurrentLocation := W.GetCurrentNode.Exits[Action.Dir];
            HandleRoomEntry(W);
          end else WriteLn('You can''t go that way.');
        end;

      ctSneak: HandleCommand_Sneak(W, Action.Dir);

      ctAttack:
        begin
          E := W.FindEnemyByName(Action.Target);
          if E <> nil then
          begin
            case TCombatEngine.ExecuteRound(W.Player, E, W) of
              crPlayerVictory: WriteLn('You have won this battle!');
              crEnemyVictory : WriteLn('Death awaits you...');
              crEscaped      : WriteLn('You escape from this battle.');
            end;
          end else WriteLn('There is no "' + Action.Target + '" here to attack.');
        end;

      ctLook:      HandleCommand_Look(W);
      ctInventory: HandleCommand_ShowInventory(W);
      ctTake:      W.AddItemToInventory(Action.Target);
      ctDrop:      W.RemoveItemFromInventory(Action.Target);
      ctStats:     HandleCommand_ShowStats(W);

      { Using the new Multi-Use/Equip Service }
      ctUse:       TItemInteraction.EquipPlayer(W, Action.Target);

      ctQuit:  begin
                 WriteLn('The shadows close in as you leave. Goodbye.');
                 W.IsRunning := False;
               end;

      ctError: WriteLn(Action.ErrorMessage);
    end;

    { Death Check }
    if W.Player.Health <= 0 then
    begin
      WriteLn('*** YOU HAVE DIED ***');
      W.IsRunning := False;
    end;
  end;
end;

end.
