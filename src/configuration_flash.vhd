----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.05.2021 21:31:32
-- Design Name: 
-- Module Name: configuration_flash - Behavioral
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
use work.configuration_flash_pkg.all;

entity configuration_flash is
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
end configuration_flash;

architecture Behavioral of configuration_flash is

    type state_t is (IDLE, READ, ERASE_SETUP, ERASE_RECOVER, WRITE_SETUP, WRITE_ACTIVE, WRITE_RECOVER);
    signal currentstate, nextstate : state_t;

    signal flash_x_addr : std_ulogic_vector(5 downto 0) := (others => '0');
    signal flash_y_addr : std_ulogic_vector(5 downto 0) := (others => '0');
    signal flash_x_en   : std_ulogic := '0';
    signal flash_y_en   : std_ulogic := '0';
    signal flash_det_en : std_ulogic := '0';
    signal flash_erase  : std_ulogic := '0';
    signal flash_prog   : std_ulogic := '0';
    signal flash_nvstr  : std_ulogic := '0';
    signal flash_data_in  : std_ulogic_vector(31 downto 0) := (others => '0');
    signal flash_data_out : std_ulogic_vector(31 downto 0) := (others => '0');
    
    signal temp_data : std_ulogic_vector(31 downto 0) := (others => '0');
    
    signal clk_5us : std_ulogic := '0';
    
    signal first_run : std_ulogic := '0';
    signal flash_read_req : std_ulogic := '0';
    signal flash_write_req : std_ulogic := '0';
    signal read_complete : std_ulogic := '0';
    signal erase_setup_complete : std_ulogic := '0';
    signal erase_recover_complete : std_ulogic := '0';
    signal write_setup_complete : std_ulogic := '0';
    signal write_complete : std_ulogic := '0';
    signal write_recover_complete : std_ulogic := '0';
    
    constant position_count_max : natural := 14;
    signal position_count : natural range 0 to position_count_max;
    
    constant read_count_max : natural := 2;
    signal read_count : natural range 0 to read_count_max;
    
    constant write_count_max : natural := 4;
    signal write_count : natural range 0 to write_count_max;
    
    signal flash_cycle : std_ulogic := '0';
    signal flash_timeout : std_ulogic := '0';
    signal erase_active : std_ulogic := '0';
    signal next_data_req : std_ulogic := '0';
    signal all_writes_complete : std_ulogic := '0';
    
    signal flash_temp_data : std_ulogic_vector(31 downto 0) := (others => '0');
    signal flash_data_ready : std_ulogic := '0';

