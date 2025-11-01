import pykx as kx
import pandas as pd

def kdb_send(cfg, table, record):
    q = kx.q
    data = {k: [v] for k, v in record.items()}
    q(".u.upd", table, kx.Table(data))

def kdb_query(cfg, query):
    q = kx.q
    df = q(query).pd()
    return df
