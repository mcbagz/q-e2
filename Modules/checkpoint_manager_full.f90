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
  PUBLIC :: install_checkpoint_handlers, write_checkpoint, load_checkpoint
  PUBLIC :: write_status_snapshot, check_checkpoint_signals
  PUBLIC :: checkpoint_file_name, snapshot_dir_name
  PUBLIC :: soft_pause_requested, snapshot_requested
  !
  ! Module variables
  LOGICAL :: soft_pause_requested = .FALSE.
  LOGICAL :: snapshot_requested = .FALSE.
  CHARACTER(LEN=256) :: checkpoint_file_name = ' '
  CHARACTER(LEN=256) :: snapshot_dir_name = './snapshots/'
  INTEGER :: checkpoint_version = 1
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
  SUBROUTINE write_checkpoint(filename, scf_iter, etot, conv_elec, forces, stress, restart_info)
    !-----------------------------------------------------------------------
    !! Write checkpoint file with current calculation state
    !
    USE ions_base,    ONLY : nat, nsp, ityp, tau, if_pos, atm, amass
    USE cell_base,    ONLY : alat, at, bg, omega, ibrav, celldm
    USE klist,        ONLY : nks, nkstot, xk, wk, lgauss, degauss, ngauss
    USE wvfct,        ONLY : nbnd, et, wg, npwx
    USE force_mod,    ONLY : force
    USE control_flags, ONLY : conv_ions, istep, nstep, ethr
    USE io_files,     ONLY : iunwfc, nwordwfc
    USE buffers,      ONLY : save_buffer, get_buffer
    !
    IMPLICIT NONE
    !
    CHARACTER(LEN=*), INTENT(IN) :: filename
    INTEGER, INTENT(IN) :: scf_iter
    REAL(DP), INTENT(IN) :: etot
    LOGICAL, INTENT(IN) :: conv_elec
    REAL(DP), INTENT(IN), OPTIONAL :: forces(3,nat)
    REAL(DP), INTENT(IN), OPTIONAL :: stress(3,3)
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: restart_info
    !
    INTEGER :: iunit, ios, ik, ibnd, i, j
    CHARACTER(LEN=256) :: full_filename
    INTEGER :: timestamp(8)
    !
    IF ( .NOT. ionode ) RETURN
    !
    ! Generate filename with timestamp
    CALL date_and_time(VALUES=timestamp)
    IF ( TRIM(filename) == ' ' ) THEN
      WRITE(full_filename, '(A,A,I4.4,I2.2,I2.2,A,I2.2,I2.2,A)') &
        TRIM(tmp_dir), 'checkpoint_', timestamp(1), timestamp(2), &
        timestamp(3), '_', timestamp(4), timestamp(5), '.dat'
    ELSE
      full_filename = filename
    END IF
    !
    checkpoint_file_name = full_filename
    !
    ! Open checkpoint file
    iunit = 99
    OPEN(UNIT=iunit, FILE=TRIM(full_filename), FORM='unformatted', &
         STATUS='replace', IOSTAT=ios)
    !
    IF ( ios /= 0 ) THEN
      WRITE(stdout, '(/,5X,"ERROR: Cannot open checkpoint file: ",A)') TRIM(full_filename)
      RETURN
    END IF
    !
    ! Write checkpoint header
    WRITE(iunit) checkpoint_version
    WRITE(iunit) timestamp
    !
    ! Write calculation parameters
    WRITE(iunit) scf_iter, etot, conv_elec
    WRITE(iunit) istep, nstep, ethr
    !
    ! Write system information
    WRITE(iunit) nat, nsp, ibrav
    WRITE(iunit) celldm
    WRITE(iunit) alat, omega
    WRITE(iunit) at
    WRITE(iunit) bg
    !
    ! Write atomic information
    WRITE(iunit) (ityp(i), i=1,nat)
    WRITE(iunit) ((tau(j,i), j=1,3), i=1,nat)
    WRITE(iunit) ((if_pos(j,i), j=1,3), i=1,nat)
    WRITE(iunit) (atm(i), i=1,nsp)
    WRITE(iunit) (amass(i), i=1,nsp)
    !
    ! Write k-point information
    WRITE(iunit) nks, nkstot
    WRITE(iunit) ((xk(j,ik), j=1,3), ik=1,nks)
    WRITE(iunit) (wk(ik), ik=1,nks)
    WRITE(iunit) lgauss, degauss, ngauss
    !
    ! Write band structure information
    WRITE(iunit) nbnd, npwx
    WRITE(iunit) ((et(ibnd,ik), ibnd=1,nbnd), ik=1,nks)
    WRITE(iunit) ((wg(ibnd,ik), ibnd=1,nbnd), ik=1,nks)
    !
    ! Write optional data
    IF ( PRESENT(forces) ) THEN
      WRITE(iunit) .TRUE.
      WRITE(iunit) forces
    ELSE
      WRITE(iunit) .FALSE.
    END IF
    !
    IF ( PRESENT(stress) ) THEN
      WRITE(iunit) .TRUE.
      WRITE(iunit) stress
    ELSE
      WRITE(iunit) .FALSE.
    END IF
    !
    IF ( PRESENT(restart_info) ) THEN
      WRITE(iunit) .TRUE.
      WRITE(iunit) restart_info
    ELSE
      WRITE(iunit) .FALSE.
    END IF
    !
    CLOSE(iunit)
    !
    WRITE(stdout, '(/,5X,"Checkpoint written to: ",A)') TRIM(full_filename)
    WRITE(stdout, '(5X,"Resume with: pw.x --resume-from ",A)') TRIM(full_filename)
    !
  END SUBROUTINE write_checkpoint
  !
  !-----------------------------------------------------------------------
  SUBROUTINE load_checkpoint(filename)
    !-----------------------------------------------------------------------
    !! Load checkpoint file and restore calculation state
    !
    USE ions_base,    ONLY : nat, nsp, ityp, tau, if_pos, atm, amass
    USE cell_base,    ONLY : alat, at, bg, omega, ibrav, celldm
    USE klist,        ONLY : nks, nkstot, xk, wk, lgauss, degauss, ngauss
    USE wvfct,        ONLY : nbnd, et, wg, npwx
    USE control_flags, ONLY : istep, nstep, ethr
    !
    IMPLICIT NONE
    !
    CHARACTER(LEN=*), INTENT(IN) :: filename
    !
    INTEGER :: iunit, ios, version_read, i, j, ik, ibnd
    INTEGER :: nat_tmp, nsp_tmp, nks_tmp, nbnd_tmp
    INTEGER :: timestamp(8)
    LOGICAL :: has_forces, has_stress, has_restart_info
    REAL(DP) :: etot_tmp
    LOGICAL :: conv_elec_tmp
    INTEGER :: scf_iter_tmp
    CHARACTER(LEN=256) :: restart_info_tmp
    !
    IF ( ionode ) THEN
      !
      iunit = 99
      OPEN(UNIT=iunit, FILE=TRIM(filename), FORM='unformatted', &
           STATUS='old', IOSTAT=ios)
      !
      IF ( ios /= 0 ) THEN
        WRITE(stdout, '(/,5X,"ERROR: Cannot open checkpoint file: ",A)') TRIM(filename)
        STOP 1
      END IF
      !
      ! Read and verify checkpoint version
      READ(iunit) version_read
      IF ( version_read /= checkpoint_version ) THEN
        CLOSE(iunit)
        WRITE(stdout, '(/,5X,"ERROR: Incompatible checkpoint version")')
        STOP 1
      END IF
      !
      READ(iunit) timestamp
      WRITE(stdout, '(/,5X,"Loading checkpoint from: ",A)') TRIM(filename)
      WRITE(stdout, '(5X,"Checkpoint timestamp: ",I4,"/",I2.2,"/",I2.2," ",I2.2,":",I2.2)') &
        timestamp(1), timestamp(2), timestamp(3), timestamp(4), timestamp(5)
      !
      ! Read calculation parameters
      READ(iunit) scf_iter_tmp, etot_tmp, conv_elec_tmp
      READ(iunit) istep, nstep, ethr
      !
      ! Read and verify system dimensions
      READ(iunit) nat_tmp, nsp_tmp, ibrav
      IF ( nat_tmp /= nat .OR. nsp_tmp /= nsp ) THEN
        CLOSE(iunit)
        WRITE(stdout, '(/,5X,"ERROR: System size mismatch in checkpoint")')
        STOP 1
      END IF
      !
      ! Read cell parameters
      READ(iunit) celldm
      READ(iunit) alat, omega
      READ(iunit) at
      READ(iunit) bg
      !
      ! Read atomic information
      READ(iunit) (ityp(i), i=1,nat)
      READ(iunit) ((tau(j,i), j=1,3), i=1,nat)
      READ(iunit) ((if_pos(j,i), j=1,3), i=1,nat)
      READ(iunit) (atm(i), i=1,nsp)
      READ(iunit) (amass(i), i=1,nsp)
      !
      ! Read k-point information
      READ(iunit) nks_tmp, nkstot
      IF ( nks_tmp /= nks ) THEN
        CLOSE(iunit)
        WRITE(stdout, '(/,5X,"ERROR: K-point number mismatch")')
        STOP 1
      END IF
      !
      READ(iunit) ((xk(j,ik), j=1,3), ik=1,nks)
      READ(iunit) (wk(ik), ik=1,nks)
      READ(iunit) lgauss, degauss, ngauss
      !
      ! Read band structure
      READ(iunit) nbnd_tmp, npwx
      IF ( nbnd_tmp /= nbnd ) THEN
        CLOSE(iunit)
        WRITE(stdout, '(/,5X,"ERROR: Band number mismatch")')
        STOP 1
      END IF
      !
      READ(iunit) ((et(ibnd,ik), ibnd=1,nbnd), ik=1,nks)
      READ(iunit) ((wg(ibnd,ik), ibnd=1,nbnd), ik=1,nks)
      !
      ! Skip optional data for now
      READ(iunit) has_forces
      IF ( has_forces ) READ(iunit) ! Skip forces
      !
      READ(iunit) has_stress  
      IF ( has_stress ) READ(iunit) ! Skip stress
      !
      READ(iunit) has_restart_info
      IF ( has_restart_info ) READ(iunit) restart_info_tmp
      !
      CLOSE(iunit)
      !
      WRITE(stdout, '(5X,"Checkpoint loaded successfully")')
      WRITE(stdout, '(5X,"Resuming from SCF iteration: ",I5)') scf_iter_tmp
      WRITE(stdout, '(5X,"Previous total energy: ",F15.8," Ry")') etot_tmp
      !
    END IF
    !
    ! Broadcast checkpoint data to all processors
    CALL mp_bcast(istep, ionode_id, world_comm)
    CALL mp_bcast(nstep, ionode_id, world_comm)
    CALL mp_bcast(ethr, ionode_id, world_comm)
    ! ... broadcast other necessary data ...
    !
  END SUBROUTINE load_checkpoint
  !
  !-----------------------------------------------------------------------
  SUBROUTINE write_status_snapshot(scf_iter, etot, forces, stress)
    !-----------------------------------------------------------------------
    !! Write a status snapshot without interrupting the calculation
    !
    USE io_global, ONLY : ionode
    !
    IMPLICIT NONE
    !
    INTEGER, INTENT(IN) :: scf_iter
    REAL(DP), INTENT(IN) :: etot
    REAL(DP), INTENT(IN), OPTIONAL :: forces(:,:)
    REAL(DP), INTENT(IN), OPTIONAL :: stress(:,:)
    !
    CHARACTER(LEN=256) :: snapshot_file
    INTEGER :: timestamp(8)
    INTEGER :: iunit, ios, i
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
      IF ( PRESENT(forces) ) THEN
        WRITE(iunit, '(/,A)') "Forces (Ry/au):"
        DO i = 1, SIZE(forces, 2)
          WRITE(iunit, '(I5,3F15.8)') i, forces(:,i)
        END DO
      END IF
      !
      IF ( PRESENT(stress) ) THEN
        WRITE(iunit, '(/,A)') "Stress (kbar):"
        DO i = 1, 3
          WRITE(iunit, '(3F15.8)') stress(i,:)
        END DO
      END IF
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