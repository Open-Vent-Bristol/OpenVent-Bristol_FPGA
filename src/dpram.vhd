library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity dpram is
    generic (
        DATA_WIDTH  : integer := 18;
        ADDR_WIDTH  : integer := 10
    );
    port (
        clka    : in    std_logic;
        addra   : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
        wea     : in    std_logic;
        dina    : in    std_logic_vector(DATA_WIDTH-1 downto 0);
        douta   : out   std_logic_vector(DATA_WIDTH-1 downto 0);
        clkb    : in    std_logic;
        addrb   : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
        web     : in    std_Logic;
        dinb    : in    std_logic_vector(DATA_WIDTH-1 downto 0);
        doutb   : out   std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity;


architecture rtl of dpram is

    type ram_array_t is array(0 to 2**ADDR_WIDTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal ram_array        : ram_array_t;

begin

    p_a : process(clka)
    begin
        if rising_edge(clka) then
            if wea = '1' then
                ram_array(to_integer(unsigned(addra))) <= dina;
            else
                douta <= ram_array(to_integer(unsigned(addra)));
            end if;
        end if;
    end process;

    p_b : process(clkb)
    begin
        if rising_edge(clkb) then
            if web = '1' then
                ram_array(to_integer(unsigned(addrb))) <= dinb;
            else
                doutb <= ram_array(to_integer(unsigned(addrb)));
            end if;
        end if;
    end process;

end architecture;