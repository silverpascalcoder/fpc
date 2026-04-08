unit uGameWorld;

{$IFDEF FPC}
{$mode ObjFPC}{$H+}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  fgl,
{$ELSE}
  System.Generics.Collections,
{$ENDIF}
  uGameTypes,
  SysUtils;

type
{$IFDEF FPC}
  TItemDefList = specialize TFPGList<TItemDefinition>;
  TItemInstanceList = specialize TFPGList<TItemInstance>;
  TLocationLedger = specialize TFPGList<TItemLocation>;
  TMapNodeList = specialize TFPGList<TMapNode>;
  TEnemyList = specialize TFPGList<TEnemy>;
{$ELSE}
  TItemDefList = TObjectList<TItemDefinition>;
  TItemInstanceList = TObjectList<TItemInstance>;
  TLocationLedger = TObjectList<TItemLocation>;
  TMapNodeList = TObjectList<TMapNode>;
  TEnemyList = TObjectList<TEnemy>;
{$ENDIF}

  TGameWorld = class
  private
    FMap: TMapNodeList;
    FDefinitions: TItemDefList;
    FInstances: TItemInstanceList;
    FLedger: TLocationLedger;
    FEnemies: TEnemyList;
    FPlayer: TPlayer;
    FCurrentLocation: integer;
    FIsRunning: boolean;
    FNextInstanceID: integer;
    function GetDefinitionByID(AID: integer): TItemDefinition;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddNode(AID: integer; const ATitle, ADesc: string);
    procedure LinkNodes(AFromID, AToID: integer; ADir: TDirection;
      ABidirectional: boolean = True);
    function GetCurrentNode: TMapNode;

    procedure AddDefinition(AID: integer; const AName, ADesc: string;
      AVal: currency = 0; ADmg: integer = 0);
    procedure SpawnItem(ADefID: integer; ALocationID: integer);

    { Improved Enemy Spawning with Weapons }
    procedure SpawnEnemy(AName: string; HP, STR, Agil, Loc: integer;
      State: TEnemyState; AWeaponDefID: integer = 0);

    function FindEnemyInRoom: TEnemy;
    function FindEnemyByName(const AName: string): TEnemy;
    procedure HandleEnemyDeath(AEnemy: TEnemy);
    procedure AddItemToInventory(const AItemName: string);
    procedure RemoveItemFromInventory(const AItemName: string);
    procedure RemoveItemFromWorld(AInstanceID: integer);

    property Player: TPlayer read FPlayer;
    property CurrentLocation: integer read FCurrentLocation write FCurrentLocation;
    property IsRunning: boolean read FIsRunning write FIsRunning;
    property Ledger: TLocationLedger read FLedger;
  end;

implementation

constructor TGameWorld.Create;
begin
  FMap := TMapNodeList.Create;
  FDefinitions := TItemDefList.Create;
  FInstances := TItemInstanceList.Create;
  FLedger := TLocationLedger.Create;
  FEnemies := TEnemyList.Create;
  FPlayer := TPlayer.Create;
  FCurrentLocation := 1;
  FIsRunning := True;
  FNextInstanceID := 1000;
end;

destructor TGameWorld.Destroy;
begin
  FMap.Free;
  FDefinitions.Free;
  FInstances.Free;
  FLedger.Free;
  FEnemies.Free;
  FPlayer.Free;
  inherited;
end;

function TGameWorld.GetDefinitionByID(AID: integer): TItemDefinition;
var
  i: integer;
begin
  Result := nil;
  for i := 0 to FDefinitions.Count - 1 do if FDefinitions[i].Id = AID then
      Exit(FDefinitions[i]);
end;

procedure TGameWorld.AddNode(AID: integer; const ATitle, ADesc: string);
var
  Node: TMapNode;
  d: TDirection;
begin
  Node := TMapNode.Create;
  Node.Id := AID;
  Node.Title := ATitle;
  Node.Description := ADesc;
  for d := Low(TDirection) to High(TDirection) do Node.Exits[d] := 0;
  FMap.Add(Node);
end;

procedure TGameWorld.LinkNodes(AFromID, AToID: integer; ADir: TDirection;
  ABidirectional: boolean = True);
var
  i, IdxFrom, IdxTo: integer;
  Opposite: TDirection;
