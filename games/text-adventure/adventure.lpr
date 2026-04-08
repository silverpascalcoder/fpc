program adventure;

{$IFDEF FPC}
{$mode ObjFPC}{$H+}
{$ENDIF}

uses
  uGameTypes, uParser, uEngine, uGameWorld, SysUtils, uOutput;

procedure InitGameWorld(var W: TGameWorld);
begin
  { Define Item Blueprints (Master Data) }
  { Params: ID, Name, Description, Value, BaseDamage }
  W.AddDefinition(1, 'Silver Fork', 'A tarnished fork with a family crest.', 15, 1);
  W.AddDefinition(2, 'Steel Dagger', 'A sharp, double-edged blade.', 50, 8);
  W.AddDefinition(3, 'Iron Spear', 'A long reach weapon with a wicked tip.', 30, 12);
  W.AddDefinition(4, 'Medical Kit', 'A pouch of clean bandages and smelling salts.', 25, 0);
  W.AddDefinition(5, 'Brass Lantern', 'A sturdy lantern. It currently lacks oil.', 10, 2);

  { Create the Map Nodes }
  W.AddNode(1, 'The Grand Foyer', 'A vast entrance hall. A massive chandelier hangs precariously from the ceiling.');
  W.AddNode(2, 'The Kitchen', 'The air is thick with the scent of rosemary and old grease.');
  W.AddNode(3, 'The Dining Room', 'A long oak table dominates the space, set for a feast that never happened.');
  W.AddNode(4, 'The Cellar', 'It is dark and damp here. The sound of dripping water echoes.');
  W.AddNode(5, 'The Guard Post', 'A small stone room designed for sentries to watch the cellar entrance.');

  { Link the Rooms }
  W.LinkNodes(1, 3, dNorth); { Foyer <-> Dining Room }
  W.LinkNodes(3, 2, dWest);  { Dining Room <-> Kitchen }
  W.LinkNodes(2, 4, dDown);  { Kitchen <-> Cellar }
  W.LinkNodes(4, 5, dEast);  { Cellar <-> Guard Post }

  { Setup Player Attributes (Point-Buy style) }
  W.Player.Stats.Strength := 12;
  W.Player.Stats.Agility := 14;  { High agility for sneaking }
  W.Player.Stats.Intelligence := 10;
  W.Player.Stats.Charisma := 8;
  W.Player.Health := 100;
  W.Player.MaxHealth := 100;

  { Spawn World Items }
  W.SpawnItem(1, 3); { Fork in Dining Room }
  W.SpawnItem(2, 1); { Dagger in Foyer (Starter Weapon) }
  W.SpawnItem(4, 2); { Medical Kit in Kitchen }
  W.SpawnItem(5, 4); { Lantern in Cellar }

  { Spawn Enemies with Equipment and States }
  { Params: Name, HP, STR, Agil, Location, State, WeaponDefID }

  { A sleeping guard in the Guard Post - perfect for a sneak or surprise attack }
  W.SpawnEnemy('Drunken Sentry', 40, 10, 5, 5, esSleeping, 3);

  { A hungry stray in the kitchen - alert and hostile }
  W.SpawnEnemy('Feral Dog', 20, 8, 12, 2, esAware, 0);
end;

var
  World: TGameWorld;
begin
  Randomize;
  World := TGameWorld.Create;
  try
    InitGameWorld(World);
    RunGame(World);
  finally
    World.Free;
  end;
end.
