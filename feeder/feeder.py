from ibapi.client import EClient
from ibapi.wrapper import EWrapper
from ibapi.contract import Contract
from ibapi.common import *
from ibapi.ticktype import TickType



import threading
import time
import traceback
from datetime import datetime
import pykx as kx


class IBKRFeeder(EWrapper, EClient):
    def __init__(self):
        EWrapper.__init__(self)
        EClient.__init__(self, wrapper=self)

        self.kdb_host = 'tick'
        self.kdb_port = 5000
        self.kdb_conn = None

        self.req_id = 1
        self.req_map = {}      # reqId → {"strike":..., "right":...}
    #def contractDetails(self, req_id, contractDetails)
    #    print("reqID: {}, contract:{}".format(req_id,contractDetails))
    # ---------------------------------------------------------
    #  KDB CONNECTION
    # ---------------------------------------------------------
    def connect_to_kdb(self):
        try:
            self.kdb_conn = kx.QConnection(
                host=self.kdb_host,
                port=self.kdb_port
            )
            print("Connected to KDB+ ticker plant")
            return True
        except Exception as e:
            print("Failed to connect to KDB:", e)
            return False

    def send_to_kdb(self, tbl, data):
        try:
            payload = {"table": tbl, "data": data}
            self.kdb_conn("handleData", payload)
        except Exception as e:
            print("Error sending to KDB:", e)
            traceback.print_exc()

    # ---------------------------------------------------------
    #  CONNECTION TO IB
    # ---------------------------------------------------------
    def connect_to_tws(self):
        try:
            self.connect("host.docker.internal", 4001, clientId=20)
            print("Connecting to IBKR...")

            # Start ibapi loop in thread
            thread = threading.Thread(target=self.run, daemon=True)
            thread.start()

            time.sleep(1)
            if self.isConnected():
                print("Connected to IBKR")
            return True

        except Exception as e:
            print("Error connecting to TWS:", e)
            return False

    # ---------------------------------------------------------
    #  MARKET DATA SUBSCRIPTIONS
    # ---------------------------------------------------------
    def make_option(self, sym, expiry, strike, right, exch="NSE", cur="INR"):
        c = Contract()
        c.symbol = "NIFTY50"
        c.secType = "IND"                     # ✅ MUST be OPT
        c.exchange = exch
        c.currency = cur
        c.lastTradeDateOrContractMonth = "20251223"  # YYYYMMDD
        c.strike = float(25950)
        c.right = "C"                       # "C" or "P"
        c.multiplier = "75"
        c.tradingClass = "NIFTY"                   # NIFTY lot size
        c.conId = 0
        return c
    
    def subscribe_underlying(self):
        c = Contract()
        c.symbol = "NIFTY50"
        c.secType = "IND"      # Index
        c.exchange = "NSE"
        c.currency = "INR"
        

        print(f"Requesting NIFTY spot (reqId={self.req_id})")
        self.reqMktData(self.req_id, c, "", False, False, [])

        self.req_map[self.req_id] = {"type": "spot"}
        self.spot_req_id = self.req_id
        self.req_id += 1


    def subscribe_option(self, strike, right):
        contract = self.make_option(
            sym="NIFTY",
            expiry="20251223",   # YYYYMMDD (weekly expiry)
            strike=float(25950),
            right="Call",
            exch="NSE"
        )

        print(f"Requesting option Greeks for {right}{strike} (reqId={self.req_id})")

        # (Optional but highly recommended)
        self.reqContractDetails(self.req_id, contract)
        time.sleep(0.5)

        self.reqMktData(self.req_id, contract, "106", False, False, [])
        self.req_map[self.req_id] = {
            "type": "option",
            "strike": strike,
            "right": right
        }
        self.req_id += 1



    
    # ---------------------------------------------------------
    #  CALLBACKS FROM IB API
    # ---------------------------------------------------------
    def tickPrice(self, reqId, tickType, price, attrib):
        if reqId not in self.req_map:
            return

        info = self.req_map[reqId]

        if info["type"] == "underlying" and tickType == TickType.LAST:
            data = {
                "symbol": "NIFTY",
                "last_price": float(price),
                "time": datetime.now()
            }
            self.send_to_kdb("underlying", data)
            print("Underlying:", data)

    def tickOptionComputation(
        self, reqId, tickType, impliedVol, delta, optPrice,
        pvDividend, gamma, vega, theta, undPrice
    ):
        if reqId not in self.req_map:
            return

        info = self.req_map[reqId]

        if info["type"] != "option":
            return

        option_data = {
            'symbol': 'NIFTY',
            'expiry': datetime(2025, 1, 24).date(),
            'strike': info["strike"],
            'option_type': info["right"],
            'bid': 0.0,
            'ask': 0.0,
            'last_price': optPrice if optPrice else 0.0,
            'volume': 0.0,
            'open_interest': 0,
            'implied_vol': float(impliedVol or 0),
            'delta': float(delta or 0),
            'gamma': float(gamma or 0),
            'theta': float(theta or 0),
            'vega': float(vega or 0),
            'time': datetime.now()
        }

        self.send_to_kdb("option_chain", option_data)
        print("Option:", option_data)

    # ---------------------------------------------------------
    #  MAIN LOOP
    # ---------------------------------------------------------
    def run_feeder(self):
        if not self.connect_to_tws():
            return

        if not self.connect_to_kdb():
            return

        self.subscribe_underlying()

        # Subscribe to example 2 options
        self.subscribe_option(25000, "C")
        self.subscribe_option(25000, "P")

        print("Feeder running... waiting for ticks")

        while True:
            time.sleep(1)


def main():
    feeder = IBKRFeeder()
    feeder.run_feeder()


if __name__ == "__main__":
    main()
