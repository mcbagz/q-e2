# upflib Module Documentation

## Overview

The upflib (Unified Pseudopotential Format library) is a fundamental component of Quantum ESPRESSO that handles all pseudopotential-related operations. This library provides comprehensive support for reading, writing, converting, and manipulating pseudopotentials in various formats, with a primary focus on the UPF (Unified Pseudopotential Format).

The module serves as the backbone for pseudopotential operations in QE, including:
- Basic I/O operations on UPF files (versions 1, 2, and XML schema)
- Setup of interpolation tables and basic pseudopotential variables
- Interpolation of pseudopotentials in reciprocal space
- Generation of various pseudopotential matrix elements
- Utilities for spherical harmonics, Bessel functions, and integration routines
- Support for norm-conserving, ultrasoft, and PAW pseudopotentials
- Handling of relativistic effects including spin-orbit coupling

## Directory Structure

The upflib directory contains only source files without subdirectories. All files are organized in a flat structure containing:
- Core library source files (.f90, .f, .c)
- Build configuration files (Makefile, CMakeLists.txt)
- Documentation (README.md, TODO_upflib.md)
- Utility programs for pseudopotential conversion
- Python utility script (fixfiles.py)

## Key Source Files

### Core Data Structures and Types
- **pseudo_types.f90**: Defines the main `pseudo_upf` type structure containing all pseudopotential data
- **uspp_param.f90**: Parameters and arrays for ultrasoft pseudopotentials
- **paw_variables.f90**: Variables specific to PAW (Projector Augmented Wave) method
- **radial_grids.f90**: Management of radial grid structures

### I/O and Format Handling
- **read_upf_new.f90**: Reader for UPF v2 format with XML support
- **read_upf_v1.f90**: Reader for legacy UPF v1 format
- **write_upf_new.f90**: Writer for UPF formats (v2 and XML)
- **read_psml.f90**: Reader for PSML (PSeudopotential Markup Language) format
- **read_cpmd.f90**: Reader for CPMD pseudopotential format
- **read_fhi.f90**: Reader for FHI pseudopotential format
- **read_ncpp.f90**: Reader for norm-conserving pseudopotentials
- **read_uspp.f90**: Reader for Vanderbilt ultrasoft format
- **upf_io.f90**: Basic I/O utilities and standard units

### Initialization and Setup
- **init_us_0.f90**: Basic initialization of ultrasoft variables
- **init_us_1.f90**: Setup of beta functions and related indices
- **init_us_2_acc.f90**: Advanced initialization with GPU acceleration support
- **init_us_b0.f90**: Box-grid initialization for ultrasoft pseudopotentials

### Computational Modules
- **qvan2.f90**: Computation of augmentation charges Q(r)
- **dqvan2.f90**: Derivatives of augmentation charges
- **gen_us_dj.f90**: Generation of first derivatives of beta functions
- **gen_us_dy.f90**: Generation of gradient of beta functions
- **beta_mod.f90**: Beta function interpolation tables
- **qrad_mod.f90**: Q-function radial Fourier transform tables
- **vloc_mod.f90**: Local potential interpolation
- **rhoat_mod.f90**: Atomic charge density tables
- **rhoc_mod.f90**: Core charge density tables

### Mathematical Utilities
- **ylmr2.f90**: Real spherical harmonics
- **dylmr2.f90**: Derivatives of spherical harmonics
- **ylmr2_gpu.f90**: GPU-accelerated spherical harmonics
- **sph_bes.f90**: Spherical Bessel functions
- **sph_ind.f90**: Spherical harmonic indices
- **splinelib.f90**: Spline interpolation routines
- **simpsn.f90**: Simpson integration
- **spinor.f90**: Spinor rotations for relativistic calculations

### Utility Functions
- **upf_utils.f90**: String manipulation and utility functions
- **upf_error.f90**: Error handling routines
- **upf_invmat.f90**: Matrix inversion utilities
- **upf_auxtools.f90**: Auxiliary tools for pseudopotential manipulation
- **atomic_number.f90**: Element symbols and atomic numbers
- **atom.f90**: Atomic configuration utilities

