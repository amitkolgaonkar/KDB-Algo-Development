FROM python:3.12-slim

RUN pip install ibapi pykx

COPY feeder.py /app/feeder.py

CMD ["python", "/app/feeder.py"]
