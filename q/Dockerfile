#FROM debian:bullseye-slim

#WORKDIR /q

## Copy q binary and license
#COPY q /usr/local/bin/q
#COPY kc.lic /root/

# Copy scripts
#COPY . /q

#RUN chmod +x /usr/local/bin/q

##EXPOSE 5001 5010 5011
#ENTRYPOINT ["/usr/local/bin/q"]
# Base image
FROM ubuntu:22.04

# Set environment variables
ENV QHOME=/root/q
ENV PATH=$QHOME/l64:$PATH

# Install dependencies
RUN apt-get update && apt-get install -y \
    libstdc++6 \
    libtinfo5 \
    && rm -rf /var/lib/apt/lists/*

# Copy your full q folder including binaries
COPY l64 /root/q/l64

# Copy your q scripts
COPY tick.q /root/q/tick.q
COPY r.q /root/q/r.q
COPY testfeed.q /root/q/testfeed.q

# Copy license file
COPY kc.lic /root/q/kc.lic

# Set working directory
WORKDIR /root/q

# Default command (you can override in docker-compose)
CMD ["q"]
