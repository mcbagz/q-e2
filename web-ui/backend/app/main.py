"""Main FastAPI application."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging

from app.config import settings
from app.api import simulations
from app.process_manager import process_manager

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events."""
    # Startup
    logger.info("Starting Quantum ESPRESSO Web UI Backend")
    logger.info(f"QE binaries path: {settings.qe_bin_path}")
    logger.info(f"Simulations directory: {settings.simulations_dir}")
    
    yield
    
    # Shutdown
    logger.info("Shutting down...")
    process_manager.cleanup()


# Create FastAPI app
app = FastAPI(
    title="Quantum ESPRESSO Web UI",
    description="Web-based interface for Quantum ESPRESSO calculations",
    version="0.1.0",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],#settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(simulations.router)


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "name": "Quantum ESPRESSO Web UI Backend",
        "version": "0.1.0",
        "status": "running"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "qe_bin_path": str(settings.qe_bin_path),
        "simulations_dir": str(settings.simulations_dir)
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.host,
        port=settings.port,
        reload=True
    )