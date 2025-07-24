# Checkpoint Functionality Fixes

## Issues Fixed

### 1. Terminal Output Visibility
**Problem**: Checkpoint/snapshot messages were going to stdout, which gets redirected to .out files when using `pw.x > output.out`

**Solution**: Changed all checkpoint-related WRITE statements to use stderr (unit 0) instead of stdout
- Modified `Modules/checkpoint_manager.f90`: All `WRITE(stdout,...)` → `WRITE(0,...)`
- Modified `PW/src/electrons.f90`: All checkpoint/snapshot `WRITE(stdout,...)` → `WRITE(0,...)`

**Result**: Messages now appear in terminal even with output redirection

### 2. Recurring Snapshot Issue
**Problem**: Snapshots were being created continuously every SCF cycle after SIGUSR2 signal

**Root Cause**: 
- C flag was being reset but Fortran flag `snapshot_requested` remained `.TRUE.`
- Duplicate flag reset in `check_checkpoint_signals()` was causing confusion

**Solution**:
1. Removed duplicate `reset_snapshot_flag()` call from `check_checkpoint_signals()`
2. Added proper Fortran flag reset: `snapshot_requested = .FALSE.` after snapshot creation
3. Applied same fix for checkpoint: `soft_pause_requested = .FALSE.` after checkpoint

**Result**: Only one snapshot per signal, as intended

## Code Changes Summary

### Modules/checkpoint_manager.f90
```fortran
! Changed all output to stderr
WRITE(stdout, ...) → WRITE(0, ...)

! Removed duplicate flag reset
IF ( snapshot_flag /= 0 ) THEN
    snapshot_requested = .TRUE.
    ! REMOVED: CALL reset_snapshot_flag()
    WRITE(0, '(/,5X,"*** SNAPSHOT SIGNAL RECEIVED ***")')
END IF
```

### PW/src/electrons.f90
```fortran
! Snapshot handling - added Fortran flag reset
IF ( snapshot_requested ) THEN
    WRITE(0, ...) ! Changed to stderr
    CALL write_status_snapshot(iter, etot)
    CALL reset_snapshot_flag()      ! Reset C flag
    snapshot_requested = .FALSE.    ! Reset Fortran flag (NEW)
    WRITE(0, ...)
ENDIF

! Checkpoint handling - added Fortran flag reset
IF ( soft_pause_requested ) THEN
    WRITE(0, ...) ! Changed to stderr
    ...
    CALL reset_soft_pause_flag()    ! Reset C flag
    soft_pause_requested = .FALSE.  ! Reset Fortran flag (NEW)
    ...
ENDIF
```

## Testing

Build and test with:
```bash
# Build
docker build -t qe-checkpoint .

# Run with output redirection
docker run -it qe-checkpoint pw.x -in input.in > output.out 2>&1

# In another terminal, send signals
docker ps  # Get container ID
docker exec <container_id> kill -USR2 1  # Should see message in terminal
docker exec <container_id> kill -USR1 1  # Should see message in terminal

# Verify only one snapshot created
ls -la snapshots/  # Should see only one file per signal
```

## Expected Terminal Output

Even with `> output.out` redirection, you'll now see in the terminal:

For SIGUSR2:
```
*** SNAPSHOT SIGNAL RECEIVED ***
*** STATUS SNAPSHOT REQUESTED ***
Current SCF iteration: 3
Current total energy: -15.84231567 Ry
Snapshot timestamp: 2024/01/23 14:35:20
Writing snapshot to: ./snapshots/test_checkpoint20240123_143520_snapshot.txt
Snapshot file created successfully
Snapshot complete, calculation continuing...
```

For SIGUSR1:
```
*** SOFT PAUSE SIGNAL RECEIVED ***
Will complete current SCF cycle and write checkpoint...
*** SOFT PAUSE REQUESTED ***
Completing current SCF iteration before checkpoint...
```

Then after SCF completion:
```
*** CHECKPOINT CREATION ***
SCF iteration 5 completed
Total energy: -15.84562369 Ry
Energy convergence: T

Creating checkpoint files:
Checkpoint timestamp: 2024/01/23 14:35:42
Writing checkpoint info to: checkpoint_scf.dat.info
Checkpoint info file created successfully
Saving calculation data to: ./test_checkpoint.save/

Checkpoint complete. Exiting calculation.
To resume: pw.x --resume-from checkpoint_scf.dat -in input.in
```