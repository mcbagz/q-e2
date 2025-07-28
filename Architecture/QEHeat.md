# QEHeat Module Documentation

## Overview

QEHeat is a Quantum ESPRESSO module that calculates ab-initio energy flux (heat current) in materials when atomic velocities are provided in addition to positions. It implements the gauge-invariant approach for thermal transport calculations as described in Marcolongo, Umari, and Baroni, Nat. Phys. 12, 80 (2016).

The module computes energy currents and their individual components (electronic, ionic, etc.) from molecular dynamics trajectories, enabling the calculation of thermal conductivity coefficients from first principles. It was written by Riccardo Bertossa (SISSA) during 2020-2021.

## Directory Structure

```
QEHeat/
├── CMakeLists.txt          # CMake build configuration
├── Makefile                # Main makefile
├── README                  # Basic installation and usage instructions
├── Doc/                    # Documentation directory
│   ├── INPUT_ALL_CURRENTS.def   # Input file definitions
│   ├── INPUT_ALL_CURRENTS.html  # HTML documentation for inputs
│   ├── INPUT_ALL_CURRENTS.txt   # Text documentation
│   ├── Makefile                  # Documentation build makefile
│   └── input_xx.xsl             # XSL stylesheet for documentation
├── examples/               # Example calculations
│   ├── README.md                 # Detailed examples documentation
│   ├── example_H2O_trajectory/   # Water trajectory analysis
│   ├── example_SiO2_single/      # Single snapshot SiO2 calculation
│   ├── example_small_H20_trajectory/  # Small water system with CP
│   └── pseudo/                   # Pseudopotential files
└── src/                    # Source code directory
    ├── Makefile                  # Source build makefile
    └── *.f90                     # Fortran source files
```

## Key Source Files

### Main Program
- **`all_currents.f90`** - Main program that orchestrates all energy current calculations. Implements the workflow for computing various current components.

### Core Modules
- **`kohn_sham_mod.f90`** - Computes the Kohn-Sham contribution to the energy current
- **`hartree_xc_mod.f90`** - Calculates Hartree and exchange-correlation contributions
- **`zero_mod.f90`** - Handles pseudopotential contributions to the current
- **`ionic_mod.f90`** - Computes ionic (Coulomb) contributions

### Utility Modules
- **`scf_result.f90`** - Manages multiple SCF results and wavefunction data
- **`cpv_traj.f90`** - Utilities for reading Car-Parrinello trajectories
- **`traj_object.f90`** - Object-oriented trajectory handling
- **`averages.f90`** - Online averaging utilities for statistical analysis
- **`compute_charge.f90`** - Charge density computation utilities
- **`project.f90`** - Projection operations
- **`ec_functionals.f90`** - Exchange-correlation functional utilities
- **`init_us_3.f90`** - Ultrasoft pseudopotential initialization

### Testing
- **`test_h_psi_s_psi_commutator_Hx_psi.f90`** - Test module for Hamiltonian operations
- **`cpv_traj_test.f90`** - Test program for trajectory reading functionality

## Core Functionality

### Main Subroutines and Functions

1. **Energy Current Calculation**
   - `current_kohn_sham()` - Computes electronic (Kohn-Sham) current contributions
   - `current_hartree_xc()` - Calculates Hartree and XC current components
   - `current_zero()` - Evaluates pseudopotential current terms
   - `current_ionic()` - Computes ionic current contributions

2. **Trajectory Processing**
   - Reads atomic positions and velocities from input or CP trajectories
   - Supports both single snapshot and full trajectory analysis
   - Handles velocity unit conversions (CP units to atomic units)

3. **Output Components**
   - Total energy current J
   - Electronic current contributions (J_kohn, J_hartree, J_xc)
   - Ionic current (J_ionic)
   - Center of mass velocities by species

### Key Algorithms Implemented

- **Gauge-invariant formulation** for thermal transport
- **Finite difference derivatives** for computing energy flux
- **Three-point derivative schemes** for improved accuracy
- **Online averaging** for trajectory analysis
- **Parallel computation** support via MPI

### Data Structures Used

- `J_all` type - Holds all current components
- `scf_result` - Stores SCF calculation data
- `cpv_trajectory` - Manages trajectory data
- `ionic_init_type` - Ionic initialization data

## Dependencies

QEHeat depends on several Quantum ESPRESSO modules:

1. **PW (PWscf)** - Core plane-wave DFT functionality
2. **PHonon** - Phonon calculations (for certain features)
3. **LR_Modules** - Linear response modules
4. **Modules** - Base QE modules including:
   - FFT interfaces
   - Parallelization (mp_global, mp_pools)
   - Pseudopotential handling
   - Wave function management

External dependencies:
- BLAS/LAPACK libraries
- MPI for parallel execution
- FFTW or compatible FFT library

## Build System

QEHeat uses the standard Quantum ESPRESSO build system:

1. **Configuration**: Uses QE's configure script
2. **Compilation**: 
   ```bash
   make all_currents
   ```
   This builds both `pw.x` (if needed) and `all_currents.x`

3. **Installation**:
   - Executable `all_currents.x` is placed in `QEHeat/src/`
   - Symbolic link created in `bin/` directory

4. **Dependencies**:
   - Automatically builds required QE modules (pw, ph)
   - Links against QE libraries (libpw.a, libph.a, liblrmod.a)

5. **Make targets**:
   - `all` - Build all_currents.x
   - `clean` - Remove object files and executables
   - `doc` - Build documentation
   - `cpv-traj-test` - Build trajectory test program

The build system is integrated with QE's main makefile structure, inheriting compiler flags and library paths from the parent make.inc file generated during configuration.