# TDDFPT Module Documentation

## Overview

TDDFPT (Time-Dependent Density Functional Perturbation Theory) is a Quantum ESPRESSO module that implements linear-response calculations for various spectroscopic properties. The module provides tools for calculating:

- **Optical absorption spectra** of molecules and solids using the Liouville-Lanczos approach
- **Electron Energy Loss Spectroscopy (EELS)** and inelastic X-ray scattering spectra
- **Magnetic excitations (magnons)** and spin-wave spectra for magnetic systems

The module implements both Lanczos and Davidson iterative algorithms for solving the time-dependent Kohn-Sham equations, as well as the Sternheimer equation method for EELS calculations.

## Directory Structure

The TDDFPT module is organized as follows:

- **`src/`** - Main source code directory containing all Fortran 90 files
- **`Doc/`** - Documentation including input file descriptions for each executable
- **`examples/`** - 19 example calculations demonstrating various features
- **`ColorCalculator/`** - Java-based tool for calculating color from absorption spectra
- **`CMakeLists.txt`** - CMake build configuration
- **`Makefile`** - Traditional make build system

## Key Source Files

### Main Program Files
- **`lr_main.f90`** - Main driver for turbo_lanczos.x (optical absorption with Lanczos)
- **`lr_dav_main.f90`** - Main driver for turbo_davidson.x (optical absorption with Davidson)
- **`lr_eels_main.f90`** - Main driver for turbo_eels.x (EELS calculations)
- **`lr_magnons_main.f90`** - Main driver for turbo_magnon.x (magnetic excitations)
- **`turbo_spectrum.f90`** - Post-processing tool for computing spectra

### Core Algorithm Files
- **`lr_lanczos.f90`** - Implementation of Lanczos algorithm (non-Hermitian and pseudo-Hermitian)
- **`lr_dav_routines.f90`** - Davidson algorithm routines
- **`lr_sternheimer.f90`** - Sternheimer equation solver
- **`lr_apply_liouvillian.f90`** - Applies Liouvillian superoperator
- **`lr_apply_liouvillian_eels.f90`** - EELS-specific Liouvillian
- **`lr_apply_liouvillian_magnons.f90`** - Magnon-specific Liouvillian

### Variable and I/O Management
- **`lr_variables.f90`** - Global variables and parameters
- **`lr_dav_variables.f90`** - Davidson-specific variables
- **`lr_readin.f90`** - Input file parsing
- **`lr_restart.f90`** - Restart file handling
- **`lr_write_restart.f90`** - Writing restart files

### Physical Calculations
- **`lr_calc_dens.f90`** - Charge density response calculations
- **`lr_calc_dens_eels.f90`** - EELS-specific density calculations
- **`lr_calc_dens_magnons.f90`** - Magnon-specific density calculations
- **`lr_charg_resp.f90`** - Charge response and susceptibility calculations
- **`lr_exx_kernel.f90`** - Exact exchange kernel implementation

### Utility Functions
- **`lr_ortho.f90`** - Orthogonalization routines
- **`lr_normalise.f90`** - Normalization procedures
- **`lr_alloc_init.f90`** - Memory allocation and initialization
- **`lr_dealloc.f90`** - Memory deallocation
- **`linear_solvers.f90`** - Linear algebra solvers

## Core Functionality

### Main Subroutines and Functions

1. **Lanczos Algorithm** (`one_lanczos_step`)
   - Implements both non-Hermitian biorthogonalization and pseudo-Hermitian variants
   - Handles interleaved chains for x and y polarizations
   - Builds tridiagonal representation of Liouvillian

2. **Davidson Algorithm** (`lr_dav_main`)
   - Iterative diagonalization for targeted eigenvalues
   - More efficient for isolated excitations
   - Suitable for large systems

3. **Liouvillian Application** (`lr_apply_liouvillian`)
   - Applies the TDDFPT superoperator to wavefunctions
   - Handles different approximations (RPA, ALDA, etc.)
   - Supports hybrid functionals and exact exchange

4. **Density Response** (`lr_calc_dens`)
   - Computes induced charge density from perturbed wavefunctions
   - Handles ultrasoft pseudopotentials and PAW
   - Supports noncollinear magnetism

### Key Algorithms Implemented

- **Liouville-Lanczos approach**: Efficient iterative solution of TDDFPT equations
- **Pseudo-Hermitian Lanczos**: Exploits symmetry for 2x speedup
- **Davidson diagonalization**: For targeted excitation energies
- **Sternheimer equation**: Direct frequency-dependent calculations for EELS

### Data Structures Used

- Wave function arrays: `evc1`, `evc1_old`, `evc1_new`
- Lanczos coefficients: `alpha_store`, `beta_store`, `gamma_store`
- Response functions: `chi`, `chirr`, `chirz`, `chizz` (for EELS)
- Projector arrays: `becp1_c`, `becp1_virt` (for ultrasoft/PAW)

## Dependencies

The TDDFPT module depends on several other Quantum ESPRESSO modules:

- **PW** - Plane-wave self-consistent field calculations
- **LR_Modules** - Linear response shared routines
- **Modules** - Core QE infrastructure (FFT, I/O, parallelization)
- **KS_Solvers** - Kohn-Sham equation solvers
- **dft-d3** - DFT-D3 dispersion corrections
- **XClib** - Exchange-correlation functionals

Optional dependencies:
- **ENVIRON** - Continuum solvation models
- **HDF5** - For advanced I/O operations

## Build System

The module can be built using either traditional Make or CMake:

### Using Make:
```bash
cd quantum-espresso/
make tddfpt
```

This creates five executables:
- `turbo_lanczos.x` - Optical spectra via Lanczos
- `turbo_davidson.x` - Optical spectra via Davidson  
- `turbo_eels.x` - EELS calculations
- `turbo_magnon.x` - Magnetic excitations
- `turbo_spectrum.x` - Spectrum post-processing

### Using CMake:
The module is integrated into QE's CMake build system with targets:
- `qe_tddfpt` - Static library
- `qe_tddfpt_turbolanczos_exe` 
- `qe_tddfpt_turbodavidson_exe`
- `qe_tddfpt_turboeels_exe`
- `qe_tddfpt_turbomagnon_exe`
- `qe_tddfpt_turbospectrum_exe`

The build system handles:
- Fortran module dependencies
- MPI and OpenMP parallelization
- GPU acceleration (CUDA)
- Linking with required QE libraries