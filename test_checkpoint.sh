#!/bin/bash

# Test script for checkpoint functionality

echo "=== Quantum ESPRESSO Checkpoint Feature Test ==="
echo

# Create a simple test input file
cat > test_checkpoint.in << EOF
&CONTROL
    calculation = 'scf'
    restart_mode = 'from_scratch'
    pseudo_dir = './pseudo/'
    outdir = './tmp/'
    prefix = 'test'
    max_seconds = 3600
/
&SYSTEM
    ibrav = 2
    celldm(1) = 10.20
    nat = 2
    ntyp = 1
    ecutwfc = 18.0
/
&ELECTRONS
    conv_thr = 1.0d-8
    mixing_beta = 0.7
/
ATOMIC_SPECIES
 Si  28.086  Si.pbe-n-rrkjus_psl.1.0.0.UPF
ATOMIC_POSITIONS (alat)
 Si 0.00 0.00 0.00
 Si 0.25 0.25 0.25
K_POINTS (automatic)
 4 4 4 1 1 1
EOF

echo "Test 1: Basic SCF calculation with signal handling"
echo "================================================="
echo "Starting pw.x in background..."

# Start pw.x in background
pw.x -input test_checkpoint.in > test_checkpoint.out 2>&1 &
PW_PID=$!

echo "PW PID: $PW_PID"
sleep 5

echo
echo "Test 2: Testing SIGUSR2 (snapshot)"
echo "==================================="
echo "Sending SIGUSR2 signal to request snapshot..."
kill -USR2 $PW_PID
sleep 2

echo "Checking for snapshot files..."
ls -la snapshots/test*snapshot.txt 2>/dev/null

echo
echo "Test 3: Testing SIGUSR1 (soft pause)"
echo "====================================="
echo "Sending SIGUSR1 signal to request checkpoint..."
kill -USR1 $PW_PID

# Wait for pw.x to exit
wait $PW_PID
EXIT_CODE=$?

echo "pw.x exited with code: $EXIT_CODE"
echo
echo "Checking for checkpoint file..."
ls -la checkpoint_scf.dat 2>/dev/null

echo
echo "Test 4: Resume from checkpoint"
echo "==============================="
if [ -f checkpoint_scf.dat ]; then
    echo "Resuming from checkpoint..."
    pw.x -input test_checkpoint.in --resume-from checkpoint_scf.dat > test_resume.out 2>&1
    echo "Resume completed."
else
    echo "No checkpoint file found!"
fi

echo
echo "Test Summary"
echo "============"
echo "Check the following files for results:"
echo "- test_checkpoint.out : Initial run output"
echo "- test_resume.out    : Resume run output"
echo "- snapshots/*        : Snapshot files"
echo "- checkpoint_scf.dat : Checkpoint file"

# Cleanup
echo
echo "Cleanup (comment out to keep files):"
# rm -f test_checkpoint.in test_checkpoint.out test_resume.out checkpoint_scf.dat
# rm -rf snapshots/

echo "Test script completed!"