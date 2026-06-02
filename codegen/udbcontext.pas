unit uDBContext;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, sqldb, sqldbpool;

type
  { Public connection contract exposed to your application routes }
  IDBContext = interface
    ['{69AA6A4D-7E3C-4C9D-B1A2-F3E4D5C6B7A8}']
    function NewQuery(const ASQL: string): TSQLQuery;
    procedure Commit;
  end;

  { The Master Infrastructure Namespace }
  TDB = class
  private
    // Private static variable holding the actual shared engine pool
    class var FManager: TSQLDBConnectionManager;
  public
    // Class methods do not require an instantiated object instance to run
    class procedure Initialize(const AConnName, ADriver, AHost, ADBName, AUser, APass: string; AMaxConns: Integer);
    class procedure Finalize;
    class function GetContext(const AConnectionName: string): IDBContext;
  end;

  { Concrete scope guard that manages the checkout and return cycle }
  TDBContext = class(TInterfacedObject, IDBContext)
  private
    FManager: TSQLDBConnectionManager;
    FConnection: TSQLConnection;
  public
    constructor Create(AManager: TSQLDBConnectionManager; const AConnectionName: string);
    destructor Destroy; override;

    function NewQuery(const ASQL: string): TSQLQuery;
    procedure Commit;
  end;

implementation

{ TDB Static Class Methods }

class procedure TDB.Initialize(const AConnName, ADriver, AHost, ADBName, AUser, APass: string; AMaxConns: Integer);
var
  Def: TSQLDBConnectionDef;
begin
  if Assigned(FManager) then Exit;

  FManager := TSQLDBConnectionManager.Create(nil);
  FManager.MaxDBConnections := AMaxConns;
  FManager.MaxTotalConnections := AMaxConns;

  // Set up the registered configuration profile name inside the pool manager
  Def := FManager.Definitions.Add as TSQLDBConnectionDef;
  Def.Name := AConnName;
  Def.ConnectionType := ADriver;
  Def.HostName := AHost;
  Def.DatabaseName := ADBName;
  Def.UserName := AUser;
  Def.Password := APass;
end;

class procedure TDB.Finalize;
begin
  if Assigned(FManager) then
  begin
    FManager.Free;
    FManager := nil;
  end;
end;

class function TDB.GetContext(const AConnectionName: string): IDBContext;
begin
  if not Assigned(FManager) then
    raise EDatabaseError.Create('Database infrastructure has not been initialized. Call TDB.Initialize first.');

  // Hand back the interfaced wrapper context, initializing the reference count to 1
  Result := TDBContext.Create(FManager, AConnectionName);
end;

{ TDBContext Implementation }

constructor TDBContext.Create(AManager: TSQLDBConnectionManager; const AConnectionName: string);
begin
  inherited Create;
  FManager := AManager;
  FConnection := FManager.GetConnection(AConnectionName);
end;

destructor TDBContext.Destroy;
begin
  Writeln('called destructor TDBContext.Destroy');
  if Assigned(FConnection) then
  begin
    if Assigned(FConnection.Transaction) and FConnection.Transaction.Active then
      FConnection.Transaction.Rollback;

    if Assigned(FManager) then
      FManager.ReleaseConnection(FConnection);
  end;
  inherited Destroy;
end;

function TDBContext.NewQuery(const ASQL: string): TSQLQuery;
begin
  Result := TSQLQuery.Create(nil);
  Result.Database := FConnection;
  Result.Transaction := FConnection.Transaction;
  Result.SQL.Text := ASQL;
end;

procedure TDBContext.Commit;
begin
  if Assigned(FConnection) and Assigned(FConnection.Transaction) then
    FConnection.Transaction.Commit;
end;

finalization
  TDB.Finalize;
end.
