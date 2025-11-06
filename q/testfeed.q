/ ----------------------------------------------------------
/ Synthetic Tick Feed for BANKNIFTY and NIFTY (to TP)
/ ----------------------------------------------------------
interval_ms: "J" $ @[getenv; `FEED_INTERVAL; {"1000"}];
symbols: (`BANKNIFTY; `NIFTY);

/ Connect to TP (port 5010)
.tp: hopen `::5010;
if[null .tp; 0N!"ERROR: Cannot connect to TP - check if running"; exit 1 ];

/ Feed loop
while[1b; {
  time: .z.p;
  {
    symbol: x;
    n: 3;  / Strikes per symbol
    / Realistic ATM strikes (Nov 4, 2025 approx)
    base_strike: $[symbol=`NIFTY; 24500; 51500];
    data: ([])
      time: n # enlist time;
      symbol: n # symbol;
      strike: base_strike + 50 * til n;  / e.g., 24500, 24550, 24600 (float for precision)
      option_type: ("CALL"; "PUT"; "CALL");
      bid: 100f + n ? 100f;
      ask: bid + 1f + n ? 5f;
      last: bid + n ? 3f;
      volume: 1000j + n ? 500j;
    / Send serialized table to TP's .u.upd
    .tp (".u.upd[`option_chain;] ", .Q.s enlist flip data);
    show "Published ", string[symbol], " (", string[count data], " ticks) at ", string[time];
    
    / Optional: Add Greeks (synthetic)
    greeks_data: ([])
      time: n # enlist time;
      symbol: n # symbol;
      gamma: 0.03f + n ? 0.01f;
      theta: -5.0f + n ? 1.0f;
      vega: 15.0f + n ? 5.0f;
    .tp (".u.upd[`greeks;] ", .Q.s enlist flip greeks_data);
  } each symbols;
  
  / Sleep (ms) - Use system for portability (works in Docker/Linux)
  / Alternative busy-wait below if needed
  system "sleep ", string[interval_ms % 1000], ".", string[interval_ms % 1000];  / Seconds + fraction (approx)
  
  / Busy-wait fallback (fixed: use :: no-op, no {})
  / sleep_ns: interval_ms * 1000000j;
  / start_ns: .z.n;
  / while[.z.n - start_ns < sleep_ns; :: ];
 }];