"""Process management for Quantum ESPRESSO executables."""

import asyncio
import subprocess
import signal
import os
from pathlib import Path
from typing import Optional, Dict, Callable
from datetime import datetime
import logging

from app.config import settings

logger = logging.getLogger(__name__)


class QEProcessManager:
    """Manage Quantum ESPRESSO processes."""
    
    def __init__(self):
        self.processes: Dict[int, subprocess.Popen] = {}
        self.output_handlers: Dict[int, Callable] = {}
        
    async def start_calculation(
        self,
        simulation_id: int,
        input_file: Path,
        output_handler: Optional[Callable] = None
    ) -> int:
        """Start a QE calculation."""
        
        # Path to pw.x executable
        pw_exe = settings.qe_bin_path / "pw.x"
        
        if not pw_exe.exists():
            raise FileNotFoundError(f"pw.x not found at {pw_exe}")
        
        # Create output directory if it doesn't exist
        sim_dir = input_file.parent
        out_dir = sim_dir / "out"
        out_dir.mkdir(parents=True, exist_ok=True)
        
        # Create output file path
        output_file = sim_dir / f"{input_file.stem}.out"
        
        # Create command - redirect output to file and tee to stdout
        cmd = [str(pw_exe), "-in", str(input_file)]
        
        # Start process
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,  # Combine stderr with stdout
            text=True,
            bufsize=1,
            universal_newlines=True,
            cwd=str(sim_dir)  # Run in the simulation directory
        )
        
        # Store process
        self.processes[simulation_id] = process
        
        if output_handler:
            self.output_handlers[simulation_id] = output_handler
            # Start monitoring output and write to file
            asyncio.create_task(self._monitor_output(simulation_id, process, output_file))
        
        logger.info(f"Started QE calculation for simulation {simulation_id}, PID: {process.pid}")
        return process.pid
    
    async def _monitor_output(self, simulation_id: int, process: subprocess.Popen, output_file: Path = None):
        """Monitor process output and call handler."""
        
        handler = self.output_handlers.get(simulation_id)
        if not handler:
            return
        
        try:
            # Open output file for writing if provided
            outfile = None
            if output_file:
                outfile = open(output_file, 'w', buffering=1)
            
            # Read stdout line by line
            while True:
                line = process.stdout.readline()
                if not line and process.poll() is not None:
                    break
                    
                if line:
                    # Write to file if provided
                    if outfile:
                        outfile.write(line)
                        outfile.flush()
                    
                    # Send to handler
                    await handler("stdout", line.strip())
                    
            # Process finished
            await handler("status", f"Process finished with code {process.returncode}")
            
        except Exception as e:
            logger.error(f"Error monitoring output for simulation {simulation_id}: {e}")
            await handler("error", str(e))
        finally:
            # Close output file
            if outfile:
                outfile.close()
                
            # Cleanup
            self.processes.pop(simulation_id, None)
            self.output_handlers.pop(simulation_id, None)
    
    def stop_calculation(self, simulation_id: int) -> bool:
        """Stop a calculation (SIGTERM)."""
        
        process = self.processes.get(simulation_id)
        if not process or process.poll() is not None:
            return False
        
        try:
            process.terminate()
            logger.info(f"Sent SIGTERM to simulation {simulation_id}")
            return True
        except Exception as e:
            logger.error(f"Error stopping simulation {simulation_id}: {e}")
            return False
    
    def force_stop_calculation(self, simulation_id: int) -> bool:
        """Force stop a calculation (SIGKILL)."""
        
        process = self.processes.get(simulation_id)
        if not process or process.poll() is not None:
            return False
        
        try:
            process.kill()
            logger.info(f"Sent SIGKILL to simulation {simulation_id}")
            return True
        except Exception as e:
            logger.error(f"Error killing simulation {simulation_id}: {e}")
            return False
    
    def send_snapshot_signal(self, simulation_id: int) -> bool:
        """Send SIGUSR2 to trigger snapshot."""
        
        process = self.processes.get(simulation_id)
        if not process or process.poll() is not None:
            return False
        
        try:
            if os.name != 'nt':  # Unix/Linux/Mac
                os.kill(process.pid, signal.SIGUSR2)
                logger.info(f"Sent SIGUSR2 to simulation {simulation_id}")
                return True
            else:
                logger.warning("Snapshot signal not supported on Windows")
                return False
        except Exception as e:
            logger.error(f"Error sending snapshot signal to simulation {simulation_id}: {e}")
            return False
    
    def send_checkpoint_signal(self, simulation_id: int) -> bool:
        """Send SIGUSR1 to trigger checkpoint and stop."""
        
        process = self.processes.get(simulation_id)
        if not process or process.poll() is not None:
            return False
        
        try:
            if os.name != 'nt':  # Unix/Linux/Mac
                os.kill(process.pid, signal.SIGUSR1)
                logger.info(f"Sent SIGUSR1 to simulation {simulation_id}")
                return True
            else:
                logger.warning("Checkpoint signal not supported on Windows")
                return False
        except Exception as e:
            logger.error(f"Error sending checkpoint signal to simulation {simulation_id}: {e}")
            return False
    
    def get_process_status(self, simulation_id: int) -> Optional[Dict]:
        """Get process status."""
        
        process = self.processes.get(simulation_id)
        if not process:
            return None
        
        poll = process.poll()
        return {
            "pid": process.pid,
            "running": poll is None,
            "return_code": poll
        }
    
    def cleanup(self):
        """Cleanup all processes."""
        
        for sim_id, process in list(self.processes.items()):
            if process.poll() is None:
                logger.warning(f"Terminating orphaned process for simulation {sim_id}")
                process.terminate()
                
        self.processes.clear()
        self.output_handlers.clear()


# Global process manager instance
process_manager = QEProcessManager()