library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.stdlib_h.all;
use work.ovb_h.all;
use work.tb_h.all;


entity display_refresh_tb is
    generic(
        SEED1   : positive := 1000000;
        SEED2   : positive := 2000000
    );
end entity;


architecture tb of display_refresh_tb is

    constant Tpd        : time := 20 ns;

    signal clk          : std_logic;
    signal arstn        : std_logic;
    signal refresh      : std_logic;
    signal done         : std_logic;
    signal we           : std_logic;
    signal addr         : std_logic_vector(4 downto 0);

    signal errors       : integer := 0;
    
begin


    g_clk   : generateClock(clk, Tpd);

    p_main : process is

        variable theSeed1   : positive := SEED1;
        variable theSeed2   : positive := SEED2;

        procedure Reset is
        begin
            arstn <= '0';
            refresh <= '0';
            done <= '0';
            wait for 10 * Tpd;
            wait until clk = '1';
            arstn <= '1';
            wait for 10 * Tpd;
        end procedure;

        procedure LcdRefresh is
        begin
            wait until clk = '1';
            refresh <= '1';
            wait until clk = '1';
            refresh <= '0';  
            -- 4 lines with one start address, 16 DDRAM  
            for i in 1 to 4*(1+16) loop
                wait for 10 * Tpd;
                wait until clk = '1';
                done <= '1';
                wait until clk = '1';
                done <= '0';
            end loop;
        end procedure;

    begin

        Reset;
        LcdRefresh;
        wait for 100 * Tpd;
        EndSimulation(errors);

    end process;


    i_dut: entity work.display_refresh
        port map (
            clk     => clk,
            arstn   => arstn,
            refresh => refresh,
            done    => done,
            we      => we,
            addr    => addr
        );

end architecture;