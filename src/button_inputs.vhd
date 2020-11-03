library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use ovb_h.all;


entity button_inputs is
    port (
        clk             : in    std_logic;
        rst             : in    std_logic;
        buttons         : in    std_logic_vector(3 downto 0);
        short_press     : out   std_logic_vector(3 downto 0);
        long_press      : out   std_logic_vector(3 downto 0)
    );
end entity;


architecture rtl of button_inputs is

    signal ce_count     : natural range 0 to BUTTON_CE_CYCLES-1;
    signal ce           : std_logic;
    signal buttons_sync : std_logic_vector(3 downto 0);

begin

    p_rst: process(clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                ce_count <= 0;
                ce <= '0';
            else
                ce_count <= ce_count + 1;
                if ce_count = BUTTON_CE_CYCLES-1 then
                    ce_count <= 0;
                end if;
                if ce_count = BUTTON_CE_CYCLES-1 then
                    ce <= '1';
                else
                    ce <= '0';
                end if;
            end if;
        end if;
    end process;

    g_buttons: for i in 0 to buttons'left generate

        i_btn_sync: entity work.sync_ff 
            port map (
                clk => clk, 
                rst => rst, 
                ce  => '1', 
                d   => buttons(i), 
                q   => buttons_sync(i)
            );
            
        i_process_button: entity work.process_button 
            port map (
                clk         => clk, 
                rst         => rst, 
                ce          => ce, 
                button      => buttons_sync(i), 
                short_press => short_press(i), 
                long_press  => long_press(i)
            );

    end generate;

end architecture;