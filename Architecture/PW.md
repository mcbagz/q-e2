# PW Module Documentation

## Overview

The PW (Plane Wave) module is the core component of Quantum ESPRESSO that implements the Plane Wave Self-Consistent Field (PWscf) method. It performs electronic structure calculations using density functional theory (DFT) with plane wave basis sets and pseudopotentials. 

The main executable `pw.x` can perform various types of calculations including:
- Self-consistent field (SCF) calculations to find the ground state electronic structure
- Non-self-consistent field (NSCF) calculations
- Band structure calculations
- Structural relaxation and optimization
- Molecular dynamics simulations
- Variable-cell relaxation and dynamics

The module supports advanced features like:
- Hybrid functionals (including exact exchange)
- DFT+U calculations for strongly correlated systems
- Van der Waals corrections (DFT-D3, vdW-DF)
- Electric and magnetic field effects
- PAW (Projector Augmented Wave) method
- RISM (Reference Interaction Site Model) for solvation
- GPU acceleration via CUDA Fortran

## Directory Structure

```
PW/
├── src/           # Main source code directory
├── Doc/           # Documentation files
├── examples/      # Example calculations and test cases
├── tools/         # Utility programs and scripts
├── Ford/          # Ford documentation configuration
├── CMakeLists.txt # CMake build configuration
└── Makefile       # Main makefile
```

### Subdirectory Details:

- **src/**: Contains all Fortran 90 source files (250+ modules) implementing the core functionality
- **Doc/**: Input file documentation (INPUT_PW.def, INPUT_OSCDFT.def) and user guide
- **examples/**: 17 example directories demonstrating various calculation types:
  - Basic SCF, band structure, molecular dynamics
  - Advanced features like EXX, ESM, RISM, VCS, DFT-D3
  - Special cases like clusters, gate fields, gamma-only calculations
- **tools/**: Utility programs for pre/post-processing:
  - Structure conversion tools (ibrav2cell, cell2ibrav, cif2qe)
  - Analysis tools (ev.x for equations of state, kpoints.x)
  - Visualization converters (pwi2xsf, pwo2xsf)

## Key Source Files

### Main Program Files:
- `pwscf.f90`: Main program entry point, handles different execution modes
- `run_pwscf.f90`: Core driver routine that orchestrates the calculation
- `electrons.f90`: Main SCF loop implementation, including hybrid functional support
- `run_driver.f90`: Driver mode for i-PI integration

### Core Modules:
- `pwcom.f90`: Central module containing k-point data structures
- `scf_mod.f90`: Self-consistent field procedures
- `atomic_wfc_mod.f90`: Atomic wavefunctions initialization
- `realus.f90`: Real-space ultrasoft pseudopotential implementation

### Electronic Structure:
- `c_bands.f90`: Band structure calculation routines
- `wfcinit.f90`: Wavefunction initialization
- `h_psi.f90`, `s_psi.f90`, `g_psi.f90`: Hamiltonian operations on wavefunctions
- `sum_band.f90`: Charge density calculation from wavefunctions
- `v_of_rho.f90`: Potential calculation from charge density
- `mix_rho.f90`: Charge density mixing for SCF convergence

### Forces and Stress:
- `forces.f90`: Force calculation coordinator
- `force_*.f90`: Various force contributions (Ewald, Hubbard, correlation, etc.)
- `stress.f90`: Stress tensor calculation
- `stres_*.f90`: Various stress contributions

### Advanced Features:
- `exx.f90`, `exx_base.f90`, `exx_band.f90`: Exact exchange implementation
- `ldaU.f90`, `hubbard.f90`: DFT+U and Hubbard corrections
- `xdm_dispersion.f90`: XDM dispersion correction
- `esm*.f90`: Effective Screening Medium method
- `rism_module.f90`: RISM solvation model
- `oscdft_*.f90`: Orthogonally constrained DFT
- `paw_*.f90`: PAW method implementation

### GPU Support:
- `*_gpu.f90` files: CUDA Fortran implementations for GPU acceleration
- `*_acc.f90` files: OpenACC implementations

### Dynamics and Optimization:
- `dynamics_module.f90`: Molecular dynamics engines
- `move_ions.f90`: Ion position updates
- `vcsmd.f90`, `vcsubs.f90`: Variable cell shape MD

## Core Functionality

### Main Subroutines and Functions:

1. **run_pwscf()**: Main calculation driver
   - Initializes the calculation
   - Runs the SCF loop via electrons()
   - Handles ionic relaxation/dynamics
   - Manages restart capabilities

2. **electrons()**: Self-consistent field loop
   - Iterates to find ground state charge density
   - Supports hybrid functionals with separate convergence
   - Handles special cases (metals, insulators, magnetic systems)

3. **c_bands()**: Diagonalization of Kohn-Sham Hamiltonian
   - Uses various solvers (Davidson, CG, PARO, etc.)
   - Parallelized over k-points and bands

4. **sum_band()**: Charge density construction
   - Computes density from wavefunctions
   - Handles spin polarization and non-collinear magnetism

5. **v_of_rho()**: Potential generation
   - Calculates Hartree, XC, and external potentials
   - Interfaces with various XC functionals via xclib

### Key Algorithms:

- **Plane Wave Basis**: Expansion of wavefunctions in plane waves up to kinetic energy cutoff
- **Iterative Diagonalization**: Davidson and CG algorithms for large eigenvalue problems  
- **Density Mixing**: Broyden and other schemes for SCF convergence
- **FFT**: Extensive use of Fast Fourier Transforms for real/reciprocal space conversions
- **Parallelization**: MPI parallelization over k-points, bands, and plane waves

### Data Structures:

- **klist module**: K-point data (coordinates, weights, number of G-vectors)
- **wvfct module**: Wavefunctions, eigenvalues, occupations
- **scf module**: Charge density, potentials, mixing history
- **cell_base module**: Unit cell parameters and reciprocal lattice
- **ions_base module**: Atomic positions and species

## Dependencies

The PW module depends on several other Quantum ESPRESSO modules:

- **Modules**: Basic infrastructure (kinds, constants, parameters, io_global)
- **UpfLib**: Pseudopotential handling
- **XClib**: Exchange-correlation functionals
- **FFTXlib**: Fast Fourier Transform library
- **LAXlib**: Linear algebra (distributed eigensolvers)
- **KS_Solvers**: Kohn-Sham equation solvers
- **dft-d3**: DFT-D3 dispersion correction
- **DevXlib**: Device acceleration support

External dependencies:
- **BLAS/LAPACK**: Basic linear algebra
- **ScaLAPACK**: Distributed linear algebra (optional)
- **FFTW**: FFT library (or internal implementation)
- **MPI**: Message passing for parallelization
- **CUDA**: GPU acceleration (optional)

## Build System

The module can be built using either traditional Makefiles or CMake:

### Makefile Build:
- Main Makefile in PW/ directory
- Includes configuration from make.inc in root directory
- Builds libpw.a library and pw.x executable
- Additional tools built in tools/ subdirectory

### CMake Build:
- CMakeLists.txt defines qe_pw library target
- Links against all required QE and external libraries
- Builds pw.x and tool executables
- Supports optional features (OSCDFT, CUDA, plugins)

### Build Outputs:
- **pw.x**: Main executable for electronic structure calculations
- **libpw.a**: Static library for use by other QE components
- Tool executables: ibrav2cell.x, cell2ibrav.x, ev.x, kpoints.x, pwi2xsf.x, scan_ibrav.x

The PW module serves as the foundation for many other Quantum ESPRESSO packages and provides the core DFT functionality that other modules build upon.