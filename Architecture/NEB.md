# NEB Module Documentation

## Overview

The NEB (Nudged Elastic Band) module in Quantum ESPRESSO implements methods for finding minimum energy paths and transition states between reactants and products in chemical reactions and phase transitions. It supports two main algorithms:

1. **NEB (Nudged Elastic Band)**: A chain-of-states method that optimizes a series of images along a reaction path while maintaining equal spacing between images through spring forces.

2. **SMD (String Method Dynamics)**: An alternative path optimization method also supported by this module.

The implementation is based on the algorithms described in:
- G. Henkelman, B.P. Uberuaga, and H. Jonsson; J.Chem.Phys., 113, 9901, (2000)
- G. Henkelman, and H. Jonsson; J.Chem.Phys., 113, 9978, (2000)

Additional features include:
- **FCP (Fixed Charge Potential)**: Allows optimization with constrained total charge
- **GCSCF (Grand Canonical SCF)**: Enables calculations at fixed chemical potential
- **ESM (Effective Screening Medium)**: Support for calculations with specific boundary conditions

## Directory Structure

```
NEB/
├── src/                    # Source code files
│   ├── *.f90              # Fortran 90 source files
│   └── Makefile           # Build configuration
├── Doc/                    # Documentation
│   ├── INPUT_NEB.*        # Input file documentation (def, html, txt)
│   ├── user_guide.*       # User guide (tex, pdf)
│   └── Makefile           # Documentation build
├── examples/               # Example calculations
│   ├── example01/         # Basic NEB examples
│   ├── ESM_example/       # ESM-specific examples
│   └── test files         # Test input/reference files
├── tools/                  # Utility scripts
│   ├── path_interpolation.sh
│   └── path_merge.sh
├── Makefile               # Main build file
└── CMakeLists.txt         # CMake build configuration
```

## Key Source Files

### Core NEB Implementation
- **neb.f90**: Main program entry point that coordinates the NEB calculation
- **path_base.f90**: Core module containing the main NEB/SMD algorithm implementation
- **path_variables.f90**: Defines all variables needed for path calculations
- **path_opt_routines.f90**: Optimization algorithms (steepest descent, quick-min, Broyden, Langevin)
- **path_reparametrisation.f90**: Handles reparametrization of the path to maintain image spacing

### Input/Output Handling
- **path_gen_inputs.f90**: Parses input files and generates individual PWscf inputs
- **path_input_parameters_module.f90**: Manages input parameters
- **path_read_namelists_module.f90**: Reads NEB-specific namelists
- **path_read_cards_module.f90**: Reads NEB-specific cards
- **path_io_routines.f90**: General I/O routines for path calculations
- **path_io_tools.f90**: Additional I/O utilities
- **path_formats.f90**: Format specifications for output

### SCF Engine Interface
- **compute_scf.f90**: Main driver for SCF calculations on each image
- **engine_to_path_*.f90**: Functions to transfer data from PWscf to path variables
  - engine_to_path_pos.f90 (atomic positions)
  - engine_to_path_nat.f90 (number of atoms)
  - engine_to_path_alat.f90 (lattice parameter)
  - engine_to_path_fix_atom_pos.f90 (fixed atoms)
  - engine_to_path_tot_charge.f90 (total charge)
- **path_to_engine_fix_atom_pos.f90**: Transfer constraints back to engine

### Special Features
- **fcp_variables.f90**: Variables for Fixed Charge Potential calculations
- **fcp_opt_routines.f90**: Optimization routines for FCP
- **gcscf_variables.f90**: Variables for Grand Canonical SCF
- **bcast_file.f90**: Handles file broadcasting in parallel calculations

### Utilities
- **path_interpolation.f90**: Standalone program for interpolating between images
- **stop_run_path.f90**: Clean termination routines
- **set_defaults.f90**: Default parameter initialization
- **neb_input.f90**: Additional input handling

## Core Functionality

### Main Subroutines and Functions

1. **initialize_path** (path_base.f90)
   - Initializes the path with given number of images
   - Sets up arrays for positions, forces, and energies

2. **search_mep** (path_base.f90)
   - Main driver for Minimum Energy Path search
   - Implements the iterative optimization loop

3. **compute_scf** (compute_scf.f90)
   - Performs SCF calculation for each image
   - Handles parallelization over images
   - Computes forces and energies

4. **Optimization Algorithms** (path_opt_routines.f90)
   - `steepest_descent`: Basic gradient descent
   - `quick_min`: Quick-min algorithm (velocity Verlet with damping)
   - `broyden`/`broyden2`: Quasi-Newton methods
   - `langevin`: Langevin dynamics for finite temperature

### Key Algorithms Implemented

1. **NEB Algorithm**:
   - Optimizes chain of images connected by springs
   - Uses tangent to the path for projecting out perpendicular components
   - Implements climbing image variant for transition state search

2. **String Method**:
   - Alternative to NEB without explicit springs
   - Images evolve according to force projections
   - Reparametrization maintains equal spacing

3. **Path Reparametrization**:
   - Ensures equal spacing between images
   - Uses spline interpolation for smooth paths

### Data Structures Used

- **pos(dim1, num_of_images)**: Atomic positions for all images
- **grad_pes(dim1, num_of_images)**: Potential energy surface gradients
- **pes(num_of_images)**: Potential energies
- **frozen(num_of_images)**: Flags for frozen images
- **tangent(dim1)**: Local tangent to the path

## Dependencies

The NEB module depends on several other QE modules:

1. **PW (PWscf)**: The plane-wave DFT engine
   - Used for electronic structure calculations
   - Provides forces and energies

2. **Modules**: Core QE modules including:
   - `kinds`: Data type definitions
   - `constants`: Physical constants
   - `mp` and `mp_global`: MPI parallelization
   - `io_global`: I/O handling
   - `cell_base`: Unit cell information

3. **KS_Solvers**: Kohn-Sham equation solvers

4. **dft-d3**: Dispersion corrections (optional)

5. **External libraries**:
   - BLAS/LAPACK: Linear algebra
   - MPI: Parallel communication
   - FFT libraries: Fast Fourier transforms

## Build System

### Makefile Build
The module uses a traditional Makefile system:

```makefile
# Main executables
neb.x: Main NEB program
path_interpolation.x: Path interpolation utility

# Library
libneb.a: Static library containing all NEB routines

# Dependencies
- Requires PW modules to be built first
- Links against libpw.a, libks_solvers.a, libdftd3qe.a
```

### CMake Build
Alternative CMake configuration is provided:

```cmake
# Library target
qe_neb: NEB library

# Executable targets
qe_neb_exe -> neb.x
qe_neb_pathinterpolation_exe -> path_interpolation.x

# Installation
Installs both library and executables
```

### Compilation
```bash
# Using make
cd NEB/
make all

# Using CMake
mkdir build && cd build
cmake .. -DQE_ENABLE_NEB=ON
make neb
```

The build system automatically handles:
- Module dependencies
- Fortran module compilation order
- Linking with required QE libraries
- Installation to bin/ directory