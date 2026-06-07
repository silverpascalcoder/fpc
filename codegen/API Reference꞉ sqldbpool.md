---
title: 'API Reference: sqldbpool'
created: '2026-06-06T01:32:43.999Z'
modified: '2026-06-06T01:32:46.019Z'
---

# # API Reference: `sqldbpool`

The `sqldbpool` unit implements a high-performance, thread-safe connection pooling framework for the Free Component Library (FCL) SQLDB data access layer. It provides automatic lifecycle management, timeout enforcement, and connection reuse strategies optimized for concurrent database-driven applications.

---

## Constants

### `DefaultDisconnectTimeOut`

```pascal
const DefaultDisconnectTimeOut = 10 * 60;

```

The default duration, in seconds, that an inactive database connection is permitted to remain idle within a pool list before it becomes eligible for automatic reclamation and closure during maintenance passes.

---

## Type Definitions

### `TPoolLogEvent`

```pascal
type TPoolLogEvent = procedure(Sender: TObject; const Msg: string) of object;

```

Standardized callback signature utilized by pooling components to forward internal structural operations, warnings, performance thresholds, or connection state changes to diagnostic listeners.

---

## Exception Classes

### `ESQLDBPool`

```pascal
type ESQLDBPool = class(EDatabaseError);

```

The generic exception type raised when structural allocation violations, internal synchronization blocks, configuration limits, or lifecycle validation checks fail within the pooling framework.

---

## Core Classes

### `TSQLDBConnectionDef`

Represents a precise database connection definition profile, acting as the structural identity key within the hash routing matrix.

#### Constructors & Destructors

##### `Create`

```pascal
constructor Create(ACollection: TCollection); override;

```

* **Parameters:** `ACollection` — The managing collection container instance.
* **Remarks:** Instantiates internal string dictionary allocations for parameter definitions and overrides default execution flags to activate the connection tracking channel.

##### `Destroy`

```pascal
destructor Destroy; override;

```

* **Remarks:** Safely tears down parameter list allocations and systematically unlinks runtime key generation caches prior to passing control back up the inheritance chain.

#### Public Methods

##### `Assign`

```pascal
procedure Assign(Source: TPersistent); override;

```

* **Parameters:** `Source` — A source persistent object instance (`TSQLDBConnectionDef` or a live `TSQLConnection`).
* **Remarks:** Performs deep field-level replication of targeted connection parameters, resetting downstream indexing keys to match configuration states.

##### `GetDescription`

```pascal
function GetDescription(Full: Boolean = False): string;

```

* **Parameters:** `Full` — Flag determining whether confidential or verbose parameter subsets (passwords, specific extra parameters) are attached.
* **Returns:** A formatted, human-readable comma-delimited string summarizing identifying configuration values.

##### `ToString`

```pascal
function ToString: string; override;

```

* **Returns:** Equivalent to executing `GetDescription(False)`.

#### Published Properties

* **`ConnectionType: String`** — The registered name mapping directly to an underlying driver connector block (e.g., `'PostgreSQL'`).
* **`Name: UTF8String`** — Unique alias assigned to this definition inside programmatic management dictionaries.
* **`DatabaseName: UTF8String`** — The precise operational target identifier on the target server.
* **`HostName: UTF8String`** — Network location or IP coordinate pointing to the hosting server database instance.
* **`UserName: UTF8String`** — Authentication identity provided during validation handshakes.
* **`Role: UTF8String`** — Optional permissions group context applied immediately upon connection verification.
* **`Password: UTF8String`** — Secret phrase used to validate database authorization.
* **`Params: TStrings`** — Extensible key-value text pairs capturing driver-specific options.
* **`CharSet: UTF8String`** — Client-side communication character compilation standard used to enforce encoding rules.
* **`Port: Word`** — Explicit network communication gateway endpoint mapping directly into operational parameters.
* **`Enabled: Boolean`** — Runtime verification toggle indicating if new allocations are permitted against this specification. Defaults to `True`.

---

### `TConnectionPoolData`

