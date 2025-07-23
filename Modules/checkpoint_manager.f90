!
! Copyright (C) 2024 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!----------------------------------------------------------------------------
MODULE checkpoint_manager
  !----------------------------------------------------------------------------
  !! This module handles checkpointing and status monitoring through signals.
  !! It provides functionality for:
  !! - SIGUSR1: Soft pause with checkpoint creation
  !! - SIGUSR2: Status snapshot without interrupting execution
  !! - Resume from checkpoint functionality
  !
  USE kinds,      ONLY : DP
  USE io_global,  ONLY : stdout, ionode, ionode_id
  USE io_files,   ONLY : tmp_dir, prefix
  USE mp,         ONLY : mp_bcast
  USE mp_world,   ONLY : world_comm
  USE iso_c_binding
  !
  IMPLICIT NONE
  !
  SAVE
  PRIVATE
  !
  ! Public routines
  PUBLIC :: install_checkpoint_handlers, write_checkpoint_info, request_checkpoint
  PUBLIC :: write_status_snapshot, check_checkpoint_signals
  PUBLIC :: checkpoint_file_name, snapshot_dir_name
  PUBLIC :: soft_pause_requested, snapshot_requested
  PUBLIC :: checkpoint_requested_file
  PUBLIC :: reset_snapshot_flag
  !
  ! Module variables
  LOGICAL :: soft_pause_requested = .FALSE.
  LOGICAL :: snapshot_requested = .FALSE.
  CHARACTER(LEN=256) :: checkpoint_file_name = ' '
  CHARACTER(LEN=256) :: snapshot_dir_name = './snapshots/'
  CHARACTER(LEN=256) :: checkpoint_requested_file = 'checkpoint_requested.dat'
  !
  ! C interface for signal handling
  INTERFACE
    FUNCTION install_checkpoint_signals() BIND(C, name="install_checkpoint_signals")
      USE iso_c_binding
      INTEGER(C_INT) :: install_checkpoint_signals
    END FUNCTION install_checkpoint_signals
    
    FUNCTION check_soft_pause_flag() BIND(C, name="check_soft_pause_flag")
      USE iso_c_binding
      INTEGER(C_INT) :: check_soft_pause_flag
    END FUNCTION check_soft_pause_flag
    
    FUNCTION check_snapshot_flag() BIND(C, name="check_snapshot_flag")
      USE iso_c_binding
      INTEGER(C_INT) :: check_snapshot_flag
    END FUNCTION check_snapshot_flag
    
    SUBROUTINE reset_soft_pause_flag() BIND(C, name="reset_soft_pause_flag")
      USE iso_c_binding
    END SUBROUTINE reset_soft_pause_flag
    
    SUBROUTINE reset_snapshot_flag() BIND(C, name="reset_snapshot_flag")
      USE iso_c_binding
    END SUBROUTINE reset_snapshot_flag
  END INTERFACE
  !
