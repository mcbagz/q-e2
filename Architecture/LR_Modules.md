# LR_Modules Module Documentation

## Overview

The LR_Modules (Linear Response Modules) is a core component of Quantum ESPRESSO that implements linear response theory calculations, primarily used for:

- **Density Functional Perturbation Theory (DFPT)** calculations
- **Phonon calculations** - computing vibrational properties of materials
- **Electric field perturbations** - dielectric response properties
- **Magnetic perturbations** - for magnetic systems and spin dynamics
- **Time-Dependent DFT (TDDFPT)** support functions

This module provides the fundamental routines for calculating how electronic systems respond to small perturbations, which is essential for computing material properties like phonon frequencies, dielectric constants, and optical properties.

## Directory Structure

The LR_Modules directory contains approximately 70 Fortran source files (.f90) organized as a single module library:

```
LR_Modules/
├── Makefile              # Traditional make build system
├── CMakeLists.txt        # CMake build configuration
└── *.f90                 # Fortran 90 source files
```

## Key Source Files

### Core Module Definitions

- **`lrcom.f90`** - Common variables and data structures for linear response calculations
  - `MODULE qpoint` - q-point information and k+q point handling
  - `MODULE control_lr` - Control parameters for linear response calculations
  - `MODULE eqv` - Variables describing the linear response problem
  - `MODULE gc_lr` - Gradient corrected functional support
  - `MODULE lr_symm_base` - Symmetry operations for small group of q
  - `MODULE lrus` - US pseudopotential specific linear response variables
  - `MODULE units_lr` - File units for I/O operations
  - `MODULE ldaU_lr` - DFT+U linear response support

### DFPT Core Routines

- **`dv_of_drho.f90`** - Computes change in self-consistent potential (Hartree and XC) due to perturbation
- **`cgsolve_all.f90`** - Conjugate gradient solver for linear response equations
- **`ch_psi_all.f90`** - Applies (H-e+Q) operator to wavefunctions
- **`apply_dpot.f90`** - Applies perturbation potential to wavefunctions

### Symmetry and q-point Handling

- **`lr_sym_mod.f90`** - Routines for rotating charge density and magnetization under symmetry
- **`star_q.f90`** - Generates star of q vectors
- **`set_small_group_of_q.f90`** - Determines symmetry operations that leave q invariant
- **`check_q_points_sym.f90`** - Verifies q-point symmetry consistency

### Self-Consistent Field Updates

- **`incdrhoscf.f90`** - Updates charge density in DFPT iterations
- **`incdrhoscf_nc.f90`** - Non-collinear version
- **`mix_pot.f90`** - Potential mixing for SCF convergence
- **`adddvscf.f90`** - Adds SCF potential corrections

### US Pseudopotential Support

- **`addusdbec.f90`** - US pseudopotential contributions to beta functions
- **`adddvepsi_us.f90`** - US corrections to perturbation
- **`newdq.f90`** - Q-function derivatives for US pseudopotentials

### Exchange-Correlation Contributions

- **`dgradcorr.f90`** - Gradient corrections to XC potential
- **`dv_vdW_DF.f90`** - van der Waals density functional contributions
- **`dv_rVV10.f90`** - rVV10 non-local correlation contributions
- **`setup_dmuxc.f90`** - XC kernel setup

### Special Features

- **`Coul_cut_2D_ph.f90`** - 2D Coulomb cutoff for slab calculations
- **`dfpt_tetra_mod.f90`** - Tetrahedron method for Fermi surface integration
- **`lanczos_*.f90`** - Lanczos algorithms for non-Hermitian problems
- **`response_kernels.f90`** - Response function kernels

## Core Functionality

### Main Subroutines and Functions

1. **Linear System Solvers**
   - `cgsolve_all` - Main conjugate gradient solver
   - `ccgsolve_all` - Complex version for magnetic systems
   - `cg_psi` - Single band CG iteration
   
2. **Potential Calculations**
   - `dv_of_drho` - Hartree and XC response to density change
   - `dv_of_drho_xc` - XC-only contribution
   - `apply_dpot` - Apply perturbation potential

3. **Symmetry Operations**
   - `rotate_mesh` - Rotate FFT mesh under symmetry
   - `psymdvscf` - Symmetrize perturbed potential
   - `star_q` - Generate q-point star

### Key Algorithms Implemented

- **Sternheimer Equation** - Solves (H-ε+Q)|Δψ⟩ = -ΔV|ψ⟩ for response wavefunctions
- **Self-consistent DFPT** - Iterative solution with potential mixing
- **Symmetry Analysis** - Small group of q, time-reversal symmetry
- **US Pseudopotential Linear Response** - Augmentation charge response

### Data Structures Used

- **q-point data** - `xq(3)`, `eigqts`, k+q mappings
- **Response quantities** - `dvscf` (potential), `dpsi` (wavefunctions), `drhos` (density)
- **Control parameters** - convergence thresholds, mixing parameters
- **Symmetry data** - small group operations, phase factors

## Dependencies

The LR_Modules depends on several other QE modules:

- **`Modules/`** - Basic data types, constants, FFT, etc.
- **`PW/src/`** - Electronic structure routines
- **`UtilXlib/`** - Linear algebra, parallel utilities
- **`XClib/`** - Exchange-correlation functionals
- **`upflib/`** - Pseudopotential handling

External dependencies:
- **LAPACK/BLAS** - Linear algebra
- **MPI** - Parallel communication
- **CUDA** (optional) - GPU acceleration

## Build System

### Traditional Make
The module is built as a static library `liblrmod.a` using the main QE Makefile system:

```bash
cd LR_Modules
make all
```

Dependencies are handled through `make.depend` and the module requires `mods` and `pwlibs` to be built first.

### CMake Build
The CMakeLists.txt provides modern CMake support:
- Creates target `qe_lr_modules`
- Links against QE internal libraries
- Supports CUDA acceleration when enabled
- Handles OpenMP and MPI configurations

The module integrates into the larger QE build system and is typically not built standalone but as part of executables like `ph.x` (PHonon) or `turbo_lanczos.x` (TDDFPT).