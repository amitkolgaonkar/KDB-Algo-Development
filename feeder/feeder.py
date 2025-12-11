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
    def subscribe_underlying(self):
        contract = Stock(
            symbol="NIFTY",
            exchange="NSE",
            currency="INR"
        )

        print(f"Requesting market data for underlying NIFTY (reqId={self.req_id})")
        self.reqMktData(self.req_id, contract, "", False, False, [])
        self.req_map[self.req_id] = {"type": "underlying"}
        self.req_id += 1

    def subscribe_option(self, strike, right):

        contract = Option(
            symbol="NIFTY",
            lastTradeDateOrContractMonth="20250124",
            strike=strike,
            right=right,
            exchange="NSE",
            currency="INR"
        )

        print(f"Requesting option Greeks for {right}{strike} (reqId={self.req_id})")
        self.reqMktData(self.req_id, contract, "106", False, False, [])
        self.req_map[self.req_id] = {
            "type": "option",
            "strike": strike,
            "right": right
        }
        self.req_id += 1
    def Stock(sym, exch="NSE", cur="INR"):
        c = Contract()
        c.symbol = sym
        c.secType = "STK"
        c.exchange = exch
        c.currency = cur
        return c
    def Option(sym, expiry, strike, right, exch="NSE", cur="INR"):
        c = Contract()
        c.symbol = sym
        c.secType = "OPT"
        c.exchange = exch
        c.currency = cur
        c.lastTradeDateOrContractMonth = expiry
        c.strike = float(strike)
        c.right = right   # "C" or "P"
        return c
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
