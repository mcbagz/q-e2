# GWW Module Documentation

## Overview

The GWW (GW with Wannier functions) module is a comprehensive implementation of many-body perturbation theory methods within Quantum ESPRESSO. It provides tools for calculating quasiparticle energies, optical properties, and excitonic effects using the GW approximation and Bethe-Salpeter equation (BSE). The module leverages Wannier functions and Lanczos techniques to efficiently compute electronic correlations and optical responses in materials.

Key capabilities include:
- GW quasiparticle corrections for band structures
- Calculation of dielectric functions and optical spectra
- Solution of the Bethe-Salpeter equation for excitonic effects
- Support for both molecules and extended systems
- Efficient algorithms using Lanczos chains and optimal basis sets

## Directory Structure

The GWW module is organized into several subdirectories, each handling specific aspects of the calculations:

- **`gww/`** - Core GW implementation with self-energy calculations
- **`pw4gww/`** - Interface with PWscf for preparing Wannier functions and optimal basis sets
- **`bse/`** - Bethe-Salpeter equation solver for optical properties and excitons
- **`head/`** - Calculation of head of dielectric matrix and macroscopic dielectric function
- **`simple/`** - Simplified GW implementation for band structure calculations
- **`simple_bse/`** - Simplified BSE solver for optical absorption
- **`simple_ip/`** - Independent particle approximation for dielectric functions
- **`minpack/`** - Mathematical library for optimization and fitting procedures
- **`util/`** - Utility programs for post-processing
- **`doc/`** - Documentation and references
- **`examples/`** - Example calculations demonstrating various features

## Key Source Files

### Core GWW (`gww/`)
- **`gww.f90`** - Main GW program driver
- **`self_energy.f90`** - Self-energy calculations within GW approximation
- **`polarization.f90`** - Polarization function calculations
- **`green_function.f90`** - Green's function construction
- **`do_self_lanczos.f90`**, **`do_self_lanczos_full.f90`**, **`do_self_lanczos_time.f90`** - Lanczos-based self-energy calculations
- **`expansion.f90`** - Basis set expansion methods
- **`fit_multipole.f90`**, **`fit_polynomial.f90`** - Fitting procedures for frequency dependence
- **`input_gw.f90`** - Input parameter reading and validation

### PW4GWW Interface (`pw4gww/`)
- **`pw4gww.f90`** - Main interface program between PWscf and GWW
- **`produce_wannier_gamma.f90`** - Generation of Wannier functions at Gamma point
- **`optimal.f90`** - Construction of optimal basis sets
- **`wannier.f90`** - Wannier function transformations
- **`pola_lanczos.f90`** - Lanczos chains for polarizability
- **`fake_conduction.f90`** - Generation of conduction states
- **`semicore.f90`**, **`semicore_read.f90`** - Treatment of semicore states

### BSE Solver (`bse/`)
- **`bse_main.f90`** - Main BSE program
- **`exciton.f90`** - Excitonic wavefunctions and eigenvalues
- **`direct_v_exc.f90`**, **`direct_w_exc.f90`** - Direct terms in BSE kernel
- **`exchange_exc.f90`** - Exchange interactions for excitons
- **`absorption.f90`** - Optical absorption spectra
- **`spectrum.f90`** - Spectral function calculations
- **`lanczos.f90`** - Lanczos algorithm for BSE
- **`diago_exc.f90`** - Diagonalization of excitonic Hamiltonian

### Dielectric Head (`head/`)
- **`head.f90`** - Main program for head calculations
- **`solve_head.f90`** - Linear response solver for macroscopic dielectric function
- **`lanczos_k.f90`** - k-point dependent Lanczos chains

### Simplified Implementations
- **`simple/simple.f90`** - Simplified GW for band structures
- **`simple_bse/simple_bse.f90`** - Simplified BSE solver
- **`simple_ip/simple_ip.f90`** - Independent particle dielectric function

## Core Functionality

