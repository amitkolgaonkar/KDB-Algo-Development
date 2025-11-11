FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update && apt-get install -y \
    wget \
    && rm -rf /var/lib/apt/lists/*

COPY q.k /opt/kdb/q

COPY kc.lic /opt/kdb/kc.lic

COPY tick.q /opt/kdb/tick.q

COPY schema.q /opt/kdb/schema.q

RUN chmod +x /opt/kdb/q

WORKDIR /opt/kdb

ENV QHOME=/opt/kdb

EXPOSE 5000

CMD ["/opt/kdb/q", "/opt/kdb/tick.q", "-p", "5000"]