# Quantum ESPRESSO Feature Implementation Game Plan

## Overview
This document outlines the implementation strategy for adding new features to Quantum ESPRESSO, including checkpointing, parameter optimization, pseudopotential management, sanity checks, and GUI enhancements.

## Feature 1: Signal-Based Checkpointing and Status Monitoring

### 1.1 Core Objectives
- **Soft pause signal (SIGUSR1)**: Complete current SCF cycle, write checkpoint, exit gracefully
- **Status snapshot signal (SIGUSR2)**: Write viewable output without stopping execution
- **Resume from checkpoint**: `--resume-from <checkpoint_file>` flag to continue calculations
- **Two distinct use cases**: Emergency save/restart vs. progress monitoring

### 1.2 Implementation Details

#### Files to Modify:
1. **PW/src/run_pwscf.f90**
   - Install signal handlers for SIGUSR1 and SIGUSR2
   - Add checkpoint resume logic at program startup
   - Parse `--resume-from` command line flag

2. **PW/src/electrons.f90**
   - Check signal flags at beginning of each SCF cycle
   - Handle soft pause: complete current cycle then checkpoint and exit
   - Handle snapshot: write current state without interrupting execution

3. **Modules/command_line_options.f90**
   - Add `--resume-from` flag parsing
   - Store checkpoint file path

4. **New Module: Modules/checkpoint_manager.f90**
   ```fortran
   MODULE checkpoint_manager
     USE kinds, ONLY : DP
     USE io_global, ONLY : stdout
     IMPLICIT NONE
     
     LOGICAL :: soft_pause_requested = .FALSE.
     LOGICAL :: snapshot_requested = .FALSE.
     CHARACTER(LEN=256) :: checkpoint_file = ''
     CHARACTER(LEN=256) :: snapshot_dir = './snapshots/'
     
     CONTAINS
       SUBROUTINE install_signal_handlers()
       SUBROUTINE handle_soft_pause_signal()  ! SIGUSR1 handler
       SUBROUTINE handle_snapshot_signal()    ! SIGUSR2 handler
       SUBROUTINE write_checkpoint(filename, iter, etot, conv)
       SUBROUTINE load_checkpoint(filename)
       SUBROUTINE write_status_snapshot(iter, etot, forces, stress)
   END MODULE checkpoint_manager
   ```

#### Key Changes:
- Modify `electrons()` in PW/src/electrons.f90:
  ```fortran
  DO iter = 1, niter
    ! Check for signals at cycle start
    IF (soft_pause_requested) THEN
      WRITE(stdout,'(/,5X,"Soft pause requested - completing current cycle...")')
      ! Complete this iteration
      CALL scf_cycle()  ! Normal SCF operations
      
      ! Write checkpoint after cycle completes
      CALL write_checkpoint('checkpoint_scf.dat', iter, etot, conv_elec)
      WRITE(stdout,'(/,5X,"Checkpoint written to checkpoint_scf.dat")')
      WRITE(stdout,'(5X,"Resume with: pw.x --resume-from checkpoint_scf.dat")')
      CALL stop_run(.FALSE.)
    END IF
    
    IF (snapshot_requested) THEN
      ! Write snapshot without interrupting
      WRITE(stdout,'(/,5X,"Writing status snapshot...")')
      CALL write_status_snapshot(iter, etot, forces, stress)
      snapshot_requested = .FALSE.  ! Reset flag
      WRITE(stdout,'(5X,"Snapshot written, calculation continuing...")')
    END IF
    
    ! Normal SCF iteration...
  END DO
  ```

- Signal handling setup in run_pwscf.f90:
  ```fortran
  SUBROUTINE run_pwscf()
    ! Check for resume flag
    IF (LEN_TRIM(checkpoint_file) > 0) THEN
      CALL load_checkpoint(checkpoint_file)
      WRITE(stdout,'(/,5X,"Resuming from checkpoint: ",A)') TRIM(checkpoint_file)
    END IF
    
    ! Install signal handlers
    CALL install_signal_handlers()
    
    ! Normal PWscf execution...
  END SUBROUTINE
  ```

#### Dependencies Affected:
- PW module (core changes)
- Modules (new checkpoint manager)
- Signal handling (system-specific implementation)

