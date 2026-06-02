# Pascal Data-Layer Code Generator (`codegen`)

An authentic, zero-boilerplate structural code generation tool built for Modern Object Pascal. It processes database table definitions (`TTableDef`) to generate type-safe data services and standalone integration tests, moving your data layer to an elegant, interface-driven RAII pattern using `IDBContext`.

---

## The Architecture: Feature-Rich, Doc-Poor

Leveraging Free Pascal's highly efficient but undocumented `sqldbpool` core, this tool automates thread-safe connection leasing behind a reference-counted interface scope-guard:


```

[ Your Application Layer ]
│
▼ (Interface Scope Guard)
[ IDBContext ] ──► Automatic reference-counted transactional cleanup
│
▼ (Manages Connection Leases)
[ TDB Static Context Namespace ]
│
▼ (Concurrent Queue)
[ Core FCL sqldbpool Implementation ]

```

When the `IDBContext` variable falls out of scope in your application flow, the Pascal runtime execution engine automatically triggers the reference destructor, rolling back uncommitted transactions and returning the socket handle to the pool without leaky manual boilerplate.

---

## ⚠️ Status: Pending Database Integration Testing

> **NOTICE:** While the core template generation logic, code emitting blocks, and layout tokenization filters are fully verified, **the live database execution paths of the generated code have not yet been fully tested.** Ensure you validate data-type compatibility and execute mappings within an isolated staging environment before moving generated files into production workloads.

---

## Artifact Specifications

1. **Data-Access Services (`u*Service.pas`):** Emits full CRUD functions mapping to your structural table layouts. Services depend strictly on pre-configured runtime pool profiles instead of hardcoded string credentials.
2. **Integration Test Harnesses (`test_*_db.lpr`):** Generates standalone, compile-ready console programs to run execution passes on mock fields to verify system schema validation before pushing to active codebases.

---

## Quick Start Example

### 1. Bootstrap Runtime Pool
Initialize your global database configuration signature at your master application setup level:

```pascal
uses uDBContext;

begin
  TDB.Initialize('main', 'Firebird', 'localhost', '/var/db/wedding.fdb', 'SYSDBA', 'masterkey', 32);
end.

```

### 2. Run Clean Generated Operations

Because memory structures are reference-counted, your service endpoints stay lean:

```pascal
var
  Service: TPersonService;
  RecordData: TPersonRecord;
  NewID: Int64;
begin
  Service := TPersonService.Create;
  try
    FillChar(RecordData, SizeOf(RecordData), 0);
    RecordData.FirstName := 'Tim';
    
    // Smoothly fetches execution lease under the hood from profile 'main'
    NewID := Service.CreateItem(RecordData);
    WriteLn('Created row primary key: ', NewID);
  finally
    Service.Free;
  end;
end; // <-- IDBContext automatically expires here, releasing the thread lease safely!

```
