----------------------------------------------------------------------------------
-- Company:     OVB
-- Engineer:    Roland Johnson
-- 
-- Create Date: 13.05.2021 16:21:04
-- Design Name: 
-- Module Name: ovb_ram - Behavioral
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
-- GOWIN FLASH instatiation: http://cdn.gowinsemi.com.cn/UG295E.pdf , page 9
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.ovb_h_rlj.all;

entity ovb_ram is
generic
(
    g_reset_active : std_ulogic := '0'
);
port
(
    clk_i               : in std_ulogic;                                    -- System Clock IN
    rst_a_n_i           : in std_ulogic;                                    -- Asynchronous Reset IN
    soft_rst_n_i        : in std_ulogic;                                    -- Synchronous Reset IN (here if you need/want it)

    -- Probably used for MCU
    mcu_addr_i         : in std_ulogic_vector(31 downto 0);   
    mcu_oe_i           : in std_ulogic;
    mcu_data_o         : out std_ulogic_vector(31 downto 0);
    mcu_ack_o          : out std_ulogic;   
    
    -- Probably used for UART
    uart_addr_i         : in std_ulogic_vector(31 downto 0);   
    uart_oe_i           : in std_ulogic;
    uart_data_o         : out std_ulogic_vector(31 downto 0);
    uart_ack_o          : out std_ulogic;                

    -- From Sensor Arbitration
    sensor_addr_i       : in std_ulogic_vector(31 downto 0);
    sensor_data_i       : in std_ulogic_vector(31 downto 0);
    sensor_data_valid_i : in std_ulogic;
    
    -- To/From UI
    ui_addr_i           : in std_ulogic_vector(31 downto 0);
    ui_oe_i             : in std_ulogic;
    ui_we_i             : in std_ulogic;
    ui_data_i           : in std_ulogic_vector(31 downto 0);
    ui_data_valid_i     : in std_ulogic;
    ui_data_o           : out std_ulogic_vector(31 downto 0);
    ui_data_valid_o     : out std_ulogic;
    ui_ack_o            : out std_ulogic;
    
    -- Additional Signals
    cfg_mode_change_i   : in std_ulogic;                            -- Change to/from Standby to something 
    alarm_status_o      : out std_ulogic_vector(31 downto 0);       -- Alarm status flags

    test_point_o        : out std_ulogic_vector(7 downto 0)
);
end ovb_ram;

