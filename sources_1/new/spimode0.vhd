--------------------------------------------------------------------------------
-- File: spi_master.vhd
-- Description: Simple SPI Master (Mode 0: CPOL=0, CPHA=0)
-- Author: For Learning Purpose
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_master is
    generic (
        DATA_WIDTH : integer := 8;      -- Number of bits per transfer
        CLK_DIV    : integer := 4       -- Clock divider (SPI_CLK = CLK/CLK_DIV)
    );
    port (
        -- System signals
        clk      : in  std_logic;       -- System clock
        rst      : in  std_logic;       -- Active high reset
        
        -- Control interface
        start    : in  std_logic;       -- Start transmission
        tx_data  : in  std_logic_vector(DATA_WIDTH-1 downto 0);  -- Data to send
        rx_data  : out std_logic_vector(DATA_WIDTH-1 downto 0);  -- Data received
        busy     : out std_logic;       -- Transfer in progress
        done     : out std_logic;       -- Transfer complete pulse
        
        -- SPI interface
        sclk     : out std_logic;       -- SPI clock
        mosi     : out std_logic;       -- Master Out Slave In
        miso     : in  std_logic;       -- Master In Slave Out
        cs_n     : out std_logic        -- Chip select (active low)
    );
end spi_master;

architecture rtl of spi_master is

    -- State machine states
    type state_type is (IDLE, TRANSFER, COMPLETE);
    signal state : state_type := IDLE;
    
    -- Internal registers
    signal shift_reg_tx : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal shift_reg_rx : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal bit_counter  : integer range 0 to DATA_WIDTH := 0;
    signal clk_counter  : integer range 0 to CLK_DIV-1 := 0;
    signal sclk_int     : std_logic := '0';
    signal sclk_rising  : std_logic := '0';
    signal sclk_falling : std_logic := '0';

begin

    ----------------------------------------------------------------------------
    -- Clock Divider Process: Generates SPI clock from system clock
    ----------------------------------------------------------------------------
    clk_divider_proc: process(clk, rst)
    begin
        if rst = '1' then
            clk_counter  <= 0;
            sclk_int     <= '0';
            sclk_rising  <= '0';
            sclk_falling <= '0';
        elsif rising_edge(clk) then
            sclk_rising  <= '0';
            sclk_falling <= '0';
            
            if state = TRANSFER then
                if clk_counter = CLK_DIV/2 - 1 then
                    clk_counter <= clk_counter + 1;
                    sclk_int    <= '1';
                    sclk_rising <= '1';      -- Rising edge indicator
                elsif clk_counter = CLK_DIV - 1 then
                    clk_counter  <= 0;
                    sclk_int     <= '0';
                    sclk_falling <= '1';     -- Falling edge indicator
                else
                    clk_counter <= clk_counter + 1;
                end if;
            else
                clk_counter <= 0;
                sclk_int    <= '0';
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Main State Machine: Controls SPI transfer
    ----------------------------------------------------------------------------
    main_proc: process(clk, rst)
    begin
        if rst = '1' then
            state        <= IDLE;
            shift_reg_tx <= (others => '0');
            shift_reg_rx <= (others => '0');
            bit_counter  <= 0;
            rx_data      <= (others => '0');
            busy         <= '0';
            done         <= '0';
            cs_n         <= '1';            -- Deselect slave
            
        elsif rising_edge(clk) then
            done <= '0';                    -- Default: clear done pulse
            
            case state is
                ----------------------------------------------------------------
                -- IDLE: Wait for start signal
                ----------------------------------------------------------------
                when IDLE =>
                    cs_n <= '1';            -- Slave not selected
                    busy <= '0';
                    
                    if start = '1' then
                        state        <= TRANSFER;
                        shift_reg_tx <= tx_data;    -- Load TX data
                        shift_reg_rx <= (others => '0');
                        bit_counter  <= 0;
                        cs_n         <= '0';        -- Select slave
                        busy         <= '1';
                    end if;
                
                ----------------------------------------------------------------
                -- TRANSFER: Shift out TX data, shift in RX data
                ----------------------------------------------------------------
                when TRANSFER =>
                    -- Sample MISO on rising edge of SCLK
                    if sclk_rising = '1' then
                        shift_reg_rx <= shift_reg_rx(DATA_WIDTH-2 downto 0) & miso;
                    end if;
                    
                    -- Shift TX data on falling edge of SCLK
                    if sclk_falling = '1' then
                        bit_counter <= bit_counter + 1;
                        
                        if bit_counter = DATA_WIDTH - 1 then
                            state <= COMPLETE;
                        else
                            shift_reg_tx <= shift_reg_tx(DATA_WIDTH-2 downto 0) & '0';
                        end if;
                    end if;
                
                ----------------------------------------------------------------
                -- COMPLETE: Transfer finished
                ----------------------------------------------------------------
                when COMPLETE =>
                    cs_n    <= '1';                 -- Deselect slave
                    rx_data <= shift_reg_rx;        -- Output received data
                    done    <= '1';                 -- Signal completion
                    busy    <= '0';
                    state   <= IDLE;
                
                when others =>
                    state <= IDLE;
                    
            end case;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Output Assignments
    ----------------------------------------------------------------------------
    sclk <= sclk_int;
    mosi <= shift_reg_tx(DATA_WIDTH-1);     -- MSB first

end rtl;
-----------------