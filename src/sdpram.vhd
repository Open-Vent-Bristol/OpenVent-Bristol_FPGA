library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity sdpram is
    generic (
        DATA_WIDTH  : integer := 18;
        ADDR_WIDTH  : integer := 10
    );
    port (
        clka    : in    std_logic;
        addra   : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
        wea     : in    std_logic;
        dina    : in    std_logic_vector(DATA_WIDTH-1 downto 0);
        clkb    : in    std_logic;
        addrb   : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
        doutb   : out   std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity;


architecture rtl of sdpram is

    type ram_array_t is array(0 to 2**ADDR_WIDTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal ram_array        : ram_array_t;

begin

    p_write : process(clka)
    begin
        if rising_edge(clka) then
            if wea = '1' then
                ram_array(to_integer(unsigned(addra))) <= dina;
            end if;
        end if;
    end process;

    p_read : process(clkb)
    begin
        if rising_edge(clkb) then
            doutb <= ram_array(to_integer(unsigned(addrb)));
        end if;
    end process;

end architecture;