# Quantum ESPRESSO Checkpoint Implementation Summary

## Overview
This document summarizes the implementation of signal-based checkpointing and status monitoring features for Quantum ESPRESSO, as specified in Tasks 1, 2, and 3 of the GamePlan.

## Features Implemented

### 1. Signal-Based Checkpointing (SIGUSR1)
- **Soft pause signal**: When SIGUSR1 is received, the calculation completes the current SCF cycle, writes a checkpoint file, and exits gracefully
- **Non-disruptive**: Ensures the SCF cycle completes before creating checkpoint
- **Checkpoint file**: Contains all necessary data to resume the calculation

### 2. Status Monitoring (SIGUSR2)
- **Snapshot signal**: When SIGUSR2 is received, a status snapshot is written without interrupting execution
- **Continuous operation**: The calculation continues running after writing the snapshot
- **Snapshot content**: Current iteration, total energy, timestamp, and optionally forces/stress

### 3. Resume Functionality
- **Command-line flag**: `--resume-from <checkpoint_file>` to continue from a saved checkpoint
- **Automatic state restoration**: Loads all necessary data and continues from the saved point
- **Validation**: Checks compatibility of checkpoint data with current system

## Implementation Details

### New Files Created

1. **`Modules/checkpoint_manager.f90`**
   - Core module providing checkpoint functionality
   - Exports: `install_checkpoint_handlers`, `check_checkpoint_signals`, `write_checkpoint`, `load_checkpoint`, `write_status_snapshot`
   - Manages signal flags and checkpoint I/O

2. **`Modules/signal_wrap.c`**
   - C wrapper for POSIX signal handling
   - Implements signal handlers for SIGUSR1 and SIGUSR2
   - Provides flag checking/resetting functions for Fortran

3. **`test_checkpoint.sh`**
   - Test script demonstrating all checkpoint features
   - Tests signal sending, checkpoint creation, and resume

4. **`qe-control.sh`**
   - Command-line tool for controlling background QE processes
   - Commands: `status`, `pause <pid>`, `snapshot <pid>`

### Modified Files

1. **`Modules/command_line_options.f90`**
   - Added `checkpoint_file_` variable
   - Added parsing for `--resume-from` flag
   - Added broadcast of checkpoint filename

2. **`PW/src/run_pwscf.f90`**
   - Added checkpoint handler installation
   - Added checkpoint loading logic when `--resume-from` is specified
   - Sets `restart = .TRUE.` when resuming

3. **`PW/src/electrons.f90`**
   - Added signal checking at start of each SCF iteration
   - Handles soft pause by completing current cycle then checkpointing
   - Handles snapshot by writing status and continuing

4. **`Modules/Makefile`**
   - Added `checkpoint_manager.o` to MODULES list
   - Added `signal_wrap.o` to OBJS list

## Usage Examples

### Basic Usage

```bash
# Start a calculation
pw.x -input silicon.in &

# Get the process ID
PID=$!

# Request a status snapshot (calculation continues)
kill -USR2 $PID

# Request checkpoint and pause (completes current cycle)
kill -USR1 $PID

# Resume from checkpoint
pw.x -input silicon.in --resume-from checkpoint_scf.dat
```

### Using the Control Script

```bash
# Check status of running calculations
./qe-control.sh status

# Pause a specific process
./qe-control.sh pause 12345

# Take a snapshot
./qe-control.sh snapshot 12345
```

## Keyboard Shortcuts

While the POSIX signal implementation doesn't directly support keyboard shortcuts like Ctrl+Shift+C, the functionality can be accessed through:

1. Terminal job control (Ctrl+Z, fg, bg)
2. The `qe-control.sh` script
3. Custom terminal key bindings that send signals

## Testing

Run the test script to verify all functionality:

```bash
./test_checkpoint.sh
```

This will:
1. Start a test calculation
2. Send snapshot signal and verify snapshot creation
3. Send pause signal and verify checkpoint creation
4. Resume from checkpoint and verify continuation

## Implementation Notes

### Thread Safety
- Signal flags are marked as `volatile sig_atomic_t` in C
- MPI broadcast ensures all processes are synchronized

### Performance Impact
- Minimal overhead: only flag checking at SCF iteration start
- Checkpoint I/O only occurs when requested
- Snapshot writing is asynchronous to calculation

### File Formats
- Checkpoint files: Binary format with version header
- Snapshot files: Human-readable text format
- Timestamped filenames prevent overwrites

### Error Handling
- Graceful fallback if signal installation fails
- Validation of checkpoint compatibility
- Clear error messages for user guidance

## Future Enhancements

Potential improvements not included in this implementation:

1. **Automatic checkpointing**: Periodic checkpoints based on time/iterations
2. **Checkpoint compression**: Reduce checkpoint file sizes
3. **Multiple checkpoint slots**: Maintain history of checkpoints
4. **GUI integration**: Direct integration with QE GUI
5. **Network control**: Remote checkpoint control via sockets

## Building and Installation

The implementation integrates with the standard QE build system:

```bash
# Standard QE build process
./configure
make pw

# The new files are automatically included via updated Makefiles
```

## Compatibility

- Compatible with existing QE input files (no changes required)
- Works with MPI parallel calculations
- Platform-specific signal handling (POSIX systems)
- Windows support would require alternative implementation

This implementation provides a robust foundation for checkpoint/restart functionality in Quantum ESPRESSO, enabling long-running calculations to be safely paused and resumed as needed.