program main
  use doubler, only: double_number
  use printer, only: print_result
  implicit none
  character(len=32) :: arg
  real :: input_number, doubled_number
  integer :: ierr

  ! Get command-line argument
  if (command_argument_count() /= 1) then
    print *, 'Error: Please provide exactly one number as argument'
    stop
  end if

  call get_command_argument(1, arg)
  read(arg, *, iostat=ierr) input_number
  if (ierr /= 0) then
    print *, 'Error: Invalid number provided'
    stop
  end if

  ! Call doubling function
  doubled_number = double_number(input_number)

  ! Call print subroutine
  call print_result(doubled_number)
end program main