FROM ubuntu:22.04

ENV QHOME=/root/q
ENV PATH=$QHOME/l64:$PATH

RUN apt-get update && apt-get install -y \
    libstdc++6 \
    libtinfo5 \
    && rm -rf /var/lib/apt/lists/*

# Copy core q files (essential)
COPY q.k ${QHOME}/q.k

# Copy optional files only if they exist on host
RUN \
    if [ -f q.q ]; then cp q.q ${QHOME}/q.q && echo "Copied q.q"; else echo "q.q optional - skipping"; fi && \
    if [ -f sl.q ]; then cp sl.q ${QHOME}/sl.q && echo "Copied sl.q"; else echo "sl.q optional - skipping"; fi

# Copy binaries
COPY l64 ${QHOME}/l64

# Copy all scripts
COPY *.q ${QHOME}/

# Copy license if exists
RUN if [ -f kc.lic ]; then cp kc.lic ${QHOME}/kc.lic && echo "Copied kc.lic"; else echo "kc.lic missing - running in trial mode"; fi

WORKDIR ${QHOME}

# Debug: Verify key files during build
RUN echo "=== Verifying q files ===" && \
    ls -la q.k l64/q *.q && \
    [ -f kc.lic ] && echo "kc.lic present" || echo "Running in trial mode"

# Create dirs
RUN mkdir -p /hdb /tmp

EXPOSE 5010 5011

CMD ["/root/q/l64/q"]