begin

    clock_5us: clock_divider
    generic map
    (
        g_reset_active => g_reset_active,
        g_output_clock_counts => 62                     -- 2.5us-ish
    )
    port map
    (
        clk_i        => clk_i,
        rst_a_n_i    => rst_a_n_i,
        soft_rst_n_i => soft_rst_n_i,

        clk_o        => clk_5us
    );
    
    config_sync_inputs: process(all)
    begin
        if rst_a_n_i = g_reset_active then
            flash_write_req <= '0';
            flash_read_req <= '0';
            temp_data <= (others => '0');
        elsif rising_edge (clk_i) then
            if soft_rst_n_i = g_reset_active then
                flash_write_req <= '0';
                flash_read_req <= '0';
                temp_data <= (others => '0');
            else
                if currentstate = IDLE then
                    if cfg_oe_i = '1' then                          -- If stuff needs to be done
                        if cfg_we_i = '1' then                      -- WRITE
                            flash_write_req <= '1';
                        else                                        -- READ
                            flash_read_req <= '1';
                        end if;
                    end if;
                else
                    if cfg_data_valid_i = '1' then
                        temp_data <= cfg_data_i;
                    end if;
                    
                    flash_write_req <= '0';
                    flash_read_req <= '0';
                end if;
            end if;
        end if;    
    end process config_sync_inputs;

    fsm_driver : process (all)
    begin
        if rst_a_n_i = g_reset_active then
            currentstate <= IDLE;
        elsif rising_edge (clk_5us) then
            if soft_rst_n_i = g_reset_active then
                currentstate <= IDLE;
            else
                currentstate <= nextstate;
            end if;
        end if;
    end process fsm_driver;
    
    fsm_loop: process(all)
    begin
        nextstate <= currentstate;
        case currentstate is
            when IDLE =>
                if first_run = '1' or flash_read_req = '1' then
                    nextstate <= READ;
                elsif flash_write_req = '1' then
                    nextstate <= ERASE_SETUP;
                else
                    nextstate <= IDLE;
                end if;  
                   
            when READ =>
                if read_complete = '1' then
                    nextstate <= IDLE;
                else
                    nextstate <= READ;
                end if;
                
            when ERASE_SETUP =>
                if erase_setup_complete = '1' then
                    nextstate <= ERASE_RECOVER;
                else
                    nextstate <= ERASE_SETUP;
                end if;   
                
            when ERASE_RECOVER =>
                if erase_recover_complete = '1' then
                    nextstate <= WRITE_SETUP;
                else
                    nextstate <= ERASE_RECOVER;
                end if;

            when WRITE_SETUP =>
                if write_setup_complete = '1' then
                    nextstate <= WRITE_ACTIVE;
                else
                    nextstate <= WRITE_SETUP;
                end if;
                
            when WRITE_ACTIVE =>
                if all_writes_complete = '1' then
                    nextstate <= WRITE_RECOVER;
                else
                    nextstate <= WRITE_ACTIVE;
                end if;    
                
            when WRITE_RECOVER =>
                if write_recover_complete = '1' then
                    nextstate <= IDLE;
                else
                    nextstate <= WRITE_RECOVER;
                end if;

            when others =>
                nextstate <= IDLE;
            
        end case;
    end process fsm_loop;
 
    configuration_access: process(all)
    
    procedure flash_access_reset is
    begin
        flash_data_in <= (others => '0');
        flash_x_addr <= (others => '0');
        flash_y_addr <= (others => '0');
        flash_x_en <= '0';
        flash_y_en <= '0';
        flash_det_en <= '0';
        flash_erase <= '0';
        flash_prog <= '0';
        flash_nvstr <= '0';
    end procedure flash_access_reset;
    
    procedure reset is
    begin
        flash_access_reset;
        first_run <= '1';
        position_count <= 0;
        read_count <= 0;
        write_count <= 0;
        flash_temp_data <= (others => '0');
        flash_data_ready <= '0';
        flash_cycle <= '0';
        erase_active <= '0';
        erase_setup_complete <= '0';
        erase_recover_complete <= '0';
        write_recover_complete <= '0';
    end procedure reset;

    begin
        if rst_a_n_i = g_reset_active then
            reset;
        elsif rising_edge(clk_5us) then
            if soft_rst_n_i = g_reset_active then
                reset;
            else
                flash_data_ready <= '0';
                write_complete <= '0';
                all_writes_complete <= '0';
                if currentstate = IDLE then
                    first_run <= '0';
                    flash_access_reset;
    
                elsif currentstate = READ then                       -- Read everything, so we can cycle through
                    if position_count < position_count_max and read_complete = '0' then
                        read_count <= read_count + 1;
                        if read_count < read_count_max then
                            if read_count = 0 then
                                flash_x_addr <= (others => '0');                                                        -- Only 1 row needed for our data
                                flash_y_addr <= std_ulogic_vector(to_unsigned(position_count, flash_y_addr'length));    -- Page encompasses all of Y, specific row selected by X
                                flash_x_en <= '1';
                                flash_y_en <= '1';
                                flash_det_en <= '1';
                                flash_erase <= '0';
                                flash_prog <= '0';
                                flash_nvstr <= '0';
                            else
                                flash_det_en <= '0';
                            end if;
                        else
                            flash_y_en <= '0';
                            flash_temp_data <= flash_data_out;
                            flash_data_ready <= '1';
                            read_count <= 0;
                            position_count <= position_count + 1;
                        end if; 
                    else
                        read_complete <= '1';
                        position_count <= 0;
                    end if;

                elsif currentstate = ERASE_SETUP then
                    erase_active <= flash_cycle;
                    if erase_active = '0' and erase_setup_complete = '0' then
                        write_count <= write_count + 1;
                        if write_count < write_count_max then
                            if write_count = 0 then
                                flash_x_addr <= (others => '0');                -- Only 1 row needed for our data
                                flash_y_addr <= (others => '0');                -- Page encompasses all of Y, specific row selected by X
                                flash_x_en <= '0';
                                flash_y_en <= '0';
                                flash_det_en <= '0';
                                flash_erase <= '0';
                                flash_prog <= '0';
                                flash_nvstr <= '0';
                            elsif write_count = 1 then
                                flash_x_en <= '1';
                            elsif write_count = 2 then
                                flash_erase <= '1';
                            else
                                flash_nvstr <= '1';
                            end if;
                        else
                            flash_cycle <= '1';
                            write_count <= 0;
                        end if; 
                    else
                        if flash_timeout = '1' then
                            erase_setup_complete <= '1';
                            flash_cycle <= '0';
                            erase_active <= '0';
                        else
                            erase_setup_complete <= '0';
                        end if;
                    end if;
                        
                elsif currentstate = ERASE_RECOVER then
                    write_count <= write_count + 1;
                    if write_count < write_count_max and erase_recover_complete = '0' then
                        if write_count = 0 then
                            flash_erase <= '0';
                        elsif write_count = 1 then
                            flash_nvstr <= '0';
                        elsif write_count = 2 then
                            flash_nvstr <= '0';
                        else
                            flash_nvstr <= '1';
                        end if;
                    else
                        erase_recover_complete <= '1';
                        write_count <= 0;
                    end if;
 
                elsif currentstate = WRITE_SETUP then
                    write_count <= write_count + 1;
                    if write_count < write_count_max and write_setup_complete = '0' then
                        if write_count = 0 then
                            flash_x_addr <= (others => '0');
                            flash_y_addr <= (others => '0');
                            flash_x_en <= '0';
                            flash_y_en <= '0';
                            flash_det_en <= '0';
                            flash_erase <= '0';
                            flash_prog <= '0';
                            flash_nvstr <= '0';
                        elsif write_count = 1 then
                            flash_x_en <= '1';
                        elsif write_count = 2 then
                            flash_prog <= '1';
                        else
                            flash_nvstr <= '1';
                        end if;
                    else
                        write_setup_complete <= '1';
                        write_count <= 0;
                    end if;
                        
                elsif currentstate = WRITE_ACTIVE then 
                    if position_count < position_count_max and all_writes_complete = '0' then
                        write_count <= write_count + 1;
                        if write_count < write_count_max then
                            if write_count = 0 then
                                flash_y_addr <= std_ulogic_vector(to_unsigned(position_count, flash_y_addr'length));
                                flash_data_in <= temp_data;
                                next_data_req <= '1';
                            elsif write_count = 1 then
                                flash_y_en <= '1';
                            elsif write_count = 2 then
                                flash_y_en <= '1';
                            else
                                flash_y_en <= '0';
                                if position_count < 13 then
                                    write_complete <= '1';
                                else
                                    write_complete <= '0';
                                end if;
                            end if;
                        else
                            write_count <= 0;
                            position_count <= position_count + 1;
                        end if;
                    else
                        all_writes_complete <= '1';
                        position_count <= 0;
                    end if;
                    
                elsif currentstate = WRITE_RECOVER then 
                    write_count <= write_count + 1;
                    if write_count < (write_count_max - 1) and write_recover_complete = '0' then            -- Count up to 3 in this case
                        if write_count = 0 then
                            flash_prog <= '0';
                        elsif write_count = 1 then
                            flash_nvstr <= '0';
                        else
                            flash_nvstr <= '0';
                        end if;
                    else
                        write_recover_complete <= '1';
                        write_count <= 0;
                    end if;
                end if;
            end if;
        end if;    
    end process configuration_access;
    
    erase_timeout: pulse_generator
    generic map
    (
        g_divided_clock_count_max => 24000,           -- Approx. 120ms
        g_reset_active => g_reset_active
    )
    port map
    (
        clk_i           => clk_5us,
        rst_a_n_i       => rst_a_n_i,
        soft_rst_n_i    => flash_cycle,
        clock_enable_i  => flash_cycle,          -- Start timer cycle

        divided_clock_o => flash_timeout        -- Output inhibit?
    );

--    uut: FLASH64KZ
--    port map 
--    (
--        XADR  => flash_x_addr,
--        YADR  => flash_y_addr,
--        XE    => flash_x_en,
--        YE    => flash_y_en,
--        SE    => flash_det_en,
--        ERASE => flash_erase,
--        PROG  => flash_prog,
--        NVSTR => flash_nvstr,
--        DIN   => flash_data_in,
--        DOUT  => flash_data_out
--    );
    
    cfg_data_o       <= flash_temp_data;
    cfg_data_valid_o <= flash_data_ready;
    cfg_data_req_o   <= write_complete;

end Behavioral;
