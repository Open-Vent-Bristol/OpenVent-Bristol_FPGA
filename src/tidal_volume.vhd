----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.07.2021 20:06:40
-- Design Name: 
-- Module Name: tidal_volume_calc - Behavioral
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

entity tidal_volume_calc is
generic
(
    g_reset_active : std_ulogic := '0'
);
port
(
    clk_i           : in std_ulogic;                                    -- System Clock IN
    clk_5ms_i       : in std_ulogic;                                    -- 5ms Clock IN
    rst_a_n_i       : in std_ulogic;                                    -- Asynchronous Reset IN
    soft_rst_n_i    : in std_ulogic;                                    -- Synchronous Reset IN (here if you need/want it)

    flow_rate_i     : in std_ulogic_vector(11 downto 0);

    data_o          : out std_ulogic_vector(11 downto 0);
    data_valid_o    : out std_ulogic
);
end tidal_volume_calc;

architecture Behavioral of tidal_volume_calc is

    type t_state_type is (IDLE, ADDITION_1, DIVIDE, MULTIPLY, ADDITION_2, RESULT);
    signal currentstate, nextstate : t_state_type;
    
    signal delta_t_clk : std_ulogic := '0';
    constant c_delta_t : natural := 5;           -- 5ms
    
    signal flow_rate_now, flow_rate_prev : std_ulogic_vector(11 downto 0) := (others => '0');

begin

    flow_capture: process(all)
    
    procedure reset is
    begin
        delta_t_clk <= '0';
        flow_rate_now <= (others => '0');
        flow_rate_prev <= (others => '0');
    end procedure reset;

    begin
        if rst_a_n_i = g_reset_active then
            reset;
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                reset;
            else
                delta_t_clk <= '0';
                if clk_5ms_i = '1' then
                    flow_rate_now <= flow_rate_i;
                    flow_rate_prev <= flow_rate_now;
                    delta_t_clk <= '1';
                end if;
            end if;
        end if;
    end process flow_capture;
    
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
        low_rate_sum <= (others => '0');
        flow_rate_mult <= (others => '0');
        tidal_volume <= (others => '0');
        volume_valid <= '0';
    end procedure reset;
    
    begin
        if rst_a_n_i = g_reset_active then
            reset;
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                reset;
            else
                volume_valid <= '0';
                elsif currentstate = ADDITION_1 then
                    flow_rate_sum <= flow_rate_now + flow_rate_prev;
                elsif currentstate = DIVIDE_1 then
                    flow_rate_sum <= flow_rate_sum srl 2;
                elsif currentstate = MULTIPLY then
                    flow_rate_mult <= flow_rate_sum * c_delta_t;
                elsif currentstate = DIVIDE_2 then
                    flow_rate_mult <= flow_rate_mult / 10;
                elsif currentstate = ADDITION_2 then
                    tidal_volume <= flow_rate_mult + tidal_volume;
                elsif currentstate = RESULT then
                    volume_valid <= '1';
                End if;
            end if;
        end if;
    end process calculation;

    fsm_driver: process(all)
    begin
        nextstate <= currentstate;
        case currentstate is
            when IDLE =>
                if delta_t_clk = '1' then
                    nextstate <= ADDITION_1;
                else
                    nextstate <= IDLE;
                end if;
                
            when ADDITION_1 =>
                nextstate <= DIVIDE_1;
                
            when DIVIDE_1 =>
                nextstate <= MULTIPLY;
                
            when MULTIPLY =>
                nextstate <= DIVIDE_2; 
                
            when DIVIDE_2 =>
                nextstate <= ADDITION_2; 
                
            when ADDITION_2 =>
                nextstate <= RESULT; 
                
            when RESULT =>
                nextstate <= IDLE; 

            when others =>
                nextstate <= IDLE;
        end case;
    end process fsm_driver;

end Behavioral;
