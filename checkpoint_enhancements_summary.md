# Checkpoint Functionality Enhancements

## Summary of Changes

### 1. Fixed Checkpoint Creation Issue
- **Problem**: Checkpoint was not creating files due to premature iteration increment
- **Solution**: Removed early `iter++` in soft pause handling, allowing normal SCF flow

### 2. Enhanced Terminal Output

#### Checkpoint (SIGUSR1) Terminal Output:
```
*** SOFT PAUSE REQUESTED ***
Completing current SCF iteration before checkpoint...

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

#### Snapshot (SIGUSR2) Terminal Output:
```
*** STATUS SNAPSHOT REQUESTED ***
Current SCF iteration: 3
Current total energy: -15.84231567 Ry
Snapshot timestamp: 2024/01/23 14:35:20
Writing snapshot to: ./snapshots/test_checkpoint20240123_143520_snapshot.txt
Snapshot file created successfully
Snapshot complete, calculation continuing...
```

### 3. Files Created

#### Checkpoint Files:
- `checkpoint_scf.dat.info` - Checkpoint metadata (iteration, energy, timestamp)
- `{prefix}.save/` - Full calculation data (via punch('config'))

#### Snapshot Files:
- `snapshots/{prefix}YYYYMMDD_HHMMSS_snapshot.txt` - Status snapshot file

### 4. Flag Management
- Added proper reset of `soft_pause_flag` after checkpoint creation
- `snapshot_flag` already resets immediately after use

### 5. Testing
- Created `test_enhanced_checkpoint.sh` for comprehensive testing
- Tests both SIGUSR1 and SIGUSR2 functionality
- Verifies file creation and output messages

## Docker Build & Usage

```bash
# Build
docker build -t qe-checkpoint .

# Run with checkpointing
docker run -it qe-checkpoint pw.x -in input.in

# Send signals (from another terminal)
docker ps  # Get container ID
docker exec <container_id> kill -USR1 1  # Checkpoint
docker exec <container_id> kill -USR2 1  # Snapshot

# Resume from checkpoint
docker run -it qe-checkpoint pw.x --resume-from checkpoint_scf.dat -in input.in
```

## Key Improvements
1. ✅ Checkpoint now creates files correctly
2. ✅ Detailed terminal output for both operations
3. ✅ Clear file paths shown to user
4. ✅ Proper signal flag management
5. ✅ Resume instructions displayed after checkpoint