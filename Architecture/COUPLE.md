# COUPLE Module Documentation

## Overview

The COUPLE module provides a library interface to Quantum ESPRESSO, allowing external programs to call QE codes (PWscf and CPV) as subroutines rather than standalone executables. This is particularly useful for building hybrid parallel programs where multiple executables or multiple copies of the same executable share a single MPI communicator and need to exchange information during runtime.

The module was developed by Axel Kohlmeyer and provides C/C++ and Fortran bindings to integrate QE calculations into larger computational workflows, such as QM/MM simulations or other multi-scale modeling applications.

## Directory Structure

```
COUPLE/
├── CMakeLists.txt      # CMake build configuration
├── Makefile            # Traditional Makefile
├── README              # Basic module description
├── include/            # Public header files
│   └── libqecouple.h   # C/C++ API definitions
├── src/                # Source code
│   ├── Makefile        # Source directory Makefile
│   ├── libpwscf.f90    # PWscf library interface
│   ├── libcpv.f90      # CPV library interface
│   └── libqemod.f90    # QM/MM interface utilities
├── examples/           # Example programs
│   ├── README          # Examples documentation
│   ├── Makefile.gfortran  # GNU compiler makefile
│   ├── Makefile.ifort     # Intel compiler makefile
│   ├── c2pw.cpp        # C++ PWscf example
│   ├── f2pw.f90        # Fortran PWscf example
│   ├── c2cp.cpp        # C++ CPV example
│   └── f2cp.f90        # Fortran CPV example
└── tests/              # Test suite
    ├── check-couple.j  # Test runner script
    ├── clean_all       # Cleanup script
    └── *.ref, *.in     # Reference outputs and input files
```

## Key Source Files

### libpwscf.f90
Provides the library interface to PWscf (Plane Wave Self-Consistent Field) calculations:
- `c2libpwscf`: C wrapper function that converts C data types to Fortran
- `f2libpwscf`: Main Fortran interface that:
  - Initializes MPI environment with custom communicator
  - Sets up parallel execution parameters (pools, bands, task groups)
  - Reads input file and launches PWscf calculation
  - Handles cleanup and returns exit status

### libcpv.f90
Provides the library interface to CPV (Car-Parrinello) molecular dynamics:
- `c2libcpv`: C wrapper function for C/C++ compatibility
- `f2libcpv`: Main Fortran interface that:
  - Configures MPI parallelization
  - Initializes CP environment
  - Reads input and pseudopotential files
  - Executes CP main loop
  - Returns calculation status

### libqemod.f90
Utility functions for QM/MM (Quantum Mechanics/Molecular Mechanics) coupling:
- `c2qmmm_mpi_config`: C wrapper for QM/MM MPI configuration
- `f2qmmm_mpi_config`: Fortran interface for setting up QM/MM communication
- Configures inter-program MPI communicators for QM/MM calculations

### libqecouple.h
C/C++ header file defining the public API:
- API version control (QE_LIBCOUPLE_API_VERSION)
- Function prototypes for PWscf and CPV interfaces
- QM/MM configuration functions
- Proper C/C++ compatibility with extern "C" declarations

## Core Functionality

### Main Subroutines and Functions

1. **PWscf Interface**:
   - Accepts MPI communicator and parallelization parameters
   - Supports image parallelization (nimage)
   - Configures k-point pools (npool)
   - Sets up band groups (nband) and task groups (ntg)
   - Manages linear algebra parallelization (ndiag)

2. **CPV Interface**:
   - Similar parallelization options as PWscf
   - Additional support for plugin systems
   - Handles Car-Parrinello specific initialization

3. **QM/MM Interface**:
   - Configures inter-program MPI communication
   - Sets verbosity and operation mode
   - Manages step synchronization between QM and MM codes

### Key Algorithms Implemented

- MPI communicator splitting and management
- Input file parsing and distribution across MPI ranks
- Environment initialization with custom parallel configurations
- Proper cleanup and resource deallocation

### Data Structures Used

- MPI communicators for hierarchical parallelization
- Input parameter structures from QE modules
- Environment and parallel configuration data

## Dependencies

The COUPLE module depends on several QE modules:

- **Modules/** directory:
  - `environment`: Environment initialization
  - `mp_global`: Global MPI management
  - `read_input`: Input file parsing
  - `command_line_options`: Command line parameter handling
  - `qmmm`: QM/MM interface utilities
  - `mp_pools`, `mp_bands`, `mp_images`: Parallel distribution

- **UtilXlib/**:
  - `parallel_include`: MPI definitions
  - `laxlib`: Linear algebra parallelization

- **PW/** and **CPV/**:
  - Core calculation routines (run_pwscf, cpr_loop)
  - Input processing modules

## Build System

### Traditional Make Build
- Main Makefile delegates to src/Makefile
- Requires QE to be built first (dependencies: pw, cp)
- Creates static library `libqecouple.a`
- Example programs have separate makefiles for different compilers

### CMake Build
- Defines `qe_couple` library target
- Links against required QE libraries (modules, lax, fftx, cpv)
- Installs public header to include directory
- Supports CUDA Fortran if enabled
- Creates build target named "couple"

### Compilation Process
1. Build dependencies (pw and cp modules)
2. Compile Fortran sources with proper module paths
3. Create static library archive
4. Optionally build example programs

The module integrates seamlessly with both QE's traditional Make system and the newer CMake build system, allowing it to be used in various build configurations.