### 1.3 Usage Examples
```bash
# Start a calculation
pw.x -input silicon.in

# From another terminal, soft pause:
kill -USR1 <pid>  # Completes current cycle, saves checkpoint, exits

# Resume from checkpoint:
pw.x -input silicon.in --resume-from checkpoint_scf.dat

# Request status snapshot without stopping:
kill -USR2 <pid>  # Writes snapshot, continues running
```

## Feature 2: Automated Parameter Optimization

### 2.1 Core Objectives
- Auto-optimize k-point grids
- Suggest optimal energy cutoffs
- Provide convergence testing framework

### 2.2 Implementation Details

#### New Module Structure:
Create `PW/src/parameter_optimization.f90`:
```fortran
MODULE parameter_optimization
  USE kinds
  USE cell_base
  USE klist
  
  TYPE param_optimizer
    REAL(DP) :: target_accuracy = 1.0e-4_DP
    INTEGER :: max_iterations = 10
    LOGICAL :: optimize_kpoints = .TRUE.
    LOGICAL :: optimize_cutoff = .TRUE.
  END TYPE
  
  CONTAINS
    SUBROUTINE optimize_parameters()
    SUBROUTINE suggest_kpoint_grid()
    SUBROUTINE test_cutoff_convergence()
END MODULE
```

#### Files to Modify:

1. **PW/src/input.f90**
   - Add AUTO_OPTIMIZE namelist
   - Parse optimization parameters

2. **PW/src/setup.f90**
   - Call parameter optimizer before main calculation
   - Override user parameters if optimization enabled

3. **PW/src/kpoint_grid.f90**
   - Enhance automatic k-point generation
   - Add convergence testing loops

#### Algorithm Implementation:
```fortran
SUBROUTINE suggest_kpoint_grid(at, bg, target_spacing)
  ! Based on reciprocal lattice vectors
  ! Target spacing in Bohr^-1
  REAL(DP) :: b_norm(3)
  INTEGER :: nk_suggest(3)
  
  DO i = 1, 3
    b_norm(i) = SQRT(SUM(bg(:,i)**2))
    nk_suggest(i) = CEILING(b_norm(i) / target_spacing)
    ! Ensure odd for better symmetry
    IF (MOD(nk_suggest(i), 2) == 0) nk_suggest(i) = nk_suggest(i) + 1
  END DO
END SUBROUTINE
```

## Feature 3: Simplified Pseudopotential Management

### 3.1 Core Objectives
- Recommend pseudopotentials based on element and calculation type
- Integrate with existing PP database
- Provide quality metrics

### 3.2 Implementation Details

#### New Module: upflib/pp_recommender.f90
```fortran
MODULE pp_recommender
  USE pseudo_types
  
  TYPE pp_recommendation
    CHARACTER(LEN=256) :: filename
    CHARACTER(LEN=20) :: type ! 'NC', 'US', 'PAW'
    REAL(DP) :: quality_score
    CHARACTER(LEN=256) :: notes
  END TYPE
  
  CONTAINS
    FUNCTION recommend_pp(element, calc_type) RESULT(recommendation)
    SUBROUTINE load_pp_database()
    FUNCTION evaluate_pp_quality()
END MODULE
```

#### Database Structure:
Create `pseudo/pp_database.json`:
```json
{
  "H": {
    "recommended": {
      "standard": "H.pbe-rrkjus_psl.1.0.0.UPF",
      "high_accuracy": "H.pbe-kjpaw_psl.1.0.0.UPF",
      "efficiency": "H.pbe-n-rrkjus_psl.1.0.0.UPF"
    },
    "properties": {
      "cutoff_wfc": 40.0,
      "cutoff_rho": 320.0
    }
  }
}
```

#### Integration Points:
1. **PW/src/read_pseudo.f90**
   - Add recommendation system call
   - Warn if non-optimal PP chosen

2. **atomic/src/export_upf.f90**
   - Tag generated PPs with metadata
   - Update recommendation database

## Feature 4: User-Controllable Sanity Checks System

### 4.1 Core Objectives
- Detect common input errors and unusual configurations
- **Always allow users to proceed** despite warnings
- Provide easy configuration for default behavior
- Support veteran users who want to disable checks entirely
- Integrate seamlessly with GUI

