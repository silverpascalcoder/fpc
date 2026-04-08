unit uCombat;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, uGameTypes, uGameWorld, uOutput;

type
  { Represents the outcome of a single combat encounter }
  TCombatResult = (crPlayerVictory, crEnemyVictory, crEscaped, crOngoing);

  TCombatEngine = class
  private
    class function CalculateDamage(AStr, ABaseDmg: Integer; AIsSurprise: Boolean): Integer;
  public
    { Executes a single round of combat interaction }
    class function ExecuteRound(APlayer: TPlayer; AEnemy: TEnemy; AWorld: TGameWorld): TCombatResult;

    { Enemy acts independently (e.g., triggered by failed stealth or ongoing fight) }
    class procedure ExecuteEnemyTurn(APlayer: TPlayer; AEnemy: TEnemy; AWorld: TGameWorld);
  end;

implementation

class function TCombatEngine.CalculateDamage(AStr, ABaseDmg: Integer; AIsSurprise: Boolean): Integer;
var
  Multiplier: Single;
begin
  Multiplier := 1.0;
  { High-stakes advantage for stealth-based openings }
  if AIsSurprise then Multiplier := 3.0;

  Result := Round((ABaseDmg + (AStr div 3)) * Multiplier);
end;

class function TCombatEngine.ExecuteRound(APlayer: TPlayer; AEnemy: TEnemy; AWorld: TGameWorld): TCombatResult;
var
  DamageDealt: Integer;
  BaseWeaponDmg: Integer;
  IsSurpriseOpening: Boolean;
begin
  Result := crOngoing;

  { Check state BEFORE any transitions occur }
  IsSurpriseOpening := (AEnemy.State in [esSleeping, esUnaware]);

  { 1. Player Action Phase }
  if Assigned(APlayer.EquippedWeapon) then
    BaseWeaponDmg := APlayer.EquippedWeapon.Definition.BaseDamage
  else
    BaseWeaponDmg := 2; { Minimal unarmed damage }

  DamageDealt := CalculateDamage(APlayer.Stats.Strength, BaseWeaponDmg, IsSurpriseOpening);

  if IsSurpriseOpening then
    Output.Write('>>> TACTICAL ADVANTAGE: Target neutralized from stealth!', otCombat)
  else
    Output.Write('Engaging ' + AEnemy.Name + '...', otCombat);

  AEnemy.Health := AEnemy.Health - DamageDealt;
  Output.Write(Format('Target sustained %d units of damage.', [DamageDealt]), otCombat);

  { Transition target to active combat state }
  AEnemy.State := esAware;

  { Check for Target Neutralization }
  if AEnemy.Health <= 0 then
  begin
    AWorld.HandleEnemyDeath(AEnemy);
    Exit(crPlayerVictory);
  end;

  { 2. Counter-Measure Phase }
  { If the player had the surprise, the enemy is too disoriented to strike back this round }
  if IsSurpriseOpening then
  begin
    Output.Write('The ' + AEnemy.Name + ' is recovering from the sudden strike.', otCombat);
  end
  else
  begin
    { Standard combat flow: Enemy responds }
    ExecuteEnemyTurn(APlayer, AEnemy, AWorld);
  end;

  { Check for Player Vital Signs }
  if APlayer.Health <= 0 then
    Result := crEnemyVictory;
end;

class procedure TCombatEngine.ExecuteEnemyTurn(APlayer: TPlayer; AEnemy: TEnemy; AWorld: TGameWorld);
var
  IncomingDmg: Integer;
  EnemyBaseDmg: Integer;
begin
  if (AEnemy = nil) or (AEnemy.IsDead) or (AEnemy.Health <= 0) then Exit;

  if Assigned(AEnemy.EquippedWeapon) then
    EnemyBaseDmg := AEnemy.EquippedWeapon.Definition.BaseDamage
  else
    EnemyBaseDmg := 5; { Default threat level }

  { Mitigation logic: Higher Agility provides a passive 'Dodge/Deflect' value }
  IncomingDmg := (EnemyBaseDmg + (AEnemy.Stats.Strength div 4)) - (APlayer.Stats.Agility div 5);

  if IncomingDmg < 1 then IncomingDmg := 1;

  APlayer.Health := APlayer.Health - IncomingDmg;

  Output.Write('The ' + AEnemy.Name + ' initiates a counter-strike: ' + IntToStr(IncomingDmg) + ' damage.', otCombat);
  Output.Write(Format('Vital Signs: %d/%d', [APlayer.Health, APlayer.MaxHealth]), otStatus);
end;

end.
