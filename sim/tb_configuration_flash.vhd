----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.06.2021 10:34:55
-- Design Name: 
-- Module Name: tb_configuration_flash - Behavioral
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

entity tb_configuration_flash is
end tb_configuration_flash;

architecture Behavioral of tb_configuration_flash is

    component configuration_flash is
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
    
    signal sig_clk_i            : std_ulogic := '0';
    signal sig_rst_a_n_i        : std_ulogic := '0';
    signal sig_soft_rst_n_i     : std_ulogic := '0';

    signal sig_cfg_we_i         : std_ulogic := '0';
    signal sig_cfg_oe_i         : std_ulogic := '0';

    signal sig_cfg_data_i       : std_ulogic_vector(31 downto 0) := (others => '0');
    signal sig_cfg_data_valid_i : std_ulogic := '0';

    signal sig_cfg_data_o       : std_ulogic_vector(31 downto 0) := (others => '0');
    signal sig_cfg_data_valid_o : std_ulogic := '0';

    signal sig_cfg_data_req_o   : std_ulogic := '0';

    signal sig_test_point_o     : std_ulogic_vector(7 downto 0) := (others => '0');

    constant clk_period : time := 20ns;         -- Roughly 25MHz clock (33.3MHz is awkward af for timing)
    signal done : boolean := false;

begin

    TESTBENCH : configuration_flash
    port map
    (
        clk_i            => sig_clk_i,           
        rst_a_n_i        => sig_rst_a_n_i,       
        soft_rst_n_i     => sig_soft_rst_n_i,    

        cfg_we_i         => sig_cfg_we_i,        
        cfg_oe_i         => sig_cfg_oe_i,        

        cfg_data_i       => sig_cfg_data_i,      
        cfg_data_valid_i => sig_cfg_data_valid_i,

        cfg_data_o       => sig_cfg_data_o,      
        cfg_data_valid_o => sig_cfg_data_valid_o,

        cfg_data_req_o   => sig_cfg_data_req_o,  

        test_point_o     => sig_test_point_o 
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

            wait for 1us;
            
            ----------------- READ CONFIGURATION ----------------
            
            sig_cfg_oe_i <= '1';                -- Start
            sig_cfg_we_i <= '0';                -- Read
            wait for 120ns;
            sig_cfg_oe_i <= '0';                -- Start
            
            wait for 400us;
            
            ----------------- WRITE CONFIGURATION ----------------
            
            sig_cfg_oe_i <= '1';                -- Start
            sig_cfg_we_i <= '1';                -- Write
            wait for 120ns;
            sig_cfg_oe_i <= '0';                -- Start
            
            wait for 1us;
            
            sig_cfg_data_i <= x"00000000";
            sig_cfg_data_valid_i <= '1';
            wait for 40ns;
            sig_cfg_data_valid_i <= '0';
            
            for i in 1 to 14 loop
            
                while (sig_cfg_data_req_o = '0') loop
                    wait for 40ns;
                end loop;
                
                wait for 1us;
                
                sig_cfg_data_i <= std_ulogic_vector(to_unsigned(i, sig_cfg_data_i'length));
                sig_cfg_data_valid_i <= '1';
                wait for 40ns;
                sig_cfg_data_valid_i <= '0';
                
                while (sig_cfg_data_req_o = '1') loop
                    wait for 40ns;
                end loop;
            
            end loop;

            wait for 500us;

            done <= true;
        end loop;
    end process tb;

end Behavioral;
