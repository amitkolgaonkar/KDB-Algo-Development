\l schema.q
system "p 7000"

/ subscribe to TP
.tp: hopen `:kdb-tick:5000;
if[not null .tp; .tp ".u.sub[`option_chain;()]"; .tp ".u.sub[`underlying;()]"; 0N!"Strategy: subscribed to TP"];

/ get spot from underlying table
getSpot:{[sym]
    res: select last from underlying where symbol=sym;
    : $[count res; last res; 0N]
}

/ nearest ATM from nifty_opts (snapshot maintained by RDB)
getATM:{[spot]
    strikes: asc distinct select strike from nifty_opts where time>.z.p - 00:05:00;
    if[count strikes=0; : 0N];
    idx:(abs each strikes - spot) mmin;
    : strikes idx
}

/ latest option last price for strike/right
getLastPrice:{[strike; right]
    res: select last last from option_chain where strike=strike, right=right, time>.z.p - 00:05:00;
    : $[count res; last res; 0N]
}

/ leg id generator
.nextLegId:{
    if[not `.legCounter in key .; .legCounter:0N];
    .legCounter+:1;
    : .legCounter
}

insertLeg:{[strat; sym; strike; right; qty; entryPrice]
    lid:.nextLegId[];
    upsert[`pnl] (`time`strategy`leg_id`symbol_inst`strike`right`qty`entry_price`mtm`pnl`total_pnl)!(.z.p; strat; lid; sym; strike; right; qty; entryPrice; 0.0; 0.0; 0.0);
    0N!"Strategy: inserted leg ", string lid, " for ", string strat;
}

/ Enter long straddle
enterStraddle:{[sym]
    spot:getSpot[sym];
    if[spot~0N; 0N!"Strategy: cannot obtain spot"; :0N];
    atm:getATM[spot];
    if[atm~0N; 0N!"Strategy: no ATM strikes"; :0N];
    callPrice: getLastPrice[atm; `C];
    putPrice: getLastPrice[atm; `P];
    if[callPrice~0N or putPrice~0N; 0N!"Strategy: invalid leg prices"; :0N];
    insertLeg[`straddle; sym; atm; `C; 1; callPrice];
    insertLeg[`straddle; sym; atm; `P; 1; putPrice];
    upsert[`strategy_state] (`strategy`active`start_time`end_time`metadata)!(`straddle;1b;.z.p;.z.p + 00:05:00; `entered);
    0N!"Strategy: straddle entered ATM:", string atm;
}

/ Update PnL
updatePnL:{[]
    if[count pnl=0; :0N];
    latest: select last last by strike, right from option_chain where time>.z.p - 00:05:00;
    { 
        lid:x`leg_id;
        s:x`strike;
        r:x`right;
        qty:x`qty;
        entry:x`entry_price;
        curRow: select last from latest where strike=s, right=r;
        curPrice: $[count curRow; last curRow; 0N];
        mtm: $[curPrice~0N; 0N; (curPrice - entry) * qty];
        update mtm: mtm, pnl: mtm from `pnl where leg_id=lid;
    } each select from pnl;
    update total_pnl: sum pnl by strategy from `pnl;
}

/ End windows
endExpiredStrategies:{[]
    expired: select from strategy_state where active=1b, end_time < .z.p;
    if[count expired>0;
        { update active:0b from `strategy_state where strategy=x } each expired`strategy;
        0N!"Strategy: ended ", string count expired, " windows";
    ];
}

/ Remote signal handler: called by Signal engine
.u.signal:{[strategyName; reason; params; sentTime]
    activeRows: select from strategy_state where strategy=strategyName, active=1b;
    if[count activeRows>0; 0N!"Strategy: already active - ignoring"; :0N];

    if[strategyName=`straddle;
        enterStraddle[`BANKNIFTY];
    ];
    0N!"Strategy: processed signal for ", string strategyName;
}

/ timer
.z.ts:{
    updatePnL[];
    endExpiredStrategies[];
}
\t 1000
