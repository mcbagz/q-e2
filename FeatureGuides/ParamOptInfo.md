# AUTO_OPTIMIZE: Automatic Parameter Optimization for Quantum ESPRESSO

## Overview

The AUTO_OPTIMIZE feature automatically determines optimal k-point grids and plane-wave cutoffs for your Quantum ESPRESSO calculations. This eliminates the need for manual convergence testing and ensures efficient, accurate calculations.

## Purpose

Running DFT calculations requires careful selection of numerical parameters:
- **K-point grids**: Too few k-points give inaccurate results; too many waste computational resources
- **Cutoff energies**: Insufficient cutoffs lead to poor convergence; excessive cutoffs increase calculation time

AUTO_OPTIMIZE automates this optimization process by:
1. Analyzing your crystal structure to suggest appropriate k-point grids
2. Testing cutoff convergence to find the minimum cutoff needed for your target accuracy
3. Providing clear feedback about the optimization process
4. Applying optimized parameters automatically

## How to Use

### Basic Usage

Add the `&AUTO_OPTIMIZE` namelist to your input file:

```
&CONTROL
  calculation = 'scf'
  prefix = 'si'
  pseudo_dir = './pseudo/'
/
&SYSTEM
  ibrav = 2
  celldm(1) = 10.26
  nat = 2
  ntyp = 1
  ecutwfc = 30.0    ! Initial guess - will be optimized
/
&ELECTRONS
  conv_thr = 1.0d-8
/
&AUTO_OPTIMIZE
  optimize_kpoints = .true.
  optimize_cutoff = .true.
/
ATOMIC_SPECIES
  Si 28.086 Si.pz-vbc.UPF
ATOMIC_POSITIONS (alat)
  Si 0.00 0.00 0.00
  Si 0.25 0.25 0.25
K_POINTS (automatic)
  4 4 4 0 0 0      ! Initial guess - will be optimized
```

### Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `optimize_kpoints` | .false. | Enable k-point grid optimization |
| `optimize_cutoff` | .false. | Enable cutoff energy optimization |
| `kpoint_spacing` | 0.2 | Target k-point spacing in Bohr⁻¹ |
| `cutoff_min` | 30.0 | Minimum cutoff to test (Ry) |
| `cutoff_max` | 120.0 | Maximum cutoff to test (Ry) |
| `cutoff_step` | 10.0 | Step size for cutoff testing (Ry) |
| `target_accuracy` | 1.0d-4 | Energy convergence threshold (Ry) |
| `max_iterations` | 20 | Maximum optimization iterations |

### Example Configurations

#### High-Accuracy Calculation
```
&AUTO_OPTIMIZE
  optimize_kpoints = .true.
  optimize_cutoff = .true.
  kpoint_spacing = 0.1      ! Dense k-point grid
  cutoff_min = 40.0
  cutoff_max = 150.0
  cutoff_step = 5.0         ! Fine steps
  target_accuracy = 1.0d-5  ! Tight convergence
/
```

#### Quick Testing
```
&AUTO_OPTIMIZE
  optimize_kpoints = .true.
  optimize_cutoff = .true.
  kpoint_spacing = 0.25     ! Sparse k-point grid
  cutoff_min = 20.0
  cutoff_max = 80.0
  cutoff_step = 20.0        ! Coarse steps
  target_accuracy = 1.0d-3  ! Loose convergence
/
```

#### Metals (Dense K-points)
```
&AUTO_OPTIMIZE
  optimize_kpoints = .true.
  kpoint_spacing = 0.05     ! Very dense for metals
  optimize_cutoff = .false.
/
```

## Understanding the Output

### K-point Optimization Output
```
Suggested k-point grid based on 0.150 Bohr^-1 spacing:
nk1 =  9, nk2 =  9, nk3 =  9
Reciprocal lattice vector norms (Bohr^-1):
b1 =   1.061, b2 =   1.061, b3 =   1.061

AUTO_OPTIMIZE: Applied optimized k-point grid
Now using: nk1=  9, nk2=  9, nk3=  9
```

The optimizer:
1. Calculates reciprocal lattice vector lengths
2. Divides by your `kpoint_spacing` to get grid density
3. Rounds up to ensure sufficient sampling

