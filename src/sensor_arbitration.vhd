----------------------------------------------------------------------------------
-- Company:     OVB
-- Engineer:    Roland Johnson
-- 
-- Create Date: 13.05.2021 16:21:04
-- Design Name: 
-- Module Name: max_min_RAM - Behavioral
-- Project Name:    OVB
-- Target Devices:  GOWIN something
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

entity sensor_arbitration is
generic
(
    g_reset_active : std_ulogic := '0'
);
port
(
    clk_i           : in std_ulogic;                                    -- System Clock IN
    rst_a_n_i       : in std_ulogic;                                    -- Asynchronous Reset IN
    soft_rst_n_i    : in std_ulogic;                                    -- Synchronous Reset IN (here if you need/want it)
    
    ram_busy_i      : in std_ulogic;                        -- If the RAM is IDLE

    -- Sigma Delta Signals
    -- O2 Sensor
    O2_sd_data_i                : in std_ulogic_vector(13 downto 0);
    O2_sd_data_valid_i          : in std_ulogic; 
    
    -- Pressure Sensor Ventilator
    pres_vent_sd_data_i         : in std_ulogic_vector(13 downto 0);
    pres_vent_sd_data_valid_i   : in std_ulogic;                    
    
    -- Pressure Sensor Patient
    pres_pat_sd_data_i          : in std_ulogic_vector(13 downto 0);
    pres_pat_sd_data_valid_i    : in std_ulogic;                    
    
    -- Flow Sensor Direct
    flow_drct_sd_data_i         : in std_ulogic_vector(13 downto 0);
    flow_drct_sd_data_valid_i   : in std_ulogic;                    
  
    -- Flow Sensor Gain
    flow_gain_sd_data_i         : in std_ulogic_vector(13 downto 0);
    flow_gain_sd_data_valid_i   : in std_ulogic;                    
  
    -- I2C Signals
    i2c_data_i          : in std_ulogic_vector(13 downto 0);
    i2c_data_valid_i    : in std_ulogic;                    
  
    -- SPI Signals
    spi_data_i          : in std_ulogic_vector(13 downto 0);
    spi_data_valid_i    : in std_ulogic;                    

    -- Write to Main Data BRAM
    sensor_address_o       : out std_ulogic_vector(7 downto 0);
    sensor_data_o          : out std_ulogic_vector(15 downto 0);
    sensor_data_valid_o    : out std_ulogic;

    test_point_o    : out std_ulogic_vector(7 downto 0)
);
end sensor_arbitration;

architecture Behavioral of sensor_arbitration is
    
    signal update_vector : std_ulogic_vector(6 downto 0) := (others => '0');
    
    signal temp_data : std_ulogic_vector(13 downto 0) := (others => '0');
    signal temp_addr : std_ulogic_vector(3 downto 0) := (others => '0');
    
    constant shift_count_max : natural := 6;
    type valid_counter_t is array (6 downto 0) of natural range 0 to shift_count_max;
    signal valid_counter : valid_counter_t := (others => (0));

    signal new_data_loaded : std_ulogic := '0';
    
    signal shift_lock : std_ulogic := '0';

begin

    update_vector <= spi_data_valid_i & i2c_data_valid_i & flow_gain_sd_data_valid_i & flow_drct_sd_data_valid_i & pres_pat_sd_data_valid_i & pres_vent_sd_data_valid_i & O2_sd_data_valid_i;

    ram_assignment: process(all)
    
    variable valid_counter : valid_counter_t := (others => (0));
    variable update_vector_count : natural range 0 to shift_count_max;

    procedure reset is
    begin
        temp_data <= (others => '0');
        temp_addr <= (others => '0');
        new_data_loaded <= '0';
        update_vector_count := 0;
        valid_counter := (others => (0));
    end procedure reset;

    begin
        if rst_a_n_i = g_reset_active then
            reset;
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                reset;
            else
                new_data_loaded <= '0';
                if update_vector > "0000000" then
                    for i in 0 to 6 loop
                        if update_vector(i) = '1' then
                            if update_vector_count < shift_count_max then
                                update_vector_count := update_vector_count + 1;
                            else
                                update_vector_count := 0;
                            end if;
                            valid_counter(i) := update_vector_count;
                        end if;
                    end loop;
                else
                    if ram_busy_i = '0' and new_data_loaded = '0' then
                        if update_vector_count > 0 then
                            if valid_counter(0) = update_vector_count then
                                temp_addr <= x"0"; 
                                temp_data <= O2_sd_data_i;
                                valid_counter(0) := 0;
                            elsif valid_counter(1) = update_vector_count then
                                temp_addr <= x"1"; 
                                temp_data <= pres_vent_sd_data_i;
                                valid_counter(1) := 0;
                            elsif valid_counter(2) = update_vector_count then
                                temp_addr <= x"2"; 
                                temp_data <= pres_pat_sd_data_i;
                                valid_counter(2) := 0;
                            elsif valid_counter(3) = update_vector_count then
                                temp_addr <= x"3"; 
                                temp_data <= flow_drct_sd_data_i;
                                valid_counter(3) := 0;
                            elsif valid_counter(4) = update_vector_count then
                                temp_addr <= x"4"; 
                                temp_data <= flow_gain_sd_data_i;
                                valid_counter(4) := 0;
                            elsif valid_counter(5) = update_vector_count then
                                temp_addr <= x"5"; 
                                temp_data <= i2c_data_i;
                                valid_counter(5) := 0;
                            elsif valid_counter(6) = update_vector_count then
                                temp_addr <= x"6"; 
                                temp_data <= spi_data_i;
                                valid_counter(6) := 0;
                            end if;
                            update_vector_count := update_vector_count - 1;
                            new_data_loaded <= '1';
                        else
                            new_data_loaded <= '0';
                        end if;
                    else
                        new_data_loaded <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process ram_assignment; 

    sensor_address_o    <= x"0" & temp_addr;
    sensor_data_o       <= "00" & temp_data;
    sensor_data_valid_o <= new_data_loaded;

end Behavioral;