### Main Subroutines and Functions

1. **Self-Energy Calculations**
   - `do_self_lanczos()` - Lanczos-based GW self-energy
   - `self_energy_omega()` - Frequency-dependent self-energy
   - `go_exchange()` - Exchange contributions

2. **Polarization and Screening**
   - `do_polarization_lanczos()` - Lanczos polarization function
   - `calculate_w()` - Screened Coulomb interaction
   - `fit_multipole_omega()` - Multipole expansion of W

3. **Wannier Functions**
   - `produce_wannier_gamma()` - Generate Wannier functions
   - `rotate_wannier()` - Unitary transformations
   - `optimal_basis()` - Construct optimal product basis

4. **BSE and Optical Properties**
   - `solve_bse()` - Solve Bethe-Salpeter equation
   - `build_kernel()` - Construct BSE kernel
   - `optical_absorption()` - Calculate absorption spectra

### Key Algorithms Implemented

- **Lanczos recursion** for efficient calculation of response functions
- **Optimal basis sets** to reduce computational cost
- **Contour deformation** techniques for frequency integration
- **Wannier interpolation** for k-point sampling
- **Iterative solvers** (CG, Davidson) for large-scale eigenproblems

### Data Structures Used

- `self_storage` - Storage of self-energy data on frequency grids
- `self_expansion` - Expansion coefficients for self-energy
- `quasi_particles` - Quasiparticle energies and wavefunctions
- `v_state`, `c_state` - Valence and conduction state information
- `exc` - Excitonic states and eigenvectors
- `w_expectation` - Matrix elements of screened interaction

## Dependencies

The GWW module depends on several other Quantum ESPRESSO modules:

- **`PW`** - Base plane-wave DFT calculations
- **`Modules`** - Core QE infrastructure (FFT, linear algebra, I/O)
- **`UtilXlib`** - Utility libraries
- **`FFTXlib`** - Fast Fourier Transform libraries
- **`LAXlib`** - Linear algebra libraries
- **`UPFlib`** - Pseudopotential handling
- **`XClib`** - Exchange-correlation functionals
- **`LR_Modules`** - Linear response modules (for head.x)
- **`PHonon`** - Phonon calculations (for head.x)

External dependencies:
- BLAS/LAPACK for linear algebra
- MPI for parallel execution
- Optional: ScaLAPACK for distributed linear algebra

## Build System

The GWW module uses two build systems:

### Traditional Make
- Main `Makefile` in GWW directory orchestrates subdirectory builds
- Each subdirectory has its own `Makefile`
- Build order enforces dependencies (e.g., minpack before gww)
- Executables created:
  - `pw4gww.x` - Wannier function interface
  - `gww.x` - Main GW program
  - `gww_fit.x` - Fitting utility
  - `head.x` - Dielectric head calculation
  - `bse_main.x` - BSE solver
  - `simple.x` - Simplified GW
  - `simple_bse.x` - Simplified BSE
  - `simple_ip.x` - Independent particle approximation
  - Utilities: `graph.x`, `abcoeff_to_eps.x`, `memory_pw4gww.x`

### CMake Build
- `CMakeLists.txt` provides modern CMake configuration
- Defines libraries for each component
- Proper dependency management between libraries
- Target `gwl` builds all GWW executables
- Supports CUDA acceleration for pw4gww component

To compile with traditional make:
```bash
cd GWW
make all
```

To compile with CMake (from QE root):
```bash
cmake -B build
cmake --build build --target gwl
```

## Usage Notes

The module is designed for advanced many-body calculations requiring:
1. Initial DFT calculation with PWscf
2. Generation of optimal basis/Wannier functions with pw4gww.x
3. GW calculation with gww.x for quasiparticle corrections
4. Optional BSE calculation with bse_main.x for optical properties

Example workflows are provided in the `examples/` directory for:
- Molecular systems (CH4)
- Bulk semiconductors (Si)
- Metals (Ag)
- Optical properties and excitons