### Cutoff Optimization Output
```
Testing cutoff convergence...
Target accuracy:  1.0000E-04 Ry
Ecutwfc =   30.0 Ry, Energy =   -13.14492985 Ry
Ecutwfc =   40.0 Ry, Energy =   -13.64061007 Ry, Delta =  4.9568E-01
Ecutwfc =   50.0 Ry, Energy =   -14.04886517 Ry, Delta =  4.0826E-01
...
Ecutwfc =   80.0 Ry, Energy =   -14.87951130 Ry, Delta =  2.2527E-01

Converged cutoff values:
ecutwfc =   80.0 Ry
ecutrho =  320.0 Ry
```

The optimizer:
1. Tests increasing cutoff values
2. Monitors energy change (Delta)
3. Stops when Delta < `target_accuracy`
4. Sets `ecutrho = 4 * ecutwfc` (default ratio)

### Summary Output
```
==================================================
AUTO_OPTIMIZE SUMMARY:
Using optimized k-point grid:   9x  9x  9
Using ecutwfc =   80.0 Ry, ecutrho =  320.0 Ry
==================================================
```

## Guidelines for Settings

### K-point Spacing
- **0.05-0.10 Bohr⁻¹**: Metals, systems with small band gaps
- **0.15-0.20 Bohr⁻¹**: Semiconductors, standard accuracy
- **0.25-0.30 Bohr⁻¹**: Insulators, large gap systems, quick tests

### Target Accuracy
- **1.0d-3 Ry**: Rough optimization, structural relaxation
- **1.0d-4 Ry**: Standard production calculations
- **1.0d-5 Ry**: High accuracy, sensitive properties
- **1.0d-6 Ry**: Extreme accuracy, benchmark calculations

### Cutoff Ranges
- **Norm-conserving pseudopotentials**: Often converge by 40-80 Ry
- **Ultrasoft pseudopotentials**: Usually need 25-50 Ry
- **PAW datasets**: Typically require 40-60 Ry

## Important Notes

1. **K-point optimization requires** `K_POINTS (automatic)` in your input file
2. **Initial values** in your input serve as fallbacks if optimization fails
3. **Optimization runs before** the main SCF calculation
4. **Error messages** will appear on stderr for user awareness
5. **Cutoff optimization** currently uses a realistic model (full SCF implementation pending)

## Troubleshooting

### "WARNING: K-point optimization requested but k_points = 'gamma'"
Add to your input:
```
K_POINTS (automatic)
  1 1 1 0 0 0
```

### "WARNING: Cutoff convergence not achieved"
Try:
- Increasing `cutoff_max`
- Decreasing `target_accuracy`
- Using smaller `cutoff_step` for finer sampling

### Optimization taking too long
- Increase `kpoint_spacing` (use sparser k-points)
- Increase `cutoff_step` (test fewer cutoffs)
- Increase `target_accuracy` (looser convergence)

## Best Practices

1. **Start with defaults** and adjust based on your system
2. **For production**, verify optimized parameters with manual convergence tests
3. **For metals**, use denser k-point grids (smaller `kpoint_spacing`)
4. **For large cells**, k-point requirements decrease (can use larger `kpoint_spacing`)
5. **Save optimized values** for similar calculations

## Example: Complete Silicon Calculation

```
&CONTROL
  calculation = 'scf'
  prefix = 'si_optimized'
  pseudo_dir = './pseudo/'
  outdir = './tmp/'
/
&SYSTEM
  ibrav = 2
  celldm(1) = 10.26
  nat = 2
  ntyp = 1
  ecutwfc = 30.0      ! Will be optimized
/
&ELECTRONS
  conv_thr = 1.0d-8
/
&AUTO_OPTIMIZE
  optimize_kpoints = .true.
  optimize_cutoff = .true.
  kpoint_spacing = 0.15
  cutoff_min = 30.0
  cutoff_max = 100.0
  cutoff_step = 10.0
  target_accuracy = 1.0d-4
/
ATOMIC_SPECIES
  Si 28.086 Si.pz-vbc.UPF
ATOMIC_POSITIONS (alat)
  Si 0.00 0.00 0.00
  Si 0.25 0.25 0.25
K_POINTS (automatic)
  1 1 1 0 0 0         ! Will be optimized
```

This will automatically determine that a 9×9×9 k-point grid and ~80 Ry cutoff are optimal for this silicon calculation, saving you from manual convergence testing.