### 4.2 Configuration System

#### Global Configuration File: `~/.qe/config.ini`
```ini
[sanity_checks]
enabled = true                # Can be set to false to disable by default
level = warning              # info, warning, or critical
prompt_on_warning = true     # Ask user before continuing with warnings
prompt_on_critical = true    # Ask user before continuing with critical issues
auto_continue = false        # If true, always continue despite warnings
```

#### Command Line Flags:
- `--ignore-sanity-checks`: Skip all sanity checks for this run
- `--sanity-checks-only`: Run only sanity checks and exit (for GUI pre-check)
- `--force`: Continue execution regardless of warnings/errors
- `--config`: Update default configuration

### 4.3 Implementation Details

#### New Module: Modules/sanity_config.f90
```fortran
MODULE sanity_config
  USE kinds
  IMPLICIT NONE
  
  TYPE sanity_settings
    LOGICAL :: enabled = .TRUE.
    LOGICAL :: prompt_on_warning = .TRUE.
    LOGICAL :: prompt_on_critical = .TRUE.
    LOGICAL :: ignore_all = .FALSE.
    LOGICAL :: checks_only = .FALSE.
    LOGICAL :: force_continue = .FALSE.
    INTEGER :: min_level = 1  ! 1=info, 2=warning, 3=critical
  END TYPE
  
  TYPE(sanity_settings) :: sanity_opts
  CHARACTER(LEN=256) :: config_file = "~/.qe/config.ini"
  
  CONTAINS
    SUBROUTINE load_sanity_config()
    SUBROUTINE save_sanity_config()
    SUBROUTINE parse_sanity_flags()
    SUBROUTINE set_config_value(key, value)
END MODULE sanity_config
```

#### Enhanced Module: Modules/sanity_checks.f90
```fortran
MODULE sanity_checks
  USE ions_base
  USE cell_base
  USE sanity_config
  
  TYPE sanity_warning
    INTEGER :: level ! 1=info, 2=warning, 3=critical
    CHARACTER(LEN=256) :: message
    CHARACTER(LEN=256) :: suggestion
  END TYPE
  
  TYPE(sanity_warning), ALLOCATABLE :: warnings(:)
  INTEGER :: n_warnings = 0
  INTEGER :: n_critical = 0
  
  CONTAINS
    SUBROUTINE run_all_checks(allow_continue)
      LOGICAL, INTENT(OUT) :: allow_continue
      
      allow_continue = .TRUE.
      
      ! Skip if disabled
      IF (sanity_opts%ignore_all .OR. .NOT. sanity_opts%enabled) RETURN
      
      ! Run all checks
      CALL check_atomic_distances()
      CALL check_cell_parameters()
      CALL check_isolated_atoms()
      CALL check_symmetry_breaking()
      
      ! Print report
      CALL print_sanity_report()
      
      ! Handle user interaction
      IF (.NOT. sanity_opts%force_continue) THEN
        CALL handle_user_choice(allow_continue)
      END IF
      
      ! Exit if checks only mode
      IF (sanity_opts%checks_only) THEN
        CALL stop_run(.FALSE.)
      END IF
    END SUBROUTINE
    
    SUBROUTINE handle_user_choice(allow_continue)
      LOGICAL, INTENT(OUT) :: allow_continue
      CHARACTER(LEN=1) :: response
      
      IF (n_critical > 0 .AND. sanity_opts%prompt_on_critical) THEN
        WRITE(stdout,'(/,5X,"CRITICAL issues found!")')
        WRITE(stdout,'(5X,"Continue anyway? (y/N): ",$)')
        READ(stdin,'(A1)') response
        allow_continue = (response == 'y' .OR. response == 'Y')
      ELSE IF (n_warnings > 0 .AND. sanity_opts%prompt_on_warning) THEN
        WRITE(stdout,'(/,5X,"Warnings detected.")')
        WRITE(stdout,'(5X,"Continue? (Y/n): ",$)')
        READ(stdin,'(A1)') response
        allow_continue = (response /= 'n' .AND. response /= 'N')
      END IF
    END SUBROUTINE
END MODULE
```

