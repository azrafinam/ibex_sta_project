set LIB "/home/stark/.ciel/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ss_100C_1v60.lib"
set NETLIST "../synth/ibex_synth.v"
set SDC "constraints.sdc"
set TOP "ibex_core"

read_liberty $LIB
read_verilog $NETLIST
link_design $TOP
read_sdc $SDC

report_wns
report_tns
report_checks -path_delay max -endpoint_path_count 20 -fields {slew capacitance input_pin net} -format full_clock_expanded
report_checks -path_delay min -endpoint_path_count 10
report_clock_skew -setup
report_check_types -max_slew -max_cap -violators