architecture Behavioral of ovb_ram is

    component configuration_flash is
    generic
    (
        g_reset_active : std_ulogic := '0'
    );
    port
    (
        clk_i               : in std_ulogic;                                    -- System Clock IN
        rst_a_n_i           : in std_ulogic;                                    -- Asynchronous Reset IN
        soft_rst_n_i        : in std_ulogic;                                    -- Synchronous Reset IN (here if you need/want it)
    
        -- Comms To/From Arbitration Block (MCU, UART, Sensors, UI)
        cfg_we_i            : in std_ulogic;                                   -- Read or Write CMD
        cfg_oe_i            : in std_ulogic;                                   -- '0' when IDLE, '1' when you want to do stuff
        
        cfg_data_i          : in std_ulogic_vector(31 downto 0);               -- What you want to write to FLASH
        cfg_data_valid_i    : in std_ulogic;                                   -- The data is valid
        
        cfg_data_o          : out std_ulogic_vector(31 downto 0);              -- Stuff from FLASH
        cfg_data_valid_o    : out std_ulogic;                                  -- The data is valid
        
        cfg_data_req_o      : out std_ulogic;                                  -- A Write has finished, more data requested
    
        test_point_o        : out std_ulogic_vector(7 downto 0)
    );
    end component;

    signal absolute_boundary : std_ulogic := '0';
    signal temp_data : std_ulogic_vector(31 downto 0) := (others => '0');
    
    signal cfg_data_valid_in : std_ulogic := '0';
    signal cfg_data_valid_mono : std_ulogic := '0';
    signal cfg_data_valid : std_ulogic := '0';

    signal cfg_data_req_in : std_ulogic := '0';
    signal cfg_data_req_mono : std_ulogic := '0';
    signal cfg_data_req : std_ulogic := '0';
    
    signal cfg_read_active : std_ulogic := '0';
    signal first_run : std_ulogic := '0';
    signal cfg_write_inhibit : std_ulogic := '0';
    
    signal cfg_oe : std_ulogic := '0';
    signal cfg_we : std_ulogic := '0';
    
    signal cfg_lock : std_ulogic := '0';
    
    constant cfg_count_max : natural := 13;
    signal cfg_count : natural range 0 to cfg_count_max;

    signal minmax_setup_write_finished : std_ulogic := '0';
    signal minmax_setup_read_finished : std_ulogic := '0';
    
    signal cfg_read_req : std_ulogic := '0';
    signal cfg_write_req : std_ulogic := '0';
    
    signal mcu_sensor_req : std_ulogic := '0';
    signal mcu_minmax_req : std_ulogic := '0';
    signal mcu_minmax_ack : std_ulogic := '0';
    signal mcu_data_ack   : std_ulogic := '0';
    
    signal uart_sensor_req : std_ulogic := '0';
    signal uart_minmax_req : std_ulogic := '0';
    signal uart_minmax_ack : std_ulogic := '0';
    signal uart_data_ack   : std_ulogic := '0';
    
    signal ui_minmax_write_req : std_ulogic := '0';
    signal ui_minmax_read_req  : std_ulogic := '0';
    signal ui_sensor_req : std_ulogic := '0';
    signal ui_minmax_req : std_ulogic := '0';
    signal ui_minmax_ack : std_ulogic := '0';
    signal ui_data_ack   : std_ulogic := '0';
    
    signal sensor_sensor_req : std_ulogic := '0';
    signal sensor_minmax_req : std_ulogic := '0';
    signal sensor_minmax_ack : std_ulogic := '0';
    signal sensor_sensor_ack : std_ulogic := '0';
    
    signal mcu_sensor_ram_control : std_ulogic := '0';
    signal uart_sensor_ram_control : std_ulogic := '0';
    signal ui_sensor_ram_control : std_ulogic := '0';
    
    signal sensor_ram_we : std_ulogic := '0';
    signal sensor_ram_active : std_ulogic := '0';
    signal sensor_ram_ack : std_ulogic := '0';
    signal sensor_min_access : std_ulogic := '0';

    signal sensor_ram_addr : std_ulogic_vector(31 downto 0) := (others => '0');
    signal sensor_ram_data_in : std_ulogic_vector(31 downto 0) := (others => '0');
    
    signal minmax_ram_we : std_ulogic := '0';
    signal minmax_ram_ack : std_ulogic := '0';
   
    signal minmax_ram_active : std_ulogic := '0';
    signal minmax_ram_addr : std_ulogic_vector(31 downto 0) := (others => '0');
    signal minmax_ram_data_in : std_ulogic_vector(31 downto 0) := (others => '0');
    signal cfg_data_in : std_ulogic_vector(31 downto 0) := (others => '0');

    signal cfg_minmax_ram_control : std_ulogic := '0';
    signal mcu_minmax_ram_control : std_ulogic := '0';
    signal uart_minmax_ram_control : std_ulogic := '0';
    signal ui_minmax_ram_control : std_ulogic := '0';
    
    signal sensor_ram_data_out : std_ulogic_vector(31 downto 0) := (others => '0');
    signal minmax_ram_data_out : std_ulogic_vector(31 downto 0) := (others => '0');
    
    signal minmax_ram_addr_temp : std_ulogic_vector(31 downto 0) := (others => '0');
    
    constant access_count_max : natural := 2;
    signal access_count : natural range 0 to access_count_max;
    
    signal temp_data_max : std_ulogic_vector(31 downto 0) := (others => '0');
    signal temp_data_min : std_ulogic_vector(31 downto 0) := (others => '0');

    signal alarm_status : std_ulogic_vector(31 downto 0) := (others => '0');
    
    signal cfg_data_out : std_ulogic_vector(31 downto 0) := (others => '0');
    signal cfg_ack_out : std_ulogic := '0';
    
    type ram_t is array (127 downto 0) of std_ulogic_vector(31 downto 0);
    signal sensor_ram, minmax_ram : ram_t := (others => (others => '0'));
 
