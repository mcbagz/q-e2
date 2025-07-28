# PHonon Module Documentation

## Overview

The PHonon module is a critical component of Quantum ESPRESSO that implements Density Functional Perturbation Theory (DFPT) for calculating phonon properties, dielectric responses, and electron-phonon coupling in materials. This module enables the computation of:

- **Phonon Dispersion Relations**: Calculate vibrational frequencies and eigenvectors throughout the Brillouin zone
- **Dynamical Matrices**: Compute force constants and interatomic force constants
- **Dielectric Properties**: Calculate dielectric constants, Born effective charges, and infrared/Raman spectra
- **Electron-Phonon Coupling**: Determine electron-phonon interaction strengths for superconductivity and transport
- **Linear Response Properties**: Compute response functions to various perturbations (atomic displacements, electric fields)

The module supports various pseudopotential types (norm-conserving, ultrasoft, PAW) and can handle magnetic systems, spin-orbit coupling, and non-local van der Waals functionals.

## Directory Structure

The PHonon directory is organized into several subdirectories:

- **`PH/`**: Main phonon calculation routines and core functionality
  - Contains the primary `ph.x` executable source code
  - Implements DFPT algorithms and response calculations
  - Houses electron-phonon coupling routines

- **`Gamma/`**: Gamma-point only phonon calculations
  - Optimized routines for q=0 calculations
  - Contains the `phcg.x` executable for conjugate gradient phonon calculations
  - Specialized for systems where only zone-center phonons are needed

- **`FD/`**: Finite differences phonon calculations
  - Alternative to DFPT using finite displacement method
  - Contains `fd.x`, `fd_ef.x`, and `fd_ifc.x` executables
  - Useful for validation and special cases

- **`Doc/`**: Documentation files
  - Input file format descriptions (INPUT_*.txt/xml/html)
  - User guides and developer manuals
  - Theory documentation for DFPT implementation

- **`examples/`**: Example calculations and test cases
  - Demonstrates various calculation types
  - Contains reference outputs for validation
  - Includes scripts for running example calculations

## Key Source Files

### Main Program Files

- **`PH/phonon.f90`**: Main driver program for `ph.x` executable
  - Entry point for phonon calculations
  - Initializes MPI, reads input, and calls do_phonon

- **`PH/do_phonon.f90`**: Core phonon calculation loop
  - Loops over q-points and irreducible representations
  - Coordinates SCF calculations and linear response

- **`PH/phcom.f90`**: Common variables and modules
  - Defines key data structures (modes, dynmat, efield_mod)
  - Stores transformation matrices and symmetry information

### Core Calculation Routines

- **`PH/phq_readin.f90`**: Input file parsing and validation
- **`PH/phq_setup.f90`**: Initialize phonon calculation parameters
- **`PH/phq_init.f90`**: Set up wavefunctions and potentials
- **`PH/solve_linter.f90`**: Solve linear response equations
- **`PH/dynmat0.f90`**: Calculate dynamical matrix at q=0
- **`PH/dynmatrix.f90`**: General dynamical matrix routines

### Electron-Phonon Coupling

- **`PH/elph.f90`**: Main electron-phonon coupling routines
- **`PH/elphon.f90`**: Electron-phonon matrix elements
- **`PH/elph_tetra_mod.f90`**: Tetrahedron method for e-ph coupling
- **`PH/ahc.f90`**: Allen-Heine-Cardona theory implementation

### Post-Processing Tools

- **`PH/dynmat.f90`**: `dynmat.x` - Analyze dynamical matrices
- **`PH/matdyn.f90`**: `matdyn.x` - Interpolate phonon dispersions
- **`PH/q2r.f90`**: `q2r.x` - Transform q-space to real space
- **`PH/lambda.f90`**: `lambda.x` - Calculate e-ph coupling strength
- **`PH/alpha2f.f90`**: `alpha2f.x` - Compute Eliashberg function

### Specialized Calculations

- **`PH/dielec.f90`**: Dielectric constant calculations
- **`PH/zstar_eu.f90`**: Born effective charges
- **`PH/raman.f90`**: Raman tensor calculations
- **`PH/dvscf_q2r.f90`**: Interpolate self-consistent potentials

