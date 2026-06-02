program sqldbpoolsimple;

{$mode objfpc}
{$H+}

uses
  SysUtils, DB, SqlDB, {IBConnection,} SqlDBPool;

var
  Manager : TSQLDBConnectionManager;
  Def     : TSQLDBConnectionDef;
  Conn    : TSQLConnection;
  Qry     : TSQLQuery;

begin
  // 1. Create the manager
  Manager := TSQLDBConnectionManager.Create(nil);
  try
    // 2. Define the connection
    Def                := TSQLDBConnectionDef(Manager.Definitions.Add);
    Def.Name           := 'main';
    Def.ConnectionType := 'Firebird';
    Def.HostName       := 'localhost';
    Def.DatabaseName   := '/home/tim/dev/database/wedding.fdb';
    Def.UserName       := 'SYSDBA';
    Def.Password       := 'masterkey';
    Def.CharSet        := 'UTF8';

    // 3. Borrow a connection from the pool
    Conn := Manager.GetConnection('main');
    try
      // 4. Run a query
      Qry := TSQLQuery.Create(nil);
      try
        Qry.DataBase    := Conn;
        Qry.Transaction := Conn.Transaction;
        Qry.SQL.Text    := 'SELECT * FROM PERSON';
        Qry.Open;
        while not Qry.EOF do
        begin
          WriteLn(Qry.Fields[0].AsString + ' | ' + Qry.Fields[1].AsString);
          Qry.Next;
        end;
      finally
        Qry.Free;
      end;

    finally
      // 5. Return the connection to the pool
      Manager.ReleaseConnection(Conn);
    end;

  finally
    Manager.Free;
  end;
end.
