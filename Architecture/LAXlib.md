# LAXlib Module Documentation

## Overview

LAXlib (Linear Algebra eXtensions library) is a critical component of Quantum ESPRESSO that provides optimized linear algebra routines specifically designed for electronic structure calculations. It serves as a high-performance interface layer between QE and standard linear algebra libraries (BLAS, LAPACK, ScaLAPACK), with specialized implementations for:

- **Matrix Diagonalization**: Solving generalized eigenvalue problems (Hv = eSv) that arise in electronic structure calculations
- **Parallel Linear Algebra**: Distributed matrix operations across MPI processes using block-cyclic data distributions
- **GPU Acceleration**: CUDA-enabled versions of key routines for heterogeneous computing
- **Processor Grid Management**: Efficient organization of computational resources for parallel linear algebra

The library is designed to handle both real and complex matrices, with optimizations for the symmetric/Hermitian matrices common in quantum mechanical calculations.

## Directory Structure

```
LAXlib/
├── *.f90, *.h         # Core source files and headers
├── tests/             # Test suite and benchmarking tools
│   ├── test_*.f90     # Unit tests for various functionalities
│   ├── *.bin          # Test data files (ZnO test cases)
│   └── utils.f90      # Testing utilities
├── Makefile           # Main build configuration
├── CMakeLists.txt     # CMake build support
└── README.TEST        # Testing documentation
```

## Key Source Files

### Core Modules

- **`la_module.f90`**: Main LAXlib module providing the primary interfaces:
  - `diaghg`: Serial matrix diagonalization interface (CPU/GPU)
  - `pdiaghg`: Parallel distributed matrix diagonalization
  - Automatic GPU offloading support with fallback to CPU

- **`la_types.f90`**: Data type definitions including the crucial `la_descriptor` type for distributed matrix descriptions

- **`la_param.f90`**: Parameter definitions and MPI/ScaLAPACK interface configurations

- **`la_helper.f90`**: Helper routines for LAXlib initialization and configuration management

### Diagonalization Drivers

- **`cdiaghg.f90`**: Complex matrix diagonalization implementation using LAPACK's ZHEGV/ZHEGVX
- **`rdiaghg.f90`**: Real matrix diagonalization implementation using LAPACK's DSYGV/DSYGVX
- **`dspev_drv.f90`**: Driver for symmetric packed eigenvalue problems
- **`zhpev_drv.f90`**: Driver for Hermitian packed eigenvalue problems

### Parallel Tools

- **`mp_diag.f90`**: MPI processor grid management for distributed linear algebra
- **`ptoolkit.f90`**: Parallel toolkit with matrix redistribution routines
- **`distools.f90`**: Distribution tools for cyclic and block distributions
- **`transto.f90`**: Matrix transposition utilities for distributed matrices

### Header Files

- **`laxlib.h`**: Main include file aggregating all interfaces
- **`laxlib_low.h`**: Low-level interfaces (initialization, distribution)
- **`laxlib_mid.h`**: Mid-level interfaces (parallel operations)
- **`laxlib_hi.h`**: High-level interfaces (main diagonalization routines)
- **`laxlib_param.h`**: Parameter definitions (descriptor sizes, status codes)
- **`laxlib_kinds.h`**: Precision definitions (DP, SP, etc.)

## Core Functionality

### Main Subroutines and Functions

1. **Matrix Diagonalization**
   - `laxlib_cdiaghg`: Complex generalized eigenvalue solver
   - `laxlib_rdiaghg`: Real generalized eigenvalue solver
   - `laxlib_pcdiaghg`: Parallel complex eigenvalue solver
   - `laxlib_prdiaghg`: Parallel real eigenvalue solver

2. **GPU Acceleration**
   - `laxlib_cdiaghg_gpu`: GPU-accelerated complex diagonalization
   - `laxlib_rdiaghg_gpu`: GPU-accelerated real diagonalization
   - Automatic offloading with CPU fallback capabilities

3. **Distribution Management**
   - `laxlib_init_desc`: Initialize matrix descriptors
   - `distribute_lambda`/`collect_lambda`: Distribute/collect eigenvalue matrices
   - `blk2cyc_redist`/`cyc2blk_redist`: Block-to-cyclic redistribution

4. **Matrix Operations**
   - `sqr_mm_cannon`: Cannon's algorithm for distributed matrix multiplication
   - `laxlib_dsqmsym`/`laxlib_zsqmher`: Symmetrization of distributed matrices
   - `sqr_tr_cannon`: Distributed matrix transposition

### Key Algorithms Implemented

- **Generalized Eigenvalue Problems**: Solving Hv = eSv where H is the Hamiltonian and S is the overlap matrix
- **Cannon's Algorithm**: Efficient distributed matrix multiplication
- **Block-Cyclic Distribution**: ScaLAPACK-compatible data distribution for load balancing
- **Processor Grid Organization**: 2D processor grids for optimal parallel efficiency

### Data Structures Used

- **`la_descriptor`**: Central data structure containing:
  - Local matrix dimensions (nr, nc, nrcx)
  - Global indices (ir, ic)
  - Processor grid information (npr, npc, myr, myc)
  - Communication contexts (comm, cntx)
  - Distribution parameters

- **LAX_DESC_SIZE**: Fixed-size integer array for descriptor storage
- **Status arrays**: For querying parallel configuration

## Dependencies

LAXlib depends on several other QE modules and external libraries:

### External Libraries
- **BLAS**: Basic Linear Algebra Subprograms
- **LAPACK**: Linear Algebra PACKage
- **ScaLAPACK**: Scalable LAPACK (optional, for parallel operations)
- **CUDA**: For GPU acceleration (optional)
- **MPI**: For parallel communication

### QE Module Dependencies
- **UtilXlib**: Through included headers for error handling (`lax_error__`)
- Build system integration with main QE infrastructure

## Build System

### Compilation
The module is built using a traditional Makefile system:

```makefile
# Main targets
libqela.a: $(LAX)           # Static library
la_test.x: test.o libqela.a # Test executable

# Key variables from ../make.inc
EXTLIBS = $(CUDA_LIBS) $(SCALAPACK_LIBS) $(LAPACK_LIBS) $(BLAS_LIBS) $(MPI_LIBS)
```

### Build Process
1. Configure QE with desired options (MPI, ScaLAPACK, CUDA)
2. LAXlib inherits configuration from main `make.inc`
3. Compile with `make` to build `libqela.a`
4. Optional: `make TEST` builds testing executable

### CMake Support
Alternative CMake build system is provided through `CMakeLists.txt` for integration with CMake-based builds.

### Testing
Comprehensive test suite available:
- Build tests: `make TEST`
- Run tests: `mpirun -np 4 ./la_test.x -n 1024`
- Includes performance benchmarking capabilities

## Key Features

1. **Automatic GPU Offloading**: Transparent GPU acceleration with CPU fallback
2. **Flexible Parallelization**: Supports various processor grid configurations
3. **Optimized for QE**: Tailored for electronic structure calculation patterns
4. **ScaLAPACK Integration**: Full compatibility with ScaLAPACK when available
5. **Robust Error Handling**: Comprehensive error checking and reporting
6. **Performance Testing**: Built-in benchmarking capabilities