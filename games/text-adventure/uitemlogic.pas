unit uItemLogic;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, uGameTypes, uGameWorld;

type
  { Logic for item-based interactions }
  TItemInteraction = class
  public
    class procedure UseMedicalKit(AWorld: TGameWorld; AInstance: TItemInstance);
    class procedure EquipPlayer(AWorld: TGameWorld; const AItemName: string);
  end;

implementation

class procedure TItemInteraction.UseMedicalKit(AWorld: TGameWorld;
  AInstance: TItemInstance);
const
  HEAL_AMOUNT = 25;
begin
  if AWorld.Player.Health >= AWorld.Player.MaxHealth then
  begin
    WriteLn('You are already at full health.');
    Exit;
  end;

  AWorld.Player.Health := AWorld.Player.Health + HEAL_AMOUNT;

  if AWorld.Player.Health > AWorld.Player.MaxHealth then
    AWorld.Player.Health := AWorld.Player.MaxHealth;

  WriteLn('You apply the medical kit. You feel much better.');
  WriteLn('Health: ' + IntToStr(AWorld.Player.Health) + '/' +
    IntToStr(AWorld.Player.MaxHealth));

  { Consumable logic: Remove this specific instance from the world after use }
  AWorld.RemoveItemFromWorld(AInstance.InstanceId);
end;

class procedure TItemInteraction.EquipPlayer(AWorld: TGameWorld;
  const AItemName: string);
var
  Loc: TItemLocation;
begin
  for Loc in AWorld.Ledger do
  begin
    { Check if the item is in the player's inventory and matches the name }
    if (Loc.LocationId = LOC_INVENTORY) and
      (AnsiSameText(Loc.Instance.Definition.Name, AItemName)) then
    begin
      { Only equip if the item definition defines it as a weapon (Damage > 0) }
      if Loc.Instance.Definition.BaseDamage > 0 then
      begin
        AWorld.Player.EquippedWeapon := Loc.Instance;
        WriteLn('You equip the ' + AItemName + '.');
      end
      else
        WriteLn('The ' + AItemName + ' is not something you can wield in combat.');
      Exit;
    end;
  end;
  WriteLn('You aren''t carrying a "' + AItemName + '".');
end;

end.
