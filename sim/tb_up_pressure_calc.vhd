----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.07.2021 13:59:32
-- Design Name: 
-- Module Name: tb_up_pressure_calc - Behavioral
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

entity tb_up_pressure_calc is
end tb_up_pressure_calc;

architecture Behavioral of tb_up_pressure_calc is

    component up_pressure_calc is
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
    end component;
    
    signal sig_clk_i            : std_ulogic := '0';
    signal sig_rst_a_n_i        : std_ulogic := '0';
    signal sig_soft_rst_n_i     : std_ulogic := '0';

    signal sig_sensor_address_i : std_ulogic_vector(7 downto 0) := (others => '0');
    signal sig_addr_valid_i     : std_ulogic := '0';

    signal sig_op_mode_i        : std_ulogic := '0';

    signal sig_abs_pressure_i   : std_ulogic_vector(11 downto 0) := (others => '0');
    signal sig_raw_data_i       : std_ulogic_vector(11 downto 0) := (others => '0');

    signal sig_data_o           : std_ulogic_vector(11 downto 0) := (others => '0');
    signal sig_data_valid_o     : std_ulogic := '0';
    
    type t_raw_data is array(8 downto 3) of std_ulogic_vector(11 downto 0);
    constant raw_data_setup : t_raw_data :=
    (
        x"064",         --  8   100     Offset  FiO2                        3.3V    80.57
        x"0C8",         --  7   200     Offset  Ambient Absolute Pressure   5V      244.14
        x"12C",         --  6   300     Offset  Upstream Pressure           5V      366.21
        x"190",         --  5   400     Offset  Downstream Pressure         5V      488.28
        x"1F4",         --  4   500     Offset  Ambient Temperature         3.3V    403     (in fact hard set to 400mV)
        x"258"          --  3   600     Offset  Differential Pressure       5V      732.42
    ); 
    
    constant raw_data : t_raw_data :=
    (
        x"1F4",         --  8   500      FiO2                        3.3V    402.85
        x"3E8",         --  7   1000     Ambient Absolute Pressure   5V      1220.7
        x"5DC",         --  6   1500     Upstream Pressure           5V      1831.05
        x"7D0",         --  5   2000     Downstream Pressure         5V      2441.4
        x"9C4",         --  4   2500     Ambient Temperature         3.3V    2014.25
        x"BB8"          --  3   3000     Differential Pressure       5V      3662.1
    ); 
    
    -- Totals for above (what is at the output)
    -- 8 25.296703
    -- 7 1274.049473
    -- 6 1911.074209
    -- 5 2548.098946
    -- 4 82.77874
    -- 3 3822.148418

    constant c_abs_pressure : std_ulogic_vector(11 downto 0) := x"4FA";     -- 1274

    constant clk_period : time := 20ns;         -- Roughly 25MHz clock (33.3MHz is awkward af for timing)
    signal done : boolean := false;

begin

    TESTBENCH_CORE : up_pressure_calc
    port map
    (
        clk_i            => sig_clk_i,
        rst_a_n_i        => sig_rst_a_n_i,
        soft_rst_n_i     => sig_soft_rst_n_i,

        sensor_address_i => sig_sensor_address_i,
        addr_valid_i     => sig_addr_valid_i,

        op_mode_i        => sig_op_mode_i,

        abs_pressure_i   => sig_abs_pressure_i,
        raw_data_i       => sig_raw_data_i,

        data_o           => sig_data_o,
        data_valid_o     => sig_data_valid_o
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
            
            sig_abs_pressure_i <= c_abs_pressure;

            wait for 1us;
            
            ------------------------- SET OFFSET --------------------------
            
            sig_op_mode_i <= '0';  
            
            wait for 1us; 
            
            for i in 3 to 8 loop
            
                sig_sensor_address_i <= std_ulogic_vector(to_unsigned(i, sig_sensor_address_i'length));
                sig_addr_valid_i <= '1';
                
                sig_raw_data_i <= raw_data_setup(i);
                wait for 40ns;
                sig_addr_valid_i <= '0';
                
                wait for 200ns;

            end loop;
            
            wait for 1us;
            
            ----------------------- NORMAL MODE ------------------------
            
            sig_op_mode_i <= '1';  
            
            wait for 1us; 
            
            for i in 3 to 8 loop
            
                sig_sensor_address_i <= std_ulogic_vector(to_unsigned(i, sig_sensor_address_i'length));
                sig_addr_valid_i <= '1';
                
                sig_raw_data_i <= raw_data(i);
                wait for 40ns;
                sig_addr_valid_i <= '0';
                
                wait for 600ns;

            end loop;
            
            wait for 5us;

            done <= true;
        end loop;
    end process tb;

end Behavioral;
