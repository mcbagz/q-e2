# Best Practices for Fortran Development

**Note:** The following are general best practices for modern Fortran. When contributing to a large, existing project like this one, the most important principle is to **adhere to the project's established conventions**. The points below are listed in order of importance for this context.

1.  **Adhere to Existing Project Conventions (The Golden Rule)**
    - Before writing any code, investigate the existing conventions and stick to them, even if they differ from your personal preferences or the general advice below.
    - **Code Style**: Examine existing source files (e.g., in `PW/src/`) to understand naming conventions, capitalization of keywords (e.g., `SUBROUTINE` vs. `subroutine`), and indentation style. Consistency is critical for readability in a large codebase.
    - **Project Documentation**: Look for files like `CONTRIBUTING.md`, `README.md`, or documentation in the `Doc/` directory. These often contain explicit guidelines for contributors.

2.  **Write and Run Tests**
    - The project's tests are located in the `test-suite/` directory. They are organized into subdirectories based on functionality (e.g., `pw_scf`, `ph_base`).
    - **Running Tests**: The `test-suite/README` file indicates that tests are run using `make`. Type `make` in the `test-suite` directory for a list of available test targets.
    - **Test Structure**: Tests follow a regression testing model. Each test case consists of an input file (e.g., `scf.in`) and a corresponding benchmark output file (e.g., `benchmark.out.git.inp=scf.in`). The test passes if the output of the program matches the benchmark file.
    - **Writing New Tests**: When adding a new feature or fixing a bug, create a new test directory with a descriptive name. Add a minimal input file that exercises the new code. Run the program and save the output as a benchmark file. This ensures your changes are correct and protects against future regressions.

3.  **Understand the Build System**
    - This project appears to use both `make` and `CMake`. Investigate the `README.md` or `CONTRIBUTING.md` to determine the preferred build system for development.
    - Understanding how to build the code and run tests is a prerequisite for any contribution. The presence of a `configure` script suggests a typical `./configure && make` workflow might be used.

4.  **Managing Dependencies with CMake (The Practical Guide)**
    - `CMake` automatically handles most compilation order issues, but it needs to be told which files and libraries to work with. If you get an error about a module being "called before it is compiled" or an "undefined reference," it's almost always a `CMakeLists.txt` configuration issue.
    - **Case 1: Adding a New Source File to an Existing Component.**
        - **Action:** Find the `CMakeLists.txt` file in the directory of the component you're working on (e.g., `PW/CMakeLists.txt`).
        - **Implementation:** Add the path to your new `.f90` file to the list of source files, which is usually defined in a `set(src_...)` block.
        - **Example:** If you create `my_feature.f90` in `PW/src/`, add `src/my_feature.f90` to the `set(src_pw ...)` list in `PW/CMakeLists.txt`.
        - **Result:** The next time you run `make`, `CMake` will automatically detect the change, update the build rules, and compile your new file and any files that depend on it.
    - **Case 2: Creating a Dependency Between Components.**
        - **Action:** This is necessary when your code in one component (e.g., `PW`) needs to `USE` a module from another component (e.g., `CPV`). This results in a "linker error."
        - **Implementation:** You must explicitly tell `CMake` that the first component now depends on the second. Edit the `CMakeLists.txt` of the *consuming* component (`PW/CMakeLists.txt` in this case).
        - **Example:** Add the name of the *providing* component's library (e.g., `qe_cpv`) to the `target_link_libraries()` block for the consuming target (e.g., `qe_pw`).
        - **Result:** `CMake` will now correctly link the two components together, resolving the "undefined reference" errors.


5.  **Enable `implicit none` Everywhere**
    - Always include `implicit none` in modules, programs, and procedures to prevent undeclared variables and catch typos early.
    - Example:
        ```fortran
        program main
          implicit none
          real :: x = 1.0
          ! No undeclared variables allowed
        end program main
        ```

