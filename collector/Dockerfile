FROM python:3.10-bullseye
WORKDIR /app
# Copy the local utils package into the container
COPY utils/ /app/utils
COPY collector/requirements.txt ./requirements.txt
COPY . /app
RUN pip install --default-timeout=100 --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
CMD ["collector_ibkr.py"]
