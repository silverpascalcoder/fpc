program guard_demo;

{$mode objfpc}{$H+}

(*
https://www.sec.gov/news/studies/2010/marketevents-report.pdf
https://www.sifma.org/research/insights/10th-flash-crash-anniversary
https://repository.uclawsf.edu/cgi/viewcontent.cgi?article=1172&context=hastings_business_law_journal
*)

uses
  SysUtils,
  ArgCheck in 'ArgCheck.pas';


procedure ProcessOrder(const Ticker: string;
                       Quantity: Integer;
                       Price: Currency;
                       LastPrice: Currency);
begin
  Writeln(Format('Processing: %d shares of %s at %m...', [Quantity, Ticker, Price]));

  // 1. String Protection
  TArgumentString.IsNotEmpty({$I %CURRENTROUTINE%}, 'Ticker', Ticker);

  // 2. Quantity Protection (Integer)
  TArgumentInteger.IsPositive({$I %CURRENTROUTINE%}, 'Quantity', Quantity);
  TArgumentInteger.IsInRange({$I %CURRENTROUTINE%}, 'Quantity', Quantity, 1, 100000); // Limit order size

  // 3. Price Protection (Currency)
  TArgumentCurrency.IsInRange({$I %CURRENTROUTINE%}, 'Price', Price, 0.01, 5000.00);
  TArgumentCurrency.CheckVariance({$I %CURRENTROUTINE%}, 'Price', Price, LastPrice, 15.0); // 15% Max Move

  // what if I don t have sufficient funds!
  // ie. price * volume > funds_available

  Writeln('>>> Result: ORDER SECURED AND VERIFIED.');
end;

// About {$I %CURRENTROUTINE%}
//
// if you are using Delphi (I think) you would need to
//
// const
//   S_Context = 'ProcessFlashCrashOrder';
//
// and then use S_Context as the Context parameter where required. For example
//
// TArgCurrency.CheckVariance({S_Context, 'MarketPrice', ...);
//

var
  MarketPrice: Currency;
begin
  MarketPrice := 150.00;

  try
    Writeln('--- Scenario 1: Normal Operation ---');
    ProcessOrder('MSFT', 100, 155.00, MarketPrice);

    Writeln(#10'--- Scenario 2: Systemic Failure (The Flash Crash Move) ---');
    // Price drops from 150 to 10 in a split second
    ProcessOrder('MSFT', 100, 10.00, MarketPrice);

  except
    on E: Exception do
      Writeln(#10'SURVIVAL ALERT: ' + E.Message);
  end;

  Writeln(#10'Press Enter to exit.');
  Readln;
end.
