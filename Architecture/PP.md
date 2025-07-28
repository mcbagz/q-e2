# PP Module Documentation

## Overview

The PP (Post-Processing) module in Quantum ESPRESSO is a comprehensive suite of tools designed to analyze and visualize the results of electronic structure calculations performed by pw.x (PWscf). This module enables users to extract, process, and plot various physical quantities from the self-consistent field calculations, including charge densities, band structures, density of states, molecular orbitals, and many other properties.

The PP module serves as a critical bridge between raw computational results and meaningful physical insights, providing tools for:
- Electronic structure analysis (bands, DOS, PDOS)
- Real-space visualization (charge density, STM images, ELF)
- Wannier function generation and analysis
- Interface with external visualization and analysis codes
- Core-level spectroscopy calculations
- Transport properties calculations

## Directory Structure

The PP module is organized into the following subdirectories:

- **src/**: Contains all source code files for the various post-processing programs
- **Doc/**: Documentation files including input file descriptions for each program
- **examples/**: Comprehensive set of examples demonstrating various features
- **simple_transport/**: Tools for calculating transport properties
- **tools/**: Additional utility scripts and programs

## Key Source Files

### Main Programs (src/)

1. **postproc.f90** - Main post-processing program (pp.x)
   - Extracts and processes various quantities from pw.x output
   - Handles charge density, potential, STM images, ELF, etc.

2. **dos.f90** - Density of States calculator (dos.x)
   - Computes total DOS with various broadening schemes
   - Supports spin-polarized calculations

3. **projwfc.f90** - Projected Density of States (projwfc.x)
   - Projects wavefunctions onto atomic orbitals
   - Calculates Löwdin charges and PDOS

4. **bands.f90** - Band structure processor (bands.x)
   - Processes band structure data from pw.x
   - Identifies band symmetries

5. **plotband.f90** - Band structure plotter (plotband.x)
   - Formats band data for plotting

6. **average.f90** - Planar/spherical averages (average.x)
   - Computes averages of charge/potential
   - Useful for surface/interface calculations

7. **pw2wannier90.f90** - Interface to Wannier90 (pw2wannier90.x)
   - Prepares data for Wannier function calculations

8. **epsilon.f90** - Dielectric function calculator (epsilon.x)
   - Computes optical properties

9. **fermisurface.f90** - Fermi surface generator (fs.x)
   - Creates data for Fermi surface visualization

10. **molecularpdos.f90** - Molecular PDOS (molecularpdos.x)
    - Projects DOS onto molecular orbitals

### Supporting Modules

1. **chdens_module.f90** - Charge density manipulation routines
2. **projections_mod.f90** - Wavefunction projection utilities
3. **wannier_mod.f90** - Wannier function support
4. **fermisurfer_common.f90** - Fermi surface calculation utilities
5. **fft_interpolation_mod.f90** - FFT-based interpolation methods
6. **oscdft_pp_mod.f90** - Oxidation state constrained DFT post-processing

### Interface Programs

1. **pw2bgw.f90** - Interface to BerkeleyGW
2. **pw2gw.f90** - Interface for GW calculations
3. **pw2critic.f90** - Interface to Critic2
4. **ppacf.f90** - Adiabatic connection fluctuation-dissipation
5. **wannier2pw.f90** - Import Wannier functions back to QE

## Core Functionality

### Main Subroutines and Functions

1. **extract()** (in postproc.f90)
   - Main routine for extracting quantities from pw.x output
   - Handles various plot types (charge, potential, ELF, etc.)

2. **do_dos()** (in dos.f90)
   - Calculates density of states using tetrahedron or broadening methods
   - Supports various smearing functions

3. **do_projwfc()** (in projwfc.f90)
   - Projects KS states onto atomic wavefunctions
   - Computes Löwdin populations and spilling parameters

4. **punch_band()** (in bands.f90)
   - Processes and outputs band structure data
   - Performs symmetry analysis of bands

5. **do_average()** (in average.f90)
   - Computes 1D, 2D averages of 3D quantities
   - Macroscopic averages for surfaces

### Key Algorithms Implemented

1. **Tetrahedron method** - For accurate DOS calculations
2. **Löwdin orthogonalization** - For projected DOS
3. **FFT interpolation** - For band structure interpolation
4. **Wannier projection** - Interface to Wannier90
5. **STM simulation** - Tersoff-Hamann approximation
6. **ELF calculation** - Electron localization function

### Data Structures Used

- **plot_type** - Stores information about quantities to plot
- **projection_type** - Manages atomic projection data
- **tetrahedra_type** - For tetrahedron method in DOS
- **wannier_data** - Wannier function information

## Dependencies

The PP module depends on several other Quantum ESPRESSO modules:

1. **PW/src** - Core PWscf routines and data structures
2. **Modules/** - Basic modules (kinds, constants, io, fft, etc.)
3. **KS_Solvers/** - Kohn-Sham solver routines
4. **dft-d3/** - DFT-D3 dispersion corrections
5. **UtilXlib/** - Utility libraries
6. **FFTXlib/** - FFT libraries

External dependencies:
- MPI libraries for parallel execution
- BLAS/LAPACK for linear algebra
- Optional: Wannier90 library for wannier functions

## Build System

The PP module uses a hierarchical Makefile system:

1. **Main Makefile** (PP/Makefile)
   - Coordinates building of all subdirectories
   - Targets: all, clean, doc

2. **src/Makefile**
   - Builds all executable programs
   - Creates libpp.a library with common routines
   - Links executables to ../../bin/

3. **Compilation**:
   ```
   cd PP
   make all
   ```
   This creates all PP executables and installs them in QE/bin/

4. **Key make variables**:
   - MODFLAGS: Module search paths
   - PPOBJS: Object files for libpp.a
   - QELIBS: QE library dependencies

The build system automatically handles dependencies through make.depend and ensures proper linking with other QE modules.