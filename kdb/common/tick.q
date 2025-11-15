/ -------------------------------------------
/ tick.q  — tickerplant + IBKR market-data feed
/ -------------------------------------------
\l schema.q
system "p 5000"
.subs:()

.u.sub:{[tbl; args]
    h:.z.w;
    if[not any h=.subs; .subs,: enlist h];
    0N!"TP: subscriber added ", string h;
}

.u.unsub:{[tbl; args]
    h:.z.w;
    .subs: .subs where not .subs = h;
    0N!"TP: subscriber removed ", string h;
}


/*
Feeder pushes into TP by calling .tick.upd
*/
.tick.upd:{[t;x]
    if[t=`option_chain; option_chain upsert x];
    if[t=`underlying; underlying upsert x];

    { try h(".u.upd"; t; x) catch {0N!"TP forward fail to ", string h}} each .subs;
    0N!"TP: forwarded ", string count x, " rows to ", string count .subs, " subscribers for ", string t;
}
