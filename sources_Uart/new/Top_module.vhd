--------------------------------------------------------------------------------
-- Minimal UART Loopback
-- Receives character and sends it back - NO buttons, NO switches!
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_loopback_minimal is
    port (
        clk          : in  std_logic;   -- 100 MHz
        uart_txd_in  : in  std_logic;   -- PC TX -> FPGA RX
        uart_rxd_out : out std_logic    -- FPGA TX -> PC RX
    );
end uart_loopback_minimal;

architecture rtl of uart_loopback_minimal is

    -- RX signals
    signal rx_data  : std_logic_vector(7 downto 0);
    signal rx_valid : std_logic;
    
    -- TX signals
    signal tx_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_valid : std_logic := '0';
    signal tx_ready : std_logic;
    
    -- Simple buffer
    signal data_buf   : std_logic_vector(7 downto 0) := (others => '0');
    signal data_ready : std_logic := '0';

begin

    -----------------------------------------------
    -- UART Receiver
    -----------------------------------------------
    uart_rx_inst : entity work.uart_rx
        generic map (
            CLK_FREQ  => 100_000_000,
            BAUD_RATE => 115200
        )
        port map (
            clk      => clk,
            rst      => '0',
            rx       => uart_txd_in,
            rx_data  => rx_data,
            rx_valid => rx_valid
        );

    -----------------------------------------------
    -- UART Transmitter
    -----------------------------------------------
    uart_tx_inst : entity work.uart_tx
        generic map (
            CLK_FREQ  => 100_000_000,
            BAUD_RATE => 115200
        )
        port map (
            clk      => clk,
            rst      => '0',
            tx_data  => tx_data,
            tx_valid => tx_valid,
            tx_ready => tx_ready,
            tx       => uart_rxd_out
        );

    -----------------------------------------------
    -- Loopback Logic: RX ? Buffer ? TX
    -----------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            tx_valid <= '0';  -- Default
            
            -- Capture received data
            if rx_valid = '1' then
                data_buf   <= rx_data;
                data_ready <= '1';
            end if;
            
            -- Send when TX is ready
            if data_ready = '1' and tx_ready = '1' then
                tx_data    <= data_buf;
                tx_valid   <= '1';
                data_ready <= '0';
            end if;
        end if;
    end process;

end rtl;
