FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update && apt-get install -y \
    wget \
    libssl-dev \
    file \
    && rm -rf /var/lib/apt/lists/*

# Copy 64-bit files
RUN mkdir -p /opt/kdb
COPY ./common/q /opt/kdb/q
RUN chmod +x /opt/kdb/q

COPY common /opt/kdb/common

COPY ./common/q /opt/kdb/q

COPY ./common/kc.lic /opt/kdb/kc.lic

COPY ./common/q.k /opt/kdb/q.k

COPY ./common/tick.q /opt/kdb/tick.q

COPY ./common/schema.q /opt/kdb/schema.q

RUN chmod +x /opt/kdb/q

WORKDIR /opt/kdb

ENV QHOME=/opt/kdb

ENV LD_LIBRARY_PATH=/opt/kdb

EXPOSE 5000

CMD ["/opt/kdb/q", "/opt/kdb/tick.q", "-p", "5000"]
