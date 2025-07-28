# HP Module Documentation

## Overview

The HP (Hubbard Parameters) module is a specialized component of Quantum ESPRESSO that calculates Hubbard U and V parameters from first principles using Density-Functional Perturbation Theory (DFPT). This code enables the automated calculation of on-site (U) and inter-site (V) Hubbard parameters for DFT+U and DFT+U+V calculations, eliminating the need for empirical parameter fitting.

The HP code implements the linear-response approach to determine Hubbard parameters self-consistently, which is crucial for accurate modeling of strongly correlated materials such as transition metal oxides, rare-earth compounds, and other materials with localized d or f electrons.

## Directory Structure

The HP module is organized as follows:

- **`src/`** - Core source code files containing the main algorithms and functionality
- **`Doc/`** - Documentation including input file descriptions and README
- **`examples/`** - Example calculations demonstrating various use cases:
  - `example01/` - LiCoO2 calculation
  - `example02/` - NiO calculation with different magnetic configurations
  - `example03/` - CrI3 calculation
  - `example04/` - Metallic Ni calculation
  - `example05/` - LiCoO2 with different settings
  - `example06/` - Ni2MnGa multi-site calculation
  - `example07/` - Ni2MnGa with step-by-step approach
  - `example08/` - NiO2 calculation
  - `example09/` - CoO2 calculation
  - `example10/` - LiCoO2 with external Hubbard parameters
- **Build files**:
  - `Makefile` - Main makefile for building the module
  - `CMakeLists.txt` - CMake configuration file

## Key Source Files

### Main Program
- **`hp_main.f90`** - Main driver program that orchestrates the HP calculation workflow

### Core Modules
- **`hpcom.f90`** - Common variables and data structures module (ldaU_hp) containing:
  - Control flags for calculation options
  - Arrays for storing response functions and occupation matrices
  - Parameters for q-point grids and convergence thresholds

### Initialization and Setup
- **`hp_readin.f90`** - Reads input parameters from the input file
- **`hp_init.f90`** - Initializes arrays and variables for HP calculation
- **`hp_summary.f90`** - Prints calculation summary
- **`hp_bcast_input.f90`** - Broadcasts input parameters in parallel execution

### Grid Generation
- **`hp_generate_grids.f90`** - Generates q-point and R-point grids
- **`hp_q_points.f90`** - Manages q-point generation and symmetry
- **`hp_R_points.f90`** - Manages R-point (real-space) grid

### Core Calculation Routines
- **`hp_solve_linear_system.f90`** - Solves the linearized Kohn-Sham equation
- **`hp_calc_chi.f90`** - Calculates response functions χ0 and χ
- **`hp_dvpsi_pert.f90`** - Computes perturbing potential and applies it to wavefunctions
- **`hp_dnsq.f90`** - Handles response occupation matrices

### Symmetry Operations
- **`hp_symdnsq.f90`** - Symmetrizes response occupation matrices
- **`hp_symdvscf.f90`** - Symmetrizes the perturbing potential
- **`hp_sym_dmag.f90`** - Handles symmetry for magnetic systems
- **`hp_psym_dmag.f90`** - Point symmetry operations for magnetic systems

### I/O Operations
- **`hp_write_chi.f90`** - Writes response functions to file
- **`hp_write_chi_full.f90`** - Writes complete chi matrices
- **`hp_write_dnsq.f90`** - Writes response occupation matrices
- **`hp_read_chi.f90`** - Reads response functions from file
- **`hp_read_dnsq.f90`** - Reads response occupation matrices

### Post-processing
- **`hp_postproc.f90`** - Post-processes results to extract Hubbard parameters
- **`hp_find_inequiv_sites.f90`** - Identifies inequivalent atomic sites

### Utility Functions
- **`hp_check_pert.f90`** - Checks which atoms should be perturbed
- **`hp_check_type.f90`** - Analyzes atomic types
- **`hp_run_nscf.f90`** - Runs non-self-consistent calculations
- **`hp_print_clock.f90`** - Prints timing information

## Core Functionality

### Main Subroutines and Functions

1. **Linear Response Calculation**:
   - The code perturbs Hubbard atoms one by one
   - For each perturbation, it solves the linearized Kohn-Sham equation
   - Calculates response occupation matrices at various q-points

2. **Response Functions**:
   - Computes bare response function χ0 (first iteration)
   - Computes self-consistent response function χ
   - Uses these to determine Hubbard parameters

3. **Symmetry Analysis**:
   - Exploits crystal symmetry to reduce computational cost
   - Identifies equivalent atoms and q-points
   - Symmetrizes response quantities

### Key Algorithms Implemented

- **DFPT for Hubbard parameters**: Linear-response approach to compute U and V
- **Self-consistent solution**: Iterative solution of response equations
- **q-point integration**: Summation over Brillouin zone with appropriate weights
- **Symmetry reduction**: Use of point and space group symmetries

### Data Structures Used

- **Response occupation matrices**: `dns0`, `dnsscf_tot` (complex arrays)
- **Response functions**: `chi0`, `chi` (real arrays)
- **Control flags**: Various logical variables for calculation options
- **Grid parameters**: `nq1`, `nq2`, `nq3` for q-point mesh

## Dependencies

The HP module depends on several other Quantum ESPRESSO modules:

- **PW (PWscf)**: Core plane-wave DFT functionality
  - Uses PW data structures and routines
  - Requires completed SCF calculation as input
- **LR_Modules**: Linear response modules
  - Provides DFPT functionality
  - Handles perturbation theory calculations
- **KS_Solvers**: Kohn-Sham equation solvers
- **dft-d3**: DFT-D3 dispersion corrections (if needed)
- **Base modules**: 
  - FFTXlib for Fast Fourier Transforms
  - LAXlib for linear algebra
  - UtilXlib for utilities

## Build System

The HP module uses a standard Quantum ESPRESSO build system:

### Makefile Structure
- Main `Makefile` in HP directory handles:
  - Building the hp.x executable
  - Creating static library libhp.a
  - Documentation generation
  - Cleaning operations

### Compilation Process
1. Compiles all source files in `src/` to object files
2. Creates static library `libhp.a` from HP objects
3. Links with required QE libraries (PW, LR_Modules, etc.)
4. Produces executable `hp.x` in `bin/` directory

### Build Commands
- `make hp` or `make all` - builds the HP executable
- `make hp-lib` - builds only the HP library
- `make clean` - removes compiled files
- `make doc` - generates documentation

### Module Dependencies
The build system ensures proper compilation order through:
- `MODFLAGS` specifying module search paths
- Dependency tracking in `make.depend`
- Links to required libraries: `$(PWOBJS)`, `$(LRMODS)`, `$(QEMODS)`

## Usage Notes

- HP calculations require a completed SCF calculation with DFT+U
- The code is applicable only to open-shell systems
- Supports collinear and non-collinear magnetic calculations
- Can handle ultrasoft pseudopotentials and PAW datasets
- Parallel execution is supported via MPI