CONTAINS
  !
  !-----------------------------------------------------------------------
  SUBROUTINE install_checkpoint_handlers()
    !-----------------------------------------------------------------------
    !! Install signal handlers for checkpointing functionality
    !
    USE io_global, ONLY : meta_ionode
    !
    IMPLICIT NONE
    !
    INTEGER :: ierr
    !
    IF ( meta_ionode ) THEN
      ierr = install_checkpoint_signals()
      IF ( ierr /= 0 ) THEN
        WRITE(stdout, '(/,5X,"WARNING: Failed to install checkpoint signal handlers, code:",I3)') ierr
      ELSE
        WRITE(stdout, '(/,5X,"Checkpoint signal handlers installed successfully")')
        WRITE(stdout, '(5X,"  - Send SIGUSR1 (kill -USR1 <pid>) for soft pause with checkpoint")')
        WRITE(stdout, '(5X,"  - Send SIGUSR2 (kill -USR2 <pid>) for status snapshot")')
      END IF
    END IF
    !
    CALL mp_bcast(ierr, ionode_id, world_comm)
    !
  END SUBROUTINE install_checkpoint_handlers
  !
  !-----------------------------------------------------------------------
  SUBROUTINE check_checkpoint_signals()
    !-----------------------------------------------------------------------
    !! Check if any checkpoint signals have been received
    !
    IMPLICIT NONE
    !
    INTEGER :: pause_flag, snapshot_flag
    !
    IF ( ionode ) THEN
      pause_flag = check_soft_pause_flag()
      snapshot_flag = check_snapshot_flag()
      
      IF ( pause_flag /= 0 ) THEN
        soft_pause_requested = .TRUE.
        WRITE(stdout, '(/,5X,"*** SOFT PAUSE SIGNAL RECEIVED ***")')
        WRITE(stdout, '(5X,"Will complete current SCF cycle and write checkpoint...")')
      END IF
      
      IF ( snapshot_flag /= 0 ) THEN
        snapshot_requested = .TRUE.
        ! Reset immediately as we don't want to stop
        CALL reset_snapshot_flag()
        WRITE(stdout, '(/,5X,"*** SNAPSHOT SIGNAL RECEIVED ***")')
      END IF
    END IF
    !
    CALL mp_bcast(soft_pause_requested, ionode_id, world_comm)
    CALL mp_bcast(snapshot_requested, ionode_id, world_comm)
    !
  END SUBROUTINE check_checkpoint_signals
  !
  !-----------------------------------------------------------------------
  SUBROUTINE write_checkpoint_info(filename, scf_iter, etot, conv_elec)
    !-----------------------------------------------------------------------
    !! Write basic checkpoint information file
    !! The actual checkpoint data should be written by the calling program
    !
    IMPLICIT NONE
    !
    CHARACTER(LEN=*), INTENT(IN) :: filename
    INTEGER, INTENT(IN) :: scf_iter
    REAL(DP), INTENT(IN) :: etot
    LOGICAL, INTENT(IN) :: conv_elec
    !
    INTEGER :: iunit, ios
    CHARACTER(LEN=256) :: info_file
    INTEGER :: timestamp(8)
    !
    IF ( .NOT. ionode ) RETURN
    !
    ! Generate info filename
    info_file = TRIM(filename) // '.info'
    !
    ! Write checkpoint info
    iunit = 99
    OPEN(UNIT=iunit, FILE=TRIM(info_file), STATUS='replace', IOSTAT=ios)
    !
    IF ( ios == 0 ) THEN
      CALL date_and_time(VALUES=timestamp)
      WRITE(iunit, '(A)') "QUANTUM ESPRESSO CHECKPOINT INFO"
      WRITE(iunit, '(A)') "================================"
      WRITE(iunit, '(A,I4,"/",I2.2,"/",I2.2," ",I2.2,":",I2.2,":",I2.2)') &
        "Timestamp: ", timestamp(1), timestamp(2), timestamp(3), &
        timestamp(4), timestamp(5), timestamp(6)
      WRITE(iunit, '(A,I5)') "SCF Iteration: ", scf_iter
      WRITE(iunit, '(A,F15.8,A)') "Total Energy: ", etot, " Ry"
      WRITE(iunit, '(A,L1)') "Converged: ", conv_elec
      WRITE(iunit, '(A,A)') "Checkpoint file: ", TRIM(filename)
      CLOSE(iunit)
      !
      checkpoint_file_name = filename
      WRITE(stdout, '(/,5X,"Checkpoint info written to: ",A)') TRIM(info_file)
      WRITE(stdout, '(5X,"Resume with: pw.x --resume-from ",A)') TRIM(filename)
    ELSE
      WRITE(stdout, '(/,5X,"WARNING: Could not write checkpoint info file")')
    END IF
    !
  END SUBROUTINE write_checkpoint_info
  !
  !-----------------------------------------------------------------------
  SUBROUTINE request_checkpoint(filename)
    !-----------------------------------------------------------------------
    !! Write a file requesting checkpoint at next opportunity
    !! Used for communication between checkpoint manager and PW module
    !
    IMPLICIT NONE
    !
    CHARACTER(LEN=*), INTENT(IN) :: filename
    !
    INTEGER :: iunit, ios
    !
    IF ( .NOT. ionode ) RETURN
    !
    iunit = 98
    OPEN(UNIT=iunit, FILE=TRIM(checkpoint_requested_file), STATUS='replace', IOSTAT=ios)
    IF ( ios == 0 ) THEN
      WRITE(iunit, '(A)') TRIM(filename)
      CLOSE(iunit)
    END IF
    !
  END SUBROUTINE request_checkpoint
  !
  !-----------------------------------------------------------------------
  SUBROUTINE write_status_snapshot(scf_iter, etot)
    !-----------------------------------------------------------------------
    !! Write a status snapshot without interrupting the calculation
    !
    USE io_global, ONLY : ionode
    !
    IMPLICIT NONE
    !
    INTEGER, INTENT(IN) :: scf_iter
    REAL(DP), INTENT(IN) :: etot
    !
    CHARACTER(LEN=256) :: snapshot_file
    INTEGER :: timestamp(8)
    INTEGER :: iunit, ios
    !
    IF ( .NOT. ionode ) RETURN
    !
    ! Create snapshot directory if needed
    CALL system('mkdir -p ' // TRIM(snapshot_dir_name))
    !
    ! Generate snapshot filename
    CALL date_and_time(VALUES=timestamp)
    WRITE(snapshot_file, '(A,A,A,I4.4,I2.2,I2.2,A,I2.2,I2.2,I2.2,A)') &
      TRIM(snapshot_dir_name), '/', TRIM(prefix), &
      timestamp(1), timestamp(2), timestamp(3), '_', &
      timestamp(4), timestamp(5), timestamp(6), '_snapshot.txt'
    !
    ! Write snapshot
    iunit = 98
    OPEN(UNIT=iunit, FILE=TRIM(snapshot_file), STATUS='replace', IOSTAT=ios)
    !
    IF ( ios == 0 ) THEN
      WRITE(iunit, '(A)') "QUANTUM ESPRESSO STATUS SNAPSHOT"
      WRITE(iunit, '(A)') "================================"
      WRITE(iunit, '(A,I4,"/",I2.2,"/",I2.2," ",I2.2,":",I2.2,":",I2.2)') &
        "Timestamp: ", timestamp(1), timestamp(2), timestamp(3), &
        timestamp(4), timestamp(5), timestamp(6)
      WRITE(iunit, '(A,I5)') "SCF Iteration: ", scf_iter
      WRITE(iunit, '(A,F15.8,A)') "Total Energy: ", etot, " Ry"
      !
      CLOSE(iunit)
      !
      WRITE(stdout, '(5X,"Status snapshot written to: ",A)') TRIM(snapshot_file)
    ELSE
      WRITE(stdout, '(5X,"WARNING: Could not write snapshot file")')
    END IF
    !
  END SUBROUTINE write_status_snapshot
  !
END MODULE checkpoint_manager