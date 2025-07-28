!
! Copyright (C) 2001-2024 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
MODULE pp_module
CONTAINS
!-----------------------------------------------------------------------
SUBROUTINE extract (plot_files,plot_num,nc)
  !-----------------------------------------------------------------------
  !
  !    Reads data produced by pw.x, computes the desired quantity (rho, V, ...)
  !    and writes it to a file (or multiple files) for further processing or
  !    plotting
  !
  !    On return, plot_files contains a list of all written files.
  !
  !    DESCRIPTION of the INPUT: see file Doc/INPUT_PP
  !
  USE kinds,     ONLY : DP
  USE cell_base, ONLY : bg
  USE ener,      ONLY : ef
  USE ions_base, ONLY : nat, ntyp=>nsp, ityp, tau
  USE gvect
  USE fft_base,  ONLY : dfftp
  USE klist,     ONLY : two_fermi_energies, degauss, ngauss
  USE vlocal,    ONLY : strf
  USE io_files,  ONLY : tmp_dir, prefix
  USE io_global, ONLY : ionode, ionode_id
  USE noncollin_module, ONLY : i_cons
  USE paw_variables, ONLY : okpaw
  USE mp,        ONLY : mp_bcast
  USE mp_images, ONLY : intra_image_comm
  USE constants, ONLY : rytoev
  USE parameters,ONLY : npk
  USE io_global, ONLY : stdout
  USE run_info,  ONLY : title
  USE ldaU,      ONLY : lda_plus_u
  USE lsda_mod,  ONLY : nspin
  !
  IMPLICIT NONE
  !
  CHARACTER(LEN=256), EXTERNAL :: trimcheck
  !
  CHARACTER(len=256), DIMENSION(:), ALLOCATABLE, INTENT(out) :: plot_files
  INTEGER, INTENT(out) :: plot_num
  INTEGER, INTENT(out) :: nc(3)

  INTEGER :: n0(3)
  CHARACTER (len=2), DIMENSION(0:3) :: spin_desc = &
       (/ '  ', '_X', '_Y', '_Z' /)

  INTEGER :: kpoint(2), kband(2), spin_component(3), ios
  LOGICAL :: lsign, needwf, dummy, use_gauss_ldos

  REAL(DP) :: emin, emax, sample_bias, z, dz

  REAL(DP) :: degauss_ldos, delta_e
  CHARACTER(len=256) :: filplot, spin_label(2)
  INTEGER :: plot_nkpt, plot_nbnd, plot_nspin, nplots
  INTEGER :: iplot, iplot2, ikpt, ibnd, ispin

  ! directory for temporary files
  CHARACTER(len=256) :: outdir

  NAMELIST / inputpp / title, outdir, prefix, plot_num, sample_bias, &
      spin_component, z, dz, emin, emax, delta_e, degauss_ldos, kpoint, kband, &
      filplot, lsign, use_gauss_ldos, nc, n0
  !
  !   set default values for variables in namelist
  !
  title = ' '
  prefix = 'pwscf'
  CALL get_environment_variable( 'ESPRESSO_TMPDIR', outdir )
  IF ( trim( outdir ) == ' ' ) outdir = './'
  filplot = 'tmp.pp'
  plot_num = -1
  kpoint(2) = 0
  kband(2) = 0
  spin_component = 0
  sample_bias = 0.01d0
  z = 1.d0
  dz = 0.05d0
  lsign=.false.
  emin = -999.0d0
  emax = +999.0d0
  delta_e=0.1d0
  degauss_ldos=-999.0d0
  use_gauss_ldos=.false.
  nc(:) = 1
  n0(:) = 0
  !
  ios = 0
  !
  IF ( ionode )  THEN
     !
     !     reading the namelist inputpp
     !
     READ (5, inputpp, iostat = ios)
     !
     tmp_dir = trimcheck ( outdir )
     !
  ENDIF
  !
  CALL mp_bcast (ios, ionode_id, intra_image_comm)
  !
  IF ( ios /= 0) CALL errore ('postproc', 'reading inputpp namelist', abs(ios))
  !
  ! ... Broadcast variables
  !
  CALL mp_bcast( title, ionode_id, intra_image_comm )
  CALL mp_bcast( tmp_dir, ionode_id, intra_image_comm )
  CALL mp_bcast( prefix, ionode_id, intra_image_comm )
  CALL mp_bcast( plot_num, ionode_id, intra_image_comm )
  CALL mp_bcast( sample_bias, ionode_id, intra_image_comm )
  CALL mp_bcast( spin_component, ionode_id, intra_image_comm )
  CALL mp_bcast( z, ionode_id, intra_image_comm )
  CALL mp_bcast( dz, ionode_id, intra_image_comm )
  CALL mp_bcast( emin, ionode_id, intra_image_comm )
  CALL mp_bcast( emax, ionode_id, intra_image_comm )
  CALL mp_bcast( degauss_ldos, ionode_id, intra_image_comm )
  CALL mp_bcast( delta_e, ionode_id, intra_image_comm )
  CALL mp_bcast( kband, ionode_id, intra_image_comm )
  CALL mp_bcast( kpoint, ionode_id, intra_image_comm )
  CALL mp_bcast( filplot, ionode_id, intra_image_comm )
  CALL mp_bcast( lsign, ionode_id, intra_image_comm )
  CALL mp_bcast( use_gauss_ldos, ionode_id, intra_image_comm)
  CALL mp_bcast( nc, ionode_id, intra_image_comm )
  CALL mp_bcast( n0, ionode_id, intra_image_comm )
  !
  ! no task specified: do nothing and return
  !
  IF (plot_num == -1) THEN
     ALLOCATE( plot_files(0) )
     RETURN
  ENDIF
  !
  IF (plot_num < 0 .or. (plot_num > 25 .and. &
        plot_num /= 119 .and. plot_num /= 123)) CALL errore ('postproc', &
          'Wrong plot_num', abs (plot_num) )

  IF (plot_num == 7 .or. plot_num == 13 .or. plot_num==18) THEN
     IF  (spin_component(1) < 0 .or. spin_component(1) > 3) CALL errore &
          ('postproc', 'wrong spin_component', 1)
  ELSEIF (plot_num == 10) THEN
     IF  (spin_component(1) < 0 .or. spin_component(1) > 2) CALL errore &
          ('postproc', 'wrong spin_component', 2)
  ELSE
     IF (spin_component(1) < 0 ) CALL errore &
         ('postproc', 'wrong spin_component', 3)
  ENDIF
  !
  ! Check on the nc and n0 variables
  IF (((nc(1)/=1) .OR. (nc(2)/=1) .OR. (nc(3)/=1)) .AND. .NOT.(plot_num==25)) &
     CALL errore('postproc', 'nc can be used only for plot_num=25',1)
  IF (((n0(1)/=0) .OR. (n0(2)/=0) .OR. (n0(3)/=0)) .AND. .NOT.(plot_num==25)) &
     CALL errore('postproc', 'n0 can be used only for plot_num=25',1)
  IF (plot_num==25) THEN
     IF ((nc(1)<1) .OR. (nc(2)<1) .OR. (nc(3)<1)) &
     CALL errore('postproc', 'nc must be greater or equal to 1',1)
  ENDIF
  !
  !   Read xml file, allocate and initialize general variables
  !   If needed, allocate and initialize wavefunction-related variables
  !
  needwf=(plot_num==3).or.(plot_num==4).or.(plot_num==5).or.(plot_num==7).or. &
         (plot_num==8).or.(plot_num==10).or.(plot_num==23).or.(plot_num==25)
  CALL read_file_new ( needwf )
  !
  IF ( ( two_fermi_energies .or. i_cons /= 0) .and. &
       ( plot_num==3 .or. plot_num==4 .or. plot_num==5 ) ) &
     CALL errore('postproc',&
     'Post-processing with constrained magnetization is not available yet',1)
  !
  ! Set default values for emin, emax, degauss_ldos
  ! Done here because ef, degauss must be read from file
  IF (emin > emax) CALL errore('postproc','emin > emax',0)
  IF (plot_num == 10) THEN
      IF (emax == +999.0d0) emax = ef * rytoev
  ELSEIF (plot_num == 3) THEN
      IF (emin == -999.0d0) emin = ef * rytoev
      IF (emax == +999.0d0) emax = ef * rytoev
      IF (degauss_ldos == -999.0d0) THEN
          WRITE(stdout, &
              '(/5x,"degauss_ldos not set, defaults to degauss = ",f6.4, " eV")') &
             degauss * rytoev
          degauss_ldos = degauss * rytoev
      ENDIF
  ENDIF
  ! transforming all back to Ry units
  emin = emin / rytoev
  emax = emax / rytoev
  delta_e = delta_e / rytoev
  degauss_ldos = degauss_ldos / rytoev

  ! Set ngauss to 0 if necessary.
  IF (use_gauss_ldos .AND. plot_num == 3) THEN
    ngauss = 0
  ENDIF

  ! Number of output files depends on input
  nplots = 1
  IF (plot_num == 3) THEN
     nplots=(emax-emin)/delta_e + 1
  ELSEIF (plot_num == 7) THEN
      IF (kpoint(2) == 0)  kpoint(2) = kpoint(1)
      plot_nkpt = kpoint(2) - kpoint(1) + 1
      IF (kband(2) == 0)  kband(2) = kband(1)
      plot_nbnd = kband(2) - kband(1) + 1
      IF (spin_component(2) == 0)  spin_component(2) = spin_component(1)
      plot_nspin = spin_component(2) - spin_component(1) + 1
      nplots = plot_nbnd * plot_nkpt * plot_nspin
  ELSEIF (plot_num == 23) THEN
      IF (spin_component(1) == 3) nplots = 2
  ELSEIF (plot_num == 25) THEN
      IF (.NOT.lda_plus_u) CALL errore('postproc',&
         'plot_num=25 can be used only for DFT+Hubbard',1)
      CALL hubbard_projectors (filplot, plot_num, nc, n0, nplots)
  ENDIF
  ALLOCATE( plot_files(nplots) )
  plot_files(1) = filplot

  ! 
  ! First handle plot_nums with multiple calls to punch_plot
  !
  IF (nplots > 1 .AND. plot_num == 3) THEN
  ! Local density of states on energy grid of spacing delta_e within [emin, emax]
    DO iplot=1,nplots
      WRITE(plot_files(iplot),'(A, I0.3)') TRIM(filplot), iplot
      CALL punch_plot (TRIM(plot_files(iplot)), plot_num, sample_bias, z, dz, &
        emin, degauss_ldos, kpoint, kband, spin_component, lsign)
      emin=emin+delta_e
    ENDDO
  ELSEIF (nplots > 1 .AND. plot_num == 7) THEN
  ! Plot multiple KS orbitals in one go
    iplot = 1
    DO ikpt=kpoint(1), kpoint(2)
      DO ibnd=kband(1), kband(2)
        DO ispin=spin_component(1), spin_component(2)
          WRITE(plot_files(iplot),"(A,A,I0.3,A,I0.3,A)") &
            TRIM(filplot), "_K", ikpt, "_B", ibnd, TRIM(spin_desc(ispin))
          CALL punch_plot (TRIM(plot_files(iplot)), plot_num, sample_bias, z, dz, &
            emin, emax, ikpt, ibnd, ispin, lsign)
          iplot = iplot + 1
        ENDDO
      ENDDO
    ENDDO
  !
  ELSEIF (plot_num == 23) THEN
    !
    IF (spin_component(1) == 3) THEN
        !
        ispin = 1
        plot_files(1) = TRIM(filplot) // "_spin1"
        CALL punch_plot ( TRIM(plot_files(1)), plot_num, sample_bias, z, dz, &
                          emin, emax, ikpt, ibnd, ispin, lsign )
        !
        ispin = 2
        plot_files(2) = TRIM(filplot) // "_spin2"
        CALL punch_plot ( TRIM(plot_files(2)), plot_num, sample_bias, z, dz, &
                          emin, emax, ikpt, ibnd, ispin, lsign )
        !
    ELSE
        CALL punch_plot ( TRIM(plot_files(1)), plot_num, sample_bias, z, dz, &
                          emin, emax, ikpt, ibnd, spin_component, lsign )
        !
    ENDIF
    !
  ELSEIF (plot_num == 25) THEN
    !
    spin_label(:) = ''
    IF (nspin==2) THEN
       spin_label(1) = '_up'
       spin_label(2) = '_down'
       DEALLOCATE (plot_files)
       ALLOCATE (plot_files(nplots*nspin))
    ENDIF
    !
    DO ispin=1,nspin
       DO iplot=1,nplots
          iplot2 = iplot + (ispin-1)*nplots
          WRITE(plot_files(iplot2),'(A, I0.3, A)') TRIM(filplot), iplot, TRIM(spin_label(ispin))
       ENDDO
    ENDDO
    !
  ELSE
    ! Single call to punch_plot
    IF (plot_num == 3) THEN
       CALL punch_plot (filplot, plot_num, sample_bias, z, dz, &
           emin, degauss_ldos, kpoint, kband, spin_component, lsign)
     ELSE
       CALL punch_plot (filplot, plot_num, sample_bias, z, dz, &
          emin, emax, kpoint, kband, spin_component, lsign)
     ENDIF

  ENDIF
  !
  RETURN
  !
