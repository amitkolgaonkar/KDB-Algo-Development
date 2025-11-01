from ib_insync import *
import yaml, time, sys, os
from utils.kdb_connector import kdb_send
from utils.logger import get_logger

log = get_logger("collector")

cfg = yaml.safe_load(open("config.yaml"))
ib_cfg, kdb_cfg = cfg["ibkr"], cfg["kdb"]

ib = IB()

def connect_ibkr():
    try:
        ib.connect(ib_cfg["host"], ib_cfg["port"], clientId=ib_cfg["client_id"])
        log.info("Connected to IBKR")
        return True
    except:
        log.error("IBKR connection failed")
        return False

while not connect_ibkr():
    time.sleep(ib_cfg["reconnect_interval"])

contract = Index(ib_cfg["symbol"], ib_cfg["exchange"], ib_cfg["currency"])
ib.qualifyContracts(contract)

while True:
    try:
        ticker = ib.reqMktData(contract, "", False, False)
        time.sleep(1)
        tick = {
            "time": time.time(),
            "symbol": ib_cfg["symbol"],
            "bid": ticker.bid,
            "ask": ticker.ask,
            "last": ticker.last,
            "volume": ticker.volume
        }
        kdb_send(kdb_cfg, "option_chain", tick)
    except Exception as e:
        log.error(f"Error streaming: {e}")
        os.system("python fallback_manager.py")
        break
