"""Configuration management for the QE Web UI backend."""

import os
from pathlib import Path
from pydantic_settings import BaseSettings
from typing import Optional, List


class Settings(BaseSettings):
    """Application settings."""
    
    # Database
    database_url: str = "sqlite:///./simulations.db"
    
    # QE configuration
    qe_bin_path: Path = Path("/opt/qe/bin")
    qe_pseudo_path: Path = Path("/opt/qe/pseudo")
    
    # Simulation storage
    simulations_dir: Path = Path("./simulations")
    logs_dir: Path = Path("./logs")
    
    # Server configuration
    host: str = "0.0.0.0"
    port: int = 8009
    
    # CORS configuration
    cors_origins: List[str] = ["*"]
    
    # WebSocket configuration
    ws_heartbeat_interval: int = 30
    
    # Logging
    log_level: str = "INFO"
    
    class Config:
        env_file = ".env"
        case_sensitive = False
        
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Handle environment variable overrides
        if os.getenv("QE_BIN_PATH"):
            self.qe_bin_path = Path(os.getenv("QE_BIN_PATH"))
        if os.getenv("QE_PSEUDO_PATH"):
            self.qe_pseudo_path = Path(os.getenv("QE_PSEUDO_PATH"))
        if os.getenv("CORS_ORIGINS"):
            self.cors_origins = os.getenv("CORS_ORIGINS").split(",")
            
        # Convert to absolute paths
        self.qe_bin_path = self.qe_bin_path.resolve()
        self.qe_pseudo_path = self.qe_pseudo_path.resolve()
        self.simulations_dir = self.simulations_dir.resolve()
        self.logs_dir = self.logs_dir.resolve()
        
        # Create directories if they don't exist
        self.simulations_dir.mkdir(parents=True, exist_ok=True)
        self.logs_dir.mkdir(parents=True, exist_ok=True)


settings = Settings()