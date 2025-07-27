#!/bin/bash
#
# Test script for pp.x --visualize-all feature
#

# Set up environment
NAME=$(basename ${PWD})
ESPRESSO_ROOT=$(cd ../../; pwd)
ESPRESSO_TMPDIR=${ESPRESSO_TMPDIR:="${PWD}/out"}
PSEUDO_DIR=${ESPRESSO_PSEUDO:="${ESPRESSO_ROOT}/pseudo"}

# Executables
PW_COMMAND="${ESPRESSO_ROOT}/bin/pw.x"
PP_COMMAND="${ESPRESSO_ROOT}/bin/pp.x"

# Check if executables exist
if [ ! -x "$PW_COMMAND" ]; then
    echo "Error: pw.x not found or not executable"
    exit 1
fi

if [ ! -x "$PP_COMMAND" ]; then
    echo "Error: pp.x not found or not executable"
    exit 1
fi

# Clean up previous runs
rm -rf ${ESPRESSO_TMPDIR}
mkdir -p ${ESPRESSO_TMPDIR}

echo "Running test: $NAME"
echo "=================="

# Step 1: Run SCF calculation
echo "Step 1: Running SCF calculation..."
$PW_COMMAND < si.scf.in > si.scf.out 2>&1

if [ $? -ne 0 ]; then
    echo "Error: SCF calculation failed"
    exit 1
fi

# Check if output directory was created
if [ ! -d "${ESPRESSO_TMPDIR}/si.save" ]; then
    echo "Error: Output directory si.save not created"
    exit 1
fi

# Step 2: Run pp.x with --visualize-all flag
echo "Step 2: Running pp.x --visualize-all..."
$PP_COMMAND --visualize-all -in ${ESPRESSO_TMPDIR}/si.save > si.pp_visualize.out 2>&1

if [ $? -ne 0 ]; then
    echo "Error: pp.x --visualize-all failed"
    exit 1
fi

# Step 3: Check if expected output files were created
echo "Step 3: Checking output files..."
expected_files="charge_density.xsf potential.xsf elf.xsf"
missing_files=""

for file in $expected_files; do
    if [ ! -f "$file" ]; then
        missing_files="$missing_files $file"
    fi
done

if [ -n "$missing_files" ]; then
    echo "Error: Expected output files not found:$missing_files"
    exit 1
fi

# Step 4: Check output content
echo "Step 4: Checking output content..."
if ! grep -q "Automated Visualization Complete" si.pp_visualize.out; then
    echo "Error: Summary report not found in output"
    exit 1
fi

echo ""
echo "Test completed successfully!"
echo "Generated files:"
ls -la *.xsf

exit 0