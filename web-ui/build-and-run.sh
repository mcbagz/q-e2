#!/bin/bash

# Quantum ESPRESSO Web UI - Build and Run Script

set -e

echo "=== Quantum ESPRESSO Web UI Builder ==="
echo

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Parse command line arguments
MODE="dev"
BUILD_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --prod)
            MODE="prod"
            shift
            ;;
        --build-only)
            BUILD_ONLY=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --prod       Build and run production configuration"
            echo "  --build-only Only build containers without starting them"
            echo "  --help       Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Determine which docker-compose file to use
if [ "$MODE" = "prod" ]; then
    COMPOSE_FILE="docker-compose.prod.yml"
    print_info "Using production configuration"
else
    COMPOSE_FILE="docker-compose.yml"
    print_info "Using development configuration"
fi

# Create necessary directories
print_info "Creating necessary directories..."
mkdir -p data simulations logs

# Build containers
print_info "Building Docker containers..."
docker-compose -f $COMPOSE_FILE build

if [ "$BUILD_ONLY" = true ]; then
    print_success "Containers built successfully!"
    exit 0
fi

# Stop any existing containers
print_info "Stopping any existing containers..."
docker-compose -f $COMPOSE_FILE down

# Start containers
print_info "Starting containers..."
docker-compose -f $COMPOSE_FILE up -d

# Wait for services to be ready
print_info "Waiting for services to be ready..."
sleep 5

# Check if services are running
if docker-compose -f $COMPOSE_FILE ps | grep -q "Up"; then
    print_success "Services are running!"
    echo
    echo "Access the application at:"
    echo "  - Web UI: http://localhost"
    echo "  - API Docs: http://localhost:8000/docs"
    echo
    echo "To view logs:"
    echo "  - All services: docker-compose -f $COMPOSE_FILE logs -f"
    echo "  - Backend only: docker-compose -f $COMPOSE_FILE logs -f backend"
    echo "  - Frontend only: docker-compose -f $COMPOSE_FILE logs -f frontend"
    echo
    echo "To stop services:"
    echo "  - docker-compose -f $COMPOSE_FILE down"
else
    print_error "Services failed to start. Check logs with: docker-compose -f $COMPOSE_FILE logs"
    exit 1
fi