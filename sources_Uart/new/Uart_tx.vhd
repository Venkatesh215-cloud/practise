--------------------------------------------------------------------------------
-- UART Transmitter - Centralized Baud Tick Version
-- Target: Digilent Arty A7-100T
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
    generic (
        CLK_FREQ    : integer := 100_000_000;
        BAUD_RATE   : integer := 115200
    );
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        tx_data     : in  std_logic_vector(7 downto 0);
        tx_valid    : in  std_logic;
        tx_ready    : out std_logic;
        tx          : out std_logic
    );
end uart_tx;

architecture rtl of uart_tx is

    constant CLKS_PER_BIT : integer := CLK_FREQ / BAUD_RATE;
    
    type tx_state_t is (S_IDLE, S_START, S_DATA, S_STOP);
    signal state : tx_state_t := S_IDLE;
    
    signal baud_cnt     : integer range 0 to CLKS_PER_BIT - 1 := 0;
    signal baud_tick    : std_logic := '0';
    signal bit_idx      : integer range 0 to 7 := 0;
    signal tx_shift_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_busy      : std_logic := '0';
    signal tx_reg       : std_logic := '1';

begin

    tx       <= tx_reg;
    tx_ready <= '1' when state = S_IDLE else '0';

    -- Baud Rate Tick Generator
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                baud_cnt  <= 0;
                baud_tick <= '0';
            else
                baud_tick <= '0';
                
                if tx_busy = '1' then
                    if baud_cnt = CLKS_PER_BIT - 1 then
                        baud_cnt  <= 0;
                        baud_tick <= '1';
                    else
                        baud_cnt <= baud_cnt + 1;
                    end if;
                else
                    baud_cnt <= 0;
                end if;
            end if;
        end if;
    end process;

    -- FSM Process
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state        <= S_IDLE;
                tx_reg       <= '1';
                bit_idx      <= 0;
                tx_shift_reg <= (others => '0');
                tx_busy      <= '0';
            else
                case state is
                
                    when S_IDLE =>
                        tx_reg  <= '1';
                        tx_busy <= '0';
                        bit_idx <= 0;
                        
                        if tx_valid = '1' then
                            tx_shift_reg <= tx_data;
                            tx_busy      <= '1';
                            state        <= S_START;
                        end if;
                    
                    when S_START =>
                        tx_reg <= '0';
                        if baud_tick = '1' then
                            state <= S_DATA;
                        end if;
                    
                    when S_DATA =>
                        tx_reg <= tx_shift_reg(bit_idx);
                        if baud_tick = '1' then
                            if bit_idx = 7 then
                                bit_idx <= 0;
                                state   <= S_STOP;
                            else
                                bit_idx <= bit_idx + 1;
                            end if;
                        end if;
                    
                    when S_STOP =>
                        tx_reg <= '1';
                        if baud_tick = '1' then
                            tx_busy <= '0';
                            state   <= S_IDLE;
                        end if;
                    
                    when others =>
                        state <= S_IDLE;
                        
                end case;
            end if;
        end if;
    end process;

end rtl;
