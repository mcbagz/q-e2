# KCW Module Documentation

## Overview

KCW (Koopmans-Compliant with Wannier) is a Quantum ESPRESSO module that implements Koopmans functionals based on Density Functional Perturbation Theory (DFPT) and Wannier functions. The code reads outputs from PWSCF and Wannier90 calculations to perform Koopmans calculations in a perturbative way.

The module implements the theory described in:
- N. Colonna, R. De Gennaro, E. Linscott, and N. Marzari, JCTC 18, 5435 (2022)
- N. Colonna et al. J. Chem. Theory Comput. 14, 2549 (2018)
- A. Marrazzo and N. Colonna, Phys. Rev. Research 6, 033085 (2024) [for non-collinear mode]

### Main Features:
- Calculation of screening coefficients using a linear response approach
- Construction and interpolation of Koopmans-compliant Hamiltonians
- Support for collinear and non-collinear calculations (including spin-orbit coupling)
- Integration with Wannier90 for orbital localization
- Band structure calculations with Koopmans functionals

## Directory Structure

```
KCW/
├── src/              # Main source code directory
├── PP/               # Post-processing utilities
├── Doc/              # Documentation files
├── examples/         # Example calculations
│   ├── example01/    # Basic Si band structure
│   ├── example02/    # H2O calculation
│   ├── example03/    # Si with interpolation
│   ├── example04/    # GaAs with multiple Wannier blocks
│   ├── example05/    # Si with different calculation modes
│   ├── example05.1/  # Comprehensive spin examples
│   ├── example06/    # CrI3 magnetic system
│   └── test_io/      # I/O testing examples
├── Makefile          # Main makefile
└── CMakeLists.txt    # CMake build configuration
```

## Key Source Files

### Main Program
- **kcw.f90**: Main driver program that controls the workflow based on calculation type

### Core Calculation Routines
- **wann2kcw.f90**: Interface between PWSCF/Wannier90 and KCW calculations
- **kcw_screen.f90**: Computes screening coefficients using linear response
- **kcw_ham.f90**: Constructs, interpolates, and diagonalizes the Koopmans Hamiltonian
- **screen_coeff.f90**: Core screening coefficient calculation
- **koopmans_ham.f90**: Koopmans Hamiltonian construction

### Setup and Initialization
- **kcw_setup.f90**: General setup routine
- **kcw_setup_screen.f90**: Setup for screening calculations
- **kcw_setup_ham.f90**: Setup for Hamiltonian calculations
- **kcw_readin.f90**: Input file reading and parsing

### Wannier Function Handling
- **read_wannier.f90**: Reads Wannier90 output files
- **apply_u_matrix.f90**: Applies unitary matrices from Wannier90
- **group_orbitals.f90**: Groups orbitals for efficient calculation

### Coulomb and Screening
- **coulomb.f90**: Module for Coulomb interaction calculations
- **setup_coulomb.f90**: Setup for Coulomb calculations
- **bare_pot.f90**: Bare potential calculations
- **self_hartree.f90**: Self-Hartree contributions

### Linear Response
- **solve_linter_koop_mod.f90**: Linear response solver module
- **rho_of_q.f90**: Charge density response calculations

### Hamiltonian Operations
- **hamilt.f90**: General Hamiltonian operations
- **ham_R0_2nd.f90**: Second-order Hamiltonian at R=0
- **full_ham.f90**: Full Hamiltonian construction
- **ks_hamiltonian.f90**: Kohn-Sham Hamiltonian handling
- **rotate_ks.f90**: Rotates KS states to Wannier basis

### Interpolation and Band Structure
- **interpolation.f90**: Module for interpolation procedures
- **write_hr_to_file.f90**: Writes Hamiltonian in real space
- **kcw_kpoint_grid.f90**: K-point grid handling

### Symmetry Handling
- **kcw_read_sym.f90**: Reads symmetry information
- **kcw_write_sym.f90**: Writes symmetry information
- **find_IBZ_q.f90**: Finds irreducible Brillouin zone points

