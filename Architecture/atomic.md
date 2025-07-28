# atomic Module Documentation

## Overview

The atomic module in Quantum ESPRESSO is a comprehensive package for atomic calculations and pseudopotential generation. Originally based on the ld1 code by P. Giannozzi, it has been extended with contributions from Andrea Dal Corso (SISSA, Trieste) and others. The module performs three main types of calculations:

1. **All-electron atomic calculations** - Solves the radial Schrödinger equation for isolated atoms
2. **Pseudopotential generation** - Creates norm-conserving (NC) and ultrasoft (US) pseudopotentials using various recipes
3. **Pseudopotential testing** - Validates generated pseudopotentials by comparing with all-electron results

The code supports:
- Norm-conserving and ultrasoft pseudopotentials with the Rappe-Rabe-Kaxiras-Joannopoulos (RRKJ) recipe
- Fully relativistic pseudopotentials including spin-orbit coupling
- PAW (Projector Augmented Wave) dataset generation
- Multiple electronic configurations
- Van der Waals C6 coefficient calculations
- LDA+1/2 corrections to pseudopotentials

## Directory Structure

```
atomic/
├── src/                    # Source code files
├── Doc/                    # Documentation and manuals
├── examples/               # Example calculations
│   ├── all-electron/      # All-electron calculation examples
│   ├── paw_examples/      # PAW dataset generation examples
│   ├── pseudo-gen/        # Pseudopotential generation examples
│   ├── pseudo-test/       # Pseudopotential testing examples
│   ├── pseudo-LDA-0.5/    # LDA+1/2 examples
│   └── vdw-in-tfvw/       # Van der Waals calculations
├── pseudo_library/         # Input files for pseudopotential generation
│   ├── LDA/               # LDA pseudopotentials
│   │   ├── SR/           # Scalar-relativistic
│   │   └── REL/          # Fully relativistic
│   └── PBE/               # PBE pseudopotentials
│       ├── SR/           # Scalar-relativistic
│       └── REL/          # Fully relativistic
├── Makefile               # Main build file
├── CMakeLists.txt         # CMake build configuration
├── README                 # Basic module information
└── KLI.md                 # KLI approximation notes

```

## Key Source Files

### Main Program
- **ld1.f90** - Main driver program that coordinates all calculations based on the `iswitch` parameter:
  - `iswitch=1`: All-electron calculation
  - `iswitch=2`: Pseudopotential test
  - `iswitch=3`: Pseudopotential generation and test
  - `iswitch=4`: LDA-1/2 correction

### Core Modules
- **ld1inc.f90** - Main module containing global variables and data structures for atomic calculations
- **parameters.f90** - Parameter definitions (max configurations, wavefunctions, etc.)
- **atomic_paw.f90** - PAW-specific routines and conversions between US and PAW
- **paw_type.f90** - PAW data type definitions

### All-Electron Calculation Routines
- **all_electron.f90** - Driver for all-electron atomic calculations
- **scf.f90** - Self-consistent field iteration solver
- **starting_potential.f90** - Initial potential estimation
- **new_potential.f90** - Potential update during SCF
- **v_of_rho_at.f90** - Compute potential from charge density

### Equation Solvers
- **ascheq.f90** - Solves radial Schrödinger equation for all-electron atoms
- **ascheqps.f90** - Solves radial Schrödinger equation for pseudopotentials
- **lschps.f90** - Solves radial Schrödinger equation with logarithmic derivatives
- **integrate_outward.f90** - Outward integration of radial equation
- **integrate_inward.f90** - Inward integration of radial equation

### Pseudopotential Generation
- **gener_pseudo.f90** - Main pseudopotential generation routine
- **compute_phi.f90** - Compute pseudo-wavefunctions (general method)
- **compute_phi_tm.f90** - Troullier-Martins pseudo-wavefunctions
- **compute_chi.f90** - Compute auxiliary chi functions
- **pseudovloc.f90** - Generate local pseudopotential
- **compute_potps.f90** - Compute screened pseudopotentials
- **pseudo_q.f90** - Compute Q functions for ultrasoft pseudopotentials