END SUBROUTINE extract

END MODULE pp_module
!
!-----------------------------------------------------------------------
PROGRAM pp
  !-----------------------------------------------------------------------
  !
  !    Program for data analysis and plotting. The two basic steps are:
  !    1) read the output file produced by pw.x, extract and calculate
  !       the desired quantity (rho, V, ...)
  !    2) write the desired quantity to file in a suitable format for
  !       various types of plotting and various plotting programs
  !    The two steps can be performed independently. Intermediate data
  !    can be saved to file in step 1 and read from file in step 2.
  !
  !    DESCRIPTION of the INPUT : see file Doc/INPUT_PP.*
  !
  !    NEW: --visualize-all flag for automated visualization
  !         Usage: pp.x --visualize-all -in <output_directory>
  !
  USE io_global,  ONLY : ionode, stdout
  USE mp_global,  ONLY : mp_startup
  USE environment,ONLY : environment_start, environment_end
  USE chdens_module, ONLY : chdens
  USE pp_module, ONLY : extract
  USE io_files,  ONLY : prefix, tmp_dir
  USE auto_vis_analyzer_mod, ONLY : analyze_output_directory, available_plots_type

  !
  IMPLICIT NONE
  !
  CHARACTER(len=256), DIMENSION(:), ALLOCATABLE :: plot_files
  INTEGER :: plot_num
  INTEGER :: nc(3)
  !
  ! Variables for command-line parsing
  LOGICAL :: visualize_all_mode
  CHARACTER(len=256) :: arg, output_dir
  INTEGER :: nargs, iarg
  !
  ! initialise environment
  !
