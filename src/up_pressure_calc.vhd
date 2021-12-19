----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.07.2021 10:32:26
-- Design Name: 
-- Module Name: up_pressure_calc - Behavioral
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

entity up_pressure_calc is
generic
(
    g_reset_active : std_ulogic := '0'
);
port
(
    clk_i               : in std_ulogic;                                    -- System Clock IN
    rst_a_n_i           : in std_ulogic;                                    -- Asynchronous Reset IN
    soft_rst_n_i        : in std_ulogic;                                    -- Synchronous Reset IN (here if you need/want it)
    
    sensor_address_i    : in std_ulogic_vector(7 downto 0);                 -- It would be nice to reuse this module to save space...
    addr_valid_i        : in std_ulogic;

    op_mode_i           : in std_ulogic;                                    -- Operation mode - '0' is inactive (getting offset), '1' is in operation

    abs_pressure_i      : in std_ulogic_vector(11 downto 0);                -- Some things need the absolute pressure
    raw_data_i          : in std_ulogic_vector(11 downto 0);

    data_o              : out std_ulogic_vector(11 downto 0);
    data_valid_o        : out std_ulogic
);
end up_pressure_calc;

architecture Behavioral of up_pressure_calc is

    component adc_multiplication is
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
        
        scaling_fctr_i  : in std_ulogic_vector(11 downto 0);

        data_o          : out std_ulogic_vector(11 downto 0);
        data_valid_o    : out std_ulogic
    );
    end component;
    
    type t_state_type is (IDLE, SUBTRACT, READY, FIO2_MULTIPLY, FIO2_DIVIDE);
    signal currentstate, nextstate : t_state_type;
    
    signal voltage_ref : t_adc_vref := REF_5V;          -- Dynamic and so will change
    signal ref_valid : std_ulogic := '0';
    
    signal adc_data_out : std_ulogic_vector(11 downto 0) := (others => '0');
    signal adc_data_valid_out : std_ulogic := '0';
    
    type t_adc_offset is array(5 downto 0) of std_ulogic_vector(11 downto 0);
    signal adc_offset : t_adc_offset := (others => (others => '0'));

    signal adc_data_op : std_ulogic_vector(11 downto 0) := (others => '0');
    signal adc_data_valid : std_ulogic := '0';
    
    signal sensor_address : std_ulogic_vector(7 downto 0) := (others => '0');
    
    constant address_normal_max : natural := 5;
    signal address_normal : natural range 0 to address_normal_max;
    
    signal scaling_factor : std_ulogic_vector(11 downto 0) := (others => '0');
    
    signal volt_minus_offset : std_ulogic_vector(11 downto 0) := (others => '0');

    signal data_refined : std_ulogic_vector(23 downto 0) := (others => '0');
    signal refined_valid : std_ulogic := '0';
    
    signal fi02_percentage : std_ulogic_vector(23 downto 0) := (others => '0');

    constant c_hundred  : std_ulogic_vector(11 downto 0) := "000001100100";

    signal offset_valid, offset_valid_de : std_ulogic := '0';
    
    signal ready_done : std_ulogic := '0';
    
