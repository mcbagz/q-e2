module doubler
  implicit none
contains
  function double_number(num) result(doubled)
    real, intent(in) :: num
    real :: doubled
    doubled = 2.0 * num
  end function double_number
end module doubler