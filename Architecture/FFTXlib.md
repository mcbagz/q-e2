# FFTXlib Module Documentation

## Overview

FFTXlib is a specialized Fast Fourier Transform (FFT) library module within Quantum ESPRESSO that implements real space grid parallelization of FFT operations and task groups. This module is crucial for efficiently transforming data between reciprocal space (G-space) and real space (R-space) in quantum mechanical calculations. It provides optimized parallel FFT routines specifically designed for plane-wave based DFT calculations, supporting both charge density and wavefunction transformations.

The library handles complex 3D FFT operations with advanced parallelization strategies, including:
- Distributed memory parallelization using MPI
- Task group parallelization for improved scalability
- Support for GPU acceleration (CUDA)
- Multiple FFT backend implementations (FFTW, DFTI, ESSL, cuFFT, etc.)

## Directory Structure

The FFTXlib directory is organized as follows:

```
FFTXlib/
├── CMakeLists.txt      # CMake build configuration
├── Makefile            # Main makefile
├── README.md           # Basic module documentation
├── examples/           # Example outputs and scripts
│   ├── reference/      # Reference output files
│   └── run_example     # Example execution script
├── src/                # Source code directory
│   ├── CMakeLists.txt  # CMake config for source
│   ├── Makefile        # Source makefile
│   └── *.f90, *.c, *.h # Source files
└── tests/              # Test suite
    ├── CMakeLists.txt  # CMake config for tests
    ├── Makefile        # Test makefile
    └── *.f90           # Test programs
```

## Key Source Files

### Core FFT Types and Parameters
- **fft_param.f90** - Compile-time parameters and constants for FFT operations
- **fft_types.f90** - Defines the main `fft_type_descriptor` type that manages FFT grid dimensions, parallel distribution, and processor mappings
- **fft_smallbox_type.f90** - Descriptor type for "box-grid" FFTs used in CP calculations
- **stick_base.f90** - Base module for stick (column) data structures used in reciprocal space

### High-Level FFT Interfaces
- **fft_interfaces.f90** - Public interfaces for forward (`fwfft`) and inverse (`invfft`) FFT operations, including GPU variants
- **fft_fwinv.f90** - Implementation of the forward and inverse FFT driver routines that dispatch to appropriate backends

### Parallel FFT Implementation
- **fft_parallel.f90** - Main parallel 3D FFT driver for standard grids, implements the `tg_cft3s` routine
- **fft_parallel_2d.f90** - Alternative 2D decomposition for improved scalability
- **fft_scatter.f90** - MPI communication routines for data redistribution during parallel FFTs
- **fft_scatter_2d.f90** - Scatter operations for 2D decomposition
- **fft_scatter_gpu.f90** - GPU-accelerated scatter operations
- **fft_scatter_2d_gpu.f90** - GPU scatter for 2D decomposition
- **scatter_mod.f90** - Low-level scatter module implementation
- **tg_gather.f90** - Task group gather operations for wavefunction FFTs

### FFT Backend Wrappers
- **fft_scalar.f90** - Main scalar FFT module that selects appropriate backend
- **fft_scalar.FFTW3.f90** - FFTW3 library wrapper (most common)
- **fft_scalar.FFTW.f90** - Legacy FFTW wrapper
- **fft_scalar.DFTI.f90** - Intel MKL DFTI wrapper
- **fft_scalar.ESSL.f90** - IBM ESSL library wrapper
- **fft_scalar.SX6.f90** - NEC SX6 specific implementation
- **fft_scalar.cuFFT.f90** - NVIDIA cuFFT wrapper for GPU acceleration
- **fftw_interfaces.f90** - Fortran interfaces to FFTW C functions

### C Interface Layer
- **fft_stick.c** - C implementation of 1D FFT on sticks
- **fftw.c, fftw_dp.c, fftw_sp.c** - C wrappers for FFTW library calls
- **fftw.h, fftw_dp.h, fftw_sp.h** - Header files for FFTW wrappers
- **konst.h** - Constants used in C code

