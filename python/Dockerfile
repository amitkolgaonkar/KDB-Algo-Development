FROM python:3.10-slim

WORKDIR /app
# Copy the local utils package into the container
COPY utils/ /app/utils
COPY . /app

RUN pip install --no-cache-dir -r requirements.txt || true

EXPOSE 4001

#ENTRYPOINT ["python"]
CMD ["collector.py"]