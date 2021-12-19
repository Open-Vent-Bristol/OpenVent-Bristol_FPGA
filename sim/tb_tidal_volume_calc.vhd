----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.08.2021 19:25:53
-- Design Name: 
-- Module Name: tb_tidal_volume_calc - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;

entity tb_tidal_volume_calc is
end tb_tidal_volume_calc;

architecture Behavioral of tb_tidal_volume_calc is

    component tidal_volume_calc is
    port
    (
        clk_i           : in std_ulogic;                                    -- System Clock IN
        rst_a_n_i       : in std_ulogic;                                    -- Asynchronous Reset IN
        soft_rst_n_i    : in std_ulogic;                                    -- Synchronous Reset IN (here if you need/want it)
    
        flow_rate_i     : in std_ulogic_vector(11 downto 0);
    
        data_o          : out std_ulogic_vector(11 downto 0);
        data_valid_o    : out std_ulogic
    );
    end component;

    signal sig_clk_i        : std_ulogic := '0';
    signal sig_rst_a_n_i    : std_ulogic := '0';
    signal sig_soft_rst_n_i : std_ulogic := '0';

    signal sig_flow_rate_i  : std_ulogic_vector(11 downto 0) := (others => '0');

    signal sig_data_o       : std_ulogic_vector(11 downto 0) := (others => '0');
    signal sig_data_valid_o : std_ulogic := '0';
    
    constant clk_period : time := 20ns;         -- Roughly 25MHz clock (33.3MHz is awkward af for timing)
    signal done : boolean := false;

begin

    TIDAL_VOLUME : tidal_volume_calc
    port map
    (
        clk_i        => sig_clk_i,
        rst_a_n_i    => sig_rst_a_n_i,
        soft_rst_n_i => sig_soft_rst_n_i,

        flow_rate_i  => sig_flow_rate_i,

        data_o       => sig_data_o,
        data_valid_o => sig_data_valid_o
    );
    
    clock: process     -- Clock Generation
    begin
        if (done /= true) then
            sig_clk_i <= not sig_clk_i;
            wait for clk_period;
        else
           sig_clk_i <= '1';
        end if;
    end process clock;

tb: process        -- Testbench Stimulus

    begin
        while(done /= true) loop
            sig_rst_a_n_i <= '0';
            sig_soft_rst_n_i <= '0';
            wait for 1us;
            sig_rst_a_n_i <= '1';
            sig_soft_rst_n_i <= '1';
            wait for 1us;

            -- Sine (ish) wave
            
            sig_flow_rate_i <= std_ulogic_vector(to_unsigned(100, sig_flow_rate_i'length));

--            for i in 0 to 5000 loop
--                sig_flow_rate_i <= std_ulogic_vector(to_unsigned(i, sig_flow_rate_i'length));
--                wait for 3us;
--            end loop;
            
--            for i in 5000 downto 0 loop
--                sig_flow_rate_i <= std_ulogic_vector(to_unsigned(i, sig_flow_rate_i'length));
--                wait for 2us;
--            end loop;

            wait for 100ms;

            done <= true;
        end loop;
    end process tb;

end Behavioral;
