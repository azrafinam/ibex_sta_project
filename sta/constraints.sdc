current_design ibex_core
create_clock -name clk_i -period 20 [get_ports clk_i]
set_clock_uncertainty 0.25 [get_clocks clk_i]
set_input_delay 0 -clock clk_i [get_ports -filter "direction == input && name != clk_i"]
set_output_delay 0 -clock clk_i [all_outputs]
set_load 0.0334 [all_outputs]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_1 -pin Y [get_ports -filter "direction == input && name != clk_i"]
