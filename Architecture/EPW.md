# EPW Module Documentation

## Overview

EPW (Electron-Phonon Wannier) is an open-source F90/MPI code that calculates properties related to electron-phonon interactions using Density-Functional Perturbation Theory (DFPT) and Maximally Localized Wannier Functions (MLWFs). EPW is distributed as part of the Quantum ESPRESSO suite and enables the study of:

- Electron-phonon coupling
- Electronic and phonon self-energies
- Transport properties
- Superconducting properties using isotropic/anisotropic Eliashberg theory
- Polaron physics
- Optical properties and indirect absorption
- Time-dependent Bethe-Salpeter Equation (TDBE)

The code performs Wannier interpolation to obtain electron-phonon matrix elements on ultra-dense Brillouin zone grids, enabling accurate calculations of materials properties that depend on fine momentum resolution.

## Directory Structure

```
EPW/
├── bin/                  # Contains epw.x executable (soft link)
├── doc/                  # Documentation files
│   └── Ford/            # Ford documentation framework files
├── examples/            # Example calculations for various materials
│   ├── diamond/         # Diamond example (basic EPW workflow)
│   ├── gan/            # GaN example
│   ├── lif_hdf5/       # LiF with HDF5 support and BSE calculations
│   ├── mgb2/           # MgB2 superconductor example
│   ├── pb/             # Lead with/without spin-orbit coupling
│   └── sic/            # Silicon carbide example
├── irobjs/             # Intermediate representation objects
├── src/                # Main source code directory
│   ├── io/             # Input/output routines
│   └── utilities/      # Utility functions and tools
├── ZG/                 # Special displacement method for el-ph interactions
│   └── src/           # ZG method source files
├── CMakeLists.txt     # CMake build configuration
├── Makefile           # Main makefile
├── README             # Basic information and ASCII art logo
└── epw.md            # Ford documentation configuration
```

## Key Source Files

### Main Program and Core Modules
- **epw.f90**: Main EPW driver program that orchestrates the calculation workflow
- **global_var.f90**: Global variables and arrays used throughout EPW
- **ep_constants.f90**: Physical constants and conversion factors
- **input.f90**: Input parameter reading and validation

### Wannierization and Interpolation
- **wannierization.f90**: Interface to Wannier90 for MLWF generation
- **wannier.f90**: Wannier function utilities
- **pw2wan.f90**: Interface between plane-wave and Wannier basis
- **use_wannier.f90**: Routines for using pre-computed Wannier functions
- **wannier2bloch.f90**: Wannier to Bloch transformation
- **wannier2bloch_opt.f90**: Optimized version of Wannier interpolation
- **bloch2wannier.f90**: Bloch to Wannier transformation

### Electron-Phonon Coupling
- **ep_coarse.f90**: Coarse grid electron-phonon calculations
- **ep_coarse_unfolding.f90**: Band unfolding for supercells
- **selfen.f90**: Electronic and phononic self-energy calculations
- **spectral.f90**: Spectral function calculations
- **longrange.f90**: Long-range polar corrections

### Transport Properties
- **transport.f90**: Main transport module for conductivity and mobility
- **transport_legacy.f90**: Legacy transport routines
- **transport_mag.f90**: Magnetotransport calculations
- **io/io_transport.f90**: Transport I/O routines

### Superconductivity
- **supercond.f90**: Main superconductivity module
- **supercond_iso.f90**: Isotropic Eliashberg equations
- **supercond_aniso.f90**: Anisotropic Eliashberg equations
- **supercond_common.f90**: Common superconductivity routines
- **supercond_coul.f90**: Coulomb pseudopotential
- **supercond_vertex.f90**: Vertex corrections
- **supercond_driver.f90**: Driver for superconducting calculations

### Special Features
- **polaron.f90**: Polaron calculations
- **expolaron.f90**: Exact polaron calculations
- **cumulant.f90**: Cumulant expansion method
- **indabs.f90**: Indirect optical absorption
- **qdabs.f90**: Q-dependent absorption
- **phph.f90**: Phonon-phonon interactions
- **tdbe_driver.f90**: Time-dependent BSE driver
- **tdbe_mod.f90**: TDBE module definitions
- **tdbe_common.f90**: Common TDBE routines

