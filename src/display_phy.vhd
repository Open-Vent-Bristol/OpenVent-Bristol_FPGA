library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.stdlib_h.all;
use work.ovb_h.all;


entity display_phy is
    port(
        clk         : in    std_logic;
        rst         : in    std_logic;
        start       : in    std_logic;
        rnw         : in    std_logic;
        rs          : in    std_logic;
        csn         : in    std_logic_vector(1 downto 0);
        din         : in    std_logic_vector(7 downto 0);
        dout        : out   std_logic_vector(7 downto 0);
        display     : out   display_out_t;
        done        : out   std_logic
    );
end entity;


architecture rtl of display_phy is

    type phy_st_t is (IDLE_ST, E_HIGH_ST, E_LOW_ST);
    signal phy_st       : phy_st_t;

    signal e            : std_logic;
    signal phy_count    : unsigned(clog2(DISPLAY_ENABLE_CYCLES)-1 downto 0);

begin

    display.e(0) <= e when csn(0) = '0' else '0';
    display.e(1) <= e when csn(1) = '0' else '0';
    display.t <= (others=>'1') when rnw = '1' else (others=>'0');
    display.rnw <= rnw;
    display.rs <= rs;
    display.db <= din;

    p_rst: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                phy_st <= IDLE_ST;
                e <= '0';
                phy_count <= (others=>'0');
                dout <= (others=>'0');
                done <= '0';
            else
                case phy_st is
                    when IDLE_ST =>
                        if start = '1' then
                            phy_st <= E_HIGH_ST;
                        end if;
                    when E_HIGH_ST =>
                        if phy_count = DISPLAY_ENABLE_CYCLES then
                            phy_st <= E_LOW_ST;
                        end if;
                    when E_LOW_ST =>
                        if phy_count = DISPLAY_ENABLE_CYCLES then
                            phy_st <= IDLE_ST;
                        end if;
                    when OTHERS =>
                        phy_st <= IDLE_ST;
                end case;

                if phy_st = E_HIGH_ST then
                    e <= '1';
                else
                    e <= '0';
                end if;

                if phy_st = E_HIGH_ST or phy_st = E_LOW_ST then
                    phy_count <= phy_count + 1;
                    if phy_count = DISPLAY_ENABLE_CYCLES then
                        phy_count <= (others=>'0');
                    end if;
                else
                    phy_count <= (others=>'0');
                end if;

                if phy_st = E_LOW_ST and phy_count = 0 then
                    dout <= din;
                end if;

                if phy_st = E_LOW_ST and phy_count = DISPLAY_ENABLE_CYCLES then
                    done <= '1';
                else
                    done <= '0';
                end if;

            end if;
        end if;
    end process;

end architecture;