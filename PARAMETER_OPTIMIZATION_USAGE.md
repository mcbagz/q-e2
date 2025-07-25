# AUTO_OPTIMIZE Feature - User Guide

## Overview

The AUTO_OPTIMIZE feature in Quantum ESPRESSO provides automated optimization of computational parameters to help users find the optimal balance between accuracy and computational efficiency. Currently, it supports:

1. **K-point grid optimization** - Automatically determines the optimal k-point mesh based on a target spacing in reciprocal space
2. **Cutoff optimization** - Tests convergence of energy cutoffs (ecutwfc and ecutrho)

## Usage

### Basic Example

Add the `&AUTO_OPTIMIZE` namelist to your input file:

```fortran
&CONTROL
  calculation = 'scf'
  prefix = 'si'
  pseudo_dir = 'pseudo/'
  outdir = './'
/
&SYSTEM
  ibrav = 2
  celldm(1) = 10.26
  nat = 2
  ntyp = 1
  ecutwfc = 30.0    ! This will be overridden if optimize_cutoff=.true.
/
&ELECTRONS
  conv_thr = 1.0d-8
/
&AUTO_OPTIMIZE
  optimize_kpoints = .true.   ! Automatically apply optimal k-point grid
  optimize_cutoff = .true.    ! Test and apply optimal cutoffs
  kpoint_spacing = 0.15       ! Target k-point spacing in Bohr^-1
  target_accuracy = 1.0e-4    ! Target energy accuracy in Ry
/
ATOMIC_SPECIES
  Si 28.086 Si.pbe-n-rrkjus_psl.1.0.0.UPF
ATOMIC_POSITIONS (alat)
  Si 0.00 0.00 0.00
  Si 0.25 0.25 0.25
K_POINTS (automatic)
  4 4 4 0 0 0   ! This will be overridden if optimize_kpoints=.true.
```

### Namelist Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `optimize_kpoints` | LOGICAL | .FALSE. | Enable automatic k-point grid optimization |
| `optimize_cutoff` | LOGICAL | .FALSE. | Enable energy cutoff optimization |
| `target_accuracy` | REAL | 1.0e-4 | Target accuracy for convergence tests (Ry) |
| `max_iterations` | INTEGER | 10 | Maximum optimization iterations |
| `kpoint_spacing` | REAL | 0.15 | Target k-point spacing in Bohr^-1 |
| `cutoff_min` | REAL | 30.0 | Minimum cutoff to test (Ry) |
| `cutoff_max` | REAL | 120.0 | Maximum cutoff to test (Ry) |
| `cutoff_step` | REAL | 10.0 | Step size for cutoff testing (Ry) |

## Feature Details

### K-point Grid Optimization

When `optimize_kpoints = .true.` and `K_POINTS (automatic)` is used:

1. The code calculates the reciprocal lattice vector norms
2. Determines the optimal k-point grid based on the `kpoint_spacing` parameter
3. Ensures odd numbers for better symmetry exploitation
4. **Automatically applies** the optimized grid to the calculation

Example output:
```
============================================================
AUTOMATED PARAMETER OPTIMIZATION
============================================================

Suggested k-point grid based on 0.150 Bohr^-1 spacing:
nk1 =  9, nk2 =  9, nk3 =  9
Reciprocal lattice vector norms (Bohr^-1):
b1 =   1.061, b2 =   1.061, b3 =   1.061

AUTO_OPTIMIZE: Applied optimized k-point grid
Now using: nk1=  9, nk2=  9, nk3=  9
```

### Cutoff Optimization

When `optimize_cutoff = .true.`:

1. Tests a range of cutoffs from `cutoff_min` to `cutoff_max` in steps of `cutoff_step`
2. Currently uses a **mock energy function** for testing (real SCF integration coming soon)
3. Monitors energy convergence with respect to cutoff
4. **Automatically applies** the converged cutoff values

**Note**: The current implementation uses a placeholder energy function. Full SCF-based optimization is under development.

## Best Practices

### For k-point optimization:
- Use `kpoint_spacing = 0.1-0.2` Bohr^-1 for metals
- Use `kpoint_spacing = 0.2-0.3` Bohr^-1 for semiconductors/insulators
- Always verify the suggested grid is reasonable for your system

### For cutoff optimization:
- Start with reasonable `cutoff_min` based on your pseudopotentials
- Set `target_accuracy` based on your required precision
- Currently, manually verify the optimized values until full SCF integration is complete

## Limitations

1. **K-point optimization** only works with `K_POINTS (automatic)`
2. **Cutoff optimization** currently uses a mock energy function - treat results with caution
3. No MPI parallelization for optimization loops yet
4. Limited error handling and validation

## Future Enhancements

- Full SCF integration for cutoff optimization
- Support for other k-point types
- Combined k-point and cutoff optimization
- Material-specific parameter databases
- MPI parallelization of convergence tests
- Smarter convergence algorithms

## Examples

### Example 1: K-points only
```fortran
&AUTO_OPTIMIZE
  optimize_kpoints = .true.
  kpoint_spacing = 0.2    ! Looser grid for insulator
/
```

### Example 2: Cutoffs only
```fortran
&AUTO_OPTIMIZE
  optimize_cutoff = .true.
  cutoff_min = 40.0
  cutoff_max = 100.0
  cutoff_step = 5.0
  target_accuracy = 1.0e-5   ! Tighter convergence
/
```

### Example 3: Both optimizations
```fortran
&AUTO_OPTIMIZE
  optimize_kpoints = .true.
  optimize_cutoff = .true.
  kpoint_spacing = 0.15
  target_accuracy = 5.0e-4   ! Looser for initial optimization
/
```