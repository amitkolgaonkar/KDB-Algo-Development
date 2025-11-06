/ ----------------------------------------------------------
/ Tickerplant (TP) - Port 5010, Log to /tmp/tplog
/ ----------------------------------------------------------
\l schema.q  / Load schemas (option_chain, etc.)

/ Manual .u namespace init (replaces full tick.r.k for simplicity)
.u.lf:{0N!x};  / Simple log func
.u.rep:{(0N!x;.u.lf x)};

/ Init TP components
.u.w:();  / Subscribers (e.g., RDB)
.u.i:0;   / Update counter
.u.L:1;   / Enable logging
.u.l:`: /tmp/tplog  / Log file (binary for recovery)

/ Manual .u.makeupds (creates .u.upd funcs for tables)
.u.makeupds:{[]
  / For each table in schema, create .u.upd[t;data]
  tbls: tables `.;
  .u.upd: { [t;x] 
    if[t in tbls; 
      .u.rep (`upd; t; enlist x) @\: .u.w;  / Publish to subs
      if[.u.L; hopen .u.l; .z.w .u.rep (`upd; t; enlist x); hclose .u.l ];  / Log
      .u.i::.u.i + count x  / Count rows
    ] 
  } /: tbls;  / One func per table
 };

/ Ensure .u.upd funcs exist (fixed: call makeupds if needed)
if[not `upd in key `.u; .u.makeupds[] ];

/ Subscribe handler (RDB connects here)
.z.w:{ [w] .u.w,:w };

/ Unsub
.z.pc:{ [w] .u.w::.u.w except enlist w };

/ EOD Timer (daily)
.z.ts:{ if[.z.D = last .z.D; .u.end[] ] };
\t 86400000;

/ Heartbeat (1s)
.z.t:1000;
.z.ts:{ .u.heart[] };

/ EOD Handler (notify subs)
.u.end:{ [] .u.rep (`end; `) @\: .u.w };

/ Init and start
.u.init: { [] 0N!"TP initialized" };
.u.init[];
0N!"TP started on port ", string[.z.p], " - Log: ", string[.u.l];