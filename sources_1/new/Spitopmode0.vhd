--------------------------------------------------------------------------------
-- File: spi_test_minimal.vhd
-- Description: Minimal SPI test - continuous transmission for oscilloscope
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_test_minimal is
    port (
        -- System Clock
        CLK100MHZ : in  std_logic;
        
        -- ChipKit SPI Header ONLY
        ck_miso   : in  std_logic;
        ck_mosi   : out std_logic;
        ck_sck    : out std_logic;
        ck_ss     : out std_logic
    );
end spi_test_minimal;

architecture rtl of spi_test_minimal is

    -- Internal signals
    signal rst        : std_logic := '0';
    signal start      : std_logic := '0';
    signal tx_data    : std_logic_vector(7 downto 0);
    signal rx_data    : std_logic_vector(7 downto 0);
    signal busy       : std_logic;
    signal done       : std_logic;
    
    -- Auto-send timer
    signal delay_cnt  : unsigned(23 downto 0) := (others => '0');
    signal send_pulse : std_logic := '0';
    
    -- Power-on reset
    signal reset_cnt  : unsigned(7 downto 0) := (others => '0');
    signal reset_done : std_logic := '0';

begin

    ----------------------------------------------------------------------------
    -- Power-On Reset (holds reset for 256 clock cycles)
    ----------------------------------------------------------------------------
    process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            if reset_done = '0' then
                reset_cnt <= reset_cnt + 1;
                if reset_cnt = 255 then
                    reset_done <= '1';
                end if;
                rst <= '1';
            else
                rst <= '0';
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Fixed Test Pattern: 0xA5 (10100101) - Easy to verify on scope
    ----------------------------------------------------------------------------
    tx_data <= x"A5";

    ----------------------------------------------------------------------------
    -- Auto-Send Timer: Transmit every ~168ms (~6 Hz)
    -- 100MHz / 2^24 ? 5.96 Hz
    ----------------------------------------------------------------------------
    process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            send_pulse <= '0';
            
            if rst = '1' then
                delay_cnt <= (others => '0');
            else
                delay_cnt <= delay_cnt + 1;
                if delay_cnt = 0 then
                    send_pulse <= '1';
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Start when not busy
    ----------------------------------------------------------------------------
    start <= send_pulse and (not busy);

    ----------------------------------------------------------------------------
    -- SPI Master Instance
    ----------------------------------------------------------------------------
    spi_master_inst : entity work.spi_master
        generic map (
            DATA_WIDTH => 8,
            CLK_DIV    => 100    -- 100MHz / 100 = 1MHz SPI clock
        )
        port map (
            clk     => CLK100MHZ,
            rst     => rst,
            start   => start,
            tx_data => tx_data,
            rx_data => rx_data,
            busy    => busy,
            done    => done,
            sclk    => ck_sck,
            mosi    => ck_mosi,
            miso    => ck_miso,
            cs_n    => ck_ss
        );

end rtl;
