#===============================================================================
# Clock
#===============================================================================
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports { CLK100MHZ }]
create_clock -period 10.000 -name sys_clk [get_ports CLK100MHZ]

#===============================================================================
# ChipKit SPI Header
#===============================================================================
set_property -dict { PACKAGE_PIN G1 IOSTANDARD LVCMOS33 } [get_ports { ck_miso }]
set_property -dict { PACKAGE_PIN H1 IOSTANDARD LVCMOS33 } [get_ports { ck_mosi }]
set_property -dict { PACKAGE_PIN F1 IOSTANDARD LVCMOS33 } [get_ports { ck_sck }]
set_property -dict { PACKAGE_PIN C1 IOSTANDARD LVCMOS33 } [get_ports { ck_ss }]
