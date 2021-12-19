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
    rst_a_n_i       : in std_ulogic;                                    -- Asynchronous Reset IN
    soft_rst_n_i    : in std_ulogic;                                    -- Synchronous Reset IN (here if you need/want it)

    flow_rate_i     : in std_ulogic_vector(11 downto 0);

    data_o          : out std_ulogic_vector(11 downto 0);
    data_valid_o    : out std_ulogic
);
end tidal_volume_calc;

architecture Behavioral of tidal_volume_calc is

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

    type t_state_type is (IDLE, ADDITION_1, DIVIDE_1, MULTIPLY, DIVIDE_2, ADDITION_2, RESULT);
    signal currentstate, nextstate : t_state_type;
    
    signal clk_5ms : std_ulogic := '0';
    
    signal delta_t_clk : std_ulogic := '0';
    constant c_delta_t : natural := 5;           -- 5ms
    
    constant tens : unsigned(11 downto 0) := x"00A";
    
    signal clk_5ms_a, clk_5ms_b : std_ulogic := '0';
    signal clk_5ms_re, clk_5ms_fe : std_ulogic := '0';
    
    signal flow_rate_now, flow_rate_prev : std_ulogic_vector(11 downto 0) := (others => '0');
    signal flow_rate_sum : std_ulogic_vector(11 downto 0) := (others => '0');
    signal flow_rate_mult : std_ulogic_vector(23 downto 0) := (others => '0');
    
    signal tidal_volume_large : std_ulogic_vector(23 downto 0) := (others => '0');
    signal tidal_volume : std_ulogic_vector(11 downto 0) := (others => '0');
    signal volume_valid : std_ulogic := '0';

begin

    CLOCK_5ms : clock_divider
    generic map
    (
        g_reset_active => g_reset_active,
        g_output_clock_counts => 125000             -- 5ms
    )
    port map
    (
        clk_i        => clk_i,       
        rst_a_n_i    => rst_a_n_i,   
        soft_rst_n_i => soft_rst_n_i,
    
        clk_o        => clk_5ms
    );
    
    clk_edge: process(all)
    begin
        if rst_a_n_i = g_reset_active then
            clk_5ms_a <= '0';
            clk_5ms_b <= '0';
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                clk_5ms_a <= '0';
                clk_5ms_b <= '0';
            else
                clk_5ms_a <= clk_5ms;
                clk_5ms_b <= clk_5ms_a;
            end if;
        end if;
    end process clk_edge;
    
    clk_5ms_re <= clk_5ms_a and not clk_5ms_b;
    clk_5ms_fe <= clk_5ms_b and not clk_5ms_a;

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
                if clk_5ms_re = '1' or clk_5ms_fe = '1' then            -- Any edge
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
        flow_rate_sum <= (others => '0');
        flow_rate_mult <= (others => '0');
        tidal_volume_large <= (others => '0');
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
                if currentstate = ADDITION_1 then
                    flow_rate_sum <= std_ulogic_vector(unsigned(flow_rate_now) + unsigned(flow_rate_prev));
                elsif currentstate = DIVIDE_1 then
                    flow_rate_sum <= flow_rate_sum srl 1;
                elsif currentstate = MULTIPLY then
                    flow_rate_mult <= std_ulogic_vector(unsigned(flow_rate_sum) * to_unsigned(c_delta_t, 12));
                elsif currentstate = DIVIDE_2 then
                    flow_rate_mult <= std_ulogic_vector(unsigned(flow_rate_mult) / tens);
                elsif currentstate = ADDITION_2 then
                    tidal_volume_large <= std_ulogic_vector(unsigned(flow_rate_mult) + unsigned(tidal_volume));
                elsif currentstate = RESULT then
                    tidal_volume <= tidal_volume_large(11 downto 0);
                    volume_valid <= '1';
                end if;
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
    
    data_o       <= tidal_volume;
    data_valid_o <= volume_valid;

end Behavioral;
