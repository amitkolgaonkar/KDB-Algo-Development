/ schema.q
option_chain:([] symbol:`symbol$(); expiry:`date$(); strike:`float$(); right:`symbol$(); bid:`float$(); ask:`float$(); last:`float$(); volume:`long$(); open_interest:`long$(); implied_vol:`float$(); time:`timestamp$())

nifty_opts:([] symbol:`symbol$(); expiry:`date$(); strike:`float$(); right:`symbol$(); bid:`float$(); ask:`float$(); last:`float$(); volume:`long$(); open_interest:`long$(); implied_vol:`float$(); time:`timestamp$())

pnl: ([] time:`timestamp$(); strategy:`symbol$(); leg_id:`int$(); symbol_inst:`symbol$(); strike:`float$(); right:`symbol$(); qty:`int$(); entry_price:`float$(); mtm:`float$(); pnl:`float$(); total_pnl:`float$())

strategy_state:([] strategy:`symbol$(); active:`boolean$(); start_time:`timestamp$(); end_time:`timestamp$(); metadata:`symbol$())

signals:([] time:`timestamp$(); strategy:`symbol$(); reason:`symbol$(); params:())
