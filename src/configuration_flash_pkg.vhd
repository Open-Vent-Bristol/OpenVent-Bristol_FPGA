----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.05.2021 21:33:15
-- Design Name: 
-- Module Name: configuration_flash_pkg - Behavioral
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

package configuration_flash_pkg is

    component FLASH64KZ
    port 
    (   
        XADR    : in std_logic_vector(4 downto 0);
        YADR    : in std_logic_vector(5 downto 0);
        XE      : in std_logic;
        YE      : in std_logic;
        SE      : in std_logic;
        ERASE   : in std_logic;
        PROG    : in std_logic;
        NVSTR   : in std_logic;
        DIN     : in std_logic_vector(31 downto 0);
        DOUT    : out std_logic_vector(31 downto 0)
    );
    end component;
    
    component clock_divider is
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
    end component;

    component pulse_generator is
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
    end component;

end package configuration_flash_pkg;
