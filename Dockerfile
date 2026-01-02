FROM ghcr.io/rise-maritime/porla:v0.5.0

# Add custom binaries to the bin folder in the repository as required
COPY --chmod=555 ./bin/* /usr/local/bin/
