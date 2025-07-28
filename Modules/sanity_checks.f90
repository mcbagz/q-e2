!
! Copyright (C) 2024 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!----------------------------------------------------------------------------
MODULE sanity_checks
  !----------------------------------------------------------------------------
  !! Sanity check system for detecting common input errors and unusual configurations.
  !! Provides configurable warnings and allows users to proceed despite issues.
  !
  USE kinds,         ONLY : DP
  USE io_global,     ONLY : stdout, stdin, meta_ionode
  USE mp,            ONLY : mp_bcast
  USE mp_world,      ONLY : root, world_comm
  USE ions_base,     ONLY : nat, tau, ityp, atm, nsp
  USE cell_base,     ONLY : at, alat, celldm
  USE sanity_config, ONLY : sanity_settings, sanity_opts
  USE constants,     ONLY : bohr_radius_angs
  !
  IMPLICIT NONE
  !
  SAVE
  !
  ! ... Standard error unit (unit 0 in Fortran)
  INTEGER, PARAMETER :: stderr = 0
  !
  ! ... Warning structure
  TYPE sanity_warning
     INTEGER :: level ! 1=info, 2=warning, 3=critical
     CHARACTER(LEN=256) :: message
     CHARACTER(LEN=256) :: suggestion
  END TYPE sanity_warning
  !
  TYPE(sanity_warning), ALLOCATABLE :: warnings(:)
  INTEGER :: n_warnings = 0
  INTEGER :: n_info = 0
  INTEGER :: n_critical = 0
  INTEGER :: max_warnings = 100
  !
  PRIVATE
  PUBLIC :: run_all_checks
  PUBLIC :: sanity_warning, warnings, n_warnings, n_critical
  !
