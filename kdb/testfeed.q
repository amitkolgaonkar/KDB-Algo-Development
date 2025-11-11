/ ----------------------------------------------------------
/ Realistic Synthetic Option Chain Feed for NIFTY
/ Publishes to Tickerplant on port 5010 every 1 second
/ ----------------------------------------------------------
interval_ms: "J"$@[getenv; `FEED_INTERVAL; {"1000"}];
/ Connect to Tickerplant (TP)
.tp: hopen `:tick:5010;
if[null .tp; 0N!"ERROR: Cannot connect to TP - check tick.q"; exit 1 ];
/ Symbols and strikes
symbol:`NIFTY;
expiry: 2025.11.14; / upcoming Friday expiry
base_strike:24500; / approximate ATM
strikes: base_strike + 50 * til 11; / 24500–25000 (11 strikes)
/ Helper: generate realistic random option prices
randf:{[min;max] min + (max - min) * rand 1f;} / uniform float
/ Start feed loop
while[1b; {
  time:.z.p;
  / Generate CALL and PUT data for each strike
  data: flip `time`symbol`expiry`strike`option_type`bid`ask`last`volume`open_interest`implied_vol!(
    raze each (
      {[t;s;e;strk;opt]
        n:count strk;
        / base price and spread logic
        bid:(100f - 2f*abs[strk - base_strike]%100) + 10f*rand[n]?1f;
        ask:bid + 1f + rand[n]?3f;
        last:(bid + ask)%2f + randf[-1f;1f];
        volume:1000j + 500j * (n?1j);
        oi:20000j + 5000j * (n?1j);
        iv:randf[10f;25f];
        (n#t; n#s; n#e; strk; opt; bid; ask; last; volume; oi; iv)
      }[time; symbol; expiry; strikes; `CALL],
      {[t;s;e;strk;opt]
        n:count strk;
        bid:(110f - 2f*abs[strk - base_strike]%100) + 10f*rand[n]?1f;
        ask:bid + 1f + rand[n]?3f;
        last:(bid + ask)%2f + randf[-1f;1f];
        volume:1200j + 800j * (n?1j);
        oi:25000j + 7000j * (n?1j);
        iv:randf[12f;28f];
        (n#t; n#s; n#e; strk; opt; bid; ask; last; volume; oi; iv)
      }[time; symbol; expiry; strikes; `PUT]
    )
  );
  / Publish to Tickerplant
  msg: ".u.upd[`option_chain;", .Q.s enlist data, "]";
  .tp msg;
  show "Published ", string[count data], " NIFTY option ticks at ", string time;
  / Sleep for interval (seconds as float)
  system "sleep ", string[interval_ms % 1000 / 1000.0];
}];