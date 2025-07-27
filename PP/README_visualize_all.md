# Automated Visualization Feature for pp.x

## Overview

The `pp.x` post-processing tool now includes an automated visualization mode that can generate all possible visualizations from a completed Quantum ESPRESSO calculation without requiring manual input file creation.

## Usage

```bash
pp.x --visualize-all -in path/to/output.save
```

Where `path/to/output.save` is the output directory from a completed `pw.x` calculation.

## Features

The automated mode will:

1. **Analyze the output directory** to determine what data is available
2. **Generate appropriate visualizations** for all available quantities:
   - Total charge density
   - Spin-up and spin-down charge densities (for spin-polarized calculations)
   - Total potential (V_bare + V_H + V_xc)
   - Electron Localization Function (ELF)
   - Spin density/magnetization (for spin-polarized calculations)
3. **Save all outputs in XSF format** for easy visualization with XCrySDen or VESTA
4. **Provide a summary report** listing all generated files

## Implementation Details

### New Files Added

1. **PP/src/auto_vis_analyzer.f90** - Module for analyzing calculation output directories
2. **PP/Doc/INPUT_PP.def** - Updated documentation

### Modified Files

1. **PP/src/postproc.f90** - Added command-line parsing and auto_visualize subroutine
2. **PP/src/Makefile** - Added auto_vis_analyzer.o to compilation
3. **PP/CMakeLists.txt** - Added auto_vis_analyzer.f90 to source list

### Test Suite

A new test case has been added in `test-suite/pp_visualize_all/` that:
- Runs a simple Si calculation
- Tests the --visualize-all feature
- Verifies that expected output files are generated

## Example Output

```
Automated Visualization Complete
------------------------------------------------------------------------
File                          Description
------------------------------------------------------------------------
charge_density.xsf            Total charge density
potential.xsf                 Total potential (V_loc+V_H+V_xc)
elf.xsf                       Electron Localization Function (ELF)
------------------------------------------------------------------------
Total files generated:   3
All files are in XSF format for visualization
```

## Benefits

- **Ease of use**: No need to write multiple input files for different visualizations
- **Comprehensive**: Automatically generates all possible visualizations
- **Time-saving**: Ideal for quickly exploring calculation results
- **Consistent format**: All outputs in XSF format for compatibility

## Future Enhancements

Potential improvements could include:
- Support for additional plot types (STM images, wavefunctions, etc.)
- Multiple output format options (cube, PLT, etc.)
- Customizable resolution and plotting parameters
- Batch processing of multiple calculations