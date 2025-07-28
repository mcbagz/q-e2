# CPV Module Documentation

## Overview

The CPV (Car-Parrinello Velocities) module is a core component of Quantum ESPRESSO that implements Car-Parrinello molecular dynamics (CPMD) simulations. This module enables ab initio molecular dynamics calculations where both electronic and ionic degrees of freedom evolve simultaneously according to classical equations of motion.

Key capabilities include:
- Car-Parrinello molecular dynamics with fictitious electron dynamics
- Variable-cell dynamics (NPT ensemble)
- Born-Oppenheimer molecular dynamics
- Ensemble DFT calculations
- Wannier function calculations
- Electric field and Berry phase calculations
- Support for ultrasoft pseudopotentials and PAW
- Hybrid functional calculations with exact exchange (EXX)
- Meta-GGA functionals
- GPU acceleration via CUDA Fortran and OpenACC

The module is based on the original code by Roberto Car and Michele Parrinello, with extensive contributions from the Quantum ESPRESSO community.

## Directory Structure

```
CPV/
├── src/              # Main source code directory
├── Doc/              # Documentation files
├── examples/         # Example calculations and test cases
├── Ford/             # Documentation for automatic code documentation
├── CMakeLists.txt    # CMake build configuration
└── Makefile          # Main makefile
```

### Subdirectory Details:

