from utils.logger import get_logger
import time
log = get_logger("monitor")

while True:
    log.info("System OK | Monitoring services...")
    time.sleep(10)
