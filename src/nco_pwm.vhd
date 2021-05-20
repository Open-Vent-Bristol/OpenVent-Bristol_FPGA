library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nco_pwm is
    generic
    (
        MAX_COUNT : POSITIVE := 256;
        DUTY      : NATURAL  := 128
    );
    port
    (
        clk   : in STD_LOGIC;
        rst   : in STD_LOGIC;
        pwm_o : out STD_LOGIC := '0'
    );
end entity;

architecture behav of nco_pwm is
    signal count : INTEGER range 0 to MAX_COUNT - 1 := 0;
begin

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                pwm_o <= '0';
                count <= 0;
            else
                if count >= MAX_COUNT - 1 then
                    count <= 0;
                else
                    count <= count + 1;
                end if;

                if count < DUTY then
                    pwm_o <= '1';
                else
                    pwm_o <= '0';
                end if;
            end if;
        end if;
    end process;

end architecture;
