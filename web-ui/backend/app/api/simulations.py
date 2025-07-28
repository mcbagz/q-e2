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
        # Handle status messages (process completion)
        if stream == "status":
            if "Process finished" in line:
                # Extract return code
                return_code = 0
                match = re.search(r"code (\d+)", line)
                if match:
                    return_code = int(match.group(1))
                
                # Update simulation status
                if return_code == 0:
                    simulation.status = "completed"
                else:
                    simulation.status = "error"
                    simulation.error_log = f"Process exited with code {return_code}"
                
                simulation.end_time = datetime.utcnow()
                db.commit()
                
                await connection_manager.send_status(simulation.id, simulation.status)
                return
            elif stream == "error":
                simulation.status = "error"
                simulation.error_log = line
                simulation.end_time = datetime.utcnow()
                db.commit()
                await connection_manager.send_status(simulation.id, "error")
                return
        
        # Send to WebSocket
        await connection_manager.send_log(simulation.id, stream, line)
        
        # Parse output for progress - check both stdout and stderr
        # QE sends important progress info to stderr
        if stream in ["stdout", "stderr"]:
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
            
            # Check for SCF convergence achieved
            if "convergence has been achieved" in line:
                await connection_manager.send_progress(
                    simulation.id, 0, simulation.total_energy or 0.0, True
                )
                
            # Parse estimated accuracy
            accuracy_match = re.search(r"estimated scf accuracy\s*<\s*([-\d.E]+)\s*Ry", line)
            if accuracy_match:
                accuracy = float(accuracy_match.group(1))
                await connection_manager.send_message(simulation.id, "simulation_accuracy", {
                    "simulation_id": simulation.id,
                    "accuracy": accuracy
                })
                
            # Parse CPU time
            cpu_time_match = re.search(r"total cpu time spent up to now is\s*([\d.]+)\s*secs", line)
            if cpu_time_match:
                cpu_time = float(cpu_time_match.group(1))
                await connection_manager.send_message(simulation.id, "simulation_cpu_time", {
                    "simulation_id": simulation.id,
                    "cpu_time": cpu_time
                })
    
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
    
    # Read output and error log files if they exist
    output_file = Path(simulation.outdir) / f"{simulation.prefix}.out"
    error_file = Path(simulation.outdir) / f"{simulation.prefix}.err"
    
    stdout_content = ""
    stderr_content = ""
    
    if output_file.exists():
        try:
            stdout_content = output_file.read_text()
        except Exception as e:
            stdout_content = f"Error reading stdout: {str(e)}"
    
    if error_file.exists():
        try:
            stderr_content = error_file.read_text()
        except Exception as e:
            stderr_content = f"Error reading stderr: {str(e)}"
    
    return {
        "stdout": stdout_content or "No stdout output available",
        "stderr": stderr_content or "No stderr output available",
        "logs": stdout_content  # Keep for backward compatibility
    }


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
        simulation.checkpoint_available = True
        simulation.last_checkpoint = datetime.utcnow()
        db.commit()
        await connection_manager.send_status(simulation.id, "checkpointed")
        return {"status": "checkpoint_created"}
    else:
        raise HTTPException(status_code=500, detail="Failed to send checkpoint signal")