### XML Support
- **xmltools.f90**: XML parsing utilities
- **dom.f90**: DOM (Document Object Model) for XML
- **wxml.f90**: XML writing utilities

### Relativistic and Spin-Orbit
- **upf_spinorb.f90**: Spin-orbit coupling support
- **uspp.f90**: Main ultrasoft pseudopotential module with spin-orbit extensions

### Specialized Formats
- **gth.f90**: Goedecker-Teter-Hutter pseudopotential support
- **casino_pp.f90**: CASINO quantum Monte Carlo format support

### Conversion Utilities (Executables)
- **upfconv.f90**: Main conversion utility for various PP formats to UPF
- **virtual_v2.f90**: Virtual Crystal Approximation pseudopotential generator
- **casino2upf.f90**: CASINO to UPF format converter
- **hgh2qe.f90**: HGH to QE format converter

## Core Functionality

### Main Subroutines and Functions

1. **Pseudopotential Reading**
   - `read_pseudo_upf2()`: Reads UPF v2 format files
   - `read_pseudo_upf_v1()`: Reads legacy UPF v1 format
   - `read_pseudo_*()`: Family of readers for various formats

2. **Initialization Routines**
   - `init_us_1()`: Initializes beta functions, indices, and Q-functions
   - `init_us_2()`: Sets up beta functions in G-space
   - `init_tab_*()`: Initialize various interpolation tables

3. **Interpolation Tables**
   - `init_tab_qrad()`: Q-function radial transform tables
   - `init_tab_beta()`: Beta function tables
   - `init_tab_atwfc()`: Atomic wavefunction tables

4. **Mathematical Operations**
   - `ylmr2()`: Compute real spherical harmonics
   - `sph_bes()`: Compute spherical Bessel functions
   - `simpson()`: Numerical integration using Simpson's rule

### Key Algorithms Implemented

1. **Kleinman-Bylander Projectors**: Construction of non-local projectors for norm-conserving pseudopotentials
2. **Augmentation Charges**: Q-function evaluation for ultrasoft scheme
3. **PAW Reconstruction**: Tools for all-electron reconstruction in PAW method
4. **Bessel Transforms**: Fourier-Bessel transforms for radial functions
5. **Spline Interpolation**: Cubic spline interpolation for smooth pseudopotential evaluation

### Data Structures Used

1. **pseudo_upf type**: Master structure containing all pseudopotential data
   - Metadata (generator, author, date, element)
   - Grid information (mesh points, radial grid)
   - Projector functions (beta functions)
   - Local and non-local potentials
   - Atomic wavefunctions
   - Augmentation data for US/PAW

2. **uspp module variables**:
   - `vkb`: Beta functions in reciprocal space
   - `deeq`: Integral of effective potential with Q functions
   - `qq_at/qq_nt`: Augmentation charge integrals

## Dependencies

The upflib module depends on several other QE modules:

1. **UtilXlib**: Basic utilities and parallel communication
   - `mp.f90`: MPI wrapper routines
   - `mp_global.f90`: Global MPI variables

2. **External Libraries**:
   - LAPACK: Linear algebra operations
   - BLAS: Basic linear algebra subroutines

3. **Build Dependencies**:
   - Requires `../make.inc` configuration file
   - Links with qe_xml, qe_utilx, qe_lapack libraries

## Build System

The module uses two build systems:

### Makefile-based Build
- Traditional make system with dependency tracking
- Separates objects into:
  - `OBJS_NODEP`: No external dependencies
  - `OBJS_DEP`: Depend on UtilXlib
  - `OBJS_GPU`: GPU-specific routines
- Produces:
  - `libupf.a`: Main static library
  - `upfconv.x`: Conversion utility
  - `virtual_v2.x`: VCA pseudopotential generator
  - `casino2upf.x`: CASINO converter

### CMake Build
- Modern CMake configuration
- Defines targets:
  - `qe_upflib`: Main library target
  - `qe_xml`: XML support library
  - Various executable targets
- Supports CUDA Fortran compilation
- Handles installation and dependencies automatically

The library can be compiled independently from the rest of Quantum ESPRESSO, requiring only the specified dependencies.