6.  **Use Modules for Encapsulation and Modularity**
    - Organize code into modules to group related procedures, variables, and types. This improves readability, reusability, and reduces namespace pollution.
    - Use `private` by default and explicitly declare `public` entities to control access.
    - Place module definitions in separate .f90 files and compile them into .mod files for reuse.
    - Example:
        ```fortran
        module my_module
          implicit none
          private
          public :: my_subroutine
        contains
          subroutine my_subroutine(x, y)
            real, intent(inout) :: x, y
            y = x + 1.0
          end subroutine my_subroutine
        end module my_module
        ```

7.  **Write Portable and Standard-Compliant Code**
    - Stick to standard Fortran (avoid compiler-specific extensions unless necessary).
    - **Check Existing Code First**: Before using modern features like `iso_fortran_env` for portable constants (e.g., `real64`), check if the project has its own established way of handling this (e.g., a custom `kinds` module or preprocessor macros). Use the existing pattern to maintain consistency.
    - Example:
        ```fortran
        use iso_fortran_env, only: real64
        real(real64) :: precise_value
        ```

8.  **Leverage Modern Fortran Features**
    - Use `intent(in)`, `intent(out)`, or `intent(inout)` for procedure arguments to clarify data flow and enable compiler checks.
    - Prefer allocatable arrays over fixed-size arrays for flexibility and memory efficiency.
    - Use derived types (`type`) for complex data structures instead of relying on multiple arrays.
    - Example:
        ```fortran
        type :: particle
          real :: x, y, velocity
        end type particle
        ```

9.  **Enable Compiler Warnings and Checks**
    - Compile with strict flags to catch errors early (e.g., `-Wall -Wextra` for gfortran; `-warn all` for Intel Fortran).
    - Use bounds checking (`-fcheck=bounds` in gfortran) during development to catch array access errors.
    - Example:
        ```bash
        gfortran -Wall -Wextra -fcheck=all -o my_program main.f90
        ```

10.  **Optimize Later, Not Prematurely**
    - Focus on correctness and clarity first. Profile the code (using tools like `gprof` or Intel VTune) before optimizing bottlenecks.
    - **Context is Key**: In a high-performance computing project, performance is critical. Be mindful of the performance implications of your changes, but always follow the project's existing patterns for optimization and verify improvements with profiling. Avoid outdated tricks (e.g., excessive `common` blocks) that harm readability.

11. **Use Version Control**
    - Use Git or another version control system to track changes, especially in a large codebase.
    - Commit small, logical changes with clear messages (e.g., “Refactor matrix solver in solver.f90 for better readability”).
    - Branch for experimental changes to avoid breaking the main codebase.

12. **Document and Maintain Interfaces**
    - Define explicit interfaces for procedures using `interface` blocks or by placing procedures in modules (automatic in Fortran 90+ for module procedures).
    - Keep interfaces consistent to avoid breaking dependent code.

13. **Use Descriptive Naming and Consistent Style**
    - Choose clear, meaningful names for variables, procedures, and modules (e.g., `calculate_velocity` instead of `calc`).
    - Follow a consistent naming convention (e.g., `snake_case` or `camelCase`) and stick to it across the codebase.
    - Comment generously, especially for complex logic, but avoid redundant comments (e.g., don’t comment `x = x + 1` as “increments x”).

14. **Automate Builds with Tools**
    - Use build tools like make, CMake, or Meson to manage dependencies and compilation.
    - For .f90 files, ensure the build system handles module dependencies (.mod files) automatically, as Fortran modules must be compiled before files that use them.
    - Example Makefile snippet:
        ```makefile
        FC = gfortran
        FFLAGS = -Wall -Wextra -O2
        main: main.o my_module.o
            $(FC) -o main main.o my_module.o
        main.o: main.f90 my_module.mod
            $(FC) $(FFLAGS) -c main.f90
        my_module.mod: my_module.f90
            $(FC) $(FFLAGS) -c my_module.f90
        ```