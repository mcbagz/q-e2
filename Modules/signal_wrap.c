#include <stdlib.h>
#include <stdio.h>
#include <signal.h>

// Global flags that will be accessed from Fortran
volatile sig_atomic_t soft_pause_flag = 0;
volatile sig_atomic_t snapshot_flag = 0;

// Signal handler for SIGUSR1 (soft pause)
void handle_soft_pause(int signum) {
    soft_pause_flag = 1;
}

// Signal handler for SIGUSR2 (snapshot)
void handle_snapshot(int signum) {
    snapshot_flag = 1;
}

// Function to install signal handlers
int install_checkpoint_signals() {
    struct sigaction sa_pause, sa_snapshot;
    
    // Set up handler for SIGUSR1 (soft pause)
    sa_pause.sa_handler = handle_soft_pause;
    sigemptyset(&sa_pause.sa_mask);
    sa_pause.sa_flags = SA_RESTART;
    
    if (sigaction(SIGUSR1, &sa_pause, NULL) != 0) {
        return -1;
    }
    
    // Set up handler for SIGUSR2 (snapshot)
    sa_snapshot.sa_handler = handle_snapshot;
    sigemptyset(&sa_snapshot.sa_mask);
    sa_snapshot.sa_flags = SA_RESTART;
    
    if (sigaction(SIGUSR2, &sa_snapshot, NULL) != 0) {
        return -2;
    }
    
    return 0;
}

// Functions to check and reset flags from Fortran
int check_soft_pause_flag() {
    return soft_pause_flag;
}

int check_snapshot_flag() {
    return snapshot_flag;
}

void reset_soft_pause_flag() {
    soft_pause_flag = 0;
}

void reset_snapshot_flag() {
    snapshot_flag = 0;
}

// Function to handle keyboard shortcuts (platform-specific)
// This is a placeholder - actual implementation would require terminal control
int setup_keyboard_handlers() {
    // TODO: Implement terminal raw mode and keyboard handling
    // For now, signals are the primary interface
    return 0;
}