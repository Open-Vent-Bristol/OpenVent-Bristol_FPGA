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

    -- Sigma Delta Signals
    sd_address_i        : in std_ulogic_vector(31 downto 0);
    sd_data_i           : in std_ulogic_vector(31 downto 0);
    sd_data_valid_i     : in std_ulogic;
  
    -- I2C Signals
    i2c_data_i          : in std_ulogic_vector(31 downto 0);
    i2c_data_valid_i    : in std_ulogic;                    
  
    -- SPI Signals
    spi_data_i          : in std_ulogic_vector(31 downto 0);
    spi_data_valid_i    : in std_ulogic;                    

    -- Write to Main Data BRAM
    sensor_address_o       : out std_ulogic_vector(31 downto 0);
    sensor_data_o          : out std_ulogic_vector(31 downto 0);
    sensor_data_valid_o    : out std_ulogic;

    test_point_o    : out std_ulogic_vector(7 downto 0)
);
end sensor_arbitration;

architecture Behavioral of sensor_arbitration is
    
    signal ram_update_vector : std_ulogic_vector(31 downto 0) := (others => '0');
    
    signal temp_data : std_ulogic_vector(31 downto 0) := (others => '0');
    signal temp_addr : std_ulogic_vector(31 downto 0) := (others => '0');
    
    constant shift_count_max : natural := 7;
    signal shift_count : natural range 0 to shift_count_max;
    
    signal new_data : std_ulogic := '0';
    signal new_data_loaded : std_ulogic := '0';

begin

    ram_assignment: process(all)
    
    procedure reset is
    begin
        ram_update_vector <= (others => '0');
        temp_data <= (others => '0');
        temp_addr <= (others => '0');
        shift_count <= 0;
        new_data <= '0';
        new_data_loaded <= '0';
    end procedure reset;
    
    begin
        if rst_a_n_i = g_reset_active then
            reset;
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                reset;
            else
                new_data <= '0';
                new_data_loaded <= '0';
                if sd_data_valid_i = '1' or i2c_data_valid_i = '1' or spi_data_valid_i = '1' then
                    ram_update_vector(to_integer(unsigned(sd_address_i))) <= '1';
                    ram_update_vector(6) <= i2c_data_valid_i;
                    ram_update_vector(7) <= spi_data_valid_i;
                    new_data <= '1';
                elsif new_data = '1' then
                    if ram_update_vector(shift_count) = '1' then
                        if shift_count = 6 then
                            temp_data <= i2c_data_i;
                        elsif shift_count = 7 then  
                            temp_data <= spi_data_i;
                        else
                            temp_data <= sd_data_i;
                        end if;  
                        temp_addr <= std_ulogic_vector(to_unsigned(shift_count, temp_addr'length)); 
                        new_data_loaded <= '1';
                        ram_update_vector(shift_count) <= '0';
                    else
                        if shift_count < shift_count_max then
                            shift_count <= shift_count + 1;               
                        else
                            shift_count <= 0;
                        end if;
                    end if;
                else
                    temp_data <= (others => '0');
                    new_data_loaded <= '0';
                end if;
            end if;
        end if;
    end process ram_assignment; 

    sensor_address_o    <= temp_addr;
    sensor_data_o       <= temp_data;
    sensor_data_valid_o <= new_data_loaded;

end Behavioral;
