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
    && rm -rf /var/lib/apt/lists/*

# Create symbolic link for python2 (force creation if it exists)
RUN ln -sf /usr/bin/python2.7 /usr/bin/python2

# Create working directory
WORKDIR /app

# Copy requirements first to leverage Docker cache
COPY requirements.txt /app/
RUN pip2 install ete2==2.3.10

# Copy PhyloWGS code
COPY . /app/

# Make the script executable
RUN chmod +x /app/run.sh

# Compile the C++ code
WORKDIR /app/phylowgs
RUN g++ -o mh.o -O3 mh.cpp util.cpp `gsl-config --cflags --libs`
WORKDIR /app

# Create data directory
RUN mkdir -p /data

# Set volume for data
VOLUME ["/data"]

# Default command (will be overridden by run command)
ENTRYPOINT ["/app/run.sh"]
CMD ["7", "4", "1"]  

# Default values: patient 7, 4 chains, bootstrap 1