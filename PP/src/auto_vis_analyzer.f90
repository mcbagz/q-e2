!
! Copyright (C) 2024 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------------------------------------
MODULE auto_vis_analyzer_mod
  !-----------------------------------------------------------------------
  !
  ! Module for analyzing completed calculation output directories
  ! to determine what visualizations can be automatically generated
  !
  USE kinds, ONLY : DP
  USE io_global, ONLY : stdout, ionode
  !
  IMPLICIT NONE
  !
  PRIVATE
  !
  ! Data structure to hold information about available plots
  TYPE :: available_plots_type
     LOGICAL :: charge_density        ! Total charge density
     LOGICAL :: spin_density         ! Spin density (if spin-polarized)
     LOGICAL :: potential            ! Total potential
     LOGICAL :: wavefunctions        ! Kohn-Sham wavefunctions
     LOGICAL :: elf                  ! Electron Localization Function
     LOGICAL :: stm                  ! STM images
     LOGICAL :: psi_squared          ! |psi|^2
     LOGICAL :: partial_charge       ! Partial charge (LDOS)
     INTEGER :: nspin                ! Number of spin components
     INTEGER :: nks                  ! Number of k-points
     INTEGER :: nbnd                 ! Number of bands
     CHARACTER(len=256) :: prefix    ! Calculation prefix
  END TYPE available_plots_type
  !
  PUBLIC :: analyze_output_directory, available_plots_type, update_nspin
  !
