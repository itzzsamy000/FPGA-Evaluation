# Virtual clock: 10 ns period
create_clock -name virtual_clk -period 10.000

# Input timing
set_input_delay -clock virtual_clk -max 1.000 \
    [get_ports {a[*] b[*]}]

set_input_delay -clock virtual_clk -min 0.000 \
    [get_ports {a[*] b[*]}]

# Output timing
set_output_delay -clock virtual_clk -max 1.000 \
    [get_ports {product[*]}]

set_output_delay -clock virtual_clk -min 0.000 \
    [get_ports {product[*]}]