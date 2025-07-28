"""Database configuration and models."""

from sqlalchemy import create_engine, Column, Integer, String, DateTime, Text, Float, Boolean
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime

from app.config import settings

# Create engine
engine = create_engine(
    settings.database_url,
    connect_args={"check_same_thread": False}  # Needed for SQLite
)

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create base class for models
Base = declarative_base()


class Simulation(Base):
    """Simulation model."""
    
    __tablename__ = "simulations"
    
    id = Column(Integer, primary_key=True, index=True)
    prefix = Column(String, nullable=False)
    outdir = Column(String, nullable=False)
    status = Column(String, default="draft")  # draft, running, completed, error, cancelled
    calculation_type = Column(String, default="scf")  # scf, nscf, relax, md, etc.
    
    # Input parameters
    input_file = Column(Text)
    
    # Process information
    pid = Column(Integer, nullable=True)
    start_time = Column(DateTime, nullable=True)
    end_time = Column(DateTime, nullable=True)
    
    # Results
    total_energy = Column(Float, nullable=True)
    final_structure = Column(Text, nullable=True)
    output_log = Column(Text, nullable=True)
    error_log = Column(Text, nullable=True)
    
    # Metadata
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Checkpoint information
    checkpoint_available = Column(Boolean, default=False)
    last_checkpoint = Column(DateTime, nullable=True)


def get_db():
    """Dependency to get database session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# Create tables
Base.metadata.create_all(bind=engine)