**src/** - Contains all Fortran 90 source files implementing the CP dynamics algorithms

**Doc/** - Documentation including:
- INPUT_CP.def/html/txt - Input file documentation for cp.x
- INPUT_CPPP.def/html/txt - Input documentation for postprocessing
- user_guide.md - User guide in Markdown format
- autopilot_guide.md - Guide for using the autopilot feature

**examples/** - Working examples demonstrating various features:
- example01-09: Basic CP dynamics examples
- EXX-wf-example: Exact exchange with Wannier functions
- Extffield_example: External electric field calculations
- Restart_example: Restarting calculations
- autopilot-example: Autopilot feature demonstration

## Key Source Files

### Core Program Files:
- **cpr.f90** - Main CP molecular dynamics loop (cprmain subroutine)
- **cprstart.f90** - Main program entry point for cp.x
- **cppp.f90** - Postprocessing program for CP calculations
- **wfdd.f90** - Wannier function damped dynamics utility
- **manycp.f90** - Multiple concurrent CP calculations

### Initialization and Setup:
- **init.f90** - Initialize dimensions, G-vectors, FFT grids
- **init_run.f90** - Initialize run parameters and variables
- **input.f90** - Input file parsing and validation
- **fromscra.f90** - Initialize from scratch calculations

### Electronic Structure:
- **electrons.f90** - Electronic minimization and dynamics
- **move_electrons.f90** - Electron position updates
- **electrons_nose.f90** - Nosé thermostat for electrons
- **wave.f90**, **wave_base.f90** - Wavefunction handling
- **cp_wavefunctions.f90** - CP-specific wavefunction routines

### Forces and Dynamics:
- **forces.f90** - Force calculations
- **newd.f90** - Non-local pseudopotential contributions
- **ions_positions.f90** - Ion position updates and constraints
- **cpr_loop.f90** - Main dynamics loop implementation

### Energy Calculations:
- **energies.f90** - Total energy components
- **exx_*.f90** - Exact exchange implementation files
- **exch_corr.f90** - Exchange-correlation functionals
- **metaxc.f90** - Meta-GGA functionals

### Cell Dynamics:
- **cell_base.f90** dependencies - Unit cell parameters
- **stress.f90** - Stress tensor calculations
- **cell_nose.f90** dependencies - Cell Nosé-Hoover thermostat

### Special Features:
- **efield.f90** - Electric field implementation
- **berry*.f90** - Berry phase calculations
- **wannier.f90**, **wannier_base.f90** - Wannier function calculations
- **ensemble_dft.f90** - Ensemble DFT implementation
- **ldaU*.f90** - DFT+U implementation
- **sic.f90** - Self-interaction correction

### Utilities:
- **restart.f90**, **restart_sub.f90** - Checkpoint/restart functionality
- **cp_restart_new.f90** - New restart format implementation
- **print_out.f90** - Output routines
- **cp_autopilot.f90** - Autopilot feature for parameter changes

### Parallelization:
- **ortho.f90**, **ortho_base.f90** - Orthogonalization (parallel)
- **nl_base.f90** - Non-local operations base routines

## Core Functionality

### Main Subroutines and Functions:

1. **cprmain** (cpr.f90) - Main molecular dynamics loop that:
   - Updates electronic wavefunctions
   - Calculates forces on ions
   - Propagates ionic positions
   - Handles thermostats and barostats
   - Manages I/O and checkpointing

2. **move_electrons** - Electronic minimization using:
   - Steepest descent
   - Conjugate gradient
   - Damped dynamics
   - Verlet algorithm for CPMD

3. **forces** - Computes forces from:
   - Local pseudopotentials
   - Non-local pseudopotentials  
   - Hartree potential
   - Exchange-correlation
   - Ion-ion interactions

### Key Algorithms:

- **Car-Parrinello Lagrangian**: Extended Lagrangian including fictitious electronic kinetic energy
- **Nosé-Hoover thermostats**: For both ionic and electronic degrees of freedom
- **Parrinello-Rahman dynamics**: Variable cell shape MD
- **Orthogonalization**: Gram-Schmidt and parallel algorithms
- **Wannier functions**: Damped dynamics and minimization
- **Berry phase**: Modern theory of polarization implementation

### Data Structures:

- Wave function arrays distributed across processors
- Real and reciprocal space grids (FFT grids)
- Pseudopotential data structures
- Force and stress tensor arrays
- Thermostat chain variables
- Cell dynamics variables

## Dependencies

The CPV module depends on several other Quantum ESPRESSO modules:

### Core QE Modules:
- **Modules/** - Base modules for kinds, constants, parameters
- **FFTXlib/** - FFT libraries and grid management
- **LAXlib/** - Linear algebra routines (parallel)
- **UtilXlib/** - Utility functions and MPI wrappers
- **upflib/** - Pseudopotential I/O and processing

### Shared Components:
- **KS_Solvers/** - Kohn-Sham solvers (some shared routines)
- Common modules for:
  - ions_base - Ion-related base quantities
  - cell_base - Cell parameters and operations
  - fft_base - FFT grid definitions
  - uspp - Ultrasoft pseudopotential routines
  - control_flags - Global control variables

### External Libraries:
- BLAS/LAPACK - Linear algebra
- MPI - Parallel communication
- FFTW or internal FFT - Fast Fourier transforms
- CUDA (optional) - GPU acceleration

## Build System

The CPV module uses a Makefile-based build system integrated with Quantum ESPRESSO's build infrastructure:

### Main Build Files:
- **Makefile** - Top-level makefile that calls src/Makefile
- **src/Makefile** - Compiles all source files and creates executables
- **CMakeLists.txt** - Alternative CMake build configuration

### Build Process:
1. Inherits configuration from QE's make.inc
2. Compiles all .f90 files to object files
3. Creates static library libcp.a
4. Links executables: cp.x, cppp.x, wfdd.x, manycp.x
5. Installs executables in ../../bin/

### Compilation Flags:
- Uses MODFLAGS for module paths
- Links against QEMODS (QE base modules)
- Links against QELIBS (QE libraries)
- Supports OpenMP and MPI parallelization
- Optional GPU flags for CUDA compilation

### Build Commands:
```bash
make cp          # Build from main QE directory
make             # Build from CPV directory  
make clean       # Clean build files
make doc         # Build documentation
```

The build system automatically handles dependencies and module compilation order through the QE build infrastructure.