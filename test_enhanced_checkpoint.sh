#!/bin/bash
#
# Enhanced test script for checkpoint functionality
# Tests SIGUSR1 (checkpoint) and SIGUSR2 (snapshot) signals
#

echo "=== Quantum ESPRESSO Enhanced Checkpoint Test ==="
echo "Testing improved checkpoint and snapshot functionality"
echo

# Create a simple QE input file for testing
cat > test_checkpoint.in << EOF
&control
    calculation = 'scf'
    prefix = 'test_checkpoint'
    pseudo_dir = './'
    outdir = './'
    max_seconds = 3600
    etot_conv_thr = 1.0d-6
    forc_conv_thr = 1.0d-4
/
&system
    ibrav = 2
    celldm(1) = 10.0
    nat = 2
    ntyp = 1
    ecutwfc = 30.0
    nbnd = 8
/
&electrons
    mixing_beta = 0.3
    conv_thr = 1.0d-8
    electron_maxstep = 100
/
ATOMIC_SPECIES
Si  28.086  Si.pbe-n-rrkjus_psl.1.0.0.UPF
ATOMIC_POSITIONS alat
Si 0.00 0.00 0.00
Si 0.25 0.25 0.25
K_POINTS automatic
4 4 4 0 0 0
EOF

echo "1. Starting QE calculation in background..."
echo "   Command: pw.x < test_checkpoint.in > test_checkpoint.out 2>&1 &"
pw.x < test_checkpoint.in > test_checkpoint.out 2>&1 &
PW_PID=$!
echo "   Started with PID: $PW_PID"
echo

# Give it time to initialize and start SCF
echo "2. Waiting for calculation to start (10 seconds)..."
sleep 10

# Test SIGUSR2 (snapshot)
echo "3. Testing SIGUSR2 (status snapshot)..."
echo "   Sending: kill -USR2 $PW_PID"
kill -USR2 $PW_PID
sleep 2

# Check if snapshot was created
if [ -d "snapshots" ]; then
    echo "   ✓ Snapshot directory created"
    SNAPSHOT_COUNT=$(ls -1 snapshots/*.txt 2>/dev/null | wc -l)
    if [ $SNAPSHOT_COUNT -gt 0 ]; then
        echo "   ✓ Found $SNAPSHOT_COUNT snapshot file(s):"
        ls -la snapshots/*.txt | tail -n 5
        echo
        echo "   Latest snapshot content:"
        LATEST_SNAPSHOT=$(ls -t snapshots/*.txt | head -1)
        cat "$LATEST_SNAPSHOT" | head -20
    else
        echo "   ✗ No snapshot files found"
    fi
else
    echo "   ✗ Snapshot directory not created"
fi
echo

# Give more time for SCF to progress
echo "4. Waiting for SCF to progress (10 seconds)..."
sleep 10

# Test SIGUSR1 (checkpoint)
echo "5. Testing SIGUSR1 (checkpoint with soft pause)..."
echo "   Sending: kill -USR1 $PW_PID"
kill -USR1 $PW_PID

# Wait for checkpoint to complete
echo "   Waiting for checkpoint to complete (10 seconds)..."
sleep 10

# Check if process has exited
if ps -p $PW_PID > /dev/null 2>&1; then
    echo "   ! Process still running, forcing termination..."
    kill -TERM $PW_PID 2>/dev/null
else
    echo "   ✓ Process exited after checkpoint"
fi

echo
echo "6. Checking checkpoint files..."

# Check for checkpoint info file
if [ -f "checkpoint_scf.dat.info" ]; then
    echo "   ✓ Checkpoint info file created"
    echo "   Content of checkpoint_scf.dat.info:"
    cat checkpoint_scf.dat.info
else
    echo "   ✗ Checkpoint info file not found"
fi

# Check for save directory
if [ -d "test_checkpoint.save" ]; then
    echo "   ✓ Calculation data saved in test_checkpoint.save/"
    echo "   Directory contents:"
    ls -la test_checkpoint.save/ | head -10
else
    echo "   ✗ Save directory not found"
fi

echo
echo "7. Checking output for checkpoint messages..."
if [ -f "test_checkpoint.out" ]; then
    echo "   Relevant output lines:"
    grep -E "(CHECKPOINT|SNAPSHOT|PAUSE|checkpoint|snapshot)" test_checkpoint.out | tail -20
else
    echo "   ✗ Output file not found"
fi

echo
echo "8. Test summary:"
echo "   - Snapshot functionality: Check snapshots/ directory"
echo "   - Checkpoint functionality: Check checkpoint_scf.dat.info"
echo "   - Full calculation data: Check test_checkpoint.save/"
echo "   - To resume: pw.x --resume-from checkpoint_scf.dat -in test_checkpoint.in"

# Cleanup
echo
echo "9. Cleaning up test files..."
rm -f test_checkpoint.in
echo "   Done. Output preserved in test_checkpoint.out"
echo
echo "=== Test complete ==="