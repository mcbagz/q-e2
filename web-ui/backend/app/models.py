"""Pydantic models for API requests and responses."""

from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from datetime import datetime


class SimulationCreate(BaseModel):
    """Create a new simulation."""
    
    prefix: str = Field(..., description="Prefix for output files")
    outdir: str = Field(..., description="Output directory")
    calculation_type: str = Field(default="scf", description="Type of calculation (scf, relax, vc-relax, md, vc-md, nscf, bands)")
    
    # Structure parameters
    atoms: Optional[List[Dict[str, Any]]] = Field(None, description="Atomic positions and species")
    cell_parameters: Optional[List[List[float]]] = Field(None, description="Cell parameters")
    
    # Pseudopotentials
    pseudopotentials: Optional[Dict[str, str]] = Field(None, description="Custom pseudopotential mapping")
    
    # Calculation parameters  
    ecutwfc: Optional[float] = Field(None, description="Kinetic energy cutoff for wavefunctions (Ry)")
    ecutrho: Optional[float] = Field(None, description="Kinetic energy cutoff for charge density (Ry)")
    k_points: Optional[Dict[str, Any]] = Field(None, description="K-points specification")
    
    # Advanced parameters
    conv_thr: Optional[float] = Field(1e-6, description="Convergence threshold for self-consistency")
    mixing_beta: Optional[float] = Field(0.7, description="Mixing factor for self-consistency")
    
    # AUTO_OPTIMIZE parameters
    auto_optimize: Optional[Dict[str, Any]] = Field(None, description="AUTO_OPTIMIZE settings")
    
    # Additional QE parameters
    qe_params: Optional[Dict[str, Any]] = Field(None, description="Additional QE parameters for namelists")
    

class SimulationUpdate(BaseModel):
    """Update simulation status."""
    
    status: Optional[str] = None
    pid: Optional[int] = None
    total_energy: Optional[float] = None
    output_log: Optional[str] = None
    error_log: Optional[str] = None
    checkpoint_available: Optional[bool] = None
    

class SimulationResponse(BaseModel):
    """Simulation response."""
    
    id: int
    prefix: str
    outdir: str
    status: str
    calculation_type: str
    input_file: Optional[str]
    pid: Optional[int]
    start_time: Optional[datetime]
    end_time: Optional[datetime]
    total_energy: Optional[float]
    created_at: datetime
    updated_at: datetime
    checkpoint_available: bool
    last_checkpoint: Optional[datetime]
    
    class Config:
        from_attributes = True


class SimulationListResponse(BaseModel):
    """List of simulations."""
    
    simulations: List[SimulationResponse]
    total: int
    
    
class ProcessControl(BaseModel):
    """Process control commands."""
    
    action: str = Field(..., description="Action to perform: start, stop, pause, resume, snapshot, checkpoint")
    simulation_id: int = Field(..., description="Simulation ID")
    

class WebSocketMessage(BaseModel):
    """WebSocket message format."""
    
    type: str = Field(..., description="Message type: log, status, error, progress")
    simulation_id: int
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    data: Dict[str, Any]