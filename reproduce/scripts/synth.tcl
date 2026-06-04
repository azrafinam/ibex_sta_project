read_liberty -lib /home/stark/.ciel/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

read_verilog ibex_core.v

hierarchy -top ibex_core

proc
opt
fsm
opt
memory
opt

techmap
opt

dfflibmap -liberty /home/stark/.ciel/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

abc -liberty /home/stark/.ciel/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

clean

write_verilog ibex_synth.v
