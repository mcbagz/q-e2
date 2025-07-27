"""Test script for Phase 2 backend features."""

import requests
import json
import time

# Base URL for the API
BASE_URL = "http://localhost:8009"

def test_pseudopotentials_endpoint():
    """Test the pseudopotentials listing endpoint."""
    print("\n=== Testing Pseudopotentials Endpoint ===")
    
    response = requests.get(f"{BASE_URL}/api/pseudopotentials/")
    if response.status_code == 200:
        data = response.json()
        print(f"Found pseudopotentials for {len(data)} elements")
        # Show a few examples
        for element in list(data.keys())[:5]:
            print(f"  {element}: default={data[element]['default']}, available={len(data[element]['available'])} files")
    else:
        print(f"Error: {response.status_code} - {response.text}")

def test_structure_import():
    """Test structure import functionality."""
    print("\n=== Testing Structure Import ===")
    
    # Test XYZ format
    xyz_content = """3
Water molecule
O    0.000000    0.000000    0.000000
H    0.757000    0.586000    0.000000
H   -0.757000    0.586000    0.000000
"""
    
    files = {'file': ('water.xyz', xyz_content, 'text/plain')}
    data = {'file_format': 'xyz'}
    
    response = requests.post(f"{BASE_URL}/api/simulations/import-structure", files=files, data=data)
    if response.status_code == 200:
        result = response.json()
        print(f"Successfully imported XYZ structure:")
        print(f"  Atoms: {len(result['atoms'])}")
        print(f"  Cell parameters: {result['cell_parameters'][0]}")
    else:
        print(f"Error: {response.status_code} - {response.text}")

def test_auto_optimize_simulation():
    """Test creating a simulation with AUTO_OPTIMIZE."""
    print("\n=== Testing AUTO_OPTIMIZE Simulation ===")
    
    simulation_data = {
        "prefix": "test_auto_opt",
        "outdir": "/tmp/test_auto_opt",
        "calculation_type": "scf",
        "atoms": [
            {"element": "Si", "position": [0.0, 0.0, 0.0]},
            {"element": "Si", "position": [1.3575, 1.3575, 1.3575]}
        ],
        "cell_parameters": [
            [2.715, 2.715, 0.0],
            [2.715, 0.0, 2.715],
            [0.0, 2.715, 2.715]
        ],
        "ecutwfc": 30.0,
        "k_points": {"type": "automatic", "grid": [4, 4, 4], "shift": [0, 0, 0]},
        "auto_optimize": {
            "k_points": True,
            "k_min": 2,
            "k_max": 8,
            "k_step": 2,
            "ecutwfc": True,
            "ecutwfc_min": 20,
            "ecutwfc_max": 50,
            "ecutwfc_step": 10,
            "convergence_threshold": 0.01
        }
    }
    
    response = requests.post(f"{BASE_URL}/api/simulations/", json=simulation_data)
    if response.status_code == 200:
        result = response.json()
        print(f"Successfully created simulation with AUTO_OPTIMIZE:")
        print(f"  ID: {result['id']}")
        print(f"  Prefix: {result['prefix']}")
        
        # Check the generated input file
        if 'input_file' in result and result['input_file']:
            print("\nGenerated input file preview:")
            lines = result['input_file'].split('\n')
            # Show AUTO_OPTIMIZE section
            for i, line in enumerate(lines):
                if '&AUTO_OPTIMIZE' in line:
                    for j in range(i, min(i+10, len(lines))):
                        print(f"  {lines[j]}")
                    break
    else:
        print(f"Error: {response.status_code} - {response.text}")

def test_advanced_parameters():
    """Test creating a simulation with advanced QE parameters."""
    print("\n=== Testing Advanced Parameters ===")
    
    simulation_data = {
        "prefix": "test_advanced",
        "outdir": "/tmp/test_advanced",
        "calculation_type": "relax",
        "atoms": [
            {"element": "C", "position": [0.0, 0.0, 0.0]},
            {"element": "O", "position": [1.2, 0.0, 0.0], "fixed": [False, True, True]}  # Fix Y and Z
        ],
        "cell_parameters": [
            [10.0, 0.0, 0.0],
            [0.0, 10.0, 0.0],
            [0.0, 0.0, 10.0]
        ],
        "ecutwfc": 45.0,
        "ecutrho": 180.0,
        "k_points": {"type": "gamma"},
        "qe_params": {
            "nspin": 2,
            "starting_magnetization": {"C": 0.0, "O": 0.1},
            "occupations": "smearing",
            "smearing": "gaussian",
            "degauss": 0.02,
            "mixing_mode": "local-TF",
            "diagonalization": "davidson",
            "ion_dynamics": "bfgs",
            "forc_conv_thr": 1e-3
        }
    }
    
    response = requests.post(f"{BASE_URL}/api/simulations/", json=simulation_data)
    if response.status_code == 200:
        result = response.json()
        print(f"Successfully created simulation with advanced parameters:")
        print(f"  ID: {result['id']}")
        print(f"  Type: {result['calculation_type']}")
        
        # Check the generated input file
        if 'input_file' in result and result['input_file']:
            print("\nGenerated input file preview (first 30 lines):")
            lines = result['input_file'].split('\n')
            for i, line in enumerate(lines[:30]):
                print(f"  {line}")
    else:
        print(f"Error: {response.status_code} - {response.text}")

def test_custom_pseudopotentials():
    """Test creating a simulation with custom pseudopotentials."""
    print("\n=== Testing Custom Pseudopotentials ===")
    
    simulation_data = {
        "prefix": "test_custom_pseudo",
        "outdir": "/tmp/test_custom_pseudo", 
        "calculation_type": "scf",
        "atoms": [
            {"element": "Fe", "position": [0.0, 0.0, 0.0]},
            {"element": "O", "position": [2.0, 0.0, 0.0]}
        ],
        "cell_parameters": [
            [4.0, 0.0, 0.0],
            [0.0, 4.0, 0.0],
            [0.0, 0.0, 4.0]
        ],
        "pseudopotentials": {
            "Fe": "Fe.pbe-spn-kjpaw_psl.1.0.0.UPF",
            "O": "O.pbe-n-kjpaw_psl.1.0.0.UPF"
        },
        "ecutwfc": 60.0,
        "ecutrho": 480.0,
        "qe_params": {
            "nspin": 2,
            "starting_magnetization": {"Fe": 0.7, "O": 0.0}
        }
    }
    
    response = requests.post(f"{BASE_URL}/api/simulations/", json=simulation_data)
    if response.status_code == 200:
        result = response.json()
        print(f"Successfully created simulation with custom pseudopotentials:")
        print(f"  ID: {result['id']}")
        
        # Check atomic species section
        if 'input_file' in result and result['input_file']:
            print("\nAtomic species section:")
            lines = result['input_file'].split('\n')
            in_species = False
            for line in lines:
                if 'ATOMIC_SPECIES' in line:
                    in_species = True
                elif in_species and ('ATOMIC_POSITIONS' in line or 'CELL_PARAMETERS' in line):
                    break
                elif in_species:
                    print(f"  {line}")
    else:
        print(f"Error: {response.status_code} - {response.text}")

if __name__ == "__main__":
    print("Testing Phase 2 Backend Features")
    print("=" * 50)
    
    # Run tests
    test_pseudopotentials_endpoint()
    test_structure_import()
    test_auto_optimize_simulation()
    test_advanced_parameters()
    test_custom_pseudopotentials()
    
    print("\n" + "=" * 50)
    print("Phase 2 testing complete!")