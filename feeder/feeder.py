from ibapi.client import EClient
from ibapi.wrapper import EWrapper
from ibapi.contract import Contract

import pykx as kx
import threading
import time

# KDB connection inside Docker
kdb = kx.QConnection(host="tick", port=5000)   # tick plant port
kdb.open()

class IBKRWrapper(EWrapper):

    def tickPrice(self, reqId, tickType, price, attrib):
        ts = kx.TimeStamp.now()
        data = kx.q('([] symbol: `NIFTY50; last: {}; time: {})'.format(price, ts))
        kdb('.u.upd', 'underlying', data)

    def tickSize(self, reqId, tickType, size):
        pass

    def tickOptionComputation(self, reqId, tickType, impliedVol, delta, optPrice,
                              pvDividend, gamma, vega, theta, undPrice):
        ts = kx.TimeStamp.now()
        data = kx.q('([] symbol:`NIFTY50; implied_vol:{}; time:{})'
                    .format(impliedVol, ts))
        kdb('.u.upd', 'nifty_opts', data)

class IBKRApp(EClient, IBKRWrapper):
    def __init__(self):
        EClient.__init__(self, self)

def start_ibkr():
    app = IBKRApp()

    print("Connecting to IBKR...")
    app.connect("host.docker.internal", 4001, clientId=101)

    # Run the IBKR event loop in a background thread
    thread = threading.Thread(target=app.run, daemon=True)
    thread.start()

    # Subscribe to NIFTY underlying
    contract = Contract()
    contract.symbol = "NIFTY50"
    contract.secType = "IND"
    contract.exchange = "NSE"
    contract.currency = "INR"

    app.reqMarketDataType(1)
    app.reqMktData(1, contract, "", False, False, [])

    while True:
        time.sleep(1)

if __name__ == "__main__":
    start_ibkr()
