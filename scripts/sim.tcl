if {$argc != 1} {
    puts "Error - Incorrect number of arguments - expected 1."
    puts "Usage: tclsh sim.tcl module_name"
    puts "       where module_name is the name of the module for testing"
    exit 1
}

set bindir [file nativename ../bin]
if {![file exists $bindir]} {
    file mkdir $bindir
}
cd $bindir

set module [lindex $::argv 0]

set xelab [file nativename /Xilinx/Vivado/2019.1/bin/xelab]
set xsim [file nativename /Xilinx/Vivado/2019.1/bin/xsim]

set tb [file nativename ../sim/${module}_tb.vhd]
set prj [file nativename ../sim/prj/${module}.prj]

if {![file exists $tb]} {
    puts "Error - Missing testbench file - $tb does not exist"
    exit 1
}

if {![file exists $prj]} {
    puts "Error - Missing project file - $prj does not exist"
    exit 1
}

set tic [clock seconds]
set status [exec $xelab ${module}_tb -prj $prj -debug typical -O2 -incr -s ${module}_sim -nolog >@stdout 2>@stderr]
set toc [clock seconds]
puts $status
puts "\nCompilation and elaboration took [expr {$toc - $tic}] seconds."


if {[file exists ../sim/wave/${module}_sim.wcfg]} {
    exec $xsim -nolog -g ${module}_sim -view ../sim/wave/${module}_sim.wcfg
} else {
    exec $xsim -nolog -g ${module}_sim
}