FROM python:3.11-slim

WORKDIR /app
# Copy the local utils package into the container
COPY utils/ /app/utils                                                                                                                                                                                                                                                                                       

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc g++ libffi-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

COPY collector/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app

ENV KDB_HOST=rdb
ENV KDB_PORT=5010
ENV IB_GATEWAY_HOST=host.docker.internal
ENV IB_GATEWAY_PORT=7497

# Run both modules if needed via multiprocessing or supervisor
CMD ["python", "-m", "multiprocessing", "execution_engine.py"]