#if defined(__MPI)
  CALL mp_startup ( )
#endif
  CALL environment_start ( 'POST-PROC' )
  !
  ! Check for --visualize-all flag
  visualize_all_mode = .FALSE.
  output_dir = ' '
  nargs = command_argument_count()
  !
  iarg = 1
  DO WHILE (iarg <= nargs)
     CALL get_command_argument(iarg, arg)
     !
     IF (TRIM(arg) == '--visualize-all') THEN
        visualize_all_mode = .TRUE.
        IF (iarg + 2 <= nargs) THEN
           CALL get_command_argument(iarg + 1, arg)
           IF (TRIM(arg) == '-in') THEN
              CALL get_command_argument(iarg + 2, output_dir)
              iarg = iarg + 2
           END IF
        END IF
     END IF
     iarg = iarg + 1
  END DO
  !
  IF (visualize_all_mode) THEN
     ! New automated visualization mode
     IF (ionode) THEN
        WRITE(stdout,'(/,5X,"Automated visualization mode activated")')
        IF (TRIM(output_dir) == ' ') THEN
           WRITE(stdout,'(5X,"Error: Output directory not specified")')
           WRITE(stdout,'(5X,"Usage: pp.x --visualize-all -in <output_directory>")')
           CALL stop_pp()
        END IF
        WRITE(stdout,'(5X,"Output directory: ",A)') TRIM(output_dir)
     END IF
     !
     ! Call the automated visualization subroutine
     CALL auto_visualize(output_dir)
     !
  ELSE
     ! Traditional mode - read input from file or stdin
     IF ( ionode )  CALL input_from_file ( )
     !
     CALL extract (plot_files, plot_num, nc)
     !
     CALL chdens (plot_files, plot_num, nc)
  END IF
  !
  CALL environment_end ( 'POST-PROC' )
  !
  CALL stop_pp()
  !
