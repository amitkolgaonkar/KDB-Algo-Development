import os
from dotenv import load_dotenv

load_dotenv()

IB_HOST = os.getenv("IB_HOST", "localhost")
IB_PORT = int(os.getenv("IB_PORT", 4001)
KDB_HOST = os.getenv("KDB_HOST", "localhost")
KDB_PORT = int(os.getenv("KDB_PORT", 5000))
CLIENT_ID = int(os.getenv("CLIENT_ID", 10))