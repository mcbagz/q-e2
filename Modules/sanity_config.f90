!
! Copyright (C) 2024 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!----------------------------------------------------------------------------
MODULE sanity_config
  !----------------------------------------------------------------------------
  !! Configuration management for the sanity check system.
  !! Handles reading/writing INI configuration files and storing user preferences.
  !
  USE kinds,     ONLY : DP
  USE io_global, ONLY : stdout, meta_ionode
  USE mp,        ONLY : mp_bcast
  USE mp_world,  ONLY : root, world_comm
  !
  IMPLICIT NONE
  !
  SAVE
  !
  ! ... Sanity check configuration settings
  TYPE sanity_settings
     LOGICAL :: enabled = .TRUE.
     LOGICAL :: prompt_on_warning = .FALSE.
     LOGICAL :: prompt_on_critical = .FALSE.
     LOGICAL :: ignore_all = .FALSE.
     LOGICAL :: checks_only = .FALSE.
     INTEGER :: min_level = 1  ! 1=info, 2=warning, 3=critical
  END TYPE sanity_settings
  !
  TYPE(sanity_settings) :: sanity_opts
  CHARACTER(LEN=256) :: config_file_path = ' '
  CHARACTER(LEN=256) :: default_config_file = '~/.qe/config.ini'
  CHARACTER(LEN=256) :: local_config_file = '.qe_config'
  !
  PRIVATE
  PUBLIC :: sanity_settings, sanity_opts, config_file_path
  PUBLIC :: load_sanity_config, save_sanity_config, parse_sanity_flags
  PUBLIC :: set_config_value, print_config
  !
CONTAINS
  !
  !----------------------------------------------------------------------------
  SUBROUTINE load_sanity_config()
    !----------------------------------------------------------------------------
    !! Load sanity check configuration from INI file.
    !! First tries local .qe_config, then ~/.qe/config.ini, then uses defaults.
    !
    IMPLICIT NONE
    !
    CHARACTER(LEN=256) :: home_dir, global_config
    LOGICAL :: exists, opened
    INTEGER :: ios, unit
    CHARACTER(LEN=256) :: line, key, value
    INTEGER :: eq_pos
    !
    IF ( .NOT. meta_ionode ) THEN
       CALL mp_bcast( sanity_opts%enabled, root, world_comm )
       CALL mp_bcast( sanity_opts%prompt_on_warning, root, world_comm )
       CALL mp_bcast( sanity_opts%prompt_on_critical, root, world_comm )
       CALL mp_bcast( sanity_opts%ignore_all, root, world_comm )
       CALL mp_bcast( sanity_opts%checks_only, root, world_comm )
       CALL mp_bcast( sanity_opts%min_level, root, world_comm )
       RETURN
    END IF
    !
    ! ... Try local config first
    INQUIRE(FILE=TRIM(local_config_file), EXIST=exists)
    IF (exists) THEN
       config_file_path = local_config_file
    ELSE
       ! ... Try global config
       CALL get_environment_variable('HOME', home_dir)
       global_config = TRIM(home_dir) // '/.qe/config.ini'
       INQUIRE(FILE=TRIM(global_config), EXIST=exists)
       IF (exists) THEN
          config_file_path = global_config
       ELSE
          ! ... Create default config if none exists
          config_file_path = global_config
          CALL create_default_config()
       END IF
    END IF
    !
    ! ... Read configuration file
    opened = .FALSE.
    DO unit = 10, 99
       INQUIRE(UNIT=unit, OPENED=opened)
       IF (.NOT. opened) EXIT
    END DO
    !
    OPEN(UNIT=unit, FILE=TRIM(config_file_path), STATUS='OLD', &
         ACTION='READ', IOSTAT=ios)
    IF (ios /= 0) THEN
       WRITE(stdout,'(/,5X,"Warning: Could not open config file: ",A)') &
            TRIM(config_file_path)
       WRITE(stdout,'(5X,"Using default settings")')
       GOTO 100
    END IF
    !
    ! ... Parse INI file
    DO
       READ(unit,'(A256)',IOSTAT=ios) line
       IF (ios /= 0) EXIT
       !
       ! ... Skip comments and empty lines
       line = ADJUSTL(line)
       IF (LEN_TRIM(line) == 0) CYCLE
       IF (line(1:1) == '#' .OR. line(1:1) == ';') CYCLE
       !
       ! ... Skip section headers for now
       IF (line(1:1) == '[') CYCLE
       !
       ! ... Parse key=value pairs
       eq_pos = INDEX(line, '=')
       IF (eq_pos > 0) THEN
          key = ADJUSTL(line(1:eq_pos-1))
          value = ADJUSTL(line(eq_pos+1:))
          !
          ! ... Remove trailing comments
          eq_pos = INDEX(value, '#')
          IF (eq_pos > 0) value = value(1:eq_pos-1)
          eq_pos = INDEX(value, ';')
          IF (eq_pos > 0) value = value(1:eq_pos-1)
          value = ADJUSTL(TRIM(value))
          !
          CALL set_config_value(key, value)
       END IF
    END DO
    !
    CLOSE(unit)
    !
