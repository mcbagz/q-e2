# PWCOND Module Documentation

## Overview

PWCOND is a Quantum ESPRESSO module that computes ballistic conductance and complex band structures for quantum transport calculations. It implements the method of Choi and Ihm (PRB 59, 2267 (1999)), generalized to ultrasoft pseudopotentials (US-PP). The module calculates:

- **Ballistic conductance** via the Landauer formula (G = e²/h × T)
- **Complex band structure** of periodic systems
- **Transmission coefficients** through scattering regions
- **Scattering states** for quantum transport analysis

The code solves the scattering problem for a system consisting of left lead + scattering region + right lead, computing transmission probabilities for electrons at different energies.

## Directory Structure

```
PWCOND/
├── CMakeLists.txt      # CMake build configuration
├── Makefile            # Main Makefile
├── Doc/                # Documentation files
│   ├── INPUT_PWCOND.def    # Input parameter definitions
│   ├── INPUT_PWCOND.html   # HTML documentation
│   ├── INPUT_PWCOND.txt    # Text documentation
│   └── Makefile            # Documentation build
├── examples/           # Example calculations
│   ├── example01/      # Al bulk, Al wire, Ni bulk, Al wire with H impurity
│   ├── example02/      # Pt calculations with tetrahedra
│   ├── example03/      # Au wire with CO molecule
│   └── run_all_examples
└── src/                # Source code files
```

## Key Source Files

### Main Program and Driver
- **condmain.f90** - Main program entry point for pwcond.x
- **do_cond.f90** - Main driver routine that orchestrates the calculation

### Core Modules
- **condcom.f90** - Common variables and data structures for conductance calculations
  - `geomcell_cond` - Geometry and cell parameters
  - `orbcell_cond` - Orbital descriptions
  - `eigen_cond` - Eigenvalue storage
  - `control_cond` - Control parameters

### Complex Band Structure
- **compbs.f90** - Computes complex band structure of leads
- **compbs_2.f90** - Alternative CBS calculation routine
- **jbloch.f90** - Constructs Bloch states for left tip
- **kbloch.f90** - Constructs Bloch states for right tip
- **summary_band.f90** - Summarizes band structure results

### Scattering and Transmission
- **scatter_forw.f90** - Forward scattering calculation
- **transmit.f90** - Constructs scattering states and calculates transmission
- **eigenchnl.f90** - Eigenvalue channel analysis
- **summary_tran.f90** - Summarizes transmission results

### Initialization and Setup
- **init_cond.f90** - Initializes conductance calculation
- **init_gper.f90** - Initializes perpendicular G-vectors
- **init_orbitals.f90** - Sets up orbital basis
- **allocate_cond.f90** - Memory allocation routines
- **openfil_cond.f90** - Opens necessary files

### Mathematical Routines
- **integrals.f90** - Computes various integrals
- **bessj.f90** - Bessel function calculations
- **four.f90** - Fourier transform utilities
- **gramsh.f90** - Gram-Schmidt orthogonalization
- **gep_x.f90** - Generalized eigenvalue problem solver
- **hev_ab.f90** - Hermitian eigenvalue solver
- **sunitary.f90** - Unitary transformation routines
- **rotproc.f90** - Rotation procedures

### Potential and Hamiltonian
- **poten.f90** - Potential calculations
- **form_zk.f90** - Forms k-dependent matrices
- **plus_u_setup.f90** - Sets up DFT+U calculations
- **realus_scatt.f90** - Real-space ultrasoft PP for scattering region

### I/O and Utilities
- **cond_out.f90** - Output routines
- **cond_restart.f90** - Restart/recovery functionality
- **save_cond.f90** - Saves conductance data
- **local.f90** - Local DOS calculations
- **local_set.f90** - Local DOS setup
- **scat_states_plot.f90** - Plotting scattering states
- **print_clock_pwcond.f90** - Timing information
- **free_mem.f90** - Memory deallocation

## Core Functionality

### Main Subroutines and Functions

1. **do_cond()** - Main driver that:
   - Reads input parameters from namelist
   - Initializes parallel environment
   - Sets up geometry for leads and scattering region
   - Loops over k-points and energies
   - Calls appropriate routines for CBS or transmission

2. **compbs()** - Complex band structure calculation:
   - Constructs generalized eigenvalue problem
   - Finds propagating and evanescent states
   - Sorts solutions by decay/growth behavior
   - Saves results for transmission matching

3. **transmit()** - Transmission calculation:
   - Matches wavefunctions at boundaries
   - Solves linear system for transmission/reflection coefficients
   - Computes total transmission probability
   - Handles both left→right and right→left scattering

4. **scatter_forw()** - Forward scattering:
   - Integrates Schrödinger equation through scattering region
   - Handles nonlocal pseudopotentials
   - Computes scattering states

### Key Algorithms Implemented

- **Generalized Bloch theorem** for complex band structures
- **Transfer matrix method** for quantum transport
- **Wavefunction matching** at interfaces
- **Green's function techniques** for open systems
- **Layer-by-layer integration** through scattering region

### Data Structures Used

- **Slab decomposition**: System divided into slabs perpendicular to transport
- **2D Fourier representation**: Wavefunctions expanded in perpendicular plane
- **Orbital basis**: Localized orbitals for nonlocal pseudopotentials
- **Complex k-vectors**: Both real (propagating) and complex (evanescent) states

## Dependencies

PWCOND depends on several Quantum ESPRESSO modules:

- **PW (PWscf)**: Core plane-wave DFT functionality
- **Modules**: Basic QE modules (kinds, constants, parameters)
- **UpfLib**: Pseudopotential handling
- **FFTXlib**: Fast Fourier transforms
- **LApack**: Linear algebra routines
- **XClib**: Exchange-correlation functionals
- **MPI**: Parallel communication

The module requires a prior PWscf calculation to generate the self-consistent potential for the system.

## Build System

### Makefile Build
The traditional make-based build system uses:
- Main `Makefile` in PWCOND/ directory
- Source-specific `Makefile` in src/
- Automatic dependency generation via `make.depend`
- Links against PW libraries and QE modules

### CMake Build
Modern CMake support includes:
- `CMakeLists.txt` defining the pwcond.x target
- Proper linking to QE libraries
- Installation rules for the executable

### Compilation
From the PWCOND directory:
```bash
make all          # Builds pwcond.x
make clean        # Cleans build artifacts
make doc          # Builds documentation
```

The executable `pwcond.x` is installed in the QE bin/ directory.

## Usage Notes

1. **Input Structure**: Uses namelist `&inputcond` for parameters
2. **Workflow**: Requires PWscf calculations for leads and scattering region
3. **Parallelization**: Supports MPI parallelization over k-points
4. **Output**: Produces transmission data, complex bands, and optionally scattering states
5. **Applications**: Molecular electronics, nanowires, tunnel junctions, spin transport