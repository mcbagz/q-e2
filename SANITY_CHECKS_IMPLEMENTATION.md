# Sanity Checks Implementation Summary

## Overview
This document summarizes the implementation of Tasks 8 and 9 from the GamePlan.md, which introduce a comprehensive sanity check system to Quantum ESPRESSO.

## Files Created/Modified

### New Modules Created:

1. **Modules/sanity_config.f90**
   - Handles INI file configuration for sanity checks
   - Provides load/save functionality for user preferences
   - Supports command-line configuration overrides
   - Default config location: ~/.qe/config.ini

2. **Modules/sanity_checks.f90**
   - Implements the actual sanity check routines
   - Checks for:
     - Atomic distances too close (< 0.5 Å critical, < 1.0 Å warning)
     - Extreme cell parameters (small cells, extreme angles, high aspect ratios)
     - Isolated atoms (no neighbors within 5 Å)
     - Symmetry-breaking issues
   - Provides user interaction with configurable prompting

### Modified Files:

1. **Modules/command_line_options.f90**
   - Added support for new command-line flags:
     - `--ignore-sanity-checks`: Skip all sanity checks
     - `--sanity-checks-only`: Run only sanity checks and exit
     - `--force`: Continue despite warnings/errors
     - `--config`: Set configuration values

2. **PW/src/setup.f90**
   - Integrated sanity check calls after crystal structure setup
   - Added proper MPI handling for user prompts
   - Ensures checks run before heavy computations

3. **Modules/CMakeLists.txt**
   - Added sanity_config.f90 and sanity_checks.f90 to build system

### Test Suite Created:

**test-suite/pw_sanity/**
- `sanity_close_atoms.in`: Tests critical distance warnings
- `sanity_extreme_cell.in`: Tests cell parameter warnings
- `sanity_isolated_atom.in`: Tests isolated atom detection
- `sanity_force_continue.in`: Tests command-line flag behavior
- `README`: Documentation for running tests

## Key Features

### Configuration System
- INI file format for easy editing
- Per-user (~/.qe/config.ini) and per-project (.qe_config) settings
- Runtime configuration updates via command line
- Settings include:
  - `enabled`: Turn checks on/off
  - `level`: Minimum warning level (info/warning/critical)
  - `prompt_on_warning`: Ask user before continuing (deprecated, defaults to false)
  - `prompt_on_critical`: Ask user on critical issues (deprecated, defaults to false)

### MPI Considerations
- Only root rank performs user interaction
- Decisions are broadcast to all ranks
- File I/O operations restricted to meta_ionode
- Proper synchronization ensures consistent behavior

### User Experience
- Clear, formatted warning reports **printed to stderr**
- Non-intrusive - warnings shown but execution continues
- Easy to disable for experienced users
- Command-line overrides for automation
- Helpful suggestions for each warning

## Usage Examples

```bash
# Normal run with sanity checks (warnings to stderr, calculation continues)
pw.x -input silicon.in 2>&1 | tee output.log

# Skip all sanity checks
pw.x -input silicon.in --ignore-sanity-checks

# Run sanity checks only (no calculation)
pw.x -input silicon.in --sanity-checks-only

# Update configuration
pw.x --config sanity_checks.enabled=false
```

## Key Changes in This Version

1. **Removed --force flag**: The program now always continues after showing warnings. Users see the issues but aren't interrupted.

2. **stderr output**: All sanity check messages now go to stderr instead of stdout. This ensures users see warnings in the terminal even when redirecting stdout to a file.

## Testing Instructions

The implementation is ready for testing in a Docker environment. To test:

1. Build Quantum ESPRESSO with the new modules
2. Run the test cases in test-suite/pw_sanity/
3. Verify MPI behavior with multiple processes
4. Test configuration persistence across runs

## Future Enhancements

The sanity check system is designed to be extensible. Additional checks can be added to sanity_checks.f90 following the existing pattern. The GUI integration (Task 10+) will use the `--sanity-checks-only` flag for pre-flight validation.