#!/usr/bin/env python3
"""
feeder.py

Modes:
 - mock: generates synthetic BANKNIFTY option chain + underlying and pushes to TP.
 - ibkr: connects to TWS (host.docker.internal:4001), subscribes, pushes to TP.

Ensure q (TP) is reachable at KDB_HOST:KDB_PORT (tick container).
"""

import os, time, sys
import pandas as pd
from datetime import datetime, timedelta
from qpython import qconnection

FEED_MODE = os.getenv("FEED_MODE", "mock").lower()
IB_HOST = os.getenv("IB_HOST", "host.docker.internal")
IB_PORT = int(os.getenv("IB_PORT", "4001"))
IB_CLIENT_ID = int(os.getenv("IB_CLIENT_ID", "10"))
KDB_HOST = os.getenv("KDB_HOST", "tick")
KDB_PORT = int(os.getenv("KDB_PORT", "5000"))
PRINT = True

def q_push(table_name, df):
    q = qconnection.QConnection(host=KDB_HOST, port=KDB_PORT, pandas=True, timeout=10.0)
    try:
        q.open()
        # Call .tick.upd on TP (remote)
        q.sync(".tick.upd", table_name, df)
        if PRINT:
            print(f"[{datetime.utcnow().isoformat()}] pushed {len(df)} rows to {table_name}")
    except Exception as e:
        print("q push error:", e, file=sys.stderr)
    finally:
        try:
            q.close()
        except:
            pass

def mock_feed_loop():
    strikes = list(range(48000, 49401, 100))
    while True:
        now = pd.Timestamp.utcnow()
        expiry = (now + pd.Timedelta(days=2)).date().isoformat()
        rows=[]
        for s in strikes:
            # synthetic prices
            base = 200.0 + (s - 48500)/100.0
            last_c = round(abs(base + (0.5 - os.urandom(1)[0]/255.0)*5),2)
            last_p = round(abs(base + (0.5 - os.urandom(1)[0]/255.0)*5),2)
            rows.append({"symbol":"BANKNIFTY","expiry":expiry,"strike":float(s),"option_type":"C","bid":last_c-0.5,"ask":last_c+0.5,"last_price":last_c,"volume":0,"open_interest":0,"implied_vol":12.0,"time":now.to_pydatetime()})
            rows.append({"symbol":"BANKNIFTY","expiry":expiry,"strike":float(s),"option_type":"P","bid":last_p-0.5,"ask":last_p+0.5,"last_price":last_p,"volume":0,"open_interest":0,"implied_vol":12.0,"time":now.to_pydatetime()})
        df=pd.DataFrame(rows)
        q_push("option_chain", df)

        # push underlying spot
        u_last = float(48500.0 + (0.5 - os.urandom(1)[0]/255.0)*20)
        u_df = pd.DataFrame([{"symbol":"BANKNIFTY","last_price":u_last,"time":now.to_pydatetime()}])
        q_push("underlying", u_df)

        time.sleep(1)

def ibkr_feed_loop():
    from ib_insync import IB, Contract
    ib = IB()
    print("Connecting to IB:", IB_HOST, IB_PORT, "clientId", IB_CLIENT_ID)
    ib.connect(IB_HOST, IB_PORT, clientId=IB_CLIENT_ID)
    if not ib.isConnected():
        print("IB connect failed", file=sys.stderr)
        return

    # WARNING: contract fields for Indian exchanges often need tweaks.
    underlying = Contract(symbol='BANKNIFTY', secType='IND', exchange='NSE', currency='INR')
    chains = ib.reqSecDefOptParams(underlying.symbol, '', underlying.secType, 0)
    if not chains:
        print("No option chain info from IB. Check contract/exchange/permissions.", file=sys.stderr)
        ib.disconnect()
        return

    chain = chains[0]
    expirations = sorted(chain.expirations)
    strikes = sorted(chain.strikes)
    if len(expirations) == 0 or len(strikes) == 0:
        print("No expiries/strikes", file=sys.stderr)
        ib.disconnect()
        return

    expiry = expirations[0]
    mid = len(strikes)//2
    slice_strikes = strikes[max(0,mid-6):min(len(strikes),mid+6)]

    # subscribe to underlying market data
    uTicker = ib.reqMktData(underlying, snapshot=False)

    # subscribe to a slice of option contracts
    contracts=[]
    for s in slice_strikes:
        for right in ['C','P']:
            c = Contract(symbol=underlying.symbol, secType='OPT', exchange=chain.exchange,
                         currency='INR', lastTradeDateOrContractMonth=expiry, strike=float(s), right=right, multiplier=chain.multiplier)
            contracts.append(c)

    tickers = [ib.reqMktData(c, snapshot=False) for c in contracts]
    print("Subscribed to", len(tickers), "option contracts")

    try:
        while True:
            now = pd.Timestamp.utcnow()
            rows=[]
            for t in tickers:
                c = t.contract
                last = t.last or 0.0
                bid = t.bid or 0.0
                ask = t.ask or 0.0
                iv = 0.0
                rows.append({"symbol":"BANKNIFTY","expiry":expiry,"strike":float(c.strike),"option_type":c.right,"bid":float(bid),"ask":float(ask),"last_price":float(last),"volume":0,"open_interest":0,"implied_vol":iv,"time":now.to_pydatetime()})
            if rows:
                q_push("option_chain", pd.DataFrame(rows))
            # underlying
            underlying_price = uTicker.last or 0.0
            q_push("underlying", pd.DataFrame([{"symbol":"BANKNIFTY","last":float(underlying_price),"time":now.to_pydatetime()}]))
            time.sleep(1)
    except KeyboardInterrupt:
        ib.disconnect()

if __name__ == "__main__":
    print("FEED_MODE:", FEED_MODE)
    if FEED_MODE == "mock":
        mock_feed_loop()
    else:
        ibkr_feed_loop()