@router.post("/{simulation_id}/resume")
async def resume_simulation(
    simulation_id: int,
    db: Session = Depends(get_db)
):
    """Resume a simulation from checkpoint."""
    
    simulation = db.query(Simulation).filter(Simulation.id == simulation_id).first()
    if not simulation:
        raise HTTPException(status_code=404, detail="Simulation not found")
    
    if not simulation.checkpoint_available:
        raise HTTPException(status_code=400, detail="No checkpoint available for this simulation")
    
    if simulation.status == "running":
        raise HTTPException(status_code=400, detail="Simulation is already running")
    
    # Create a new input file with restart_mode = 'restart'
    input_gen = QEInputGenerator()
    
    # Parse the original input file to get parameters
    original_input = simulation.input_file
    
    # Add restart_mode to the input
    # Simple approach: modify the &CONTROL section
    lines = original_input.split('\n')
    new_lines = []
    in_control = False
    restart_added = False
    
    for line in lines:
        if '&CONTROL' in line.upper():
            in_control = True
            new_lines.append(line)
        elif in_control and not restart_added and (line.strip().startswith('/') or not line.strip()):
            # Add restart_mode before the end of CONTROL namelist
            new_lines.append("  restart_mode = 'restart'")
            restart_added = True
            new_lines.append(line)
            in_control = False
        else:
            # Remove any existing restart_mode line
            if 'restart_mode' not in line.lower():
                new_lines.append(line)
    
    # Write the modified input file
    restart_input = '\n'.join(new_lines)
    sim_dir = Path(simulation.outdir)
    restart_input_file = sim_dir / f"{simulation.prefix}_restart.in"
    restart_input_file.write_text(restart_input)
    
    # Create output handler (same as start_simulation)
    async def output_handler(stream: str, line: str):
        # Handle status messages (process completion)
        if stream == "status":
            if "Process finished" in line:
                # Extract return code
                return_code = 0
                match = re.search(r"code (\d+)", line)
                if match:
                    return_code = int(match.group(1))
                
                # Update simulation status
                if return_code == 0:
                    simulation.status = "completed"
                else:
                    simulation.status = "error"
                    simulation.error_log = f"Process exited with code {return_code}"
                
                simulation.end_time = datetime.utcnow()
                db.commit()
                
                await connection_manager.send_status(simulation.id, simulation.status)
                return
            elif stream == "error":
                simulation.status = "error"
                simulation.error_log = line
                simulation.end_time = datetime.utcnow()
                db.commit()
                await connection_manager.send_status(simulation.id, "error")
                return
        
        await connection_manager.send_log(simulation.id, stream, line)
        
        if stream in ["stdout", "stderr"]:
            energy_match = re.search(r"total energy\s*=\s*([-\d.]+)\s*Ry", line)
            if energy_match:
                energy = float(energy_match.group(1))
                simulation.total_energy = energy
                db.commit()
                
            iter_match = re.search(r"iteration #\s*(\d+)", line)
            if iter_match:
                iteration = int(iter_match.group(1))
                await connection_manager.send_progress(
                    simulation.id, iteration, simulation.total_energy or 0.0, False
                )
            
            if "convergence has been achieved" in line:
                await connection_manager.send_progress(
                    simulation.id, 0, simulation.total_energy or 0.0, True
                )
                
            accuracy_match = re.search(r"estimated scf accuracy\s*<\s*([-\d.E]+)\s*Ry", line)
            if accuracy_match:
                accuracy = float(accuracy_match.group(1))
                await connection_manager.send_message(simulation.id, "simulation_accuracy", {
                    "simulation_id": simulation.id,
                    "accuracy": accuracy
                })
                
            cpu_time_match = re.search(r"total cpu time spent up to now is\s*([\d.]+)\s*secs", line)
            if cpu_time_match:
                cpu_time = float(cpu_time_match.group(1))
                await connection_manager.send_message(simulation.id, "simulation_cpu_time", {
                    "simulation_id": simulation.id,
                    "cpu_time": cpu_time
                })
    
    # Start calculation with restart input
    try:
        pid = await process_manager.start_calculation(
            simulation.id, restart_input_file, output_handler
        )
        
        # Update simulation
        simulation.status = "running"
        simulation.pid = pid
        simulation.start_time = datetime.utcnow()
        db.commit()
        
        await connection_manager.send_status(simulation.id, "running", {"pid": pid})
        await connection_manager.send_log(simulation.id, "info", "[RESUME] Resuming from checkpoint")
        
        return {"status": "resumed", "pid": pid}
        
    except Exception as e:
        simulation.status = "error"
        simulation.error_log = str(e)
        db.commit()
        raise HTTPException(status_code=500, detail=str(e))


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