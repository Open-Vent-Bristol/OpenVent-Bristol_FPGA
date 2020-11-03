library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.stdlib_h.all;
use work.ovb_h.all;
use work.tb_h.all;


entity display_phy_tb is
    generic(
        SEED1   : positive := 1000000;
        SEED2   : positive := 2000000
    );
end entity;


architecture tb of display_phy_tb is

    constant Tpd        : time := 20 ns;

    signal clk          : std_logic;
    signal rst          : std_logic;
    signal start        : std_logic;
    signal rnw          : std_logic;
    signal rs           : std_logic;
    signal csn          : std_logic_vector(1 downto 0);
    signal din          : std_logic_vector(7 downto 0);
    signal dout         : std_logic_vector(7 downto 0);
    signal display      : display_out_t;
    signal done         : std_logic;

    signal errors       : integer := 0;

begin

    g_clk   : generateClock(clk, Tpd);

    p_main : process is

        variable theSeed1   : positive := SEED1;
        variable theSeed2   : positive := SEED2;

        procedure Reset is
        begin
            rst <= '1';
            din <= (others=>'0');
            start <= '0';
            rnw <= '0';
            rs <= '0';
            csn <= (others=>'1');
            wait for 10 * Tpd;
            wait until clk = '1';
            rst <= '0';
            wait for 10 * Tpd;
        end procedure;

        procedure RandWrite(csn_i: std_logic_vector(1 downto 0)) is
            variable rdata   : std_logic_vector(7 downto 0);
        begin
            rand(rdata, theSeed1, theSeed2);
            wait until clk = '1';
            start <= '1';
            din <= rdata;
            csn <= csn_i;
            rnw <= '0';
            rs <= '1';
            wait until clk = '1';
            start <= '0';
        end procedure;

    begin

        Reset;
        RandWrite("11");
        wait for 10 * Tpd;
        wait until done = '1';
        wait for 10 * Tpd;
        EndSimulation(errors);

    end process;


    i_dut: entity work.display_phy 
        port map (
            clk         => clk,
            rst         => rst,
            start       => start,
            rnw         => rnw,
            rs          => rs,
            csn         => csn,
            din         => din,
            dout        => dout,
            display     => display,
            done        => done
        );

end architecture;