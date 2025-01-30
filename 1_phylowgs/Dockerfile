# Use Ubuntu 18.04 as base since it still has good Python 2.7 support
FROM ubuntu:18.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python2.7 \
    python-pip \
    g++ \
    libgsl-dev \
    libgsl23 \
    wget \
    python-dev \
    libblas-dev \
    liblapack-dev \
    gfortran \
    python-numpy \
    python-scipy \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create symbolic link for python2
RUN ln -sf /usr/bin/python2.7 /usr/bin/python2

# Set working directory
WORKDIR /app/1_phylowgs

# Install Python dependencies
RUN pip2 install ete2==2.3.10

# Copy the PhyloWGS source files from your local directory
COPY phylowgs/ ./phylowgs/

# Compile the C++ code in the correct directory
WORKDIR /app/1_phylowgs/phylowgs
RUN g++ -o mh.o -O3 mh.cpp util.cpp `gsl-config --cflags --libs`

# Create necessary directories
RUN mkdir -p data chains tmp

# Create data directory for mounting
RUN mkdir -p /data
VOLUME ["/data"]

# Copy run script
COPY run.sh /app/1_phylowgs/
RUN chmod +x /app/1_phylowgs/run.sh

# Set environment variables
ENV DATA_DIR=/data
ENV PYTHONPATH=/app/1_phylowgs/phylowgs:$PYTHONPATH
ENV PATH=/app/1_phylowgs/phylowgs:$PATH

# Stay in the PhyloWGS directory
WORKDIR /app/1_phylowgs/phylowgs

# Default command
ENTRYPOINT ["/app/1_phylowgs/run.sh"]
CMD ["7", "4", "1"]

# Default values: patient 7, 4 chains, bootstrap 1