----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.06.2021 12:27:50
-- Design Name: 
-- Module Name: tb_ovb_ram - Behavioral
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

entity tb_ovb_ram is
end tb_ovb_ram;

architecture Behavioral of tb_ovb_ram is

    component ovb_ram is
    generic
    (
        g_reset_active : std_ulogic := '0'
    );
    port
    (
        clk_i               : in std_ulogic;                                    -- System Clock IN
        rst_a_n_i           : in std_ulogic;                                    -- Asynchronous Reset IN
        soft_rst_n_i        : in std_ulogic;                                    -- Synchronous Reset IN (here if you need/want it)
        
        ram_busy_o          : out std_ulogic; 
    
        -- Probably used for MCU
        mcu_addr_i         : in std_ulogic_vector(7 downto 0); 
        mcu_sel_i          : in std_ulogic;                                 -- '1' Get Sensor Data, '0' Get MinMax Data  
        mcu_oe_i           : in std_ulogic;
        mcu_data_o         : out std_ulogic_vector(15 downto 0);
        mcu_ack_o          : out std_ulogic;   
        
        -- Probably used for UART
        uart_addr_i         : in std_ulogic_vector(7 downto 0); 
        uart_sel_i          : in std_ulogic;                                -- '1' Get Sensor Data, '0' Get MinMax Data 
        uart_oe_i           : in std_ulogic;
        uart_data_o         : out std_ulogic_vector(15 downto 0);
        uart_ack_o          : out std_ulogic;                
    
        -- From Sensor Arbitration
        sensor_addr_i       : in std_ulogic_vector(7 downto 0);
        sensor_data_i       : in std_ulogic_vector(15 downto 0);
        sensor_data_valid_i : in std_ulogic;
        
        -- To/From UI
        ui_addr_i           : in std_ulogic_vector(7 downto 0);
        ui_sel_i            : in std_ulogic;                                -- '1' Get Sensor Data, '0' Get/Set MinMax Data
        ui_oe_i             : in std_ulogic;
        ui_we_i             : in std_ulogic;
        ui_data_i           : in std_ulogic_vector(15 downto 0);
        ui_data_o           : out std_ulogic_vector(15 downto 0);
        ui_ack_o            : out std_ulogic;
        
        -- Additional Signals
        cfg_mode_change_i   : in std_ulogic;                            -- Change to/from Standby to something else
        alarm_status_o      : out std_ulogic_vector(15 downto 0);       -- Alarm status flags 7 alarms, each with 2 states, "00" at start to make it 16 bit
    
        test_point_o        : out std_ulogic_vector(7 downto 0)
    );
    end component;
    
    signal sig_clk_i               : std_ulogic := '0';
    signal sig_rst_a_n_i           : std_ulogic := '0';
    signal sig_soft_rst_n_i        : std_ulogic := '0';
    
    signal sig_ram_busy_o          : std_ulogic := '0';

    signal sig_mcu_addr_i          : std_ulogic_vector(7 downto 0) := (others => '0');
    signal sig_mcu_sel_i           : std_ulogic := '0';
    signal sig_mcu_oe_i            : std_ulogic := '0';
    signal sig_mcu_data_o          : std_ulogic_vector(15 downto 0) := (others => '0');
    signal sig_mcu_ack_o           : std_ulogic := '0';

    signal sig_uart_addr_i         : std_ulogic_vector(7 downto 0) := (others => '0');
    signal sig_uart_sel_i          : std_ulogic := '0';
    signal sig_uart_oe_i           : std_ulogic := '0';
    signal sig_uart_data_o         : std_ulogic_vector(15 downto 0) := (others => '0');
    signal sig_uart_ack_o          : std_ulogic := '0';

    signal sig_sensor_addr_i       : std_ulogic_vector(7 downto 0) := (others => '0');
    signal sig_sensor_data_i       : std_ulogic_vector(15 downto 0) := (others => '0');
    signal sig_sensor_data_valid_i : std_ulogic := '0';

    signal sig_ui_addr_i           : std_ulogic_vector(7 downto 0) := (others => '0');
    signal sig_ui_sel_i            : std_ulogic := '0';
    signal sig_ui_oe_i             : std_ulogic := '0';
    signal sig_ui_we_i             : std_ulogic := '0';
    signal sig_ui_data_i           : std_ulogic_vector(15 downto 0) := (others => '0');
    signal sig_ui_data_o           : std_ulogic_vector(15 downto 0) := (others => '0');
    signal sig_ui_ack_o            : std_ulogic := '0';

    signal sig_cfg_mode_change_i   : std_ulogic := '0';
    signal sig_alarm_status_o      : std_ulogic_vector(15 downto 0) := (others => '0');

    signal sig_test_point_o        : std_ulogic_vector(7 downto 0) := (others => '0');
    
    constant clk_period : time := 20ns;         -- Roughly 25MHz clock (33.3MHz is awkward af for timing)
    signal done : boolean := false;

