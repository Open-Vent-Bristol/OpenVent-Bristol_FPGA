----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.05.2021 13:12:05
-- Design Name: 
-- Module Name: tb_sensor_arbitration - Behavioral
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

entity tb_sensor_arbitration is
end tb_sensor_arbitration;

architecture Behavioral of tb_sensor_arbitration is

    component sensor_arbitration is
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
        ram_ack_i       : in std_ulogic;                        -- Stops shift count until valid
    
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
        sensor_data_o          : out std_ulogic_vector(13 downto 0);
        sensor_data_valid_o    : out std_ulogic;
    
        test_point_o    : out std_ulogic_vector(7 downto 0)
    );
    end component;
    
    constant c_g_reset_active   : std_ulogic := '0';
    
    signal sig_clk_i                        : std_ulogic := '0';
    signal sig_rst_a_n_i                    : std_ulogic := '0';
    signal sig_soft_rst_n_i                 : std_ulogic := '0';

    signal sig_ram_busy_i                   : std_ulogic := '0';
    signal sig_ram_ack_i                    : std_ulogic := '0';

    signal sig_O2_sd_data_i                 : std_ulogic_vector(13 downto 0) := (others => '0');
    signal sig_O2_sd_data_valid_i           : std_ulogic := '0';

    signal sig_pres_vent_sd_data_i          : std_ulogic_vector(13 downto 0) := (others => '0');
    signal sig_pres_vent_sd_data_valid_i    : std_ulogic := '0';

    signal sig_pres_pat_sd_data_i           : std_ulogic_vector(13 downto 0) := (others => '0');
    signal sig_pres_pat_sd_data_valid_i     : std_ulogic := '0';

    signal sig_flow_drct_sd_data_i          : std_ulogic_vector(13 downto 0) := (others => '0');
    signal sig_flow_drct_sd_data_valid_i    : std_ulogic := '0';

    signal sig_flow_gain_sd_data_i          : std_ulogic_vector(13 downto 0) := (others => '0');
    signal sig_flow_gain_sd_data_valid_i    : std_ulogic := '0';

    signal sig_i2c_data_i                   : std_ulogic_vector(13 downto 0) := (others => '0');
    signal sig_i2c_data_valid_i             : std_ulogic := '0';

    signal sig_spi_data_i                   : std_ulogic_vector(13 downto 0) := (others => '0');
    signal sig_spi_data_valid_i             : std_ulogic := '0';

    signal sig_sensor_address_o             : std_ulogic_vector(7 downto 0) := (others => '0');
    signal sig_sensor_data_o                : std_ulogic_vector(13 downto 0) := (others => '0');
    signal sig_sensor_data_valid_o          : std_ulogic := '0';

    signal sig_test_point_o                 : std_ulogic_vector(7 downto 0) := (others => '0');
    
    type test_vector_t is array (6 downto 0) of std_ulogic_vector(13 downto 0);
    signal test_vector : test_vector_t := (others => (others => '0'));
    
    signal test_vector_valid : std_ulogic_vector(6 downto 0) := (others => '0');

    constant clk_period : time := 20ns;         -- Roughly 25MHz clock (33.3MHz is awkward af for timing)
    signal done : boolean := false;

