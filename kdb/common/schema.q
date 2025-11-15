/ ======================= option_chain ==========================
option_chain:(
    [] symbol:`symbol$();
       expiry:`date$();
       strike:`float$();
       option_type:`symbol$();
       bid:`float$();
       ask:`float$();
       last_price:`float$();
       volume:`long$();
       open_interest:`long$();
       implied_vol:`float$();
       time:`timestamp$()
);

/ ======================= nifty_opts ============================
nifty_opts:([] 
    time:`timestamp$();
    exp:`date$();
    strike:`float$();
    right:`symbol$();
    bid:`float$();
    ask:`float$();
    last_price:`float$();
    vol:`long$();
    size:`long$();
    implied_vol:`float$()  // Added this; ensure it's after other columns
    );

pnl:([] 
    time:`timestamp$();
    strategy:`symbol$();
    position:`symbol$();
    qty:`int$();
    entry_price:`float$();
    mtm:`float$();
    pnl:`float$();
    total_pnl:`float$()
    );

strategy_state:([] 
    strategy:`symbol$();
    active:`boolean$();
    entry_time:`timestamp$();
    legs:()
    );
/ ======================= underlying =============================
underlying:(
    [] symbol:`symbol$();
       last_price:`float$();
       time:`timestamp$()
);

/ ======================= pnl table ===============================
/ ======================= strategy_state ==========================
/ ======================= signals ===============================
signals:(
    [] time:`timestamp$();
       strategy:`symbol$();
       reason:`symbol$();
       params:()
);
