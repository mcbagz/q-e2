# Modules Module Documentation

## Overview

The Modules directory contains the core library modules that provide fundamental functionality for all Quantum ESPRESSO components. This is essentially the foundation layer of QE, providing basic data types, mathematical operations, parallelization infrastructure, I/O utilities, and common computational routines that are shared across all QE executables (PW, CP, PHonon, etc.).

The module serves as a central repository for:
- Physical constants and mathematical parameters
- Data types and structures for atomic systems
- FFT (Fast Fourier Transform) infrastructure
- Parallelization and MPI communication layers
- I/O operations and file management
- Exchange-correlation functional interfaces
- Basic linear algebra routines
- Environment setup and runtime management

## Directory Structure

The Modules directory is organized as a flat structure containing:
- **Fortran source files (.f90, .f)**: Core module implementations
- **C source files (.c)**: Low-level system interfaces and optimized routines
- **Build files**: Makefile and CMakeLists.txt for compilation
- **No subdirectories**: All source files are at the root level

## Key Source Files

### Core Infrastructure
- **kind.f90**: Defines precision types (DP for double precision, etc.) and data type parameters used throughout QE
- **constants.f90**: Physical constants (Planck's constant, Boltzmann constant, etc.) and mathematical constants (pi, etc.)
- **parameters.f90**: System-wide parameters and limits
- **environment.f90**: Environment initialization and finalization routines

### Parallelization and MPI
- **mp_global.f90**: Global MPI initialization and management
- **mp_world.f90**: MPI world communicator management
- **mp_images.f90**: Image-level parallelization (for NEB, etc.)
- **mp_pools.f90**: K-point pool parallelization
- **mp_bands.f90**: Band parallelization
- **mp_wave.f90**: Wave function parallelization
- **mp_exx.f90**: Exact exchange parallelization

### FFT Infrastructure
- **fft_base.f90**: Base FFT data structures and descriptors
- **fft_rho.f90**: FFT operations for charge density
- **fft_wave.f90**: FFT operations for wave functions
- **recvec.f90**: Reciprocal space vectors
- **recvec_subs.f90**: Reciprocal vector subroutines

### Atomic and Crystal Structure
- **ions_base.f90**: Ion positions and types
- **cell_base.f90**: Unit cell parameters and operations
- **atomic_wfc_mod.f90**: Atomic wave function utilities
- **space_group.f90**: Space group operations
- **wyckoff.f90**: Wyckoff positions

### I/O and File Management
- **io_global.f90**: Global I/O operations
- **io_files.f90**: File management and naming conventions
- **io_base.f90**: Base I/O routines
- **open_close_input_file.f90**: Input file handling
- **read_input.f90**: Input parsing
- **read_cards.f90**: Card-based input reading
- **read_namelists.f90**: Namelist input processing

### Electronic Structure
- **electrons_base.f90**: Electronic structure data
- **wavefunctions.f90**: Wave function management
- **becmod.f90**: Beta functions and projectors
- **noncol.f90**: Non-collinear magnetism support
- **funct.f90**: Exchange-correlation functional interfaces

### RISM (Reference Interaction Site Model) Modules
- **rism.f90**: Main RISM module
- **rism1d_facade.f90**: 1D-RISM interface
- **rism3d_facade.f90**: 3D-RISM interface
- **do_1drism.f90**, **do_3drism.f90**, **do_lauerism.f90**: RISM calculation drivers
- **solvation_*.f90**: Solvation-related calculations

### Utility Modules
- **basic_algebra_routines.f90**: Basic linear algebra operations
- **invmat.f90**: Matrix inversion
- **random_numbers.f90**: Random number generation
- **sort.f90**: Sorting algorithms
- **parser.f90**: General parsing utilities
- **version.f90**: Version information

### C Interface Files
- **customize_signals.c**: Unix signal handling
- **sockets.c**: Socket communication for i-PI interface
- **qmmm_aux.c**: QM/MM auxiliary functions

## Core Functionality

### Main Subroutines and Functions
1. **Environment Management**:
   - `environment_start()`: Initialize QE environment and MPI
   - `environment_end()`: Clean shutdown procedures

2. **Parallelization Setup**:
   - `mp_startup()`: Initialize all parallelization levels
   - Various communicator creation and management routines

3. **FFT Operations**:
   - Grid setup and descriptor initialization
   - Forward and backward FFT transformations
   - Parallel FFT data distribution

4. **I/O Operations**:
   - File opening/closing with proper MPI coordination
   - Parallel I/O for large datasets
   - XML and binary format support

### Key Algorithms Implemented
- Fast Fourier Transform algorithms with MPI parallelization
- Space group symmetry operations
- Brillouin zone integration schemes
- Exchange-correlation functional evaluation
- RISM equations for solvation

### Data Structures Used
- `fft_type_descriptor`: FFT grid descriptors
- `ions_type`: Ion positions and species
- `cell_type`: Crystal cell parameters
- `mp_comm_type`: MPI communicator wrappers
- `rism_type`: RISM calculation data

## Dependencies

The Modules library depends on:
- **External libraries**: BLAS, LAPACK, MPI, FFTW (optional)
- **QE components**: None (this is the base layer)
- **System libraries**: Standard Fortran and C libraries

Other QE modules depend on this module:
- **All QE components** (PW, CPV, PHonon, etc.) use Modules as their foundation
- Provides the common infrastructure layer for the entire QE ecosystem

## Build System

The module is compiled using:
- **Makefile**: Traditional make-based build
  - Compiles all .f90 and .c files
  - Creates static library libqemod.a
  - Includes RISM modules as a separate library (librismmod.a)
- **CMakeLists.txt**: Modern CMake build support
  - Defines qe_modules target
  - Handles dependencies and include paths
  - Supports both CPU and GPU builds

The build process:
1. Compiles individual source files to object files
2. Archives object files into static libraries
3. Libraries are linked by all QE executables
4. Module files (.mod) are generated for Fortran module interfaces