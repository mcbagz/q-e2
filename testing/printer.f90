module printer
  implicit none
contains
  subroutine print_result(num)
    real, intent(in) :: num
    print *, 'The doubled number is: ', num
  end subroutine print_result
end module printer