CONTAINS
  !
  !-----------------------------------------------------------------------
  SUBROUTINE auto_visualize(out_dir)
    !-----------------------------------------------------------------------
    ! Automated visualization orchestrator
    ! Analyzes output directory and generates all possible visualizations
    ! by creating input files and calling pp.x externally
    !
    USE io_global, ONLY : stdout, ionode
    USE io_files,  ONLY : prefix, tmp_dir
    USE kinds,     ONLY : DP
    USE auto_vis_analyzer_mod, ONLY : analyze_output_directory, available_plots_type
    USE mp_world,  ONLY : world_comm
    USE mp,        ONLY : mp_barrier
    !
    IMPLICIT NONE
    CHARACTER(len=*), INTENT(in) :: out_dir
    !
    TYPE(available_plots_type) :: available_plots
    CHARACTER(len=256), DIMENSION(:), ALLOCATABLE :: generated_files
    CHARACTER(len=256) :: parent_dir
    INTEGER :: nplots
    !
    ! Initialize counters
    nplots = 0
    ALLOCATE(generated_files(20))  ! Maximum 20 different plot types
    !
    ! Analyze the output directory
    CALL analyze_output_directory(out_dir, available_plots)
    !
    ! Extract parent directory from the .save path
    CALL get_parent_dir(out_dir, parent_dir)
    !
    ! Synchronize all processors before external calls
    CALL mp_barrier(world_comm)
    !
    ! Only ionode generates files
    IF (ionode) THEN
       WRITE(stdout,'(/,5X,"Creating input files for visualization...")')
       !
       ! 1. Charge density
       IF (available_plots%charge_density) THEN
          CALL generate_and_run_pp(parent_dir, available_plots%prefix, 0, &
                                  'charge_density.xsf', 0, generated_files, nplots)
          !
          ! For spin-polarized calculations, we need to check nspin from the data
          ! For now, we'll generate spin components if the analyzer detected them
          IF (available_plots%spin_density) THEN
             ! Spin up
             CALL generate_and_run_pp(parent_dir, available_plots%prefix, 0, &
                                     'charge_density_up.xsf', 1, generated_files, nplots)
             ! Spin down
             CALL generate_and_run_pp(parent_dir, available_plots%prefix, 0, &
                                     'charge_density_down.xsf', 2, generated_files, nplots)
          END IF
       END IF
       !
       ! 2. Total potential
       IF (available_plots%potential) THEN
          CALL generate_and_run_pp(parent_dir, available_plots%prefix, 1, &
                                  'potential.xsf', 0, generated_files, nplots)
       END IF
       !
       ! 3. ELF (Electron Localization Function)
       IF (available_plots%elf) THEN
          CALL generate_and_run_pp(parent_dir, available_plots%prefix, 8, &
                                  'elf.xsf', 0, generated_files, nplots)
       END IF
       !
       ! 4. Spin density (magnetization)
       IF (available_plots%spin_density) THEN
          CALL generate_and_run_pp(parent_dir, available_plots%prefix, 6, &
                                  'spin_density.xsf', 0, generated_files, nplots)
       END IF
       !
       ! Generate summary report
       CALL print_summary(generated_files, nplots)
       !
       ! Instructions to run
       WRITE(stdout,'(/,5X,"To generate the visualization files, run:")')
       WRITE(stdout,'(5X,"  for file in pp_vis_*.in; do")')
       WRITE(stdout,'(5X,"    pp.x < $file > $file.out")')
       WRITE(stdout,'(5X,"  done")')
       WRITE(stdout,'(/,5X,"Or run them individually as needed.")')
    END IF
    !
    DEALLOCATE(generated_files)
    !
  END SUBROUTINE auto_visualize
  !
  !-----------------------------------------------------------------------
  SUBROUTINE generate_and_run_pp(parent_dir, prefix, plot_num, filplot, &
                                 spin_comp, generated_files, nplots)
    !-----------------------------------------------------------------------
    ! Generate input file for pp.x
    !
    USE io_global, ONLY : stdout
    !
    IMPLICIT NONE
    CHARACTER(len=*), INTENT(in) :: parent_dir, prefix, filplot
    INTEGER, INTENT(in) :: plot_num, spin_comp
    CHARACTER(len=256), DIMENSION(:), INTENT(inout) :: generated_files
    INTEGER, INTENT(inout) :: nplots
    !
    CHARACTER(len=256) :: input_filename
    INTEGER :: iunit, ierr
    !
    ! Create unique input filename
    WRITE(input_filename, '(A,I0,A)') 'pp_vis_', plot_num
    IF (spin_comp > 0) WRITE(input_filename, '(A,A,I0)') TRIM(input_filename), '_spin', spin_comp
    input_filename = TRIM(input_filename) // '.in'
    !
    WRITE(stdout,'(5X,"  Creating input file: ",A)') TRIM(input_filename)
    !
    ! Open temporary input file
    OPEN(newunit=iunit, file=TRIM(input_filename), status='replace', iostat=ierr)
    IF (ierr /= 0) THEN
       WRITE(stdout,'(5X,"Error creating input file: ",A)') TRIM(input_filename)
       RETURN
    END IF
    !
    ! Write namelist &INPUTPP
    WRITE(iunit,'(A)') '&INPUTPP'
    WRITE(iunit,'(A,A,A)') '  prefix = ''', TRIM(prefix), ''''
    WRITE(iunit,'(A,A,A)') '  outdir = ''', TRIM(parent_dir), ''''
    WRITE(iunit,'(A,A,A)') '  filplot = ''', TRIM(filplot), ''''
    WRITE(iunit,'(A,I0)') '  plot_num = ', plot_num
    !
    ! Add spin component if needed
    IF (spin_comp > 0) THEN
       WRITE(iunit,'(A,I0)') '  spin_component = ', spin_comp
    END IF
    !
    WRITE(iunit,'(A)') '/'
    !
    ! Write namelist &PLOT for XSF output
    WRITE(iunit,'(A)') '&PLOT'
    WRITE(iunit,'(A)') '  iflag = 3'
    WRITE(iunit,'(A)') '  output_format = 5'
    WRITE(iunit,'(A,A,A)') '  fileout = ''', TRIM(filplot), ''''
    WRITE(iunit,'(A)') '/'
    !
    CLOSE(iunit)
    !
    ! Add to list of files to be generated
    nplots = nplots + 1
    generated_files(nplots) = filplot
    !
  END SUBROUTINE generate_and_run_pp
  !
  !-----------------------------------------------------------------------
  SUBROUTINE get_parent_dir(save_dir, parent_dir)
    !-----------------------------------------------------------------------
    ! Extract parent directory from .save directory path
    !
    IMPLICIT NONE
    CHARACTER(len=*), INTENT(in) :: save_dir
    CHARACTER(len=*), INTENT(out) :: parent_dir
    !
    INTEGER :: i, last_slash
    !
    ! Find the last '/' in the path
    last_slash = 0
    DO i = LEN_TRIM(save_dir), 1, -1
       IF (save_dir(i:i) == '/') THEN
          last_slash = i
          EXIT
       END IF
    END DO
    !
    IF (last_slash > 0) THEN
       parent_dir = save_dir(1:last_slash-1)
    ELSE
       ! No slash found, assume current directory
       parent_dir = '.'
    END IF
    !
  END SUBROUTINE get_parent_dir
  !
  !-----------------------------------------------------------------------
  SUBROUTINE print_summary(generated_files, nplots)
    !-----------------------------------------------------------------------
    ! Print summary of input files created
    !
    USE io_global, ONLY : stdout, ionode
    !
    IMPLICIT NONE
    CHARACTER(len=256), DIMENSION(:), INTENT(in) :: generated_files
    INTEGER, INTENT(in) :: nplots
    !
    INTEGER :: i
    CHARACTER(len=60) :: description
    !
    IF (ionode) THEN
       WRITE(stdout,'(/,5X,"Input files created for visualization")')
       WRITE(stdout,'(5X,72("-"))')
       WRITE(stdout,'(5X,"Output File",20X,"Description")')
       WRITE(stdout,'(5X,72("-"))')
       !
       DO i = 1, nplots
          ! Determine description based on filename
          IF (INDEX(generated_files(i), 'charge_density_up') > 0) THEN
             description = 'Spin-up charge density'
          ELSE IF (INDEX(generated_files(i), 'charge_density_down') > 0) THEN
             description = 'Spin-down charge density'
          ELSE IF (INDEX(generated_files(i), 'charge_density') > 0) THEN
             description = 'Total charge density'
          ELSE IF (INDEX(generated_files(i), 'potential') > 0) THEN
             description = 'Total potential (V_loc+V_H+V_xc)'
          ELSE IF (INDEX(generated_files(i), 'elf') > 0) THEN
             description = 'Electron Localization Function (ELF)'
          ELSE IF (INDEX(generated_files(i), 'spin_density') > 0) THEN
             description = 'Spin density (magnetization)'
          ELSE
             description = 'Unknown plot type'
          END IF
          !
          WRITE(stdout,'(5X,A30,2X,A)') TRIM(generated_files(i)), TRIM(description)
       END DO
       !
       WRITE(stdout,'(5X,72("-"))')
       WRITE(stdout,'(5X,"Total input files created: ",I3)') nplots
       WRITE(stdout,'(5X,"Output files will be in XSF format for visualization")')
       WRITE(stdout,'()')
    END IF
    !
  END SUBROUTINE print_summary
  !
END PROGRAM pp