begin

    TESTBENCH : ovb_ram
    port map
    (
        clk_i               => sig_clk_i,              
        rst_a_n_i           => sig_rst_a_n_i,          
        soft_rst_n_i        => sig_soft_rst_n_i, 
        
        ram_busy_o          => sig_ram_busy_o,      

        mcu_addr_i          => sig_mcu_addr_i, 
        mcu_sel_i           => sig_mcu_sel_i,        
        mcu_oe_i            => sig_mcu_oe_i,           
        mcu_data_o          => sig_mcu_data_o,         
        mcu_ack_o           => sig_mcu_ack_o,          

        uart_addr_i         => sig_uart_addr_i, 
        uart_sel_i          => sig_uart_sel_i,        
        uart_oe_i           => sig_uart_oe_i,          
        uart_data_o         => sig_uart_data_o,        
        uart_ack_o          => sig_uart_ack_o,         

        sensor_addr_i       => sig_sensor_addr_i,      
        sensor_data_i       => sig_sensor_data_i,      
        sensor_data_valid_i => sig_sensor_data_valid_i,

        ui_addr_i           => sig_ui_addr_i,   
        ui_sel_i            => sig_ui_sel_i,     
        ui_oe_i             => sig_ui_oe_i,            
        ui_we_i             => sig_ui_we_i,            
        ui_data_i           => sig_ui_data_i,          
        ui_data_o           => sig_ui_data_o,          
        ui_ack_o            => sig_ui_ack_o,           

        cfg_mode_change_i   => sig_cfg_mode_change_i,  
        alarm_status_o      => sig_alarm_status_o,     

        test_point_o        => sig_test_point_o   
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

            -------------------- READ CONFIGURATION FLASH ------------------

            wait for 1ms;
            
            -------------------- WRITE CONFIGURATION FLASH ------------------
            
            sig_cfg_mode_change_i <= '1';
            wait for 40ns;
            sig_cfg_mode_change_i <= '0';
            
            wait for 150ms;
            
            -------------------- WRITE SENSOR DATA ------------------
            
            for i in 0 to 6 loop
            
                sig_sensor_addr_i <= std_ulogic_vector(to_unsigned(i, sig_sensor_addr_i'length));
                sig_sensor_data_i <= x"00FF";
                
                sig_sensor_data_valid_i <= '1';
                wait for 40ns;
                sig_sensor_data_valid_i <= '0';
                
                while (sig_ram_busy_o = '1') loop
                    wait for 40ns;
                end loop;
                
                wait for 40ns;

            end loop;
            
            -------------------- READ UI DATA ------------------
            
            for i in 0 to 6 loop
            
                sig_ui_addr_i <= std_ulogic_vector(to_unsigned(i, sig_ui_addr_i'length));
                sig_ui_sel_i <= '1';            -- Sensor Data
                sig_ui_oe_i <= '1';             -- Start
                wait for 40ns;
                sig_ui_oe_i <= '0';

                while (sig_ui_ack_o = '0') loop
                    wait for 40ns;
                end loop;
                
                wait for 400ns;

            end loop;
            
            -------------------- READ UI MINMAX ------------------
            
            for i in 0 to 13 loop
            
                sig_ui_addr_i <= std_ulogic_vector(to_unsigned(i, sig_ui_addr_i'length));
                sig_ui_sel_i <= '0';            -- MinMax
                sig_ui_we_i <= '0';             -- Read
                sig_ui_oe_i <= '1';             -- Start
                wait for 40ns;
                sig_ui_oe_i <= '0';

                while (sig_ui_ack_o = '0') loop
                    wait for 40ns;
                end loop;
                
                wait for 400ns;

            end loop;
            
            -------------------- WRITE UI MINMAX ------------------
            
            for i in 0 to 13 loop
            
                sig_ui_addr_i <= std_ulogic_vector(to_unsigned(i, sig_ui_addr_i'length));
                sig_ui_data_i <= std_ulogic_vector(to_unsigned(i*2, sig_ui_data_i'length));
                sig_ui_sel_i <= '0';            -- MinMax
                sig_ui_we_i <= '1';             -- Write
                sig_ui_oe_i <= '1';             -- Start
                wait for 40ns;
                sig_ui_oe_i <= '0';

                while (sig_ui_ack_o = '0') loop
                    wait for 40ns;
                end loop;
                
                wait for 400ns;

            end loop;
            
            -------------------- READ MCU DATA ------------------
            
            for i in 0 to 6 loop
            
                sig_mcu_addr_i <= std_ulogic_vector(to_unsigned(i, sig_mcu_addr_i'length));
                sig_mcu_sel_i <= '1';            -- Sensor Data
                sig_mcu_oe_i <= '1';             -- Start
                wait for 40ns;
                sig_mcu_oe_i <= '0';

                while (sig_mcu_ack_o = '0') loop
                    wait for 40ns;
                end loop;
                
                wait for 400ns;

            end loop;
            
            -------------------- READ MCU MINMAX ------------------
            
            for i in 0 to 13 loop
            
                sig_mcu_addr_i <= std_ulogic_vector(to_unsigned(i, sig_mcu_addr_i'length));
                sig_mcu_sel_i <= '0';            -- MinMax
                sig_mcu_oe_i <= '1';             -- Start
                wait for 40ns;
                sig_mcu_oe_i <= '0';

                while (sig_mcu_ack_o = '0') loop
                    wait for 40ns;
                end loop;
                
                wait for 400ns;

            end loop;
      
            -------------------- READ UART DATA ------------------
            
            for i in 0 to 6 loop
            
                sig_uart_addr_i <= std_ulogic_vector(to_unsigned(i, sig_uart_addr_i'length));
                sig_uart_sel_i <= '1';            -- Sensor Data
                sig_uart_oe_i <= '1';             -- Start
                wait for 40ns;
                sig_uart_oe_i <= '0';

                while (sig_uart_ack_o = '0') loop
                    wait for 40ns;
                end loop;
                
                wait for 400ns;

            end loop;
            
            -------------------- READ UART MINMAX ------------------
            
            for i in 0 to 13 loop
            
                sig_uart_addr_i <= std_ulogic_vector(to_unsigned(i, sig_uart_addr_i'length));
                sig_uart_sel_i <= '0';            -- MinMax
                sig_uart_oe_i <= '1';             -- Start
                wait for 40ns;
                sig_uart_oe_i <= '0';

                while (sig_uart_ack_o = '0') loop
                    wait for 40ns;
                end loop;
                
                wait for 400ns;

            end loop;
            
            -------------------- WRITE SENSOR, READ MCU AND UART DATA ------------------
            
            for i in 0 to 6 loop

                sig_sensor_addr_i <= std_ulogic_vector(to_unsigned(i, sig_sensor_addr_i'length));
                sig_sensor_data_i <= std_ulogic_vector(to_unsigned(i*3, sig_sensor_data_i'length));
                sig_sensor_data_valid_i <= '1';
                
                sig_uart_addr_i <= std_ulogic_vector(to_unsigned(i, sig_uart_addr_i'length));
                sig_uart_sel_i <= '1';            -- Sensor Data
                sig_uart_oe_i <= '1';             -- Start
                
                wait for 40ns;

                sig_mcu_addr_i <= std_ulogic_vector(to_unsigned(i, sig_mcu_addr_i'length));
                sig_mcu_sel_i <= '1';            -- Sensor Data
                sig_mcu_oe_i <= '1';             -- Start

                wait for 40ns;
                sig_sensor_data_valid_i <= '0';
                sig_mcu_oe_i <= '0';
                sig_uart_oe_i <= '0';
                
                while (sig_ram_busy_o = '1') loop
                    wait for 40ns;
                end loop;

                while (sig_mcu_ack_o = '0' and sig_uart_ack_o = '0') loop
                    wait for 40ns;
                end loop;
                
                while (sig_mcu_ack_o = '0' and sig_uart_ack_o = '0') loop
                    wait for 40ns;
                end loop;
                
                wait for 400ns;

            end loop;
            
            -------------------- WRITE SENSOR, WRITE CONFIGURATION ------------------
            
            sig_cfg_mode_change_i <= '1';
                
            wait for 40ns;
            sig_cfg_mode_change_i <= '0';
            
            wait for 120ns;
            
            for i in 0 to 6 loop

                sig_sensor_addr_i <= std_ulogic_vector(to_unsigned(i, sig_sensor_addr_i'length));
                sig_sensor_data_i <= std_ulogic_vector(to_unsigned(i*3, sig_sensor_data_i'length));
                sig_sensor_data_valid_i <= '1';
                
                wait for 40ns;
                sig_sensor_data_valid_i <= '0';
                
                while (sig_ram_busy_o = '1') loop
                    wait for 40ns;
                end loop;
                
                wait for 400ns;

            end loop;

            wait for 200ms;

            done <= true;
        end loop;
    end process tb;

end Behavioral;