## Core Functionality

### Main Subroutines and Functions

1. **Linear Response Engine**
   - `solve_linter`: Iteratively solve Sternheimer equation
   - `dvpsi_e`: Apply perturbation to wavefunctions
   - `cgsolve`: Conjugate gradient solver for linear systems

2. **Dynamical Matrix Construction**
   - `dynmat0`: Build dynamical matrix at Gamma point
   - `dynmat_us`: Ultrasoft pseudopotential contributions
   - `rotate_and_add_dyn`: Apply symmetry operations

3. **Symmetry Analysis**
   - `set_irr`: Determine irreducible representations
   - `find_mode_sym`: Classify phonon modes by symmetry
   - `symdyn_munu`: Symmetrize dynamical matrices

4. **Electron-Phonon Coupling**
   - `elphon`: Calculate matrix elements
   - `elph_do_ahc`: Allen-Heine-Cardona theory
   - `compute_alphasum`: Sum over electronic states

### Key Algorithms Implemented

- **Density Functional Perturbation Theory (DFPT)**: Self-consistent linear response
- **Sternheimer Equation**: Non-self-consistent response calculations
- **2n+1 Theorem**: Efficient calculation of higher-order derivatives
- **Variational Approach**: Energy functional minimization for perturbations
- **Long-Range Corrections**: Proper treatment of polar materials

### Data Structures Used

- **`modes` module**: Stores eigenvectors and transformation matrices
- **`dynmat` module**: Contains dynamical matrices and frequencies
- **`efield_mod` module**: Electric field perturbation data
- **`ph_restart` module**: Checkpoint and recovery information
- **`elph` module**: Electron-phonon coupling arrays

## Dependencies

The PHonon module depends on several other Quantum ESPRESSO modules:

### Core QE Modules
- **`Modules/`**: Basic infrastructure (kinds, constants, FFT, I/O)
- **`PW/src/`**: Plane-wave basis set routines and SCF engine
- **`LR_Modules/`**: Linear response common routines

### Required Libraries
- **`UtilXlib/`**: Parallel linear algebra and utilities
- **`FFTXlib/`**: Fast Fourier Transform routines
- **`LAXlib/`**: Linear algebra interfaces
- **`XClib/`**: Exchange-correlation functionals
- **`upflib/`**: Pseudopotential handling

### Optional Dependencies
- **`HDF5`**: For advanced I/O operations
- **`ELPA`**: Enhanced eigenvalue solvers
- **`FOX`**: XML parsing for QE-XML format

## Build System

The PHonon module uses multiple build systems:

### Makefile System
- **Main Makefile**: `PHonon/Makefile`
  - Builds three main targets: `phonon`, `phgamma_only`, `finite_diffs`
  - Each subdirectory has its own Makefile

### CMake System
- **CMakeLists.txt**: Modern CMake configuration
  - Defines libraries: `qe_phonon_ph`, `qe_phonon_gamma`, `qe_phonon_fd`
  - Builds executables with proper linking

### Compilation Process
1. Libraries are built first (libph.a, libphaux.a, libgamma.a)
2. Executables link against QE core libraries and phonon libraries
3. CUDA/GPU support is conditionally enabled

### Key Executables Built
- **`ph.x`**: Main phonon calculation program
- **`dynmat.x`**: Dynamical matrix analysis
- **`matdyn.x`**: Phonon dispersion interpolation
- **`q2r.x`**: Fourier transform of dynamical matrices
- **`lambda.x`**: Electron-phonon coupling strength
- **`alpha2f.x`**: Eliashberg spectral function
- **`postahc.x`**: Post-process AHC calculations
- **`phcg.x`**: Gamma-only conjugate gradient phonons
- **`fd.x`**: Finite differences phonons
- **`fd_ef.x`**: Finite differences for electric fields
- **`fd_ifc.x`**: Interatomic force constants from FD

The module integrates tightly with the Quantum ESPRESSO ecosystem, sharing data structures and computational routines while extending the capabilities for vibrational and response properties calculations.