!
! Copyright (C) 2025 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!--------------------------------------------------------------------------
MODULE auto_optimize_mod
  !--------------------------------------------------------------------------
  !
  ! ... This module handles AUTO_OPTIMIZE namelist input and configuration
  ! ... for automatic parameter optimization
  !
  USE kinds,                  ONLY : DP
  USE parameter_optimization, ONLY : param_optimizer
  USE input_parameters,       ONLY : optimize_kpoints, optimize_cutoff, &
                                     target_accuracy, max_iterations, &
                                     kpoint_spacing, cutoff_min, cutoff_max, cutoff_step
  !
  IMPLICIT NONE
  SAVE
  PRIVATE
  !
  ! ... Module instance of parameter optimizer
  TYPE(param_optimizer) :: auto_opt
  !
  ! ... Public variables and routines
  PUBLIC :: auto_opt
  PUBLIC :: read_auto_optimize
  PUBLIC :: apply_kpoint_optimization
  !
CONTAINS
  !
  !----------------------------------------------------------------------------
  SUBROUTINE read_auto_optimize()
    !----------------------------------------------------------------------------
    !
    ! ... Read AUTO_OPTIMIZE namelist and initialize parameter optimizer
    !
    USE io_global,              ONLY : ionode, ionode_id
    USE mp,                     ONLY : mp_bcast
    USE mp_images,              ONLY : intra_image_comm
    USE parameter_optimization, ONLY : init_param_optimizer
    !
    IMPLICIT NONE
    !
    ! Note: actual namelist reading happens in read_namelists.f90
    ! This routine is called after the namelist has been read
    ! to initialize the parameter optimizer
    !
    ! Initialize the parameter optimizer with namelist values
    CALL init_param_optimizer( auto_opt, target_accuracy, max_iterations, &
                              optimize_kpoints, optimize_cutoff )
    !
    ! Set additional parameters
    auto_opt%kpoint_spacing = kpoint_spacing
    auto_opt%cutoff_min = cutoff_min
    auto_opt%cutoff_max = cutoff_max
    auto_opt%cutoff_step = cutoff_step
    !
  END SUBROUTINE read_auto_optimize
  !
  !----------------------------------------------------------------------------
  SUBROUTINE apply_kpoint_optimization()
    !----------------------------------------------------------------------------
    !
    ! ... Apply k-point optimization if requested
    ! ... This is called from input.f90 after cell parameters are set up
    !
    USE io_global,              ONLY : ionode, stdout
    USE input_parameters,       ONLY : k_points, nk1_ => nk1, nk2_ => nk2, nk3_ => nk3
    USE cell_base,              ONLY : bg, alat
    USE constants,              ONLY : pi
    USE parameter_optimization, ONLY : suggest_kpoint_grid
    !
    IMPLICIT NONE
    !
    INTEGER :: nk_suggest(3), nk1_orig, nk2_orig, nk3_orig
    !
    IF ( auto_opt%optimize_kpoints .AND. k_points == 'automatic' ) THEN
       !
       ! Save original values
       nk1_orig = nk1_
       nk2_orig = nk2_
       nk3_orig = nk3_
       !
       ! Get suggested k-point grid
       CALL suggest_kpoint_grid( auto_opt, nk_suggest )
       !
       ! Override k-point grid in input_parameters module
       nk1_ = nk_suggest(1)
       nk2_ = nk_suggest(2)  
       nk3_ = nk_suggest(3)
       !
       IF ( ionode ) THEN
          WRITE(stdout,'(/,5X,"AUTO_OPTIMIZE: Applied optimized k-point grid")')
          WRITE(stdout,'(5X,"Now using: nk1=",I3,", nk2=",I3,", nk3=",I3,/)') &
               nk1_, nk2_, nk3_
          ! Also write to stderr for user awareness
          WRITE(0,'("AUTO_OPTIMIZE: Using k-point grid ",I3,"x",I3,"x",I3, &
               & " (optimized from ",I3,"x",I3,"x",I3,")")') &
               nk1_, nk2_, nk3_, nk1_orig, nk2_orig, nk3_orig
       END IF
       !
    ELSE IF ( auto_opt%optimize_kpoints .AND. k_points /= 'automatic' ) THEN
       !
       ! Warn if k-point optimization was requested but not possible
       IF ( ionode ) THEN
          WRITE(stdout,'(/,5X,"WARNING: K-point optimization requested but k_points = ''", &
               & A,"''"/)') TRIM(k_points)
          WRITE(stdout,'(5X,"AUTO_OPTIMIZE only works with K_POINTS (automatic)")')
          WRITE(stdout,'(5X,"Add the following to your input file:")')
          WRITE(stdout,'(5X,"K_POINTS (automatic)")')
          WRITE(stdout,'(5X,"  4 4 4 0 0 0",/)')
       END IF
       !
    END IF
    !
  END SUBROUTINE apply_kpoint_optimization
  !
END MODULE auto_optimize_mod