CONTAINS
  !
  !----------------------------------------------------------------------------
  SUBROUTINE run_all_checks(allow_continue)
    !----------------------------------------------------------------------------
    !! Run all sanity checks and handle user interaction.
    !
    IMPLICIT NONE
    !
    LOGICAL, INTENT(OUT) :: allow_continue
    !
    allow_continue = .TRUE.
    !
    ! ... Initialize warning array
    IF (ALLOCATED(warnings)) DEALLOCATE(warnings)
    ALLOCATE(warnings(max_warnings))
    n_warnings = 0
    n_info = 0
    n_critical = 0
    !
    ! ... Skip if disabled
    IF (sanity_opts%ignore_all .OR. .NOT. sanity_opts%enabled) THEN
       IF (meta_ionode) THEN
          WRITE(stderr,'(/,5X,"Sanity checks disabled")')
       END IF
       RETURN
    END IF
    !
    ! ... Run all checks
    CALL check_atomic_distances()
    CALL check_cell_parameters()
    CALL check_isolated_atoms()
    CALL check_symmetry_breaking()
    !
    ! ... Print report
    CALL print_sanity_report()
    !
    ! ... Always continue execution (no user interaction)
    allow_continue = .TRUE.
    !
    ! ... Exit if checks only mode
    IF (sanity_opts%checks_only) THEN
       IF (meta_ionode) THEN
          WRITE(stderr,'(/,5X,"Sanity checks completed. Exiting as requested.")')
       END IF
       allow_continue = .FALSE.
    END IF
    !
    ! ... Broadcast decision to all processors
    CALL mp_bcast(allow_continue, root, world_comm)
    !
  END SUBROUTINE run_all_checks
  !
  !----------------------------------------------------------------------------
  SUBROUTINE check_atomic_distances()
    !----------------------------------------------------------------------------
    !! Check for atoms that are too close together.
    !
    IMPLICIT NONE
    !
    INTEGER :: ia, ja
    REAL(DP) :: dist, min_dist, warn_dist, crit_dist
    REAL(DP) :: dr(3)
    CHARACTER(LEN=256) :: msg, sug
    !
    ! ... Distance thresholds in Angstrom
    crit_dist = 0.5_DP  ! Critical: atoms closer than 0.5 Å
    warn_dist = 1.0_DP  ! Warning: atoms closer than 1.0 Å
    !
    ! ... Convert to Bohr
    crit_dist = crit_dist / bohr_radius_angs
    warn_dist = warn_dist / bohr_radius_angs
    !
    ! ... Check all pairs
    DO ia = 1, nat
       DO ja = ia + 1, nat
          dr(:) = tau(:,ia) - tau(:,ja)
          ! ... Apply minimum image convention
          CALL cryst_to_cart(1, dr, at, -1)
          dr(1) = dr(1) - NINT(dr(1))
          dr(2) = dr(2) - NINT(dr(2))
          dr(3) = dr(3) - NINT(dr(3))
          CALL cryst_to_cart(1, dr, at, 1)
          !
          dist = SQRT(SUM(dr**2)) * alat
          !
          IF (dist < crit_dist) THEN
             WRITE(msg,'(A,I4,A,I4,A,F6.3,A)') &
                  'Atoms ', ia, ' and ', ja, ' are critically close (', &
                  dist * bohr_radius_angs, ' Å)'
             WRITE(sug,'(A)') &
                  'Check atomic positions or increase separation to > 0.5 Å'
             CALL add_warning(3, msg, sug)
          ELSE IF (dist < warn_dist) THEN
             WRITE(msg,'(A,I4,A,I4,A,F6.3,A)') &
                  'Atoms ', ia, ' and ', ja, ' are very close (', &
                  dist * bohr_radius_angs, ' Å)'
             WRITE(sug,'(A)') &
                  'Consider checking if this distance is intentional'
             CALL add_warning(2, msg, sug)
          END IF
       END DO
    END DO
    !
  END SUBROUTINE check_atomic_distances
  !
  !----------------------------------------------------------------------------
  SUBROUTINE check_cell_parameters()
    !----------------------------------------------------------------------------
    !! Check for unusual cell parameters.
    !
    IMPLICIT NONE
    !
    REAL(DP) :: a, b, c, alpha, beta, gamma
    REAL(DP) :: vol, min_angle, max_angle
    CHARACTER(LEN=256) :: msg, sug
    !
    ! ... Get cell parameters
    a = SQRT(SUM(at(:,1)**2)) * alat
    b = SQRT(SUM(at(:,2)**2)) * alat
    c = SQRT(SUM(at(:,3)**2)) * alat
    !
    ! ... Calculate angles in degrees
    alpha = ACOS(DOT_PRODUCT(at(:,2), at(:,3)) / &
                 (SQRT(SUM(at(:,2)**2)) * SQRT(SUM(at(:,3)**2)))) * 180.0_DP / 3.14159265359_DP
    beta  = ACOS(DOT_PRODUCT(at(:,1), at(:,3)) / &
                 (SQRT(SUM(at(:,1)**2)) * SQRT(SUM(at(:,3)**2)))) * 180.0_DP / 3.14159265359_DP
    gamma = ACOS(DOT_PRODUCT(at(:,1), at(:,2)) / &
                 (SQRT(SUM(at(:,1)**2)) * SQRT(SUM(at(:,2)**2)))) * 180.0_DP / 3.14159265359_DP
    !
    ! ... Check for very small cells
    IF (a < 2.0_DP .OR. b < 2.0_DP .OR. c < 2.0_DP) THEN
       WRITE(msg,'(A,3F8.3,A)') &
            'Cell dimensions are very small: ', &
            a * bohr_radius_angs, b * bohr_radius_angs, c * bohr_radius_angs, ' Å'
       WRITE(sug,'(A)') &
            'Check if cell parameters are in correct units (Bohr vs Angstrom)'
       CALL add_warning(3, msg, sug)
    END IF
    !
    ! ... Check for extreme angles
    min_angle = MIN(alpha, beta, gamma)
    max_angle = MAX(alpha, beta, gamma)
    !
    IF (min_angle < 30.0_DP .OR. max_angle > 150.0_DP) THEN
       WRITE(msg,'(A,3F8.2)') &
            'Cell angles are extreme: α=', alpha, ' β=', beta, ' γ=', gamma
       WRITE(sug,'(A)') &
            'Very acute or obtuse angles may cause numerical issues'
       CALL add_warning(2, msg, sug)
    END IF
    !
    ! ... Check aspect ratios
    IF (MAX(a,b,c)/MIN(a,b,c) > 10.0_DP) THEN
       WRITE(msg,'(A,F8.2)') &
            'Cell has extreme aspect ratio: ', MAX(a,b,c)/MIN(a,b,c)
       WRITE(sug,'(A)') &
            'Consider using a more balanced cell if possible'
       CALL add_warning(1, msg, sug)
    END IF
    !
  END SUBROUTINE check_cell_parameters
  !
  !----------------------------------------------------------------------------
  SUBROUTINE check_isolated_atoms()
    !----------------------------------------------------------------------------
    !! Check for atoms that appear to be isolated from others.
    !
    IMPLICIT NONE
    !
    INTEGER :: ia, ja, n_neighbors
    REAL(DP) :: dist, isolation_dist
    REAL(DP) :: dr(3)
    CHARACTER(LEN=256) :: msg, sug
    !
    ! ... Isolation threshold: no neighbors within 5 Å
    isolation_dist = 5.0_DP / bohr_radius_angs
    !
    DO ia = 1, nat
       n_neighbors = 0
       DO ja = 1, nat
          IF (ia == ja) CYCLE
          !
          dr(:) = tau(:,ia) - tau(:,ja)
          ! ... Apply minimum image convention
          CALL cryst_to_cart(1, dr, at, -1)
          dr(1) = dr(1) - NINT(dr(1))
          dr(2) = dr(2) - NINT(dr(2))
          dr(3) = dr(3) - NINT(dr(3))
          CALL cryst_to_cart(1, dr, at, 1)
          !
          dist = SQRT(SUM(dr**2)) * alat
          IF (dist < isolation_dist) n_neighbors = n_neighbors + 1
       END DO
       !
       IF (n_neighbors == 0) THEN
          WRITE(msg,'(A,I4,A,A,A)') &
               'Atom ', ia, ' (', TRIM(atm(ityp(ia))), &
               ') appears to be isolated (no neighbors within 5 Å)'
          WRITE(sug,'(A)') &
               'Check if this is intentional or if coordinates are correct'
          CALL add_warning(2, msg, sug)
       END IF
    END DO
    !
  END SUBROUTINE check_isolated_atoms
  !
  !----------------------------------------------------------------------------
  SUBROUTINE check_symmetry_breaking()
    !----------------------------------------------------------------------------
    !! Check for common symmetry-breaking issues.
    !
    IMPLICIT NONE
    !
    INTEGER :: ia, ja, isp
    REAL(DP) :: dr(3), dist, tol
    LOGICAL :: found_pair
    CHARACTER(LEN=256) :: msg, sug
    !
    tol = 0.01_DP  ! Position tolerance in Bohr
    !
    ! ... Check for nearly identical atoms of the same species
    DO isp = 1, nsp
       DO ia = 1, nat
          IF (ityp(ia) /= isp) CYCLE
          DO ja = ia + 1, nat
             IF (ityp(ja) /= isp) CYCLE
             !
             dr(:) = tau(:,ia) - tau(:,ja)
             ! ... Apply minimum image convention
             CALL cryst_to_cart(1, dr, at, -1)
             dr(1) = dr(1) - NINT(dr(1))
             dr(2) = dr(2) - NINT(dr(2))
             dr(3) = dr(3) - NINT(dr(3))
             CALL cryst_to_cart(1, dr, at, 1)
             !
             dist = SQRT(SUM(dr**2)) * alat
             !
             IF (dist < tol) THEN
                WRITE(msg,'(A,I4,A,I4,A,A,A)') &
                     'Atoms ', ia, ' and ', ja, ' (both ', &
                     TRIM(atm(isp)), ') are nearly coincident'
                WRITE(sug,'(A)') &
                     'This will break symmetry detection. Remove duplicate atom.'
                CALL add_warning(3, msg, sug)
             END IF
          END DO
       END DO
    END DO
    !
    ! ... Check for atoms very close to high-symmetry positions
    DO ia = 1, nat
       ! ... Check if very close to cell center
       dr(:) = tau(:,ia)
       CALL cryst_to_cart(1, dr, at, -1)
       IF (ABS(dr(1) - 0.5_DP) < tol/alat .AND. &
           ABS(dr(2) - 0.5_DP) < tol/alat .AND. &
           ABS(dr(3) - 0.5_DP) < tol/alat) THEN
          WRITE(msg,'(A,I4,A)') &
               'Atom ', ia, ' is very close to cell center (0.5,0.5,0.5)'
          WRITE(sug,'(A)') &
               'If exact symmetry is desired, set position exactly'
          CALL add_warning(1, msg, sug)
       END IF
       !
       ! ... Check if very close to origin
       IF (ABS(dr(1)) < tol/alat .AND. &
           ABS(dr(2)) < tol/alat .AND. &
           ABS(dr(3)) < tol/alat) THEN
          WRITE(msg,'(A,I4,A)') &
               'Atom ', ia, ' is very close to origin (0,0,0)'
          WRITE(sug,'(A)') &
               'If exact symmetry is desired, set position exactly'
          CALL add_warning(1, msg, sug)
       END IF
    END DO
    !
  END SUBROUTINE check_symmetry_breaking
  !
  !----------------------------------------------------------------------------
  SUBROUTINE add_warning(level, message, suggestion)
    !----------------------------------------------------------------------------
    !! Add a warning to the list if it meets the minimum level requirement.
    !
    IMPLICIT NONE
    !
    INTEGER, INTENT(IN) :: level
    CHARACTER(LEN=*), INTENT(IN) :: message, suggestion
    !
    ! ... Check if this warning level should be recorded
    IF (level < sanity_opts%min_level) RETURN
    !
    ! ... Check if we have space
    IF (n_warnings >= max_warnings) RETURN
    !
    n_warnings = n_warnings + 1
    warnings(n_warnings)%level = level
    warnings(n_warnings)%message = message
    warnings(n_warnings)%suggestion = suggestion
    !
    ! ... Update counters
    SELECT CASE (level)
    CASE (1)
       n_info = n_info + 1
    CASE (3)
       n_critical = n_critical + 1
    END SELECT
    !
  END SUBROUTINE add_warning
  !
  !----------------------------------------------------------------------------
  SUBROUTINE print_sanity_report()
    !----------------------------------------------------------------------------
    !! Print a formatted report of all warnings found.
    !
    IMPLICIT NONE
    !
    INTEGER :: i
    CHARACTER(LEN=12) :: level_str
    CHARACTER(LEN=6) :: icon
    !
    IF (.NOT. meta_ionode) RETURN
    !
    IF (n_warnings == 0) THEN
       WRITE(stderr,'(/,5X,"Sanity checks passed: No issues found")')
       RETURN
    END IF
    !
    WRITE(stderr,'(/,5X,70("="))')
    WRITE(stderr,'(5X,"SANITY CHECK REPORT")')
    WRITE(stderr,'(5X,70("="))')
    WRITE(stderr,'(5X,"Found ",I3," issue(s): ",I3," critical, ",I3," warning(s), ",I3," info")') &
         n_warnings, n_critical, n_warnings - n_critical - n_info, n_info
    WRITE(stderr,'(5X,70("-"))')
    !
    DO i = 1, n_warnings
       SELECT CASE (warnings(i)%level)
       CASE (1)
          level_str = '[INFO]      '
          icon = '  (i) '
       CASE (2)
          level_str = '[WARNING]   '
          icon = '  /!\ '
       CASE (3)
          level_str = '[CRITICAL]  '
          icon = ' [!!!]'
       END SELECT
       !
       WRITE(stderr,'(/,5X,A,A,A)') icon, level_str, TRIM(warnings(i)%message)
       WRITE(stderr,'(11X,"→ ",A)') TRIM(warnings(i)%suggestion)
    END DO
    !
    WRITE(stderr,'(5X,70("="),/)')
    !
  END SUBROUTINE print_sanity_report
  !
  !----------------------------------------------------------------------------
  !
  !----------------------------------------------------------------------------
  SUBROUTINE cryst_to_cart(npt, tau_in, at_in, iflag)
    !----------------------------------------------------------------------------
    !! Local version of coordinate transformation.
    !! iflag = 1: crystal to cartesian
    !! iflag = -1: cartesian to crystal
    !
    IMPLICIT NONE
    !
    INTEGER, INTENT(IN) :: npt, iflag
    REAL(DP), INTENT(INOUT) :: tau_in(3,npt)
    REAL(DP), INTENT(IN) :: at_in(3,3)
    !
    INTEGER :: i
    REAL(DP) :: bg(3,3), tau_tmp(3)
    !
    IF (iflag == 1) THEN
       ! ... Crystal to Cartesian
       DO i = 1, npt
          tau_tmp(:) = tau_in(:,i)
          tau_in(:,i) = at_in(:,1) * tau_tmp(1) + &
                       at_in(:,2) * tau_tmp(2) + &
                       at_in(:,3) * tau_tmp(3)
       END DO
    ELSE IF (iflag == -1) THEN
       ! ... Cartesian to Crystal - need reciprocal lattice
       CALL recips(at_in(:,1), at_in(:,2), at_in(:,3), bg(:,1), bg(:,2), bg(:,3))
       DO i = 1, npt
          tau_tmp(:) = tau_in(:,i)
          tau_in(1,i) = DOT_PRODUCT(tau_tmp, bg(:,1))
          tau_in(2,i) = DOT_PRODUCT(tau_tmp, bg(:,2))
          tau_in(3,i) = DOT_PRODUCT(tau_tmp, bg(:,3))
       END DO
    END IF
    !
  END SUBROUTINE cryst_to_cart
  !
  !----------------------------------------------------------------------------
  SUBROUTINE recips(a1, a2, a3, b1, b2, b3)
    !----------------------------------------------------------------------------
    !! Calculate reciprocal lattice vectors.
    !
    IMPLICIT NONE
    !
    REAL(DP), INTENT(IN) :: a1(3), a2(3), a3(3)
    REAL(DP), INTENT(OUT) :: b1(3), b2(3), b3(3)
    !
    REAL(DP) :: vol
    !
    b1(1) = a2(2) * a3(3) - a2(3) * a3(2)
    b1(2) = a2(3) * a3(1) - a2(1) * a3(3)
    b1(3) = a2(1) * a3(2) - a2(2) * a3(1)
    !
    b2(1) = a3(2) * a1(3) - a3(3) * a1(2)
    b2(2) = a3(3) * a1(1) - a3(1) * a1(3)
    b2(3) = a3(1) * a1(2) - a3(2) * a1(1)
    !
    b3(1) = a1(2) * a2(3) - a1(3) * a2(2)
    b3(2) = a1(3) * a2(1) - a1(1) * a2(3)
    b3(3) = a1(1) * a2(2) - a1(2) * a2(1)
    !
    vol = DOT_PRODUCT(a1, b1)
    !
    b1 = b1 / vol
    b2 = b2 / vol
    b3 = b3 / vol
    !
  END SUBROUTINE recips
  !
END MODULE sanity_checks