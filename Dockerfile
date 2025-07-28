# Stage 1: Build Quantum ESPRESSO
FROM ubuntu:20.04 AS qe_builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -qq update && \
    apt-get -qq install -y apt-transport-https ca-certificates gnupg software-properties-common wget build-essential git gfortran cmake libopenblas-dev libfftw3-dev libopenmpi-dev nano && \
    wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null && \
    apt-add-repository 'deb https://apt.kitware.com/ubuntu/ focal main' && \
    apt-get -qq update && \
    apt-get -qq install -y cmake

COPY . /usr/src/q-e
WORKDIR /usr/src/q-e

RUN mkdir build && \
    cd build && \
    cmake -DBUILD_SHARED_LIBS=ON -DCMAKE_Fortran_COMPILER=mpif90 -DCMAKE_C_COMPILER=mpicc -DMPIEXEC_PREFLAGS="--allow-run-as-root;--oversubscribe" .. && \
    make -j 2 && \
    make install

# Stage 2: Build Web UI Frontend
FROM node:18-alpine AS frontend_builder

WORKDIR /app
COPY web-ui/frontend/package*.json ./
RUN npm ci
COPY web-ui/frontend/ ./
RUN npm run build

# Stage 3: Build Web UI Backend and combine with QE and Frontend
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    libopenmpi-dev \
    openmpi-bin \
    libfftw3-dev \
    libfftw3-3 \
    liblapack-dev \
    liblapack3 \
    libblas-dev \
    libblas3 \
    libopenblas-dev \
    libopenblas0 \
    libgomp1 \
    gfortran \
    wget \
    curl \
    nginx \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Copy QE binaries from qe_builder stage
RUN mkdir -p /opt/qe/bin
COPY --from=qe_builder /usr/src/q-e/build/bin/pw.x /opt/qe/bin/
COPY --from=qe_builder /usr/src/q-e/build/bin/pp.x /opt/qe/bin/
RUN chmod +x /opt/qe/bin/*

# Set up pseudopotentials directory
RUN mkdir -p /opt/qe/pseudo
COPY pseudo/*.UPF /opt/qe/pseudo/
COPY pseudo/*.upf /opt/qe/pseudo/

# Copy backend application
WORKDIR /app
COPY web-ui/backend/ /app/

# Create virtual environment and install Python dependencies
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip install --upgrade pip && \
    pip install -r requirements.txt

# Create directories for simulations
RUN mkdir -p /app/simulations /app/logs /app/data

# Copy frontend build from frontend_builder stage
COPY --from=frontend_builder /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY web-ui/docker/nginx.conf /etc/nginx/conf.d/default.conf

# Copy supervisord configuration
COPY .docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose ports
EXPOSE 80
EXPOSE 8000

# Environment variables for backend
ENV QE_BIN_PATH=/opt/qe/bin
ENV QE_PSEUDO_PATH=/opt/qe/pseudo
ENV DATABASE_URL=sqlite:////app/data/qe_simulations.db
ENV CORS_ORIGINS="["*"]"
ENV PYTHONUNBUFFERED=1

# Start supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