begin

    inst_sensor_arbitration : sensor_arbitration
    generic map
    (
        g_reset_active => c_g_reset_active
    )
    port map
    (
        clk_i                     => sig_clk_i,                    
        rst_a_n_i                 => sig_rst_a_n_i,                
        soft_rst_n_i              => sig_soft_rst_n_i,             

        ram_busy_i                => sig_ram_busy_i,     
        ram_ack_i                 => sig_ram_ack_i,          

        O2_sd_data_i              => test_vector(0),             
        O2_sd_data_valid_i        => test_vector_valid(0),       

        pres_vent_sd_data_i       => test_vector(1),      
        pres_vent_sd_data_valid_i => test_vector_valid(1),

        pres_pat_sd_data_i        => test_vector(2),       
        pres_pat_sd_data_valid_i  => test_vector_valid(2), 

        flow_drct_sd_data_i       => test_vector(3),      
        flow_drct_sd_data_valid_i => test_vector_valid(3),

        flow_gain_sd_data_i       => test_vector(4),      
        flow_gain_sd_data_valid_i => test_vector_valid(4),

        i2c_data_i                => test_vector(5),               
        i2c_data_valid_i          => test_vector_valid(5),         

        spi_data_i                => test_vector(6),               
        spi_data_valid_i          => test_vector_valid(6),         

        sensor_address_o          => sig_sensor_address_o,         
        sensor_data_o             => sig_sensor_data_o,            
        sensor_data_valid_o       => sig_sensor_data_valid_o,      

        test_point_o              => sig_test_point_o             
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
    
    procedure reset is
    begin
        test_vector_valid <= (others => '0');
    end procedure reset;

    begin
        while(done /= true) loop
            sig_rst_a_n_i <= '0';
            sig_soft_rst_n_i <= '0';
            wait for 1us;
            sig_rst_a_n_i <= '1';
            sig_soft_rst_n_i <= '1';
            sig_ram_busy_i <= '0';
            wait for 1us;

            for i in 0 to 15 loop
            
                if i <= 6 then
                    test_vector(i) <= std_ulogic_vector(to_unsigned((i*2), 14));
                    test_vector_valid(i) <= '1';
                else
                    if i = 6 then
                        test_vector(0) <= std_ulogic_vector(to_unsigned((i*2), 14));
                        test_vector(1) <= std_ulogic_vector(to_unsigned((i*2), 14));
                        test_vector_valid(0) <= '1';
                        test_vector_valid(1) <= '1';
                    elsif i = 7 then
                        test_vector(2) <= std_ulogic_vector(to_unsigned((i*2), 14));
                        test_vector(3) <= std_ulogic_vector(to_unsigned((i*2), 14));
                        test_vector_valid(2) <= '1';
                        test_vector_valid(3) <= '1';
                    elsif i = 8 then 
                        test_vector(5) <= std_ulogic_vector(to_unsigned((i*2), 14));
                        test_vector(6) <= std_ulogic_vector(to_unsigned((i*2), 14));
                        test_vector_valid(5) <= '1';
                        test_vector_valid(6) <= '1';
                    elsif i = 9 then
                        test_vector(2) <= std_ulogic_vector(to_unsigned((i*2), 14));
                        test_vector(4) <= std_ulogic_vector(to_unsigned((i*2), 14));
                        test_vector(5) <= std_ulogic_vector(to_unsigned((i*2), 14));
                        test_vector(6) <= std_ulogic_vector(to_unsigned((i*2), 14));
                        test_vector_valid(2) <= '1';
                        test_vector_valid(4) <= '1';       
                        test_vector_valid(5) <= '1';
                        test_vector_valid(6) <= '1';  
                    end if;
                end if;
                
                wait for 40ns;
                sig_ram_busy_i <= '1';
                sig_ram_ack_i <= '1';
                wait for 40ns;
                sig_ram_ack_i <= '0';
                reset;
                wait for 200ns;   
                sig_ram_busy_i <= '0';

            end loop;
            
            -- Quick Writes --
            
            for x in 0 to 6 loop
            
                test_vector_valid(x) <= '1';
                test_vector(x) <= std_ulogic_vector(to_unsigned((x*2), 14));
                wait for 40ns;
                test_vector_valid(x) <= '0';

            end loop;
            
            for y in 0 to 6 loop
            
                wait for 40ns;
                sig_ram_busy_i <= '1';
                sig_ram_ack_i <= '1';
                wait for 40ns;
                sig_ram_ack_i <= '0';
                wait for 200ns;
                
            end loop;

            wait for 1ms;

            done <= true;
        end loop;
    end process tb;

end Behavioral;