### Utility and Support Modules
- **fft_ggen.f90** - Generation of G-vectors for reciprocal space
- **fft_support.f90** - Support functions for FFT dimensions and optimization
- **fft_helper_subroutines.f90** - Various helper routines
- **fft_error.f90** - Error handling routines
- **fft_buffers.f90** - Buffer management for FFT operations
- **fft_interpolate.f90** - Fourier interpolation between different grids
- **fft_smallbox.f90** - Small box FFT implementation for localized operations

### Test Programs
- **fft_test.f90** - Main FFT performance testing program
- **test_fft_scalar_gpu.f90** - GPU scalar FFT tests
- **test_fft_scatter_mod_gpu.f90** - GPU scatter operation tests
- **test_fwinv_gpu.f90** - GPU forward/inverse FFT tests
- **gen_test_params.py** - Python script to extract test parameters from pw.x output

## Core Functionality

### Main Subroutines and Functions

1. **fwfft / invfft** (fft_interfaces.f90)
   - High-level interfaces for forward and inverse FFT operations
   - Support for different grid types: 'Rho' (charge density), 'Wave' (wavefunctions)
   - Optional GPU acceleration with CUDA streams

2. **tg_cft3s** (fft_parallel.f90)
   - Core parallel 3D FFT routine
   - Handles different transform types based on isgn parameter:
     - ±1: charge density and potential
     - ±2: wavefunctions
     - ±3: wavefunctions with task groups
   - Implements pencil decomposition strategy

3. **cfft3d / cfft3ds** (fft_scalar.f90)
   - Serial 3D FFT implementations
   - Dispatches to appropriate backend library

### Key Algorithms Implemented

1. **Pencil Decomposition**
   - Data is distributed in "pencils" (columns) along one direction
   - FFT sequence: Z-direction → transpose → Y-direction → transpose → X-direction
   - Enables efficient parallel execution with minimal communication

2. **Task Group Parallelization**
   - Groups of processors work on complete planes of different wavefunctions
   - Reduces communication overhead for large numbers of bands
   - Activated with ntg parameter

3. **2D Domain Decomposition**
   - Alternative to 1D slab decomposition for better scalability
   - Distributes data across both Y and Z dimensions
   - Reduces memory footprint per processor

### Data Structures Used

**fft_type_descriptor** - Main FFT descriptor containing:
- Grid dimensions (nr1, nr2, nr3) and padded dimensions (nr1x, nr2x, nr3x)
- Parallel layout information (nproc, nproc2, nproc3)
- Processor mappings and communicators
- Stick distribution arrays
- GPU device pointers for accelerated operations

## Dependencies

FFTXlib depends on:
- **fft_param** module (internal) - Basic parameters
- **MPI libraries** - For parallel communication
- **External FFT libraries** - One of: FFTW3, MKL DFTI, ESSL, cuFFT
- **CUDA** (optional) - For GPU acceleration
- **OpenMP** (optional) - For thread-level parallelism

From other QE modules:
- The module is largely self-contained but integrates with QE's parallelization framework

## Build System

The module uses a traditional Makefile-based build system:

1. **Main Makefile** (FFTXlib/Makefile)
   - Includes ../make.inc for global QE build settings
   - Delegates to src/Makefile for actual compilation

2. **Source Makefile** (FFTXlib/src/Makefile)
   - Compiles all Fortran and C source files
   - Creates static library: libqefft.a
   - Handles dependencies through make.depend

3. **Build Process**
   ```bash
   make all      # Builds the library
   make clean    # Removes object files
   make TEST     # Builds test programs
   ```

4. **CMake Support**
   - Alternative build system via CMakeLists.txt files
   - Provides better IDE integration and cross-platform support

The library is compiled as part of the main Quantum ESPRESSO build process and linked into various QE executables that require FFT functionality.