### I/O and Communication
- **kcw_io_new.f90**: I/O module for KCW-specific files
- **kcw_comm.f90**: Main module containing control variables and data structures
- **bcast_kcw_input.f90**: Broadcasts input parameters in parallel runs

### Post-Processing Tools (PP/)
- **kcw_bands.f90**: Band structure post-processing
- **interp_r_to_k.f90**: Real to k-space interpolation
- **compute_self_hartree.f90**: Self-Hartree energy calculations
- **merge_wann.f90**: Merges multiple Wannier blocks
- **merge_Umat.f90**: Merges unitary matrices
- **sh_setup.f90**: Setup for self-Hartree calculations

## Core Functionality

### Main Subroutines and Functions

1. **Calculation Types** (controlled by `calculation` variable):
   - `'wann2kcw'`: Pre-processing to prepare KCW calculation from PWSCF and Wannier90 outputs
   - `'screen'`: Calculate screening coefficients using linear response
   - `'ham'`: Calculate, interpolate, and diagonalize Koopmans Hamiltonian
   - `'cc'`: Compute q+G=0 contribution corrections

2. **Workflow Steps**:
   - Read PWSCF output and Wannier90 localization matrices
   - Compute periodic parts of Wannier functions
   - Calculate screening coefficients for each orbital
   - Construct Koopmans Hamiltonian in Wannier basis
   - Interpolate to desired k-point grid
   - Diagonalize to obtain band structure

### Key Algorithms Implemented

1. **Screening Coefficient Calculation**:
   - Linear response approach to compute orbital-dependent screening
   - Self-consistent solution of screening equations
   - Support for various mixing schemes

2. **Hamiltonian Construction**:
   - Kohn-Sham Hamiltonian in Wannier basis
   - Addition of Koopmans corrections
   - Real-space representation for efficient interpolation

3. **Symmetry Analysis**:
   - Identification of symmetry-equivalent orbitals
   - Reduction of computational cost using symmetry
   - Support for non-symmorphic symmetries

### Data Structures (from control_kcw module)

- **unimatrx**: Unitary matrices for canonical-variational occupied orbitals
- **alpha_final**: Computed screening parameters
- **Hamlt_R**: Koopmans Hamiltonian in real-space Wannier representation
- **centers**: Wannier function centers
- **rvect/irvect**: Real-space lattice vectors for interpolation

## Dependencies

The KCW module depends on several other Quantum ESPRESSO modules:

1. **PW (PWSCF)**: Base electronic structure calculations
2. **PHonon**: For linear response calculations
3. **PP**: Post-processing utilities, specifically pw2wannier90
4. **External**: Wannier90 for orbital localization

Key QE modules used:
- `mp_global`: MPI parallelization
- `fft_base`: Fast Fourier transforms
- `klist`: K-point handling
- `uspp`: Ultrasoft pseudopotential support
- `paw_variables`: PAW support
- `control_flags`: General control parameters

## Build System

The module uses both Make and CMake build systems:

### Makefile Structure:
- Main Makefile in KCW/ directory
- Separate Makefiles in src/ and PP/ subdirectories
- Targets:
  - `all`: Build everything (kcw executable and post-processing tools)
  - `kcw`: Build main kcw.x executable
  - `pp`: Build post-processing utilities
  - `clean`: Clean build files
  - `doc`: Build documentation

### CMake Configuration:
- Defines targets: `qe_kcw`, `qe_kcw_exe`, `qe_kcwpp_*` executables
- Dependencies: `pw`, `qe_pp_pw2wannier90_exe`, `w90`
- Custom target `kcw` that builds all components

### Executables Built:
1. **kcw.x**: Main executable for all KCW calculations
2. **kcw_bands.x**: Band structure post-processing
3. **kcw_pp.x**: General post-processing utilities
4. **merge_wann.x**: Utility to merge Wannier blocks

The build process integrates with the main Quantum ESPRESSO build system, inheriting compiler flags and library dependencies from the parent make.inc file.