begin
  IdxFrom := -1;
  IdxTo := -1;
  for i := 0 to FMap.Count - 1 do
  begin
    if FMap[i].Id = AFromID then IdxFrom := i;
    if FMap[i].Id = AToID then IdxTo := i;
  end;
  if (IdxFrom = -1) or (IdxTo = -1) then Exit;
  FMap[IdxFrom].Exits[ADir] := AToID;
  if ABidirectional then
  begin
    case ADir of
      dNorth: Opposite := dSouth;
      dSouth: Opposite := dNorth;
      dEast: Opposite := dWest;
      dWest: Opposite := dEast;
      dUp: Opposite := dDown;
      dDown: Opposite := dUp;
      else
        Opposite := dUnknown;
    end;
    if Opposite <> dUnknown then FMap[IdxTo].Exits[Opposite] := AFromID;
  end;
end;

function TGameWorld.GetCurrentNode: TMapNode;
var
  i: integer;
begin
  for i := 0 to FMap.Count - 1 do if FMap[i].Id = FCurrentLocation then Exit(FMap[i]);
  Result := nil;
end;

procedure TGameWorld.AddDefinition(AID: integer; const AName, ADesc: string;
  AVal: currency = 0; ADmg: integer = 0);
var
  Def: TItemDefinition;
begin
  Def := TItemDefinition.Create;
  Def.Id := AID;
  Def.Name := AName;
  Def.Description := ADesc;
  Def.Value := AVal;
  Def.BaseDamage := ADmg;
  FDefinitions.Add(Def);
end;

procedure TGameWorld.SpawnItem(ADefID: integer; ALocationID: integer);
var
  Inst: TItemInstance;
  Loc: TItemLocation;
  Def: TItemDefinition;
begin
  Def := GetDefinitionByID(ADefID);
  if Def = nil then Exit;
  Inc(FNextInstanceID);

  Inst := TItemInstance.Create;
  Inst.InstanceId := FNextInstanceID;
  Inst.Definition := Def;
  FInstances.Add(Inst);

  Loc := TItemLocation.Create;
  Loc.Instance := Inst;
  Loc.LocationId := ALocationID;
  FLedger.Add(Loc);
end;

procedure TGameWorld.SpawnEnemy(AName: string; HP, STR, Agil, Loc: integer;
  State: TEnemyState; AWeaponDefID: integer = 0);
var
  E: TEnemy;
  WeaponDef: TItemDefinition;
  Inst: TItemInstance;
begin
  E := TEnemy.Create(AName, HP, STR, Agil, Loc, State);

  { If a weapon is provided, instantiate and equip it }
  if AWeaponDefID > 0 then
  begin
    WeaponDef := GetDefinitionByID(AWeaponDefID);
    if WeaponDef <> nil then
    begin
      Inc(FNextInstanceID);
      Inst := TItemInstance.Create;
      Inst.InstanceId := FNextInstanceID;
      Inst.Definition := WeaponDef;
      FInstances.Add(Inst);
      E.EquippedWeapon := Inst;
    end;
  end;

  FEnemies.Add(E);
end;

function TGameWorld.FindEnemyInRoom: TEnemy;
var
  E: TEnemy;
begin
  for E in FEnemies do if (E.LocationId = FCurrentLocation) and (not E.IsDead) then
      Exit(E);
  Result := nil;
end;

function TGameWorld.FindEnemyByName(const AName: string): TEnemy;
var
  E: TEnemy;
begin
  for E in FEnemies do
    if (E.LocationId = FCurrentLocation) and
      (not E.IsDead) and
      (Pos(LowerCase(AName), LowerCase(E.Name)) > 0) then
      Exit(E);
  Result := nil;
end;

procedure TGameWorld.HandleEnemyDeath(AEnemy: TEnemy);
begin
  AEnemy.IsDead := True;
end;

procedure TGameWorld.AddItemToInventory(const AItemName: string);
var
  Loc: TItemLocation;
begin
  for Loc in FLedger do
    if (Loc.LocationId = FCurrentLocation) and
      (Pos(LowerCase(AItemName), LowerCase(Loc.Instance.Definition.Name)) > 0) then
    begin
      Loc.LocationId := LOC_INVENTORY;
      WriteLn('You take the ' + Loc.Instance.Definition.Name + '.');
      Exit;
    end;
end;

procedure TGameWorld.RemoveItemFromInventory(const AItemName: string);
var
  Loc: TItemLocation;
begin
  for Loc in FLedger do
    if (Loc.LocationId = LOC_INVENTORY) and
      (Pos(LowerCase(AItemName), LowerCase(Loc.Instance.Definition.Name)) > 0) then
    begin
      Loc.LocationId := FCurrentLocation;
      WriteLn('You drop the ' + Loc.Instance.Definition.Name + '.');
      Exit;
    end;
end;

procedure TGameWorld.RemoveItemFromWorld(AInstanceID: integer);
var
  i: integer;
begin
  for i := FLedger.Count - 1 downto 0 do
    if FLedger[i].Instance.InstanceId = AInstanceID then FLedger.Delete(i);
end;

end.
