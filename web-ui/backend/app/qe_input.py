"""Quantum ESPRESSO input file generation."""

from typing import Dict, Any, List, Optional, Tuple
from pathlib import Path
import json
import re
from .config import settings


class QEInputGenerator:
    """Generate Quantum ESPRESSO input files."""
    
    def __init__(self):
        self.default_pseudopotentials = {
            "H": "H.pbe-rrkjus_psl.1.0.0.UPF",
            "He": "He.pbe-rrkjus_psl.1.0.0.UPF",
            "Li": "Li.pbe-n-rrkjus_psl.1.0.0.UPF",
            "Be": "Be.pbe-n-rrkjus_psl.1.0.0.UPF",
            "B": "B.pbe-n-rrkjus_psl.1.0.0.UPF",
            "C": "C.pbe-n-rrkjus_psl.1.0.0.UPF",
            "N": "N.pbe-n-rrkjus_psl.1.0.0.UPF",
            "O": "O.pbe-n-rrkjus_psl.1.0.0.UPF",
            "F": "F.pbe-n-rrkjus_psl.1.0.0.UPF",
            "Ne": "Ne.pbe-rrkjus_psl.1.0.0.UPF",
            "Na": "Na.pbe-n-rrkjus_psl.1.0.0.UPF",
            "Mg": "Mg.pbe-n-rrkjus_psl.1.0.0.UPF",
            "Al": "Al.pbe-n-rrkjus_psl.1.0.0.UPF",
            "Si": "Si.pbe-n-rrkjus_psl.1.0.0.UPF",
            "P": "P.pbe-n-rrkjus_psl.1.0.0.UPF",
            "S": "S.pbe-n-rrkjus_psl.1.0.0.UPF",
            "Cl": "Cl.pbe-n-rrkjus_psl.1.0.0.UPF",
            "Ar": "Ar.pbe-rrkjus_psl.1.0.0.UPF",
            "K": "K.pbe-spn-rrkjus_psl.1.0.0.UPF",
            "Ca": "Ca.pbe-spn-rrkjus_psl.1.0.0.UPF",
            "Fe": "Fe.pbe-spn-rrkjus_psl.1.0.0.UPF",
            "Ni": "Ni.pbe-n-rrkjus_psl.1.0.0.UPF",
            "Cu": "Cu.pbe-dn-rrkjus_psl.1.0.0.UPF",
            "Zn": "Zn.pbe-dn-rrkjus_psl.1.0.0.UPF",
            "Ga": "Ga.pbe-dn-rrkjus_psl.1.0.0.UPF",
            "Ge": "Ge.pbe-dn-rrkjus_psl.1.0.0.UPF",
            "As": "As.pbe-n-rrkjus_psl.1.0.0.UPF",
            # Add more default pseudopotentials as needed
        }
        self.pseudo_dir = settings.qe_pseudo_path
        self._scan_available_pseudopotentials()
    
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
        pseudopotentials: Optional[Dict[str, str]] = None,
        auto_optimize: Optional[Dict[str, Any]] = None,
        calculation_type: str = "scf",
        **kwargs
    ) -> str:
        """Generate SCF calculation input file with support for AUTO_OPTIMIZE."""
        
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
            f"  calculation = '{calculation_type}'",
            f"  prefix = '{prefix}'",
            f"  outdir = '{outdir}'",
            f"  pseudo_dir = '{self.pseudo_dir}'",
            f"  tprnfor = .true.",
            f"  tstress = .true.",
            f"  verbosity = 'high'",
        ])
        
        # Add additional control parameters
        for param in ['restart_mode', 'max_seconds', 'disk_io', 'wf_collect', 'forc_conv_thr']:
            if param in kwargs:
                if isinstance(kwargs[param], bool):
                    lines.append(f"  {param} = .{str(kwargs[param]).lower()}.")
                elif isinstance(kwargs[param], str):
                    lines.append(f"  {param} = '{kwargs[param]}'")
                else:
                    lines.append(f"  {param} = {kwargs[param]}")
        
        lines.append("/")
        
        # System namelist
        lines.extend([
            "&SYSTEM",
            f"  ibrav = 0",
            f"  nat = {len(atoms)}",
            f"  ntyp = {len(species)}",
            f"  ecutwfc = {ecutwfc}",
            f"  ecutrho = {ecutrho}",
        ])
        
        # Add default occupations for metallic systems if not specified
        if "occupations" not in kwargs:
            # Default to smearing for safety - QE will ignore if not needed
            lines.extend([
                f"  occupations = 'smearing'",
                f"  smearing = 'gaussian'",
                f"  degauss = 0.01",
            ])
        
        # Add any additional system parameters
        system_params = ['nspin', 'starting_magnetization', 'tot_charge', 'tot_magnetization',
                        'nbnd', 'nosym', 'noinv', 'force_symmorphic', 'use_all_frac',
                        'lda_plus_u', 'lda_plus_u_kind', 'Hubbard_U', 'Hubbard_J0',
                        'starting_ns_eigenvalue', 'vdw_corr', 'london', 'london_s6',
                        'london_rcut', 'ts_vdw_econv_thr', 'ts_vdw_isolated', 'ecutfock']
        
        for param in system_params:
            if param in kwargs:
                if isinstance(kwargs[param], bool):
                    lines.append(f"  {param} = .{str(kwargs[param]).lower()}.")
                elif isinstance(kwargs[param], str):
                    lines.append(f"  {param} = '{kwargs[param]}'")
                else:
                    lines.append(f"  {param} = {kwargs[param]}")
        
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
        ])
        
        # Add additional electron parameters
        electron_params = ['mixing_mode', 'mixing_ndim', 'diagonalization', 
                          'diago_thr_init', 'diago_full_acc', 'adaptive_thr']
        
        for param in electron_params:
            if param in kwargs:
                if isinstance(kwargs[param], bool):
                    lines.append(f"  {param} = .{str(kwargs[param]).lower()}.")
                elif isinstance(kwargs[param], str):
                    lines.append(f"  {param} = '{kwargs[param]}'")
                else:
                    lines.append(f"  {param} = {kwargs[param]}")
                    
        lines.append("/")
        
        # Ions namelist (for relax and md calculations)
        if calculation_type in ['relax', 'vc-relax', 'md', 'vc-md']:
            lines.extend([
                "&IONS",
                f"  ion_dynamics = '{kwargs.get('ion_dynamics', 'bfgs')}'",
            ])
            
            ion_params = ['ion_positions', 'pot_extrapolation', 'wfc_extrapolation',
                         'remove_rigid_rot', 'trust_radius_min', 'trust_radius_max',
                         'trust_radius_ini', 'bfgs_ndim', 'upscale', 'ion_temperature',
                         'tempw', 'tolp', 'delta_t', 'nraise']
                         
            for param in ion_params:
                if param in kwargs:
                    if isinstance(kwargs[param], bool):
                        lines.append(f"  {param} = .{str(kwargs[param]).lower()}.")
                    elif isinstance(kwargs[param], str):
                        lines.append(f"  {param} = '{kwargs[param]}'")
                    else:
                        lines.append(f"  {param} = {kwargs[param]}")
                        
            lines.append("/")
        
        # Cell namelist (for vc-relax and vc-md calculations)
        if calculation_type in ['vc-relax', 'vc-md']:
            lines.extend([
                "&CELL",
                f"  cell_dynamics = '{kwargs.get('cell_dynamics', 'bfgs')}'",
            ])
            
            cell_params = ['press', 'wmass', 'cell_factor', 'press_conv_thr',
                          'cell_dofree']
                          
            for param in cell_params:
                if param in kwargs:
                    if isinstance(kwargs[param], bool):
                        lines.append(f"  {param} = .{str(kwargs[param]).lower()}.")
                    elif isinstance(kwargs[param], str):
                        lines.append(f"  {param} = '{kwargs[param]}'")
                    else:
                        lines.append(f"  {param} = {kwargs[param]}")
                        
            lines.append("/")
        
        # AUTO_OPTIMIZE namelist
        if auto_optimize:
            lines.append("&AUTO_OPTIMIZE")
            if "k_points" in auto_optimize and auto_optimize["k_points"]:
                lines.append("  optimize_kpoints = .true.")
                if "kpoint_spacing" in auto_optimize:
                    lines.append(f"  kpoint_spacing = {auto_optimize['kpoint_spacing']}")
                if "k_min" in auto_optimize:
                    lines.append(f"  k_min = {auto_optimize['k_min']}")
                if "k_max" in auto_optimize:
                    lines.append(f"  k_max = {auto_optimize['k_max']}")
                if "k_step" in auto_optimize:
                    lines.append(f"  k_step = {auto_optimize['k_step']}")
            
            if "ecutwfc" in auto_optimize and auto_optimize["ecutwfc"]:
                lines.append("  optimize_cutoff = .true.")
                if "ecutwfc_min" in auto_optimize:
                    lines.append(f"  ecutwfc_min = {auto_optimize['ecutwfc_min']}")
                if "ecutwfc_max" in auto_optimize:
                    lines.append(f"  ecutwfc_max = {auto_optimize['ecutwfc_max']}")
                if "ecutwfc_step" in auto_optimize:
                    lines.append(f"  ecutwfc_step = {auto_optimize['ecutwfc_step']}")
            
            if "convergence_threshold" in auto_optimize:
                lines.append(f"  convergence_threshold = {auto_optimize['convergence_threshold']}")
                
            lines.append("/")
        
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
            # Use provided pseudopotential or select one
            if pseudopotentials and spec in pseudopotentials:
                pseudo = pseudopotentials[spec]
            else:
                pseudo = self.select_pseudopotential(spec)
            
            mass = self._get_atomic_mass(spec)
            lines.append(f"  {spec} {mass:8.4f} {pseudo}")
        
        # Atomic positions
        lines.append("ATOMIC_POSITIONS angstrom")
        for atom in atoms:
            x, y, z = atom["position"]
            # Support fixed atoms for relaxation
            if "fixed" in atom and any(atom["fixed"]):
                fx, fy, fz = atom["fixed"]
                lines.append(f"  {atom['element']} {x:12.8f} {y:12.8f} {z:12.8f} {int(not fx)} {int(not fy)} {int(not fz)}")
            else:
                lines.append(f"  {atom['element']} {x:12.8f} {y:12.8f} {z:12.8f}")
        
        # K-points
        if k_points["type"] == "automatic":
            lines.append("K_POINTS automatic")
            grid = k_points["grid"]
            shift = k_points.get("shift", [0, 0, 0])
            lines.append(f"  {grid[0]} {grid[1]} {grid[2]} {shift[0]} {shift[1]} {shift[2]}")
        elif k_points["type"] == "gamma":
            lines.append("K_POINTS gamma")
        elif k_points["type"] == "crystal" and "points" in k_points:
            lines.append(f"K_POINTS crystal")
            lines.append(f"  {len(k_points['points'])}")
            for kpt in k_points['points']:
                lines.append(f"  {kpt[0]:12.8f} {kpt[1]:12.8f} {kpt[2]:12.8f} {kpt[3]:12.8f}")
        elif k_points["type"] == "crystal_b" and "path" in k_points:
            lines.append(f"K_POINTS crystal_b")
            lines.append(f"  {len(k_points['path'])}")
            for segment in k_points['path']:
                lines.append(f"  {segment[0]:12.8f} {segment[1]:12.8f} {segment[2]:12.8f} {segment[3]:d}")
        
        return "\n".join(lines)
    
    def _get_atomic_mass(self, element: str) -> float:
        """Get atomic mass for element."""
        # Extended atomic masses table
        masses = {
            "H": 1.008, "He": 4.003, "Li": 6.941, "Be": 9.012, "B": 10.81,
            "C": 12.011, "N": 14.007, "O": 15.999, "F": 18.998, "Ne": 20.180,
            "Na": 22.990, "Mg": 24.305, "Al": 26.982, "Si": 28.086, "P": 30.974,
            "S": 32.06, "Cl": 35.45, "Ar": 39.948, "K": 39.098, "Ca": 40.078,
            "Sc": 44.956, "Ti": 47.867, "V": 50.942, "Cr": 51.996, "Mn": 54.938,
            "Fe": 55.845, "Co": 58.933, "Ni": 58.693, "Cu": 63.546, "Zn": 65.38,
            "Ga": 69.723, "Ge": 72.64, "As": 74.922, "Se": 78.96, "Br": 79.904,
            "Kr": 83.798, "Rb": 85.468, "Sr": 87.62, "Y": 88.906, "Zr": 91.224,
            "Nb": 92.906, "Mo": 95.96, "Tc": 98.0, "Ru": 101.07, "Rh": 102.906,
            "Pd": 106.42, "Ag": 107.868, "Cd": 112.411, "In": 114.818, "Sn": 118.710,
            "Sb": 121.760, "Te": 127.6, "I": 126.904, "Xe": 131.293, "Cs": 132.905,
            "Ba": 137.327, "La": 138.905, "Ce": 140.116, "Pr": 140.908, "Nd": 144.242,
            "Pm": 145.0, "Sm": 150.36, "Eu": 151.964, "Gd": 157.25, "Tb": 158.925,
            "Dy": 162.5, "Ho": 164.930, "Er": 167.259, "Tm": 168.934, "Yb": 173.054,
            "Lu": 174.967, "Hf": 178.49, "Ta": 180.948, "W": 183.84, "Re": 186.207,
            "Os": 190.23, "Ir": 192.217, "Pt": 195.084, "Au": 196.967, "Hg": 200.59,
            "Tl": 204.383, "Pb": 207.2, "Bi": 208.980, "Po": 209.0, "At": 210.0,
            "Rn": 222.0, "Fr": 223.0, "Ra": 226.0, "Ac": 227.0, "Th": 232.038,
            "Pa": 231.036, "U": 238.029,
        }
        return masses.get(element, 1.0)
    
    def _scan_available_pseudopotentials(self):
        """Scan the pseudopotential directory for available files."""
        self.available_pseudopotentials = {}
        
        if not self.pseudo_dir.exists():
            return
            
        for pseudo_file in self.pseudo_dir.glob("*.UPF"):
            # Try to extract element from filename
            filename = pseudo_file.name
            # Common patterns: Element.description.UPF or Element_description.UPF
            match = re.match(r'^([A-Z][a-z]?)[\._-]', filename)
            if match:
                element = match.group(1)
                if element not in self.available_pseudopotentials:
                    self.available_pseudopotentials[element] = []
                self.available_pseudopotentials[element].append(filename)
    
    def get_available_pseudopotentials(self) -> Dict[str, List[str]]:
        """Get all available pseudopotentials grouped by element."""
        return self.available_pseudopotentials
    
    def select_pseudopotential(self, element: str, preferred: Optional[str] = None) -> str:
        """Select appropriate pseudopotential for an element."""
        if preferred and (self.pseudo_dir / preferred).exists():
            return preferred
            
        # Check available pseudopotentials
        if element in self.available_pseudopotentials:
            return self.available_pseudopotentials[element][0]
            
        # Fall back to default
        if element in self.default_pseudopotentials:
            return self.default_pseudopotentials[element]
            
        # Last resort - generic name
        return f"{element}.UPF"
    
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
    
    def parse_xyz_structure(self, xyz_content: str) -> Tuple[List[Dict[str, Any]], Optional[List[List[float]]]]:
        """Parse XYZ format structure file.
        
        Returns:
            Tuple of (atoms list, cell_parameters or None)
        """
        lines = xyz_content.strip().split('\n')
        if len(lines) < 3:
            raise ValueError("Invalid XYZ format")
            
        n_atoms = int(lines[0])
        comment = lines[1]
        
        # Try to extract lattice from comment line (extended XYZ format)
        cell_parameters = None
        if 'Lattice=' in comment:
            lattice_match = re.search(r'Lattice="([^"]+)"', comment)
            if lattice_match:
                lattice_values = list(map(float, lattice_match.group(1).split()))
                if len(lattice_values) == 9:
                    cell_parameters = [
                        lattice_values[0:3],
                        lattice_values[3:6],
                        lattice_values[6:9]
                    ]
        
        atoms = []
        for i in range(2, min(2 + n_atoms, len(lines))):
            parts = lines[i].split()
            if len(parts) >= 4:
                element = parts[0]
                position = [float(parts[1]), float(parts[2]), float(parts[3])]
                atoms.append({"element": element, "position": position})
        
        if len(atoms) != n_atoms:
            raise ValueError(f"Expected {n_atoms} atoms but found {len(atoms)}")
            
        return atoms, cell_parameters
    
    def parse_cif_structure(self, cif_content: str) -> Tuple[List[Dict[str, Any]], List[List[float]]]:
        """Parse CIF format structure file.
        
        Returns:
            Tuple of (atoms list, cell_parameters)
        """
        # Simple CIF parser - handles basic cases
        lines = cif_content.strip().split('\n')
        
        # Extract cell parameters
        cell_params = {}
        for param in ['_cell_length_a', '_cell_length_b', '_cell_length_c',
                     '_cell_angle_alpha', '_cell_angle_beta', '_cell_angle_gamma']:
            for line in lines:
                if line.strip().startswith(param):
                    value = line.split()[1].replace('(', '').replace(')', '')
                    cell_params[param] = float(value)
        
        if len(cell_params) != 6:
            raise ValueError("Could not extract all cell parameters from CIF")
        
        # Convert to Cartesian coordinates
        a = cell_params['_cell_length_a']
        b = cell_params['_cell_length_b']
        c = cell_params['_cell_length_c']
        alpha = cell_params['_cell_angle_alpha'] * 3.14159265359 / 180.0
        beta = cell_params['_cell_angle_beta'] * 3.14159265359 / 180.0
        gamma = cell_params['_cell_angle_gamma'] * 3.14159265359 / 180.0
        
        import math
        
        # Calculate cell vectors
        cell_parameters = []
        cell_parameters.append([a, 0.0, 0.0])
        cell_parameters.append([b * math.cos(gamma), b * math.sin(gamma), 0.0])
        
        cx = c * math.cos(beta)
        cy = c * (math.cos(alpha) - math.cos(beta) * math.cos(gamma)) / math.sin(gamma)
        cz = math.sqrt(c * c - cx * cx - cy * cy)
        cell_parameters.append([cx, cy, cz])
        
        # Extract atomic positions
        atoms = []
        in_positions = False
        position_columns = {}
        
        for i, line in enumerate(lines):
            if '_atom_site_' in line:
                in_positions = True
                if '_atom_site_type_symbol' in line or '_atom_site_label' in line:
                    position_columns['symbol'] = len([l for l in lines[i-5:i+1] if '_atom_site_' in l]) - 1
                elif '_atom_site_fract_x' in line:
                    position_columns['x'] = len([l for l in lines[i-5:i+1] if '_atom_site_' in l]) - 1
                elif '_atom_site_fract_y' in line:
                    position_columns['y'] = len([l for l in lines[i-5:i+1] if '_atom_site_' in l]) - 1
                elif '_atom_site_fract_z' in line:
                    position_columns['z'] = len([l for l in lines[i-5:i+1] if '_atom_site_' in l]) - 1
            elif in_positions and line.strip() and not line.strip().startswith('_'):
                parts = line.split()
                if len(parts) > max(position_columns.values()):
                    element = parts[position_columns.get('symbol', 0)]
                    # Remove numbers from element symbol
                    element = ''.join(c for c in element if c.isalpha())
                    
                    # Get fractional coordinates
                    fract_x = float(parts[position_columns['x']].replace('(', '').replace(')', ''))
                    fract_y = float(parts[position_columns['y']].replace('(', '').replace(')', ''))
                    fract_z = float(parts[position_columns['z']].replace('(', '').replace(')', ''))
                    
                    # Convert to Cartesian
                    x = fract_x * cell_parameters[0][0] + fract_y * cell_parameters[1][0] + fract_z * cell_parameters[2][0]
                    y = fract_x * cell_parameters[0][1] + fract_y * cell_parameters[1][1] + fract_z * cell_parameters[2][1]
                    z = fract_x * cell_parameters[0][2] + fract_y * cell_parameters[1][2] + fract_z * cell_parameters[2][2]
                    
                    atoms.append({"element": element, "position": [x, y, z]})
            elif in_positions and (line.strip().startswith('_') or line.strip().startswith('#')):
                in_positions = False
        
        return atoms, cell_parameters
    
    def import_structure(self, file_content: str, file_format: str) -> Dict[str, Any]:
        """Import structure from various file formats.
        
        Args:
            file_content: Content of the structure file
            file_format: Format of the file ('xyz', 'cif', 'poscar')
            
        Returns:
            Dictionary with 'atoms' and 'cell_parameters'
        """
        file_format = file_format.lower()
        
        if file_format == 'xyz':
            atoms, cell_parameters = self.parse_xyz_structure(file_content)
            # If no cell parameters in XYZ, create a box
            if cell_parameters is None:
                # Find extent of atoms and add padding
                if atoms:
                    x_coords = [a['position'][0] for a in atoms]
                    y_coords = [a['position'][1] for a in atoms]
                    z_coords = [a['position'][2] for a in atoms]
                    
                    padding = 10.0  # Angstroms
                    cell_parameters = [
                        [max(x_coords) - min(x_coords) + padding, 0.0, 0.0],
                        [0.0, max(y_coords) - min(y_coords) + padding, 0.0],
                        [0.0, 0.0, max(z_coords) - min(z_coords) + padding]
                    ]
                else:
                    cell_parameters = [[10.0, 0.0, 0.0], [0.0, 10.0, 0.0], [0.0, 0.0, 10.0]]
                    
        elif file_format == 'cif':
            atoms, cell_parameters = self.parse_cif_structure(file_content)
            
        else:
            raise ValueError(f"Unsupported file format: {file_format}")
            
        return {
            "atoms": atoms,
            "cell_parameters": cell_parameters
        }