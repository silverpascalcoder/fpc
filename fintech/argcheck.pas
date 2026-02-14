unit ArgCheck;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils;

type
  { Specialized Guard for Currency / Fintech logic }
  TArgumentCurrency = record
  public
    class procedure IsInRange(const AContext, AName: string; AValue, AMin, AMax: Currency); static; inline;
    class procedure CheckVariance(const AContext, AName: string; ACurrent, ALast: Currency; AMaxPct: Double); static; inline;
  end;

  { Specialized Guard for Floating Point / Indicator logic }
  TArgumentDouble = record
  public
    class procedure IsPositive(const AContext, AName: string; AValue: Double); static; inline;
    class procedure IsInRange(const AContext, AName: string; AValue, AMin, AMax: Double); static; inline;
    { Used for checking percentage thresholds or multiplier sanity }
    class procedure IsNotNaN(const AContext, AName: string; AValue: Double); static; inline;
  end;

  { Protection for Integer / Quantities }

  { TArgumentInteger }

  TArgumentInteger = record
    class procedure IsInRange(const AContext, AName: string; AValue, AMin, AMax: Int64); static; inline;
    class procedure IsPositive(const AContext, AName: string; AValue: Int64); static; inline;
  end;

  { Specialized Guard for String / Input logic }
  TArgumentString = record
  public
    class procedure IsNotEmpty(const AContext, AName, AValue: string); static; inline;
    class procedure MatchesLength(const AContext, AName, AValue: string; AMaxLen: Integer); static; inline;
  end;

implementation

uses Math;

class procedure TArgumentCurrency.IsInRange(const AContext, AName: string; AValue, AMin, AMax: Currency);
begin
  if (AValue < AMin) or (AValue > AMax) then
    raise EArgumentException.CreateFmt('[%s] %s (%m) is outside allowed range: %m to %m',
      [AContext, AName, AValue, AMin, AMax]);
end;

class procedure TArgumentCurrency.CheckVariance(const AContext, AName: string; ACurrent, ALast: Currency; AMaxPct: Double);
var
  LDelta: Double;
begin
  if ALast <= 0 then Exit;

  LDelta := Abs(ACurrent - ALast) / ALast;

  if LDelta > (AMaxPct / 100.0) then
    raise EArgumentException.CreateFmt('[%s] %s Variance Alert: %g%% move exceeds %g%% limit. (Last: %m, Current: %m)',
      [AContext, AName, LDelta * 100, AMaxPct, ALast, ACurrent]);
end;

{ TArgumentDouble }

class procedure TArgumentDouble.IsPositive(const AContext, AName: string; AValue: Double);
begin
  if AValue <= 0 then
    raise EArgumentException.CreateFmt('[%s] %s (%g) must be greater than zero.', [AContext, AName, AValue]);
end;

class procedure TArgumentDouble.IsInRange(const AContext, AName: string; AValue, AMin, AMax: Double);
begin
  if (AValue < AMin) or (AValue > AMax) then
    raise EArgumentException.CreateFmt('[%s] %s (%g) is outside allowed range: %g to %g',
      [AContext, AName, AValue, AMin, AMax]);
end;

class procedure TArgumentDouble.IsNotNaN(const AContext, AName: string; AValue: Double);
begin
  if IsNaN(AValue) then
    raise EArgumentException.CreateFmt('[%s] %s is Not-a-Number (NaN).', [AContext, AName]);
end;

{ TArgumentInteger }

class procedure TArgumentInteger.IsInRange(const AContext, AName: string;
  AValue, AMin, AMax: Int64);
begin
  if (AValue < AMin) or (AValue > AMax) then
    raise EArgumentException.CreateFmt(
      '[%s] %s (%d) outside allowed range: %d to %d',
      [AContext, AName, AValue, AMin, AMax]);
end;

class procedure TArgumentInteger.IsPositive(const AContext, AName: string;
  AValue: Int64);
begin
  if AValue <= 0 then
    raise EArgumentException.CreateFmt(
    '[%s] %s must be positive. Received: %d',
    [AContext, AName, AValue]);
end;

{ TArgumentString }

class procedure TArgumentString.IsNotEmpty(const AContext, AName, AValue: string);
begin
  if AValue.Trim.IsEmpty then
    raise EArgumentException.CreateFmt('[%s] %s cannot be empty or whitespace.', [AContext, AName]);
end;

class procedure TArgumentString.MatchesLength(const AContext, AName, AValue: string; AMaxLen: Integer);
begin
  if Length(AValue) > AMaxLen then
    raise EArgumentException.CreateFmt('[%s] %s length (%d) exceeds maximum of %d',
      [AContext, AName, Length(AValue), AMaxLen]);
end;

end.
