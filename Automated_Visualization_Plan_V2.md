# Task: Automated Post-Processing Visualization in pp.x (Revised Plan V2)

## 1. Reason for Revision

The initial implementation (V1) attempted to generate all plots by calling the internal `punch_plot` subroutine in a loop within a single run of `pp.x`. This approach proved to be flawed, leading to program hangs.

**The core issue:** The `pp.x` executable and its underlying modules are designed to perform one primary task per execution. They manage a complex internal state, including memory allocation and MPI communicators, which are not properly reset between internal calls. Attempting to loop over plotting routines within a single process leads to deadlocks and unpredictable behavior.

**The new approach is safer and more robust:** This revised plan treats the `pp.x` executable as the black-box command-line tool it is. Instead of manipulating its internal state, we will orchestrate it from a high-level controller. This avoids deadlocks, ensures each visualization is generated in a clean environment, and aligns with the intended use of the program.

## 2. Revised Task Breakdown

### Subtask 2.1: Add Command-Line Flag Parsing to `pp.x`

*   **Status:** No Change in Goal.
*   **Title:** Add `--visualize-all` Flag and Argument Parsing.
*   **Description:** Modify the main program of `pp.x` to handle command-line arguments. This is the entry point for the new automated mode.
*   **Implementation Details:**
    1.  **File to Modify:** `PP/src/postproc.f90`.
    2.  In the `PROGRAM pp` block, use the `get_command_line_argument` intrinsic to check for the presence of a `--visualize-all` flag and the path to the calculation's output directory (e.g., `pp.x --visualize-all -in out/si.save`).
    3.  Introduce a new logical variable, e.g., `visualize_all_mode`, which is set to `.TRUE.` if the flag is detected.
    4.  The existing program logic should be preserved for when the flag is not present.

### Subtask 2.2: Implement Calculation Data Analysis

*   **Status:** No Change in Goal.
*   **Title:** Create Data Analysis Module.
*   **Description:** Develop a new module that can inspect a completed calculation's output directory and determine what data is available for plotting.
*   **Implementation Details:**
    1.  **New Module:** Create a new file, e.g., `PP/src/auto_vis_analyzer.f90`.
    2.  **Core Subroutine:** Implement a subroutine, e.g., `analyze_output_directory(out_dir, available_plots)`, that takes the output directory path as input.
    3.  **XML Parsing:** This subroutine must parse the `data-file-schema.xml` file to identify available data types (charge density, wavefunctions, potentials, etc.).
    4.  **Output:** The subroutine should return a simple data structure containing a list of all possible plots that can be generated.

### Subtask 2.3: Develop Automated Plotting Orchestrator (REVISED)

*   **Status:** **This is the core of the revised plan.**
*   **Title:** Implement the `auto_visualize_orchestrator` Subroutine.
*   **Description:** Create the main driver that orchestrates the automated visualization process by generating input files and calling `pp.x` in separate processes.
*   **Implementation Details:**
    1.  **New Subroutine:** Create a new subroutine `auto_visualize_orchestrator(out_dir, prefix)`.
    2.  **Call Analyzer:** This subroutine will first call `analyze_output_directory` (from Subtask 2.2) to get the list of possible plots.
    3.  **Generate Input Files:** The subroutine will loop through the list of possible plots. For each plot, it will dynamically **write a simple, temporary input file** (e.g., `auto_vis_charge.in`).

        *Example `auto_vis_charge.in`:*
        ```fortran
        &INPUTPP
          prefix = 'Si'  ! Extracted from the out_dir name
          outdir = './Si.save'
          filplot = 'charge_density.xsf'
          plot_num = 0
        /
        &PLOT
        /
        ```
    4.  **Execute `pp.x` in a Loop:** After creating an input file, the orchestrator will immediately call the `pp.x` executable as a **new system process** for that specific file. This is the critical step.
        ```fortran
        ! In the loop, for each plot type:
        CALL generate_input_file_for_charge_density(...)
        CALL execute_command_line('pp.x < auto_vis_charge.in')

        CALL generate_input_file_for_elf(...)
        CALL execute_command_line('pp.x < auto_vis_elf.in')
        ! ...and so on.
        ```
    5.  **Cleanup:** After the loop, the temporary input files should be deleted.

### Subtask 2.4: Create a Summary Report

*   **Status:** No Change in Goal.
*   **Title:** Generate a User-Friendly Summary.
*   **Description:** At the end of the entire process, provide the user with a clear summary of what was generated.
*   **Implementation Details:**
    1.  The `auto_visualize_orchestrator` should keep a list of the `filplot` names it generates.
    2.  After all the external `pp.x` calls are complete, it will print a formatted table to the standard output listing all the successfully created visualization files.

### Subtask 2.5: Write Documentation and Tests

*   **Status:** Minor change to test implementation.
*   **Title:** Document and Test the New Feature.
*   **Description:** Ensure the new feature is well-documented and robustly tested.
*   **Implementation Details:**
    1.  **Documentation:** Update `Doc/INPUT_PP.md` to describe the new `--visualize-all` flag.
    2.  **Testing:** The test will now involve:
        *   Running `pp.x --visualize-all` on a sample output directory.
        *   Verifying that the correct set of temporary `.in` files are created and then deleted.
        *   Verifying that the final set of visualization files (e.g., `charge_density.xsf`, `elf.xsf`) are all present and not empty.