Low-level wrapper encapsulating an individual `TSQLConnection` along with atomic usage metrics and concurrency locks.

#### Constructors & Destructors

##### `Create`

```pascal
constructor Create(aConnection: TSQLConnection; aLocked: Boolean = True);

```

* **Parameters:**
* `aConnection` — An active SQLDB database connection instance to track.
* `aLocked` — Initial state of the checking gate.


* **Remarks:** Captures precision time metrics immediately upon object allocation to establish an accurate base baseline for lifetime evaluation logic.

##### `Destroy`

```pascal
destructor Destroy; override;

```

* **Remarks:** Inherits standard destruction mechanics. Does *not* automatically release the referenced connection object; resource tracking must be deliberately resolved using `FreeConnection`.

#### Public Methods

##### `Lock`

```pascal
procedure Lock;

```

* **Remarks:** Transitions the internal status tracking to active reservation, updating the activity timestamp to protect the channel from concurrent collection maintenance sweeps.

##### `Unlock`

```pascal
procedure Unlock;

```

* **Remarks:** Clears active reservations, updating historical tracking timestamps to let connection collection loops audit relative inactivity lengths accurately.

##### `FreeConnection`

```pascal
procedure FreeConnection;

```

* **Remarks:** Safely cleans up the tracking structure by explicitly breaking database links, releasing internal transactions, closing connectivity paths, and freeing instance memory allocations.

#### Public Properties

* **`Connection: TSQLConnection`** — Direct access to the supervised database connectivity component.
* **`LastUsed: TDateTime`** — Precision log record tracking the final moment the channel changed its operational configuration state.
* **`Locked: Boolean`** — Thread-safety indicator signaling if a connection is currently busy processing an application task.

---

### `TConnectionList`

A single thread-safe connection queue tracking active resource allocations for a unique configuration archetype profile.

#### Constructors & Destructors

##### `Create`

```pascal
constructor Create; reintroduce;

```

* **Remarks:** Initializes thread synchronization elements alongside timeout configuration limits, establishing isolated transaction queues.

##### `Destroy`

```pascal
destructor Destroy; override;

```

* **Remarks:** Tears down internal mutex structures after validating that active tracked components have been dropped.

#### Public Methods

##### `AddConnection`

```pascal
function AddConnection(aConnection: TSQLConnection; aLocked: Boolean = True): TConnectionPoolData;

```

* **Parameters:**
* `aConnection` — The newly instantiated connectivity engine to track.
* `aLocked` — Initial processing reservation setting.


* **Returns:** A wrapper reference managing structural entry lifecycles inside the array grid.

##### `DisconnectAll`

```pascal
procedure DisconnectAll;

```

* **Remarks:** Enters a blocking mutex state to safely strip out all unreserved, unlocked connection tracks, dropping physical channels safely.

##### `DisconnectOld`

```pascal
function DisconnectOld(aTimeOut: Integer = -1): Integer;

```

* **Parameters:** `aTimeOut` — Overriding duration threshold limit (in seconds). Pass `-1` to fallback to default values.
* **Returns:** Total count of expired resources successfully cleaned out.

##### `PopConnection`

```pascal
function PopConnection: TSQLConnection;

```

* **Returns:** An available, locked `TSQLConnection` context, or `nil` if all tracked connections are currently busy.
* **Remarks:** Automatically scans and purges stale resources using inner maintenance parameters before selecting the next available idle instance.

##### `UnlockConnection`

```pascal
function UnlockConnection(aConnection: TSQLConnection): Boolean;

```

* **Parameters:** `aConnection` — Target connection instance to return to the idle queue.
* **Returns:** `True` if the reference matched an item in the tracking list and was successfully returned to service.

#### Public Properties

* **`DisconnectTimeout: Integer`** — Maximum allowed idle lifespan, in seconds, before a connection is treated as stale.
* **`OnLog: TPoolLogEvent`** — Pipeline destination link used to forward inner operational telemetry reports.

---

### `TSQLDBConnectionPool`