100 CONTINUE
    ! ... Broadcast settings to all processors
    CALL mp_bcast( sanity_opts%enabled, root, world_comm )
    CALL mp_bcast( sanity_opts%prompt_on_warning, root, world_comm )
    CALL mp_bcast( sanity_opts%prompt_on_critical, root, world_comm )
    CALL mp_bcast( sanity_opts%ignore_all, root, world_comm )
    CALL mp_bcast( sanity_opts%checks_only, root, world_comm )
    CALL mp_bcast( sanity_opts%min_level, root, world_comm )
    !
  END SUBROUTINE load_sanity_config
  !
  !----------------------------------------------------------------------------
  SUBROUTINE save_sanity_config()
    !----------------------------------------------------------------------------
    !! Save current sanity check configuration to INI file.
    !
    IMPLICIT NONE
    !
    INTEGER :: unit, ios
    LOGICAL :: opened
    CHARACTER(LEN=10) :: enabled_str, prompt_warn_str, prompt_crit_str
    CHARACTER(LEN=10) :: level_str
    !
    IF ( .NOT. meta_ionode ) RETURN
    !
    ! ... Find available unit
    opened = .FALSE.
    DO unit = 10, 99
       INQUIRE(UNIT=unit, OPENED=opened)
       IF (.NOT. opened) EXIT
    END DO
    !
    ! ... Ensure directory exists
    IF (INDEX(config_file_path, '/.qe/') > 0) THEN
       CALL create_config_directory()
    END IF
    !
    OPEN(UNIT=unit, FILE=TRIM(config_file_path), STATUS='REPLACE', &
         ACTION='WRITE', IOSTAT=ios)
    IF (ios /= 0) THEN
       WRITE(stdout,'(/,5X,"Error: Could not write config file: ",A)') &
            TRIM(config_file_path)
       RETURN
    END IF
    !
    ! ... Convert logical values to strings
    IF (sanity_opts%enabled) THEN
       enabled_str = 'true'
    ELSE
       enabled_str = 'false'
    END IF
    !
    IF (sanity_opts%prompt_on_warning) THEN
       prompt_warn_str = 'true'
    ELSE
       prompt_warn_str = 'false'
    END IF
    !
    IF (sanity_opts%prompt_on_critical) THEN
       prompt_crit_str = 'true'
    ELSE
       prompt_crit_str = 'false'
    END IF
    !
    !
    SELECT CASE (sanity_opts%min_level)
    CASE (1)
       level_str = 'info'
    CASE (2)
       level_str = 'warning'
    CASE (3)
       level_str = 'critical'
    CASE DEFAULT
       level_str = 'warning'
    END SELECT
    !
    ! ... Write INI file
    WRITE(unit,'(A)') '# Quantum ESPRESSO Sanity Check Configuration'
    WRITE(unit,'(A)') '# Generated automatically by QE'
    WRITE(unit,'(A)') ''
    WRITE(unit,'(A)') '[sanity_checks]'
    WRITE(unit,'(A)') 'enabled = ' // TRIM(enabled_str)
    WRITE(unit,'(A)') 'level = ' // TRIM(level_str)
    WRITE(unit,'(A)') 'prompt_on_warning = ' // TRIM(prompt_warn_str)
    WRITE(unit,'(A)') 'prompt_on_critical = ' // TRIM(prompt_crit_str)
    !
    CLOSE(unit)
    !
    WRITE(stdout,'(/,5X,"Configuration saved to: ",A)') TRIM(config_file_path)
    !
  END SUBROUTINE save_sanity_config
  !
  !----------------------------------------------------------------------------
  SUBROUTINE set_config_value(key, value)
    !----------------------------------------------------------------------------
    !! Set a configuration value from a key-value pair.
    !
    IMPLICIT NONE
    !
    CHARACTER(LEN=*), INTENT(IN) :: key, value
    CHARACTER(LEN=256) :: lower_key, lower_value
    !
    ! ... Convert to lowercase for comparison
    lower_key = to_lower(key)
    lower_value = to_lower(value)
    !
    SELECT CASE (TRIM(lower_key))
    CASE ('enabled')
       sanity_opts%enabled = (lower_value == 'true' .OR. lower_value == '1' &
                             .OR. lower_value == 'yes' .OR. lower_value == 'on')
    CASE ('prompt_on_warning')
       sanity_opts%prompt_on_warning = (lower_value == 'true' .OR. lower_value == '1' &
                                       .OR. lower_value == 'yes' .OR. lower_value == 'on')
    CASE ('prompt_on_critical')
       sanity_opts%prompt_on_critical = (lower_value == 'true' .OR. lower_value == '1' &
                                        .OR. lower_value == 'yes' .OR. lower_value == 'on')
    CASE ('auto_continue')
       ! This setting is deprecated - always continue
    CASE ('level')
       SELECT CASE (TRIM(lower_value))
       CASE ('info')
          sanity_opts%min_level = 1
       CASE ('warning')
          sanity_opts%min_level = 2
       CASE ('critical')
          sanity_opts%min_level = 3
       END SELECT
    END SELECT
    !
  END SUBROUTINE set_config_value
  !
  !----------------------------------------------------------------------------
  SUBROUTINE parse_sanity_flags()
    !----------------------------------------------------------------------------
    !! Parse command-line flags related to sanity checks.
    !! This is called after command_line_options has parsed its flags.
    !
    USE command_line_options, ONLY : command_line
    !
    IMPLICIT NONE
    !
    INTEGER :: i, j
    CHARACTER(LEN=256) :: arg, next_arg
    CHARACTER(LEN=512) :: remaining_args
    !
    remaining_args = ' '
    i = 1
    !
    DO WHILE (i <= LEN_TRIM(command_line))
       ! ... Extract next argument
       j = i
       DO WHILE (j <= LEN_TRIM(command_line) .AND. command_line(j:j) /= ' ')
          j = j + 1
       END DO
       arg = command_line(i:j-1)
       !
       ! ... Get next argument if needed
       IF (j < LEN_TRIM(command_line)) THEN
          i = j + 1
          DO WHILE (i <= LEN_TRIM(command_line) .AND. command_line(i:i) == ' ')
             i = i + 1
          END DO
          j = i
          DO WHILE (j <= LEN_TRIM(command_line) .AND. command_line(j:j) /= ' ')
             j = j + 1
          END DO
          next_arg = command_line(i:j-1)
       ELSE
          next_arg = ' '
       END IF
       !
       SELECT CASE (TRIM(arg))
       CASE ('--ignore-sanity-checks', '-ignore-sanity-checks')
          sanity_opts%ignore_all = .TRUE.
          sanity_opts%enabled = .FALSE.
       CASE ('--sanity-checks-only', '-sanity-checks-only')
          sanity_opts%checks_only = .TRUE.
       CASE ('--config', '-config')
          IF (LEN_TRIM(next_arg) > 0) THEN
             CALL parse_config_arg(next_arg)
             i = j  ! Skip the value we just processed
          END IF
       CASE DEFAULT
          ! ... Keep unrecognized arguments
          remaining_args = TRIM(remaining_args) // ' ' // TRIM(arg)
       END SELECT
       !
       i = j + 1
    END DO
    !
    ! ... Update command_line with remaining arguments
    command_line = remaining_args
    !
  END SUBROUTINE parse_sanity_flags
  !
  !----------------------------------------------------------------------------
  SUBROUTINE parse_config_arg(config_str)
    !----------------------------------------------------------------------------
    !! Parse a --config key=value argument.
    !
    IMPLICIT NONE
    !
    CHARACTER(LEN=*), INTENT(IN) :: config_str
    INTEGER :: eq_pos
    CHARACTER(LEN=256) :: key, value
    !
    eq_pos = INDEX(config_str, '=')
    IF (eq_pos > 0) THEN
       key = config_str(1:eq_pos-1)
       value = config_str(eq_pos+1:)
       !
       ! ... Handle sanity_checks. prefix if present
       IF (INDEX(key, 'sanity_checks.') == 1) THEN
          key = key(15:)  ! Remove 'sanity_checks.' prefix
       END IF
       !
       CALL set_config_value(key, value)
       CALL save_sanity_config()
    END IF
    !
  END SUBROUTINE parse_config_arg
  !
  !----------------------------------------------------------------------------
  SUBROUTINE create_default_config()
    !----------------------------------------------------------------------------
    !! Create default configuration file if it doesn't exist.
    !
    IMPLICIT NONE
    !
    ! ... Set default values (already set in type definition)
    ! ... Save to create the file
    CALL save_sanity_config()
    !
  END SUBROUTINE create_default_config
  !
  !----------------------------------------------------------------------------
  SUBROUTINE create_config_directory()
    !----------------------------------------------------------------------------
    !! Create ~/.qe directory if it doesn't exist.
    !
    IMPLICIT NONE
    !
    CHARACTER(LEN=256) :: home_dir, qe_dir, mkdir_cmd
    INTEGER :: ios
    !
    CALL get_environment_variable('HOME', home_dir)
    qe_dir = TRIM(home_dir) // '/.qe'
    !
    ! ... Use system call to create directory
    ! ... This is platform-dependent but works on Unix-like systems
