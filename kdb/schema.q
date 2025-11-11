\l

// Option chain
nifty_opts:([] 
    time:`timestamp$(); 
    exp:`date$(); 
    strike:`float$(); 
    right:`symbol$(); 
    bid:`float$(); 
    ask:`float$(); 
    last:`float$(); 
    vol:`long$(); 
    size:`long$()
)

// Strategy PnL
pnl:([] 
    time:`timestamp$(); 
    strategy:`symbol$(); 
    position:`symbol$(); 
    qty:`int$(); 
    entry_price:`float$(); 
    mtm:`float$(); 
    pnl:`float$(); 
    total_pnl:`float$()
)

// Strategy state
strategy_state:([] 
    strategy:`symbol$(); 
    active:`boolean$(); 
    entry_time:`timestamp$(); 
    legs:()
)