High-level multi-pool repository utilizing hash maps to index and manage collections of connection lists grouped by common operational profiles.

#### Constructors & Destructors

##### `Create`

```pascal
constructor Create(aOwner: TComponent); override;

```

* **Parameters:** `aOwner` — The component hierarchal system owner context.
* **Remarks:** Instantiates the primary hash indexing map alongside parent operational synchronization primitives.

##### `Destroy`

```pascal
destructor Destroy; override;

```

* **Remarks:** Iterates across all dictionary entries to free connection lists and related memory before dismantling thread safety locks.

#### Public Methods

##### `AddConnection`

```pascal
procedure AddConnection(aConnection: TSQLConnection; aLocked: Boolean = True);

```

* **Parameters:**
* `aConnection` — Active network interface block to pool.
* `aLocked` — Reservation state assigned to the tracking profile wrapper.



##### `CountAllConnections`

```pascal
function CountAllConnections: Integer;

```

* **Returns:** The global count of all connections currently tracked across every pool entry managed by the instance.

##### `CountConnections`

```pascal
function CountConnections(aDef: TSQLDBConnectionDef): Integer; overload;
function CountConnections(aInstance: TSQLConnection): Integer; overload;
function CountConnections(aClass: TSQLConnectionClass; const aDatabaseName, aHostName, aUserName, aPassword: string; aParams: TStrings = nil): Integer; overload;

```

* **Returns:** Total resource allocation calculations matching the specified parameter signature matrix.

##### `FindConnection`

```pascal
function FindConnection(const aConnectionDef: TSQLDBConnectionDef): TSQLConnection; overload;
function FindConnection(aClass: TSQLConnectionClass; const aDatabaseName, aHostName, aUserName, aPassword: string; aParams: TStrings = nil): TSQLConnection; overload;

```

* **Returns:** A locked, validated execution resource if a slot is open in the matching sub-pool list; otherwise `nil`.

##### `ReleaseConnection`

```pascal
function ReleaseConnection(aConnection: TSQLConnection): Boolean;

```

* **Parameters:** `aConnection` — Target connection to mark as ready for reuse.
* **Returns:** `True` if the resource matched an internal routing address and was successfully unlocked.

#### Public Properties

* **`OnLog: TPoolLogEvent`** — System diagnostic router used to pipe execution events out to external logging infrastructures.

---

### `TSQLDBConnectionmanager`

The central manager component that coordinates resource definitions, validates system capacities, and handles application checkouts.

#### Constructors & Destructors

##### `Create`

```pascal
constructor Create(aOwner: TComponent); override;

```

* **Parameters:** `aOwner` — Standard design-time ownership architecture target component.

##### `Destroy`

```pascal
destructor Destroy; override;

```

* **Remarks:** Releases both local definitions and pooling mechanisms, ensuring clean deallocations at application shutdown.

#### Public Methods

##### `CreateConnection`

```pascal
function CreateConnection(const aDef: TSQLDBConnectionDef; addToPool: Boolean): TSQLConnection; overload;
function CreateConnection(const aName: string; addToPool: Boolean): TSQLConnection; overload;

```

* **Parameters:**
* `aDef` / `aName` — The configuration profile signature or named alias.
* `addToPool` — When `True`, assigns the newly created resource directly to the pool system.


* **Returns:** An initialized `TSQLConnection` instance complete with a valid, associated `TSQLTransaction`.

##### `GetConnection`

```pascal
function GetConnection(const aDef: TSQLDBConnectionDef): TSQLConnection; overload;
function GetConnection(const aName: string): TSQLConnection; overload;

```

* **Parameters:** `aDef` / `aName` — Target profile specifications.
* **Returns:** A ready-to-use, thread-locked database connection.
* **Errors:** Raises an `ESQLDBPool` exception if a new connection is required but pool capacities defined by `MaxDBConnections` or `MaxTotalConnections` are exceeded.

##### `ReleaseConnection`

```pascal
function ReleaseConnection(aConnection: TSQLConnection): Boolean;

```