### Utilities
- **utilities/parallelism.f90**: MPI parallelization utilities
- **utilities/symmetry.f90**: Crystal symmetry operations
- **utilities/utilities.f90**: General utility functions
- **utilities/kfold.f90**: k-point folding/unfolding
- **utilities/bzgrid.f90**: Brillouin zone grid generation
- **utilities/sparse_ir.f90**: Sparse intermediate representation
- **utilities/screening.f90**: Screening calculations
- **utilities/nscf2supercond.f90**: Standalone tool for superconductivity

### Input/Output
- **io/io.f90**: Main I/O routines
- **io/io_var.f90**: I/O variable definitions
- **io/io_selfen.f90**: Self-energy I/O
- **io/io_supercond.f90**: Superconductivity I/O
- **io/io_indabs.f90**: Indirect absorption I/O
- **io/io_ahc.f90**: Anomalous Hall conductivity I/O
- **io/io_sparse_ir.f90**: Sparse IR I/O

## Core Functionality

### Main Subroutines and Functions
- **epw (program)**: Main driver that:
  - Initializes MPI and clocks
  - Reads input parameters
  - Performs Wannierization if requested
  - Executes electron-phonon interpolation
  - Calls specialized calculations (transport, superconductivity, etc.)

### Key Algorithms Implemented
1. **Wannier Interpolation**: Uses MLWFs to interpolate electronic structure and phonon frequencies
2. **Electron-Phonon Matrix Elements**: Calculates el-ph coupling on fine grids via Fourier interpolation
3. **Migdal-Eliashberg Theory**: Solves isotropic/anisotropic gap equations for superconductors
4. **Boltzmann Transport**: Iterative solution of Boltzmann equation for transport coefficients
5. **Polaron Theory**: Frohlich polaron and exact diagonalization methods
6. **Spectral Functions**: Calculation of electronic and phononic spectral functions
7. **Vertex Corrections**: Implementation of vertex corrections to el-ph coupling

### Data Structures Used
- **Wigner-Seitz cells**: For real-space representation of Hamiltonians
- **Wannier functions**: Stored as transformation matrices from Bloch states
- **Electron-phonon matrix elements**: Complex arrays indexed by band, mode, and k/q-points
- **Self-energies**: Frequency-dependent complex functions
- **Transport tensors**: Conductivity and mobility tensors

## Dependencies

EPW depends on several Quantum ESPRESSO modules:

1. **PW (PWscf)**: For electronic structure calculations
   - Uses plane-wave basis sets and pseudopotentials
   - Provides wavefunctions and eigenvalues

2. **PHonon**: For phonon calculations using DFPT
   - Calculates dynamical matrices
   - Provides phonon frequencies and eigenvectors

3. **LR_Modules**: Linear response modules
   - Common routines for DFPT calculations

4. **Wannier90**: External library for MLWF generation
   - Integrated as `../../external/wannier90/`
   - Provides Wannier functions and spreads

5. **PP (PostProcessing)**: For various analysis tools

6. **dft-d3**: For van der Waals corrections

## Build System

EPW uses a Makefile-based build system integrated with Quantum ESPRESSO:

### Compilation Process
1. First configure Quantum ESPRESSO: `./configure` in QE root directory
2. EPW inherits configuration from `../../make.inc`
3. Build dependencies: `make pw ph pp wannier` 
4. Compile EPW: `make epw` or just `make` in EPW directory

### Build Targets
- **libepw.a**: Static library containing all EPW objects
- **epw.x**: Main EPW executable
- **nscf2supercond.x**: Standalone tool for superconductivity calculations

### Module Dependencies
The Makefile includes paths to required QE modules:
- `$(MOD_FLAG)../../PW/src`
- `$(MOD_FLAG)../../PHonon/PH`
- `$(MOD_FLAG)../../LR_Modules`
- `$(MOD_FLAG)../../external/wannier90/src/obj`
- `$(MOD_FLAG)../../dft-d3`

### Object Files
All source files are compiled into object files listed in `$(EPWOBJS)` variable, maintaining proper dependency order for compilation.

### Installation
After successful compilation:
- `epw.x` is linked to `EPW/bin/`
- The executable can be run with: `mpirun -np N epw.x < input.in`