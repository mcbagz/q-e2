# Quantum ESPRESSO Architecture Overview

## 1. High-Level Summary

Quantum ESPRESSO (QE) is a modular suite of electronic structure codes built on a layered architecture. At its core, QE performs Density Functional Theory (DFT) calculations using plane wave basis sets and pseudopotentials. The architecture consists of:

- **Foundation Libraries**: Low-level utilities for parallelization (UtilXlib), FFT operations (FFTXlib), and linear algebra (LAXlib)
- **Core Infrastructure**: Common modules, pseudopotential handling (upflib), and exchange-correlation functionals (XClib)
- **Computational Engines**: DFT solvers (PW, CPV), linear response (LR_Modules), and iterative eigensolvers (KS_Solvers)
- **Specialized Applications**: Domain-specific codes for phonons, transport, spectroscopy, and advanced electronic structure methods

## 2. Module Groups by Functionality

### 2.1 Foundation Layer

**UtilXlib** - Essential utilities including MPI wrappers, timing/clocks, memory management, and error handling. Forms the base layer that all other modules depend on.

**FFTXlib** - Parallel FFT library optimized for plane-wave DFT, supporting multiple backends (FFTW, MKL, cuFFT) with advanced parallelization strategies.

**LAXlib** - Linear algebra extensions providing optimized routines for electronic structure calculations, including parallel diagonalization and GPU acceleration.

### 2.2 Core Infrastructure

**Modules** - Central repository of shared functionality including physical constants, data types, I/O operations, parallelization infrastructure, and environment setup.

**upflib** - Unified Pseudopotential Format library handling all pseudopotential operations, supporting norm-conserving, ultrasoft, and PAW methods.

**XClib** - Exchange-correlation functional library implementing LDA, GGA, and meta-GGA functionals with GPU acceleration and external library interfaces.

**KS_Solvers** - Collection of iterative eigensolvers (Davidson, CG, RMM-DIIS, ParO) for the Kohn-Sham equation with CPU/GPU implementations.

### 2.3 DFT Engines

**PW** - Plane Wave Self-Consistent Field engine, the main DFT workhorse supporting ground state calculations, structural optimization, and molecular dynamics.

**CPV** - Car-Parrinello molecular dynamics implementation for simultaneous evolution of electronic and ionic degrees of freedom.

**atomic** - All-electron atomic calculations and pseudopotential generation based on radial Schrödinger equation solvers.

### 2.4 Linear Response and Phonons

**LR_Modules** - Shared linear response routines implementing Density Functional Perturbation Theory (DFPT) for various perturbations.

**PHonon** - Comprehensive phonon calculation package computing vibrational properties, dielectric response, and electron-phonon coupling.

**TDDFPT** - Time-dependent DFT for optical spectra, implementing Lanczos and Davidson algorithms for excitation energies.

### 2.5 Post-Processing and Analysis

**PP** - Post-processing suite for analyzing DFT results including band structures, DOS, charge densities, and Wannier function interfaces.

**NEB** - Nudged Elastic Band for finding minimum energy paths and transition states in chemical reactions.

### 2.6 Advanced Electronic Structure

**HP** - Automated calculation of Hubbard U parameters from first principles using linear response theory.

**GWW** - Many-body perturbation theory implementation for GW and Bethe-Salpeter equation calculations.

**KCW** - Koopmans-compliant functionals using Wannier functions for improved band gaps and spectral properties.

**EPW** - Electron-phonon Wannier code for transport properties, superconductivity, and polaron physics.

### 2.7 Transport and Spectroscopy

**PWCOND** - Ballistic quantum transport calculations using scattering theory and complex band structures.

**QEHeat** - Thermal transport calculations computing energy flux and heat currents from molecular dynamics.

**XSpectra** - X-ray absorption spectroscopy (XANES) calculations using Lanczos algorithm.

### 2.8 Interface and Coupling

**COUPLE** - Library interface allowing external programs to call QE as a subroutine for QM/MM and multiscale simulations.

## 3. Module Dependencies

```
┌─────────────────────────────────────────────────────────┐
│                    Applications Layer                    │
│  EPW  GWW  HP  KCW  PWCOND  QEHeat  XSpectra  TDDFPT   │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────────────┐
│              Computational Engines Layer                 │
│         PW          CPV        PHonon      PP           │
│                  LR_Modules    NEB                      │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────────────┐
│                Core Infrastructure Layer                 │
│    Modules    upflib    XClib    KS_Solvers            │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────────────┐
│                  Foundation Layer                        │
│        UtilXlib      FFTXlib      LAXlib               │
└─────────────────────────────────────────────────────────┘
```

## 4. Workflow Connections

### 4.1 Basic DFT Calculation Flow
```
Input → PW (SCF) → PP (Analysis) → Output
         ↓
      [Optional]
         ↓
    PHonon/NEB/etc.
```

### 4.2 Advanced Electronic Structure Flow
```
PW → Wannier90 → EPW/KCW → Transport/Spectroscopy
 ↓
HP → DFT+U → GWW → BSE
```

### 4.3 Molecular Dynamics Flow
```
Initial Structure → CPV/PW → Trajectory → QEHeat → Thermal Properties
                      ↓
                 [Analysis]
                      ↓
                     PP
```

## 5. Commonly Used Module Combinations

### 5.1 Standard DFT Studies
- **PW + PP**: Basic electronic structure calculations with analysis
- **PW + PHonon**: Vibrational properties and thermodynamics
- **PW + NEB**: Reaction pathways and barriers

### 5.2 Spectroscopy Calculations
- **PW + TDDFPT**: Optical absorption spectra
- **PW + XSpectra**: X-ray absorption spectroscopy
- **PW + GWW**: Photoemission spectroscopy

### 5.3 Transport Properties
- **PW + EPW**: Electron-phonon coupling and carrier mobility
- **PW + PWCOND**: Ballistic electron transport
- **CPV + QEHeat**: Thermal conductivity

### 5.4 Strongly Correlated Systems
- **PW + HP**: Automated Hubbard parameter determination
- **PW + Wannier90 + KCW**: Koopmans corrections for band gaps

## 6. Starting Points for Different Calculations

### Ground State Properties
Start with **PW** for self-consistent field calculations. Use **PP** for post-processing (DOS, band structure, charge density visualization).

### Structural Optimization
Use **PW** with appropriate `calculation` flags ('relax', 'vc-relax') or **NEB** for reaction pathways.

### Vibrational Properties
Begin with **PW** ground state, then use **PHonon** for phonon frequencies, IR/Raman spectra, and thermodynamic properties.

### Optical Properties
After **PW** calculation, use **TDDFPT** for absorption spectra or **GWW** for more accurate quasiparticle corrections.

### Transport Calculations
Use **PW** + **Wannier90** + **EPW** for electron-phonon limited transport or **PWCOND** for ballistic transport.

### Molecular Dynamics
Choose **CPV** for Car-Parrinello MD or **PW** with appropriate dynamics settings. Use **QEHeat** for thermal transport analysis.

### Pseudopotential Generation
Use **atomic** module to generate and test custom pseudopotentials in UPF format.

---

For detailed information about any specific module, consult the corresponding .md file in this directory. Each module documentation includes comprehensive information about functionality, source files, algorithms, and usage examples.