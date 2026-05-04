--------------------------------------------------------------------------------
-- UART Receiver - Minimal Version
-- 115200 baud, 8N1
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_rx is
    generic (
        CLK_FREQ    : integer := 100_000_000;
        BAUD_RATE   : integer := 115200
    );
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        rx          : in  std_logic;
        rx_data     : out std_logic_vector(7 downto 0);
        rx_valid    : out std_logic
    );
end uart_rx;

architecture rtl of uart_rx is

    constant CLKS_PER_BIT : integer := CLK_FREQ / BAUD_RATE;
    
    type rx_state_t is (S_IDLE, S_START, S_DATA, S_STOP);
    signal state : rx_state_t := S_IDLE;
    
    signal baud_cnt     : integer range 0 to CLKS_PER_BIT - 1 := 0;
    signal baud_tick    : std_logic := '0';
    signal bit_idx      : integer range 0 to 7 := 0;
    signal rx_shift_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_busy      : std_logic := '0';
    signal half_bit     : std_logic := '0';  -- For start bit (half period)
    
    -- Input synchronizer (2-stage for metastability)
    signal rx_sync : std_logic_vector(1 downto 0) := "11";
    signal rx_in   : std_logic := '1';

begin

    -----------------------------------------------
    -- Input Synchronizer
    -----------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            rx_sync <= rx_sync(0) & rx;
            rx_in   <= rx_sync(1);
        end if;
    end process;

    -----------------------------------------------
    -- Baud Tick Generator
    -----------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                baud_cnt  <= 0;
                baud_tick <= '0';
            else
                baud_tick <= '0';
                
                if rx_busy = '1' then
                    -- Half bit for start, full bit for others
                    if half_bit = '1' then
                        if baud_cnt = (CLKS_PER_BIT - 1) / 2 then
                            baud_cnt  <= 0;
                            baud_tick <= '1';
                        else
                            baud_cnt <= baud_cnt + 1;
                        end if;
                    else
                        if baud_cnt = CLKS_PER_BIT - 1 then
                            baud_cnt  <= 0;
                            baud_tick <= '1';
                        else
                            baud_cnt <= baud_cnt + 1;
                        end if;
                    end if;
                else
                    baud_cnt <= 0;
                end if;
            end if;
        end if;
    end process;

    -----------------------------------------------
    -- RX FSM
    -----------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state        <= S_IDLE;
                bit_idx      <= 0;
                rx_shift_reg <= (others => '0');
                rx_data      <= (others => '0');
                rx_valid     <= '0';
                rx_busy      <= '0';
                half_bit     <= '0';
            else
                rx_valid <= '0';  -- Default: pulse
                
                case state is
                
                    when S_IDLE =>
                        rx_busy  <= '0';
                        bit_idx  <= 0;
                        half_bit <= '0';
                        
                        -- Detect start bit (falling edge)
                        if rx_in = '0' then
                            rx_busy  <= '1';
                            half_bit <= '1';  -- First wait is half bit
                            state    <= S_START;
                        end if;
                    
                    when S_START =>
                        if baud_tick = '1' then
                            half_bit <= '0';  -- Switch to full bit timing
                            if rx_in = '0' then
                                -- Valid start bit
                                state <= S_DATA;
                            else
                                -- False start (noise)
                                state <= S_IDLE;
                            end if;
                        end if;
                    
                    when S_DATA =>
                        if baud_tick = '1' then
                            rx_shift_reg(bit_idx) <= rx_in;
                            
                            if bit_idx = 7 then
                                bit_idx <= 0;
                                state   <= S_STOP;
                            else
                                bit_idx <= bit_idx + 1;
                            end if;
                        end if;
                    
                    when S_STOP =>
                        if baud_tick = '1' then
                            if rx_in = '1' then
                                -- Valid stop bit
                                rx_data  <= rx_shift_reg;
                                rx_valid <= '1';
                            end if;
                            state <= S_IDLE;
                        end if;
                    
                    when others =>
                        state <= S_IDLE;
                        
                end case;
            end if;
        end if;
    end process;

end rtl;