#### Integration in PW/src/setup.f90:
```fortran
SUBROUTINE setup()
  LOGICAL :: can_continue
  
  ! Load configuration
  CALL load_sanity_config()
  
  ! Parse command line flags
  CALL parse_sanity_flags()
  
  ! Normal setup code...
  
  ! Run sanity checks
  CALL run_all_checks(can_continue)
  
  IF (.NOT. can_continue) THEN
    WRITE(stdout,'(/,5X,"Execution halted by user choice.")')
    WRITE(stdout,'(5X,"Use --force to override.")')
    CALL stop_run(.TRUE.)
  END IF
END SUBROUTINE
```

### 4.4 Configuration Management

#### Easy Default Changes:
```bash
# Disable sanity checks by default
pw.x --config sanity_checks.enabled=false

# Change prompting behavior
pw.x --config sanity_checks.prompt_on_warning=false

# Set to always continue
pw.x --config sanity_checks.auto_continue=true
```

#### Per-Project Settings:
- Local `.qe_config` file in project directory overrides global settings
- Automatically created when user makes project-specific choices

## Feature 5: Enhanced GUI

### 5.1 Core Objectives
- Modern GUI for input file editing
- Real-time visualization
- Integration with monitoring system
- Pause/resume controls
- **Integrated sanity check system**

### 5.2 Architecture

#### Technology Stack:
- Frontend: Qt6 or Electron for cross-platform
- Backend: Python Flask/FastAPI server
- Communication: WebSockets for real-time updates

#### New Components:

1. **GUI/src/qe_gui_server.py**:
```python
from flask import Flask, jsonify
from flask_socketio import SocketIO
import json
import subprocess
import signal

class QEServer:
    def __init__(self):
        self.app = Flask(__name__)
        self.socketio = SocketIO(self.app)
        self.current_job = None
        self.sanity_warnings = []
        
    def run_sanity_checks(self, input_file):
        """Run sanity checks only, without starting calculation"""
        cmd = ['pw.x', '--sanity-checks-only', '-input', input_file]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        # Parse warnings from output
        self.sanity_warnings = self.parse_sanity_output(result.stdout)
        return {
            'warnings': self.sanity_warnings,
            'has_critical': any(w['level'] == 'critical' for w in self.sanity_warnings),
            'has_warnings': any(w['level'] == 'warning' for w in self.sanity_warnings)
        }
        
    def start_calculation(self, input_file, ignore_sanity=False):
        """Start calculation with optional sanity check bypass"""
        cmd = ['pw.x', '-input', input_file]
        if ignore_sanity:
            cmd.insert(1, '--ignore-sanity-checks')
        
        self.current_job = subprocess.Popen(cmd)
        
    def pause_calculation(self):
        """Send soft pause signal (SIGUSR1)"""
        if self.current_job:
            self.current_job.send_signal(signal.SIGUSR1)
            
    def request_snapshot(self):
        """Send snapshot signal (SIGUSR2)"""
        if self.current_job:
            self.current_job.send_signal(signal.SIGUSR2)
```

2. **GUI/src/input_editor.py**:
   - Syntax highlighting for QE input
   - Parameter validation
   - Template system

3. **GUI/src/visualizer.py**:
   - Real-time energy convergence plots
   - Structure viewer using ASE/VMD integration
   - Band structure/DOS plotting

4. **GUI/src/sanity_check_dialog.py**:
```python
class SanityCheckDialog(QDialog):
    def __init__(self, warnings, parent=None):
        super().__init__(parent)
        self.warnings = warnings
        self.setup_ui()
        
    def setup_ui(self):
        layout = QVBoxLayout()
        
        # Warning list widget
        self.warning_list = QListWidget()
        for warning in self.warnings:
            item = QListWidgetItem()
            icon = self.get_icon_for_level(warning['level'])
            item.setIcon(icon)
            item.setText(f"{warning['message']} - {warning['suggestion']}")
            self.warning_list.addItem(item)
            
        # Buttons
        button_layout = QHBoxLayout()
        self.fix_button = QPushButton("Fix Issues")
        self.ignore_button = QPushButton("Run Anyway")
        self.cancel_button = QPushButton("Cancel")
        
        button_layout.addWidget(self.fix_button)
        button_layout.addWidget(self.ignore_button)
        button_layout.addWidget(self.cancel_button)
        
        layout.addWidget(QLabel("Sanity Check Results:"))
        layout.addWidget(self.warning_list)
        layout.addLayout(button_layout)
```

