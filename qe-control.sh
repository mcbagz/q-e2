#!/bin/bash

# Quantum ESPRESSO Process Control Script
# Controls running QE processes with checkpoint signals

PROG_NAME=$(basename $0)

usage() {
    cat << EOF
Usage: $PROG_NAME [COMMAND] [OPTIONS]

Quantum ESPRESSO Process Control - Send checkpoint signals to running calculations

COMMANDS:
    pause PID       Send soft pause signal (SIGUSR1) to create checkpoint
    snapshot PID    Send snapshot signal (SIGUSR2) to save current state
    status          List all running pw.x processes
    help            Show this help message

EXAMPLES:
    $PROG_NAME status              # Show all running pw.x processes
    $PROG_NAME pause 12345         # Checkpoint and pause process 12345
    $PROG_NAME snapshot 12345      # Take snapshot of process 12345

KEYBOARD SHORTCUTS (when running in foreground):
    Ctrl+Shift+C    Equivalent to 'pause' command
    Ctrl+Shift+S    Equivalent to 'snapshot' command

NOTES:
    - Soft pause (SIGUSR1) completes current SCF cycle, writes checkpoint, then exits
    - Snapshot (SIGUSR2) writes current state without interrupting calculation
    - Resume with: pw.x --resume-from checkpoint_scf.dat

EOF
}

# Function to list running pw.x processes
show_status() {
    echo "=== Running Quantum ESPRESSO Processes ==="
    echo
    
    # Check for pw.x processes
    PW_PROCS=$(pgrep -l "pw\.x" 2>/dev/null)
    
    if [ -z "$PW_PROCS" ]; then
        echo "No pw.x processes found."
    else
        echo "PID    Command"
        echo "---    -------"
        echo "$PW_PROCS"
    fi
    
    echo
    
    # Check for recent checkpoint files
    echo "=== Recent Checkpoint Files ==="
    if ls checkpoint*.dat 2>/dev/null | head -5; then
        :
    else
        echo "No checkpoint files found."
    fi
    
    echo
    
    # Check for recent snapshots
    echo "=== Recent Snapshot Files ==="
    if [ -d snapshots ]; then
        ls -lt snapshots/*snapshot.txt 2>/dev/null | head -5
    else
        echo "No snapshot directory found."
    fi
}

# Function to send pause signal
send_pause() {
    local PID=$1
    
    if ! kill -0 $PID 2>/dev/null; then
        echo "Error: Process $PID not found or not accessible."
        exit 1
    fi
    
    echo "Sending soft pause signal to process $PID..."
    kill -USR1 $PID
    
    if [ $? -eq 0 ]; then
        echo "Soft pause signal sent successfully."
        echo "The process will complete its current SCF cycle and write a checkpoint."
        echo "Resume with: pw.x --resume-from checkpoint_scf.dat"
    else
        echo "Error: Failed to send signal to process $PID"
        exit 1
    fi
}

# Function to send snapshot signal
send_snapshot() {
    local PID=$1
    
    if ! kill -0 $PID 2>/dev/null; then
        echo "Error: Process $PID not found or not accessible."
        exit 1
    fi
    
    echo "Sending snapshot signal to process $PID..."
    kill -USR2 $PID
    
    if [ $? -eq 0 ]; then
        echo "Snapshot signal sent successfully."
        echo "A status snapshot will be written to the snapshots/ directory."
        echo "The calculation will continue running."
    else
        echo "Error: Failed to send signal to process $PID"
        exit 1
    fi
}

# Main script logic
case "$1" in
    pause)
        if [ -z "$2" ]; then
            echo "Error: Please specify a process ID"
            echo "Usage: $PROG_NAME pause PID"
            exit 1
        fi
        send_pause $2
        ;;
        
    snapshot)
        if [ -z "$2" ]; then
            echo "Error: Please specify a process ID"
            echo "Usage: $PROG_NAME snapshot PID"
            exit 1
        fi
        send_snapshot $2
        ;;
        
    status)
        show_status
        ;;
        
    help|--help|-h)
        usage
        ;;
        
    "")
        echo "Error: No command specified"
        usage
        exit 1
        ;;
        
    *)
        echo "Error: Unknown command '$1'"
        usage
        exit 1
        ;;
esac