begin

    ADC_MULTIPLIER : adc_multiplication
    generic map
    (
        g_reset_active => g_reset_active
    )
    port map
    (
        clk_i           => clk_i,
        rst_a_n_i       => rst_a_n_i,
        soft_rst_n_i    => soft_rst_n_i,
        
        op_mode_i       => op_mode_i,

        data_i          => raw_data_i,
        
        voltage_ref_i   => voltage_ref,
        ref_valid_i     => ref_valid,
        
        volt_offset_i   => volt_minus_offset,
        offset_valid_i  => offset_valid_de,
        
        scaling_fctr_i  => scaling_factor,

        data_o          => adc_data_out,
        data_valid_o    => adc_data_valid_out
    );
    
    voltage_reference: process(all)
    
    procedure reset is
    begin
        sensor_address <= (others => '0');
            address_normal <= 0;
            ref_valid <= '0';
    end procedure reset;
    
    begin
        if rst_a_n_i = g_reset_active then
            reset;
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                reset;
            else
                ref_valid <= '0';
                if addr_valid_i = '1' then
                    sensor_address <= sensor_address_i;
                    address_normal <= ((to_integer(unsigned(sensor_address_i))) - 3);
                    reference_select(sensor_address_i, voltage_ref);                        -- Select appropriate voltage reference
                    scaling(sensor_address_i, scaling_factor);                                -- Select appropriate scaling factor
                    ref_valid <= '1';
                end if;
            end if;
        end if;
    end process voltage_reference;
    
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

    record_offset: process(all)
    
    procedure reset is
    begin
        adc_offset <= (others => (others => '0'));
        adc_data_op <= (others => '0');
        adc_data_valid <= '0';
    end procedure reset;

    begin
        if rst_a_n_i = g_reset_active then
            reset;
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                reset;
            else
                adc_data_valid <= '0';
                if op_mode_i = '0' then
                    if adc_data_valid_out = '1' then
                        adc_offset(address_normal) <= adc_data_out;             -- Save Offsets to RAM, address normally 0 to 8, but 3 to 8 in this case, so offset necessary
                    end if;
                else
                    if adc_data_valid_out = '1' then
                        adc_data_op <= adc_data_out;
                        adc_data_valid <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process record_offset;

    subtract_offset: process(all)
    
    procedure reset is
    begin
        refined_valid <= '0';
            offset_valid_de <= '0';
            offset_valid <= '0';
            ready_done <= '0';
            volt_minus_offset <= (others => '0');
            fi02_percentage <= (others => '0');
            data_refined <= (others => '0');
    end procedure reset;

    begin
        if rst_a_n_i = g_reset_active then
            reset;
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                reset;
            else
                refined_valid <= '0';
                offset_valid_de <= offset_valid;
                if currentstate = IDLE then
                    offset_valid <= '0';
                    ready_done <= '0';
                elsif currentstate = SUBTRACT then
                    if offset_valid = '0' then
                        if sensor_address = x"04" then          -- Let's say 4 is temperature for now
                            volt_minus_offset <= std_ulogic_vector(unsigned(adc_data_op) - unsigned(c_temperature_offset));
                        else
                            volt_minus_offset <= std_ulogic_vector(unsigned(adc_data_op) - unsigned(adc_offset(address_normal)));
                        end if;
                        offset_valid <= '1';
                    end if;
                elsif currentstate = READY then
                    if sensor_address /= x"08" then
                        data_refined(11 downto 0) <= adc_data_out;
                        refined_valid <= '1';
                    else
                        refined_valid <= '0';
                    end if; 
                elsif currentstate = FIO2_MULTIPLY then
                    fi02_percentage <= std_ulogic_vector(unsigned(adc_data_out) * unsigned(c_hundred));        -- Multiply by 100
                elsif currentstate = FIO2_DIVIDE then
                    data_refined <= std_ulogic_vector(unsigned(fi02_percentage) / unsigned(abs_pressure_i));
                    refined_valid <= '1';
                end if;
            end if;
        end if;
    end process subtract_offset;
    
    fsm_driver: process(all)
    begin
        nextstate <= currentstate;
        case currentstate is
            when IDLE =>
                if adc_data_valid = '1' then
                    nextstate <= SUBTRACT;
                else
                    nextstate <= IDLE;
                end if;
                
            when SUBTRACT =>
                if adc_data_valid = '1' and offset_valid = '1' then
                    nextstate <= READY;
                else
                    nextstate <= SUBTRACT;
                end if;
                
            when READY =>
                if sensor_address = x"08" then
                    nextstate <= FIO2_MULTIPLY;
                else
                    nextstate <= IDLE;
                end if;
                
            when FIO2_MULTIPLY =>
                nextstate <= FIO2_DIVIDE; 
                
            when FIO2_DIVIDE =>
                nextstate <= IDLE; 

            when others =>
                nextstate <= IDLE;
        end case;
    end process fsm_driver;
    
    data_o       <= data_refined(11 downto 0);
    data_valid_o <= refined_valid;

end Behavioral;
