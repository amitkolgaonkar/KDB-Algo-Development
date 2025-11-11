from ib_insync import *
import pyq
import time
from datetime import datetime
from config import *

util.startLoop()
ib = IB()

def connect_ib():
    while True:
        try:
            ib.connect(IB_HOST, IB_PORT, clientId=CLIENT_ID)
            print("Connected to IB Gateway")
            break
        except Exception as e:
            print(f"IB connect failed: {e}. Retrying...")
            time.sleep(5)

def connect_kdb():
    while True:
        try:
            q = pyq.q(f"{KDB_HOST}:{KDB_PORT}")
            q('show `kdb_connected')
            print("Connected to KDB+")
            return q
        except Exception as e:
            print(f"KDB connect failed: {e}. Retrying...")
            time.sleep(5)

# Connect
connect_ib()
q = connect_kdb()

# Define Nifty
nifty = Index('NIFTY', 'NSE', 'INR')
ib.qualifyContracts(nifty)

# Get option chain
chains = ib.reqSecDefOptParams(nifty.symbol, '', nifty.secType, nifty.conId)
chain = next(c for c in chains if c.exchange == 'NSE')

# Filter: next 2 expirations, strikes ±300
[ticker] = ib.reqTickers(nifty)
spot = ticker.marketPrice() or 22000
strikes = [s for s in chain.strikes if abs(s - spot) <= 300 and s % 50 == 0]
expirations = sorted(chain.expirations)[:2]

# Build contracts
contracts = [
    Option('NIFTY', exp, strike, right, 'NSE', tradingClass='NIFTY', multiplier='50')
    for right in ['C', 'P']
    for exp in expirations
    for strike in strikes
]
contracts = ib.qualifyContracts(*contracts)

print(f"Streaming {len(contracts)} Nifty option contracts...")

# Stream tickers
tickers = ib.reqTickers(*contracts)

while True:
    try:
        data = []
        for t in tickers:
            if t.bid is not None and t.bid > 0:
                exp_date = datetime.strptime(t.contract.lastTradeDateOrContractMonth, '%Y%m%d').date()
                row = {
                    'time': datetime.now(),
                    'exp': exp_date,
                    'strike': float(t.contract.strike),
                    'right': t.contract.right,
                    'bid': float(t.bid),
                    'ask': float(t.ask),
                    'last': float(t.last) if t.last else 0.0,
                    'vol': int(t.volume) if t.volume else 0,
                    'size': int(t.lastSize) if t.lastSize else 0
                }
                data.append(row)

        if data:
            q('upsert', '`nifty_opts', data)
            print(f"Upserted {len(data)} rows at {datetime.now().strftime('%H:%M:%S')}")

        ib.sleep(10)  # Every 10 seconds
    except Exception as e:
        print(f"Error: {e}")
        time.sleep(5)