### Testing and Validation
- **run_test.f90** - Test generated pseudopotentials
- **run_pseudo.f90** - Run pseudopotential calculations
- **lderiv.f90** - Compute logarithmic derivatives (all-electron)
- **lderivps.f90** - Compute logarithmic derivatives (pseudo)

### I/O and File Formats
- **ld1_readin.f90** - Read input parameters
- **ld1_setup.f90** - Setup calculations based on input
- **ld1_writeout.f90** - Write final output
- **write_pseudo.f90** - Write pseudopotential in UPF format
- **write_paw_recon.f90** - Write PAW reconstruction data
- **import_upf.f90** - Import UPF format pseudopotentials
- **export_upf.f90** - Export to UPF format

### Special Features
- **run_lda_half.f90** - LDA+1/2 correction implementation
- **c6_tfvw.f90** - Van der Waals C6 coefficient (Thomas-Fermi von Weizsacker)
- **c6_dft.f90** - Van der Waals C6 coefficient (DFT)
- **kli.f90** - Krieger-Li-Iafrate (KLI) approximation
- **sic_correction.f90** - Self-interaction correction
- **compute_relpert.f90** - Relativistic perturbative corrections

## Core Functionality

### Main Subroutines and Functions

1. **all_electron()** - Performs self-consistent all-electron atomic calculation:
   - Computes initial potential estimate
   - Runs SCF iteration to convergence
   - Calculates total energy components
   - Optionally computes relativistic corrections

2. **gener_pseudo()** - Generates pseudopotentials:
   - Constructs pseudo-wavefunctions (phis)
   - Creates nonlocal projectors (betas)
   - Computes pseudopotential coefficients (bmat)
   - Generates augmentation functions for US pseudopotentials (qvan)

3. **scf()** - Self-consistent field solver:
   - Iteratively solves Kohn-Sham equations
   - Updates electron density and potential
   - Checks convergence criteria

### Key Algorithms Implemented

- **Radial Schrödinger Equation Solvers**: Outward/inward integration with matching
- **Troullier-Martins Recipe**: Smooth norm-conserving pseudopotentials
- **RRKJ Method**: Optimized pseudopotentials with multiple projectors
- **PAW Method**: All-electron accuracy with computational efficiency
- **Mixing Schemes**: Anderson mixing for SCF convergence
- **Relativistic Effects**: Scalar and full relativistic calculations

### Data Structures Used

Key arrays and types defined in ld1inc module:
- **psi(ndmx,2,nwfx)** - All-electron wavefunctions (major/minor components)
- **phis(ndmx,nwfsx)** - Pseudo-wavefunctions
- **rho(ndmx,2)** - Electron density (spin-up/down)
- **vnl(ndmx,0:3,2)** - Nonlocal pseudopotential components
- **betas(ndmx,nwfsx)** - Projector functions
- **grid** - Radial grid information (type: radial_grid_type)

## Dependencies

The atomic module depends on several other Quantum ESPRESSO modules:

1. **qe_modules** - Core QE modules including:
   - `kinds` - Precision definitions
   - `radial_grids` - Radial grid management
   - `io_global` - I/O handling
   - `mp` and `mp_global` - MPI parallelization

2. **qe_upflib** - Unified Pseudopotential Format library for reading/writing pseudopotentials

3. **qe_xclib** - Exchange-correlation functionals library

4. **External libraries** (through QE):
   - BLAS/LAPACK - Linear algebra operations
   - MPI - Parallel execution support

## Build System

The atomic module uses two build systems:

### Traditional Make
- Main Makefile in atomic/ directory
- Source-specific Makefile in atomic/src/
- Builds executable `ld1.x` linked to `../../bin/`
- Dependencies managed through `make.depend`

### CMake (Modern)
- CMakeLists.txt defines:
  - Library target: `qe_atomic`
  - Executable target: `qe_atomic_exe` (output: ld1.x)
- Links against QE libraries: qe_upflib, qe_modules, qe_xclib

### Compilation
```bash
# Traditional make
cd atomic
make all

# CMake (from QE build directory)
cmake --build . --target ld1
```

The module integrates with the main Quantum ESPRESSO build system and inherits compiler flags and library paths from the parent configuration.