* **Parameters:** `aConnection` — The tracking object instance to return to the pool.
* **Returns:** `True` if the connection was successfully routed back to its originating pool list.

#### Published Properties

* **`Pool: TSQLDBConnectionPool`** — Connects to a specific pooling instance. Automatically defaults to an internal, self-managed pool subsystem if unassigned.
* **`Definitions: TSQLDBConnectionDefList`** — Indexed collection containing predefined database configuration connection templates.
* **`MaxDBConnections: Word`** — Maximum concurrent connection limit allowed for a single configuration key profile. Set to `0` for unlimited connections.
* **`MaxTotalConnections: Cardinal`** — Global pool capacity cap across all connection profiles. Set to `0` for unlimited connections.
* **`ConnectionOwner: TComponent`** — The owner assigned to newly instantiated database components. Helpful for managing transactional lifecycles.
* **`OnLog: TPoolLogEvent`** — Primary diagnostic event pipeline for monitoring database pool activity.
* **`LogEvents: TDBEventTypes`** — Set of event filters applied directly to generated connection components to control trace verbosity.

---

## Class Helpers

### `TSQLConnectionHelper`

```pascal
type TSQLConnectionHelper = class helper for TSQLConnection

```

An internal string-processing utility class helper that extracts metadata configurations from active `TSQLConnection` targets for debugging and identification purposes.

---

## Code Example

The following example demonstrates how to configure the `TSQLDBConnectionmanager`, register a connection configuration profile, check out a connection safely, and execute operations inside an isolated atomic transaction block.

```pascal
program PoolArchitectureExample;

{$mode objfpc}{$H+}

uses
  Classes, 
  SysUtils, 
  sqldb, 
  sqldbpool, 
  pqconnection; // Utilizing PostgreSQL connection driver implementation

var
  PoolManager: TSQLDBConnectionmanager;
  ConfigDef: TSQLDBConnectionDef;
  DbConn: TSQLConnection;
  DbTransaction: TSQLTransaction;
  Query: TSQLQuery;
begin
  PoolManager := TSQLDBConnectionmanager.Create(nil);
  try
    // 1. Establish structural limits across pool channels
    PoolManager.MaxDBConnections := 5;
    PoolManager.MaxTotalConnections := 20;

    // 2. Register database connection profile specifications
    ConfigDef := PoolManager.Definitions.Add as TSQLDBConnectionDef;
    ConfigDef.Name := 'Production_DB';
    ConfigDef.ConnectionType := 'PostgreSQL';
    ConfigDef.HostName := '127.0.0.1';
    ConfigDef.DatabaseName := 'ledger_db';
    ConfigDef.UserName := 'db_operator';
    ConfigDef.Password := 'SecuredVaultPassword';
    ConfigDef.Params.Add('port=5432');

    // 3. Acquire a thread-safe connection resource from the pool manager
    // This will either reuse an idle connection or safely allocate a new one.
    DbConn := PoolManager.GetConnection('Production_DB');
    try
      // The framework automatically configures and attaches a valid transaction context
      DbTransaction := DbConn.Transaction;
      
      Query := TSQLQuery.Create(nil);
      try
        Query.Database := DbConn;
        Query.Transaction := DbTransaction;
        
        // Open the transactional pipeline boundary
        DbTransaction.StartTransaction;
        try
          Query.SQL.Text := 'UPDATE accounts SET balance = balance - 150 WHERE id = 101;';
          Query.ExecSQL;
          
          // Commit the operations if execution completes cleanly
          DbTransaction.Commit;
        except
          on E: Exception do
          begin
            DbTransaction.Rollback;
            raise;
          end;
        end;
      finally
        Query.Free;
      end;
      
    finally
      // 4. Always return the connection back to the manager pool
      // This unlocks the resource instance so other tasks can reuse it.
      PoolManager.ReleaseConnection(DbConn);
    end;

  finally
    // This systematically cleans up all allocated connections inside the pool
    PoolManager.Free;
  end;
end.

```
