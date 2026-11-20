create_clock -period 20.000 -name clk [get_ports clk]
set_power_opt -exclude_cells [get_cells memo/mem_reg]

