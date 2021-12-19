----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.08.2021 13:31:56
-- Design Name: 
-- Module Name: ovb_orifice_calc - Behavioral
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
-- Because of the supremely awkward numbers of the constants, everything will be standardised to 16-bit
-- then corrected at the end of the calculations. This means that e.g. C1; 22.8357 will become 22836 to get the most
-- accuracy possible, without asking the FPGA to do 64-bit division (if you want to do that, use a Zynq-7000 instead!!)
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.ovb_h_rlj.all;

entity ovb_orifice_calc is
generic
(
    g_reset_active : std_ulogic := '0'
);
port
(
    clk_i           : in std_ulogic;                                    -- System Clock IN
    rst_a_n_i       : in std_ulogic;                                    -- Asynchronous Reset IN
    soft_rst_n_i    : in std_ulogic;                                    -- Synchronous Reset IN (here if you need/want it)

    diff_pres_i     : in std_ulogic_vector(11 downto 0);
    ambient_temp_i  : in std_ulogic_vector(11 downto 0);
    down_abs_pres_i : in std_ulogic_vector(11 downto 0);

    data_o          : out std_ulogic_vector(11 downto 0);
    data_valid_o    : out std_ulogic
);
end ovb_orifice_calc;

architecture Behavioral of ovb_orifice_calc is

    -- starts data sampling process
    signal sample_data : std_ulogic := '0';

    signal diff_pres_standard     : std_ulogic_vector(15 downto 0) := (others => '0');
    signal ambient_temp_standard  : std_ulogic_vector(15 downto 0) := (others => '0');
    signal down_abs_pres_standard : std_ulogic_vector(15 downto 0) := (others => '0');
    
    signal standardisation_complete : std_ulogic := '0';
    





begin

    standardisation: process(all)
    
    procedure reset is
    begin
        diff_pres_standard <= (others => '0');
        ambient_temp_standard <= (others => '0');
        down_abs_pres_standard <= (others => '0');
        standardisation_complete <= '0';
    end procedure reset;

    begin
        if rst_a_n_i = g_reset_active then
            
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                
            else
                if sample_data = '1' then           -- something will begin this...
                    diff_pres_standard <= x"0" & diff_pres_i;
                    ambient_temp_standard <= x"0" & ambient_temp_i;
                    down_abs_pres_standard <= x"0" & down_abs_pres_i;
                    standardisation_complete <= '1';
                else
                    standardisation_complete <= '0';
                end if;
            end if;
        end if;
    end process standardisation;
    











end Behavioral;
