# Build stage for canboat
FROM debian:bullseye AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
    make \
    gcc \
    xsltproc \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Build canboat v4.12.0
WORKDIR /canboat
RUN wget -qO- https://github.com/canboat/canboat/archive/refs/tags/v4.12.0.tar.gz \
    | tar xvz --strip-components=1 \
    && make

# Final image
FROM ghcr.io/rise-maritime/porla:v0.5.0

# Install git for pip dependencies from git repos
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt

# Copy canboat binaries from build stage
COPY --from=build --chmod=555 /canboat/rel/linux-x86_64/analyzer /usr/local/bin/
COPY --from=build --chmod=555 /canboat/rel/linux-x86_64/actisense-serial /usr/local/bin/
COPY --from=build --chmod=555 /canboat/rel/linux-x86_64/candump2analyzer /usr/local/bin/
COPY --from=build --chmod=555 /canboat/rel/linux-x86_64/n2kd /usr/local/bin/
COPY --from=build --chmod=555 /canboat/rel/linux-x86_64/raw2json /usr/local/bin/
COPY --from=build --chmod=555 /canboat/rel/linux-x86_64/n2k-csv-analyzer /usr/local/bin/

# Copy custom scripts
COPY --chmod=555 ./bin/* /usr/local/bin/
