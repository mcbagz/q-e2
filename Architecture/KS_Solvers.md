# KS_Solvers Module Documentation

## Overview

The KS_Solvers module in Quantum ESPRESSO provides a collection of iterative solvers for the Kohn-Sham eigenvalue problem. This module implements various algorithms to solve the generalized eigenvalue equation H|ψ⟩ = εS|ψ⟩, where H is the Kohn-Sham Hamiltonian, S is the overlap matrix (for ultrasoft pseudopotentials), ψ represents the electronic wavefunctions, and ε are the eigenvalues.

The module supports both CPU and GPU execution through OpenACC directives and CUDA Fortran, enabling efficient computation on modern heterogeneous computing architectures. It provides solvers optimized for different scenarios, including gamma-point calculations (real wavefunctions) and k-point calculations (complex wavefunctions).

## Directory Structure

The KS_Solvers directory is organized into several subdirectories, each containing implementations of different solver algorithms:

- **CG/**: Conjugate Gradient solvers
  - Band-by-band iterative diagonalization using preconditioned conjugate gradient
  - Minimal memory usage implementation

- **Davidson/**: Davidson iterative eigensolvers
  - Block Davidson algorithm for finding lowest eigenvalues
  - Includes both standard and GPU-optimized versions

- **Davidson_RCI/**: Reverse Communication Interface Davidson solver
  - Alternative Davidson implementation with RCI pattern

- **DENSE/**: Dense matrix operations and subspace rotation
  - Handles Hamiltonian diagonalization in reduced subspace
  - Gram-Schmidt orthogonalization routines
  - Wavefunction rotation utilities

- **ParO/**: Parallel Orbital-updating methods
  - Advanced parallel algorithms for electronic structure calculations
  - Includes BPCG (Block Preconditioned Conjugate Gradient) variants

- **RMM/**: Residual Minimization Method - Direct Inversion in Iterative Subspace (RMM-DIIS)
  - Iterative diagonalization through preconditioned RMM-DIIS algorithm

- **PPCG_legacy/**: Legacy Preconditioned Conjugate Gradient solvers (deprecated)

## Key Source Files

### Core Solver Implementations

**Davidson Solvers:**
- `Davidson/cegterg.f90`: Complex eigensolver using block Davidson algorithm
- `Davidson/regterg.f90`: Real eigensolver for gamma-point calculations
- `Davidson/cegterg_gpu.f90`, `Davidson/regterg_gpu.f90`: GPU-optimized versions
- `Davidson_RCI/david_rci.f90`: Reverse communication interface implementation

**Conjugate Gradient Solvers:**
- `CG/ccgdiagg.f90`: Complex CG solver for band-by-band diagonalization
- `CG/rcgdiagg.f90`: Real CG solver for gamma-point calculations

**RMM-DIIS Solvers:**
- `RMM/crmmdiagg.f90`: Complex RMM-DIIS solver
- `RMM/rrmmdiagg.f90`: Real RMM-DIIS solver

**Parallel Orbital Methods:**
- `ParO/paro_gamma.f90`, `ParO/paro_gamma_new.f90`: Gamma-point ParO implementations
- `ParO/paro_k.f90`, `ParO/paro_k_new.f90`: k-point ParO implementations
- `ParO/bpcg_gamma.f90`, `ParO/bpcg_k.f90`: Block PCG implementations
- `ParO/pcg_gamma.f90`, `ParO/pcg_k.f90`: Standard PCG implementations

**Dense Matrix Operations:**
- `DENSE/rotate_driver.f90`: Driver routine for subspace rotation
- `DENSE/rotate_HSpsi_gamma.f90`, `DENSE/rotate_HSpsi_k.f90`: H and S matrix rotation
- `DENSE/rotate_wfc_gamma.f90`, `DENSE/rotate_wfc_k.f90`: Wavefunction rotation
- `DENSE/gram_schmidt_gamma.f90`, `DENSE/gram_schmidt_k.f90`: Orthogonalization

### Interface Definition
- `ks_solver_interfaces.h`: Fortran interface definitions for rotate_xpsi routines

## Core Functionality

### Main Subroutines and Functions

1. **Davidson Eigensolvers (cegterg/regterg)**
   - Iterative solution of eigenvalue problem using block Davidson algorithm
   - Supports both occupied and empty states
   - Adaptive convergence thresholds
   - Parallel distribution of basis vectors
   - GPU acceleration through OpenACC

2. **Conjugate Gradient Solvers (ccgdiagg/rcgdiagg)**
   - Band-by-band iterative diagonalization
   - Preconditioned conjugate gradient method
   - Memory-efficient implementation
   - Suitable for systems with limited memory

3. **RMM-DIIS Solvers (crmmdiagg/rrmmdiagg)**
   - Residual minimization with DIIS acceleration
   - Efficient for metallic systems
   - Supports variable number of DIIS vectors

4. **Parallel Orbital-updating (ParO)**
   - Two-level parallelization strategy
   - Orbital-wise parallel updates
   - Reduced communication overhead
   - Scalable to large parallel systems

5. **Dense Matrix Operations**
   - Subspace diagonalization after H|ψ⟩ calculation
   - Gram-Schmidt orthogonalization with re-orthogonalization
   - Efficient matrix rotation algorithms

### Key Algorithms Implemented

- **Davidson Algorithm**: Block iterative method for finding lowest eigenvalues and eigenvectors
- **Conjugate Gradient**: Minimization-based approach with preconditioning
- **RMM-DIIS**: Combines residual minimization with DIIS extrapolation
- **Parallel Orbital-updating**: Parallel update of individual orbitals with subspace acceleration
- **Gram-Schmidt**: Classical and modified Gram-Schmidt with stability improvements

### Data Structures Used

- Complex and real wavefunction arrays (psi, evc)
- Hamiltonian and overlap matrix elements (hpsi, spsi)
- Reduced basis representations (hc, sc, vc)
- Convergence tracking arrays
- GPU device arrays with OpenACC data management

## Dependencies

The KS_Solvers module depends on several other Quantum ESPRESSO modules:

- **LAXlib**: Linear algebra operations, parallel diagonalization
- **UtilXlib**: Basic utilities, timing, I/O
- **MPItools**: MPI communication wrappers
- **device_memcpy_m**: GPU memory management
- **mp_bands_util**: Band parallelization utilities
- **DevXlib**: Device acceleration library

External dependencies:
- BLAS/LAPACK or device-accelerated equivalents
- MPI for parallel execution
- CUDA/OpenACC runtime (for GPU execution)

## Build System

The module uses two build systems:

### Makefile-based Build
- Main Makefile coordinates building of all submodules
- Creates static library `libks_solvers.a`
- Includes all solver objects from subdirectories
- Supports parallel make with proper dependencies
- GPU objects included when CUDA support is enabled

### CMake Build
- Modern CMake configuration in `CMakeLists.txt`
- Creates separate libraries for each solver type:
  - `qe_kssolver_davidson`
  - `qe_kssolver_davidsonrci`
  - `qe_kssolver_cg`
  - `qe_kssolver_dense`
  - `qe_kssolver_paro`
  - `qe_kssolver_rmmdiis`
- Automatic CUDA Fortran enabling via `qe_enable_cuda_fortran()`
- Proper target dependencies and include paths
- Interface header generation for Fortran modules

The build system automatically handles:
- Fortran module dependencies
- GPU code compilation when available
- Parallel build coordination
- Installation of libraries and headers