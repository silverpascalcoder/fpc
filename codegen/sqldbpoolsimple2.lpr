program sqldbpoolsimple2;

{$mode objfpc}
{$H+}

uses
  SysUtils, DB, SqlDB, SqlDBPool, uDBContext,
  IBConnection;

var
  DBContext : IDBContext;
  Qry       : TSQLQuery;

begin
  // 1. Create the manager
  TDB.Initialize('main', 'Firebird',
    'localhost', '/home/tim/dev/database/wedding.fdb',
    'SYSDBA', 'masterkey', 32);
  DBContext := TDB.GetContext('main');
  Qry := DBContext.NewQuery('SELECT * FROM PERSON');
  try
    Qry.Open;
    while not Qry.EOF do
    begin
      WriteLn(Qry.Fields[0].AsString + ' | ' + Qry.Fields[1].AsString);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end.
