\l schema.q
system "p 5001"

// --- Helper: Get ATM Strike ---
getATM:{[spot]
    strikes:asc exec distinct strike from nifty_opts where time>.z.p-00:01:00, exp=min exp;
    strikes nearest spot
 }

// --- Strategy 1: Straddle ---
straddle:{[]
    if[not `straddle in exec strategy from strategy_state; 
        spot:exec last from nifty_opts where right=`C, strike=getATM[exec last from nifty_opts where right=`C];
        atm:getATM spot;
        call:exec ask from nifty_opts where strike=atm, right=`C, exp=min exp;
        put:exec ask from nifty_opts where strike=atm, right=`P, exp=min exp;
        if[call>0; put>0;
            upsert[`pnl] (`time`strategy`position`qty`entry_price`mtm`pnl`total_pnl)!(.z.p;`straddle;`C;1;call;call;0.0;0.0);
            upsert[`pnl] (`time`strategy`position`qty`entry_price`mtm`pnl`total_pnl)!(.z.p;`straddle;`P;1;put;put;0.0;0.0);
            upsert[`strategy_state] (`strategy`active`entry_time`legs)!(`straddle;1b;.z.p;(`C`P));
        ]
    ]
 }

// --- Strategy 2: Iron Condor ---
ironCondor:{[]
    if[not `ironcondor in exec strategy from strategy_state;
        spot:exec last from nifty_opts where right=`C;
        atm:getATM spot;
        strikes:asc exec distinct strike from nifty_opts where exp=min exp;
        sell_call:strikes binary search atm+200;
        buy_call:strikes binary search atm+400;
        sell_put:strikes binary search atm-200;
        buy_put:strikes binary search atm-400;
        
        sc:exec ask from nifty_opts where strike=sell_call, right=`C;
        bc:exec bid from nifty_opts where strike=buy_call, right=`C;
        sp:exec ask from nifty_opts where strike=sell_put, right=`P;
        bp:exec bid from nifty_opts where strike=buy_put, right=`P;
        
        if[all(sc>0;bc>0;sp>0;bp>0);
            credit:sc+sp-bc-bp;
            upsert[`pnl] (`time`strategy`position`qty`entry_price`mtm`pnl`total_pnl)!(.z.p;`ironcondor;`C;-1;sc;sc;credit;credit);
            upsert[`pnl] (`time`strategy`position`qty`entry_price`mtm`pnl`total_pnl)!(.z.p;`ironcondor;`C;1;bc;bc;-bc;-bc);
            upsert[`pnl] (`time`strategy`position`qty`entry_price`mtm`pnl`total_pnl)!(.z.p;`ironcondor;`P;-1;sp;sp;credit;credit);
            upsert[`pnl] (`time`strategy`position`qty`entry_price`mtm`pnl`total_pnl)!(.z.p;`ironcondor;`P;1;bp;bp;-bp;-bp);
            upsert[`strategy_state] (`strategy`active`entry_time`legs)!(`ironcondor;1b;.z.p;(`C`C`P`P));
        ]
    ]
 }

// --- Update PnL on every tick ---
.z.ts:{
    // Update MTM
    update mtm:last, pnl:(last-entry_price)*qty 
      from `pnl 
      where time>.z.p-00:01:00, 
            position in (exec right from nifty_opts where time>.z.p-00:01:00),
            strike in (exec strike from nifty_opts where time>.z.p-00:01:00);
    
    // Total PnL per strategy
    update total_pnl:sum pnl by strategy from `pnl;
    
    // Run strategies at 09:30
    if[.z.t within 09:30 09:31; straddle[]; ironCondor[]];
    
    // Exit at 15:00
    if[.z.t>15:00:00; 
        delete from `pnl where time<.z.p-00:05:00;
        delete from `strategy_state;
    ]
 }

\t 1000  // Run every second