library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.stdlib_h.all;
use work.ovb_h.all;


-- The display_refresh module refreshes both 16x2 displays. 
-- 0x00
-- 0x40
entity display_refresh is
    port (
        clk     : in    std_logic;
        arstn   : in    std_logic;
        refresh : in    std_logic;
        done    : in    std_logic;
        we      : out   std_logic;
        addr    : out   std_logic_vector(4 downto 0)
    );
end entity;


architecture rtl of display_refresh is

    type display_st_t is (IDLE_ST, ADDR_ST, DDRAM_ST);
    signal display_st   : display_st_t;

    signal addr_count   : unsigned(1 downto 0);
    signal ddram_count  : unsigned(3 downto 0);
    signal rd           : std_logic;

begin

    addr <= "1" & std_logic_vector(ddram_count) when display_st = DDRAM_ST else
        "000" & std_logic_vector(addr_count);

    p_rst: process(clk, arstn) is
    begin
        if arstn = '0' then
            display_st <= IDLE_ST;
            addr_count <= (others=>'0');
            ddram_count <= (others=>'0');
            rd <= '0';
            we <= '0';

        elsif rising_edge(clk) then
            
            case display_st is
                when IDLE_ST =>
                    if refresh = '1' then
                        display_st <= ADDR_ST;
                    end if;
                when ADDR_ST =>
                    if done = '1' then
                        display_st <= DDRAM_ST;
                    end if;
                when DDRAM_ST =>
                    if done = '1' and ddram_count = 15 then
                        if addr_count = 3 then
                            display_st <= IDLE_ST;
                        else
                            display_st <= ADDR_ST;
                        end if;
                    end if;
                when OTHERS =>
                    display_st <= ADDR_ST;
            end case;

            -- TODO: Fix this condition
            if (display_st = IDLE_ST and refresh = '1') or 
                (done = '1' and not(addr_count = 3 and ddram_count = 15)) then
                rd <= '1';
            else
                rd <= '0';
            end if;

            we <= rd;

            if display_st = IDLE_ST then
                addr_count <= (others=>'0');
            elsif display_st = DDRAM_ST and ddram_count = 15 and done = '1' then
                addr_count <= addr_count + 1;
            end if;

            if display_st = IDLE_ST then
                ddram_count <= (others=>'0');
            elsif display_st = DDRAM_ST and done = '1' then
                ddram_count <= ddram_count + 1;
            end if;

        end if;
    end process;

end architecture;