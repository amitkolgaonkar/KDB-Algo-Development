#!/bin/bash
echo "Starting IBKR + KDB+ + Nifty Feeder..."
docker-compose up -d
echo "Logs: docker logs -f nifty-feeder"