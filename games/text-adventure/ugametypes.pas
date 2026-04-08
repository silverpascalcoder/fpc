unit uGameTypes;

{$IFDEF FPC}
{$mode ObjFPC}{$H+}
{$modeswitch advancedrecords}
{$ENDIF}

interface

type
  TDirection = (dUnknown, dNorth, dSouth, dEast, dWest, dUp, dDown);

  TEnemyState = (esAware, esUnaware, esSleeping, esHidden);

  TStatusEffect = (seNone, sePoisoned, seBleeding, seStunned);

const
  LOC_INVENTORY = 0;

  ShortDirections: array[dNorth..dDown] of string = ('n', 's', 'e', 'w', 'u', 'd');
  LongDirections: array[dNorth..dDown] of string = ('north', 'south', 'east', 'west', 'up', 'down');

type
  { Shared Attribute structure for all Entities }
  TAttributes = record
    Strength: Integer;
    Agility: Integer;
    Intelligence: Integer;
    Charisma: Integer;
  end;

  { Silver (dessert) fork vs carving fork vs fire poker }
  TItemDefinition = class
  public
    Id: Integer;
    Name: string;
    Description: string;
    Value: Currency;
    BaseDamage: Integer;
    {Durability}
  end;

  { Instances of items contained in the game }
  TItemInstance = class
  public
    InstanceId: Integer;
    Definition: TItemDefinition;
    { Wear and ...
      Value? (More use reduces value)
    }
  end;


  { Where is each instance of the above located? }
  TItemLocation = class
  public
    Instance: TItemInstance;
    LocationId: Integer;
  end;

  TCommandType = (ctMove, ctLook, ctTake, ctUse, ctInventory,
  ctDrop, ctQuit, ctError, ctSneak, ctAttack, ctStats, ctHelp);

  TAction = record
    Command: TCommandType;
    Target: string;
    case TCommandType of
      ctMove, ctSneak: (Dir: TDirection);
      ctError: (ErrorMessage: string[63]);
  end;

  TMapNode = class
  public
    Id: Integer;
    Title: string;
    Description: string;
    Exits: array[TDirection] of Integer;
  end;

  { Base Entity logic for shared functionality }
  TPlayer = class
  public
    PlayerName: string;
    CurrentLocation: Integer;
    Health, MaxHealth: Integer;
    Stats: TAttributes;
    Status: TStatusEffect;
    StatusDuration: Integer;
    EquippedWeapon: TItemInstance;
    constructor Create;
    function GetAttackPower: Integer;
  end;

  TEnemy = class
  public
    Name: string;
    Health, MaxHealth: Integer;
    Stats: TAttributes; { Symmetry with Player }
    LocationId: Integer;
    IsDead: Boolean;
    State: TEnemyState;
    Status: TStatusEffect;
    StatusDuration: Integer;
    EquippedWeapon: TItemInstance; { Symmetry with Player }

    constructor Create(AName: string; AHP, AStr, AAgil, ALoc: Integer; AState: TEnemyState = esAware);
    function GetAttackPower: Integer;
  end;

implementation

uses SysUtils;

{ TPlayer }

constructor TPlayer.Create;
begin
  PlayerName := 'Silver';
  Health := 100; MaxHealth := 100;
  Stats.Strength := 10; Stats.Agility := 10;
  Stats.Intelligence := 10; Stats.Charisma := 10;
  Status := seNone;
end;

function TPlayer.GetAttackPower: Integer;
begin
  Result := Stats.Strength div 2; { Base damage from strength }
  if Assigned(EquippedWeapon) then
    Result := Result + EquippedWeapon.Definition.BaseDamage;
  Result := Result + Random(4);
end;

{ TEnemy }

constructor TEnemy.Create(AName: string; AHP, AStr, AAgil, ALoc: Integer; AState: TEnemyState = esAware);
begin
  Name := AName;
  Health := AHP; MaxHealth := AHP;
  Stats.Strength := AStr;
  Stats.Agility := AAgil;
  LocationId := ALoc;
  State := AState;
  IsDead := False;
  Status := seNone;
end;

function TEnemy.GetAttackPower: Integer;
begin
  Result := Stats.Strength div 2;
  if Assigned(EquippedWeapon) then
    Result := Result + EquippedWeapon.Definition.BaseDamage;
  Result := Result + Random(4);
end;

end.
