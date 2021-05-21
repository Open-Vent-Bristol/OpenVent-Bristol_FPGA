----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.05.2021 20:55:44
-- Design Name: 
-- Module Name: clock_divider - Behavioral
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

entity clock_divider is
generic
(
    g_reset_active : std_ulogic := '0';
    g_output_clock_counts : natural
);
port
(
    clk_i           : in std_ulogic;
    rst_a_n_i       : in std_ulogic;
    soft_rst_n_i    : in std_ulogic;
    
    clk_o           : out std_ulogic
);
end clock_divider;

architecture Behavioral of clock_divider is

    signal clk_count : natural range 0 to g_output_clock_counts;
    signal divided_clk : std_ulogic := '0';

begin

    clk_division: process(all)
    begin
        if rst_a_n_i = g_reset_active then
            clk_count <= 0;
            divided_clk <= '0';
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                clk_count <= 0;
                divided_clk <= '0';
            else
                if clk_count >= (g_output_clock_counts - 1) then
                    clk_count <= 0;
                    divided_clk <= not divided_clk;
                else
                    clk_count <= clk_count + 1;
                end if;
            end if;
        end if;    
    end process clk_division;
    
    clk_o <= divided_clk;

end Behavioral;
