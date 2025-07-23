# XClib Module Documentation

## Overview

XClib is the exchange-correlation (XC) library module in Quantum ESPRESSO that provides a unified interface for calculating exchange-correlation functionals used in density functional theory (DFT) calculations. The module handles:

- Local Density Approximation (LDA) and Local Spin Density Approximation (LSDA) functionals
- Generalized Gradient Approximation (GGA) functionals
- Meta-GGA (MGGA) functionals
- Hybrid functionals with exact exchange
- Integration with external libraries like Libxc and BEEF (Bayesian Error Estimate Functional)

The library provides both standard and derivative calculations of exchange-correlation energies and potentials, supporting both spin-unpolarized and spin-polarized calculations. It also includes GPU acceleration support through OpenACC directives.

## Directory Structure

```
XClib/
├── Ford/                    # Documentation generation files for FORD documentation system
│   ├── Ford.md
│   └── pagedir/
│       └── index.md
├── test_input_files/        # Test input files for the testing programs
│   ├── all_shorts.xml       # Test data for all short-name functionals
│   ├── all_terms.xml        # Test data for all individual XC terms
│   ├── exe_test.in          # Input for execution test
│   ├── gen_test.in          # Input for generation test
│   ├── test_all_shorts.in   # Test all short-name functionals
│   └── test_all_terms.in    # Test all XC terms
└── [source files]           # Main source code files (see below)
```

## Key Source Files

### Core Library Files

**xc_lib.f90**
- Main interface module for the XClib library
- Provides public interfaces for LDA (xc, dmxc), GGA (xc_gcx, dgcxc), and MGGA (xc_metagcx) calculations
- Handles DFT setting/getting routines and various utility functions

### DFT Settings and Parameters

**dft_setting_params.f90**
- Defines global parameters for DFT functionals
- Contains indices for exchange, correlation, and gradient functionals
- Manages Libxc integration parameters

**dft_setting_routines.f90**
- Routines to set and recover DFT names, parameters, and flags
- Handles parsing of functional names and setting appropriate indices
- Manages exact exchange fractions and screening parameters

**qe_dft_list.f90**
- Contains lists of all available DFT functionals
- Maps functional names to internal indices
- Provides shortname mappings for common functionals

### Exchange-Correlation Functional Implementations

**LDA/LSDA Functionals:**
- `qe_funct_exch_lda_lsda.f90` - LDA/LSDA exchange functionals
- `qe_funct_corr_lda_lsda.f90` - LDA/LSDA correlation functionals

**GGA Functionals:**
- `qe_funct_exch_gga.f90` - GGA exchange functionals
- `qe_funct_corr_gga.f90` - GGA correlation functionals

**Meta-GGA Functionals:**
- `qe_funct_mgga.f90` - Meta-GGA functionals implementation

### Driver Routines

**qe_drivers_lda_lsda.f90** / **qe_drivers_d_lda_lsda.f90**
- Drivers for LDA/LSDA calculations (standard and derivative versions)

**qe_drivers_gga.f90** / **qe_drivers_d_gga.f90**
- Drivers for GGA calculations (standard and derivative versions)

**qe_drivers_mgga.f90**
- Driver for meta-GGA calculations

### Wrapper Routines

**xc_wrapper_lda_lsda.f90** / **xc_wrapper_d_lda_lsda.f90**
- Wrapper routines for LDA/LSDA calculations with GPU support

**xc_wrapper_gga.f90** / **xc_wrapper_d_gga.f90**
- Wrapper routines for GGA calculations with GPU support

**xc_wrapper_mgga.f90**
- Wrapper routines for meta-GGA calculations

### External Library Interfaces

**xc_beef_interface.f90**
- Interface to the BEEF (Bayesian Error Estimate Functional) library

**beefun.c** / **pbecor.c**
- C implementations of BEEF functionals
- Headers: `beefleg.h`, `pbecor.h`

### Utility and Support Files

**xclib_utils_and_para.f90**
- Utility routines and parallelization support
- MPI and OpenMP handling

**xclib_error.f90**
- Error handling routines for XClib

**qe_kind.f90**
- Kind definitions for precision control

**qe_constants.f90**
- Physical and mathematical constants

**qe_dft_refs.f90**
- References for DFT functionals

### Testing Programs

**xclib_test.f90**
- Comprehensive testing program for XClib routines
- Supports generation and comparison of test data

**xc_infos.f90**
- Information utility providing details about available functionals

## Core Functionality

### Main Subroutines and Functions

1. **xc (LDA/LSDA calculations)**
   - Calculates exchange-correlation energy and potential for LDA/LSDA
   - Supports both spin-unpolarized and spin-polarized calculations
   - GPU-accelerated through OpenACC

2. **xc_gcx (GGA calculations)**
   - Handles gradient-corrected functionals
   - Requires density and density gradient as input
   - Returns exchange-correlation energy and potentials (v1x, v2x, v1c, v2c)

3. **xc_metagcx (Meta-GGA calculations)**
   - Extends GGA with kinetic energy density dependence
   - Requires density, gradient, and kinetic energy density (tau)

4. **xclib_set_dft_from_name**
   - Sets the functional based on a string name
   - Parses both short names (e.g., "PBE") and full specifications

5. **Driver routines (qe_drivers_*)**
   - Dispatch calculations to appropriate functional implementations
   - Handle both QE internal functionals and Libxc functionals

### Key Algorithms Implemented

- Perdew-Zunger LDA
- Perdew-Wang correlation
- PBE (Perdew-Burke-Ernzerhof) GGA
- BLYP (Becke-Lee-Yang-Parr) GGA
- PBEsol GGA
- SCAN meta-GGA
- Tao-Perdew-Staroverov-Scuseria (TPSS) meta-GGA
- Various hybrid functionals (B3LYP, PBE0, HSE)

### Data Structures Used

- Integer indices for functional identification (iexch, icorr, igcx, igcc, imeta, imetac)
- Arrays for density, gradients, and potentials
- Libxc function pointers for external library integration
- Parameter structures for functional-specific settings

## Dependencies

XClib depends on the following QE modules:

1. **upflib** - For pseudopotential and atomic data handling
2. **MPI libraries** - For parallel execution support
3. **OpenMP** - For shared memory parallelization
4. **OpenACC** - For GPU acceleration
5. **BLAS/LAPACK** - For numerical linear algebra operations
6. **Libxc** (optional) - External XC functional library
7. **BEEF library** - Included as part of XClib for BEEF functionals

## Build System

### Makefile Build

The module is built using the traditional Makefile system:
- Main library target: `xc_lib.a`
- Test executables: `xclib_test.x`, `xc_infos.x`
- Compilation flags inherited from QE's main `make.inc`
- Dependencies handled through `make.depend`

### CMake Build

Alternative modern build system using CMake:
- Library target: `qe_xclib`
- Separate target for BEEF library: `qe_libbeef`
- Test executables built when `QE_ENABLE_TEST` is set
- Automatic handling of Libxc detection and linking
- Support for installation targets

### Building Commands

**Traditional make:**
```bash
make           # Build the library
make test      # Build test programs
make infos     # Build info utility
make clean     # Clean build artifacts
```

**CMake:**
```bash
cmake -B build
cmake --build build
```

The module integrates seamlessly with the main Quantum ESPRESSO build system and is automatically built as part of the complete QE compilation process.