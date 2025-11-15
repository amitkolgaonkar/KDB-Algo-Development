\l schema.q
system "p 6000"

/ connect to TP
.tp: hopen `:kdb-tick:5000;
if[not null .tp; 0N!"Signal: connected to TP"];

/ subscribe
.tp ".u.sub[`option_chain;()]";
0N!"Signal: subscribed to option_chain";

iv_threshold: 14.0
lookbackSecs: 60

avgIVNearestExpiry:{[]
    exps: distinct exec expiry from option_chain where not null expiry;
    if[count exps=0; : 0N];
    nearExp:first exps;
    rows: select implied_vol from option_chain where expiry=nearExp, time>.z.p - 00:01:00;
    if[count rows=0; : 0N];
    : avg rows`implied_vol
}

sendSignal:{[strategyName; reason; params]
    stime:.z.p;
    / persist signal to RDB for audit
    r:hopen `:kdb-rdb:5010;
    if[not null r; r("upsert[`signals]"; (`time`strategy`reason`params)!(stime; strategyName; reason; params)); hclose r];

    / notify strategy engine
    s:hopen `:kdb-strategy:7000;
    if[not null s; try s(".u.signal"; strategyName; reason; params; stime) catch {0N!"Signal: failed to contact strategy"}; hclose s];

    0N!"Signal: sent ", string strategyName, " reason:", string reason;
}

.u.upd:{[t;x]
    if[t=`option_chain;
        curIV: avgIVNearestExpiry[];
        if[not null curIV;
            if[curIV > iv_threshold;
                sendSignal[`straddle; `iv_spike; (`iv curIV)];
            ];
        ];
    ];
}
