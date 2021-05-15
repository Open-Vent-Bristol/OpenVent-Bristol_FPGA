set name ovb

set_device -name GW1N-9 {GW1N-LV9LQ144C6/I5}


# Add source files
add_file ../../src/Alarm_common.vhd
add_file ../../src/ovb_h.vhd
add_file ../../src/clocks_and_reset.vhd
add_file ../../src/box_ave.vhd
add_file ../../src/sigmadelta_adc.vhd
add_file ../../src/${name}.vhd


# Add constraint files
add_file ../../constraints/physical.cst
add_file ../../constraints/timing.sdc


# Set base name of file
set_option -output_base_name ${name}

# Set the name of the top module
set_option -top_module ${name}

# Set the VHDL standard <vhd1993|vhd2008|vhd2019>
set_option -vhdl_std vhd2008

# Limit the number of reported critical paths
set_option -num_critical_paths 10

# Show all warnings during PNR
set_option -show_all_warn 1

# Enable bitstream compression
set_option -bit_compress 1

# Use MSPI as GPIO (FASTRD_N/D3, MCLK/D4, MCS_N/D5, MI/D7, MO/D6)
set_option -use_mspi_as_gpio 1
set_option -use_sspi_as_gpio 1


# Run synthesis and implementation
run all
