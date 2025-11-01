import time
from utils.logger import get_logger
log = get_logger("execution")

log.info("Execution engine active. Waiting for trade signals...")
while True:
    # simulate order execution
    log.info("Checking signal queue...")
    time.sleep(2)
