"""Simulation API endpoints."""

from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List, Optional
from pathlib import Path
from datetime import datetime
import re

from app.database import get_db, Simulation
from app.models import (
    SimulationCreate, SimulationResponse, SimulationListResponse,
    SimulationUpdate, ProcessControl
)
from app.config import settings
from app.qe_input import QEInputGenerator
from app.process_manager import process_manager
from app.websocket import connection_manager
import os

router = APIRouter(prefix="/api/simulations", tags=["simulations"])

# Create a separate router for pseudopotentials
pseudo_router = APIRouter(prefix="/api/pseudopotentials", tags=["pseudopotentials"])


@router.get("/", response_model=SimulationListResponse)
async def list_simulations(
    skip: int = 0,
    limit: int = 100,
    status: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """List all simulations with optional filtering."""
    
    query = db.query(Simulation)
    
    if status:
        query = query.filter(Simulation.status == status)
        
    total = query.count()
    simulations = query.offset(skip).limit(limit).all()
    
    return SimulationListResponse(
        simulations=[SimulationResponse.from_orm(sim) for sim in simulations],
        total=total
    )


@router.get("/{simulation_id}", response_model=SimulationResponse)
async def get_simulation(simulation_id: int, db: Session = Depends(get_db)):
    """Get a specific simulation."""
    
    simulation = db.query(Simulation).filter(Simulation.id == simulation_id).first()
    if not simulation:
        raise HTTPException(status_code=404, detail="Simulation not found")
        
    return SimulationResponse.from_orm(simulation)


@router.post("/", response_model=SimulationResponse)
async def create_simulation(
    simulation: SimulationCreate,
    db: Session = Depends(get_db)
):
    """Create a new simulation."""
    
    # Create simulation directory
    sim_dir = settings.simulations_dir / f"sim_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{simulation.prefix}"
    sim_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate input file
    input_gen = QEInputGenerator()
    
    if simulation.atoms and simulation.cell_parameters:
        # Convert atom format from frontend (x,y,z properties) to backend format (position array)
        atoms = []
        for atom in simulation.atoms:
            if isinstance(atom, dict):
                if 'position' in atom:
                    # Already in correct format
                    atoms.append(atom)
                elif 'x' in atom and 'y' in atom and 'z' in atom:
                    # Convert from frontend format
                    atoms.append({
                        "element": atom["element"],
                        "position": [atom["x"], atom["y"], atom["z"]]
                    })
            else:
                # Handle other formats if needed
                atoms.append(atom)
        
        # Prepare kwargs for additional parameters
        kwargs = {}
        if simulation.qe_params:
            kwargs.update(simulation.qe_params)
        
        # Use provided structure
        input_content = input_gen.generate_scf_input(
            prefix=simulation.prefix,
            outdir=str(sim_dir / "out"),
            atoms=atoms,
            cell_parameters=simulation.cell_parameters,
            ecutwfc=simulation.ecutwfc or 50.0,
            ecutrho=simulation.ecutrho,
            k_points=simulation.k_points,
            conv_thr=simulation.conv_thr,
            mixing_beta=simulation.mixing_beta,
            pseudopotentials=simulation.pseudopotentials,
            auto_optimize=simulation.auto_optimize,
            calculation_type=simulation.calculation_type,
            **kwargs
        )
    else:
        # Use simple test input
        input_content = input_gen.generate_simple_scf_input(
            prefix=simulation.prefix,
            outdir=str(sim_dir / "out")
        )
    
    # Save input file
    input_file = sim_dir / f"{simulation.prefix}.in"
    input_file.write_text(input_content)
    
    # Create database entry
    db_simulation = Simulation(
        prefix=simulation.prefix,
        outdir=str(sim_dir),
        status="draft",
        calculation_type=simulation.calculation_type,
        input_file=input_content
    )
    
    db.add(db_simulation)
    db.commit()
    db.refresh(db_simulation)
    
    return SimulationResponse.from_orm(db_simulation)


@router.post("/{simulation_id}/start")
async def start_simulation(
    simulation_id: int,
    db: Session = Depends(get_db)
):
    """Start a simulation."""
    
    simulation = db.query(Simulation).filter(Simulation.id == simulation_id).first()
    if not simulation:
        raise HTTPException(status_code=404, detail="Simulation not found")
        
    if simulation.status == "running":
        raise HTTPException(status_code=400, detail="Simulation already running")
    
    # Create output handler
    async def output_handler(stream: str, line: str):
        # Send to WebSocket
        await connection_manager.send_log(simulation.id, stream, line)
        
        # Parse output for progress
        if stream == "stdout":
            # Check for energy convergence
            energy_match = re.search(r"total energy\s*=\s*([-\d.]+)\s*Ry", line)
            if energy_match:
                energy = float(energy_match.group(1))
                simulation.total_energy = energy
                db.commit()
                
            # Check for iteration
            iter_match = re.search(r"iteration #\s*(\d+)", line)
            if iter_match:
                iteration = int(iter_match.group(1))
                await connection_manager.send_progress(
                    simulation.id, iteration, simulation.total_energy or 0.0, False
                )
    
    # Start calculation
    input_file = Path(simulation.outdir) / f"{simulation.prefix}.in"
    try:
        pid = await process_manager.start_calculation(
            simulation.id, input_file, output_handler
        )
        
        # Update simulation
        simulation.status = "running"
        simulation.pid = pid
        simulation.start_time = datetime.utcnow()
        db.commit()
        
        await connection_manager.send_status(simulation.id, "running", {"pid": pid})
        
        return {"status": "started", "pid": pid}
        
    except Exception as e:
        simulation.status = "error"
        simulation.error_log = str(e)
        db.commit()
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{simulation_id}/stop")
async def stop_simulation(
    simulation_id: int,
    db: Session = Depends(get_db)
):
    """Stop a simulation."""
    
    simulation = db.query(Simulation).filter(Simulation.id == simulation_id).first()
    if not simulation:
        raise HTTPException(status_code=404, detail="Simulation not found")
    
    success = process_manager.stop_calculation(simulation.id)
    if success:
        simulation.status = "stopped"
        simulation.end_time = datetime.utcnow()
        db.commit()
        await connection_manager.send_status(simulation.id, "stopped")
        return {"status": "stopped"}
    else:
        raise HTTPException(status_code=400, detail="Failed to stop process")


@router.get("/{simulation_id}/logs")
async def get_simulation_logs(
    simulation_id: int,
    db: Session = Depends(get_db)
):
    """Get simulation logs."""
    
    simulation = db.query(Simulation).filter(Simulation.id == simulation_id).first()
    if not simulation:
        raise HTTPException(status_code=404, detail="Simulation not found")
    
    # Read output log file if it exists
    output_file = Path(simulation.outdir) / f"{simulation.prefix}.out"
    if output_file.exists():
        try:
            logs = output_file.read_text()
            return {"logs": logs}
        except Exception as e:
            return {"logs": f"Error reading logs: {str(e)}"}
    else:
        return {"logs": simulation.output_log or "No logs available yet"}


@router.websocket("/{simulation_id}/ws")
async def websocket_endpoint(websocket: WebSocket, simulation_id: int):
    """WebSocket endpoint for real-time simulation updates."""
    
    await connection_manager.connect(websocket, simulation_id)
    
    try:
        while True:
            # Keep connection alive
            await websocket.receive_text()
            
    except WebSocketDisconnect:
        connection_manager.disconnect(websocket, simulation_id)


@router.post("/{simulation_id}/snapshot")
async def take_snapshot(
    simulation_id: int,
    db: Session = Depends(get_db)
):
    """Take a snapshot of the running simulation."""
    
    simulation = db.query(Simulation).filter(Simulation.id == simulation_id).first()
    if not simulation:
        raise HTTPException(status_code=404, detail="Simulation not found")
    
    if simulation.status != "running":
        raise HTTPException(status_code=400, detail="Simulation is not running")
    
    success = process_manager.send_snapshot_signal(simulation.id)
    if success:
        await connection_manager.send_log(simulation.id, "info", "[SNAPSHOT] Sent SIGUSR2 signal to QE process")
        return {"status": "snapshot_requested"}
    else:
        raise HTTPException(status_code=500, detail="Failed to send snapshot signal")


@router.post("/{simulation_id}/checkpoint")
async def create_checkpoint(
    simulation_id: int,
    db: Session = Depends(get_db)
):
    """Create a checkpoint and stop the simulation."""
    
    simulation = db.query(Simulation).filter(Simulation.id == simulation_id).first()
    if not simulation:
        raise HTTPException(status_code=404, detail="Simulation not found")
    
    if simulation.status != "running":
        raise HTTPException(status_code=400, detail="Simulation is not running")
    
    success = process_manager.send_checkpoint_signal(simulation.id)
    if success:
        await connection_manager.send_log(simulation.id, "info", "[CHECKPOINT] Sent SIGUSR1 signal to QE process")
        simulation.status = "checkpointed"
        simulation.end_time = datetime.utcnow()
        db.commit()
        await connection_manager.send_status(simulation.id, "checkpointed")
        return {"status": "checkpoint_created"}
    else:
        raise HTTPException(status_code=500, detail="Failed to send checkpoint signal")


@router.delete("/{simulation_id}")
async def delete_simulation(simulation_id: int, db: Session = Depends(get_db)):
    """Delete a simulation."""
    
    simulation = db.query(Simulation).filter(Simulation.id == simulation_id).first()
    if not simulation:
        raise HTTPException(status_code=404, detail="Simulation not found")
    
    # Stop process if running
    if simulation.status == "running":
        process_manager.stop_calculation(simulation_id)
    
    # Delete from database
    db.delete(simulation)
    db.commit()
    
    return {"status": "deleted"}


@pseudo_router.get("/")
async def list_pseudopotentials():
    """List all available pseudopotentials grouped by element."""
    
    input_gen = QEInputGenerator()
    available_pseudos = input_gen.get_available_pseudopotentials()
    
    # Also include default pseudopotentials
    result = {}
    for element, default_pseudo in input_gen.default_pseudopotentials.items():
        if element not in result:
            result[element] = {
                "default": default_pseudo,
                "available": []
            }
        else:
            result[element]["default"] = default_pseudo
    
    # Add scanned pseudopotentials
    for element, pseudos in available_pseudos.items():
        if element not in result:
            result[element] = {
                "default": pseudos[0] if pseudos else f"{element}.UPF",
                "available": pseudos
            }
        else:
            result[element]["available"] = pseudos
    
    return result


@router.post("/import-structure")
async def import_structure(
    file: UploadFile = File(...),
    file_format: str = Form(...)
):
    """Import structure from uploaded file (CIF, XYZ, etc.)."""
    
    # Read file content
    content = await file.read()
    content_str = content.decode('utf-8')
    
    # Parse structure
    input_gen = QEInputGenerator()
    try:
        structure_data = input_gen.import_structure(content_str, file_format)
        return {
            "status": "success",
            "atoms": structure_data["atoms"],
            "cell_parameters": structure_data["cell_parameters"],
            "filename": file.filename
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to parse structure: {str(e)}")