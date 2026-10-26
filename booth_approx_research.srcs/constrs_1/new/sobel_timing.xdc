create_clock -name virtual_clk -period 10.000

set_input_delay -clock virtual_clk -max 1.000 [get_ports {window_pixels[*]}]
set_input_delay -clock virtual_clk -min 0.000 [get_ports {window_pixels[*]}]

set_output_delay -clock virtual_clk -max 1.000 [get_ports {gx[*] gy[*]}]
set_output_delay -clock virtual_clk -min 0.000 [get_ports {gx[*] gy[*]}]