#### Modified QE Files:

1. **PW/src/pwscf.f90**:
   - Add `-monitor` command line flag
   - Initialize socket server when flag present

2. **Modules/command_line_options.f90**:
   - Parse GUI-related flags
   - Set up communication channels

### 5.3 Enhanced GUI Layout with Sanity Checks
```
┌─────────────────────────────────────────────┐
│  File  Edit  View  Calculate  Tools  Help   │
├─────────────┬───────────────────────────────┤
│             │ Input Editor                  │
│  Project    │ ─────────────────────         │
│  Browser    │ &CONTROL                      │
│             │   calculation = 'scf'         │
│  Structure  │   ...                         │
│  Viewer     │                               │
│             ├───────────────────────────────┤
│  Output     │ Control Panel                 │
│  Monitor    │ [Check Input] [Run] [Pause]   │
│             │ [✓] Enable Sanity Checks      │
│             ├───────────────────────────────┤
│  Status     │ Convergence Monitor           │
│  Panel      │ [=====>    ] 45%              │
│             │ Energy: -145.234 Ry           │
└─────────────┴───────────────────────────────┘
```

### 5.4 Sanity Check GUI Workflow

1. **Check Input Button**:
   - Runs `pw.x --sanity-checks-only`
   - Displays results in modal dialog
   - User can choose to fix issues or proceed

2. **Run Button Behavior**:
   - If sanity checks enabled (checkbox):
     - Performs checks first
     - Shows dialog if issues found
     - User chooses action
   - If sanity checks disabled:
     - Runs with `--ignore-sanity-checks` flag

3. **Settings Menu Integration**:
   - Configure default sanity check behavior
   - Set warning levels
   - Manage per-project overrides

4. **Status Indicators**:
   - Green checkmark: No issues found
   - Yellow warning: Minor issues detected
   - Red X: Critical issues found

## Implementation Timeline

### Phase 1: Core Infrastructure
1. Monitoring module development
2. Signal handling implementation
3. Basic checkpoint system
4. Testing framework

### Phase 2: Parameter Optimization
1. K-point optimization algorithm
2. Cutoff convergence testing
3. Integration with existing input system
4. Validation on test systems

### Phase 3: Pseudopotential Management
1. Database creation
2. Recommendation algorithm
3. Integration with read_pseudo

### Phase 4: Sanity Checks
1. Check implementations
2. Warning system
3. User documentation

### Phase 5: GUI Development
1. Server implementation
2. Editor development
3. Visualization tools
4. Integration testing

## Testing Strategy

### Unit Tests
- Create test_monitoring.f90 in test-suite/
- Parameter optimization validation suite
- Sanity check test cases

### Integration Tests
- Full calculation with monitoring
- GUI interaction tests
- Cross-platform validation

### Performance Impact
- Monitor overhead < 1% of calculation time
- Checkpoint I/O optimization
- Optional features to maintain baseline performance

## Documentation Updates

### User Guide Additions
1. New chapter on monitoring and checkpointing
2. Parameter optimization guide
3. GUI tutorial
4. Sanity check reference

### Developer Documentation
1. Monitoring API reference
2. GUI plugin development guide
3. Sanity check extension guide

## Backward Compatibility

### Ensuring Compatibility
- All new features optional via input flags
- Default behavior unchanged
- Old input files work without modification
- Checkpoint format versioning

### Migration Guide
- How to enable new features
- Converting existing workflows
- Performance considerations

## Risk Mitigation

### Technical Risks
1. **Threading issues**: Use proven MPI patterns
2. **I/O overhead**: Implement buffering and async writes
3. **GUI portability**: Extensive platform testing

### Mitigation Strategies
- Gradual rollout with feature flags
- Extensive beta testing program
- Fallback mechanisms for all new features

---

This implementation plan provides a roadmap for adding modern usability features to Quantum ESPRESSO while maintaining its scientific integrity and performance characteristics.