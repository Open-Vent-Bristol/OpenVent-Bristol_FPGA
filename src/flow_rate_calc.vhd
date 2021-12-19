----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.08.2021 15:04:25
-- Design Name: 
-- Module Name: flow_rate_calc - Behavioral
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

entity flow_rate_calc is
generic
(
    g_reset_active : std_ulogic := '0'
);
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
end flow_rate_calc;

architecture Behavioral of flow_rate_calc is

    type t_state_type is (IDLE, MULTIPLY_1, DIVISION_1, SUBTRACTION_1, MULTIPLY_2, SUBTRACTION_2, DIVIDE_2, RESULT);
    signal currentstate, nextstate : t_state_type;
    
    constant c_vdd_ten      : unsigned(11 downto 0) := x"021";          -- 33 (Analog input is effectively 100 times larger - we lose least precision this way)
    constant c_scaling      : unsigned(11 downto 0) := x"84D";          -- 2125 (Constant 212.5)
    constant c_div_thousand : unsigned(11 downto 0) := x"3EB";          -- 1000 ((We need to subtract result by 1000)
    constant c_div_hundred  : unsigned(7 downto 0) := x"64";            -- 100 (rescale output to percentage)
    constant c_mul_ten : unsigned(3 downto 0) := x"A";                  -- 10 (Scale to 16-bit to give enough floating points)
    
    signal analog_temp   : unsigned(11 downto 0) := (others => '0');
    signal analog_temp_f : unsigned(15 downto 0) := (others => '0');
    signal analog_vdd    : unsigned(15 downto 0) := (others => '0');
    signal analog_scaled : unsigned(23 downto 0) := (others => '0');
    signal flow_rate_full : unsigned(23 downto 0) := (others => '0');     -- Result will actually be 12 bit but stupid types mean we need 24 here
    signal flow_rate_normal : std_ulogic_vector(11 downto 0) := (others => '0');
    
    signal flow_valid : std_ulogic := '0';

begin

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
    
    calculation: process(all)
    
    procedure reset is
    begin
        analog_vdd    <= (others => '0');
        analog_scaled <= (others => '0');
        flow_rate_full <= (others => '0');
        flow_valid <= '0';
    end procedure reset;
    
    begin
        if rst_a_n_i = g_reset_active then
            reset;
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                reset;
            else
                analog_temp <= unsigned(analog_i);                -- sync input
                flow_valid <= '0';
                if currentstate = MULTIPLY_1 then
                    analog_temp_f <= analog_temp * c_mul_ten;
                elsif currentstate = DIVISION_1 then
                    analog_vdd <= analog_temp_f / c_vdd_ten;
                elsif currentstate = SUBTRACTION_1 then
                    if analog_vdd < to_unsigned(100, analog_vdd'length) then
                        analog_vdd <= analog_vdd + to_unsigned(100, analog_vdd'length);
                    else
                        analog_vdd <= analog_vdd - to_unsigned(100, analog_vdd'length);
                    end if;
                elsif currentstate = MULTIPLY_2 then
                    analog_scaled <= c_scaling * analog_vdd;
                elsif currentstate = SUBTRACTION_2 then
                    analog_scaled <= analog_scaled - c_div_thousand;
                elsif currentstate = DIVIDE_2 then
                    flow_rate_full <= analog_scaled / c_div_hundred;
                elsif currentstate = RESULT then
                    flow_rate_normal <= std_ulogic_vector(flow_rate_full(11 downto 0));
                    flow_valid <= '1';
                end if;
            end if;
        end if;
    end process calculation;

    fsm_driver: process(all)
    begin
        nextstate <= currentstate;
        case currentstate is
            when IDLE =>
                if analog_valid_i = '1' then
                    nextstate <= MULTIPLY_1;
                else
                    nextstate <= IDLE;
                end if;
                
            when MULTIPLY_1 =>
                nextstate <= DIVISION_1;
                
            when DIVISION_1 =>
                nextstate <= SUBTRACTION_1;
                
            when SUBTRACTION_1 =>
                nextstate <= MULTIPLY_2;
                
            when MULTIPLY_2 =>
                nextstate <= SUBTRACTION_2; 
                
            when SUBTRACTION_2 =>
                nextstate <= DIVIDE_2; 
                
            when DIVIDE_2 =>
                nextstate <= RESULT; 
                
            when RESULT =>
                nextstate <= IDLE; 

            when others =>
                nextstate <= IDLE;
        end case;
    end process fsm_driver;
    
    data_o <= flow_rate_normal;
    data_valid_o <= flow_valid;

end Behavioral;
