# ---- BUILD STAGE ----
    FROM debian:buster-slim AS builder

    RUN apt-get -qq update && \
        apt-get -qq install -y --no-install-recommends \
        cmake \
        ninja-build \
        make \
        build-essential \
        python3 \
        g++ \
        wget \
        curl \
        ca-certificates \
        libboost-dev \
        libboost-system-dev \
        libboost-filesystem-dev && \
        apt-get clean && rm -rf /var/lib/apt/lists/*

    # Download Crow
    WORKDIR /tmp
    RUN wget "https://github.com/ipkn/crow/releases/download/v0.1/crow_all.h"

    #Download .gitignore
    RUN wget "https://raw.githubusercontent.com/github/gitignore/main/C++.gitignore" -O cpp.gitignore


    # Make a directory for it all
    RUN mkdir -p /app/hello_crow

    # Move the gitignore
    RUN mv cpp.gitignore /app/hello_crow/.dockerignore

    # Add the hidden . to make it an ignore
    RUN mv /app/hello_crow/.dockerignore  /app/hello_crow/.gitignore

    # Copy the application source code (overridden by volume during development)
    COPY hello_crow /app/hello_crow

    # Move Crow header to the correct location
    RUN mv crow_all.h /app/hello_crow/crow_all.h

    # Build the application
    WORKDIR /app/hello_crow/build
    RUN cmake /app/hello_crow
    RUN make

    # ---- RUNTIME STAGE ----
    FROM debian:buster-slim AS runtime

    # Copy the built executable from the builder stage
    COPY --from=builder /app/hello_crow/build/hello_crow /usr/local/bin/hello_crow

    # Expose the port
    EXPOSE 8080

    # Command to run when the container starts
    CMD ["/usr/local/bin/hello_crow"]

