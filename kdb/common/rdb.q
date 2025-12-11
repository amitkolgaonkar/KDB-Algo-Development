\l schema.q
system "p 5010"

/ connect to TP (container names are used for hopens)
.tp: hopen `:tick:5000;
if[not null .tp; 0N!"RDB: connected to TP"];

/ subscribe to streams
/.tp ".u.sub[`option_chain;()]";
.tp "sub[`option_chain]";
/.tp ".u.sub[`underlying;()]";
.tp "sub[`underlying]";
0N!"RDB: subscribed to option_chain and underlying";

/ normalization placeholder
normalizeOptionChain:{[x] x }

.u.upd:{[t;x]
    if[t=`option_chain;
        nx: normalizeOptionChain[x];
        option_chain upsert nx;
        nifty_opts:update last each bid, ask, last, implied_vol, volume, open_interest, time by strike, right, expiry, symbol from option_chain;
        0N!"RDB: option_chain upserted ", string count nx, " rows";
    };
    if[t=`underlying;
        underlying upsert x;
        0N!"RDB: underlying upserted ", string count x, " rows";
    };
}
