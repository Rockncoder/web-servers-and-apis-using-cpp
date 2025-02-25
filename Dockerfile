# ---- BUILD STAGE ----
FROM debian:buster-slim AS builder

# Install necessary build tools and dependencies
RUN apt-get -qq update && \
    apt-get -qq install -y --no-install-recommends \
    ca-certificates \
    cmake \
    make \
    build-essential \
    libboost-dev \
    libboost-system-dev \
    libboost-filesystem-dev \
    libasio-dev \
    libssl-dev \
    libsasl2-dev \
    pkg-config \
    git \
    wget \
    python3 \
    python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN update-ca-certificates

# Set environment variables for installation paths
ENV INSTALL_PREFIX=/usr/local
ENV C_DRIVER_VERSION=1.17.2
ENV CXX_DRIVER_VERSION=r3.6.6

# Install MongoDB C Driver (libmongoc)
RUN cd /tmp && \
    wget https://github.com/mongodb/mongo-c-driver/releases/download/${C_DRIVER_VERSION}/mongo-c-driver-${C_DRIVER_VERSION}.tar.gz && \
    tar xzf mongo-c-driver-${C_DRIVER_VERSION}.tar.gz && \
    cd mongo-c-driver-${C_DRIVER_VERSION} && \
    mkdir cmake-build && \
    cd cmake-build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} .. && \
    make -j"$(nproc)" && \
    make install

# Install MongoDB C++ Driver (mongocxx)
RUN cd /tmp && \
    git clone https://github.com/mongodb/mongo-cxx-driver.git --branch ${CXX_DRIVER_VERSION} --depth 1 && \
    cd mongo-cxx-driver/build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} -DCMAKE_PREFIX_PATH=${INSTALL_PREFIX} .. && \
    make -j"$(nproc)" && \
    make install

# Create application directory
RUN mkdir -p /app/hello_crow

# Copy the application source code
COPY hello_crow /app/hello_crow

# Build the application
WORKDIR /app/hello_crow/build
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=${INSTALL_PREFIX} .. && \
    make -j"$(nproc)"

# ---- RUNTIME STAGE ----
FROM debian:buster-slim AS runtime

# Install necessary runtime dependencies
RUN apt-get -qq update && \
    apt-get -qq install -y --no-install-recommends \
    libboost-system1.67.0 \
    libboost-filesystem1.67.0 \
    libssl1.1 \
    libsasl2-2 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the built application from the builder stage
COPY --from=builder /app/hello_crow/build/hello_crow /usr/local/bin/hello_crow

# Copy necessary runtime libraries from the builder stage
COPY --from=builder /usr/local/lib/libmongocxx.so.* /usr/local/lib/
COPY --from=builder /usr/local/lib/libbsoncxx.so.* /usr/local/lib/
COPY --from=builder /usr/local/lib/libmongoc-1.0.so.* /usr/local/lib/
COPY --from=builder /usr/local/lib/libbson-1.0.so.* /usr/local/lib/

# Update the dynamic linker run-time bindings
RUN ldconfig

# Expose the application port
EXPOSE 8080

# Command to run the application
CMD ["/usr/local/bin/hello_crow"]
