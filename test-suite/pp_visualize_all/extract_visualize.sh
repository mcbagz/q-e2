#!/bin/bash
# Extract relevant information from pp.x --visualize-all output

fname=$1

# Check if automated visualization was successful
vis_complete=`grep 'Automated Visualization Complete' $fname | awk '{print $1}'`

# Count generated files
nfiles=`grep 'Total files generated:' $fname | awk '{print $4}'`

# Check for specific outputs
charge_density=`grep 'charge_density.xsf' $fname | grep -c 'Generating:'`
potential=`grep 'potential.xsf' $fname | grep -c 'Generating:'`
elf=`grep 'elf.xsf' $fname | grep -c 'Generating:'`

if test "$vis_complete" != ""; then
    echo "visualization_complete"
    echo "1"
fi

if test "$nfiles" != ""; then
    echo "nfiles"
    echo $nfiles
fi

if test "$charge_density" != ""; then
    echo "charge_density_generated"
    echo $charge_density
fi

if test "$potential" != ""; then
    echo "potential_generated"
    echo $potential
fi

if test "$elf" != ""; then
    echo "elf_generated"
    echo $elf
fi