CONTAINS
  !
  !-----------------------------------------------------------------------
  SUBROUTINE analyze_output_directory(out_dir, available_plots)
    !-----------------------------------------------------------------------
    !
    ! Analyzes the output directory and determines what plots can be generated
    ! Uses a simplified approach without XML parsing
    !
    USE io_files, ONLY : prefix
    !
    IMPLICIT NONE
    !
    CHARACTER(len=*), INTENT(in) :: out_dir
    TYPE(available_plots_type), INTENT(out) :: available_plots
    !
    CHARACTER(len=256) :: dirname, filename
    LOGICAL :: found
    !
    ! Initialize all flags to false
    available_plots%charge_density = .FALSE.
    available_plots%spin_density = .FALSE.
    available_plots%potential = .FALSE.
    available_plots%wavefunctions = .FALSE.
    available_plots%elf = .FALSE.
    available_plots%stm = .FALSE.
    available_plots%psi_squared = .FALSE.
    available_plots%partial_charge = .FALSE.
    available_plots%nspin = 1
    available_plots%nks = 0
    available_plots%nbnd = 0
    available_plots%prefix = 'pwscf'
    !
    ! Construct path to directory
    dirname = TRIM(out_dir)
    IF (dirname(LEN_TRIM(dirname):LEN_TRIM(dirname)) /= '/') THEN
       dirname = TRIM(dirname) // '/'
    END IF
    !
    ! Try to find and extract prefix from directory name
    CALL extract_prefix_from_dir(dirname, available_plots%prefix)
    !
    IF (ionode) THEN
       WRITE(stdout,'(/,5X,"Analyzing output directory: ",A)') TRIM(out_dir)
    END IF
    !
    ! Check for existence of key files to determine available data
    ! This is a simplified approach that doesn't require XML parsing
    !
    ! Check for charge density file
    filename = TRIM(dirname) // 'charge-density.dat'
    INQUIRE(file=filename, exist=found)
    IF (found) available_plots%charge_density = .TRUE.
    !
    ! Check for data-file-schema.xml (indicates complete calculation)
    filename = TRIM(dirname) // 'data-file-schema.xml'
    INQUIRE(file=filename, exist=found)
    IF (found) THEN
       ! If XML exists, we can generate most standard plots
       available_plots%charge_density = .TRUE.
       available_plots%potential = .TRUE.
       available_plots%wavefunctions = .TRUE.
    END IF
    !
    ! For now, we'll assume standard plots are available if the XML exists
    ! This is a conservative approach that ensures compatibility
    IF (available_plots%charge_density) THEN
       available_plots%elf = .TRUE.  ! ELF can be computed from charge density
    END IF
    !
    IF (available_plots%wavefunctions) THEN
       available_plots%psi_squared = .TRUE.
       available_plots%stm = .TRUE.
       available_plots%partial_charge = .TRUE.
    END IF
    !
    ! Note: To properly detect spin polarization, we would need to read
    ! the actual data. For now, we'll rely on the read_file() call
    ! in the main routine to set up the proper spin configuration
    !
    IF (ionode) THEN
       CALL determine_available_plots(available_plots)
    END IF
    !
  END SUBROUTINE analyze_output_directory
  !
  !-----------------------------------------------------------------------
  SUBROUTINE extract_prefix_from_dir(dirname, prefix)
    !-----------------------------------------------------------------------
    ! Try to extract prefix from directory structure
    ! Expected format: path/prefix.save/
    !
    IMPLICIT NONE
    CHARACTER(len=*), INTENT(in) :: dirname
    CHARACTER(len=*), INTENT(out) :: prefix
    !
    INTEGER :: i, j
    CHARACTER(len=256) :: temp
    !
    temp = TRIM(dirname)
    ! Remove trailing slash if present
    i = LEN_TRIM(temp)
    IF (temp(i:i) == '/') temp = temp(1:i-1)
    !
    ! Find last occurrence of '/'
    j = INDEX(temp, '/', BACK=.TRUE.)
    IF (j > 0) THEN
       temp = temp(j+1:)
    END IF
    !
    ! Check if it ends with .save
    i = INDEX(temp, '.save')
    IF (i > 0) THEN
       prefix = temp(1:i-1)
    ELSE
       prefix = 'pwscf'
    END IF
    !
  END SUBROUTINE extract_prefix_from_dir
  !-----------------------------------------------------------------------
  SUBROUTINE determine_available_plots(available_plots)
    !-----------------------------------------------------------------------
    ! Report what plots can be generated
    !
    IMPLICIT NONE
    TYPE(available_plots_type), INTENT(inout) :: available_plots
    !
    ! Report findings
    IF (ionode) THEN
       WRITE(stdout,'(/,5X,"Available data for visualization:")')
       IF (available_plots%charge_density) WRITE(stdout,'(5X,"  - Charge density")')
       IF (available_plots%spin_density) WRITE(stdout,'(5X,"  - Spin density")')
       IF (available_plots%potential) WRITE(stdout,'(5X,"  - Total potential")')
       IF (available_plots%wavefunctions) WRITE(stdout,'(5X,"  - Wavefunctions")')
       IF (available_plots%elf) WRITE(stdout,'(5X,"  - ELF (Electron Localization Function)")')
       IF (available_plots%stm) WRITE(stdout,'(5X,"  - STM images")')
       IF (available_plots%psi_squared) WRITE(stdout,'(5X,"  - |psi|^2")')
       IF (available_plots%partial_charge) WRITE(stdout,'(5X,"  - Partial charge (LDOS)")')
    END IF
    !
  END SUBROUTINE determine_available_plots
  !
  !-----------------------------------------------------------------------
  SUBROUTINE update_nspin(available_plots, nspin_value)
    !-----------------------------------------------------------------------
    ! Update nspin information after reading the file
    !
    IMPLICIT NONE
    TYPE(available_plots_type), INTENT(inout) :: available_plots
    INTEGER, INTENT(in) :: nspin_value
    !
    available_plots%nspin = nspin_value
    !
    ! Update spin-dependent flags
    IF (available_plots%nspin > 1 .AND. available_plots%charge_density) THEN
       available_plots%spin_density = .TRUE.
    END IF
    !
  END SUBROUTINE update_nspin
  !
END MODULE auto_vis_analyzer_mod