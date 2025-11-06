/ ----------------------------------------------------------
/ Real-time Database (RDB) - Port 5011
/ ----------------------------------------------------------
\l schema.q  / Load schemas

/ Connect to TP
.tp: hopen `::5010;

/ Replay log on startup
if[.u.L > 0;
  loglines: value .tp ".u.i";
  if[count loglines;
    replay:{[line] [t;x]: line; if[t=`option_chain; `option_chain upsert x] } each loglines;
    0N!"Replayed ", string[count loglines], " log lines"
  ]
];

/ RDB Update Handler
.u.upd:{[t;x] if[t=`option_chain; `option_chain upsert x; 0N!"RDB upserted ", string[count x], " rows" ] };

/ Subscribe to TP
.tp ".u.sub[`option_chain; () ]";

/ EOD Handler (splay to HDB /hdb/, clear RDB)
.u.end:{[] 
  t: asc `time xcol `option_chain;  / Sort
  `option_chain set t;
  .Q.dpft[`: /hdb/; `option_chain; `symbol; 0b];  / Splay partitioned by symbol (create dir if needed)
  delete from `option_chain;
  0N!"EOD: Splayed option_chain to /hdb/, RDB cleared"
 };

show "RDB started on port ", string[.z.p], " - Subscribed to TP";