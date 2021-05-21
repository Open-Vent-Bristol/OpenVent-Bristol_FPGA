----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.05.2021 11:49:21
-- Design Name: 
-- Module Name: pulse_generator - Behavioral
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
--            START                            STOP
--    ----------|________________________________|---------
--
--            ->|    g_divided_clock_count_max   |<-
--
-- When reset or inactive, hold at '1'. While active, hold at '0'.
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pulse_generator is
generic
(
    g_divided_clock_count_max : natural;         -- should be 25000000  1000000 for testing (10ms is less sufferable than 250ms)
    g_reset_active : std_ulogic := '0'
);
port
(
    clk_i           : in std_ulogic;
    rst_a_n_i       : in std_ulogic;
    soft_rst_n_i    : in std_ulogic;
    clock_enable_i  : in std_ulogic;
    
    divided_clock_o : out std_ulogic
);
end pulse_generator;

architecture Behavioral of pulse_generator is

signal divided_clock_count : natural range 0 to (g_divided_clock_count_max - 1);
signal divided_clock_driver : std_ulogic := '1';
signal enable_mono : std_ulogic := '0';

begin

    clock_division: process(all)
    
    procedure reset is
    begin
        divided_clock_driver <= '1';
        divided_clock_count <= 0;
        enable_mono <= '0';
    end procedure reset;
    
    begin
        if rst_a_n_i = g_reset_active then
            reset;
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                reset;
            elsif clock_enable_i = '1' or enable_mono = '1' then
                enable_mono <= '1';
                if divided_clock_count >= (g_divided_clock_count_max - 1) then
                    divided_clock_count <= 0;
                    enable_mono <= '0';
                    divided_clock_driver <= '1';
                else
                    divided_clock_driver <= '0';
                    divided_clock_count <= divided_clock_count + 1;
                end if;
            end if;
        end if;
    end process clock_division;
    
    divided_clock_o <= divided_clock_driver;

end Behavioral;
