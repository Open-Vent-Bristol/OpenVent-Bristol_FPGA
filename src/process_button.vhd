library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- ce should be 50ms
entity process_button is
    port (
        clk         : in    std_logic;
        rst         : in    std_logic;
        ce          : in    std_logic;
        button      : in    std_logic;
        short_press : out   std_logic;
        long_press  : out   std_logic
    );
end entity;


architecture rtl of process_button is

    type button_st_t is (WAIT_PRESS_ST, WAIT_RELEASE_ST);
    signal button_st                : button_st_t;

    constant LONG_PRESS_CYCLES      : integer := 80;    -- 4 seconds at 50ms
    signal press_count              : unsigned range 0 to LONG_PRESS_CYCLES-1;

begin
    -- short press detected < long_press length
    -- long press detected >= long_press length

    p_rst: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                button_st <= WAIT_PRESS_ST;
                press_count <= (others=>'0');
                short_press <= '0';
                long_press <= '0';
            elsif ce = '1' then
                case button_st is
                    when WAIT_PRESS_ST =>
                        if button = '1' then
                            button_st <= WAIT_RELEASE_ST;
                        end if;
                    when WAIT_RELEASE_ST =>
                        if button = '0' then
                            button_st <= WAIT_PRESS_ST;
                        end if;
                    when OTHERS =>
                        button_st <= WAIT_PRESS_ST;
                end case;

                if (button_st = WAIT_PRESS_ST) or (button_st = WAIT_RELEASE_ST and button = '0') then
                    press_count <= (others=>'0');
                elsif button_st = WAIT_RELEASE_ST then
                    if press_count < LONG_PRESS_CYCLES-1 then
                        press_count <= press_count + 1;
                    end if;
                end if;

                if button_st = WAIT_RELEASE_ST and button = '0' and press_count < LONG_PRESS_CYCLES-1 then
                    short_press <= '1';
                end if;

                if button_st = WAIT_RELEASE_ST and press_count = LONG_PRESS_CYCLES-1 then
                    long_press <= '1';
                end if;

            end if;
        end if;
    end process;

end architecture;