#if defined(_WIN32) || defined(_WIN64)
    mkdir_cmd = 'mkdir "' // TRIM(qe_dir) // '" 2>NUL'
#else
    mkdir_cmd = 'mkdir -p "' // TRIM(qe_dir) // '" 2>/dev/null'
#endif
    !
    CALL EXECUTE_COMMAND_LINE(mkdir_cmd, EXITSTAT=ios)
    !
  END SUBROUTINE create_config_directory
  !
  !----------------------------------------------------------------------------
  FUNCTION to_lower(str) RESULT(lower_str)
    !----------------------------------------------------------------------------
    !! Convert string to lowercase.
    !
    IMPLICIT NONE
    !
    CHARACTER(LEN=*), INTENT(IN) :: str
    CHARACTER(LEN=LEN(str)) :: lower_str
    INTEGER :: i, ic
    !
    DO i = 1, LEN_TRIM(str)
       ic = ICHAR(str(i:i))
       IF (ic >= 65 .AND. ic <= 90) THEN
          lower_str(i:i) = CHAR(ic + 32)
       ELSE
          lower_str(i:i) = str(i:i)
       END IF
    END DO
    !
    DO i = LEN_TRIM(str) + 1, LEN(str)
       lower_str(i:i) = ' '
    END DO
    !
  END FUNCTION to_lower
  !
  !----------------------------------------------------------------------------
  SUBROUTINE print_config()
    !----------------------------------------------------------------------------
    !! Print current configuration settings.
    !
    IMPLICIT NONE
    !
    CHARACTER(LEN=10) :: level_str
    !
    IF ( .NOT. meta_ionode ) RETURN
    !
    SELECT CASE (sanity_opts%min_level)
    CASE (1)
       level_str = 'info'
    CASE (2)
       level_str = 'warning'
    CASE (3)
       level_str = 'critical'
    END SELECT
    !
    WRITE(stdout,'(/,5X,"Sanity Check Configuration:")')
    WRITE(stdout,'(5X,"  Enabled: ",L1)') sanity_opts%enabled
    WRITE(stdout,'(5X,"  Level: ",A)') TRIM(level_str)
    WRITE(stdout,'(5X,"  Prompt on warning: ",L1)') sanity_opts%prompt_on_warning
    WRITE(stdout,'(5X,"  Prompt on critical: ",L1)') sanity_opts%prompt_on_critical
    WRITE(stdout,'(5X,"  Config file: ",A)') TRIM(config_file_path)
    !
  END SUBROUTINE print_config
  !
END MODULE sanity_config