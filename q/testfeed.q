/ ----------------------------------------------------------
/ Synthetic tick feed for BANKNIFTY and NIFTY
/ ----------------------------------------------------------
/ Get environment variable FEED_INTERVAL; default 1000 ms
interval_ms: "J"$@[getenv; `FEED_INTERVAL; {"1000"}];
symbols: (`BANKNIFTY; `NIFTY);
while[1b; {
  time: .z.p;
  {
    symbol: x;
    n: 3;
    data: ([])
      time: n#enlist time;
      symbol: n#symbol;
      strike: 44000 + 100 * til n;
      option_type: ("CALL"; "PUT"; "CALL");
      bid: 100f + n?100f;
      ask: bid + 1f + n?5f;
      last: bid + n?3f;
      volume: 1000j + n?500j;
    .u.upd[`option_chain; data];
    show "Published ", string symbol, " at ", string time;
  } each symbols;
  / ✅ safe portable sleep (milliseconds)
  sleep_t: interval_ms * 1000000;  / ns
  start: .z.n;                     / current nanotime
  while[.z.n - start < sleep_t; {::}];  / unary no-op body
  ::  / outer no-op (returns null for accumulation)
}];