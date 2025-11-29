/ =========================================================
/ schema.q  — Clean corrected schema for your project
/ =========================================================

/ -------------------- option_chain -----------------------
option_chain: ([
    symbol:        `symbol$();
    expiry:        `date$();
    strike:        `float$();
    option_type:   `symbol$();
    bid:           `float$();
    ask:           `float$();
    last_price:    `float$();
    volume:        `long$();
    open_interest: `long$();
    implied_vol:   `float$();
    time:          `timestamp$()]);

/ ---------------------- nifty_opts ------------------------
nifty_opts: ([
    time:         `timestamp$();
    expiry:       `date$();
    strike:       `float$();
    right:        `symbol$();     / CE / PE
    bid:          `float$();
    ask:          `float$();
    last_price:   `float$();
    vol:          `long$();
    size:         `long$();
    implied_vol:  `float$()]);

/ ------------------------ pnl table -----------------------
pnl: ([
    time:        `timestamp$();
    strategy:    `symbol$();
    position:    `symbol$();     / LONG or SHORT
    qty:         `int$();
    entry_price: `float$();
    mtm:         `float$();      / Mark to market
    pnl:         `float$();
    total_pnl:   `float$()]);

/ --------------------- strategy_state ---------------------
strategy_state: ([
    strategy:   `symbol$();
    active:     `boolean$();
    entry_time: `timestamp$();
    legs:       ();              / list of legs (generic)
    params:     `symbol$()]);

/ ----------------------- underlying -----------------------
underlying: ([
    symbol:      `symbol$();
    last_price:  `float$();
    time:        `timestamp$()]);

/ ------------------------- signals ------------------------
signals: ([
    time:      `timestamp$();
    strategy:  `symbol$();
    reason:    `symbol$();       / higherhigh, vixcross etc.
    params:    `symbol$()]);

show "schema loaded successfully";
