/ ----------------------------------------------------------
/ Real-time Database (RDB) - Port 5011
/ ----------------------------------------------------------
\l schema.q  / Load schemas

/ Connect to Tickerplant
.tp: hopen `:tick:5010;  / Use tick or localhost depending on setup

if[not null .tp; show "Connected to TP on 5010"];

/ RDB Update Handler
.u.upd:{[t;x]
  if[t=`option_chain;
    `option_chain upsert x;
    0N!"RDB upserted ", string[count x], " rows"
  ]
];

/ Subscribe to TP
if[not null .tp; .tp ".u.sub[`option_chain;()]"; show "Subscribed to option_chain from TP"; ];

/ EOD Handler
.u.end:{
  t: asc `time xcol `option_chain;
  `option_chain set t;
  .Q.dpft[`: /hdb/; `option_chain; `symbol; 0b];
  delete from `option_chain;
  0N!"EOD: Splayed option_chain to /hdb/, RDB cleared"
};

show "RDB started on port ", string[.z.p], " - Subscribed to TP";
