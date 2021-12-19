----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.07.2021 20:48:52
-- Design Name: 
-- Module Name: tb_adc_multiplication - Behavioral
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

entity tb_adc_multiplication is
end tb_adc_multiplication;

architecture Behavioral of tb_adc_multiplication is

    component adc_multiplication is
    port
    (
        clk_i           : in std_ulogic;                                    -- System Clock IN
        rst_a_n_i       : in std_ulogic;                                    -- Asynchronous Reset IN
        soft_rst_n_i    : in std_ulogic;                                    -- Synchronous Reset IN (here if you need/want it)
        
        data_i          : in std_ulogic_vector(11 downto 0);
        data_valid_i    : in std_ulogic;
        
        voltage_ref_i   : in t_adc_vref;
        ref_valid_i     : in std_ulogic;
        
        data_o          : out std_ulogic_vector(11 downto 0);
        data_valid_o    : out std_ulogic
    );
    end component;

    signal sig_clk_i         : std_ulogic := '0';
    signal sig_rst_a_n_i     : std_ulogic := '0';
    signal sig_soft_rst_n_i  : std_ulogic := '0';

    signal sig_data_i        : std_ulogic_vector(11 downto 0) := (others => '0');
    signal sig_data_valid_i  : std_ulogic := '0';

    signal sig_voltage_ref_i : t_adc_vref := REF_5V;
    signal sig_ref_valid_i   : std_ulogic := '0';

    signal sig_data_o        : std_ulogic_vector(11 downto 0) := (others => '0');
    signal sig_data_valid_o  : std_ulogic := '0';

    constant clk_period : time := 20ns;         -- Roughly 25MHz clock (33.3MHz is awkward af for timing)
    signal done : boolean := false;

begin

    TESTBENCH_CORE : adc_multiplication
    port map
    (
        clk_i         => sig_clk_i,        
        rst_a_n_i     => sig_rst_a_n_i,    
        soft_rst_n_i  => sig_soft_rst_n_i, 
        
        data_i        => sig_data_i,       
        data_valid_i  => sig_data_valid_i, 
        
        voltage_ref_i => sig_voltage_ref_i,
        ref_valid_i   => sig_ref_valid_i,  
        
        data_o        => sig_data_o,       
        data_valid_o  => sig_data_valid_o 
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
            
            sig_data_i <= "001101001010";                 -- 842, 1029(5v), 678(3.3v)
            sig_data_valid_i <= '1';
            wait for 40ns;
            sig_data_valid_i <= '0';
            
            sig_voltage_ref_i <= REF_5V;
            sig_ref_valid_i <= '1';
            wait for 40ns;
            sig_ref_valid_i <= '0';
            
            wait for 5us;
            
            sig_data_i <= "100000000000";                 -- 2048, 2500(5v), 1650(3.3v)
            sig_data_valid_i <= '1';
            wait for 40ns;
            sig_data_valid_i <= '0';
            
            sig_voltage_ref_i <= REF_5V;
            sig_ref_valid_i <= '1';
            wait for 40ns;
            sig_ref_valid_i <= '0';
            
            wait for 5us;
            
            sig_data_i <= "101001001000";                 -- 2632, 3213(5v), 2120(3.3v)
            sig_data_valid_i <= '1';
            wait for 40ns;
            sig_data_valid_i <= '0';
            
            sig_voltage_ref_i <= REF_5V;
            sig_ref_valid_i <= '1';
            wait for 40ns;
            sig_ref_valid_i <= '0';
            
            wait for 5us;

            done <= true;
        end loop;
    end process tb;

end Behavioral;
