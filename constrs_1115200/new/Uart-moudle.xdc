## Clock signal
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk]
#create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk100 }];
#set_property -dict {PACKAGE_PIN D9 IOSTANDARD LVCMOS33} [get_ports rst]

#set_property -dict {PACKAGE_PIN  D10 IOSTANDARD LVCMOS33} [get_ports {tx}];
##set_property -dict {package_PIN A9 IOSTANDARD LVCMOS33} [get_ports {rx}];

set_property -dict { PACKAGE_PIN D10   IOSTANDARD LVCMOS33 } [get_ports {uart_rxd_out}]; #IO_L4P_T0_15 Sch=ja[2]
set_property -dict { PACKAGE_PIN A9   IOSTANDARD LVCMOS33 } [get_ports { uart_txd_in}]; #IO_L4N_T0_15 Sch=ja[3]
