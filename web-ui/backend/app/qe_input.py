"""Quantum ESPRESSO input file generation."""

from typing import Dict, Any, List, Optional
from pathlib import Path
from .config import settings


class QEInputGenerator:
    """Generate Quantum ESPRESSO input files."""
    
    def __init__(self):
        self.default_pseudopotentials = {
            "H": "H.pbe-rrkjus_psl.1.0.0.UPF",
            "C": "C.pbe-n-rrkjus_psl.1.0.0.UPF",
            "N": "N.pbe-n-rrkjus_psl.1.0.0.UPF",
            "O": "O.pbe-n-rrkjus_psl.1.0.0.UPF",
            "Si": "Si.pbe-n-rrkjus_psl.1.0.0.UPF",
            # Add more default pseudopotentials as needed
        }
        self.pseudo_dir = settings.qe_pseudo_path
    
    def generate_scf_input(
        self,
        prefix: str,
        outdir: str,
        atoms: List[Dict[str, Any]],
        cell_parameters: List[List[float]],
        ecutwfc: float = 50.0,
        ecutrho: Optional[float] = None,
        k_points: Optional[Dict[str, Any]] = None,
        conv_thr: float = 1e-6,
        mixing_beta: float = 0.7,
        **kwargs
    ) -> str:
        """Generate SCF calculation input file."""
        
        # Default ecutrho to 4 * ecutwfc if not specified
        if ecutrho is None:
            ecutrho = 4 * ecutwfc
            
        # Default k-points if not specified
        if k_points is None:
            k_points = {"type": "automatic", "grid": [2, 2, 2], "shift": [0, 0, 0]}
        
        # Extract unique species
        species = list(set(atom["element"] for atom in atoms))
        
        # Build input file
        lines = []
        
        # Control namelist
        lines.extend([
            "&CONTROL",
            f"  calculation = 'scf'",
            f"  prefix = '{prefix}'",
            f"  outdir = '{outdir}'",
            f"  pseudo_dir = '{self.pseudo_dir}'",
            f"  tprnfor = .true.",
            f"  tstress = .true.",
            f"  verbosity = 'high'",
            "/"
        ])
        
        # System namelist
        lines.extend([
            "&SYSTEM",
            f"  ibrav = 0",
            f"  nat = {len(atoms)}",
            f"  ntyp = {len(species)}",
            f"  ecutwfc = {ecutwfc}",
            f"  ecutrho = {ecutrho}",
        ])
        
        # Add any additional system parameters
        if "nspin" in kwargs:
            lines.append(f"  nspin = {kwargs['nspin']}")
        if "occupations" in kwargs:
            lines.append(f"  occupations = '{kwargs['occupations']}'")
            if kwargs['occupations'] == 'smearing':
                lines.append(f"  smearing = '{kwargs.get('smearing', 'gaussian')}'")
                lines.append(f"  degauss = {kwargs.get('degauss', 0.01)}")
        
        lines.append("/")
        
        # Electrons namelist
        lines.extend([
            "&ELECTRONS",
            f"  conv_thr = {conv_thr}",
            f"  mixing_beta = {mixing_beta}",
            f"  electron_maxstep = 100",
            "/"
        ])
        
        # Cell parameters
        lines.extend([
            "CELL_PARAMETERS angstrom",
            f"  {cell_parameters[0][0]:12.8f} {cell_parameters[0][1]:12.8f} {cell_parameters[0][2]:12.8f}",
            f"  {cell_parameters[1][0]:12.8f} {cell_parameters[1][1]:12.8f} {cell_parameters[1][2]:12.8f}",
            f"  {cell_parameters[2][0]:12.8f} {cell_parameters[2][1]:12.8f} {cell_parameters[2][2]:12.8f}",
        ])
        
        # Atomic species
        lines.append("ATOMIC_SPECIES")
        for spec in species:
            pseudo = self.default_pseudopotentials.get(spec, f"{spec}.UPF")
            # Dummy mass for now - should be properly set
            mass = self._get_atomic_mass(spec)
            lines.append(f"  {spec} {mass:8.4f} {pseudo}")
        
        # Atomic positions
        lines.append("ATOMIC_POSITIONS angstrom")
        for atom in atoms:
            x, y, z = atom["position"]
            lines.append(f"  {atom['element']} {x:12.8f} {y:12.8f} {z:12.8f}")
        
        # K-points
        if k_points["type"] == "automatic":
            lines.append("K_POINTS automatic")
            grid = k_points["grid"]
            shift = k_points.get("shift", [0, 0, 0])
            lines.append(f"  {grid[0]} {grid[1]} {grid[2]} {shift[0]} {shift[1]} {shift[2]}")
        elif k_points["type"] == "gamma":
            lines.append("K_POINTS gamma")
        
        return "\n".join(lines)
    
    def _get_atomic_mass(self, element: str) -> float:
        """Get atomic mass for element."""
        # Simplified - should use proper atomic masses
        masses = {
            "H": 1.008,
            "C": 12.011,
            "N": 14.007,
            "O": 15.999,
            "Si": 28.086,
            "Fe": 55.845,
            # Add more as needed
        }
        return masses.get(element, 1.0)
    
    def generate_simple_scf_input(self, prefix: str, outdir: str) -> str:
        """Generate a simple SCF input for testing (Silicon example)."""
        
        atoms = [
            {"element": "Si", "position": [0.0, 0.0, 0.0]},
            {"element": "Si", "position": [1.3575, 1.3575, 1.3575]}
        ]
        
        cell_parameters = [
            [2.715, 2.715, 0.0],
            [2.715, 0.0, 2.715],
            [0.0, 2.715, 2.715]
        ]
        
        return self.generate_scf_input(
            prefix=prefix,
            outdir=outdir,
            atoms=atoms,
            cell_parameters=cell_parameters,
            ecutwfc=20.0,  # Lower for testing
            k_points={"type": "automatic", "grid": [4, 4, 4], "shift": [1, 1, 1]}
        )