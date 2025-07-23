# XSpectra Module Documentation

## Overview

XSpectra is a post-processing module in Quantum ESPRESSO for calculating X-ray Absorption Spectroscopy (XAS) spectra. It computes X-ray absorption near-edge structure (XANES) at various absorption edges (K, L1, L2, L3) using the Lanczos algorithm and continued fraction approach. The module can handle both electric dipole and electric quadrupole transitions and includes support for core-hole effects through specialized pseudopotentials.

Key features:
- Calculates X-ray absorption spectra without explicit computation of empty states
- Supports K-edge and L-edge (L1, L2, L3) calculations
- Implements both dipole and quadrupole transitions
- Uses PAW (Projector Augmented Wave) reconstruction
- Supports DFT+U calculations and collinear magnetism
- Compatible with ultrasoft pseudopotentials

## Directory Structure

```
XSpectra/
├── CMakeLists.txt          # CMake build configuration
├── Makefile               # Main makefile
├── README                 # Basic module information and citations
├── Doc/                   # Documentation directory
│   ├── INPUT_XSPECTRA     # Main input documentation
│   ├── INPUT_MOLECULARNEXAFS
│   ├── INPUT_SPECTRA_CORRECTION
│   └── INPUT_SPECTRA_MANIPULATION
├── src/                   # Source code directory
│   ├── Makefile          # Source makefile
│   └── *.f90, *.f, *.c  # Source files
├── examples/              # Example calculations
│   ├── pseudo/           # Example pseudopotentials
│   ├── reference/        # Reference outputs
│   └── run_example_*     # Example run scripts
└── tools/                 # Utility scripts
    └── upf2plotcore.sh   # Extract core wavefunctions from UPF

```

## Key Source Files

### Core Program Files
- **xspectra.f90**: Main program file that coordinates the XAS calculation
- **molecularnexafs.f90**: Specialized program for molecular NEXAFS calculations
- **spectra_correction.f90**: Post-processing tool for spectra manipulation

### Main Modules
- **xspectra_mod.f90**: Central module containing key variables and parameters for XAS calculations
- **gaunt_mod.f90**: Module for Gaunt coefficients used in angular momentum coupling
- **radin_mod.f90**: Radial integration routines
- **paw_gipaw.f90**: PAW-GIPAW reconstruction routines

### Calculation Routines
- **xanes_dipole.f90**: Calculates dipole matrix elements for K-edge XAS
- **xanes_dipole_general_edge.f90**: Generalized dipole calculations for L-edges
- **xanes_quadrupole.f90**: Quadrupole transition calculations
- **lanczos.f90**: Implementation of Lanczos algorithm for spectral calculations

### Utility Functions
- **read_input_and_bcast.f90**: Input file parsing and MPI broadcasting
- **set_xspectra_namelists_defaults.f90**: Default parameter initialization
- **plot_xanes_cross_sections.f90**: Spectrum plotting routines
- **io_routines.f90**: I/O utilities for save files and restart
- **stdout_routines.f90**: Output formatting utilities

### Initialization and Setup
- **init_gipaw_1.f90**, **init_gipaw_2.f90**: GIPAW initialization
- **select_nl_init.f90**: Selection of initial state quantum numbers
- **assign_paw_radii_to_species.f90**: PAW radius assignment
- **check_orthogonality_k_epsilon.f90**: Orthogonality checks

### Other Important Files
- **lr_sm1_psi.f90**: Linear response calculations
- **ipoolscatter.f90**: MPI pool communication routines
- **mygetK.f90**: K-point handling
- **read_k_points.f90**: K-point input routines
- **reset_k_points_and_reinit.f90**: K-point reinitialization

## Core Functionality

### Main Subroutines and Functions

1. **X_Spectra (main program)**
   - Reads input parameters and initializes calculation
   - Sets up PAW projectors and reconstructs all-electron wavefunctions
   - Calls appropriate edge-specific calculation routines
   - Manages Lanczos iterations and convergence

2. **xanes_dipole**
   - Calculates dipole matrix elements for XAS
   - Implements selection rules for dipole transitions
   - Handles core-valence transitions

3. **xanes_quadrupole**
   - Computes quadrupole contributions (K and L1 edges only)
   - Implements quadrupole selection rules

4. **lanczos**
   - Performs Lanczos recursion to build tridiagonal representation
   - Calculates continued fraction for spectral function
   - Manages convergence criteria

### Key Algorithms Implemented

- **Lanczos Algorithm**: Iterative method to calculate absorption spectra without computing all empty states
- **Continued Fraction**: Efficient representation of the spectral function
- **PAW Reconstruction**: Reconstructs all-electron wavefunctions from pseudopotential calculations
- **Core-hole Approximation**: Uses specialized pseudopotentials with core holes

### Data Structures Used

- **xspectra module**: Contains main calculation parameters (energy range, broadening, etc.)
- **paw_gipaw module**: PAW projector and reconstruction data
- **cut_valence_green module**: Green's function calculation parameters
- **xspectra_paw_variables**: PAW-specific variables for XAS

## Dependencies

XSpectra depends on several Quantum ESPRESSO modules:

### Core QE Modules
- **PW (PWscf)**: Requires prior SCF calculation for charge density
- **Modules**: Basic QE infrastructure (kinds, constants, io_global, etc.)
- **KS_Solvers**: Kohn-Sham equation solvers
- **dft-d3**: DFT-D3 dispersion corrections

### Specific Dependencies
- PAW/GIPAW pseudopotentials with reconstruction information
- Core wavefunctions (extracted from pseudopotentials)
- SCF charge density from pw.x calculation
- K-point grids and symmetry information

## Build System

### Compilation
XSpectra is compiled as part of the Quantum ESPRESSO distribution:

1. **Standard compilation**: 
   ```bash
   make xspectra
   ```
   from the main QE directory

2. **Executables produced**:
   - `xspectra.x`: Main XAS calculation program
   - `spectra_correction.x`: Post-processing tool
   - `molecularnexafs.x`: Molecular NEXAFS calculations

3. **Build dependencies**:
   - Requires prior compilation of PW and base modules (`make pwlibs`)
   - Links against libpw.a, libks_solvers.a, and libdftd3qe.a
   - Uses Fortran 90 compiler with MPI support

### Makefile Structure
- Main Makefile delegates to src/Makefile
- Object files are organized into XOBJS (main XSpectra objects) and GIPAWOBJS (GIPAW-specific objects)
- Executables are automatically linked to the bin/ directory

### Module Dependencies
The build system ensures proper compilation order through make.depend, handling complex module interdependencies in the Fortran code.