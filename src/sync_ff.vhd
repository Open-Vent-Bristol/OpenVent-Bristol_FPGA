library ieee;
use ieee.std_logic_1164.all;


entity sync_ff is
generic (
    STAGES          : natural := 2;
    RESET_VALUE     : std_logic := '0'
);
port (
    clk     : in    std_logic;
    rst     : in    std_logic;
    ce      : in    std_logic;
    d       : in    std_logic;
    q       : out   std_logic
);
end entity;


architecture rtl of sync_ff is

    signal d_meta  : std_logic_vector(STAGES-1 downto 0);

begin

    process(clk)
    begin

        assert STAGES >= 2
        report "STAGES must be greater than or equal to two."
        severity failure;

        q <= d_meta(STAGES-1);

        if rising_edge(clk) then
            if rst = '1' then
                d_meta <= (others=>RESET_VALUE);
            elsif ce = '1' then
                d_meta <= d_meta(STAGES-2 downto 0) & d;
            end if;
        end if;
    end process;

end architecture;