begin

    config_flash_sync_data: process(all)
    
    procedure reset is
    begin
        cfg_data_valid_in <= '0';
        cfg_data_valid_mono <= '0';
        cfg_data_valid <= '0';
    end procedure reset;

    begin
        if rst_a_n_i = g_reset_active then
            reset;
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                reset;
            else
                if cfg_data_valid_in = '1' then
                    if cfg_data_valid_mono = '0' then
                        cfg_data_valid <= '1';
                        cfg_data_valid_mono <= '1';
                    else
                        cfg_data_valid <= '0';
                    end if;
                else
                    cfg_data_valid_mono <= '0';
                end if;
            end if;
        end if; 
    end process config_flash_sync_data;
    
    config_flash_sync_req: process(all)
    
    procedure reset is
    begin
        cfg_data_req_in <= '0';
        cfg_data_req_mono <= '0';
        cfg_data_req <= '0';
    end procedure reset;
    
    begin
        if rst_a_n_i = g_reset_active then
            reset;
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                reset;
            else
                if cfg_data_req_in = '1' then
                    if cfg_data_req_mono = '0' then
                        cfg_data_req <= '1';
                        cfg_data_req_mono <= '1';
                    else
                        cfg_data_req <= '0';
                    end if;
                else
                    cfg_data_req_mono <= '0';
                end if;
            end if;
        end if; 
    end process config_flash_sync_req;

    config_flash_first_run: process(all)
    
    procedure reset is
    begin
        cfg_read_active <= '0';
        first_run <= '1';
        cfg_write_inhibit <= '0';
    end procedure reset;

    begin
        if rst_a_n_i = g_reset_active then
            reset;
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                reset;
            else
                if first_run = '1' then
                    cfg_read_active <= '1';
                    first_run <= '0';
                else
                    if cfg_read_active = '1' then
                        if cfg_mode_change_i = '1' then
                            cfg_write_inhibit <= '1';
                        elsif cfg_lock = '0' then
                            cfg_read_active <= '0';
                        end if;
                    else
                        if cfg_write_inhibit = '1' then
                            cfg_write_inhibit <= '0';
                        end if;
                    end if;
                end if;
            end if;
        end if;    
    end process config_flash_first_run;

    config_flash_setup: process(all)
    
    procedure reset is
    begin
        cfg_oe <= '0';
        cfg_we <= '0';
        cfg_read_req <= '0';
        cfg_write_req <= '0';
        cfg_lock <= '0';
        cfg_count <= 0;
    end procedure reset;

    begin
        if rst_a_n_i = g_reset_active then
            reset;
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                reset;
            else
                if cfg_read_active = '1' then
                    cfg_lock <= '1';
                    cfg_oe <= '1';
                    cfg_we <= '0';
                    if cfg_data_valid_in = '1' then
                        if cfg_count < cfg_count_max then
                            cfg_read_req <= '1';
                            cfg_count <= cfg_count + 1;
                        else
                            cfg_count <= 0;
                            cfg_lock <= '0';
                        end if;
                    elsif minmax_setup_write_finished = '1' then
                        cfg_read_req <= '0';
                    end if;
                else
                    if (cfg_mode_change_i = '1' or cfg_data_req = '1') or cfg_write_inhibit = '1' then
                        cfg_oe <= '1';
                        cfg_we <= '1';
                        cfg_write_req <= '1';
                        if cfg_count < cfg_count_max then
                            cfg_count <= cfg_count + 1;
                        else
                            cfg_count <= 0;
                        end if;
                    elsif minmax_setup_read_finished = '1' then
                        cfg_write_req <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process config_flash_setup;

    mcu_signal_mono: process(all)
    begin
        if rst_a_n_i = g_reset_active then
            mcu_sensor_req <= '0';
            mcu_minmax_req <= '0';
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                mcu_sensor_req <= '0';
                mcu_minmax_req <= '0';
            else
                if mcu_oe_i = '1' then
                    if mcu_addr_i <= DATA_RAM_MAX then
                        mcu_sensor_req <= '1';
                    else
                        mcu_minmax_req <= '1';
                    end if;
                elsif mcu_minmax_ack = '1' or mcu_data_ack = '1' then
                    mcu_sensor_req <= '0';
                    mcu_minmax_req <= '0';
                end if;
            end if;
        end if;    
    end process mcu_signal_mono;

    uart_signal_mono: process(all)
    begin
        if rst_a_n_i = g_reset_active then
            uart_sensor_req <= '0';
            uart_minmax_req <= '0';
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                uart_sensor_req <= '0';
                uart_minmax_req <= '0';
            else
                if uart_oe_i = '1' then
                    if uart_addr_i <= DATA_RAM_MAX then
                        uart_sensor_req <= '1';
                    else
                        uart_minmax_req <= '1';
                    end if;
                elsif uart_minmax_ack = '1' or uart_data_ack = '1' then
                    uart_sensor_req <= '0';
                    uart_minmax_req <= '0';
                end if;
            end if;
        end if;    
    end process uart_signal_mono;

    ui_signal_mono: process(all)
    begin
        if rst_a_n_i = g_reset_active then
            ui_sensor_req <= '0';
            ui_minmax_write_req <= '0';
            ui_minmax_read_req <= '0';
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                ui_sensor_req <= '0';
                ui_minmax_write_req <= '0';
                ui_minmax_read_req <= '0';
            else
                if ui_oe_i = '1' then
                    if ui_addr_i <= DATA_RAM_MAX then
                        ui_sensor_req <= '1';
                    else
                        ui_minmax_req <= '1';
                        if ui_we_i = '0' then
                            ui_minmax_read_req <= '1';
                        else
                            ui_minmax_read_req <= '0';
                        end if;
                    end if;
                elsif ui_minmax_ack = '1' or ui_data_ack = '1' then
                    ui_sensor_req <= '0';
                    ui_minmax_write_req <= '0';
                    ui_minmax_read_req <= '0';
                end if;
            end if;
        end if;    
    end process ui_signal_mono;

    sensor_signal_mono: process(all)
    begin
        if rst_a_n_i = g_reset_active then
            sensor_sensor_req <= '0';
            sensor_minmax_req <= '0';
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                sensor_sensor_req <= '0';
                sensor_minmax_req <= '0';
            else
                if sensor_data_valid_i = '1' then
                    sensor_sensor_req <= '1';
                    sensor_minmax_req <= '1';
                elsif sensor_minmax_ack = '1' or sensor_sensor_ack = '1' then
                    sensor_sensor_req <= '0';
                    sensor_minmax_req <= '0';
                end if;
            end if;
        end if;    
    end process sensor_signal_mono;

    sensor_ram_control: process(all)
    
    procedure reset is
    begin
        mcu_sensor_ram_control <= '0';
        uart_sensor_ram_control <= '0';
        ui_sensor_ram_control <= '0';
        
        sensor_ram_we <= '0';
        sensor_ram_active <= '0';
        sensor_ram_ack <= '0';
        
        sensor_ram_addr <= (others => '0');
        sensor_ram_data_in <= (others => '0');
    end procedure reset;

    begin
        if rst_a_n_i = g_reset_active then
            reset; 
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                reset; 
            else
                if sensor_sensor_req = '1' then                          -- Sensors have priority as they need to write to this ram
                    sensor_ram_we <= '1';
                    sensor_ram_active <= not sensor_ram_ack;
                    sensor_sensor_ack <= sensor_ram_ack;
                    sensor_ram_addr <= sensor_addr_i;
                    sensor_ram_data_in <= sensor_data_i;
                elsif mcu_sensor_req = '1' then                          -- MCU has 2nd priority as it's fastest
                    mcu_data_ack <= sensor_ram_ack;
                    sensor_ram_we <= '0';
                    sensor_ram_active <= not sensor_ram_ack;
                    if sensor_ram_ack = '0' then
                        mcu_sensor_ram_control <= '1';
                    else
                        mcu_sensor_ram_control <= '0';
                    end if;
                    sensor_ram_addr <= mcu_addr_i;
                elsif uart_sensor_req = '1' then                          -- Then UART
                    uart_data_ack <= sensor_ram_ack;
                    sensor_ram_we <= '0';
                    sensor_ram_active <= not sensor_ram_ack;
                    if sensor_ram_ack = '0' then
                        uart_sensor_ram_control <= '1';
                    else
                        uart_sensor_ram_control <= '0';
                    end if;
                    sensor_ram_addr <= uart_addr_i;
                elsif ui_sensor_req = '1' then                          -- UI is last as it's slowest
                    ui_data_ack <= sensor_ram_ack;
                    sensor_ram_we <= '0';
                    sensor_ram_active <= not sensor_ram_ack;
                    if sensor_ram_ack = '0' then
                        ui_sensor_ram_control <= '1';
                    else
                        ui_sensor_ram_control <= '0';
                    end if;
                    sensor_ram_addr <= ui_addr_i;
                else
                    sensor_ram_we <= '0';
                    mcu_sensor_ram_control <= '0';
                    uart_sensor_ram_control <= '0';
                    ui_sensor_ram_control <= '0';
                end if;
            end if;
        end if;
    end process sensor_ram_control;
    


    minmax_ram_control: process(all)
    begin
        if rst_a_n_i = g_reset_active then

        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then

            else
                if cfg_read_req = '1' then
            
                    minmax_ram_we <= '1';
                    minmax_setup_write_finished <= minmax_ram_ack;
                    minmax_ram_active <= not minmax_ram_ack;
                    minmax_ram_addr <= std_ulogic_vector(to_unsigned(cfg_count, minmax_ram_addr'length));
                    minmax_ram_data_in <= cfg_data_in;

                elsif cfg_write_req = '1' then
            
                    minmax_ram_we <= '0';
                    minmax_setup_read_finished <= minmax_ram_ack;
                    minmax_ram_active <= not minmax_ram_ack;
                    minmax_ram_addr <= std_ulogic_vector(to_unsigned(cfg_count, minmax_ram_addr'length));
                    
                    if minmax_ram_ack = '0' then
                        cfg_minmax_ram_control <= '1';
                    else
                        cfg_minmax_ram_control <= '0';
                    end if;

                elsif sensor_minmax_req = '1' then                          -- Sensors have priority as they need to read from here iot write to sensor RAM
                    minmax_ram_we <= '1';
                    if sensor_min_access = '0' then
                        minmax_ram_addr <= sensor_addr_i;
                        sensor_min_access <= '1';
                    else
                        minmax_ram_addr <= std_ulogic_vector(unsigned(minmax_ram_addr) + to_unsigned(1, minmax_ram_addr'length));
                        sensor_minmax_ack <= minmax_ram_ack;
                    end if;
                    minmax_ram_active <= not minmax_ram_ack;
                elsif mcu_minmax_req = '1' then                          -- MCU has 2nd priority as it's fastest
                    mcu_minmax_ack <= minmax_ram_ack;
                    minmax_ram_we <= '0';
                    minmax_ram_active <= not minmax_ram_ack;
                    if minmax_ram_ack = '0' then
                        mcu_minmax_ram_control <= '1';
                    else
                        mcu_minmax_ram_control <= '0';
                    end if;
                    minmax_ram_addr <= mcu_addr_i;
                elsif uart_minmax_req = '1' then                          -- Then UART
                    uart_minmax_ack <= minmax_ram_ack;
                    minmax_ram_we <= '0';
                    minmax_ram_active <= not minmax_ram_ack;
                    if minmax_ram_ack = '0' then
                        uart_minmax_ram_control <= '1';
                    else
                        uart_minmax_ram_control <= '0';
                    end if;
                    minmax_ram_addr <= uart_addr_i;
                    
                elsif ui_minmax_req = '1' then
                    ui_minmax_ack <= minmax_ram_ack;
                    minmax_ram_active <= not minmax_ram_ack;
                    minmax_ram_addr <= ui_addr_i;
                
                    if ui_minmax_read_req = '1' then
                        minmax_ram_we <= '0';
                    else
                        minmax_ram_we <= '1';
                        minmax_ram_data_in <= ui_data_i;
                    end if;
                    
                    if minmax_ram_ack = '0' then
                        ui_minmax_ram_control <= '1';
                    else
                        ui_minmax_ram_control <= '0';
                    end if;
                else
                    mcu_minmax_ram_control <= '0';
                    uart_minmax_ram_control <= '0';
                    ui_minmax_ram_control <= '0';
                end if;
            end if;
        end if;
    end process minmax_ram_control;

    sensor_data_ram: process(all)
    begin
        if rst_a_n_i = g_reset_active then
            sensor_ram_data_out <= (others => '0');
            sensor_ram_ack <= '0';
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                sensor_ram_data_out <= (others => '0');
                sensor_ram_ack <= '0';
            else
                sensor_ram_ack <= '0';
                if sensor_ram_active = '1' then
                    if sensor_ram_we = '1' then
                        sensor_ram(to_integer(unsigned(sensor_ram_addr))) <= sensor_ram_data_in;
                    else
                        sensor_ram_data_out <= sensor_ram(to_integer(unsigned(sensor_ram_addr)));
                    end if;
                    sensor_ram_ack <= '1';
                end if;
            end if;
        end if;
    end process sensor_data_ram;

    minmax_data_ram: process(all)
    begin
        if rst_a_n_i = g_reset_active then
            minmax_ram_data_out <= (others => '0');
            minmax_ram_ack <= '0';
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                minmax_ram_data_out <= (others => '0');
                minmax_ram_ack <= '0';
            else
                minmax_ram_ack <= '0';
                if minmax_ram_active = '1' then
                    if minmax_ram_we = '1' then
                        minmax_ram(to_integer(unsigned(minmax_ram_addr))) <= minmax_ram_data_in;
                    else
                        minmax_ram_data_out <= minmax_ram(to_integer(unsigned(minmax_ram_addr)));
                    end if;
                    minmax_ram_ack <= '1';
                end if;
            end if;
        end if;
    end process minmax_data_ram;
    
    absolute_min_max: process(all)
    begin
        if rst_a_n_i = g_reset_active then
            absolute_boundary <= '0';
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                absolute_boundary <= '0';
            else
                if sensor_data_valid_i = '1' then
                    if to_integer(unsigned(sensor_data_i)) >= min_max_array(to_integer(unsigned(sensor_addr_i)))(0) and to_integer(unsigned(sensor_data_i)) <= min_max_array(to_integer(unsigned(sensor_addr_i)))(1) then
                        absolute_boundary <= '1';
                    else
                        absolute_boundary <= '0';
                    end if;                
                end if;                
            end if;
        end if;
    end process absolute_min_max;
    
    user_set_min_max: process(all)
    
    procedure reset is
    begin
        minmax_ram_addr_temp <= (others => '0');
        access_count <= 0;
        temp_data_max <= (others => '0');
        temp_data_min <= (others => '0');
        alarm_status <= (others => '0');
    end procedure reset;
    
    begin
        if rst_a_n_i = g_reset_active then
            reset;
        elsif rising_edge(clk_i) then
            if soft_rst_n_i = g_reset_active then
                reset;
            else
                if sensor_minmax_req = '1' then
                    if access_count < access_count_max then
                        if minmax_ram_ack = '1' then
                            access_count <= access_count + 1;
                            if access_count = 0 then
                                minmax_ram_addr_temp <= minmax_ram_addr;
                                temp_data_min <= minmax_ram_data_out;
                            elsif access_count = 1 then
                                temp_data_max <= minmax_ram_data_out;
                            end if;
                        end if;
                    else
                        if sensor_ram_data_in >= temp_data_min and sensor_ram_data_in <= temp_data_max then
                            alarm_status(to_integer(unsigned(minmax_ram_addr_temp))) <= '1';
                        else
                            alarm_status(to_integer(unsigned(minmax_ram_addr_temp))) <= '0';
                        end if;
                    end if;
                else
                    access_count <= 0;
                end if;          
            end if;
        end if;
    end process user_set_min_max;
    
    MINMAX_CONFIG : configuration_flash
    generic map
    (
        g_reset_active => g_reset_active
    )
    port map
    (
        clk_i            => clk_i,
        rst_a_n_i        => rst_a_n_i,
        soft_rst_n_i     => soft_rst_n_i,

        cfg_we_i         => cfg_we,
        cfg_oe_i         => cfg_oe,
        cfg_data_i       => cfg_data_out,
        cfg_data_valid_i => cfg_ack_out,

        cfg_data_o       => cfg_data_in,
        cfg_data_valid_o => cfg_data_valid_in,
        cfg_data_req_o   => cfg_data_req_in,

        test_point_o     => open
    );

    mcu_data_o <= sensor_ram_data_out when mcu_sensor_ram_control = '1';
    mcu_ack_o  <= sensor_ram_ack      when mcu_sensor_ram_control = '1';
    
    uart_data_o <= sensor_ram_data_out when uart_sensor_ram_control = '1';
    uart_ack_o  <= sensor_ram_ack      when uart_sensor_ram_control = '1';

    ui_data_o <= sensor_ram_data_out when ui_sensor_ram_control = '1' else minmax_ram_data_out when ui_minmax_ram_control = '1';
    ui_ack_o  <= sensor_ram_ack      when ui_sensor_ram_control = '1' else minmax_ram_ack      when ui_minmax_ram_control = '1';
    
    cfg_data_out <= minmax_ram_data_out when cfg_minmax_ram_control = '1';
    cfg_ack_out  <= minmax_ram_ack      when cfg_minmax_ram_control = '1';
    
    alarm_status_o <= alarm_status;

end Behavioral;
