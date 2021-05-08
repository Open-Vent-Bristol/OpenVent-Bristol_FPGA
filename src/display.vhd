library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ovb_h.all;


entity display is
    port (
        clk             : in    std_logic;
        display_din     : in    std_logic_vector(7 downto 0);
        display_out     : out   display_out_t;
        addra           : in    std_logic_vector(9 downto 0);
        wea             : in    std_logic;
        dina            : in    std_logic_vector(17 downto 0)
    );
end entity;


architecture rtl of display is

    type display_st_t is (IDLE_ST, WAIT_RST_ST, FUNCTION_SET_ST, DISPLAY_ON_ST, DISPLAY_CLEAR_ST, ENTRY_MODE_ST, NORMAL_ST);
    signal display_st       : display_st_t;



begin


    p_rst: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                display_st <= IDLE_ST;
            else
                case display_st is
                    when IDLE_ST =>
                        display_st <= WAIT_RST_ST;
                    when WAIT_RST_ST =>
                        if count = DISPLAY_WAIT_STARTUP_CYCLES-1 then
                            display_st <= FUNCTION_SET_ST;
                        end if;
                    when FUNCTION_SET_ST =>
                        if count = DISPLAY_FUNCTION_SET_CYCLES-1 then
                            display_st <= DISPLAY_ON_ST;
                        end if;
                    when DISPLAY_ON_ST =>
                        if count = DISPLAY_DISPLAY_ON_CONTROL_CYCLES-1 then
                            display_st <= DISPLAY_CLEAR_ST;
                        end if;
                    when DISPLAY_CLEAR_ST =>
                        if count = DISPLAY_CLEAR_DISPLAY_CYCLES-1 then
                            display_st <= ENTRY_MODE_ST;
                        end if;
                    when ENTRY_MODE_ST =>
                        if count = DISPLAY_ENTRY_MODE_SET_CYCLES-1 then
                            display_st <= NORMAL_ST;
                        end if;
                    when NORMAL_ST =>

                    when OTHERS =>
                        display_st <= IDLE_ST;
                end case;
            end if;
        end if;
    end process;


end architecture;
