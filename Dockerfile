FROM ubuntu:20.04

# Set the DEBIAN_FRONTEND to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get -qq update && \
    apt-get -qq install -y apt-transport-https ca-certificates gnupg software-properties-common wget build-essential git gfortran cmake libopenblas-dev libfftw3-dev libopenmpi-dev nano && \
    wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null && \
    apt-add-repository 'deb https://apt.kitware.com/ubuntu/ focal main' && \
    apt-get -qq update && \
    apt-get -qq install -y cmake

# Copy the source code
COPY . /usr/src/q-e

# Set the working directory
WORKDIR /usr/src/q-e

# Build Quantum Espresso
RUN mkdir build && \
    cd build && \
    cmake -DBUILD_SHARED_LIBS=ON -DCMAKE_Fortran_COMPILER=mpif90 -DCMAKE_C_COMPILER=mpicc -DMPIEXEC_PREFLAGS="--allow-run-as-root;--oversubscribe" .. && \
    make -j 2 && \
    make install

# Set the entrypoint
CMD ["/bin/bash"]