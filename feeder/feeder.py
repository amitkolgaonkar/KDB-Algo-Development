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
        self.req_map = {}  # reqId → info
        self.current_underlying_price = None  # Updated from tickPrice

        self.chain_req_id = None
        self.expirations = []
        self.strikes = []

        self.atm_range = 300  # ±300 points from ATM

    # ---------------------------------------------------------
    #  KDB CONNECTION
    # ---------------------------------------------------------
    def connect_to_kdb(self):
        try:
            self.kdb_conn = kx.QConnection(host=self.kdb_host, port=self.kdb_port)
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

            thread = threading.Thread(target=self.run, daemon=True)
            thread.start()

            time.sleep(2)
            if self.isConnected():
                print("Connected to IBKR")
            return True
        except Exception as e:
            print("Error connecting to TWS:", e)
            return False

    # ---------------------------------------------------------
    #  MARKET DATA SUBSCRIPTIONS
    # ---------------------------------------------------------
    def make_nifty_underlying(self):
        c = Contract()
        c.symbol = "NIFTY"
        c.secType = "IND"
        c.exchange = "NSE"
        c.currency = "INR"
        return c

    def make_nifty_option(self, expiry, strike, right):
        c = Contract()
        c.symbol = "NIFTY"
        c.secType = "OPT"
        c.exchange = "NSE"
        c.currency = "INR"
        c.lastTradeDateOrContractMonth = expiry  # YYYYMMDD
        c.strike = strike
        c.right = right  # "C" or "P"
        c.multiplier = "50"
        c.tradingClass = "NIFTY"
        c.conId = "819060722"
        return c

    def subscribe_underlying(self):
        c = self.make_nifty_underlying()
        print(f"Requesting NIFTY underlying spot (reqId={self.req_id})")
        self.reqMktData(self.req_id, c, "", False, False, [])
        self.req_map[self.req_id] = {"type": "underlying"}
        self.req_id += 1

    def subscribe_option_chain(self):
        print(f"Requesting NIFTY option chain params (reqId={self.req_id})")
        # Hardcoded to avoid TypeError
        self.reqSecDefOptParams(self.req_id,"NIFTY","","IND","0")
        self.req_map[self.req_id] = {"type": "chain"}
        self.chain_req_id = self.req_id
        self.req_id += 1

    def subscribe_near_atm_options(self):
        if not self.expirations or not self.strikes or self.current_underlying_price is None:
            print("Waiting for chain params and underlying price...")
            return

        expiry = self.expirations[0]  # First (current) expiry
        strikes = sorted(self.strikes)

        atm = min(strikes, key=lambda s: abs(s - self.current_underlying_price))
        lower = atm - self.atm_range
        upper = atm + self.atm_range

        near_strikes = [s for s in strikes if lower <= s <= upper]
        print(f"ATM: {atm}, Subscribing to {len(near_strikes)} strikes near ATM (±{self.atm_range}) for expiry {expiry}")

        for strike in near_strikes:
            for right in ["C", "P"]:
                contract = self.make_nifty_option(expiry, strike, right)
                print(f"Subscribing {right} {strike} (reqId={self.req_id})")
                self.reqMktData(self.req_id, contract, "106", False, False, [])  # Greeks
                self.req_map[self.req_id] = {
                    "type": "option",
                    "strike": strike,
                    "right": right,
                    "expiry": expiry
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
            self.current_underlying_price = float(price)
            data = {
                "symbol": "NIFTY",
                "last_price": self.current_underlying_price,
                "time": datetime.now()
            }
            self.send_to_kdb("underlying", data)
            print(f"Underlying price: {self.current_underlying_price}")

            # Trigger near-ATM subscription once we have price
            self.subscribe_near_atm_options()

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
            'expiry': datetime.strptime(info["expiry"], '%Y%m%d').date(),
            'strike': info["strike"],
            'option_type': info["right"],
            'bid': 0.0,  # Fill from tickPrice if needed
            'ask': 0.0,
            'last_price': float(optPrice or 0),
            'volume': 0,
            'open_interest': 0,
            'implied_vol': float(impliedVol or 0),
            'time': datetime.now()
        }

        self.send_to_kdb("nifty_opts", option_data)
        print("Option tick:", option_data)

    def securityDefinitionOptionParameter(self, reqId, exchange, underlyingConId, tradingClass, multiplier, expirations, strikes):
        if reqId != self.chain_req_id:
            return

        self.expirations = expirations
        self.strikes = strikes
        print(f"Received chain: {len(expirations)} expiries, {len(strikes)} strikes")
        print(f"First expiry: {expirations[0]}, Strikes sample: {strikes[:5]}...")

        # Trigger subscription once we have chain and price
        self.subscribe_near_atm_options()

    # ---------------------------------------------------------
    #  MAIN LOOP
    # ---------------------------------------------------------
    def run_feeder(self):
        if not self.connect_to_tws():
            return

        if not self.connect_to_kdb():
            return

        # Start with underlying and chain request
        self.reqMarketDataType(3)
        self.subscribe_underlying()
        self.subscribe_option_chain()

        print("Feeder running... waiting for ticks and chain")

        while True:
            time.sleep(1)

def main():
    feeder = IBKRFeeder()
    feeder.run_feeder()

if __name__ == "__main__":
    main()