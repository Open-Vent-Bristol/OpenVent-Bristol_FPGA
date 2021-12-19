----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.07.2021 19:37:03
-- Design Name: 
-- Module Name: adc_multiplication - Behavioral
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
--  Always 12 bit
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.ovb_h_rlj.all;

entity adc_multiplication is
generic
(
    g_reset_active : std_ulogic := '0'
);
port
(
    clk_i           : in std_ulogic;                                    -- System Clock IN
    rst_a_n_i       : in std_ulogic;                                    -- Asynchronous Reset IN
    soft_rst_n_i    : in std_ulogic;                                    -- Synchronous Reset IN (here if you need/want it)
    
    op_mode_i       : in std_ulogic;                                    -- Operation mode - '0' is inactive (getting offset), '1' is in operation
    
    data_i          : in std_ulogic_vector(11 downto 0);
    
    voltage_ref_i   : in t_adc_vref;
    ref_valid_i     : in std_ulogic;
    
    volt_offset_i   : in std_ulogic_vector(11 downto 0);
    offset_valid_i  : in std_ulogic;
    
    scaling_fctr_i  : std_ulogic_vector(11 downto 0);
    
    data_o          : out std_ulogic_vector(11 downto 0);
    data_valid_o    : out std_ulogic
);
end adc_multiplication;

architecture Behavioral of adc_multiplication is

    type t_state_type is (IDLE, V_REFERENCE, MULTIPLY, DIVIDE);
    signal currentstate, nextstate : t_state_type;
    
    signal data_ready : std_ulogic_vector(23 downto 0) := (others => '0');
    signal data_valid : std_ulogic := '0';
    
    signal data_refined : std_ulogic_vector(23 downto 0) := (others => '0');
    
    signal data_storage : std_ulogic_vector(11 downto 0) := (others => '0');
    
    constant c_ref_5v  : std_ulogic_vector(11 downto 0) := "010011000101";
    constant c_ref_3v3 : std_ulogic_vector(11 downto 0) := "001100100110";
    
    signal eq_rhs : std_ulogic_vector(11 downto 0) := (others => '0');          -- RHS of multiplication equation (can be VREF or Scaling factor)
    
    constant pass_count_max : natural := 1;
    signal pass_count : natural range 0 to pass_count_max;
    
    constant c_thousand : std_ulogic_vector(11 downto 0) := "001111101000";
    
    signal offset_valid : std_ulogic := '0';
    signal offset_mono : std_ulogic := '0';
    signal offset_ack : std_ulogic := '0';
    
begin

    offset_acknowledge: process(all)
    begin
        if rst_a_n_i = g_reset_active then
            offset_valid <= '0';
            offset_mono <= '0';
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                offset_valid <= '0';
                offset_mono <= '0';
            else
                if offset_valid_i = '1' and offset_mono = '0' then
                    offset_valid <= '1';
                    offset_mono <= '1';
                elsif offset_ack = '1' then
                    offset_valid <= '0';
                elsif offset_valid_i = '0' then
                    offset_mono <= '0';
                end if;
            end if;
        end if;
    end process offset_acknowledge;

    calc_by_pass: process(all)
    begin
        if rst_a_n_i = g_reset_active then
            eq_rhs <= (others => '0');
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                eq_rhs <= (others => '0');
            else
                if pass_count = 0 then
                    data_storage <= data_i;
                    if voltage_ref_i = REF_5V then
                        eq_rhs <= c_ref_5v;
                    else
                        eq_rhs <= c_ref_3v3;
                    end if;
                elsif pass_count = 1 then
                    data_storage <= volt_offset_i;
                    eq_rhs <= scaling_fctr_i;
                end if;
            end if;
        end if;
    end process calc_by_pass;

    data_sorting: process(all)
    begin
        if rst_a_n_i = g_reset_active then
            data_refined <= (others => '0');
            data_ready <= (others => '0');
            data_valid <= '0';
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                data_refined <= (others => '0');
                data_ready <= (others => '0');
                data_valid <= '0';
            else
                data_valid <= '0';
                offset_ack <= '0';
                if currentstate = MULTIPLY then
                    data_refined <= std_ulogic_vector(unsigned(data_storage) * unsigned(eq_rhs));
                    offset_ack <= '1';
                elsif currentstate = DIVIDE then
                    data_ready <= std_ulogic_vector(unsigned(data_refined) / unsigned(c_thousand));
                    data_valid <= '1';
                    if pass_count < pass_count_max and op_mode_i = '1' then         -- Only count up if we're in operation, otherwise get offsets
                        pass_count <= pass_count + 1;
                    else
                        pass_count <= 0;
                    end if;
                end if;
            end if;
        end if;
    end process data_sorting;
    
    state_driver: process(all)
    begin
        if rst_a_n_i = g_reset_active then
            currentstate <= IDLE;
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                currentstate <= IDLE;
            else
                currentstate <= nextstate;
            end if;
        end if;
    end process state_driver;
    
    fsm_driver: process(all)
    begin
        nextstate <= currentstate;
        case currentstate is
            when IDLE =>
                if ref_valid_i = '1' or offset_valid = '1' then
                    nextstate <= MULTIPLY;
                else
                    nextstate <= IDLE;
                end if;
                
            when MULTIPLY =>
                nextstate <= DIVIDE;
                
            when DIVIDE =>
                nextstate <= IDLE;
                
            when others =>
                nextstate <= IDLE;
        end case;
    end process fsm_driver;
    
    data_o       <= data_ready(11 downto 0);
    data_valid_o <= data_valid;

end Behavioral;
