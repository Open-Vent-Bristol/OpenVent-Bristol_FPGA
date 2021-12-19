----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.08.2021 15:26:17
-- Design Name: 
-- Module Name: tb_flow_rate_calc - Behavioral
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
use work.ovb_h_rlj.all;

entity tb_flow_rate_calc is
end tb_flow_rate_calc;

architecture Behavioral of tb_flow_rate_calc is

    component flow_rate_calc is
    port
    (
        clk_i           : in std_ulogic;                                    -- System Clock IN
        rst_a_n_i       : in std_ulogic;                                    -- Asynchronous Reset IN
        soft_rst_n_i    : in std_ulogic;                                    -- Synchronous Reset IN (here if you need/want it)
    
        analog_i        : in std_ulogic_vector(11 downto 0);
        analog_valid_i  : in std_ulogic;
    
        data_o          : out std_ulogic_vector(11 downto 0);
        data_valid_o    : out std_ulogic
    );
    end component;
    
    signal sig_clk_i          : std_ulogic := '0';
    signal sig_rst_a_n_i      : std_ulogic := '0';
    signal sig_soft_rst_n_i   : std_ulogic := '0';

    signal sig_analog_i       : std_ulogic_vector(11 downto 0) := (others => '0');
    signal sig_analog_valid_i : std_ulogic := '0';

    signal sig_data_o         : std_ulogic_vector(11 downto 0) := (others => '0');
    signal sig_data_valid_o   : std_ulogic := '0';

    constant clk_period : time := 20ns;         -- Roughly 25MHz clock (33.3MHz is awkward af for timing)
    signal done : boolean := false;

begin

    TESTBENCH_CORE : flow_rate_calc
    port map
    (
        clk_i          => sig_clk_i,
        rst_a_n_i      => sig_rst_a_n_i,
        soft_rst_n_i   => sig_soft_rst_n_i,

        analog_i       => sig_analog_i,
        analog_valid_i => sig_analog_valid_i,

        data_o         => sig_data_o,
        data_valid_o   => sig_data_valid_o
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
            
            for i in 0 to 9 loop
                
                sig_analog_i <= std_ulogic_vector(to_unsigned((i * 330), sig_analog_i'length));         -- 10 % to 90% of VDD (3.3Vcc)
                
                sig_analog_valid_i <= '1';
                wait for 40ns;
                sig_analog_valid_i <= '0';
                
                wait for 1us;

            end loop;

            wait for 1us;

            done <= true;
        end loop;
    end process tb;

end Behavioral;
